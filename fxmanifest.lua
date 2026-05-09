fx_version 'cerulean'
game 'gta5'

name        'austriawien_skinmenu'
description 'AustriaWien – Skin-Menü für ESX'
version     '1.1.0'
author      'GamingDevelopment'

dependencies {
    'es_extended',
    'oxmysql',
}

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
    'html/js/app.js'
}

lua54 'yes'
