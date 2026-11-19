fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-banking'
author 'Thootje Development'
description 'Premium banking and transfers for THOOTJE-CORE'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies { 'oxmysql', 'thootje-core' }
