-- luxury_core: QBCore Import Helper con espera de arranque y fallback
local function resolveQBCore()
    if rawget(_G, 'QBCore') and type(QBCore) == 'table' and QBCore.Functions then
        return QBCore
    end

    -- 1. Intentar export de luxury_core
    local ok, obj = pcall(function()
        return exports['luxury_core']:GetCoreObject()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        return obj
    end

    -- 2. Intentar export con GetQBCore
    ok, obj = pcall(function()
        return exports['luxury_core']:GetQBCore()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        return obj
    end

    -- 3. Intentar export nativo qb-core
    ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and obj and type(obj) == 'table' and obj.Functions then
        return obj
    end

    return nil
end

QBCore = resolveQBCore()

-- Si el recurso invocador arrancó antes que el framework, resolver de forma reactiva
if not QBCore then
    local attempts = 0
    while not QBCore and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
        QBCore = resolveQBCore()
    end
end
