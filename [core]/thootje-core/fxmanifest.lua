fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-core'
author 'Thootje'
description 'Standalone custom FiveM core framework'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/callbacks.lua',
    'server/commands.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'oxmysql'
}
