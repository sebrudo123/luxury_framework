fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_radial'
description 'Menú Radial Interactivo y Fluido (Control de Vehículo, Ciudadano y Animaciones)'
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
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
