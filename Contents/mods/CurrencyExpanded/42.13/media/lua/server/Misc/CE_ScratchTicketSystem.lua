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

local function findTicketByID(player, args)
    if not player or not player.getInventory then
        return nil
    end

    local inv = player:getInventory()
    if not inv then
        return nil
    end

    local itemID = args and args.itemID or nil
    if itemID then
        return inv:getItemById(itemID)
    end

    return nil
end

local function buildLotteryInfoPayload(detail)
    local snapshot = ScratchTickets.GetLotteryInfoSnapshot and ScratchTickets.GetLotteryInfoSnapshot(6) or {}
    return {
        detail = tostring(detail or "SUMMARY"),
        jackpot = math.max(0, tonumber(snapshot.jackpot) or 0),
        commonLowMax = math.max(0, tonumber(snapshot.commonLowMax) or 0),
        commonMediumMax = math.max(0, tonumber(snapshot.commonMediumMax) or 0),
        commonHighMax = math.max(0, tonumber(snapshot.commonHighMax) or 0),
        commonMin = math.max(0, tonumber(snapshot.commonMin) or 0),
        commonMax = math.max(0, tonumber(snapshot.commonMax) or 0),
        winners = type(snapshot.winners) == "table" and snapshot.winners or {}
    }
end

function Commands.ScratchTicket(player, args)
    if not player or not ScratchTickets or not ScratchTickets.CanScratchItem then
        return
    end

    local ticket = findTicketByID(player, args)
    if not ticket then
        return
    end

    if not ScratchTickets.CanScratchItem(ticket) then
        Helpers.SendResponse(player, "CurrencyExpanded", "ScratchTicketResult", {
            status = "ALREADY_SCRATCHED",
            itemID = ticket:getID(),
            amount = ScratchTickets.GetWinAmount(ticket),
            resultType = ScratchTickets.GetWinAmount(ticket) > 0 and "WIN" or "LOSE",
            tier = ScratchTickets.GetWinAmount(ticket) > 0 and "HIGH" or "LOSE"
        })
        return
    end

    local amount, resultType, tier = ScratchTickets.RollScratchOutcome(player)
    if resultType == "LOSE" then
        ScratchTickets.MarkLoser(ticket)
    else
        ScratchTickets.MarkWinner(ticket, amount)
    end

    if ScratchTickets.RecordScratchResult then
        ScratchTickets.RecordScratchResult(player, amount, resultType, tier)
    end

    if ticket.syncItemFields then
        ticket:syncItemFields()
    end

    Helpers.SendResponse(player, "CurrencyExpanded", "ScratchTicketResult", {
        status = "SCRATCHED",
        itemID = ticket:getID(),
        amount = amount,
        resultType = resultType,
        tier = tier
    })
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

function Commands.RequestScratchLotteryInfo(player, args)
    if not player then
        return
    end

    Helpers.SendResponse(player, "CurrencyExpanded", "ScratchLotteryInfo", buildLotteryInfoPayload(args and args.detail or "SUMMARY"))
end

local function OnClientCommand(module, command, player, args)
    if module == "CurrencyExpanded" and Commands[command] then
        Commands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

CurrencyExpanded.Log("CECommons", "Init", "ScratchTicket", "Registered scratch ticket payout system")
