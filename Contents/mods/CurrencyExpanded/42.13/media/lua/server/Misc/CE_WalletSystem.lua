-- =============================================================================
-- DYNAMIC TRADING: WALLET SYSTEM (SERVER SIDE)
-- =============================================================================

require "DT/Common/ServerHelpers/ServerHelpers"
require "CE/Common/Config/CE_Config"
require "CE/Common/Wallet/CE_WalletLottery"

local Commands = {}
local Helpers = CurrencyExpanded.ServerHelpers
local WALLET_SEARCHED_KEY = "CE_WalletSearched"
local WALLET_ORIGINAL_NAME_KEY = "CE_WalletOriginalName"
local WalletLottery = CurrencyExpanded.WalletLottery or {}

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

    if item.syncItemFields then
        item:syncItemFields()
    end
end

-- =============================================================================
-- 2. COMMAND HANDLER
-- =============================================================================
function Commands.OpenWallet(player, args)
    local inv = player:getInventory()
    local requestedItemID = args and args.itemID or nil

    if not requestedItemID and args and args.item and args.item.getID then
        requestedItemID = args.item:getID()
    end
    
    -- Find the true Server-side object
    local serverItem = requestedItemID and inv:getItemById(requestedItemID) or nil
    
    if not serverItem then 
        CurrencyExpanded.Log("CECommons", "Error", "Wallet", "Wallet item not found on server")
        return 
    end

    if isWalletSearched(serverItem) then
        local resultArgs = {
            total = 0,
            type = "ALREADY_SEARCHED",
            itemID = serverItem:getID()
        }
        Helpers.SendResponse(player, "CurrencyExpanded", "WalletResult", resultArgs)
        return
    end

    -- A. CALCULATE LOOT FIRST
    if not WalletLottery.Roll then
        CurrencyExpanded.Log("CECommons", "Error", "Wallet", "Wallet lottery module unavailable")
        return
    end

    local totalMoney, type = WalletLottery.Roll(player)

    -- B. MARK WALLET AS SEARCHED INSTEAD OF REMOVING IT
    markWalletAsSearched(serverItem)

    -- C. ADD MONEY (using shared helper)
    if totalMoney > 0 then
        local bundles = math.floor(totalMoney / 100)
        local looseCash = totalMoney % 100

        if bundles > 0 then 
            Helpers.AddItem(inv, "Base.MoneyBundle", bundles)
        end
        if looseCash > 0 then 
            Helpers.AddItem(inv, "Base.Money", looseCash)
        end
    end

    -- D. SEND FEEDBACK TO CLIENT (using shared helper)
    local resultArgs = {
        total = totalMoney,
        type = type,
        itemID = serverItem:getID()
    }
    Helpers.SendResponse(player, "CurrencyExpanded", "WalletResult", resultArgs)
end

-- =============================================================================
-- 3. EVENT LISTENER
-- =============================================================================
local function OnClientCommand(module, command, player, args)
    if module == "CurrencyExpanded" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

CurrencyExpanded.Log("CECommons", "Init", "Wallet", "Registered wallet system")
