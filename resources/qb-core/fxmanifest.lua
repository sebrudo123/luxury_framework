fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-core'
description 'Luxury Core -> Puente de Compatibilidad Nativo para Scripts QBCore'
author 'Luxury Framework'
version '1.2.0'

shared_scripts {
    'import.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'GetCoreObject',
    'GetSharedObject',
    'GetQBCore'
}
