fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_core'
description 'Luxury Core -> Puente de Compatibilidad Nativo para Scripts Qbox'
author 'Luxury Framework'
version '1.4.0'

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

exports {
    'GetPlayer',
    'GetPlayerByCitizenId',
    'GetPlayersData',
    'GetCoreObject',
    'Notify',
    'AddMoney',
    'RemoveMoney',
    'SetJob',
    'SetGang',
    'SetJobDuty'
}
