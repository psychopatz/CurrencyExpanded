CurrencyExpanded = CurrencyExpanded or {}
CE_Config = CE_Config or {}
CurrencyExpanded.InteractionStrings = CurrencyExpanded.InteractionStrings or {}

local InteractionStrings = CurrencyExpanded.InteractionStrings
InteractionStrings.Registry = InteractionStrings.Registry or {}

local function mergeNestedTables(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return source
    end

    for key, value in pairs(source) do
        local existing = target[key]
        if type(existing) == "table" and type(value) == "table" and not existing[1] and not value[1] then
            mergeNestedTables(existing, value)
        else
            target[key] = value
        end
    end

    return target
end

local function getNestedValue(source, keyPath)
    local current = source
    for token in string.gmatch(tostring(keyPath or ""), "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[token]
    end
    return current
end

local function normalizeSystemID(systemID)
    return "CurrencyExpanded:" .. tostring(systemID or "")
end

function CurrencyExpanded.Log(module, category, subcategory, message)
    print(string.format("[%s][%s][%s] %s", module, category, subcategory, message))
end

function CurrencyExpanded.RegisterInteractionStrings(systemID, partID, data)
    if not systemID or not partID or type(data) ~= "table" then
        return
    end

    local registry = InteractionStrings.Registry
    registry[systemID] = registry[systemID] or {}
    registry[systemID][partID] = registry[systemID][partID] or {}
    mergeNestedTables(registry[systemID][partID], data)

    if DynamicTrading and DynamicTrading.RegisterInteractionStrings then
        DynamicTrading.RegisterInteractionStrings(normalizeSystemID(systemID), partID, data)
    end
end

function CurrencyExpanded.GetInteractionStrings(systemID, partID)
    local localSystem = InteractionStrings.Registry[tostring(systemID or "")]
    if type(localSystem) == "table" then
        local localPart = localSystem[tostring(partID or "")]
        if localPart ~= nil then
            return localPart
        end
    end

    if DynamicTrading and DynamicTrading.GetInteractionStrings then
        return DynamicTrading.GetInteractionStrings(normalizeSystemID(systemID), partID)
    end

    return nil
end

function CurrencyExpanded.ResolveInteractionString(systemID, partID, keyPath)
    local source = CurrencyExpanded.GetInteractionStrings(systemID, partID)
    if not keyPath or keyPath == "" then
        return source
    end
    return getNestedValue(source, keyPath)
end

function CurrencyExpanded.FormatInteractionString(template, tokens)
    if DynamicTrading and DynamicTrading.FormatInteractionString then
        return DynamicTrading.FormatInteractionString(template, tokens)
    end

    local text = tostring(template or "")
    return (string.gsub(text, "{(.-)}", function(token)
        local value = getNestedValue(tokens or {}, token)
        if value == nil then
            return "{" .. tostring(token) .. "}"
        end
        return tostring(value)
    end))
end

function CurrencyExpanded.RegisterManual(id, data)
    if DynamicTrading and DynamicTrading.RegisterManual then
        return DynamicTrading.RegisterManual(id, data)
    end

    return nil
end
