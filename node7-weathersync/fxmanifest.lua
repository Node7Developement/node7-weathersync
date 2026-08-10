fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'node7-weathersync'
author 'NODE7 Development Studios'
description 'Server-authoritative RedM weather and time synchronization using NODE7 menu and input resources.'
version '1.0.5'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/weather.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'node7-core',
    'node7-menu',
    'node7-input'
}
