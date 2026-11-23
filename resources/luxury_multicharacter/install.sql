-- ====================================================================
-- LUXURY MULTICHARACTER - ESQUEMA DE BASE DE DATOS (MYSQL / OXMYSQL)
-- Compatible con Cfx.re Asset Escrow y Arquitectura Proxy
-- ====================================================================

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
