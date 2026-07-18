fx_version "cerulean"
game "gta5"
lua54 "yes"

author "FXAP Community / versão multi-framework"
description "ANTI-DUMPER"
version "2.0.0"

shared_script "config.lua"

client_script "client.lua"

server_scripts {
    "server/framework.lua",
    "server.lua"
}

ui_page "ui/ui.html"

files {
    "ui/ui.html"
}
