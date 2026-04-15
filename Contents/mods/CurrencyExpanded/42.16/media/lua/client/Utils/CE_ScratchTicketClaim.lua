require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"
require "DT/Common/Utils/DT_AudioManager"
pcall(require, "DT/Common/UI/ConversationUI/ConversationUI")
pcall(require, "DT/V2/NPC/UI/DTNPC_TraderDialogue_Hub")

local ScratchTickets = CurrencyExpanded.ScratchTickets or {}
local PendingClaim = nil

if DT_AudioManager and DT_AudioManager.RegisterCategory then
    DT_AudioManager.RegisterCategory("CE_Cashier", "Wallet")
end

local function getLocalPlayer()
    return getPlayer() or getSpecificPlayer(0)
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

local function getTraderData(trader)
    if not trader then return nil end

    if DynamicTrading and DynamicTrading.GetArchetypeData then
        local archetypeData = DynamicTrading.GetArchetypeData(trader.archetype)
        if archetypeData then
            return archetypeData
        end
    end

    return DynamicTrading and DynamicTrading.Archetypes and DynamicTrading.Archetypes[trader.archetype] or nil
end

local function supportsScratchClaims(trader)
    local archetypeData = getTraderData(trader)
    if archetypeData then
        return archetypeData.supportsScratchClaims == true
    end

    return trader and trader.archetype == "Gambler"
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

local function isRootConversationOptions(options)
    local hasChat = false
    local hasTrade = false

    for _, option in ipairs(options or {}) do
        if option.text == "Chat" then
            hasChat = true
        elseif option.text == "Trade" then
            hasTrade = true
        end
    end

    return hasChat or hasTrade
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

local function getClaimSummary(player)
    local count, total = 0, 0
    if ScratchTickets.GetPotentialWinnerSummary then
        count, total = ScratchTickets.GetPotentialWinnerSummary(player)
    else
        count = ScratchTickets.CountPotentialWinners(player)
    end

    return math.max(0, count or 0), math.max(0, total or 0)
end

local function isClaimOptionText(text)
    return tostring(text or ""):find("^Claim Win Payout", 1) ~= nil
end

local function requestClaim(ui, trader, player, refreshFn)
    if not ui or not trader or not player then
        return
    end

    local ticketCount, total = getClaimSummary(player)
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

    if not isRootConversationOptions(options) then
        return options
    end

    if not supportsScratchClaims(trader) then
        return options
    end

    local ticketCount, total = getClaimSummary(player)
    if ticketCount <= 0 then
        return options
    end

    for _, option in ipairs(options) do
        if isClaimOptionText(option.text) then
            return options
        end
    end

    table.insert(options, findInsertIndex(options), {
        text = "Claim Win Payout ($" .. tostring(total) .. ")",
        message = "I need to cash in $" .. tostring(total) .. " worth of winning tickets.",
        onSelect = function()
            requestClaim(ui, trader, player, refreshFn)
        end
    })

    return options
end

local function copyOptions(options)
    local copied = {}
    for index, option in ipairs(options or {}) do
        copied[index] = option
    end
    return copied
end

local function stripClaimOption(options)
    local cleaned = {}
    for _, option in ipairs(options or {}) do
        if not isClaimOptionText(option.text) then
            table.insert(cleaned, option)
        end
    end
    return cleaned
end

local function refreshCurrentOptions(ui)
    if not ui or not ui.updateOptions then
        return
    end

    ui:updateOptions(ui.baseOptions or {})
end

local function wrapConversationUI()
    if not DT_ConversationUI or type(DT_ConversationUI.updateOptions) ~= "function" or DT_ConversationUI.__ceScratchClaimPatched == true then
        return
    end

    local original = DT_ConversationUI.updateOptions
    DT_ConversationUI.updateOptions = function(self, options)
        local baseOptions = stripClaimOption(copyOptions(options))
        local injectedOptions = injectClaimOption(
            copyOptions(baseOptions),
            self,
            self and self.target or nil,
            getLocalPlayer(),
            function()
                refreshCurrentOptions(self)
            end
        )

        local result = original(self, injectedOptions)
        self.baseOptions = baseOptions
        return result
    end

    DT_ConversationUI.__ceScratchClaimPatched = true
end

local function wrapTraderDialogueHub()
    if not DTNPC_TraderDialogue_Hub or DTNPC_TraderDialogue_Hub.__ceScratchClaimPatched == true then
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

                local baseOptions = stripClaimOption(copyOptions(options))
                local injectedOptions = injectClaimOption(
                    copyOptions(baseOptions),
                    self,
                    (self and self.target) or npc,
                    player or getLocalPlayer(),
                    function()
                        refreshCurrentOptions(self)
                    end
                )

                return originalUpdateOptions(self, injectedOptions)
            end

            local ok, result = pcall(originalGenerateOptions, ui, npc, player)
            ui.updateOptions = originalUpdateOptions

            if not ok then
                error(result)
            end

            return result
        end
    end

    DTNPC_TraderDialogue_Hub.__ceScratchClaimPatched = true
end

local function OnServerCommand(module, command, args)
    if module ~= "CurrencyExpanded" or command ~= "ScratchClaimResult" then
        return
    end

    local player = getLocalPlayer()
    if player then
        if (tonumber(args and args.total) or 0) > 0 then
            playUISound("CE_Cashier")
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

wrapConversationUI()
wrapTraderDialogueHub()
Events.OnGameBoot.Add(wrapConversationUI)
Events.OnGameStart.Add(wrapTraderDialogueHub)
Events.OnServerCommand.Add(OnServerCommand)
