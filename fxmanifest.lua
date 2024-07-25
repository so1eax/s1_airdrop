fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'so1eax'
description 'An airdorp script supporting ESX'
version '1.0'

client_script 'client.lua'
server_script 'server.lua'
shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

dependencies {
    'ox_lib',
    'es_extended'
}