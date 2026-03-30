pcall(require, "DT/Common/Config")
pcall(require, "DT/Common/Faction/TradingSys/DynamicTrading_Factions")
pcall(require, "DT/Common/Faction/TradingSys/RosterLogic/DT_RosterLogic")
pcall(require, "DT/Common/Faction/TradingSys/DynamicTrading_Stock")
pcall(require, "DT/V1/Manager")

local function isServerRuntime()
    return (not isClient()) or isServer()
end

local function countGamblerSouls()
    local rosterData = ModData.get("DynamicTrading_Roster") or {}
    local souls = rosterData.Souls or {}
    local total = 0
    local active = 0
    local firstUUID = nil
    local activeMissingCoordsUUID = nil

    for uuid, soul in pairs(souls) do
        if soul and soul.archetypeID == "Gambler" then
            total = total + 1
            firstUUID = firstUUID or uuid
            if soul.status == "Trading" then
                active = active + 1
                if (not soul.lastX or not soul.lastY) and not activeMissingCoordsUUID then
                    activeMissingCoordsUUID = uuid
                end
            end
        end
    end

    return total, active, firstUUID, activeMissingCoordsUUID
end

local function syncSharedTraderData()
    ModData.transmit("DynamicTrading_Roster")
    ModData.transmit("DynamicTrading_Factions")
    ModData.transmit("DynamicTrading_Stock")
end

local function syncIndependentMemberCount()
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetFaction then
        return
    end

    local faction = DynamicTrading_Factions.GetFaction("Independent")
    local members = DynamicTrading_Roster and DynamicTrading_Roster.GetSouls
        and DynamicTrading_Roster.GetSouls("Independent") or nil
    if faction and type(members) == "table" then
        faction.memberCount = #members
    end
end

local function ensureActiveGambler()
    if not isServerRuntime() then
        return
    end

    if not DynamicTrading
        or not DynamicTrading.Archetypes
        or not DynamicTrading.Archetypes["Gambler"]
        or not DynamicTrading_Factions
        or not DynamicTrading_Roster then
        return
    end

    local independent = DynamicTrading_Factions.GetFaction and DynamicTrading_Factions.GetFaction("Independent") or nil
    if not independent and DynamicTrading_Factions.CreateFaction then
        DynamicTrading_Factions.CreateFaction("Independent", {
            memberCount = 10,
            isNomadic = true
        })
        independent = DynamicTrading_Factions.GetFaction and DynamicTrading_Factions.GetFaction("Independent") or nil
    end

    if not independent then
        return
    end

    local total, active, firstUUID, activeMissingCoordsUUID = countGamblerSouls()
    if total > 0 then
        if active > 0
            and activeMissingCoordsUUID
            and DynamicTrading.Manager
            and DynamicTrading.Manager.EnsureTraderTradingCoordinates
            and DynamicTrading.Manager.EnsureTraderTradingCoordinates(activeMissingCoordsUUID) then
            syncSharedTraderData()
        end
        return
    end

    local uuid = DynamicTrading_Roster.AddSoul and DynamicTrading_Roster.AddSoul("Independent", "Gambler", nil, {
        forceFaction = true
    }) or nil
    if uuid then
        syncIndependentMemberCount()
        syncSharedTraderData()
    end
end

Events.OnInitGlobalModData.Add(ensureActiveGambler)
Events.EveryHours.Add(ensureActiveGambler)
