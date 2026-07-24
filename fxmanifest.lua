fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Astrxw'
description 'Gang builder ESX (job2) : creation de gangs, coffre, menu boss et interactions'
version '1.1.0'

dependencies {
    'es_extended',
    'oxmysql',
    'ox_inventory'
}

shared_scripts {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    'config.lua'
}

client_scripts {
    'src/RMenu.lua',
    'src/menu/RageUI.lua',
    'src/menu/Menu.lua',
    'src/menu/MenuController.lua',
    'src/components/*.lua',
    'src/menu/elements/*.lua',
    'src/menu/items/*.lua',
    'src/menu/panels/*.lua',
    'src/menu/windows/*.lua',

    'client/shared.lua',
    'client/boss.lua',
    'client/coffre.lua',
    'client/F7.lua',
    'client/menu.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/server.lua',
    'server/sv_coffre.lua',
    'server/sv_f7.lua'
}

escrow_ignore {
    'fxmanifest.lua',
    'config.lua',
    'src/RMenu.lua',
    'src/menu/RageUI.lua',
    'src/menu/Menu.lua',
    'src/menu/MenuController.lua',
    'src/components/*.lua',
    'src/menu/elements/*.lua',
    'src/menu/items/*.lua',
    'src/menu/panels/*.lua',
    'src/menu/windows/*.lua'
}
