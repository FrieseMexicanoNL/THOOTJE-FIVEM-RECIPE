fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-vehicles'
author 'THOOTJE'
description 'Voertuigbezit, sleutels en voertuigvergrendeling voor THOOTJE-CORE'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua'
}

client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies { 'oxmysql' }
