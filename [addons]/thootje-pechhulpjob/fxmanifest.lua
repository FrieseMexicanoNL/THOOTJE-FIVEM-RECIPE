fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'THOOTJE'
description 'THOOTJE Pechhulp & Voertuigonderhoud'
version '1.1.0'

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

shared_scripts { '@ox_lib/init.lua', 'config.lua', 'shared/bridge.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }

dependencies { 'oxmysql', 'ox_lib' }
