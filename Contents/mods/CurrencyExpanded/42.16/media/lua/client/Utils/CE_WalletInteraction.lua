-- =============================================================================
-- DYNAMIC TRADING: WALLET INTERACTION
-- =============================================================================

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISInventoryTransferAction"
require "DT/Common/Utils/DT_AudioManager"
require "CE/Common/Config/CE_Config"
require "CE/Common/Wallet/CE_WalletLottery"
require "CE/Common/InteractionStrings/Lottery/CE_InteractionStrings_Lottery_Wallet"

local WALLET_SEARCHED_KEY = "CE_WalletSearched"
local WALLET_ORIGINAL_NAME_KEY = "CE_WalletOriginalName"
local WalletLottery = CurrencyExpanded.WalletLottery or {}
local WalletTalk = CurrencyExpanded.GetInteractionStrings("Lottery", "Wallet") or {}

if DT_AudioManager and DT_AudioManager.RegisterCategory then
    DT_AudioManager.RegisterCategory("CE_Casino", "Wallet")
    DT_AudioManager.RegisterCategory("CE_Cashier", "Wallet")
end

-- =============================================================================
-- 1. FLAVOR TEXT & CONFIG
-- =============================================================================
local function GetRandomLine(category)
    if not category or #category == 0 then return "..." end
    return category[ZombRand(#category) + 1]
end

local function ForceSay(player, text)
    if not player or not text then return end
    if player.setSpeakTime then player:setSpeakTime(0) end
    player:Say(text)
end

local function ShowFloatingText(player, text, r, g, b)
    if not player then return end
    player:setHaloNote(text, r, g, b, 300)
end

local function getWalletBaseName(item)
    if not item then return "Wallet" end

    local modData = item:getModData()
    local originalName = modData and modData[WALLET_ORIGINAL_NAME_KEY] or nil

    if not originalName or originalName == "" then
        originalName = tostring(item:getName() or "Wallet")
        if string.sub(originalName, 1, 6) == "Empty " then
            originalName = string.sub(originalName, 7)
        end
        if modData then
            modData[WALLET_ORIGINAL_NAME_KEY] = originalName
        end
    end

    return originalName
end

local function isWalletSearched(item)
    if not item then return false end
    local modData = item:getModData()
    return modData and modData[WALLET_SEARCHED_KEY] == true
end

local function markWalletAsSearched(item)
    if not item then return end

    local modData = item:getModData()
    if not modData then return end

    modData[WALLET_SEARCHED_KEY] = true
    item:setName("Empty " .. getWalletBaseName(item))
end

local function findWalletInPlayerInventory(player, itemID)
    if not player or not itemID then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    return inv:getItemById(itemID)
end

-- =============================================================================
-- 2. LOCAL SP LOGIC
-- =============================================================================
local function ProcessWalletSP(player, item)
    if not item then return end
    local inv = player:getInventory()

    if isWalletSearched(item) then
        local args = { total = 0, type = "ALREADY_SEARCHED", itemID = item:getID() }
        triggerEvent("OnServerCommand", "CurrencyExpanded", "WalletResult", args)
        return
    end
    
    if not WalletLottery.Roll then return end

    local amount, resultType = WalletLottery.Roll(player)

    markWalletAsSearched(item)

    if amount > 0 then
        local bundles = math.floor(amount / 100)
        local looseCash = amount % 100
        if bundles > 0 then inv:AddItems("Base.MoneyBundle", bundles) end
        if looseCash > 0 then inv:AddItems("Base.Money", looseCash) end
    end

    local args = { total = amount, type = resultType, itemID = item:getID() }
    triggerEvent("OnServerCommand", "CurrencyExpanded", "WalletResult", args)
end

-- =============================================================================
-- 3. TIMED ACTION
-- =============================================================================
ISWalletAction = ISBaseTimedAction:derive("ISWalletAction")

function ISWalletAction:isValid()
    if not self.character then return false end
    local inv = self.character:getInventory()
    
    -- 1. Check if the current object reference is still valid, unsearched, and on the player
    if self.item and not isWalletSearched(self.item) and inv:contains(self.item) then return true end

    -- 2. Fallback ID check
    if self.itemID then
        local foundItem = inv:getItemById(self.itemID)
        if foundItem and not isWalletSearched(foundItem) then
            self.item = foundItem 
            return true
        end
    end

    return false
end

function ISWalletAction:update()
    -- Reset hand models to ensure animation looks right
    self.character:setMetabolicTarget(Metabolics.LightWork)

    if not self.soundStarted then
        self.soundStarted = true
        
        if DT_AudioManager then
            DT_AudioManager.PlaySound("CE_CasinoRandom", false, 1.0)
        else
            getSoundManager():PlaySound("CE_CasinoRandom", false, 1.0)
        end
        
        -- DYNAMIC FLAVOR TEXT LOGIC
        if self.isBulk then
            -- In bulk mode: Lower chance (25%) and use "Loop" text (shorter lines)
            -- This prevents spamming "Come on..." 20 times.
            if ZombRand(100) < 45 then
                self.character:Say(GetRandomLine(WalletTalk.BulkLoop))
            end
        else
            -- In single mode: High chance (60%) and use "Anticipation" text
            -- Makes single interactions feel livelier.
            if ZombRand(100) < 70 then
                self.character:Say(GetRandomLine(WalletTalk.Anticipation))
            end
        end
    end
end

function ISWalletAction:start()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(nil, nil)
    self.character:playSound("ClothesRustle")
end

function ISWalletAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISWalletAction:perform()
    -- Ensure item is valid before processing
    if self.item then
        if isClient() then
            local args = { itemID = self.itemID }
            sendClientCommand(self.character, "CurrencyExpanded", "OpenWallet", args)
        else
            ProcessWalletSP(self.character, self.item)
        end
    end
    
    ISBaseTimedAction.perform(self)
end

function ISWalletAction:new(character, item, isBulk)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.isBulk = isBulk or false -- Store the bulk flag
    
    -- Store ID for robust lookup in SP
    if item then
        o.itemID = item:getID()
    end
    
    -- Reduced time slightly for mass opening QoL (was 120)
    o.maxTime = 90 
    o.soundStarted = false 
    return o
end

-- =============================================================================
-- 4. VISUALS HANDLER (Client Side)
-- =============================================================================
local function OnServerCommand(module, command, args)
    if module ~= "CurrencyExpanded" then return end
    
    if command == "WalletResult" then
        local player = getPlayer() 
        if not player then return end

        local total = args.total
        local type = args.type
        local itemID = args.itemID
        local r, g, b = 170, 170, 170 

        if itemID then
            local walletItem = findWalletInPlayerInventory(player, itemID)
            if walletItem then
                markWalletAsSearched(walletItem)
            end
        end

        if ISInventoryPage and ISInventoryPage.dirtyUI then
            ISInventoryPage.dirtyUI()
        end

        if type == "ALREADY_SEARCHED" then
            ShowFloatingText(player, "Already searched", 150, 150, 150)
            return
        end

        if type == "EMPTY" then
            if DT_AudioManager then DT_AudioManager.PlaySound("CE_CasinoLose", false, 1.0) else getSoundManager():PlaySound("CE_CasinoLose", false, 1.0) end
            
            -- Reduced chat spam for mass opening
            if ZombRand(100) < 30 then 
                ForceSay(player, GetRandomLine(WalletTalk.Empty))
            end
            
            ShowFloatingText(player, "Empty", 150, 150, 150)
        else
            if DT_AudioManager then DT_AudioManager.PlaySound("CE_Cashier", false, 1.0) else getSoundManager():PlaySound("CE_Cashier", false, 1.0) end
            
            local maxPossible = math.max(1, SandboxVars.CurrencyExpanded.WalletMaxCash or 300)
            local ratio = total / maxPossible

            if type == "JACKPOT" or ratio >= 0.7 then
                r, g, b = 50, 255, 50 
                ForceSay(player, GetRandomLine(WalletTalk.High))
            elseif ratio >= 0.3 then
                r, g, b = 100, 255, 100 
                if ZombRand(100) < 50 then ForceSay(player, GetRandomLine(WalletTalk.Medium)) end
            else
                r, g, b = 150, 200, 150 
                if ZombRand(100) < 30 then ForceSay(player, GetRandomLine(WalletTalk.Low)) end
            end
            
            local messageText = "+ $" .. tostring(total)
            ShowFloatingText(player, messageText, r, g, b)
        end
    end
end

Events.OnServerCommand.Add(OnServerCommand)

-- =============================================================================
-- 5. CONTEXT MENU & BULK ACTION LOGIC
-- =============================================================================

-- Helper to check if an item is a wallet
local function isWalletItem(item)
    if not item then return false end
    local fullType = item:getFullType()
    return fullType == "Base.Wallet" or fullType == "Base.Wallet_Female" or fullType == "Base.Wallet_Male"
end

local function addDisabledWalletOption(context, text, icon)
    local option = context:addOption(text, nil, nil)
    option.notAvailable = true
    if icon then option.iconTexture = icon end
    return option
end

local function queueWalletAction(playerObj, playerInv, wallet, isBulkOperation)
    if not playerObj or not playerInv or not wallet or not ISWalletAction then
        return false
    end

    if not wallet.getContainer then
        return false
    end

    local sourceContainer = wallet:getContainer()
    if not sourceContainer then
        return false
    end

    if sourceContainer ~= playerInv then
        if not ISInventoryTransferAction then
            return false
        end
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wallet, sourceContainer, playerInv))
    end

    ISTimedActionQueue.add(ISWalletAction:new(playerObj, wallet, isBulkOperation))
    return true
end

-- Helper to actually perform the queue logic
local function OnOpenWallet(items, playerObj, openAll)
    local playerInv = playerObj:getInventory()
    local walletsToOpen = {}

    -- 1. Gather all valid wallets from the selection
    local actualItems = ISInventoryPane.getActualItems(items)
    
    if openAll then
        -- If Open All, we ignore the specific selection and look at the container of the first item selected
        local firstItem = actualItems[1]
        if firstItem and firstItem:getContainer() then
            local containerItems = firstItem:getContainer():getItems()
            for i=0, containerItems:size()-1 do
                local it = containerItems:get(i)
                if isWalletItem(it) and not isWalletSearched(it) then
                    table.insert(walletsToOpen, it)
                end
            end
        end
    else
        -- Just open the specifically selected items
        for _, item in ipairs(actualItems) do
            if isWalletItem(item) and not isWalletSearched(item) then
                table.insert(walletsToOpen, item)
            end
        end
    end
    
    -- 2. Trigger Bulk Start Dialogue (Immediate)
    local count = #walletsToOpen
    local isBulkOperation = (count > 1)
    
    if isBulkOperation then
        ForceSay(playerObj, GetRandomLine(WalletTalk.BulkStart))
    end

    -- 3. Iterate and Queue Actions
    for _, wallet in ipairs(walletsToOpen) do
        queueWalletAction(playerObj, playerInv, wallet, isBulkOperation)
    end
end

local function WalletContextMenu(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not items then return end
    
    local actualItems = ISInventoryPane.getActualItems(items)
    local walletCount = 0
    local searchableWalletCount = 0
    local testItem = nil

    -- Count how many wallets are in the selection to determine menu options
    for _, item in ipairs(actualItems) do
        if isWalletItem(item) then
            walletCount = walletCount + 1
            if not isWalletSearched(item) then
                searchableWalletCount = searchableWalletCount + 1
            end
            testItem = item
        end
    end

    -- If we found at least one wallet
    if walletCount > 0 and testItem then
        local diceIcon = getTexture("Item_Dice")
        
        -- Option 1: Open Selected
        if searchableWalletCount > 0 then
            local text = "Rummage through Wallet"
            if searchableWalletCount > 1 then
                text = "Rummage through Selected Wallets (" .. searchableWalletCount .. ")"
            end
            
            local option = context:addOption(text, items, OnOpenWallet, playerObj, false)
            if diceIcon then option.iconTexture = diceIcon end
        else
            local text = "Wallet Already Empty"
            if walletCount > 1 then
                text = "Selected Wallets Already Empty (" .. walletCount .. ")"
            end
            addDisabledWalletOption(context, text, diceIcon)
        end

        -- Option 2: Open All in Container (Detect if more exist in the container)
        local container = testItem:getContainer()
        if container then
            local totalSearchableWalletsInContainer = 0
            local cItems = container:getItems()
            for i=0, cItems:size()-1 do
                local containerItem = cItems:get(i)
                if isWalletItem(containerItem) and not isWalletSearched(containerItem) then
                    totalSearchableWalletsInContainer = totalSearchableWalletsInContainer + 1
                end
            end

            -- Show the container-wide action when it would process wallets beyond the current selection
            if totalSearchableWalletsInContainer > searchableWalletCount then
                local allText = "Rummage through ALL Wallets (" .. totalSearchableWalletsInContainer .. ")"
                if totalSearchableWalletsInContainer == 1 then
                    allText = "Rummage through Remaining Wallet"
                end
                local allOption = context:addOption(allText, items, OnOpenWallet, playerObj, true)
                if diceIcon then allOption.iconTexture = diceIcon end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(WalletContextMenu)
CurrencyExpanded.Log("CECommons", "Init", "Wallet", "Registered wallet interaction with Smart Flavor Text")
