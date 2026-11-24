-- luxury_core: Configuración Privada de Webhooks de Discord (Server-Side Only)
-- Este archivo es estrictamente del servidor. NUNCA se envía al cliente.
-- Los dumpers jamás podrán ver tus URLs ni tokens de Discord.

Webhooks = {
    -- Pega aquí tus Webhook URLs de Discord (o déjalas vacías si no las utilizas)
    Bans = '',         -- Canal de Baneos HWID y Sanciones
    Anticheat = '',    -- Canal de Detecciones y Alertas Centinela
    Admin = '',        -- Canal de Registro de Comandos Administrativos
    Money = '',        -- Canal de Auditoría de Transferencias, Sociedades y Economía
    Connections = '',  -- Canal de Entradas, Salidas y Desconexiones en Rol
    Deaths = '',       -- Canal de Muertes (Kill Logs con Arma y Distancia)
    Chat = '',         -- Canal de Chat RP (/me, /do, /ooc, /twt, /anon, /911)
    Reports = '',      -- Canal de Reportes de Jugadores (/report)
}
