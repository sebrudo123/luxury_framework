-- luxury_core: Servidor Principal y Arranque de Base de Datos (Entrypoint)
Core = Core or {}
Core.Players = Core.Players or {}

---------------------------------------------------------------------
-- Base de Datos: Inicialización y Migración Automática Completa
---------------------------------------------------------------------
function Core.RunDatabaseMigrations()
    -- 1) Tabla de Jugadores y Personajes (luxury_players con soporte Multi-Character)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `luxury_players` (
            `id` INT AUTO_INCREMENT UNIQUE KEY,
            `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
            `license` VARCHAR(60) NOT NULL,
            `name` VARCHAR(100) DEFAULT NULL,
            `cash` INT NOT NULL DEFAULT 500,
            `bank` INT NOT NULL DEFAULT 5000,
            `black_money` INT NOT NULL DEFAULT 0,
            `crypto` INT NOT NULL DEFAULT 0,
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
            ADD COLUMN IF NOT EXISTS `black_money` INT NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `crypto` INT NOT NULL DEFAULT 0,
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

    -- 5) Compatibilidad completa con jg-advancedgarages v4 y player_vehicles
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `player_vehicles` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `license` VARCHAR(50) DEFAULT NULL,
            `citizenid` VARCHAR(50) DEFAULT NULL,
            `vehicle` VARCHAR(50) DEFAULT NULL,
            `hash` VARCHAR(50) DEFAULT NULL,
            `mods` LONGTEXT DEFAULT NULL,
            `plate` VARCHAR(15) NOT NULL,
            `fakeplate` VARCHAR(50) DEFAULT NULL,
            `garage` VARCHAR(50) DEFAULT 'Legion Square',
            `fuel` INT(11) DEFAULT 100,
            `engine` FLOAT DEFAULT 1000,
            `body` FLOAT DEFAULT 1000,
            `state` INT(11) DEFAULT 1,
            `depotprice` INT(11) NOT NULL DEFAULT 0,
            `drivingdistance` INT(50) DEFAULT NULL,
            `status` TEXT DEFAULT NULL,
            `balance` INT(11) NOT NULL DEFAULT 0,
            `paymentamount` INT(11) NOT NULL DEFAULT 0,
            `paymentsleft` INT(11) NOT NULL DEFAULT 0,
            `financetime` INT(11) NOT NULL DEFAULT 0,
            `damage` LONGTEXT DEFAULT '',
            `in_garage` TINYINT(1) DEFAULT '1',
            `garage_id` VARCHAR(255) DEFAULT 'Legion Square',
            `job_vehicle` TINYINT(1) DEFAULT '0',
            `job_vehicle_rank` INT(10) DEFAULT '0',
            `gang_vehicle` TINYINT(1) DEFAULT '0',
            `gang_vehicle_rank` INT(10) DEFAULT '0',
            `impound` INT(10) DEFAULT '0',
            `impound_retrievable` INT(10) DEFAULT '0',
            `impound_data` LONGTEXT DEFAULT '',
            `nickname` VARCHAR(255) DEFAULT '',
            `favourite` TINYINT(1) DEFAULT '0',
            `admin_blocked` TINYINT(1) DEFAULT '0',
            `admin_block_reason` LONGTEXT DEFAULT '',
            `admin_blocked_by` VARCHAR(255) DEFAULT '',
            `admin_blocked_at` DATETIME DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_player_veh_plate` (`plate`),
            KEY `idx_player_veh_citizenid` (`citizenid`),
            KEY `idx_player_veh_license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    pcall(function()
        MySQL.query.await([[
            ALTER TABLE `player_vehicles` 
            ADD COLUMN IF NOT EXISTS `damage` LONGTEXT DEFAULT '',
            ADD COLUMN IF NOT EXISTS `in_garage` TINYINT(1) DEFAULT '1',
            ADD COLUMN IF NOT EXISTS `garage_id` VARCHAR(255) DEFAULT 'Legion Square',
            ADD COLUMN IF NOT EXISTS `job_vehicle` TINYINT(1) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `job_vehicle_rank` INT(10) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `gang_vehicle` TINYINT(1) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `gang_vehicle_rank` INT(10) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `impound` INT(10) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `impound_retrievable` INT(10) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `impound_data` LONGTEXT DEFAULT '',
            ADD COLUMN IF NOT EXISTS `nickname` VARCHAR(255) DEFAULT '',
            ADD COLUMN IF NOT EXISTS `favourite` TINYINT(1) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `admin_blocked` TINYINT(1) DEFAULT '0',
            ADD COLUMN IF NOT EXISTS `admin_block_reason` LONGTEXT DEFAULT '',
            ADD COLUMN IF NOT EXISTS `admin_blocked_by` VARCHAR(255) DEFAULT '',
            ADD COLUMN IF NOT EXISTS `admin_blocked_at` DATETIME DEFAULT NULL;
        ]])
    end)

    -- Tablas complementarias de jg-advancedgarages v4
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `garage_interiors` (
            `id` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `disabled` TINYINT(1) NOT NULL DEFAULT '0',
            `entrance` LONGTEXT NOT NULL,
            `entrance_interaction` LONGTEXT DEFAULT NULL,
            `camera_cutscene` LONGTEXT NOT NULL,
            `vehicle_positions` LONGTEXT NOT NULL,
            `vehicle_exit_points` LONGTEXT DEFAULT NULL,
            `ipl_profile` VARCHAR(255) DEFAULT NULL,
            `ipl_config` LONGTEXT DEFAULT NULL,
            `detected_interior_id` VARCHAR(255) DEFAULT NULL,
            `is_default` TINYINT(1) NOT NULL DEFAULT '0',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_locations` (
            `id` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `kind` VARCHAR(20) NOT NULL,
            `restriction_type` VARCHAR(20) NOT NULL DEFAULT 'public',
            `vehicle_type` VARCHAR(20) NOT NULL DEFAULT 'car',
            `disabled` TINYINT(1) NOT NULL DEFAULT '0',
            `map_position` LONGTEXT DEFAULT NULL,
            `open_interactions` LONGTEXT NOT NULL,
            `use_open_interactions_for_store` TINYINT(1) NOT NULL DEFAULT '1',
            `store_interactions` LONGTEXT DEFAULT NULL,
            `spawn_points` LONGTEXT DEFAULT NULL,
            `blip` LONGTEXT DEFAULT NULL,
            `markers` LONGTEXT DEFAULT NULL,
            `distance` FLOAT DEFAULT '15',
            `restriction_data` LONGTEXT DEFAULT NULL,
            `vehicle_rules` LONGTEXT DEFAULT NULL,
            `impound_options` LONGTEXT DEFAULT NULL,
            `interior_id` VARCHAR(255) DEFAULT NULL,
            `sale_options` LONGTEXT DEFAULT NULL,
            `template_id` VARCHAR(255) DEFAULT NULL,
            `purchased_by` VARCHAR(255) DEFAULT NULL,
            `purchase_price` INT DEFAULT NULL,
            `purchased_at` DATETIME DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `kind` (`kind`),
            KEY `restriction_type` (`restriction_type`),
            KEY `vehicle_type` (`vehicle_type`),
            KEY `interior_id` (`interior_id`),
            KEY `template_id` (`template_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_location_access` (
            `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
            `garage_id` VARCHAR(255) NOT NULL,
            `identifier` VARCHAR(255) NOT NULL,
            `display_name` VARCHAR(255) DEFAULT NULL,
            `access_type` VARCHAR(50) NOT NULL DEFAULT 'user',
            `role` ENUM('owner', 'member') NOT NULL DEFAULT 'member',
            PRIMARY KEY (`id`),
            UNIQUE KEY `garage_identifier` (`garage_id`, `identifier`),
            KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `player_priv_garages` (
            `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
            `owners` LONGTEXT,
            `name` VARCHAR(255),
            `type` VARCHAR(50),
            `x` FLOAT,
            `y` FLOAT,
            `z` FLOAT,
            `h` FLOAT,
            `distance` INT(11) DEFAULT '10',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_vehicle_shares` (
            `plate` VARCHAR(16) NOT NULL,
            `owner_identifier` VARCHAR(255) NOT NULL,
            `identifier` VARCHAR(255) NOT NULL,
            `display_name` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`plate`, `owner_identifier`, `identifier`),
            KEY `recipient` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_vehicle_loans` (
            `plate` VARCHAR(16) NOT NULL,
            `owner_identifier` VARCHAR(255) NOT NULL,
            `borrower_identifier` VARCHAR(255) NOT NULL,
            `borrower_name` VARCHAR(255) NOT NULL,
            `garage_id` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_vehicle_favourites` (
            `plate` VARCHAR(16) NOT NULL,
            `owner_identifier` VARCHAR(255) NOT NULL,
            `identifier` VARCHAR(255) NOT NULL,
            PRIMARY KEY (`plate`, `owner_identifier`, `identifier`),
            KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_vehicle_trailers` (
            `vehicle_plate` VARCHAR(8) NOT NULL,
            `trailer_plate` VARCHAR(8) NOT NULL,
            `position` TINYINT UNSIGNED NOT NULL,
            `data` LONGTEXT NOT NULL,
            PRIMARY KEY (`trailer_plate`),
            UNIQUE KEY `vehicle_position` (`vehicle_plate`, `position`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

        CREATE TABLE IF NOT EXISTS `garage_settings` (
            `id` TINYINT UNSIGNED NOT NULL,
            `settings_data` LONGTEXT NOT NULL,
            `version` INT UNSIGNED NOT NULL DEFAULT 1,
            `updated_by_identifier` VARCHAR(255) DEFAULT NULL,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Interior por defecto de jg-advancedgarages v4
    MySQL.query.await([[
        INSERT IGNORE INTO `garage_interiors`
        (`id`, `name`, `disabled`, `entrance`, `entrance_interaction`, `camera_cutscene`, `vehicle_positions`, `ipl_profile`, `ipl_config`, `detected_interior_id`, `is_default`)
        VALUES
        (
            'default',
            'Default Garage Interior',
            0,
            '{"x":227.96,"y":-1003.06,"z":-99.0,"w":0.0}',
            NULL,
            '[{"x":227.96,"y":-977.81,"z":-98.99,"w":0.0},{"x":227.96,"y":-1006.96,"z":-98.99,"w":0.0}]',
            '[{"x":233.0,"y":-984.0,"z":-99.410004,"w":118.0},{"x":233.0,"y":-988.5,"z":-99.410004,"w":118.0},{"x":233.0,"y":-993.0,"z":-99.410004,"w":118.0},{"x":233.0,"y":-997.5,"z":-99.410004,"w":118.0},{"x":233.0,"y":-1002.0,"z":-99.410004,"w":118.0},{"x":223.600006,"y":-979.0,"z":-99.410004,"w":235.199997},{"x":223.600006,"y":-983.599976,"z":-99.410004,"w":235.199997},{"x":223.600006,"y":-988.200012,"z":-99.410004,"w":235.199997},{"x":223.600006,"y":-992.799988,"z":-99.410004,"w":235.199997},{"x":223.600006,"y":-997.400024,"z":-99.410004,"w":235.199997},{"x":223.600006,"y":-1002.0,"z":-99.410004,"w":235.199997}]',
            NULL,
            NULL,
            NULL,
            1
        );
    ]])
    print('^5[LUXURY-DATABASE]^7 Tablas e interiores de ^3jg-advancedgarages v4^7 verificadas y listas.')

    -- 6) Tabla legacy ESX owned_vehicles para compatibilidad con scripts ESX clásicos
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `owned_vehicles` (
            `owner` VARCHAR(60) NOT NULL,
            `plate` VARCHAR(12) NOT NULL,
            `vehicle` LONGTEXT DEFAULT NULL,
            `type` VARCHAR(20) NOT NULL DEFAULT 'car',
            `job` VARCHAR(20) DEFAULT NULL,
            `stored` TINYINT(1) NOT NULL DEFAULT 0,
            `parking` VARCHAR(60) DEFAULT NULL,
            `pound` VARCHAR(60) DEFAULT NULL,
            `glovebox` LONGTEXT DEFAULT NULL,
            `trunk` LONGTEXT DEFAULT NULL,
            PRIMARY KEY (`plate`),
            KEY `idx_owned_owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    print('^5[LUXURY-DATABASE]^7 Tabla ^3`owned_vehicles`^7 (compatibilidad ESX legacy) verificada.')

    -- 7) Auto-limpieza de registros históricos en luxury_logs
    local retentionDays = tonumber(Config.LogsRetentionDays) or 30
    if retentionDays > 0 then
        pcall(function()
            MySQL.query('DELETE FROM `luxury_logs` WHERE `created_at` < DATE_SUB(NOW(), INTERVAL ? DAY)', { retentionDays })
        end)
    end

    return true
end

exports('RunDatabaseMigrations', Core.RunDatabaseMigrations)

CreateThread(function()
    Core.RunDatabaseMigrations()

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
-- Bucle de Nóminas y Salarios (Paycheck con control onduty)
---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait((Config.PaycheckInterval or 10) * 60 * 1000)
        for src, player in pairs(Core.Players) do
            local salary = player.job.salary or 0
            local requireDuty = Config.PaycheckRequireDuty ~= false and player.job.name ~= 'unemployed'
            local isOnDuty = player:isOnDuty()

            if salary > 0 and (not requireDuty or isOnDuty) then
                player:addMoney('bank', salary, 'Nómina automática')
                if Config.PaycheckNotification then
                    TriggerClientEvent('chat:addMessage', src, {
                        args = { '^2[Nómina]^7', ('Has recibido tu sueldo de ^2$%d^7 en el banco (%s - %s).'):format(salary, player.job.label, player.job.grade_label) }
                    })
                end
            elseif salary > 0 and requireDuty and not isOnDuty and Config.PaycheckNotification then
                TriggerClientEvent('chat:addMessage', src, {
                    args = { '^3[Nómina]^7', 'No recibiste salario por encontrarte ^1fuera de servicio^7 (/duty).' }
                })
            end
        end
    end
end)

---------------------------------------------------------------------
-- Bucle de Autoguardado Escalonado por Lotes y Limpieza Periódica
---------------------------------------------------------------------
CreateThread(function()
    local cycleCount = 0
    while true do
        Wait((Config.AutoSaveMinutes or 5) * 60 * 1000)
        cycleCount = cycleCount + 1

        local batchSize = Config.AutoSaveBatchSize or 10
        local count = 0
        for _, player in pairs(Core.Players) do
            player:save(true)
            count = count + 1
            if count % batchSize == 0 then
                Wait(100)
            end
        end

        -- Cada 12 ciclos (~1h), purgar logs antiguos
        if cycleCount % 12 == 0 then
            local retentionDays = tonumber(Config.LogsRetentionDays) or 30
            if retentionDays > 0 then
                pcall(function()
                    MySQL.query('DELETE FROM `luxury_logs` WHERE `created_at` < DATE_SUB(NOW(), INTERVAL ? DAY)', { retentionDays })
                end)
            end
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
