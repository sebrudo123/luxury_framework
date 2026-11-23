-- luxury_core: Lista Privada de Administradores del Servidor (Server-Side Only)
-- Este archivo es estrictamente del servidor. NUNCA se envía al cliente.
-- Los dumpers de FiveM jamás podrán ver tus administradores ni licencias Rockstar.

ServerAdmins = {
    -- Ejemplo: añade tu license aquí o usa el comando /setGroup en el juego:
    -- ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = 'admin',
}

Config = Config or {}
Config.Admins = Config.Admins or {}

for license, group in pairs(ServerAdmins) do
    Config.Admins[license] = group
end
