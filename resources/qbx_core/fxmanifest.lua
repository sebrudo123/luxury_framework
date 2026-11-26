fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_core'
description 'Luxury Core -> Puente oficial compatible con scripts de Qbox (qbx_core)'
author 'Vertex Development'
version '1.0.0'

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
    'GetPlayer',
    'GetPlayerByCitizenId',
    'GetPlayersData',
    'Notify',
    'AddMoney',
    'RemoveMoney',
    'SetJob',
    'SetGang',
    'SetJobDuty',
    'GetQbxPlayer',
    'GetQboxPlayer'
}
