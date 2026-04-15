pcall(require, "DT/Common/Config")

if DynamicTrading and DynamicTrading.RegisterArchetypeModule then
    DynamicTrading.RegisterArchetypeModule("Gambler")
end

if DynamicTrading and DynamicTrading.RegisterRosterPoolEntry then
    DynamicTrading.RegisterRosterPoolEntry("ce_gambler_independent", {
        archetypeID = "Gambler",
        factionID = "Independent",
        minCount = 1,
        priority = 1
    })
end
