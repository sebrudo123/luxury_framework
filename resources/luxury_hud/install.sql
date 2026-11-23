-- ====================================================================
-- LUXURY HUD - ESQUEMA DE BASE DE DATOS (MYSQL / OXMYSQL)
-- Compatible con Cfx.re Asset Escrow y Arquitectura Proxy
-- ====================================================================

CREATE TABLE IF NOT EXISTS `luxury_hud_settings` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `settings` LONGTEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
