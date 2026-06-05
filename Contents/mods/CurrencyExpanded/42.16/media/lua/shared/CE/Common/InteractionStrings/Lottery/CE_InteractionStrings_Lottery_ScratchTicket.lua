require "CE/Common/Config/CE_Config"

CurrencyExpanded = CurrencyExpanded or {}

if not CurrencyExpanded.RegisterInteractionStrings then
    return nil
end

local function getTextList(prefix)
    if CurrencyExpanded.Text and CurrencyExpanded.Text.GetList then
        return CurrencyExpanded.Text.GetList(prefix, {})
    end

    return {}
end

CurrencyExpanded.RegisterInteractionStrings("Lottery", "ScratchTicket", {
    Anticipation = getTextList("CECommon_Ambient_ScratchTicket_Anticipation"),
    BulkStart = getTextList("CECommon_Ambient_ScratchTicket_BulkStart"),
    BulkLoop = getTextList("CECommon_Ambient_ScratchTicket_BulkLoop"),
    Lose = getTextList("CECommon_Ambient_ScratchTicket_Lose"),
    Low = getTextList("CECommon_Ambient_ScratchTicket_Low"),
    Medium = getTextList("CECommon_Ambient_ScratchTicket_Medium"),
    High = getTextList("CECommon_Ambient_ScratchTicket_High"),
    Jackpot = getTextList("CECommon_Ambient_ScratchTicket_Jackpot"),
    AlreadyScratched = getTextList("CECommon_Ambient_ScratchTicket_AlreadyScratched"),
})

return CurrencyExpanded.GetInteractionStrings("Lottery", "ScratchTicket")
