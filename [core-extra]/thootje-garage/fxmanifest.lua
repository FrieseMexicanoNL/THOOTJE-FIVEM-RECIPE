fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-garage'
author 'THOOTJE'
description 'Modern voertuig- en garagesysteem voor THOOTJE-CORE'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'garages.lua'
}

client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies { 'oxmysql' }
