-- luxury_core: Configuración Raíz
-- Los valores canónicos se encuentran en config/shared.lua, config/server.lua y config/client.lua.
-- Este archivo mantiene fallbacks retroactivos sin sobrescribir configuraciones modulares.
Config = Config or {}

Config.StartCash = Config.StartCash or 500
Config.StartBank = Config.StartBank or 2500
Config.StartBlackMoney = Config.StartBlackMoney or 0
Config.StartCrypto = Config.StartCrypto or 0
Config.DefaultJob = Config.DefaultJob or { name = 'unemployed', grade = 0 }
Config.DefaultGang = Config.DefaultGang or { name = 'none', grade = 0 }
Config.DefaultSpawn = Config.DefaultSpawn or { x = -1037.0, y = -2737.0, z = 13.8, heading = 0.0 }
Config.HospitalCoords = Config.HospitalCoords or { x = 307.74, y = -595.02, z = 43.28, heading = 18.0 }
Config.HospitalFee = Config.HospitalFee or 250
Config.BleedoutTimer = Config.BleedoutTimer or 300
Config.Groups = Config.Groups or { user = 0, mod = 1, admin = 2 }

Config.Status = Config.Status or {
    TickInterval = 60000,
    HungerRate = 0.5,
    ThirstRate = 0.8,
    StarvationDamage = 5
}

Config.AutoSaveMinutes = Config.AutoSaveMinutes or 5
Config.PaycheckInterval = Config.PaycheckInterval or 10
Config.PaycheckNotification = Config.PaycheckNotification ~= false
Config.CoordsSyncInterval = Config.CoordsSyncInterval or 60000
Config.DefaultBucket = Config.DefaultBucket or 0
Config.CharacterSelectionBucket = Config.CharacterSelectionBucket or 100

-- Seguridad Anti-Dump: Los administradores se definen privadamente en server/admins.lua o vía base de datos /setGroup
Config.Admins = Config.Admins or {}
