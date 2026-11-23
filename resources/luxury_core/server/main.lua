-- luxury_core: Servidor Principal y Arranque de Base de Datos (Entrypoint)
Core = Core or {}
Core.Players = Core.Players or {}

---------------------------------------------------------------------
-- Base de Datos: Inicialización y Migración Automática Completa
---------------------------------------------------------------------
CreateThread(function()
    -- 1) Tabla de Jugadores y Personajes (luxury_players con soporte Multi-Character)
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

    -- Migraciones seguras no destructivas
    pcall(function()
        MySQL.query.await([[
            ALTER TABLE `luxury_players` 
            ADD COLUMN IF NOT EXISTS `id` INT AUTO_INCREMENT UNIQUE KEY,
            ADD COLUMN IF NOT EXISTS `position` LONGTEXT DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS `group` VARCHAR(20) NOT NULL DEFAULT 'user',
            ADD COLUMN IF NOT EXISTS `citizenid` VARCHAR(50) NOT NULL DEFAULT '',
            ADD COLUMN IF NOT EXISTS `needs` VARCHAR(100) DEFAULT '{"hunger":100,"thirst":100}',
            ADD COLUMN IF NOT EXISTS `gang` VARCHAR(50) NOT NULL DEFAULT 'none',
            ADD COLUMN IF NOT EXISTS `gang_grade` INT NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `metadata` LONGTEXT DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS `inventory` LONGTEXT DEFAULT NULL;
        ]])
    end)
    print('^2[luxury_core]^7 Base de datos de ^3`luxury_players`^7 verificada y migrada automáticamente.')

    -- 2) Tabla de Sanciones / Baneos (HWID Multi-Token)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_bans` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `license` VARCHAR(60) NOT NULL,
            `name` VARCHAR(100) DEFAULT 'Desconocido',
            `reason` TEXT NOT NULL,
            `author` VARCHAR(100) NOT NULL DEFAULT 'Consola',
            `expire` INT NOT NULL DEFAULT 0,
            `identifiers` LONGTEXT DEFAULT NULL,
            `tokens` LONGTEXT DEFAULT NULL,
            `ip` VARCHAR(50) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX (`license`),
            INDEX (`ip`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    pcall(function()
        MySQL.query.await([[
            ALTER TABLE `luxury_bans` 
            ADD COLUMN IF NOT EXISTS `identifiers` LONGTEXT DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS `tokens` LONGTEXT DEFAULT NULL,
            ADD COLUMN IF NOT EXISTS `ip` VARCHAR(50) DEFAULT NULL;
        ]])
    end)
    print('^5[LUXURY-DATABASE]^7 Tabla ^3`luxury_bans`^7 verificada y lista para producción.')
    MySQL.query([[
        DELETE FROM `luxury_bans` 
        WHERE `reason` LIKE '%Godmode%' OR `reason` LIKE '%Invencibilidad%'
    ]])
    print('^2[LUXURY-SECURITY]^7 Purgadas sanciones errÃ³neas de Godmode en luxury_bans.')

    -- 3) Tabla de Auditoría (luxury_logs)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `type` VARCHAR(50) NOT NULL,
            `identifier` VARCHAR(60) DEFAULT NULL,
            `action` TEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX (`type`),
            INDEX (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print('^5[LUXURY-DATABASE]^7 Tabla ^3`luxury_logs`^7 verificada y lista para producción.')

    -- 4) Tabla de Sociedades y Facciones (luxury_societies)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_societies` (
            `name` VARCHAR(50) NOT NULL PRIMARY KEY,
            `label` VARCHAR(100) NOT NULL,
            `money` INT NOT NULL DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local defaultSocieties = {
        { name = 'police', label = 'Policía Nacional' },
        { name = 'ambulance', label = 'Servicios Médicos (EMS)' },
        { name = 'mechanic', label = 'Taller Mecánico' },
        { name = 'taxi', label = 'Downtown Cab Co.' }
    }
    for _, soc in ipairs(defaultSocieties) do
        MySQL.query.await('INSERT IGNORE INTO `luxury_societies` (name, label, money) VALUES (?, ?, ?)', { soc.name, soc.label, 0 })
    end
    print('^5[LUXURY-DATABASE]^7 Tabla ^3`luxury_societies`^7 verificada y lista para producción.')

    -- Presentación del Banner Oficial
    if PrintLuxuryBanner then
        PrintLuxuryBanner()
    end

    -- Soporte para Hot Reload en caliente
    for _, strSrc in ipairs(GetPlayers()) do
        local src = tonumber(strSrc)
        if src and not Core.Players[src] then
            Core.LoadPlayer(src)
        end
    end
end)

---------------------------------------------------------------------
-- Verificación de Baneos y Evasión por Hardware (playerConnecting)
---------------------------------------------------------------------
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(50)
    deferrals.update(('Comprobando credenciales y seguridad para %s...'):format(playerName))

    if Security and Security.CheckBans then
        if Security.CheckBans(src, deferrals) then
            return
        end
    end

    deferrals.done()
end)

---------------------------------------------------------------------
-- Bucle de Nóminas y Salarios (Paycheck)
---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait((Config.PaycheckInterval or 10) * 60 * 1000)
        for src, player in pairs(Core.Players) do
            local salary = player.job.salary or 0
            if salary > 0 then
                player:addMoney('bank', salary)
                if Config.PaycheckNotification then
                    TriggerClientEvent('chat:addMessage', src, {
                        args = { '^2[Nómina]^7', ('Has recibido tu sueldo de ^2$%d^7 en el banco (%s - %s).'):format(salary, player.job.label, player.job.grade_label) }
                    })
                end
            end
        end
    end
end)

---------------------------------------------------------------------
-- Bucle de Autoguardado Periódico y Cierre del Recurso
---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait((Config.AutoSaveMinutes or 5) * 60 * 1000)
        for _, player in pairs(Core.Players) do
            player:save(true)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    print('^3[luxury_core]^7 Guardando datos de todos los jugadores antes de detener el recurso...')
    for _, player in pairs(Core.Players) do
        player:save(false)
    end
    print('^2[luxury_core]^7 Todos los jugadores han sido guardados con éxito.')
end)
