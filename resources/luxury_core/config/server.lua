-- luxury_core: Configuración Exclusiva del Servidor
Config = Config or {}

-- Autoguardado escalonado y limpieza automática de base de datos
Config.AutoSaveMinutes = 5
Config.AutoSaveBatchSize = 10      -- Jugadores guardados por lote para evitar picos SQL
Config.LogsRetentionDays = 30      -- Días de retención de registros en luxury_logs
Config.ArmorPersistence = true     -- Restaurar armadura guardada al conectar

-- Sistema de Nóminas (Paycheck) y Servicio
Config.PaycheckInterval = 10       -- Minutos entre cada pago de nómina
Config.PaycheckNotification = true
Config.PaycheckRequireDuty = true  -- Exigir estar de servicio (onduty) para cobrar sueldo en trabajos con turno

-- Sincronización de Coordenadas y Anti-Combat Log
Config.CoordsSyncInterval = 60000  -- 60 segundos
Config.CombatLogDuration = 45000   -- Milisegundos que permanece el marcador 3D tras desconectar (45s)

-- Dimensiones / Instancias (Routing Buckets)
Config.DefaultBucket = 0
Config.CharacterSelectionBucket = 100 -- Instancia privada mientras se crea o selecciona personaje
