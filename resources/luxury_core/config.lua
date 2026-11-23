-- luxury_core: Configuración Raíz (Carga modular de config/shared.lua, config/server.lua y config/client.lua)
Config = Config or {}

-- 1) Carga de parámetros compartidos
Config.StartCash = 500
Config.StartBank = 2500
Config.DefaultJob = { name = 'unemployed', grade = 0 }
Config.DefaultGang = { name = 'none', grade = 0 }
Config.DefaultSpawn = { x = -1037.0, y = -2737.0, z = 13.8, heading = 0.0 }
Config.HospitalCoords = { x = 307.74, y = -595.02, z = 43.28, heading = 18.0 }
Config.HospitalFee = 250
Config.BleedoutTimer = 300
Config.Groups = { user = 0, mod = 1, admin = 2 }

Config.Status = {
    TickInterval = 60000,
    HungerRate = 0.5,
    ThirstRate = 0.8,
    StarvationDamage = 5
}

-- 2) Parámetros de Servidor
Config.AutoSaveMinutes = 5
Config.PaycheckInterval = 10
Config.PaycheckNotification = true
Config.CoordsSyncInterval = 60000
Config.DefaultBucket = 0
Config.CharacterSelectionBucket = 100

-- Seguridad Anti-Dump: Los administradores se definen privadamente en server/admins.lua o vía base de datos /setGroup
Config.Admins = {}
