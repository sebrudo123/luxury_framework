-- =====================================================================
-- Esquema de Base de Datos para luxury_banking (Edición ESX)
-- Se auto-ejecuta de manera automática al iniciar el servidor FiveM
-- =====================================================================

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
