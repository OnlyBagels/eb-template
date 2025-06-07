local storageZones = {}

-- Create storage zones on resource start
CreateThread(function()
    Wait(1000) -- Wait for everything to initialize
    
    for _, storage in ipairs(Config.Storages) do
        local stashName = ('%s_%s'):format(Config.RestaurantName, storage.id)
        
        local options = {
            {
                name = 'open_' .. storage.id,
                label = storage.label,
                icon = 'fa-solid fa-box-open',
                distance = 2.0,
                groups = storage.groups,
                canInteract = function(entity, distance, coords, name, bone)
                    return IsOnDuty()
                end,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', stashName)
                end
            }
        }
        
        -- Create either box or sphere zone based on config
        if storage.size then
            -- Box zone
            storageZones[storage.id] = exports.ox_target:addBoxZone({
                coords = storage.coords,
                size = storage.size,
                rotation = storage.rotation or 0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        else
            -- Sphere zone
            storageZones[storage.id] = exports.ox_target:addSphereZone({
                coords = storage.coords,
                radius = storage.radius or 1.0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        end
    end
    
    if Config.Debug then
        print(('[%s] Created %d storage zones'):format(GetCurrentResourceName(), #Config.Storages))
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, zone in pairs(storageZones) do
            exports.ox_target:removeZone(zone)
        end
    end
end)