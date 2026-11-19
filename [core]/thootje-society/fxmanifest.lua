fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-society'
author 'THOOTJE'
description 'Bedrijven, medewerkers en bedrijfsrekeningen voor THOOTJE-CORE'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'societies.lua'
}

client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies { 'oxmysql' }
