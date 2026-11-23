fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_lib'
description 'Librería utilitaria oficial para el ecosistema Luxury Framework'
author 'Vertex Development'
version '1.3.0'

shared_scripts {
    'shared/math.lua',
    'shared/table.lua',
    'shared/proxy.lua',
    'shared/tunnel.lua',
    'init.lua'
}

server_scripts {
    'server/callback.lua'
}

client_scripts {
    'client/cache.lua',
    'client/callback.lua',
    'client/streaming.lua',
    'client/notify.lua'
}

exports {
    'GetLib',
    'GetProxy',
    'GetTunnel'
}
