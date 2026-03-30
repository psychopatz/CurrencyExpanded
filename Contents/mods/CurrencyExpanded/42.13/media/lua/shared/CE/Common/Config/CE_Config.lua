CurrencyExpanded = CurrencyExpanded or {}
CE_Config = CE_Config or {}

function CurrencyExpanded.Log(module, category, subcategory, message)
    print(string.format("[%s][%s][%s] %s", module, category, subcategory, message))
end

-- Add more shared helpers here if needed, or point to DynamicTrading's if preferred.
-- Since we want it independent, we define the basics here.
