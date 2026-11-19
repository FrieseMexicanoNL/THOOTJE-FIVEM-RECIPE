fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'THOOTJE'
description 'THOOTJE Housing - huizen, appartementen, verhuur en sleutels'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/bridge.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'oxmysql',
    'thootje-core'
}
