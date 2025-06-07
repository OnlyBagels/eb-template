-- ====================================
-- POS SYSTEM CONFIGURATION
-- ====================================

Config.POS = {}

-- General POS Settings
Config.POS.Enabled = true -- Enable/disable the entire POS system
Config.POS.TaxRate = 2 -- Tax percentage (2 = 2%)
Config.POS.TaxAccount = 'government' -- Where tax money goes (Renewed-Banking account)
Config.POS.EnableBlips = false -- Show POS machines on map
Config.POS.EnableBankHistory = true -- Create transaction records in Renewed-Banking
Config.POS.SaveTransactionsToDB = true -- Save transactions to database
Config.POS.ManagerGradeLevel = 3 -- Minimum job grade to view reports

-- ====================================
-- POS MACHINE LOCATIONS
-- ====================================
Config.POS.Machines = {
    {
        id = 'register_1',
        label = 'Cash Register #1',
        coords = vec3(-90.0, 95.0, 50.0), -- Replace with your coordinates
        size = vec3(0.8, 0.8, 1.0), -- Box zone
        rotation = 45.0,
        business = Config.RestaurantJob
    },
    {
        id = 'register_2',
        label = 'Cash Register #2',
        coords = vec3(-95.0, 98.0, 50.0), -- Replace with your coordinates
        radius = 0.8, -- Sphere zone (alternative to box)
        business = Config.RestaurantJob
    }
}

-- Business name mapping (for display)
Config.POS.BusinessNames = {
    [Config.RestaurantJob] = Config.RestaurantLabel
}

-- ====================================
-- COMBO MEALS CONFIGURATION
-- ====================================
-- Define special combo deals
Config.POS.ComboMeals = {
    {
        id = 'value_meal',
        label = 'Value Meal',
        description = 'Complete meal deal',
        price = 25,
        -- Optional: Define what's included (for display)
        items = {
            {name = 'burger', quantity = 1},
            {name = 'fries', quantity = 1},
            {name = 'soda', quantity = 1}
        }
    },
    {
        id = 'breakfast_combo',
        label = 'Breakfast Combo',
        description = 'Morning special',
        price = 18,
        items = {
            {name = 'sandwich', quantity = 1},
            {name = 'coffee', quantity = 1}
        }
    },
    {
        id = 'family_deal',
        label = 'Family Deal',
        description = 'Feed the whole family',
        price = 65,
        items = {
            {name = 'burger', quantity = 4},
            {name = 'fries', quantity = 4},
            {name = 'soda', quantity = 4}
        }
    },
}

-- ====================================
-- ITEM PRICES
-- ====================================
-- Set prices for individual menu items
Config.POS.ItemPrices = {
    -- Food Items
    burger = 15,
    sandwich = 12,
    salad = 10,
    cooked_steak = 25,
    fries = 8,
    wings = 18,
    
    -- Drinks
    coffee = 5,
    soda = 4,
    beer = 6,
    wine = 8,
    water = 2,
    energy_drink = 7,
    
    -- Add all your menu items here
    -- The key must match the recipe ID from Config.Recipes
}

-- ====================================
-- ADVANCED CONFIGURATION
-- ====================================

-- Transaction webhook format
Config.POS.WebhookFormat = {
    username = Config.RestaurantLabel .. ' POS',
    avatar_url = '', -- Optional: Discord avatar URL
    color = 5763719 -- Green color in decimal
}

-- Manager permissions
Config.POS.ManagerPermissions = {
    viewTransactions = true,
    viewReports = true,
    refundTransactions = false, -- Not implemented by default
    modifyPrices = false -- Not implemented by default
}

-- ====================================
-- POS CONFIGURATION GUIDE
-- ====================================
--[[
Setting up the POS System:

1. Machine Placement:
   - Use either size (box) or radius (sphere) for zones
   - Ensure coords are accessible to customers
   - Multiple registers can share the same business

2. Pricing Strategy:
   - Individual items: Set in ItemPrices
   - Combos: Usually discounted vs buying separately
   - Consider your server's economy

3. Banking Integration:
   - Requires Renewed-Banking for full functionality
   - Business account must exist with same name as job
   - Tax account should exist for tax collection

4. Manager Features:
   - Set appropriate grade level for managers
   - Daily reports show sales summaries
   - Transaction logs for accountability

5. Custom Combos:
   - Create meal deals to encourage larger orders
   - Items list is optional but helps with display
   - Price should be less than sum of components
]]