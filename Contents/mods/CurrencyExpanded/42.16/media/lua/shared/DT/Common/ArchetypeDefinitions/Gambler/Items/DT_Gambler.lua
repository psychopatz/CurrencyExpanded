pcall(require, "DT/Common/Config")

if DynamicTrading and DynamicTrading.RegisterArchetype then
    DynamicTrading.RegisterArchetype("Gambler", {
        name = "Lottery Agent",
        preferredFactionID = "Independent",
        allowedFactions = { "Independent" },
        minFactionWealth = 25000,
        supportsScratchClaims = true,
        disableSellTab = true,
        disableWildcardStock = true,
        allocations = {
            { item = "Base.ScratchTicket", count = 1, fixedQty = 50, fixedPrice = 100 }
        },
        expertTags = {},
        wants = {},
        forbid = { "*" }
    })
end
