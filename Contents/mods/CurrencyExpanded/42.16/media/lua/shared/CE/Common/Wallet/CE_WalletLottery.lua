CurrencyExpanded = CurrencyExpanded or {}
CurrencyExpanded.WalletLottery = CurrencyExpanded.WalletLottery or {}

local WalletLottery = CurrencyExpanded.WalletLottery

local STATE_KEY = "CE_WalletLotteryState"

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function safeRandRange(minValue, maxValue)
    local minNumber = math.floor(tonumber(minValue) or 0)
    local maxNumber = math.floor(tonumber(maxValue) or minNumber)
    if maxNumber <= minNumber then
        return minNumber
    end
    return ZombRand(minNumber, maxNumber + 1)
end

local function ensureState(player)
    if not player or not player.getModData then return nil end

    local modData = player:getModData()
    if not modData then return nil end

    if type(modData[STATE_KEY]) ~= "table" then
        modData[STATE_KEY] = {
            searches = 0,
            dryStreak = 0,
            emptyStreak = 0,
            hotStreak = 0,
            jackpotCooldown = 0,
            lastResult = "NONE"
        }
    end

    return modData[STATE_KEY]
end

local function getResultTier(amount, maxCash, resultType)
    if resultType == "JACKPOT" then
        return "JACKPOT"
    end

    local maxValue = math.max(1, math.floor(tonumber(maxCash) or 1))
    local ratio = (tonumber(amount) or 0) / maxValue
    if ratio >= 0.7 then
        return "HIGH"
    elseif ratio >= 0.3 then
        return "MEDIUM"
    end
    return "LOW"
end

local function updateState(state, resultType, tier)
    if not state then return end

    local nextCooldown = math.max((tonumber(state.jackpotCooldown) or 0) - 1, 0)
    state.searches = (tonumber(state.searches) or 0) + 1

    if resultType == "EMPTY" then
        state.emptyStreak = math.min((tonumber(state.emptyStreak) or 0) + 1, 8)
        state.dryStreak = math.min((tonumber(state.dryStreak) or 0) + 1, 12)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "EMPTY"
        return
    end

    state.emptyStreak = 0

    if tier == "JACKPOT" then
        state.dryStreak = 0
        state.hotStreak = math.min((tonumber(state.hotStreak) or 0) + 3, 8)
        state.jackpotCooldown = 4
        state.lastResult = "JACKPOT"
    elseif tier == "HIGH" then
        state.dryStreak = 0
        state.hotStreak = math.min((tonumber(state.hotStreak) or 0) + 1, 8)
        state.jackpotCooldown = math.max(nextCooldown, 1)
        state.lastResult = "HIGH"
    elseif tier == "MEDIUM" then
        state.dryStreak = math.max((tonumber(state.dryStreak) or 0) - 2, 0)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "MEDIUM"
    else
        state.dryStreak = math.min((tonumber(state.dryStreak) or 0) + 1, 12)
        state.hotStreak = math.max((tonumber(state.hotStreak) or 0) - 1, 0)
        state.jackpotCooldown = nextCooldown
        state.lastResult = "LOW"
    end
end

function WalletLottery.Roll(player)
    local minCash = math.max(1, math.floor(SandboxVars.CurrencyExpanded.WalletMinCash or 1))
    local maxCash = math.max(minCash, math.floor(SandboxVars.CurrencyExpanded.WalletMaxCash or 300))
    local emptyChance = clamp(tonumber(SandboxVars.CurrencyExpanded.WalletEmptyChance or 20) or 20, 0, 100)
    local jackpotChance = clamp(tonumber(SandboxVars.CurrencyExpanded.WalletJackpotChance or 5.0) or 5.0, 0, 100)

    local state = ensureState(player)
    local dryStreak = tonumber(state and state.dryStreak) or 0
    local emptyStreak = tonumber(state and state.emptyStreak) or 0
    local hotStreak = tonumber(state and state.hotStreak) or 0
    local jackpotCooldown = tonumber(state and state.jackpotCooldown) or 0

    local minEmptyChance = emptyChance > 0 and math.min(emptyChance, math.max(2, emptyChance * 0.35)) or 0
    local effectiveEmptyChance = emptyChance
    effectiveEmptyChance = effectiveEmptyChance + math.min(hotStreak * 3, 12)
    effectiveEmptyChance = effectiveEmptyChance - math.min(emptyStreak * 5, 15)
    effectiveEmptyChance = effectiveEmptyChance - math.min(dryStreak * 2, 8)
    effectiveEmptyChance = clamp(effectiveEmptyChance, minEmptyChance, 85)

    if ZombRandFloat(0.0, 100.0) < effectiveEmptyChance then
        updateState(state, "EMPTY", "EMPTY")
        return 0, "EMPTY"
    end

    local effectiveJackpotChance = jackpotChance
    if jackpotChance > 0 then
        effectiveJackpotChance = effectiveJackpotChance + math.min(dryStreak * 0.9, 9.0)
        effectiveJackpotChance = effectiveJackpotChance + math.min(emptyStreak * 0.5, 4.0)
        effectiveJackpotChance = effectiveJackpotChance - math.min(hotStreak * 1.75, 6.0)
        if jackpotCooldown > 0 then
            effectiveJackpotChance = effectiveJackpotChance * 0.15
        end
        effectiveJackpotChance = clamp(effectiveJackpotChance, 0, math.max(jackpotChance * 2.5, jackpotChance + 8.0))
    else
        effectiveJackpotChance = 0
    end

    local amount = 0
    local resultType = "MONEY"

    if effectiveJackpotChance > 0 and ZombRandFloat(0.0, 100.0) <= effectiveJackpotChance then
        local bonus = ZombRandFloat(0.8, 1.5)
        amount = math.floor(maxCash * bonus)
        resultType = "JACKPOT"
    else
        local lowWeight = clamp(60 + math.min(hotStreak * 7, 18) - math.min(dryStreak * 4, 12), 35, 72)
        local highWeight = clamp(10 - math.min(hotStreak * 3, 6) + math.min(dryStreak * 3, 9) + math.min(emptyStreak * 2, 6), 5, 24)
        local mediumWeight = 100 - lowWeight - highWeight

        if mediumWeight < 15 then
            local deficit = 15 - mediumWeight
            lowWeight = math.max(30, lowWeight - math.ceil(deficit / 2))
            highWeight = math.max(5, highWeight - math.floor(deficit / 2))
            mediumWeight = 100 - lowWeight - highWeight
        end

        local lowMax = math.max(minCash, math.floor(maxCash * 0.3))
        local mediumMin = math.max(minCash, lowMax)
        local mediumMax = math.max(mediumMin, math.floor(maxCash * 0.7))
        local highMin = math.max(mediumMin, mediumMax)

        local roll = ZombRand(100)
        if roll < lowWeight then
            amount = safeRandRange(minCash, lowMax)
        elseif roll < (lowWeight + mediumWeight) then
            amount = safeRandRange(mediumMin, mediumMax)
        else
            amount = safeRandRange(highMin, maxCash)
        end
    end

    if amount < 1 then amount = 1 end

    local tier = getResultTier(amount, maxCash, resultType)
    updateState(state, resultType, tier)

    return amount, resultType
end

return WalletLottery
