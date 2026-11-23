fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_core'
description 'Luxury Core -> Puente oficial compatible con scripts de Qbox'
author 'Vertex Development'
version '1.0.0'

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'GetPlayer',
    'GetPlayerByCitizenId'
}
