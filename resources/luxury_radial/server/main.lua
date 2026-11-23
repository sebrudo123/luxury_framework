-- luxury_radial: Lógica de Servidor
-- Compatible con ESX y Luxury Framework

local ESX = nil

-- Obtención segura de ESX
CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        if not ESX then
            pcall(function()
                if exports['es_extended'] then ESX = exports['es_extended']:getSharedObject() end
            end)
        end
        if not ESX then
            pcall(function()
                if exports['luxury_core'] then ESX = exports['luxury_core']:GetESX() end
            end)
        end
        if not ESX then Wait(250) end
    end
end)

--- Mostrar documento DNI a jugadores cercanos
RegisterNetEvent('luxury_radial:server:showIdCard', function()
    local src = source
    if not ESX then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local name = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or 'Ciudadano'
    local job = xPlayer.job and xPlayer.job.label or 'Desempleado'

    TriggerClientEvent('esx:showNotification', src, ('~g~Mostraste tu DNI: ~w~%s (~b~%s~w~)'):format(name, job))
end)
