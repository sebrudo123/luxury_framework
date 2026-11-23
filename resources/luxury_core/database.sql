-- luxury_core: Esquema de Base de Datos SQL Oficial (v1.0.0 - Qbox Architecture)
-- luxury_core crea y migra automáticamente todas las tablas al arrancar el servidor.

CREATE TABLE IF NOT EXISTS `luxury_players` (
    `license` VARCHAR(60) NOT NULL,
    `citizenid` VARCHAR(20) DEFAULT NULL,
    `name` VARCHAR(100) DEFAULT NULL,
    `cash` INT NOT NULL DEFAULT 0,
    `bank` INT NOT NULL DEFAULT 0,
    `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
    `job_grade` INT NOT NULL DEFAULT 0,
    `gang` VARCHAR(50) NOT NULL DEFAULT 'none',
    `gang_grade` INT NOT NULL DEFAULT 0,
    `group` VARCHAR(20) NOT NULL DEFAULT 'user',
    `charinfo` LONGTEXT DEFAULT NULL,
    `position` LONGTEXT DEFAULT NULL,
    `needs` VARCHAR(100) DEFAULT '{"hunger":100,"thirst":100}',
    `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`license`),
    UNIQUE KEY `uk_citizenid` (`citizenid`),
    INDEX `idx_gang` (`gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

CREATE TABLE IF NOT EXISTS `luxury_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(60) DEFAULT NULL,
    `action` TEXT NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (`type`),
    INDEX (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `luxury_societies` (
    `name` VARCHAR(50) NOT NULL PRIMARY KEY,
    `label` VARCHAR(100) NOT NULL,
    `money` INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `luxury_societies` (`name`, `label`, `money`) VALUES
('police', 'Policía Nacional', 0),
('ambulance', 'Servicios Médicos (EMS)', 0),
('mechanic', 'Taller Mecánico', 0),
('taxi', 'Downtown Cab Co.', 0);
