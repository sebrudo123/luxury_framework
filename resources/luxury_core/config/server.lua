-- luxury_core: Configuración Exclusiva del Servidor
Config = Config or {}

-- Autoguardado periódico en base de datos (minutos)
Config.AutoSaveMinutes = 5

-- Sistema de Nóminas (Paycheck)
Config.PaycheckInterval = 10 -- Minutos entre cada pago de nómina
Config.PaycheckNotification = true

-- Sincronización de Coordenadas
Config.CoordsSyncInterval = 60000 -- 60 segundos

-- Dimensiones / Instancias (Routing Buckets)
Config.DefaultBucket = 0
Config.CharacterSelectionBucket = 100 -- Instancia privada mientras se crea o selecciona personaje
