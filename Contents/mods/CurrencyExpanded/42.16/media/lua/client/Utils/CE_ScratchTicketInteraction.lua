require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISInventoryTransferAction"
require "DT/Common/Utils/DT_AudioManager"
require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"
require "CE/Common/InteractionStrings/Lottery/CE_InteractionStrings_Lottery_ScratchTicket"

local ScratchTickets = CurrencyExpanded.ScratchTickets or {}
local ScratchTalk = CurrencyExpanded.GetInteractionStrings("Lottery", "ScratchTicket") or {}

if DT_AudioManager and DT_AudioManager.RegisterCategory then
    DT_AudioManager.RegisterCategory("CE_Casino", "Wallet")
    DT_AudioManager.RegisterCategory("CE_Cashier", "Wallet")
end

local function getLocalPlayer()
    return getPlayer() or getSpecificPlayer(0)
end

local function getRandomLine(category)
    if not category or #category == 0 then
        return "..."
    end

    return category[ZombRand(#category) + 1]
end

local function forceSay(player, text)
    if not player or not text or text == "" then
        return
    end

    if player.setSpeakTime then
        player:setSpeakTime(0)
    end

    player:Say(text)
end

local function queueScratchTicketAction(playerObj, playerInv, ticket, isBulk)
    if not playerObj or not playerInv or not ticket or not ISScratchTicketAction then
        return false
    end

    if not ticket.getContainer then
        return false
    end

    local sourceContainer = ticket:getContainer()
    if not sourceContainer then
        return false
    end

    if sourceContainer ~= playerInv then
        if not ISInventoryTransferAction then
            return false
        end
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, ticket, sourceContainer, playerInv))
    end

    ISTimedActionQueue.add(ISScratchTicketAction:new(playerObj, ticket, isBulk))
    return true
end

local function playUISound(soundName)
    if not soundName or soundName == "" then
        return
    end

    if DT_AudioManager and DT_AudioManager.PlaySound then
        DT_AudioManager.PlaySound(soundName, false, 1.0)
    elseif getSoundManager() then
        getSoundManager():PlaySound(soundName, false, 1.0)
    end
end

local function showScratchFeedback(player, args)
    if not player then return end

    local status = tostring(args and args.status or "")
    local resultType = tostring(args and args.resultType or "LOSE")
    local tier = tostring(args and args.tier or (resultType == "JACKPOT" and "JACKPOT" or "LOW"))
    local amount = math.max(0, tonumber(args and args.amount) or 0)

    if status == "ALREADY_SCRATCHED" then
        player:setHaloNote("Already scratched", 150, 150, 150, 300)
        if ZombRand(100) < 45 then
            forceSay(player, getRandomLine(ScratchTalk.AlreadyScratched))
        end
        return
    end

    if resultType == "LOSE" then
        playUISound("CE_CasinoLose")
        player:setHaloNote("Loser", 170, 170, 170, 300)
        if ZombRand(100) < 60 then
            forceSay(player, getRandomLine(ScratchTalk.Lose))
        end
        return
    end

    playUISound("CE_Cashier")

    local r, g, b = 90, 220, 90
    if tier == "JACKPOT" then
        r, g, b = 50, 255, 50
        forceSay(player, getRandomLine(ScratchTalk.Jackpot))
    elseif tier == "HIGH" then
        r, g, b = 90, 240, 90
        forceSay(player, getRandomLine(ScratchTalk.High))
    elseif tier == "MEDIUM" then
        r, g, b = 120, 235, 120
        if ZombRand(100) < 65 then
            forceSay(player, getRandomLine(ScratchTalk.Medium))
        end
    else
        r, g, b = 150, 220, 150
        if ZombRand(100) < 45 then
            forceSay(player, getRandomLine(ScratchTalk.Low))
        end
    end

    player:setHaloNote("+ $" .. tostring(amount), r, g, b, 300)
end

local function findTicketInPlayerInventory(player, itemID)
    if not player or not itemID or not player.getInventory then
        return nil
    end

    local inv = player:getInventory()
    if not inv then
        return nil
    end

    return inv:getItemById(itemID)
end

local function processScratchSP(player, item)
    if not player or not item then
        return
    end

    if not ScratchTickets.CanScratchItem(item) then
        triggerEvent("OnServerCommand", "CurrencyExpanded", "ScratchTicketResult", {
            status = "ALREADY_SCRATCHED",
            itemID = item:getID(),
            amount = ScratchTickets.GetWinAmount(item),
            resultType = ScratchTickets.GetWinAmount(item) > 0 and "WIN" or "LOSE",
            tier = ScratchTickets.GetWinAmount(item) > 0 and "HIGH" or "LOSE"
        })
        return
    end

    local amount, resultType, tier = ScratchTickets.RollScratchOutcome(player)
    if resultType == "LOSE" then
        ScratchTickets.MarkLoser(item)
    else
        ScratchTickets.MarkWinner(item, amount)
    end

    ScratchTickets.RecordScratchResult(player, amount, resultType, tier)

    if ISInventoryPage and ISInventoryPage.dirtyUI then
        ISInventoryPage.dirtyUI()
    end

    triggerEvent("OnServerCommand", "CurrencyExpanded", "ScratchTicketResult", {
        status = "SCRATCHED",
        itemID = item:getID(),
        amount = amount,
        resultType = resultType,
        tier = tier
    })
end

ISScratchTicketAction = ISBaseTimedAction:derive("ISScratchTicketAction")

function ISScratchTicketAction:isValid()
    if not self.character then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    if self.item and ScratchTickets.CanScratchItem(self.item) and inv:contains(self.item) then
        return true
    end

    if self.itemID then
        local foundItem = inv:getItemById(self.itemID)
        if foundItem and ScratchTickets.CanScratchItem(foundItem) then
            self.item = foundItem
            return true
        end
    end

    return false
end

function ISScratchTicketAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)

    if not self.soundStarted then
        self.soundStarted = true
        playUISound("CE_CasinoRandom")

        if self.isBulk then
            if ZombRand(100) < 45 then
                forceSay(self.character, getRandomLine(ScratchTalk.BulkLoop))
            end
        elseif ZombRand(100) < 70 then
            forceSay(self.character, getRandomLine(ScratchTalk.Anticipation))
        end
    end
end

function ISScratchTicketAction:start()
    self:setActionAnim("Loot")
    self:setOverrideHandModels(nil, nil)
    self.character:playSound("ClothesRustle")
end

function ISScratchTicketAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISScratchTicketAction:perform()
    if self.item then
        if isClient() then
            sendClientCommand(self.character, "CurrencyExpanded", "ScratchTicket", {
                itemID = self.itemID
            })
        else
            processScratchSP(self.character, self.item)
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISScratchTicketAction:new(character, item, isBulk)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.itemID = item and item:getID() or nil
    o.isBulk = isBulk or false
    o.maxTime = 65
    o.soundStarted = false
    return o
end

local function OnServerCommand(module, command, args)
    if module ~= "CurrencyExpanded" or command ~= "ScratchTicketResult" then
        return
    end

    local player = getLocalPlayer()
    if not player then
        return
    end

    local ticket = findTicketInPlayerInventory(player, args and args.itemID or nil)
    local status = tostring(args and args.status or "")
    local resultType = tostring(args and args.resultType or "LOSE")
    local tier = tostring(args and args.tier or (resultType == "JACKPOT" and "JACKPOT" or "LOW"))

    if ticket then
        if status == "SCRATCHED" then
            if resultType == "LOSE" then
                ScratchTickets.MarkLoser(ticket)
            else
                ScratchTickets.MarkWinner(ticket, tonumber(args and args.amount) or 0)
            end
        else
            ScratchTickets.NormalizePreRolledTicket(ticket)
        end
    end

    if ISInventoryPage and ISInventoryPage.dirtyUI then
        ISInventoryPage.dirtyUI()
    end

    showScratchFeedback(player, {
        status = status,
        itemID = args and args.itemID or nil,
        amount = args and args.amount or 0,
        resultType = resultType,
        tier = tier
    })
end

Events.OnServerCommand.Add(OnServerCommand)

local function addDisabledOption(context, text, icon)
    local option = context:addOption(text, nil, nil)
    option.notAvailable = true
    if icon then
        option.iconTexture = icon
    end
    return option
end

local function appendResolvedItems(source, results, seen)
    if not source then
        return
    end

    if source.getFullType then
        local itemID = source.getID and source:getID() or tostring(source)
        if not seen[itemID] then
            seen[itemID] = true
            table.insert(results, source)
        end
        return
    end

    if type(source) ~= "table" then
        return
    end

    local wrappedItems = rawget(source, "items")
    if wrappedItems and wrappedItems ~= source then
        if wrappedItems.getFullType then
            appendResolvedItems(wrappedItems, results, seen)
        else
            for _, value in ipairs(wrappedItems) do
                appendResolvedItems(value, results, seen)
            end
        end
    end

    for _, value in ipairs(source) do
        appendResolvedItems(value, results, seen)
    end
end

local function resolveSelectedScratchItems(items)
    local resolved = {}
    local seen = {}

    if ISInventoryPane and ISInventoryPane.getActualItems then
        appendResolvedItems(ISInventoryPane.getActualItems(items), resolved, seen)
    end

    if #resolved == 0 then
        appendResolvedItems(items, resolved, seen)
    end
    return resolved
end

local function onScratchTickets(items, playerObj, scratchAll)
    if not playerObj or not items then
        return
    end

    local playerInv = playerObj:getInventory()
    if not playerInv then
        return
    end

    local actualItems = resolveSelectedScratchItems(items)
    local ticketsToScratch = {}

    if scratchAll then
        local firstItem = actualItems[1]
        local container = firstItem and firstItem:getContainer() or nil
        local containerItems = container and container:getItems() or nil

        if containerItems then
            for index = 0, containerItems:size() - 1 do
                local item = containerItems:get(index)
                if ScratchTickets.CanScratchItem(item) then
                    table.insert(ticketsToScratch, item)
                end
            end
        end
    else
        for _, item in ipairs(actualItems) do
            if ScratchTickets.CanScratchItem(item) then
                table.insert(ticketsToScratch, item)
            end
        end
    end

    if #ticketsToScratch > 1 then
        forceSay(playerObj, getRandomLine(ScratchTalk.BulkStart))
    end

    for _, ticket in ipairs(ticketsToScratch) do
        queueScratchTicketAction(playerObj, playerInv, ticket, #ticketsToScratch > 1)
    end
end

local function ScratchTicketContextMenu(playerIndex, context, items)
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj or not items then
        return
    end

    local actualItems = resolveSelectedScratchItems(items)
    local ticketCount = 0
    local scratchableCount = 0
    local testItem = nil

    for _, item in ipairs(actualItems) do
        if ScratchTickets.IsScratchTicket(item) then
            ticketCount = ticketCount + 1
            if ScratchTickets.CanScratchItem(item) then
                scratchableCount = scratchableCount + 1
            end
            testItem = item
        end
    end

    if ticketCount <= 0 or not testItem then
        return
    end

    local scratchIcon = getTexture("Item_ScratchTicket") or getTexture("Item_Dice")

    if scratchableCount > 0 then
        local text = "Carefully Scratch Ticket"
        if scratchableCount > 1 then
            text = "Carefully Scratch Selected Tickets (" .. scratchableCount .. ")"
        end

        local option = context:addOption(text, items, onScratchTickets, playerObj, false)
        if scratchIcon then
            option.iconTexture = scratchIcon
        end
    else
        local text = "Selected Tickets Already Scratched"
        if ticketCount == 1 then
            text = "Ticket Already Scratched"
        end
        addDisabledOption(context, text, scratchIcon)
    end

    local container = testItem:getContainer()
    local containerItems = container and container:getItems() or nil
    if not containerItems then
        return
    end

    local totalScratchableInContainer = 0
    for index = 0, containerItems:size() - 1 do
        local item = containerItems:get(index)
        if ScratchTickets.CanScratchItem(item) then
            totalScratchableInContainer = totalScratchableInContainer + 1
        end
    end

    if totalScratchableInContainer > scratchableCount then
        local allText = "Carefully Scratch ALL Tickets (" .. totalScratchableInContainer .. ")"
        if totalScratchableInContainer == 1 then
            allText = "Carefully Scratch Remaining Ticket"
        end

        local allOption = context:addOption(allText, items, onScratchTickets, playerObj, true)
        if scratchIcon then
            allOption.iconTexture = scratchIcon
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ScratchTicketContextMenu)
CurrencyExpanded.Log("CECommons", "Init", "ScratchTicket", "Registered custom scratch ticket interaction")
