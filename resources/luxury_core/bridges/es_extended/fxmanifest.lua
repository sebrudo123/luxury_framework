fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'es_extended'
description 'Luxury Core -> Puente oficial compatible con scripts de ESX'
author 'Vertex Development'
version '1.9.4'

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
    'GetSharedObject',
    'GetESX'
}
