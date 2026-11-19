fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'thootje-drugs'
author 'THOOTJE'
description 'Uitgebreid illegaal drugs RP-systeem voor THOOTJE-CORE'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
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

dependencies {
    'oxmysql',
    'ox_lib',
    'thootje-core',
    'thootje-inventory'
}
