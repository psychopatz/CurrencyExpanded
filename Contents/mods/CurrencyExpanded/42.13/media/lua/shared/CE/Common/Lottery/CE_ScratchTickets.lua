require "CE/Common/Config/CE_Config"

CurrencyExpanded = CurrencyExpanded or {}
CurrencyExpanded.ScratchTickets = CurrencyExpanded.ScratchTickets or {}

local ScratchTickets = CurrencyExpanded.ScratchTickets

local STATE_KEY = "CE_ScratchState"
local WIN_AMOUNT_KEY = "CE_ScratchWinAmount"
local CLAIMED_KEY = "CE_ScratchClaimed"
local ORIGINAL_NAME_KEY = "CE_ScratchOriginalName"

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function floorNumber(value, fallback)
    local numeric = math.floor(tonumber(value) or fallback or 0)
    return numeric
end

local function safeRandRange(minValue, maxValue)
    local low = floorNumber(minValue, 1)
    local high = floorNumber(maxValue, low)
    if high <= low then
        return low
    end
    return ZombRand(low, high + 1)
end

local function isInventoryItem(value)
    return value and type(value) == "userdata" and value.getFullType ~= nil
end

local function isPlayerObject(value)
    return value and type(value) == "userdata" and value.getInventory ~= nil
end

local function rememberOriginalName(item)
    if not item then return end
    local modData = item:getModData()
    if not modData[ORIGINAL_NAME_KEY] or modData[ORIGINAL_NAME_KEY] == "" then
        modData[ORIGINAL_NAME_KEY] = tostring(item:getName() or "Scratch Ticket")
    end
end

local function syncTicket(item)
    if item and item.syncItemFields then
        item:syncItemFields()
    end
end

local function setTicketPresentation(item, label, tooltip)
    if not item then return end
    rememberOriginalName(item)
    item:setName(label)
    if item.setTooltip then
        item:setTooltip(tooltip)
    end
    syncTicket(item)
end

local function walkCollection(collection, callback)
    if not collection or not callback then return end

    if type(collection) == "table" then
        for _, value in pairs(collection) do
            callback(value)
        end
        return
    end

    if collection.size and collection.get then
        local ok, count = pcall(collection.size, collection)
        if ok and count then
            for index = 0, count - 1 do
                callback(collection:get(index))
            end
        end
    end
end

local function findTicketInValue(value)
    if isInventoryItem(value) and ScratchTickets.IsScratchTicket(value) then
        return value
    end

    if type(value) == "table" or (value and value.size and value.get) then
        local found = nil
        walkCollection(value, function(entry)
            if not found then
                found = findTicketInValue(entry)
            end
        end)
        return found
    end

    return nil
end

local function resolvePlayerFromArgs(args)
    for _, value in ipairs(args) do
        if isPlayerObject(value) then
            return value
        end

        if type(value) == "table" then
            if isPlayerObject(value.character) then
                return value.character
            end
            if isPlayerObject(value.player) then
                return value.player
            end
        end
    end

    return nil
end

local function resolveRecipeTicketFromArgs(args)
    if type(args[1]) == "table" and not isInventoryItem(args[1]) then
        local params = args[1]
        local directResult = findTicketInValue(params.result)
        if directResult then
            return directResult
        end

        local createdItem = findTicketInValue(params.createdItem)
        if createdItem then
            return createdItem
        end

        local selected = findTicketInValue(params.selectedItem)
        if selected then
            return selected
        end

        local items = findTicketInValue(params.items)
        if items then
            return items
        end

        if params.recipeData then
            local inputItems = params.recipeData.getAllInputItems and params.recipeData:getAllInputItems() or nil
            local fromInputs = findTicketInValue(inputItems)
            if fromInputs then
                return fromInputs
            end
        end
    end

    local directSecond = findTicketInValue(args[2])
    if directSecond then
        return directSecond
    end

    local directFirst = findTicketInValue(args[1])
    if directFirst then
        return directFirst
    end

    for _, value in ipairs(args) do
        local candidate = findTicketInValue(value)
        if candidate then
            return candidate
        end
    end

    return nil
end

function ScratchTickets.IsScratchTicket(item)
    if not item then return false end
    local fullType = item:getFullType()
    return fullType == "Base.ScratchTicket"
        or fullType == "Base.ScratchTicket_Winner"
        or fullType == "Base.ScratchTicket_Loser"
end

function ScratchTickets.IsClaimed(item)
    if not item then return false end
    local modData = item:getModData()
    return modData and modData[CLAIMED_KEY] == true
end

function ScratchTickets.IsScratched(item)
    if not item then return false end
    local modData = item:getModData()
    local state = modData and tostring(modData[STATE_KEY] or "")
    return state == "WIN" or state == "LOSE" or state == "CLAIMED"
end

function ScratchTickets.IsClaimable(item)
    if not item or ScratchTickets.IsClaimed(item) then
        return false
    end

    local modData = item:getModData()
    local amount = floorNumber(modData and modData[WIN_AMOUNT_KEY], 0)
    if amount > 0 then
        return true
    end

    return item:getFullType() == "Base.ScratchTicket_Winner"
end

function ScratchTickets.CanScratchItem(item)
    if not item then return false end
    if item:getFullType() ~= "Base.ScratchTicket" then
        return false
    end
    return not ScratchTickets.IsScratched(item)
end

function ScratchTickets.GetWinAmount(item)
    if not item then return 0 end
    local modData = item:getModData()
    return math.max(0, floorNumber(modData and modData[WIN_AMOUNT_KEY], 0))
end

function ScratchTickets.GetWinChance()
    local chance = tonumber(SandboxVars.CurrencyExpanded.ScratchTicketWinChance or 15.0) or 15.0
    return clamp(chance, 0.0, 100.0)
end

function ScratchTickets.GetWinRange()
    local minWin = math.max(1, floorNumber(SandboxVars.CurrencyExpanded.ScratchTicketMinWin, 25))
    local maxWin = math.max(minWin, floorNumber(SandboxVars.CurrencyExpanded.ScratchTicketMaxWin, minWin))
    return minWin, maxWin
end

function ScratchTickets.RollGuaranteedWinAmount()
    local minWin, maxWin = ScratchTickets.GetWinRange()
    return safeRandRange(minWin, maxWin)
end

function ScratchTickets.RollScratchOutcome(player)
    local didWin = ZombRandFloat(0.0, 100.0) < ScratchTickets.GetWinChance()
    if didWin then
        return ScratchTickets.RollGuaranteedWinAmount(), "WIN"
    end
    return 0, "LOSE"
end

function ScratchTickets.MarkWinner(item, amount)
    if not item then return end
    local payout = math.max(1, floorNumber(amount, ScratchTickets.RollGuaranteedWinAmount()))
    local modData = item:getModData()
    modData[STATE_KEY] = "WIN"
    modData[WIN_AMOUNT_KEY] = payout
    modData[CLAIMED_KEY] = false
    setTicketPresentation(item, "Scratch Ticket - Winner ($" .. tostring(payout) .. ")", "Claim this payout from a qualified trader.")
end

function ScratchTickets.MarkLoser(item)
    if not item then return end
    local modData = item:getModData()
    modData[STATE_KEY] = "LOSE"
    modData[WIN_AMOUNT_KEY] = 0
    modData[CLAIMED_KEY] = false
    setTicketPresentation(item, "Scratch Ticket - Loser", "No payout on this ticket.")
end

function ScratchTickets.MarkClaimed(item)
    if not item then return end
    local modData = item:getModData()
    modData[STATE_KEY] = "CLAIMED"
    modData[CLAIMED_KEY] = true
    modData[WIN_AMOUNT_KEY] = 0
    setTicketPresentation(item, "Claimed Scratch Ticket", "This ticket has already been paid out.")
end

function ScratchTickets.NormalizePreRolledTicket(item)
    if not item then return end
    if ScratchTickets.IsClaimed(item) then return end

    local fullType = item:getFullType()
    if fullType == "Base.ScratchTicket_Winner" and ScratchTickets.GetWinAmount(item) <= 0 then
        ScratchTickets.MarkWinner(item, ScratchTickets.RollGuaranteedWinAmount())
    elseif fullType == "Base.ScratchTicket_Loser" and not ScratchTickets.IsScratched(item) then
        ScratchTickets.MarkLoser(item)
    end
end

function ScratchTickets.CollectPotentialWinners(container, results)
    if not container or not results then return end

    local items = container.getItems and container:getItems() or nil
    if not items then return end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if ScratchTickets.IsClaimable(item) then
            table.insert(results, item)
        end

        local innerContainer = item.getItemContainer and item:getItemContainer() or nil
        if innerContainer then
            ScratchTickets.CollectPotentialWinners(innerContainer, results)
        end
    end
end

function ScratchTickets.CountPotentialWinners(player)
    if not player or not player.getInventory then return 0 end
    local results = {}
    ScratchTickets.CollectPotentialWinners(player:getInventory(), results)
    return #results
end

RecipeCodeOnCreate = RecipeCodeOnCreate or {}
RecipeCodeOnTest = RecipeCodeOnTest or {}
ItemCodeOnCreate = ItemCodeOnCreate or {}

function RecipeCodeOnTest.scratchTicket(item, ...)
    local target = item
    if not isInventoryItem(target) then
        target = resolveRecipeTicketFromArgs({ item, ... })
    end
    return ScratchTickets.CanScratchItem(target)
end

function RecipeCodeOnCreate.scratchTicket(...)
    local args = { ... }
    local ticket = resolveRecipeTicketFromArgs(args)
    if not ticket or not ScratchTickets.CanScratchItem(ticket) then
        return
    end

    local player = resolvePlayerFromArgs(args)
    local amount, resultType = ScratchTickets.RollScratchOutcome(player)
    if resultType == "WIN" then
        ScratchTickets.MarkWinner(ticket, amount)
    else
        ScratchTickets.MarkLoser(ticket)
    end
end

function ItemCodeOnCreate.scratchTicketWinner(item)
    if ScratchTickets.IsScratchTicket(item) then
        ScratchTickets.NormalizePreRolledTicket(item)
    end
end

return ScratchTickets
