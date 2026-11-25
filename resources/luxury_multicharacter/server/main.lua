-- luxury_multicharacter: Lógica de Servidor
-- Compatible con Cfx.re Asset Escrow y Arquitectura Proxy Luxury Framework

local Proxy = Proxy or (exports['luxury_lib'] and exports['luxury_lib']:GetProxy()) or {}
local Luxury = Proxy.getInterface('luxury')

--- Inicialización de Base de Datos Automática para Multicharacter
CreateThread(function()
    while not MySQL do Wait(100) end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_players` (
            `id` INT AUTO_INCREMENT UNIQUE KEY,
            `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
            `license` VARCHAR(60) NOT NULL,
            `name` VARCHAR(100) DEFAULT NULL,
            `cash` INT NOT NULL DEFAULT 500,
            `bank` INT NOT NULL DEFAULT 5000,
            `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
            `job_grade` INT NOT NULL DEFAULT 0,
            `gang` VARCHAR(50) NOT NULL DEFAULT 'none',
            `gang_grade` INT NOT NULL DEFAULT 0,
            `group` VARCHAR(20) NOT NULL DEFAULT 'user',
            `charinfo` LONGTEXT DEFAULT NULL,
            `position` LONGTEXT DEFAULT NULL,
            `needs` VARCHAR(100) DEFAULT '{"hunger":100,"thirst":100}',
            `metadata` LONGTEXT DEFAULT NULL,
            `inventory` LONGTEXT DEFAULT NULL,
            `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_luxury_license` (`license`),
            INDEX `idx_luxury_job` (`job`),
            INDEX `idx_luxury_gang` (`gang`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print('^2[luxury_multicharacter]^7 Base de datos de personajes verificada e inicializada automáticamente.')
end)

--- Obtiene la licencia de Rockstar del jugador
local function getPlayerLicense(src)
    local fallback = nil
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.sub(id, 1, 9) == 'license2:' then
            return id
        elseif string.sub(id, 1, 8) == 'license:' then
            fallback = id
        end
    end
    return fallback
end

local function getAllLicenses(src)
    local l1, l2 = nil, nil
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.sub(id, 1, 8) == 'license:' then l1 = id end
        if string.sub(id, 1, 9) == 'license2:' then l2 = id end
    end
    local primary = l2 or l1
    return primary, l1 or primary, l2 or primary
end

--- Coloca al jugador en un Routing Bucket aislado al entrar en la selección
RegisterNetEvent('luxury_multicharacter:server:init', function()
    local src = source
    SetPlayerRoutingBucket(src, src)
end)

--- Solicitud de lista de personajes del jugador
RegisterNetEvent('luxury_multicharacter:server:requestCharacters', function()
    local src = source
    local license, l1, l2 = getAllLicenses(src)
    if not license then
        DropPlayer(src, '[LUXURY] No se pudo autenticar tu licencia de Rockstar.')
        return
    end

    local rows = MySQL.query.await([[
        SELECT citizenid, cash, bank, job, job_grade, gang, gang_grade, charinfo, position
        FROM luxury_players
        WHERE license = ? OR license = ? OR license = ?
        ORDER BY id ASC
    ]], { license, l1, l2 }) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        local charinfo = (type(row.charinfo) == 'string' and json.decode(row.charinfo)) or row.charinfo or {}
        local position = (type(row.position) == 'string' and json.decode(row.position)) or row.position or {}

        table.insert(characters, {
            citizenid = row.citizenid,
            firstname = charinfo.firstname or 'Ciudadano',
            lastname = charinfo.lastname or '',
            birthdate = charinfo.birthdate or '1998-01-01',
            gender = charinfo.gender or 0,
            nationality = charinfo.nationality or 'Los Santos',
            phone = charinfo.phone or 'N/A',
            job = row.job or 'unemployed',
            cash = tonumber(row.cash) or 0,
            bank = tonumber(row.bank) or 0,
            position = position
        })
    end

    TriggerClientEvent('luxury_multicharacter:client:setupUI', src, characters, Config.MaxCharacters)
end)

--- Selección y carga de un personaje
RegisterNetEvent('luxury_multicharacter:server:selectCharacter', function(citizenid)
    local src = source
    local license, l1, l2 = getAllLicenses(src)
    if not license or not citizenid then return end

    local row = MySQL.single.await([[
        SELECT citizenid, position FROM luxury_players WHERE citizenid = ? AND (license = ? OR license = ? OR license = ?)
    ]], { citizenid, license, l1, l2 })

    if not row then
        TriggerClientEvent('luxury_multicharacter:client:notify', src, 'error', 'El personaje no pertenece a tu cuenta.')
        return
    end

    -- Restaurar jugador al Routing Bucket global (0)
    SetPlayerRoutingBucket(src, 0)

    -- Iniciar sesión en el Core & compatibilidad ESX
    TriggerEvent('luxury_core:server:playerLoaded', src, citizenid)
    TriggerEvent('esx:playerLoaded', src, citizenid)

    local pos = (type(row.position) == 'string' and json.decode(row.position)) or row.position
    local spawnCoords = pos and vector4(pos.x, pos.y, pos.z, pos.w or 0.0) or Config.DefaultSpawns[1].coords

    TriggerClientEvent('luxury_multicharacter:client:spawnPlayer', src, spawnCoords)
end)

--- Creación de un nuevo personaje
RegisterNetEvent('luxury_multicharacter:server:createCharacter', function(data)
    local src = source
    local license, l1, l2 = getAllLicenses(src)
    if not license or not data then return end

    local countResult = MySQL.single.await([[
        SELECT COUNT(*) as total FROM luxury_players WHERE license = ? OR license = ? OR license = ?
    ]], { license, l1, l2 })

    local totalChars = countResult and countResult.total or 0
    if totalChars >= Config.MaxCharacters then
        TriggerClientEvent('luxury_multicharacter:client:notify', src, 'error', 'Has alcanzado el límite máximo de ranuras de personaje.')
        return
    end

    -- Generar Citizen ID único
    local citizenid = ('LX-%d'):format(math.random(10000, 99999))

    local charinfo = {
        firstname = data.firstname or 'Ciudadano',
        lastname = data.lastname or 'Nuevo',
        birthdate = data.birthdate or '1998-01-01',
        gender = tonumber(data.gender) or 0,
        nationality = data.nationality or 'Los Santos',
        phone = ('555-%04d'):format(math.random(1000, 9999)),
        licences = { driver = true, weapon = false, hunting = false, pilot = false }
    }

    local initialCash = 500
    local initialBank = 5000
    local spawnCoords = Config.DefaultSpawns[1].coords
    local position = { x = spawnCoords.x, y = spawnCoords.y, z = spawnCoords.z, w = spawnCoords.w }

    MySQL.insert([[
        INSERT INTO luxury_players (citizenid, license, name, cash, bank, job, job_grade, gang, gang_grade, charinfo, position)
        VALUES (?, ?, ?, ?, ?, 'unemployed', 0, 'none', 0, ?, ?)
    ]], {
        citizenid,
        license,
        GetPlayerName(src) or 'Jugador',
        initialCash,
        initialBank,
        json.encode(charinfo),
        json.encode(position)
    })

    -- Sacar al jugador del Routing Bucket aislado al mundo común
    SetPlayerRoutingBucket(src, 0)
    TriggerEvent('luxury_core:server:playerLoaded', src, citizenid)

    TriggerClientEvent('luxury_multicharacter:client:spawnPlayer', src, spawnCoords, true)
end)

--- Eliminación segura de un personaje
RegisterNetEvent('luxury_multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    if not Config.AllowDelete then return end
    local license = getPlayerLicense(src)
    if not license or not citizenid then return end

    local _, l1, l2 = getAllLicenses(src)
    MySQL.query.await([[
        DELETE FROM luxury_players WHERE citizenid = ? AND (license = ? OR license = ? OR license = ?)
    ]], { citizenid, license, l1, l2 })

    -- Limpiar datos asociados del personaje eliminado
    pcall(function() MySQL.query.await('DELETE FROM luxury_banking_transactions WHERE citizenid = ?', { citizenid }) end)
    pcall(function() MySQL.query.await('DELETE FROM luxury_hud_settings WHERE citizenid = ?', { citizenid }) end)
    pcall(function() MySQL.query.await('DELETE FROM luxury_owned_vehicles WHERE citizenid = ?', { citizenid }) end)
    pcall(function() MySQL.query.await('DELETE FROM player_vehicles WHERE citizenid = ?', { citizenid }) end)

    TriggerClientEvent('luxury_multicharacter:client:notify', src, 'success', 'Personaje eliminado exitosamente.')

    -- Refrescar la lista de personajes
    TriggerEvent('luxury_multicharacter:server:requestCharacters', src)
end)
