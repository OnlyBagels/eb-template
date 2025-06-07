local posZones = {}
local activePOS = false
local currentCart = {}
local currentCartTotal = 0

-- Get QBX Core
local QBX = exports['qb-core']:GetCoreObject()

-- Draw 3D text helper
local function DrawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Check if player can use POS
local function canUsePOS()
    return IsOnDuty()
end

-- Reset cart
local function resetCart()
    currentCart = {}
    currentCartTotal = 0
end

-- Update cart item quantity
local function updateCartItem(itemName, quantity)
    for i, item in ipairs(currentCart) do
        if item.name == itemName then
            if quantity <= 0 then
                table.remove(currentCart, i)
            else
                item.quantity = quantity
                item.total = item.price * quantity
            end
            break
        end
    end
    
    -- Recalculate total
    currentCartTotal = 0
    for _, item in ipairs(currentCart) do
        currentCartTotal = currentCartTotal + item.total
    end
end

-- Add item to cart with quantity
local function addToCart(itemName, itemLabel, price, quantity)
    quantity = quantity or 1
    
    -- Check if item already in cart
    local found = false
    for i, item in ipairs(currentCart) do
        if item.name == itemName then
            item.quantity = item.quantity + quantity
            item.total = item.price * item.quantity
            found = true
            break
        end
    end
    
    if not found then
        table.insert(currentCart, {
            name = itemName,
            label = itemLabel,
            price = price,
            quantity = quantity,
            total = price * quantity
        })
    end
    
    -- Recalculate total
    currentCartTotal = 0
    for _, item in ipairs(currentCart) do
        currentCartTotal = currentCartTotal + item.total
    end
end

-- Get item icon
local function getItemIcon(itemName)
    -- Map items to appropriate icons
    local iconMap = {
        -- Coffee items
        coffee = 'coffee',
        latte = 'mug-hot',
        mocha = 'mug-hot',
        
        -- Drinks
        soda = 'glass-water',
        beer = 'beer-mug-empty',
        wine = 'wine-glass',
        water = 'bottle-water',
        
        -- Food items
        burger = 'burger',
        sandwich = 'sandwich',
        salad = 'bowl-food',
        steak = 'utensils',
        fries = 'french-fries',
        wings = 'drumstick-bite',
        pizza = 'pizza-slice'
    }
    
    return iconMap[itemName] or 'utensils'
end

-- Get item icon URL (same as cooking.lua)
local function getItemImageUrl(itemName)
    -- ox_inventory stores images in web/images/ folder
    return ('nui://ox_inventory/web/images/%s.png'):format(itemName)
end

-- Get combo icon
local function getComboIcon(combo)
    if not combo.items or #combo.items == 0 then
        return getItemImageUrl(combo.id)
    end
    
    -- Use the first item's icon as the main display
    local firstItem = combo.items[1]
    return getItemImageUrl(firstItem.name)
end

-- Build combo description from items
local function getComboDescription(combo)
    if not combo.items or #combo.items == 0 then
        return combo.description
    end
    
    local itemsList = {}
    for _, item in ipairs(combo.items) do
        -- Try to get the label from recipes
        local itemLabel = nil
        
        -- Check all recipe categories
        for _, station in ipairs(Config.CookingStations) do
            for _, recipeId in ipairs(station.recipes) do
                if recipeId == item.name then
                    local recipe = Config.Recipes[recipeId]
                    if recipe then
                        itemLabel = recipe.label
                        break
                    end
                end
            end
            if itemLabel then break end
        end
        
        -- Fallback to item name if no label found
        itemLabel = itemLabel or item.name
        
        table.insert(itemsList, string.format('%dx %s', item.quantity, itemLabel))
    end
    
    return combo.description .. ' • ' .. table.concat(itemsList, ' + ')
end

-- Show add item dialog with slider
local function showAddItemDialog(itemId, itemLabel, price, isCombo)
    local maxQuantity = isCombo and 100 or 10
    
    local input = lib.inputDialog('Add ' .. itemLabel .. ' to Cart', {
        {
            type = 'slider',
            label = 'Quantity',
            description = 'Price per item: $' .. lib.math.groupdigits(price),
            default = 1,
            min = isCombo and 0 or 1,
            max = maxQuantity,
            step = 1
        }
    })
    
    if input then
        local quantity = input[1]
        
        if quantity == 0 then
            return false
        end
        
        addToCart(itemId, itemLabel, price, quantity)
        
        lib.notify({
            title = 'Added to Cart',
            description = string.format('%dx %s added ($%s)', quantity, itemLabel, lib.math.groupdigits(price * quantity)),
            type = 'success',
            position = Config.NotificationPosition,
            duration = 3000
        })
        
        return true
    end
    
    return false
end

-- Show edit cart item dialog
local function showEditCartItemDialog(item, index)
    local input = lib.inputDialog('Edit ' .. item.label, {
        {
            type = 'slider',
            label = 'Quantity',
            description = 'Price per item: $' .. lib.math.groupdigits(item.price),
            default = item.quantity,
            min = 0,
            max = 20,
            step = 1
        }
    })
    
    if input then
        local newQuantity = input[1]
        
        if newQuantity == 0 then
            updateCartItem(item.name, 0)
            lib.notify({
                title = 'Removed from Cart',
                description = item.label .. ' removed',
                type = 'success',
                position = Config.NotificationPosition
            })
        else
            updateCartItem(item.name, newQuantity)
            lib.notify({
                title = 'Cart Updated',
                description = string.format('%s quantity changed to %d', item.label, newQuantity),
                type = 'success',
                position = Config.NotificationPosition
            })
        end
        
        return true
    end
    
    return false
end

-- Show cart menu with better formatting
local function showCartMenu(machine)
    if #currentCart == 0 then
        lib.alertDialog({
            header = '🛒 Cart is Empty',
            content = 'Add some items to your cart first!',
            centered = true
        })
        return
    end
    
    local menuOptions = {}
    
    -- Add header with summary
    local tax = math.floor(currentCartTotal * (Config.POS.TaxRate / 100))
    local grandTotal = currentCartTotal + tax
    
    table.insert(menuOptions, {
        title = '📋 Order Summary',
        description = string.format('%d items • Subtotal: $%s', #currentCart, lib.math.groupdigits(currentCartTotal)),
        icon = 'fas fa-receipt',
        disabled = true,
        metadata = {
            {label = 'Subtotal', value = '$' .. lib.math.groupdigits(currentCartTotal)},
            {label = 'Tax (' .. Config.POS.TaxRate .. '%)', value = '$' .. lib.math.groupdigits(tax)},
            {label = 'Total', value = '$' .. lib.math.groupdigits(grandTotal)}
        }
    })
    
    table.insert(menuOptions, {
        title = '─────────────────────',
        disabled = true
    })
    
    -- Add cart items with better formatting
    for i, item in ipairs(currentCart) do
        table.insert(menuOptions, {
            title = item.label,
            description = 'Click to edit quantity or remove',
            icon = getItemImageUrl(item.name),
            iconColor = '#F59E0B',
            metadata = {
                {label = 'Quantity', value = item.quantity .. 'x'},
                {label = 'Unit Price', value = '$' .. lib.math.groupdigits(item.price)},
                {label = 'Subtotal', value = '$' .. lib.math.groupdigits(item.total)}
            },
            onSelect = function()
                if showEditCartItemDialog(item, i) then
                    showCartMenu(machine)
                end
            end
        })
    end
    
    table.insert(menuOptions, {
        title = '─────────────────────',
        disabled = true
    })
    
    -- Action buttons with colors
    table.insert(menuOptions, {
        title = '💳 Checkout',
        description = 'Process payment for this order',
        icon = 'fas fa-cash-register',
        iconColor = '#10B981',
        onSelect = function()
            selectCustomer(machine)
        end
    })
    
    table.insert(menuOptions, {
        title = '➕ Add More Items',
        description = 'Continue shopping',
        icon = 'fas fa-plus-circle',
        iconColor = '#3B82F6',
        onSelect = function()
            openPOSInterface(machine)
        end
    })
    
    table.insert(menuOptions, {
        title = '🗑️ Clear Cart',
        description = 'Remove all items',
        icon = 'fas fa-trash-alt',
        iconColor = '#EF4444',
        onSelect = function()
            local confirm = lib.alertDialog({
                header = 'Clear Cart?',
                content = 'Are you sure you want to remove all items from the cart?',
                centered = true,
                cancel = true
            })
            
            if confirm == 'confirm' then
                resetCart()
                lib.notify({
                    title = Config.RestaurantLabel,
                    description = 'Cart cleared',
                    type = 'success',
                    position = Config.NotificationPosition
                })
                openPOSInterface(machine)
            else
                showCartMenu(machine)
            end
        end
    })
    
    lib.registerContext({
        id = 'pos_cart',
        title = '🛒 Shopping Cart',
        options = menuOptions
    })
    
    lib.showContext('pos_cart')
end

-- Open POS interface with better categorization
function openPOSInterface(machine)
    if activePOS then
        lib.notify({
            title = Config.RestaurantLabel,
            description = 'Already using POS',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    local menuOptions = {}
    
    -- Add cart status at top if items in cart
    if #currentCart > 0 then
        table.insert(menuOptions, {
            title = '🛒 View Cart',
            description = string.format('%d items • Total: $%s', #currentCart, lib.math.groupdigits(currentCartTotal)),
            icon = 'fas fa-shopping-cart',
            iconColor = '#F59E0B',
            progress = (#currentCart / 10) * 100,
            onSelect = function()
                showCartMenu(machine)
            end
        })
        
        table.insert(menuOptions, {
            title = '═══════════════════════',
            disabled = true
        })
    end
    
    -- Add combo meals section first
    if Config.POS.ComboMeals and #Config.POS.ComboMeals > 0 then
        table.insert(menuOptions, {
            title = '🌟 Combo Meals',
            description = #Config.POS.ComboMeals .. ' special combos available',
            disabled = true
        })
        
        for _, combo in ipairs(Config.POS.ComboMeals) do
            -- Check if combo is in cart
            local inCart = 0
            for _, cartItem in ipairs(currentCart) do
                if cartItem.name == combo.id then
                    inCart = cartItem.quantity
                    break
                end
            end
            
            -- Build combo metadata showing included items
            local metadata = {
                {label = 'Combo Price', value = '$' .. lib.math.groupdigits(combo.price)},
                {label = 'Type', value = 'Special Deal'}
            }
            
            -- Add included items to metadata if available
            if combo.items then
                for i, item in ipairs(combo.items) do
                    if i <= 3 then
                        local itemLabel = nil
                        -- Find item label from recipes
                        for _, station in ipairs(Config.CookingStations) do
                            for _, recipeId in ipairs(station.recipes) do
                                if recipeId == item.name then
                                    local recipe = Config.Recipes[recipeId]
                                    if recipe then
                                        itemLabel = recipe.label
                                        break
                                    end
                                end
                            end
                            if itemLabel then break end
                        end
                        
                        table.insert(metadata, {
                            label = 'Includes',
                            value = string.format('%dx %s', item.quantity, itemLabel or item.name)
                        })
                    end
                end
            end
            
            table.insert(menuOptions, {
                title = combo.label,
                description = getComboDescription(combo) .. (inCart > 0 and string.format(' • In cart: %dx', inCart) or ''),
                icon = getComboIcon(combo),
                iconColor = inCart > 0 and '#10B981' or nil,
                metadata = metadata,
                onSelect = function()
                    if showAddItemDialog(combo.id, combo.label, combo.price, true) then
                        openPOSInterface(machine)
                    end
                end
            })
        end
        
        table.insert(menuOptions, {
            title = '',
            disabled = true
        })
    end
    
    -- Group recipes by category with emojis
    local categoryEmojis = {
        ['Prep Station'] = '🔪',
        ['Grill'] = '🔥',
        ['Drinks Station'] = '☕',
        ['Deep Fryer'] = '🍟'
    }
    
    -- Get prices from config
    local itemPrices = Config.POS.ItemPrices or {}
    
    -- Organize recipes by station
    for _, station in ipairs(Config.CookingStations) do
        local category = station.label
        local categoryItems = {}
        
        for _, recipeId in ipairs(station.recipes) do
            local recipe = Config.Recipes[recipeId]
            if recipe then
                table.insert(categoryItems, {
                    id = recipeId,
                    label = recipe.label,
                    price = itemPrices[recipeId] or 10
                })
            end
        end
        
        if #categoryItems > 0 then
            -- Sort items alphabetically
            table.sort(categoryItems, function(a, b) return a.label < b.label end)
            
            -- Add category header with emoji
            table.insert(menuOptions, {
                title = (categoryEmojis[category] or '📦') .. ' ' .. category,
                description = #categoryItems .. ' items available',
                disabled = true
            })
            
            -- Add items in category
            for _, item in ipairs(categoryItems) do
                -- Check if item is in cart
                local inCart = 0
                for _, cartItem in ipairs(currentCart) do
                    if cartItem.name == item.id then
                        inCart = cartItem.quantity
                        break
                    end
                end
                
                table.insert(menuOptions, {
                    title = item.label,
                    description = inCart > 0 and string.format('In cart: %dx', inCart) or 'Click to add',
                    icon = getItemImageUrl(item.id),
                    iconColor = inCart > 0 and '#10B981' or nil,
                    metadata = {
                        {label = 'Price', value = '$' .. lib.math.groupdigits(item.price)}
                    },
                    onSelect = function()
                        if showAddItemDialog(item.id, item.label, item.price, false) then
                            openPOSInterface(machine)
                        end
                    end
                })
            end
            
            -- Add spacer between categories
            table.insert(menuOptions, {
                title = '',
                disabled = true
            })
        end
    end
    
    -- Add separator before manager options
    table.insert(menuOptions, {
        title = '═══════════════════════',
        disabled = true
    })
    
    -- View transactions (for managers)
    local player = exports.qbx_core:GetPlayerData()
    if player and player.job and player.job.grade and player.job.grade.level >= Config.POS.ManagerGradeLevel then
        table.insert(menuOptions, {
            title = '📊 Manager Options',
            description = 'View transactions and reports',
            icon = 'fas fa-user-tie',
            iconColor = '#8B5CF6',
            onSelect = function()
                showManagerMenu(machine)
            end
        })
    end
    
    -- Show main menu
    lib.registerContext({
        id = 'pos_main_menu',
        title = '💳 ' .. Config.RestaurantLabel .. ' POS System',
        options = menuOptions
    })
    
    lib.showContext('pos_main_menu')
end

-- Manager menu
function showManagerMenu(machine)
    local menuOptions = {
        {
            title = '📊 Recent Transactions',
            description = 'View last 20 transactions',
            icon = 'fas fa-receipt',
            onSelect = function()
                viewTransactions(machine)
            end
        },
        {
            title = '📈 Daily Report',
            description = 'View today\'s sales summary',
            icon = 'fas fa-chart-line',
            onSelect = function()
                lib.callback('eb-template:pos:getDailyReport', false, function(report)
                    if report then
                        lib.alertDialog({
                            header = '📈 Daily Sales Report',
                            content = string.format(
                                '**Date:** %s\n\n' ..
                                '**Total Sales:** $%s\n' ..
                                '**Tax Collected:** $%s\n' ..
                                '**Transactions:** %d\n' ..
                                '**Average Sale:** $%s',
                                os.date('%Y-%m-%d'),
                                lib.math.groupdigits(report.totalSales),
                                lib.math.groupdigits(report.totalTax),
                                report.transactionCount,
                                lib.math.groupdigits(report.averageSale)
                            ),
                            centered = true
                        })
                    end
                end)
            end
        },
        {
            title = '← Back',
            icon = 'fas fa-arrow-left',
            onSelect = function()
                openPOSInterface(machine)
            end
        }
    }
    
    lib.registerContext({
        id = 'pos_manager_menu',
        title = '👔 Manager Options',
        menu = 'pos_main_menu',
        options = menuOptions
    })
    
    lib.showContext('pos_manager_menu')
end

-- Select customer with better UI
function selectCustomer(machine)
    -- Get nearby players
    local selfId = GetPlayerServerId(PlayerId())
    local selfPed = PlayerPedId()
    local myCoords = GetEntityCoords(selfPed)
    local nearbyPlayers = {}
    
    for _, i in ipairs(GetActivePlayers()) do
        local targetId = GetPlayerServerId(i)
        
        -- Skip self
        if targetId ~= selfId then
            local targetPed = GetPlayerPed(i)
            
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(myCoords - targetCoords)
                
                -- Only add nearby customers (10.0 unit radius for POS)
                if distance <= 10.0 then
                    table.insert(nearbyPlayers, {
                        id = targetId,
                        distance = math.floor(distance * 10) / 10
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(nearbyPlayers, function(a, b) return a.distance < b.distance end)
    
    -- No customers nearby
    if #nearbyPlayers == 0 then
        lib.alertDialog({
            header = '❌ No Customers Nearby',
            content = 'There are no customers within range of the POS system.',
            centered = true
        })
        return
    end
    
    -- Extract just the IDs for the callback
    local playerIds = {}
    for _, player in ipairs(nearbyPlayers) do
        table.insert(playerIds, player.id)
    end
    
    -- Get player names from server
    local playerOptions = lib.callback.await('eb-template:pos:getNearbyPlayerOptions', false, playerIds)
    
    if not playerOptions or #playerOptions == 0 then
        lib.notify({
            title = 'Error',
            description = 'Failed to get customer information',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    -- Build cart description
    local cartItems = {}
    for _, item in ipairs(currentCart) do
        table.insert(cartItems, item.quantity .. 'x ' .. item.label)
    end
    local cartDescription = table.concat(cartItems, ', ')
    
    -- Calculate totals for display
    local tax = math.floor(currentCartTotal * (Config.POS.TaxRate / 100))
    local grandTotal = currentCartTotal + tax
    
    -- Build customer selection menu
    local menuOptions = {}
    
    -- Add order summary at top
    table.insert(menuOptions, {
        title = '📋 Order Total: $' .. lib.math.groupdigits(grandTotal),
        description = string.format('%d items (incl. $%s tax)', #currentCart, lib.math.groupdigits(tax)),
        icon = 'fas fa-calculator',
        disabled = true
    })
    
    table.insert(menuOptions, {
        title = '─────────────────────',
        disabled = true
    })
    
    -- Add customer options with distance
    for i, option in ipairs(playerOptions) do
        local distance = nearbyPlayers[i] and nearbyPlayers[i].distance or 0
        
        table.insert(menuOptions, {
            title = option.title,
            description = option.description .. string.format(' • %.1fm away', distance),
            icon = 'fas fa-user',
            iconColor = '#3B82F6',
            onSelect = function()
                processPayment(machine, option.value, currentCartTotal, cartDescription)
            end
        })
    end
    
    table.insert(menuOptions, {
        title = '─────────────────────',
        disabled = true
    })
    
    table.insert(menuOptions, {
        title = '← Back to Cart',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            showCartMenu(machine)
        end
    })
    
    lib.registerContext({
        id = 'pos_select_customer',
        title = '👥 Select Customer',
        options = menuOptions
    })
    
    lib.showContext('pos_select_customer')
end

-- Process payment
function processPayment(machine, customerId, amount, description)
    activePOS = true
    
    -- Show loading with progress circle
    if lib.progressCircle({
        duration = 2000,
        label = 'Processing payment...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle'
        }
    }) then
        -- Send to server
        local success, result = lib.callback.await('eb-template:pos:createTransaction', false, {
            target = customerId,
            amount = amount,
            description = description,
            business = machine.business,
            items = currentCart
        })
        
        activePOS = false
        
        if success then
            -- Play success sound
            PlaySound(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", 0, 0, 1)
            
            lib.notify({
                title = '✅ Payment Successful',
                description = 'Transaction #' .. result .. ' completed',
                type = 'success',
                position = Config.NotificationPosition,
                icon = 'fas fa-check-circle',
                duration = 5000
            })
            
            -- Clear cart after successful payment
            resetCart()
            
            -- Return to main menu
            Wait(1000)
            openPOSInterface(machine)
        else
            lib.notify({
                title = '❌ Transaction Failed',
                description = result or 'Failed to process payment',
                type = 'error',
                position = Config.NotificationPosition,
                icon = 'fas fa-exclamation-triangle'
            })
        end
    else
        activePOS = false
    end
end

-- View transactions (manager function)
function viewTransactions(machine)
    local transactions = lib.callback.await('eb-template:pos:getTransactions', false, machine.business, 20)
    
    if not transactions or #transactions == 0 then
        lib.alertDialog({
            header = 'No Transactions',
            content = 'No recent transactions found.',
            centered = true
        })
        return
    end
    
    local menuOptions = {}
    
    for _, trans in ipairs(transactions) do
        local timestamp = os.date('%m/%d %I:%M %p', trans.timestamp)
        
        table.insert(menuOptions, {
            title = 'Transaction #' .. trans.id,
            description = trans.description,
            icon = 'fas fa-file-invoice-dollar',
            metadata = {
                {label = 'Time', value = timestamp},
                {label = 'Total', value = '$' .. lib.math.groupdigits(trans.total)},
                {label = 'Employee', value = trans.employee_name},
                {label = 'Tax', value = '$' .. lib.math.groupdigits(trans.tax)}
            }
        })
    end
    
    lib.registerContext({
        id = 'pos_transactions',
        title = '📊 Recent Transactions',
        menu = 'pos_manager_menu',
        options = menuOptions
    })
    
    lib.showContext('pos_transactions')
end

-- Create POS zones on resource start
CreateThread(function()
    Wait(1000) -- Wait for initialization
    
    if not Config.POS.Enabled then return end
    
    for _, pos in ipairs(Config.POS.Machines) do
        -- Create blip if enabled
        if Config.POS.EnableBlips then
            local blip = AddBlipForCoord(pos.coords)
            SetBlipSprite(blip, 605)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.6)
            SetBlipColour(blip, 2)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(pos.label)
            EndTextCommandSetBlipName(blip)
        end
        
        -- Target options
        local options = {
            {
                name = 'pos_' .. pos.id,
                label = 'Use POS Machine',
                icon = 'fas fa-cash-register',
                distance = 2.0,
                groups = {[Config.RestaurantJob] = 0},
                canInteract = function()
                    return canUsePOS()
                end,
                onSelect = function()
                    openPOSInterface(pos)
                end
            }
        }
        
        -- Create target zone
        if pos.size then
            posZones[pos.id] = exports.ox_target:addBoxZone({
                coords = pos.coords,
                size = pos.size,
                rotation = pos.rotation or 0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        else
            posZones[pos.id] = exports.ox_target:addSphereZone({
                coords = pos.coords,
                radius = pos.radius or 1.0,
                debug = Config.Debug,
                drawSprite = Config.TargetOptions.drawSprite,
                options = options
            })
        end
    end
    
    if Config.Debug then
        print(('[%s] POS system initialized with %d machines'):format(GetCurrentResourceName(), #Config.POS.Machines))
    end
end)

-- Export function to add POS machines dynamically
exports('addPOSMachine', function(coords, business, label)
    table.insert(Config.POS.Machines, {
        coords = coords,
        business = business or Config.RestaurantJob,
        label = label or Config.RestaurantLabel .. ' POS'
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, zone in pairs(posZones) do
            exports.ox_target:removeZone(zone)
        end
        resetCart()
    end
end)