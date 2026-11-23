fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_core'
description 'Framework base modular con arquitectura Qbox: Proxy/Tunnel, Gangs, Licencias, Buckets, blindaje Anti-Dump y Centinela Anti-Cheat'
version '1.3.0'

shared_scripts {
    'shared/proxy.lua',
    'shared/tunnel.lua',
    'config/shared.lua',
    'config.lua',
    'shared/jobs.lua',
    'shared/gangs.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server.lua',
    'server/webhooks.lua',
    'server/logger.lua',
    'server/preflight.lua',
    'server/security.lua',
    'server/admins.lua',
    'server/proxy.lua',
    'server/buckets.lua',
    'server/licenses.lua',
    'server/player.lua',
    'server/functions.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/inventory.lua',
    'server/society.lua',
    'server/status.lua',
    'server/death.lua',
    'server/admin.lua',
    'server/updater.lua',
    'bridge/esx_server.lua',
    'bridge/qb_server.lua',
    'bridge/qbox.lua',
    'server/main.lua'
}

client_scripts {
    'config/client.lua',
    'client/security.lua',
    'client/proxy.lua',
    'client/functions.lua',
    'client/player.lua',
    'client/events.lua',
    'client/loops.lua',
    'client/death.lua',
    'client/status.lua',
    'client/suggestions.lua',
    'client/admin.lua',
    'bridge/esx_client.lua',
    'bridge/qb_client.lua',
    'client/main.lua'
}

exports {
    -- Proxy & Tunnel Engine
    'ProxyCall',
    'GetProxy',
    'GetTunnel',

    -- Core Functions
    'GetPlayer',
    'GetPlayers',
    'GetPlayerByCitizenId',
    'GetPlayerByPhone',
    'GetLicense',

    -- Routing Buckets
    'SetPlayerBucket',
    'GetPlayerBucket',
    'ResetPlayerBucket',

    -- Licenses
    'HasLicense',
    'GrantLicense',
    'RevokeLicense',

    -- Logger & Anticheat
    'LogBan',
    'LogAnticheat',
    'LogAdminCommand',

    -- ESX Compatibility
    'getSharedObject',
    'GetSharedObject',
    'GetESX',

    -- Auto-Updater
    'CheckForUpdates',
    'UpdateFramework',

    -- QBCore Compatibility
    'GetCoreObject',
    'GetQBCore',

    -- Qbox Compatibility
    'GetQboxPlayer'
}
