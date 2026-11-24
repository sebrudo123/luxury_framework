-- luxury_core: Configuración Compartida (Cliente y Servidor)
Config = Config or {}

-- Dinero inicial de un personaje nuevo y cuentas soportadas
Config.StartCash = 500
Config.StartBank = 2500
Config.StartBlackMoney = 0
Config.StartCrypto = 0
Config.Accounts = {
    cash = { label = 'Efectivo' },
    bank = { label = 'Banco' },
    black_money = { label = 'Dinero Negro' },
    crypto = { label = 'Cripto' }
}

-- Trabajo y Banda predeterminados
Config.DefaultJob = { name = 'unemployed', grade = 0 }
Config.DefaultGang = { name = 'none', grade = 0 }

-- Coordenadas de Spawn por defecto (Aeropuerto Internacional de Los Santos)
Config.DefaultSpawn = { x = -1037.0, y = -2737.0, z = 13.8, heading = 0.0 }

-- Reaparición Médica (Hospital Pillbox Hill)
Config.HospitalCoords = { x = 307.74, y = -595.02, z = 43.28, heading = 18.0 }
Config.HospitalFee = 250 -- Coste de atención médica al despertar
Config.BleedoutTimer = 300 -- Segundos en coma antes de poder reaparecer (5 min)

-- Jerarquía de Grupos Administrativos
Config.Groups = { user = 0, mod = 1, admin = 2 }

-- Configuración del Sistema de Necesidades (Hambre y Sed)
Config.Status = {
    TickInterval = 60000, -- 60 segundos
    HungerRate = 0.5,    -- Desgaste de hambre por minuto
    ThirstRate = 0.8,    -- Desgaste de sed por minuto
    StarvationDamage = 5 -- Daño a la salud por minuto al llegar a 0%
}
