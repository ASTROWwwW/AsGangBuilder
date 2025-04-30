fx_version 'cerulean'
game 'gta5'
author 'Astrxw'

version '1.0'
lua54 'yes'
escrow_ignore {
    "config.lua",
    "src/RMenu.lua",
    "src/menu/RageUI.lua",
    "src/menu/Menu.lua",
    "src/menu/MenuController.lua",

    "src/components/*.lua",

    "src/menu/elements/*.lua",

    "src/menu/items/*.lua",

    "src/menu/panels/*.lua",

    "src/menu/panels/*.lua",
    "src/menu/windows/*.lua",
    "fxmanifest.lua"
}

client_scripts {
    "src/RMenu.lua",
    "src/menu/RageUI.lua",
    "src/menu/Menu.lua",
    "src/menu/MenuController.lua",

    "src/components/*.lua",

    "src/menu/elements/*.lua",

    "src/menu/items/*.lua",

    "src/menu/panels/*.lua",

    "src/menu/panels/*.lua",
    "src/menu/windows/*.lua",

}

shared_scripts {
    "config.lua",
}

server_scripts {
    '@es_extended/locale.lua',
    '@oxmysql/lib/MySQL.lua',
    "config.lua",
    'server/*.lua'
}

client_scripts {
    '@es_extended/locale.lua',
  "config.lua",
    'client/*.lua'
}

shared_script '@es_extended/imports.lua'


