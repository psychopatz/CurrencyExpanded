require "CE/Common/Config/CE_Config"

CurrencyExpanded = CurrencyExpanded or {}
CurrencyExpanded.ScratchTickets = CurrencyExpanded.ScratchTickets or {}

local ScratchTickets = CurrencyExpanded.ScratchTickets

local STATE_KEY = "CE_ScratchState"
local WIN_AMOUNT_KEY = "CE_ScratchWinAmount"
local CLAIMED_KEY = "CE_ScratchClaimed"
local ORIGINAL_NAME_KEY = "CE_ScratchOriginalName"
local VISUAL_TYPE_KEY = "CE_ScratchVisualType"
local CUSTOM_TICKET_FULL_TYPE = "CE.ScratchTicket"
local SCRATCH_LOTTERY_STATE_KEY = "CE_ScratchLotteryState"
local LOTTERY_LEDGER_KEY = "CurrencyExpanded_ScratchLottery"
local WEEK_HOURS = 24 * 7
local MAX_WEEKLY_WINNERS = 16
local FALLBACK_NPC_WINNERS = {
    "Riley Mercer",
    "June Holloway",
    "Wade Barrett",
    "Elsie Monroe",
    "Cal Mercer",
    "Nina Doyle",
    "Frank Harlow",
    "Mara Bishop"
}

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

local function getSandbox()
    SandboxVars = SandboxVars or {}
    SandboxVars.CurrencyExpanded = SandboxVars.CurrencyExpanded or {}
    return SandboxVars.CurrencyExpanded
end

local function roundMoney(value)
    local amount = math.max(0, floorNumber(value, 0))
    if amount <= 10 then
        return amount
    end

    local rounded = math.floor((amount + 2) / 5) * 5
    return math.max(5, rounded)
end

local function currentWeekIndex()
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and gameTime.getWorldAgeHours and gameTime:getWorldAgeHours() or 0
    return math.max(0, math.floor((tonumber(hours) or 0) / WEEK_HOURS))
end

local function ensureTableSlot(data, key)
    if type(data[key]) ~= "table" then
        data[key] = {}
    end
    return data[key]
end

local function ensureLotteryLedger()
    ScratchTickets._localLotteryLedger = ScratchTickets._localLotteryLedger or {}

    local data = ScratchTickets._localLotteryLedger
    if ModData and ModData.exists and ModData.get and ModData.add then
        if not ModData.exists(LOTTERY_LEDGER_KEY) then
            ModData.add(LOTTERY_LEDGER_KEY, {})
        end
        data = ModData.get(LOTTERY_LEDGER_KEY) or data
        ScratchTickets._localLotteryLedger = data
    end

    local weekIndex = currentWeekIndex()
    data.weekIndex = floorNumber(data.weekIndex, weekIndex)
    data.jackpotPool = math.max(0, floorNumber(data.jackpotPool, 0))
    data.totalScratches = math.max(0, floorNumber(data.totalScratches, 0))
    data.lastJackpotAmount = math.max(0, floorNumber(data.lastJackpotAmount, 0))
    ensureTableSlot(data, "winners")
    ensureTableSlot(data, "seededNames")

    if data.weekIndex ~= weekIndex then
        data.weekIndex = weekIndex
        data.winners = {}
        data.seededNames = {}
        data.totalScratches = 0
    end

    return data
end

local function getPlayerDisplayName(player)
    if not player then
        return "Unknown Survivor"
    end

    if player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then
            return username
        end
    end

    local descriptor = player.getDescriptor and player:getDescriptor() or nil
    if descriptor then
        local forename = tostring((descriptor.getForename and descriptor:getForename()) or "")
        local surname = tostring((descriptor.getSurname and descriptor:getSurname()) or "")
        local fullName = (forename .. " " .. surname):gsub("^%s+", ""):gsub("%s+$", "")
        if fullName ~= "" then
            return fullName
        end
    end

    if player.getFullName then
        local fullName = tostring(player:getFullName() or "")
        if fullName ~= "" then
            return fullName
        end
    end

    return "Unknown Survivor"
end

local function getRosterNames()
    local names = {}
    local seen = {}
    local roster = ModData and ModData.get and ModData.get("DynamicTrading_Roster") or nil
    local souls = roster and roster.Souls or nil

    if type(souls) == "table" then
        for _, soul in pairs(souls) do
            local name = soul and tostring(soul.name or "") or ""
            if name ~= "" and not seen[name] then
                seen[name] = true
                table.insert(names, name)
            end
        end
    end

    if #names == 0 then
        for _, name in ipairs(FALLBACK_NPC_WINNERS) do
            table.insert(names, name)
        end
    end

    return names
end

local function getJackpotChance()
    local value = tonumber(getSandbox().ScratchTicketJackpotChance or 2.5) or 2.5
    return clamp(value, 0.0, 100.0)
end

local function getJackpotBaseMultiplier()
    local value = tonumber(getSandbox().ScratchTicketJackpotBaseMultiplier or 1.25) or 1.25
    return clamp(value, 1.0, 10.0)
end

local function getJackpotGrowthPerScratch()
    local value = floorNumber(getSandbox().ScratchTicketJackpotGrowthPerScratch, 25)
    return math.max(0, value)
end

local function getTierWeights()
    local sandbox = getSandbox()
    local low = math.max(1, floorNumber(sandbox.ScratchTicketLowTierWeight, 60))
    local medium = math.max(1, floorNumber(sandbox.ScratchTicketMediumTierWeight, 28))
    local high = math.max(1, floorNumber(sandbox.ScratchTicketHighTierWeight, 12))
    local total = low + medium + high

    return {
        low = (low / total) * 100,
        medium = (medium / total) * 100,
        high = (high / total) * 100
    }
end

local function getTierCeilings()
    local sandbox = getSandbox()
    local lowPct = clamp(tonumber(sandbox.ScratchTicketLowTierMaxPercent or 22) or 22, 5, 60)
    local mediumPct = clamp(tonumber(sandbox.ScratchTicketMediumTierMaxPercent or 55) or 55, lowPct + 5, 85)
    local highPct = clamp(tonumber(sandbox.ScratchTicketHighTierMaxPercent or 82) or 82, mediumPct + 5, 95)
    return lowPct / 100.0, mediumPct / 100.0, highPct / 100.0
end

local function getTierBounds(minWin, maxWin)
    local lowPct, mediumPct, highPct = getTierCeilings()
    local range = math.max(0, maxWin - minWin)
    local lowMax = roundMoney(minWin + math.floor(range * lowPct))
    local mediumMax = roundMoney(minWin + math.floor(range * mediumPct))
    local highMax = roundMoney(minWin + math.floor(range * highPct))

    lowMax = clamp(lowMax, minWin, maxWin)
    mediumMax = clamp(mediumMax, lowMax, maxWin)
    highMax = clamp(highMax, mediumMax, maxWin)

    local mediumMin = math.min(maxWin, math.max(minWin, lowMax + 5))
    local highMin = math.min(maxWin, math.max(mediumMin, mediumMax + 5))

    if mediumMin > mediumMax then
        mediumMin = mediumMax
    end

    if highMin > highMax then
        highMin = highMax
    end

    return {
        lowMin = minWin,
        lowMax = lowMax,
        mediumMin = mediumMin,
        mediumMax = mediumMax,
        highMin = highMin,
        highMax = highMax
    }
end

local function insertWinnerEntry(ledger, entry)
    if not ledger or type(entry) ~= "table" then
        return
    end

    local winners = ensureTableSlot(ledger, "winners")
    table.insert(winners, 1, entry)

    while #winners > MAX_WEEKLY_WINNERS do
        table.remove(winners)
    end
end

local function buildNPCWinnerAmount()
    local minWin, maxWin = ScratchTickets.GetWinRange()
    local tierBounds = getTierBounds(minWin, maxWin)
    local roll = ZombRand(100)
    local amount = tierBounds.mediumMin
    local tier = "MEDIUM"

    if roll < 20 then
        tier = "LOW"
        amount = safeRandRange(tierBounds.lowMin, tierBounds.lowMax)
    elseif roll < 80 then
        tier = "MEDIUM"
        amount = safeRandRange(tierBounds.mediumMin, tierBounds.mediumMax)
    else
        tier = "HIGH"
        amount = safeRandRange(tierBounds.highMin, tierBounds.highMax)
    end

    return roundMoney(amount), tier
end

local function ensureSeededWinners(ledger)
    if not ledger then
        return
    end

    local seededNames = ensureTableSlot(ledger, "seededNames")
    local desiredSeeds = 4
    local rosterNames = getRosterNames()

    if #rosterNames == 0 then
        return
    end

    while #seededNames < desiredSeeds and #seededNames < #rosterNames do
        local candidate = rosterNames[ZombRand(#rosterNames) + 1]
        local exists = false
        for _, name in ipairs(seededNames) do
            if name == candidate then
                exists = true
                break
            end
        end

        if not exists then
            local amount, tier = buildNPCWinnerAmount()
            table.insert(seededNames, candidate)
            insertWinnerEntry(ledger, {
                name = candidate,
                amount = amount,
                tier = tier,
                resultType = "WIN",
                kind = "NPC",
                weekIndex = ledger.weekIndex
            })
        end
    end
end

local function aggregateWinners(entries, limit)
    local buckets = {}
    local results = {}
    local activeWeekIndex = currentWeekIndex()

    for _, entry in ipairs(entries or {}) do
        local name = tostring(entry and entry.name or "")
        local entryWeekIndex = floorNumber(entry and entry.weekIndex, activeWeekIndex)
        if name ~= "" and entryWeekIndex == activeWeekIndex then
            local key = tostring(entry.kind or "NPC") .. "|" .. name
            local entryAmount = math.max(0, floorNumber(entry.amount, 0))
            if not buckets[key] then
                buckets[key] = {
                    name = name,
                    amount = entryAmount,
                    bestAmount = entryAmount,
                    tier = tostring(entry.tier or "LOW"),
                    resultType = tostring(entry.resultType or "WIN"),
                    kind = tostring(entry.kind or "NPC"),
                    hits = 1,
                    weekIndex = entryWeekIndex
                }
                table.insert(results, buckets[key])
            else
                local bucket = buckets[key]
                bucket.hits = bucket.hits + 1
                bucket.amount = bucket.amount + entryAmount
                if entryAmount > bucket.bestAmount then
                    bucket.bestAmount = entryAmount
                    bucket.tier = tostring(entry.tier or bucket.tier)
                    bucket.resultType = tostring(entry.resultType or bucket.resultType)
                end
            end
        end
    end

    table.sort(results, function(left, right)
        if left.amount == right.amount then
            return tostring(left.name) < tostring(right.name)
        end
        return left.amount > right.amount
    end)

    if limit and #results > limit then
        while #results > limit do
            table.remove(results)
        end
    end

    return results
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

local function getScriptItem(fullType)
    if not fullType or fullType == "" then
        return nil
    end

    local manager = ScriptManager and ScriptManager.instance or (getScriptManager and getScriptManager())
    if manager and manager.FindItem then
        return manager:FindItem(fullType)
    end

    return nil
end

local function applyTicketVisual(item, fullType)
    if not item then return end

    local modData = item:getModData()
    modData[VISUAL_TYPE_KEY] = fullType

    local scriptItem = getScriptItem(fullType)
    if not scriptItem then
        return
    end

    local texture = scriptItem.getNormalTexture and scriptItem:getNormalTexture() or nil
    if texture and item.setTexture then
        item:setTexture(texture)
    end

    local worldModel = scriptItem.getStaticModel and scriptItem:getStaticModel() or nil
    if worldModel and worldModel ~= "" and item.setWorldStaticModel then
        item:setWorldStaticModel(worldModel)
    end
end

local function getDefaultVisualType(item)
    if item and item.getFullType and item:getFullType() == CUSTOM_TICKET_FULL_TYPE then
        return CUSTOM_TICKET_FULL_TYPE
    end

    return "Base.ScratchTicket"
end

local function setTicketPresentation(item, label, tooltip, visualType)
    if not item then return end
    rememberOriginalName(item)
    item:setName(label)
    if item.setTooltip then
        item:setTooltip(tooltip)
    end
    if visualType then
        applyTicketVisual(item, visualType)
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

local function ensureScratchState(player)
    if not player or not player.getModData then return nil end

    local modData = player:getModData()
    if not modData then return nil end

    if type(modData[SCRATCH_LOTTERY_STATE_KEY]) ~= "table" then
        modData[SCRATCH_LOTTERY_STATE_KEY] = {
            scratches = 0,
            dryStreak = 0,
            hotStreak = 0,
            jackpotCooldown = 0,
            lastResult = "NONE"
        }
    end

    return modData[SCRATCH_LOTTERY_STATE_KEY]
end

local function getScratchTier(amount, maxWin, resultType)
    if resultType == "LOSE" then
        return "LOSE"
    end

    if resultType == "JACKPOT" then
        return "JACKPOT"
    end

    local ratio = (tonumber(amount) or 0) / math.max(1, tonumber(maxWin) or 1)
    if ratio >= 0.7 then
        return "HIGH"
    elseif ratio >= 0.3 then
        return "MEDIUM"
    end

    return "LOW"
end

local function updateScratchState(state, resultType, tier)
    if not state then return end

    local nextCooldown = math.max((tonumber(state.jackpotCooldown) or 0) - 1, 0)
    state.scratches = (tonumber(state.scratches) or 0) + 1

    if resultType == "LOSE" then
        state.dryStreak = math.min((tonumber(state.dryStreak) or 0) + 1, 14)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "LOSE"
        return
    end

    if tier == "JACKPOT" then
        state.dryStreak = 0
        state.hotStreak = math.min((tonumber(state.hotStreak) or 0) + 3, 9)
        state.jackpotCooldown = 4
        state.lastResult = "JACKPOT"
    elseif tier == "HIGH" then
        state.dryStreak = 0
        state.hotStreak = math.min((tonumber(state.hotStreak) or 0) + 2, 9)
        state.jackpotCooldown = math.max(nextCooldown, 1)
        state.lastResult = "HIGH"
    elseif tier == "MEDIUM" then
        state.dryStreak = math.max((tonumber(state.dryStreak) or 0) - 2, 0)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "MEDIUM"
    else
        state.dryStreak = math.max((tonumber(state.dryStreak) or 0) - 1, 0)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "LOW"
    end
end

function ScratchTickets.GetCurrentJackpotAmount()
    local _, maxWin = ScratchTickets.GetWinRange()
    local baseAmount = roundMoney(maxWin * getJackpotBaseMultiplier())
    local ledger = ensureLotteryLedger()
    ensureSeededWinners(ledger)
    return math.max(baseAmount, baseAmount + math.max(0, floorNumber(ledger and ledger.jackpotPool, 0)))
end

function ScratchTickets.GetWeeklyWinners(limit)
    local ledger = ensureLotteryLedger()
    ensureSeededWinners(ledger)
    return aggregateWinners(ledger and ledger.winners or {}, limit or 6)
end

function ScratchTickets.GetLotteryInfoSnapshot(limit)
    local minWin, maxWin = ScratchTickets.GetWinRange()
    local bounds = getTierBounds(minWin, maxWin)
    return {
        jackpot = ScratchTickets.GetCurrentJackpotAmount(),
        commonLowMax = bounds.lowMax,
        commonMediumMax = bounds.mediumMax,
        commonHighMax = bounds.highMax,
        commonMin = minWin,
        commonMax = maxWin,
        winners = ScratchTickets.GetWeeklyWinners(limit or 6)
    }
end

function ScratchTickets.RecordScratchResult(player, amount, resultType, tier)
    local ledger = ensureLotteryLedger()
    if not ledger then
        return
    end

    ensureSeededWinners(ledger)
    ledger.totalScratches = math.max(0, floorNumber(ledger.totalScratches, 0)) + 1

    if tostring(resultType or "") == "JACKPOT" then
        ledger.lastJackpotAmount = math.max(0, floorNumber(amount, 0))
        ledger.jackpotPool = 0
    else
        ledger.jackpotPool = math.max(0, floorNumber(ledger.jackpotPool, 0)) + getJackpotGrowthPerScratch()
    end

    local payout = math.max(0, floorNumber(amount, 0))
    if payout > 0 then
        insertWinnerEntry(ledger, {
            name = getPlayerDisplayName(player),
            amount = payout,
            tier = tostring(tier or "LOW"),
            resultType = tostring(resultType or "WIN"),
            kind = "PLAYER",
            weekIndex = ledger.weekIndex
        })
    end
end

local function findTicketInFields(source, fieldNames)
    if type(source) ~= "table" or type(fieldNames) ~= "table" then
        return nil
    end

    for _, fieldName in ipairs(fieldNames) do
        local candidate = findTicketInValue(source[fieldName])
        if candidate then
            return candidate
        end
    end

    return nil
end

local function resolveRecipeTicketFromArgs(args)
    if type(args[1]) == "table" and not isInventoryItem(args[1]) then
        local params = args[1]
        local directResult = findTicketInFields(params, {
            "result",
            "results",
            "output",
            "outputs",
            "outputItem",
            "outputItems",
            "createdItem",
            "createdItems"
        })
        if directResult then
            return directResult
        end

        local selected = findTicketInFields(params, {
            "selectedItem",
            "selectedItems",
            "item",
            "items",
            "inventoryItem",
            "inventoryItems"
        })
        if selected then
            return selected
        end

        if params.recipeData then
            local outputItems = params.recipeData.getAllCreatedItems and params.recipeData:getAllCreatedItems() or nil
            local fromCreated = findTicketInValue(outputItems)
            if fromCreated then
                return fromCreated
            end

            local outputItemsAlt = params.recipeData.getAllOutputItems and params.recipeData:getAllOutputItems() or nil
            local fromOutputs = findTicketInValue(outputItemsAlt)
            if fromOutputs then
                return fromOutputs
            end

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
    return fullType == CUSTOM_TICKET_FULL_TYPE
        or fullType == "Base.ScratchTicket"
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
    local fullType = item:getFullType()
    if fullType ~= "Base.ScratchTicket" and fullType ~= CUSTOM_TICKET_FULL_TYPE then
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
    local chance = tonumber(getSandbox().ScratchTicketWinChance or 15.0) or 15.0
    return clamp(chance, 0.0, 100.0)
end

function ScratchTickets.GetWinRange()
    local sandbox = getSandbox()
    local minWin = math.max(1, floorNumber(sandbox.ScratchTicketMinWin, 25))
    local maxWin = math.max(minWin, floorNumber(sandbox.ScratchTicketMaxWin, minWin))
    return minWin, maxWin
end

function ScratchTickets.RollGuaranteedWinAmount()
    local minWin, maxWin = ScratchTickets.GetWinRange()
    return safeRandRange(minWin, maxWin)
end

function ScratchTickets.RollScratchOutcome(player)
    local baseWinChance = ScratchTickets.GetWinChance()
    local minWin, maxWin = ScratchTickets.GetWinRange()
    local state = ensureScratchState(player)
    local dryStreak = tonumber(state and state.dryStreak) or 0
    local hotStreak = tonumber(state and state.hotStreak) or 0
    local jackpotCooldown = tonumber(state and state.jackpotCooldown) or 0
    local tierWeights = getTierWeights()
    local tierBounds = getTierBounds(minWin, maxWin)
    local jackpotAmount = ScratchTickets.GetCurrentJackpotAmount()

    local minEffectiveWinChance = baseWinChance > 0 and math.min(baseWinChance, math.max(1.5, baseWinChance * 0.35)) or 0
    local effectiveWinChance = baseWinChance
    effectiveWinChance = effectiveWinChance + math.min(dryStreak * 1.35, 10.0)
    effectiveWinChance = effectiveWinChance - math.min(hotStreak * 1.65, 9.0)
    effectiveWinChance = clamp(effectiveWinChance, minEffectiveWinChance, 78.0)

    if ZombRandFloat(0.0, 100.0) >= effectiveWinChance then
        updateScratchState(state, "LOSE", "LOSE")
        return 0, "LOSE", "LOSE"
    end

    local amount = 0
    local resultType = "WIN"
    local tier = "LOW"

    local jackpotChance = getJackpotChance()
    jackpotChance = jackpotChance + math.min(dryStreak * 0.35, 4.0) - math.min(hotStreak * 0.5, 3.0)
    if jackpotCooldown > 0 then
        jackpotChance = jackpotChance * 0.15
    end
    jackpotChance = clamp(jackpotChance, 0.0, math.max(getJackpotChance() + 5.0, getJackpotChance() * 2.0))

    if jackpotChance > 0 and ZombRandFloat(0.0, 100.0) < jackpotChance then
        amount = jackpotAmount
        resultType = "JACKPOT"
        tier = "JACKPOT"
    else
        local lowWeight = tierWeights.low + math.min(hotStreak * 4.0, 12.0) - math.min(dryStreak * 2.0, 6.0)
        local mediumWeight = tierWeights.medium + math.min(dryStreak * 1.5, 5.0) - math.min(hotStreak * 1.0, 3.0)
        local highWeight = tierWeights.high + math.min(dryStreak * 1.75, 5.5) - math.min(hotStreak * 2.5, 6.0)

        if tostring(state and state.lastResult or "") == "HIGH" then
            highWeight = math.max(3.0, highWeight - 3.5)
        end

        lowWeight = math.max(15.0, lowWeight)
        mediumWeight = math.max(10.0, mediumWeight)
        highWeight = math.max(4.0, highWeight)

        local totalWeight = lowWeight + mediumWeight + highWeight
        local roll = ZombRandFloat(0.0, totalWeight)

        if roll < lowWeight then
            tier = "LOW"
            amount = safeRandRange(tierBounds.lowMin, tierBounds.lowMax)
        elseif roll < (lowWeight + mediumWeight) then
            tier = "MEDIUM"
            amount = safeRandRange(tierBounds.mediumMin, tierBounds.mediumMax)
        else
            tier = "HIGH"
            amount = safeRandRange(tierBounds.highMin, tierBounds.highMax)
        end

        amount = roundMoney(amount)
    end

    amount = math.max(1, amount)
    updateScratchState(state, resultType, tier)
    return amount, resultType, tier
end

function ScratchTickets.MarkWinner(item, amount)
    if not item then return end
    local payout = math.max(1, floorNumber(amount, ScratchTickets.RollGuaranteedWinAmount()))
    local modData = item:getModData()
    modData[STATE_KEY] = "WIN"
    modData[WIN_AMOUNT_KEY] = payout
    modData[CLAIMED_KEY] = false
    setTicketPresentation(
        item,
        "Scratch Ticket - Winner ($" .. tostring(payout) .. ")",
        "Claim this payout from a qualified trader.",
        "Base.ScratchTicket_Winner"
    )
end

function ScratchTickets.MarkLoser(item)
    if not item then return end
    local modData = item:getModData()
    modData[STATE_KEY] = "LOSE"
    modData[WIN_AMOUNT_KEY] = 0
    modData[CLAIMED_KEY] = false
    setTicketPresentation(item, "Scratch Ticket - Loser", "No payout on this ticket.", "Base.ScratchTicket_Loser")
end

function ScratchTickets.MarkClaimed(item)
    if not item then return end
    local modData = item:getModData()
    modData[STATE_KEY] = "CLAIMED"
    modData[CLAIMED_KEY] = true
    modData[WIN_AMOUNT_KEY] = 0
    setTicketPresentation(item, "Claimed Scratch Ticket", "This ticket has already been paid out.", "Base.ScratchTicket_Winner")
end

function ScratchTickets.NormalizePreRolledTicket(item)
    if not item then return end
    if ScratchTickets.IsClaimed(item) then
        ScratchTickets.MarkClaimed(item)
        return
    end

    local fullType = item:getFullType()
    if fullType == "Base.ScratchTicket_Winner" and ScratchTickets.GetWinAmount(item) <= 0 then
        ScratchTickets.MarkWinner(item, ScratchTickets.RollGuaranteedWinAmount())
    elseif fullType == "Base.ScratchTicket_Loser" and not ScratchTickets.IsScratched(item) then
        ScratchTickets.MarkLoser(item)
    elseif ScratchTickets.GetWinAmount(item) > 0 then
        ScratchTickets.MarkWinner(item, ScratchTickets.GetWinAmount(item))
    elseif ScratchTickets.IsScratched(item) then
        ScratchTickets.MarkLoser(item)
    else
        applyTicketVisual(item, getDefaultVisualType(item))
        syncTicket(item)
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

function ScratchTickets.GetPotentialWinnerSummary(player)
    if not player or not player.getInventory then
        return 0, 0
    end

    local results = {}
    local total = 0
    ScratchTickets.CollectPotentialWinners(player:getInventory(), results)

    for _, ticket in ipairs(results) do
        ScratchTickets.NormalizePreRolledTicket(ticket)
        local amount = ScratchTickets.GetWinAmount(ticket)
        if amount > 0 and not ScratchTickets.IsClaimed(ticket) then
            total = total + amount
        end
    end

    return #results, total
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
