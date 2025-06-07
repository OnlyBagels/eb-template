local cookingZones = {}
local activeCooking = false

-- Function to get item data from ox_inventory
local function getItemData(itemName)
    local items = exports.ox_inventory:Items()
    if items[itemName] then
        return {
            label = items[itemName].label,
            image = items[itemName].client and items[itemName].client.image or nil
        }
    end
    return {label = itemName, image = nil}
end

-- Function to build item image URL
local function getItemImageUrl(itemName)
    -- ox_inventory stores images in web/images/ folder
    return ('nui://ox_inventory/web/images/%s.png'):format(itemName)
end

-- Show cooking quantity dialog with slider
local function showCookingDialog(station, recipe, recipeId)
    -- Calculate max quantity based on available ingredients
    local maxQuantity = 99
    
    -- Check each ingredient to find the limiting factor
    for _, item in ipairs(recipe.requiredItems) do
        local playerCount = exports.ox_inventory:GetItemCount(item.name)
        local possibleQuantity = math.floor(playerCount / item.amount)
        maxQuantity = math.min(maxQuantity, possibleQuantity)
    end
    
    if maxQuantity == 0 then
        lib.notify({
            title = Config.RestaurantLabel,
            description = 'You don\'t have the required ingredients!',
            type = 'error',
            position = Config.NotificationPosition
        })
        return false
    end
    
    -- Build initial ingredients info
    local ingredientInfo = {}
    for _, item in ipairs(recipe.requiredItems) do
        local itemData = getItemData(item.name)
        local playerCount = exports.ox_inventory:GetItemCount(item.name)
        ingredientInfo[item.name] = {
            label = itemData.label,
            required = item.amount,
            have = playerCount
        }
    end
    
    -- Create dynamic description function
    local function getIngredientsDescription(quantity)
        local lines = {}
        for _, item in ipairs(recipe.requiredItems) do
            local info = ingredientInfo[item.name]
            local needed = item.amount * quantity
            local hasEnough = info.have >= needed
            local symbol = hasEnough and '✓' or '✗'
            table.insert(lines, string.format('%s %s: %d/%d', 
                symbol, info.label, needed, info.have))
        end
        return table.concat(lines, '\n')
    end
    
    local input = lib.inputDialog('Cook ' .. recipe.label, {
        {
            type = 'slider',
            label = 'Quantity to Cook',
            description = 'Adjust to see ingredient requirements',
            default = 1,
            min = 1,
            max = maxQuantity,
            step = 1
        },
        {
            type = 'input',
            label = 'Ingredients Required (for selected quantity)',
            description = getIngredientsDescription(1),
            disabled = true
        }
    })
    
    if input then
        local quantity = input[1]
        
        if quantity > 0 then
            -- Start cooking process with quantity
            StartCookingWithQuantity(station, recipe, recipeId, quantity)
            return true
        end
    end
    
    return false
end

-- Function to open cooking menu
function openCookingMenu(station)
    local menuOptions = {}
    
    -- Build menu options based on station's recipes
    for _, recipeId in ipairs(station.recipes) do
        local recipe = Config.Recipes[recipeId]
        if recipe then
            -- Build metadata with ingredient information
            local metadata = {}
            local ingredientsList = {}
            local canCook = true
            local limitingFactor = 99
            
            for _, item in ipairs(recipe.requiredItems) do
                local itemData = getItemData(item.name)
                local playerCount = exports.ox_inventory:GetItemCount(item.name)
                local hasEnough = playerCount >= item.amount
                
                if not hasEnough then
                    canCook = false
                end
                
                -- Calculate how many we can make with this ingredient
                local possibleWithThis = math.floor(playerCount / item.amount)
                limitingFactor = math.min(limitingFactor, possibleWithThis)
                
                table.insert(ingredientsList, string.format('%dx %s', item.amount, itemData.label))
                
                -- Add to metadata with availability indicator
                table.insert(metadata, {
                    label = itemData.label,
                    value = string.format('%d/%d', playerCount, item.amount),
                    -- Show red if not enough
                    progress = hasEnough and 100 or (playerCount / item.amount * 100),
                    colorScheme = hasEnough and 'green' or 'red'
                })
            end
            
            -- Add max quantity to metadata
            if canCook and limitingFactor > 0 then
                table.insert(metadata, 1, {
                    label = 'Can Make',
                    value = limitingFactor .. 'x'
                })
            end
            
            -- Get the main product icon
            local mainProductIcon = getItemImageUrl(recipeId)
            
            table.insert(menuOptions, {
                title = recipe.label,
                description = canCook and 
                    string.format('Can make up to %dx', limitingFactor) or 
                    '❌ Missing ingredients',
                icon = mainProductIcon,
                iconColor = canCook and '#10B981' or '#EF4444',
                disabled = not canCook,
                metadata = metadata,
                onSelect = function()
                    if canCook then
                        showCookingDialog(station, recipe, recipeId)
                    end
                end
            })
        end
    end
    
    -- Show the menu
    lib.registerContext({
        id = 'cooking_menu',
        title = station.label,
        options = menuOptions
    })
    
    lib.showContext('cooking_menu')
end

-- Create cooking zones on resource start
CreateThread(function()
    Wait(1000) -- Wait for everything to initialize
    
    for _, station in ipairs(Config.CookingStations) do
        local options = {
            {
                name = 'cook_' .. station.id,
                label = station.label,
                icon = 'fa-solid fa-utensils',
                distance = 2.0,
                groups = {[Config.RestaurantJob] = 0},
                canInteract = function(entity, distance, coords, name, bone)
                    return IsOnDuty() and not activeCooking
                end,
                onSelect = function()
                    openCookingMenu(station)
                end
            }
        }
        
        -- Create either box or sphere zone based on config
        if station.size then
            -- Box zone
            cookingZones[station.id] = exports.ox_target:addBoxZone({
                coords = station.coords,
                size = station.size,
                rotation = station.rotation or 0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        else
            -- Sphere zone
            cookingZones[station.id] = exports.ox_target:addSphereZone({
                coords = station.coords,
                radius = station.radius or 1.0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        end
    end
end)

-- Start cooking process with quantity
function StartCookingWithQuantity(station, recipe, recipeId, quantity)
    if activeCooking then
        lib.notify({
            title = Config.RestaurantLabel,
            description = 'You are already cooking something!',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    -- Double check ingredients for the requested quantity
    local hasAllIngredients = true
    for _, item in ipairs(recipe.requiredItems) do
        local playerCount = exports.ox_inventory:GetItemCount(item.name)
        if playerCount < (item.amount * quantity) then
            hasAllIngredients = false
            break
        end
    end
    
    if not hasAllIngredients then
        lib.notify({
            title = Config.RestaurantLabel,
            description = 'You don\'t have enough ingredients for that quantity!',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    activeCooking = true
    
    -- Calculate scaled duration
    local baseDuration = recipe.duration or 5000
    local duration = baseDuration
    
    if quantity > 1 then
        -- Scaling formula:
        -- 1-20 items: adds 3.6s per item
        -- 20-50 items: adds 2.6s per item  
        -- 50-100 items: adds 2.0s per item
        
        if quantity <= 20 then
            duration = baseDuration + ((quantity - 1) * 3600)
        elseif quantity <= 50 then
            local timeAt20 = baseDuration + (19 * 3600)
            duration = timeAt20 + ((quantity - 20) * 2600)
        else
            local timeAt20 = baseDuration + (19 * 3600)
            local timeAt50 = timeAt20 + (30 * 2600)
            duration = timeAt50 + ((quantity - 50) * 2000)
        end
    end
    
    -- Play animation if configured
    if recipe.animation then
        lib.requestAnimDict(recipe.animation.dict)
        TaskPlayAnim(
            cache.ped,
            recipe.animation.dict,
            recipe.animation.clip,
            8.0, 8.0,
            duration,
            1, 0, false, false, false
        )
    end
    
    -- Show progress circle with quantity info
    local timeInMinutes = duration / 60000
    local timeDisplay = timeInMinutes >= 1 and string.format('%.1f min', timeInMinutes) or string.format('%d sec', math.floor(duration / 1000))
    
    local success = lib.progressCircle({
        duration = duration,
        label = string.format('Cooking %dx %s', quantity, recipe.label),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
    
    -- Clear animation
    ClearPedTasks(cache.ped)
    activeCooking = false
    
    if success then
        -- Create modified recipe data with quantities
        local modifiedRecipe = {
            label = recipe.label,
            requiredItems = {},
            receivedItems = {}
        }
        
        -- Multiply required items by quantity
        for _, item in ipairs(recipe.requiredItems) do
            table.insert(modifiedRecipe.requiredItems, {
                name = item.name,
                amount = item.amount * quantity
            })
        end
        
        -- Multiply received items by quantity
        for _, item in ipairs(recipe.receivedItems) do
            table.insert(modifiedRecipe.receivedItems, {
                name = item.name,
                amount = item.amount * quantity
            })
        end
        
        -- Trigger server event to complete cooking with original recipeId for validation
        TriggerServerEvent('eb-template:completeCooking', station.id, modifiedRecipe, recipeId, quantity)
    else
        lib.notify({
            title = Config.RestaurantLabel,
            description = 'Cooking cancelled!',
            type = 'error',
            position = Config.NotificationPosition
        })
    end
end

-- Start cooking process (legacy function for compatibility)
function StartCooking(station, recipe)
    StartCookingWithQuantity(station, recipe, recipe.label, 1)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, zone in pairs(cookingZones) do
            exports.ox_target:removeZone(zone)
        end
    end
end)