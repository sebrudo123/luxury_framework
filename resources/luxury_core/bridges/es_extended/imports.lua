-- luxury_core: ESX Import Helper (0.00ms no bloqueante)
local function resolveESX()
    if rawget(_G, 'ESX') and type(ESX) == 'table' and (ESX.GetPlayerData or ESX.GetPlayerFromId) then
        return ESX
    end

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

    return nil
end

ESX = resolveESX()

-- Resolución asíncrona en hilo separado para NUNCA bloquear el inicio del recurso
if not ESX then
    CreateThread(function()
        local attempts = 0
        while not ESX and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
            ESX = resolveESX()
        end
    end)
end
