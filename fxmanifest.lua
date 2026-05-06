fx_version 'cerulean'
game 'gta5'

name        'austriawien_skinmenu'
description 'AustriaWien – Drag & Drop Skin-Menü für ESX'
version     '1.0.2'
author      'GamingDevelopment'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',

    -- Vorschau-Bilder: html/img/{slotId}/{drawableId}.{png|jpg|webp}
    -- Alle Unterordner werden automatisch eingebunden.
    'html/img/**/*.png',
    'html/img/**/*.jpg',
    'html/img/**/*.webp'
}

lua54 'yes'
