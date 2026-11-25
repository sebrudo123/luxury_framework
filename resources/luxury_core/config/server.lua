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

-- Configuración del Centinela Anti-Cheat (Luxury Sentinel)
Config.Security = {
    Enabled = true,
    Mode = 'strict',              -- 'strict' (ban/kick tras strikes), 'log' (solo alertas a Discord/staff sin banear)
    MaxStrikes = 3,               -- Advertencias antes de sanción automática en detecciones heurísticas
    TeleportGraceSeconds = 6,     -- Segundos de gracia tras teleport legítimo del servidor
    ServerCoordsCheckMs = 3000,   -- Frecuencia de revisión de teletransporte autoritativo en servidor
    HeartbeatTimeoutSec = 75,     -- Segundos sin respuesta al desafío criptográfico antes de expulsión
    RequireSessionToken = false,  -- Poner en true cuando todos los recursos externos reenvíen el token de sesión
    CheckResourceInjection = true,-- Verifica si el cliente inyectó recursos extra no iniciados por el servidor
    UseScreenshots = true,        -- Captura pantalla automática si screenshot-basic está iniciado
    RequireDiscord = false,       -- Exigir Discord vinculado para entrar al servidor
    MaxEntitiesWindowSec = 3,     -- Ventana de tiempo (segundos) para conteo de spawn masivo
    MaxVehiclesPerWindow = 6,
    MaxPedsPerWindow = 8,
    MaxObjectsPerWindow = 10,
    MaxParticlesPerWindow = 10,
    MaxFiresPerWindow = 3,
    MaxWeaponSingleHitDamage = 450
}
