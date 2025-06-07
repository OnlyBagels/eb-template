local QBX = exports['qb-core']:GetCoreObject()

-- Check if player has required ingredients
lib.callback.register('eb-template:checkIngredients', function(source, requiredItems)
    for _, item in ipairs(requiredItems) do
        local count = exports.ox_inventory:GetItemCount(source, item.name)
        if count < item.amount then
            return false
        end
    end
    return true
end)

-- Complete cooking process
RegisterNetEvent('eb-template:completeCooking', function(stationId, recipeData, originalRecipeId, quantity)
    local src = source
    
    -- Security checks
    local Player = QBX.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Config.RestaurantJob or not Player.PlayerData.job.onduty then
        if Config.Debug then
            print(('[%s] Unauthorized cooking attempt by %s'):format(GetCurrentResourceName(), src))
        end
        return
    end
    
    -- Validate quantity
    quantity = tonumber(quantity) or 1
    if quantity < 1 or quantity > 100 then
        if Config.Debug then
            print(('[%s] Invalid quantity %s from player %s'):format(GetCurrentResourceName(), quantity, src))
        end
        return
    end
    
    -- Find the station and verify the recipe
    local validStation = false
    local station = nil
    local originalRecipe = nil
    
    for _, s in ipairs(Config.CookingStations) do
        if s.id == stationId then
            station = s
            -- Check if this station can make this recipe
            for _, recipeId in ipairs(s.recipes) do
                if recipeId == originalRecipeId then
                    originalRecipe = Config.Recipes[recipeId]
                    if originalRecipe then
                        validStation = true
                        break
                    end
                end
            end
            break
        end
    end
    
    if not validStation or not originalRecipe then
        if Config.Debug then
            print(('[%s] Player %s attempted to cook with invalid station/recipe'):format(GetCurrentResourceName(), src))
        end
        return
    end
    
    -- Verify the recipe data matches (with scaled quantities)
    local expectedRequiredItems = {}
    local expectedReceivedItems = {}
    
    for _, item in ipairs(originalRecipe.requiredItems) do
        table.insert(expectedRequiredItems, {
            name = item.name,
            amount = item.amount * quantity
        })
    end
    
    for _, item in ipairs(originalRecipe.receivedItems) do
        table.insert(expectedReceivedItems, {
            name = item.name,
            amount = item.amount * quantity
        })
    end
    
    -- Check ingredients again (security)
    for _, item in ipairs(expectedRequiredItems) do
        local count = exports.ox_inventory:GetItemCount(src, item.name)
        if count < item.amount then
            lib.notify(src, {
                title = Config.RestaurantLabel,
                description = 'You don\'t have the required ingredients!',
                type = 'error',
                position = Config.NotificationPosition
            })
            if Config.Debug then
                print(('[%s] Player %s missing ingredient %s (has %d, needs %d)'):format(GetCurrentResourceName(), src, item.name, count, item.amount))
            end
            return
        end
    end
    
    -- Remove required items
    local allRemoved = true
    for _, item in ipairs(expectedRequiredItems) do
        local success = exports.ox_inventory:RemoveItem(src, item.name, item.amount)
        if not success then
            allRemoved = false
            if Config.Debug then
                print(('[%s] Failed to remove %dx %s from player %s'):format(GetCurrentResourceName(), item.amount, item.name, src))
            end
            break
        end
    end
    
    if not allRemoved then
        -- Try to return any items that were removed
        for _, item in ipairs(expectedRequiredItems) do
            exports.ox_inventory:AddItem(src, item.name, item.amount)
        end
        lib.notify(src, {
            title = Config.RestaurantLabel,
            description = 'Failed to process ingredients!',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    -- Give cooked items
    local allAdded = true
    local addedItems = {}
    
    for _, item in ipairs(expectedReceivedItems) do
        local success = exports.ox_inventory:AddItem(src, item.name, item.amount)
        if success then
            table.insert(addedItems, item)
            if Config.Debug then
                print(('[%s] Added %dx %s to player %s'):format(GetCurrentResourceName(), item.amount, item.name, src))
            end
        else
            allAdded = false
            if Config.Debug then
                print(('[%s] Failed to add %dx %s to player %s - inventory full?'):format(GetCurrentResourceName(), item.amount, item.name, src))
            end
            break
        end
    end
    
    if not allAdded then
        -- Remove any items that were added
        for _, item in ipairs(addedItems) do
            exports.ox_inventory:RemoveItem(src, item.name, item.amount)
        end
        
        -- Return ingredients
        for _, ingredient in ipairs(expectedRequiredItems) do
            exports.ox_inventory:AddItem(src, ingredient.name, ingredient.amount)
        end
        
        lib.notify(src, {
            title = Config.RestaurantLabel,
            description = 'Your inventory is full!',
            type = 'error',
            position = Config.NotificationPosition
        })
    else
        -- Success notification
        local itemList = {}
        for _, item in ipairs(expectedReceivedItems) do
            table.insert(itemList, string.format('%dx %s', item.amount, originalRecipe.label))
        end
        
        lib.notify(src, {
            title = Config.RestaurantLabel,
            description = 'Successfully cooked ' .. table.concat(itemList, ', '),
            type = 'success',
            position = Config.NotificationPosition
        })
        
        -- Discord webhook logging if enabled
        if Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
            local ingredientsList = {}
            for _, item in ipairs(expectedRequiredItems) do
                table.insert(ingredientsList, string.format('%dx %s', item.amount, item.name))
            end
            
            local embed = {
                {
                    title = 'Cooking Completed',
                    description = string.format('**Player:** %s\n**Station:** %s\n**Recipe:** %s\n**Quantity:** %d\n**Used:** %s\n**Received:** %s\n**Time:** %s',
                        GetPlayerName(src),
                        station.label,
                        originalRecipe.label,
                        quantity,
                        table.concat(ingredientsList, ', '),
                        table.concat(itemList, ', '),
                        os.date('%Y-%m-%d %H:%M:%S')
                    ),
                    color = 5763719, -- Green
                    footer = {
                        text = Config.RestaurantLabel
                    }
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
                username = Config.RestaurantLabel,
                embeds = embed
            }), { ['Content-Type'] = 'application/json' })
        end
    end
end)