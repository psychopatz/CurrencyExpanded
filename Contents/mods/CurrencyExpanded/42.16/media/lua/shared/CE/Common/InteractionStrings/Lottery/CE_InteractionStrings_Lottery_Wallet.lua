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

CurrencyExpanded.RegisterInteractionStrings("Lottery", "Wallet", {
    Anticipation = getTextList("CECommon_Ambient_Wallet_Anticipation"),
    BulkStart = getTextList("CECommon_Ambient_Wallet_BulkStart"),
    BulkLoop = getTextList("CECommon_Ambient_Wallet_BulkLoop"),
    Empty = getTextList("CECommon_Ambient_Wallet_Empty"),
    Low = getTextList("CECommon_Ambient_Wallet_Low"),
    Medium = getTextList("CECommon_Ambient_Wallet_Medium"),
    High = getTextList("CECommon_Ambient_Wallet_High"),
})

return CurrencyExpanded.GetInteractionStrings("Lottery", "Wallet")
