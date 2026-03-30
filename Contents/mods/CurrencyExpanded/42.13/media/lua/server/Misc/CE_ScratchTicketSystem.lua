require "DT/Common/ServerHelpers/ServerHelpers"
require "CE/Common/Config/CE_Config"
require "CE/Common/Lottery/CE_ScratchTickets"

local Commands = {}
local Helpers = CurrencyExpanded.ServerHelpers
local ScratchTickets = CurrencyExpanded.ScratchTickets or {}

local function addMoneyToInventory(inv, totalMoney)
    if not inv or totalMoney <= 0 then return end

    local bundles = math.floor(totalMoney / 100)
    local looseCash = totalMoney % 100

    if bundles > 0 then
        Helpers.AddItem(inv, "Base.MoneyBundle", bundles)
    end
    if looseCash > 0 then
        Helpers.AddItem(inv, "Base.Money", looseCash)
    end
end

function Commands.ClaimScratchTickets(player, args)
    if not player or not ScratchTickets or not ScratchTickets.CollectPotentialWinners then
        return
    end

    local inv = player:getInventory()
    if not inv then
        return
    end

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
            Helpers.RemoveItem(ticket)
        end
    end

    if total > 0 then
        addMoneyToInventory(inv, total)
    end

    Helpers.SendResponse(player, "CurrencyExpanded", "ScratchClaimResult", {
        status = count > 0 and "SUCCESS" or "NONE",
        total = total,
        count = count,
        traderID = args and args.traderID or nil
    })
end

local function OnClientCommand(module, command, player, args)
    if module == "CurrencyExpanded" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

CurrencyExpanded.Log("CECommons", "Init", "ScratchTicket", "Registered scratch ticket payout system")
