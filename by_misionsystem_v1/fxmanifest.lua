fx_version 'adamant'

game 'gta5'

client_scripts {
    'client/cl_main.lua',
    'config.lua'
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    'server/sv_main.lua',
    'config.lua',
    'test.lua'
}

ui_page {
    "html/index.html"
    --"html/create.html"
}

files {
    "html/index.html",
    --"html/create.html",
    "html/listener.js",
    "html/style.css",
    "html/reset.css"
}