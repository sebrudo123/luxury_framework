-- ====================================================================
-- LUXURY FRAMEWORK - PLANTILLA OFICIAL DE BASE DE DATOS
-- Compatible con MariaDB / MySQL y motor oxmysql
-- Auto-migración y compatibilidad universal ESX + QBCore
-- ====================================================================

-- 1. Tabla Principal de Personajes y Jugadores
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

-- 2. Tabla de Sanciones y Baneos (Multi-Token HWID)
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
    INDEX `idx_ban_license` (`license`),
    INDEX `idx_ban_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabla de Auditoría y Seguridad Anti-Dump
CREATE TABLE IF NOT EXISTS `luxury_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(60) DEFAULT NULL,
    `action` TEXT NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_log_type` (`type`),
    INDEX `idx_log_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Tabla de Fondos Corporativos y Facciones (Sociedades)
CREATE TABLE IF NOT EXISTS `luxury_societies` (
    `name` VARCHAR(50) NOT NULL PRIMARY KEY,
    `label` VARCHAR(100) NOT NULL,
    `money` INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar Facciones Oficiales por defecto (Solo si no existen)
INSERT IGNORE INTO `luxury_societies` (`name`, `label`, `money`) VALUES
('police', 'Los Santos Police Department', 250000),
('ambulance', 'Emergency Medical Services (EMS)', 150000),
('mechanic', 'Los Santos Customs', 80000),
('taxi', 'Downtown Cab Co.', 50000),
('cardealer', 'Luxury Autos Dealership', 500000),
('realestate', 'Century 21 Real Estate', 300000);

-- 5. Tabla de Transacciones Bancarias (luxury_banking)
CREATE TABLE IF NOT EXISTS `luxury_banking_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(60) NOT NULL,
    `type` VARCHAR(30) NOT NULL,
    `amount` INT NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `sender` VARCHAR(100) NOT NULL,
    `recipient` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_banking_citizenid` (`citizenid`),
    INDEX `idx_banking_type` (`type`),
    INDEX `idx_banking_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Tabla de Vehículos en Propiedad y Garajes (luxury_garage)
CREATE TABLE IF NOT EXISTS `luxury_owned_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(60) NOT NULL,
    `plate` VARCHAR(12) NOT NULL UNIQUE,
    `vehicle` VARCHAR(50) NOT NULL,
    `mods` LONGTEXT DEFAULT NULL,
    `garage` VARCHAR(50) NOT NULL DEFAULT 'LegionSquare',
    `state` INT NOT NULL DEFAULT 1 COMMENT '1 = En Garaje, 0 = En Calle/Depósito, 2 = Incautado Policial',
    `fuel` INT NOT NULL DEFAULT 100,
    `engine` INT NOT NULL DEFAULT 1000,
    `body` INT NOT NULL DEFAULT 1000,
    `stored_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_veh_citizenid` (`citizenid`),
    INDEX `idx_veh_plate` (`plate`),
    INDEX `idx_veh_garage` (`garage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Tabla de Ajustes de Interfaz de Usuario (luxury_hud)
CREATE TABLE IF NOT EXISTS `luxury_hud_settings` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `settings` LONGTEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABLAS OFICIALES DE COMPATIBILIDAD CON JG-ADVANCEDGARAGES V4
-- Compatible con QBCore, Qbox, ESX y luxury_framework
-- ====================================================================

-- 1. Tabla de Vehículos de Jugadores (player_vehicles)
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

ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `damage` LONGTEXT DEFAULT '';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `in_garage` TINYINT(1) DEFAULT '1';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `garage_id` VARCHAR(255) DEFAULT 'Legion Square';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `job_vehicle` TINYINT(1) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `job_vehicle_rank` INT(10) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `gang_vehicle` TINYINT(1) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `gang_vehicle_rank` INT(10) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `impound` INT(10) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `impound_retrievable` INT(10) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `impound_data` LONGTEXT DEFAULT '';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `nickname` VARCHAR(255) DEFAULT '';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `favourite` TINYINT(1) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `admin_blocked` TINYINT(1) DEFAULT '0';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `admin_block_reason` LONGTEXT DEFAULT '';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `admin_blocked_by` VARCHAR(255) DEFAULT '';
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `admin_blocked_at` DATETIME DEFAULT NULL;

-- 2. Interiores de Garaje (garage_interiors)
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

ALTER TABLE `garage_interiors` ADD COLUMN IF NOT EXISTS `ipl_profile` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `garage_interiors` ADD COLUMN IF NOT EXISTS `vehicle_exit_points` LONGTEXT DEFAULT NULL;
ALTER TABLE `garage_interiors` ADD COLUMN IF NOT EXISTS `ipl_config` LONGTEXT DEFAULT NULL;
ALTER TABLE `garage_interiors` ADD COLUMN IF NOT EXISTS `detected_interior_id` VARCHAR(255) DEFAULT NULL;

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

-- 3. Ubicaciones de Garajes (garage_locations)
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

ALTER TABLE `garage_locations` ADD COLUMN IF NOT EXISTS `sale_options` LONGTEXT DEFAULT NULL;
ALTER TABLE `garage_locations` ADD COLUMN IF NOT EXISTS `template_id` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `garage_locations` ADD COLUMN IF NOT EXISTS `purchased_by` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `garage_locations` ADD COLUMN IF NOT EXISTS `purchase_price` INT DEFAULT NULL;
ALTER TABLE `garage_locations` ADD COLUMN IF NOT EXISTS `purchased_at` DATETIME DEFAULT NULL;

-- 4. Acceso a Garajes (garage_location_access)
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

ALTER TABLE `garage_location_access` ADD COLUMN IF NOT EXISTS `role` ENUM('owner', 'member') NOT NULL DEFAULT 'member';

-- 5. Garajes Privados de Jugadores (player_priv_garages)
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

-- 6. Vehículos Compartidos (garage_vehicle_shares)
CREATE TABLE IF NOT EXISTS `garage_vehicle_shares` (
  `plate` VARCHAR(16) NOT NULL,
  `owner_identifier` VARCHAR(255) NOT NULL,
  `identifier` VARCHAR(255) NOT NULL,
  `display_name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`plate`, `owner_identifier`, `identifier`),
  KEY `recipient` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Préstamos de Vehículos (garage_vehicle_loans)
CREATE TABLE IF NOT EXISTS `garage_vehicle_loans` (
  `plate` VARCHAR(16) NOT NULL,
  `owner_identifier` VARCHAR(255) NOT NULL,
  `borrower_identifier` VARCHAR(255) NOT NULL,
  `borrower_name` VARCHAR(255) NOT NULL,
  `garage_id` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Vehículos Favoritos (garage_vehicle_favourites)
CREATE TABLE IF NOT EXISTS `garage_vehicle_favourites` (
  `plate` VARCHAR(16) NOT NULL,
  `owner_identifier` VARCHAR(255) NOT NULL,
  `identifier` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`plate`, `owner_identifier`, `identifier`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Remolques de Vehículos (garage_vehicle_trailers)
CREATE TABLE IF NOT EXISTS `garage_vehicle_trailers` (
  `vehicle_plate` VARCHAR(8) NOT NULL,
  `trailer_plate` VARCHAR(8) NOT NULL,
  `position` TINYINT UNSIGNED NOT NULL,
  `data` LONGTEXT NOT NULL,
  PRIMARY KEY (`trailer_plate`),
  UNIQUE KEY `vehicle_position` (`vehicle_plate`, `position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Ajustes de Garajes (garage_settings)
CREATE TABLE IF NOT EXISTS `garage_settings` (
  `id` TINYINT UNSIGNED NOT NULL,
  `settings_data` LONGTEXT NOT NULL,
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `updated_by_identifier` VARCHAR(255) DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tabla legacy ESX owned_vehicles para compatibilidad con scripts clásicos
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

-- 11. Tabla de Usuarios ESX y Compatibilidad ox_inventory
CREATE TABLE IF NOT EXISTS `users` (
  `identifier` VARCHAR(60) NOT NULL PRIMARY KEY,
  `license` VARCHAR(60) DEFAULT NULL,
  `name` VARCHAR(100) DEFAULT NULL,
  `money` INT NOT NULL DEFAULT 500,
  `bank` INT NOT NULL DEFAULT 5000,
  `group` VARCHAR(50) DEFAULT 'user',
  `job` VARCHAR(50) DEFAULT 'unemployed',
  `job_grade` INT DEFAULT 0,
  `inventory` LONGTEXT DEFAULT NULL,
  `accounts` LONGTEXT DEFAULT NULL,
  `skin` LONGTEXT DEFAULT NULL,
  `position` LONGTEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_job` (`job`),
  INDEX `idx_users_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Tablas de Licencias ESX (licenses & user_licenses)
CREATE TABLE IF NOT EXISTS `licenses` (
  `type` VARCHAR(60) NOT NULL PRIMARY KEY,
  `label` VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES
  ('driver', 'Licencia de Conducir'),
  ('weapon', 'Weapon License'),
  ('dmv', 'Permiso de Tráfico (DMV)'),
  ('drive_bike', 'Licencia de Motos'),
  ('drive_truck', 'Licencia de Camiones'),
  ('hunting', 'Licencia de Caza');

CREATE TABLE IF NOT EXISTS `user_licenses` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `type` VARCHAR(60) NOT NULL,
  `owner` VARCHAR(60) NOT NULL,
  UNIQUE KEY `uk_user_licenses` (`type`, `owner`),
  INDEX `idx_lic_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
