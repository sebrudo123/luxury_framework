fx_version 'cerulean'
game 'gta5'

name 'luxury-loading'
author 'Luxury Scripts'
description 'Sistema de Loading Screen Profesional y Ultra Personalizable para FiveM'
version '1.0.0'

-- Cargar interfaz NUI en la pantalla de carga
loadscreen 'web/index.html'

-- Habilitar cursor interactivo durante la carga
loadscreen_cursor 'yes'

-- Archivos necesarios para la interfaz NUI
files {
    'web/index.html',
    'web/config.js',
    'web/css/*.css',
    'web/js/*.js',
    'web/assets/images/*',
    'web/assets/images/**/*',
    'web/assets/audio/*',
    'web/assets/video/*'
}
