fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxury_notify'
description 'Sistema Moderno de Notificaciones y TextUI (Estilo okokNotify)'
author 'Vertex Development'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'client.lua'
}

exports {
    'Alert',
    'Notify',
    'TextUI',
    'HideUI'
}
