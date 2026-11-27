fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-core'
description 'Luxury Core -> Puente oficial compatible con scripts de QBCore'
author 'Vertex Development'
version '1.2.6'

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
