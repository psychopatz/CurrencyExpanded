require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"
pcall(require, "DT/Common/UI/ConversationUI/ConversationUI")
pcall(require, "DT/V2/NPC/UI/DTNPC_TraderDialogue_Hub")

local ScratchTickets = CurrencyExpanded.ScratchTickets or {}
local PendingLotteryInfo = nil
local CEText = CurrencyExpanded and CurrencyExpanded.Text or nil

local function getLocalPlayer()
    return getPlayer() or getSpecificPlayer(0)
end

local function T(key, fallback, params)
    if CEText and CEText.Get then
        return CEText.Get(key, params, fallback)
    end

    if type(params) == "table" and fallback then
        return (tostring(fallback):gsub("{([%w_]+)}", function(name)
            local value = params[name]
            return value == nil and ("{" .. name .. "}") or tostring(value)
        end))
    end

    return fallback or key
end

local function getList(prefix)
    if CEText and CEText.GetList then
        return CEText.GetList(prefix, {})
    end

    return {}
end

local function pick(prefix, params, fallback)
    local values = getList(prefix)
    local chosen = values[ZombRand(math.max(#values, 1)) + 1]
    if chosen then
        return CEText and CEText.Format and CEText.Format(chosen, params) or T(prefix .. "_1", chosen, params)
    end

    return T(prefix .. "_1", fallback or prefix, params)
end

local function getTraderData(trader)
    if not trader then
        return nil
    end

    if DynamicTrading and DynamicTrading.GetArchetypeData then
        local archetypeData = DynamicTrading.GetArchetypeData(trader.archetype)
        if archetypeData then
            return archetypeData
        end
    end

    return DynamicTrading and DynamicTrading.Archetypes and DynamicTrading.Archetypes[trader.archetype] or nil
end

local function supportsLotteryTalk(trader)
    local archetypeData = getTraderData(trader)
    if archetypeData then
        return archetypeData.supportsScratchClaims == true
    end

    return trader and trader.archetype == "Gambler"
end

local function copyOptions(options)
    local copied = {}
    for index, option in ipairs(options or {}) do
        copied[index] = option
    end
    return copied
end

local function formatMoney(amount)
    return T("CECommon_UI_MoneyAmount", "${amount}", {
        amount = tostring(math.max(0, math.floor(tonumber(amount) or 0)))
    })
end

local function buildJackpotReply(payload)
    return pick("CECommon_Dialogue_Gambler_JackpotReply", {
        jackpot = formatMoney(payload and payload.jackpot or 0),
        commonHighMax = formatMoney(payload and payload.commonHighMax or 0),
    }, "Current live jackpot is {jackpot}. Common wins top out around {commonHighMax}, so anything above that is the real board.")
end

local function buildWinnersReply(payload)
    local winners = payload and payload.winners or nil
    if type(winners) ~= "table" or #winners == 0 then
        return T("CECommon_Dialogue_Gambler_WinnersNone", "Quiet week so far. Board's still warming up and nobody's posted a real brag yet.")
    end

    local fragments = {}
    for index = 1, math.min(#winners, 5) do
        local entry = winners[index]
        local name = tostring(entry and entry.name or T("CECommon_Dialogue_Gambler_WinnersUnknown", "Unknown"))
        local amount = formatMoney(entry and entry.amount or 0)
        local hits = math.max(1, math.floor(tonumber(entry and entry.hits) or 1))
        local bestAmount = formatMoney(entry and entry.bestAmount or entry and entry.amount or 0)

        if hits > 1 then
            fragments[#fragments + 1] = T("CECommon_Dialogue_Gambler_WinnersFragmentMulti", "{name} {amount} total over {hits} wins", {
                name = name,
                amount = amount,
                hits = tostring(hits),
            })
        else
            fragments[#fragments + 1] = T("CECommon_Dialogue_Gambler_WinnersFragmentSingle", "{name} {amount} total", {
                name = name,
                amount = amount,
            })
        end

        if index == 1 and hits > 1 then
            fragments[#fragments] = T("CECommon_Dialogue_Gambler_WinnersBestHit", "{fragment} (best hit {amount})", {
                fragment = fragments[#fragments],
                amount = bestAmount,
            })
        end
    end

    return T("CECommon_Dialogue_Gambler_WinnersSummary", "This week's board reads: {entries}.", {
        entries = table.concat(fragments, ", "),
    })
end

local function buildPayoutReply(payload)
    local lowMax = formatMoney(payload and payload.commonLowMax or 0)
    local mediumMax = formatMoney(payload and payload.commonMediumMax or 0)
    local highMax = formatMoney(payload and payload.commonHighMax or 0)
    local jackpot = formatMoney(payload and payload.jackpot or 0)

    return T("CECommon_Dialogue_Gambler_PayoutReply", "Low hits run up to {lowMax}, medium hits climb to about {mediumMax}, and the high common board stops near {highMax}. After that, you're chasing the live jackpot at {jackpot}.", {
        lowMax = lowMax,
        mediumMax = mediumMax,
        highMax = highMax,
        jackpot = jackpot,
    })
end

local function buildInfoReply(payload)
    local detail = tostring(payload and payload.detail or "SUMMARY")
    if detail == "JACKPOT" then
        return buildJackpotReply(payload)
    elseif detail == "WINNERS" then
        return buildWinnersReply(payload)
    end

    return buildPayoutReply(payload)
end

local function buildWinnerGreeting(player)
    local count, total = 0, 0
    if ScratchTickets.GetPotentialWinnerSummary then
        count, total = ScratchTickets.GetPotentialWinnerSummary(player)
    else
        count = ScratchTickets.CountPotentialWinners(player)
    end

    count = math.max(0, tonumber(count) or 0)
    total = math.max(0, tonumber(total) or 0)
    if count <= 0 or total <= 0 then
        return nil
    end

    if count == 1 then
        return pick("CECommon_Dialogue_Gambler_WinnerGreetingSingle", {
            total = formatMoney(total),
        }, "Hold on, you've got a live winner on you. That's {total}. Didn't expect you to walk in already beating the board.")
    end

    return pick("CECommon_Dialogue_Gambler_WinnerGreetingMulti", {
        count = tostring(count),
        total = formatMoney(total),
    }, "Damn, you've got {count} winners on you already. That's {total} waiting at my counter.")
end

local function showLotteryChatMenu(ui, trader, npc, player, rootGenerator)
    if not ui then
        return
    end

    local options = {
        {
            text = T("CECommon_Dialogue_Gambler_ChatHouseBanter", "House Banter"),
            message = T("CECommon_Dialogue_Gambler_ChatHouseBanterMessage", "How's the table feeling today?"),
            onSelect = function(innerUI)
                innerUI:speak(pick("CECommon_Dialogue_Gambler_HouseBanterReply", nil, "Luck's moody, but business is awake. That's usually enough."))
                showLotteryChatMenu(innerUI, trader, npc, player, rootGenerator)
            end
        },
        {
            text = T("CECommon_Dialogue_Gambler_ChatJackpot", "Current Jackpot"),
            message = T("CECommon_Dialogue_Gambler_ChatJackpotMessage", "What's the current jackpot sitting at?"),
            onSelect = function(innerUI)
                PendingLotteryInfo = {
                    ui = innerUI,
                    trader = trader,
                    npc = npc,
                    player = player,
                    rootGenerator = rootGenerator
                }

                if isClient() then
                    sendClientCommand(player, "CurrencyExpanded", "RequestScratchLotteryInfo", { detail = "JACKPOT" })
                else
                    PendingLotteryInfo = nil
                    local payload = ScratchTickets.GetLotteryInfoSnapshot and ScratchTickets.GetLotteryInfoSnapshot(6) or {}
                    payload.detail = "JACKPOT"
                    innerUI:speak(buildInfoReply(payload))
                    showLotteryChatMenu(innerUI, trader, npc, player, rootGenerator)
                end
            end
        },
        {
            text = T("CECommon_Dialogue_Gambler_ChatWinners", "Winners This Week"),
            message = T("CECommon_Dialogue_Gambler_ChatWinnersMessage", "Who has been winning this week?"),
            onSelect = function(innerUI)
                PendingLotteryInfo = {
                    ui = innerUI,
                    trader = trader,
                    npc = npc,
                    player = player,
                    rootGenerator = rootGenerator
                }

                if isClient() then
                    sendClientCommand(player, "CurrencyExpanded", "RequestScratchLotteryInfo", { detail = "WINNERS" })
                else
                    PendingLotteryInfo = nil
                    local payload = ScratchTickets.GetLotteryInfoSnapshot and ScratchTickets.GetLotteryInfoSnapshot(6) or {}
                    payload.detail = "WINNERS"
                    innerUI:speak(buildInfoReply(payload))
                    showLotteryChatMenu(innerUI, trader, npc, player, rootGenerator)
                end
            end
        },
        {
            text = T("CECommon_Dialogue_Gambler_ChatPayouts", "How The Board Pays"),
            message = T("CECommon_Dialogue_Gambler_ChatPayoutsMessage", "Break down the payouts for me."),
            onSelect = function(innerUI)
                PendingLotteryInfo = {
                    ui = innerUI,
                    trader = trader,
                    npc = npc,
                    player = player,
                    rootGenerator = rootGenerator
                }

                if isClient() then
                    sendClientCommand(player, "CurrencyExpanded", "RequestScratchLotteryInfo", { detail = "PAYOUTS" })
                else
                    PendingLotteryInfo = nil
                    local payload = ScratchTickets.GetLotteryInfoSnapshot and ScratchTickets.GetLotteryInfoSnapshot(6) or {}
                    payload.detail = "PAYOUTS"
                    innerUI:speak(buildInfoReply(payload))
                    showLotteryChatMenu(innerUI, trader, npc, player, rootGenerator)
                end
            end
        },
        {
            text = T("CECommon_Dialogue_Gambler_Back", "< Back"),
            message = T("CECommon_Dialogue_Gambler_BackMessage", "Let's get back to business."),
            onSelect = function(innerUI)
                if rootGenerator then
                    rootGenerator(innerUI, npc, player)
                end
            end
        }
    }

    ui:updateOptions(options)
end

local function decorateRootOptions(options, ui, npc, player, rootGenerator)
    if type(options) ~= "table" or not ui or not ui.target or not supportsLotteryTalk(ui.target) then
        return options
    end

    local updated = copyOptions(options)
    for _, option in ipairs(updated) do
        if option.text == "Chat" then
            option.message = T("CECommon_Dialogue_Gambler_RootChatMessage", "Let's talk lottery for a second.")
            option.onSelect = function(innerUI)
                innerUI:speak(pick("CECommon_Dialogue_Gambler_RootChatIntro", nil, "You want table talk or board talk?"))
                showLotteryChatMenu(innerUI, ui.target, npc, player, rootGenerator)
            end
            break
        end
    end

    return updated
end

local function wrapDialogueHub()
    if not DTNPC_TraderDialogue_Hub or DTNPC_TraderDialogue_Hub.__ceLotteryChatPatched == true then
        return
    end

    if type(DTNPC_TraderDialogue_Hub.GenerateOptions) == "function" then
        local originalGenerateOptions = DTNPC_TraderDialogue_Hub.GenerateOptions
        DTNPC_TraderDialogue_Hub.GenerateOptions = function(ui, npc, player)
            if not ui then
                return originalGenerateOptions(ui, npc, player)
            end

            local originalUpdateOptions = ui.updateOptions
            ui.updateOptions = function(self, options)
                ui.updateOptions = originalUpdateOptions
                return originalUpdateOptions(
                    self,
                    decorateRootOptions(options, self, npc, player, DTNPC_TraderDialogue_Hub.GenerateOptions)
                )
            end

            local ok, result = pcall(originalGenerateOptions, ui, npc, player)
            ui.updateOptions = originalUpdateOptions

            if not ok then
                error(result)
            end

            return result
        end
    end

    if type(DTNPC_TraderDialogue_Hub.Init) == "function" then
        local originalInit = DTNPC_TraderDialogue_Hub.Init
        DTNPC_TraderDialogue_Hub.Init = function(ui, npc, player)
            local hadUI = ui ~= nil
            local result = originalInit(ui, npc, player)

            local activeUI = result or ui or (DT_ConversationUI and DT_ConversationUI.instance) or nil
            local trader = activeUI and activeUI.target or nil
            if not hadUI
                and activeUI
                and trader
                and supportsLotteryTalk(trader)
                and player
                and not activeUI.__ceWinnerGreetingShown then
                local winnerGreeting = buildWinnerGreeting(player)
                if winnerGreeting and winnerGreeting ~= "" then
                    activeUI.__ceWinnerGreetingShown = true
                    activeUI:speak(winnerGreeting)
                end
            end

            return result
        end
    end

    DTNPC_TraderDialogue_Hub.__ceLotteryChatPatched = true
end

local function OnServerCommand(module, command, args)
    if module ~= "CurrencyExpanded" or command ~= "ScratchLotteryInfo" then
        return
    end

    local pending = PendingLotteryInfo
    PendingLotteryInfo = nil

    if not pending or not pending.ui or not pending.ui.getIsVisible or not pending.ui:getIsVisible() then
        return
    end

    pending.ui:speak(buildInfoReply(args or {}))
    showLotteryChatMenu(pending.ui, pending.trader, pending.npc, pending.player or getLocalPlayer(), pending.rootGenerator)
end

wrapDialogueHub()
Events.OnServerCommand.Add(OnServerCommand)
Events.OnGameStart.Add(wrapDialogueHub)
