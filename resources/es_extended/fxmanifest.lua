fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'es_extended'
description 'Luxury Core -> Puente de Compatibilidad Nativo para Scripts ESX'
author 'Luxury Framework'
version '1.2.0'

shared_scripts {
    'imports.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'getSharedObject',
    'GetSharedObject'
}
