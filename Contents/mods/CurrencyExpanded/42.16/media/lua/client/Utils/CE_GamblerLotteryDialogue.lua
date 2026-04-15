require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"
pcall(require, "DT/Common/UI/ConversationUI/ConversationUI")
pcall(require, "DT/V2/NPC/UI/DTNPC_TraderDialogue_Hub")

local ScratchTickets = CurrencyExpanded.ScratchTickets or {}
local PendingLotteryInfo = nil

local function getLocalPlayer()
    return getPlayer() or getSpecificPlayer(0)
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
    return "$" .. tostring(math.max(0, math.floor(tonumber(amount) or 0)))
end

local function buildJackpotReply(payload)
    local jackpot = formatMoney(payload and payload.jackpot or 0)
    local commonHighMax = formatMoney(payload and payload.commonHighMax or 0)
    local variants = {
        "Current live jackpot is " .. jackpot .. ". Common wins top out around " .. commonHighMax .. ", so anything above that is the real board.",
        "Board's sitting at " .. jackpot .. " right now. Regular winners stay under about " .. commonHighMax .. "; the rest is jackpot country.",
        "Live pot's up to " .. jackpot .. ". Standard tickets can still hit, but the true jackpot starts above roughly " .. commonHighMax .. "."
    }

    return variants[ZombRand(#variants) + 1]
end

local function buildWinnersReply(payload)
    local winners = payload and payload.winners or nil
    if type(winners) ~= "table" or #winners == 0 then
        return "Quiet week so far. Board's still warming up and nobody's posted a real brag yet."
    end

    local fragments = {}
    for index = 1, math.min(#winners, 5) do
        local entry = winners[index]
        local name = tostring(entry and entry.name or "Unknown")
        local amount = formatMoney(entry and entry.amount or 0)
        local hits = math.max(1, math.floor(tonumber(entry and entry.hits) or 1))
        local bestAmount = formatMoney(entry and entry.bestAmount or entry and entry.amount or 0)

        if hits > 1 then
            fragments[#fragments + 1] = name .. " " .. amount .. " total over " .. tostring(hits) .. " wins"
        else
            fragments[#fragments + 1] = name .. " " .. amount .. " total"
        end

        if index == 1 and hits > 1 then
            fragments[#fragments] = fragments[#fragments] .. " (best hit " .. bestAmount .. ")"
        end
    end

    return "This week's board reads: " .. table.concat(fragments, ", ") .. "."
end

local function buildPayoutReply(payload)
    local lowMax = formatMoney(payload and payload.commonLowMax or 0)
    local mediumMax = formatMoney(payload and payload.commonMediumMax or 0)
    local highMax = formatMoney(payload and payload.commonHighMax or 0)
    local jackpot = formatMoney(payload and payload.jackpot or 0)

    return "Low hits run up to " .. lowMax .. ", medium hits climb to about " .. mediumMax .. ", and the high common board stops near " .. highMax .. ". After that, you're chasing the live jackpot at " .. jackpot .. "."
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
        local variants = {
            "Hold on, you've got a live winner on you. That's $" .. tostring(total) .. ". Didn't expect you to walk in already beating the board.",
            "Well now, that's a winning ticket in your pocket. $" .. tostring(total) .. " on the table already.",
            "You came in carrying a hitter. That's $" .. tostring(total) .. " waiting to be paid."
        }
        return variants[ZombRand(#variants) + 1]
    end

    local variants = {
        "Damn, you've got " .. tostring(count) .. " winners on you already. That's $" .. tostring(total) .. " waiting at my counter.",
        "Now that's a surprise. " .. tostring(count) .. " winning tickets for a total of $" .. tostring(total) .. ".",
        "You're walking in hot. I count " .. tostring(count) .. " winning scratches, worth $" .. tostring(total) .. " altogether."
    }
    return variants[ZombRand(#variants) + 1]
end

local function showLotteryChatMenu(ui, trader, npc, player, rootGenerator)
    if not ui then
        return
    end

    local options = {
        {
            text = "House Banter",
            message = "How's the table feeling today?",
            onSelect = function(innerUI)
                local variants = {
                    "Luck's moody, but business is awake. That's usually enough.",
                    "Table's been mean, which means it's due to flinch eventually.",
                    "I've seen worse boards. I've also seen better liars.",
                    "People keep chasing the top line. House keeps eating the nerves."
                }
                innerUI:speak(variants[ZombRand(#variants) + 1])
                showLotteryChatMenu(innerUI, trader, npc, player, rootGenerator)
            end
        },
        {
            text = "Current Jackpot",
            message = "What's the current jackpot sitting at?",
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
            text = "Winners This Week",
            message = "Who has been winning this week?",
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
            text = "How The Board Pays",
            message = "Break down the payouts for me.",
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
            text = "< Back",
            message = "Let's get back to business.",
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
            option.message = "Let's talk lottery for a second."
            option.onSelect = function(innerUI)
                local lines = {
                    "You want table talk or board talk?",
                    "Fine. Ask your lottery questions.",
                    "All right. What part of the board are you chasing?"
                }
                innerUI:speak(lines[ZombRand(#lines) + 1])
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
