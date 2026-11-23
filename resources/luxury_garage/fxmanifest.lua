fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_garage'
description 'Sistema Moderno de Garajes, Depósito de Incautados y Llaves de Vehículo (Estilo okokGarage)'
author 'Vertex Development'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

exports {
    'HasKeys',
    'GiveKeys'
}
