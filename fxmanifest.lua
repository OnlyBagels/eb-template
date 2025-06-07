fx_version 'cerulean'
game 'gta5'

name 'eb-template'
description 'Restaurant Template Script'
author 'Bagelbites99'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',     
    'shared/emote.lua',      
    'shared/consumable.lua',  
    'shared/pos.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/consumable.lua',  
    'client/cooking.lua',
    'client/storage.lua',
    'client/autoclock.lua',
    'client/pos.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/consumable.lua',
    'server/cooking.lua',
    'server/storage.lua',
    'server/autoclock.lua',
    'server/pos.lua',
}

-- Uncomment if you have custom props/models
-- file 'stream/**.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/**.ytyp'

-- Client exports
exports {
    'useConsumable'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    '/assetpacks'
}