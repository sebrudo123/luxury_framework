fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_hud'
description 'HUD Oficial de Alta Gama con Interfaz HTML/JS, Cinemática y Telemetría Vehicular (Cfx.re Asset Escrow Compatible)'
author 'Luxury Scripts'
version '1.0.0'

-- Configuración Oficial para el sistema de encriptación Cfx.re Asset Escrow
escrow_ignore {
    'config.lua'
}

shared_scripts {
    '@luxury_core/shared/proxy.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
