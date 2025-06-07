-- Register all storage stashes on resource start
CreateThread(function()
    -- Wait a bit for everything to initialize
    Wait(1000)
    
    for _, storage in ipairs(Config.Storages) do
        local stashName = ('%s_%s'):format(Config.RestaurantName, storage.id)
        
        -- Register the stash with ox_inventory
        exports.ox_inventory:RegisterStash(
            stashName,
            storage.label,
            storage.slots,
            storage.weight,
            nil, -- owner (nil = shared)
            storage.groups,
            storage.coords
        )
        
        if Config.Debug then
            print(('[%s] Registered stash: %s'):format(GetCurrentResourceName(), stashName))
        end
    end
end)

-- Optional: Add a command for managers to clear a stash
lib.addCommand('clearstash', {
    help = 'Clear a restaurant stash (Manager only)',
    params = {
        {
            name = 'stash',
            type = 'string',
            help = 'Stash ID (e.g., ingredients, counter, freezer)'
        }
    },
    restricted = 'group.admin' -- Change this to your manager group
}, function(source, args, raw)
    local stashName = ('%s_%s'):format(Config.RestaurantName, args.stash)
    
    -- Verify the stash exists in config
    local validStash = false
    for _, storage in ipairs(Config.Storages) do
        if storage.id == args.stash then
            validStash = true
            break
        end
    end
    
    if not validStash then
        lib.notify(source, {
            title = Config.RestaurantLabel,
            description = 'Invalid stash ID!',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    -- Clear the stash
    exports.ox_inventory:ClearInventory(stashName)
    
    lib.notify(source, {
        title = Config.RestaurantLabel,
        description = ('Cleared %s stash'):format(args.stash),
        type = 'success',
        position = Config.NotificationPosition
    })
    
    -- Log the action
    print(('[%s] Admin %s cleared stash %s'):format(GetCurrentResourceName(), source, stashName))
end)