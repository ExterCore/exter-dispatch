fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'sobing4413'

version '1.0'

description 'Emergency Dispatch System For QBCore Nopixel 4.0 Design'

shared_script {
    'shared/config.lua',
}

client_scripts {
    'client/editable_client.lua', 
    'client/client.lua',          
}

server_scripts {
    'server/server.lua'           
}

ui_page 'html/index.html'

files {
    'html/*',
    'html/**',            
}