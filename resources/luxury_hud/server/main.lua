-- luxury_hud: Lógica de Servidor - Persistencia de Ajustes
-- Compatible con TODAS las versiones de ESX (v1.1, v1.2, v1-final, Legacy) y Luxury Framework

local ESX = nil

-- Obtención segura de ESX sin causar "No such export"
local function getESX()
    local esxObj = nil
    -- 1. Evento tradicional de ESX (100% compatible con v1.1, v1.2, v1-final)
    TriggerEvent('esx:getSharedObject', function(obj)
        esxObj = obj
    end)
    if esxObj then return esxObj end

    -- 2. Export protegido con pcall para ESX Legacy moderno
    pcall(function()
        if exports['es_extended'] then
            esxObj = exports['es_extended']:getSharedObject()
        end
    end)
    if esxObj then return esxObj end

    -- 3. Fallback a luxury_core si está presente
    pcall(function()
        if exports['luxury_core'] then
            esxObj = exports['luxury_core']:GetESX()
        end
    end)
    return esxObj
end

CreateThread(function()
    while ESX == nil do
        ESX = getESX()
        if not ESX then
            Wait(250)
        end
    end
end)

--- Inicialización de Base de Datos Automática para HUD
CreateThread(function()
    while not MySQL do Wait(100) end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_hud_settings` (
            `citizenid` VARCHAR(60) NOT NULL PRIMARY KEY,
            `settings` LONGTEXT NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print('^2[luxury_hud]^7 Base de datos de preferencias de HUD verificada e instalada automáticamente.')
end)

--- Guardar preferencias personalizadas del jugador (/hud)
RegisterNetEvent('luxury_hud:server:saveSettings', function(settingsData)
    local src = source
    if not settingsData then return end

    local cid = tostring(src)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            cid = xPlayer.identifier or xPlayer.citizenid or cid
        end
    end

    local strSettings = type(settingsData) == 'table' and json.encode(settingsData) or tostring(settingsData)

    MySQL.insert([[
        INSERT INTO luxury_hud_settings (citizenid, settings)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings = VALUES(settings)
    ]], { cid, strSettings })
end)

--- Cargar preferencias al entrar el jugador
RegisterNetEvent('luxury_hud:server:requestSettings', function()
    local src = source
    local cid = tostring(src)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            cid = xPlayer.identifier or xPlayer.citizenid or cid
        end
    end

    local result = MySQL.query.await('SELECT settings FROM luxury_hud_settings WHERE citizenid = ? LIMIT 1', { cid })
    if result and result[1] and result[1].settings then
        TriggerClientEvent('luxury_hud:client:loadSettings', src, json.decode(result[1].settings))
    end
end)
