require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"

local ScratchTickets = CurrencyExpanded.ScratchTickets or {}
local PendingClaim = nil

local function getLocalPlayer()
    return getPlayer() or getSpecificPlayer(0)
end

local function getTraderData(trader)
    if not trader then return nil end
    return DynamicTrading and DynamicTrading.GetArchetypeData and DynamicTrading.GetArchetypeData(trader.archetype) or nil
end

local function supportsScratchClaims(trader)
    local archetypeData = getTraderData(trader)
    return archetypeData and archetypeData.supportsScratchClaims == true
end

local function addMoneyLocal(inv, totalMoney)
    if not inv or totalMoney <= 0 then return end

    local bundles = math.floor(totalMoney / 100)
    local looseCash = totalMoney % 100

    if bundles > 0 then
        inv:AddItems("Base.MoneyBundle", bundles)
    end
    if looseCash > 0 then
        inv:AddItems("Base.Money", looseCash)
    end
end

local function removeItemLocal(item)
    if not item then return end
    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
    end
end

local function processClaimSP(player, args)
    if not player or not player.getInventory then return end

    local inv = player:getInventory()
    local tickets = {}
    ScratchTickets.CollectPotentialWinners(inv, tickets)

    local total = 0
    local count = 0

    for _, ticket in ipairs(tickets) do
        ScratchTickets.NormalizePreRolledTicket(ticket)

        local amount = ScratchTickets.GetWinAmount(ticket)
        if amount > 0 and not ScratchTickets.IsClaimed(ticket) then
            total = total + amount
            count = count + 1
            removeItemLocal(ticket)
        end
    end

    if total > 0 then
        addMoneyLocal(inv, total)
    end

    if ISInventoryPage and ISInventoryPage.dirtyUI then
        ISInventoryPage.dirtyUI()
    end

    triggerEvent("OnServerCommand", "CurrencyExpanded", "ScratchClaimResult", {
        status = count > 0 and "SUCCESS" or "NONE",
        total = total,
        count = count,
        traderID = args and args.traderID or nil
    })
end

local function findInsertIndex(options)
    for index, option in ipairs(options) do
        if option.text == "Trade" then
            return index + 1
        end
    end
    return #options + 1
end

local function buildClaimLine(args)
    local total = math.max(0, tonumber(args and args.total) or 0)
    local count = math.max(0, tonumber(args and args.count) or 0)

    if total <= 0 or count <= 0 then
        return "No winners to cash today. Bring me a real hit."
    end

    if count == 1 then
        return "House pays. That's $" .. tostring(total) .. " for your winner."
    end

    return "Nice stack. That's $" .. tostring(total) .. " across " .. tostring(count) .. " winning tickets."
end

local function requestClaim(ui, trader, player, refreshFn)
    if not ui or not trader or not player then
        return
    end

    local ticketCount = ScratchTickets.CountPotentialWinners(player)
    if ticketCount <= 0 then
        ui:speak("You don't have a winning ticket for me right now.")
        if refreshFn then
            refreshFn()
        end
        return
    end

    PendingClaim = {
        ui = ui,
        traderID = trader.id or trader.uuid,
        refresh = refreshFn
    }

    local args = { traderID = trader.id or trader.uuid }
    if isClient() then
        sendClientCommand(player, "CurrencyExpanded", "ClaimScratchTickets", args)
    else
        processClaimSP(player, args)
    end
end

local function injectClaimOption(options, ui, trader, player, refreshFn)
    if type(options) ~= "table" or not ui or not trader or not player then
        return options
    end

    if not supportsScratchClaims(trader) then
        return options
    end

    if ScratchTickets.CountPotentialWinners(player) <= 0 then
        return options
    end

    for _, option in ipairs(options) do
        if option.text == "Claim Win Payout" then
            return options
        end
    end

    table.insert(options, findInsertIndex(options), {
        text = "Claim Win Payout",
        message = "I need to cash in a winning ticket.",
        onSelect = function()
            requestClaim(ui, trader, player, refreshFn)
        end
    })

    return options
end

local function wrapGenerateOptions(targetTable, key, traderResolver, refreshResolver)
    if not targetTable or type(targetTable[key]) ~= "function" or targetTable.__ceScratchClaimWrapped == true then
        return
    end

    local original = targetTable[key]
    targetTable[key] = function(ui, a, b, c)
        local originalUpdateOptions = ui and ui.updateOptions or nil

        if ui and originalUpdateOptions then
            ui.updateOptions = function(self, options)
                local trader = traderResolver(ui, a, b, c)
                local refreshFn = refreshResolver(ui, a, b, c, original)
                options = injectClaimOption(options or {}, ui, trader, c or b, refreshFn)
                return originalUpdateOptions(self, options)
            end
        end

        local ok, err = pcall(original, ui, a, b, c)

        if ui and originalUpdateOptions then
            ui.updateOptions = originalUpdateOptions
        end

        if not ok then
            error(err)
        end
    end

    targetTable.__ceScratchClaimWrapped = true
end

local function patchDialogueHubs()
    if DTNPC_TraderDialogue_Hub and type(DTNPC_TraderDialogue_Hub.GenerateOptions) == "function" and not DTNPC_TraderDialogue_Hub.__ceScratchClaimPatched then
        wrapGenerateOptions(
            DTNPC_TraderDialogue_Hub,
            "GenerateOptions",
            function(ui)
                return ui and ui.target or nil
            end,
            function(ui, npc, player, _, original)
                return function()
                    original(ui, npc, player)
                end
            end
        )
        DTNPC_TraderDialogue_Hub.__ceScratchClaimPatched = true
    end

    if DT_V1_Dialogue_Hub and type(DT_V1_Dialogue_Hub.GenerateOptions) == "function" and not DT_V1_Dialogue_Hub.__ceScratchClaimPatched then
        wrapGenerateOptions(
            DT_V1_Dialogue_Hub,
            "GenerateOptions",
            function(_, _, traderID)
                if DynamicTrading and DynamicTrading.Manager and DynamicTrading.Manager.GetTrader then
                    return DynamicTrading.Manager.GetTrader(traderID)
                end
                return nil
            end,
            function(ui, radioObj, traderID, player, original)
                return function()
                    original(ui, radioObj, traderID, player)
                end
            end
        )
        DT_V1_Dialogue_Hub.__ceScratchClaimPatched = true
    end
end

local function OnServerCommand(module, command, args)
    if module ~= "CurrencyExpanded" or command ~= "ScratchClaimResult" then
        return
    end

    local player = getLocalPlayer()
    if player then
        if (tonumber(args and args.total) or 0) > 0 then
            player:setHaloNote("+ $" .. tostring(args.total), 50, 255, 50, 300)
        else
            player:setHaloNote("No payout", 170, 170, 170, 300)
        end
    end

    local pending = PendingClaim
    PendingClaim = nil

    if pending and pending.ui and pending.ui.getIsVisible and pending.ui:getIsVisible() then
        pending.ui:speak(buildClaimLine(args))
        if pending.refresh then
            pending.refresh()
        end
    end
end

patchDialogueHubs()
Events.OnGameBoot.Add(patchDialogueHubs)
Events.OnServerCommand.Add(OnServerCommand)
