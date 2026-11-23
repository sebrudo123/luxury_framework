-- ====================================================================
-- LUXURY CORE - ESQUEMA DE BASE DE DATOS (MYSQL / OXMYSQL)
-- Compatible con Cfx.re Asset Escrow y Arquitectura Proxy
-- ====================================================================

-- 1. Tabla Principal de Personajes y Jugadores
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
