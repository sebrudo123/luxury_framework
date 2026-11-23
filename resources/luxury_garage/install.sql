-- =====================================================================
-- Esquema de Base de Datos para luxury_garage
-- Se auto-ejecuta automáticamente al arrancar el servidor FiveM
-- =====================================================================

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
