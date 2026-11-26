-- luxury_core: ESX Import Helper con resolución asíncrona reactiva
local function resolveESX()
    if rawget(_G, 'ESX') and type(ESX) == 'table' and (ESX.GetPlayerData or ESX.GetPlayerFromId) then
        return ESX
    end

    -- 1. Intentar export de luxury_core
    local ok, obj = pcall(function()
        return exports['luxury_core']:getSharedObject()
    end)
    if ok and obj and type(obj) == 'table' then
        return obj
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetSharedObject()
    end)
    if ok and obj and type(obj) == 'table' then
        return obj
    end

    ok, obj = pcall(function()
        return exports['luxury_core']:GetESX()
    end)
    if ok and obj and type(obj) == 'table' then
        return obj
    end

    -- 2. Intentar export de es_extended
    ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and obj and type(obj) == 'table' then
        return obj
    end

    return nil
end

ESX = resolveESX()

-- Si el recurso invocador arrancó antes que el framework, resolver de forma reactiva
if not ESX then
    local attempts = 0
    while not ESX and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
        ESX = resolveESX()
    end
end
