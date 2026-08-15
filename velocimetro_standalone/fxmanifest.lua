fx_version 'cerulean'
game 'gta5'

description 'Standalone Speedometer & Fuel Mod for FiveM'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
