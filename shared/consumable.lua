-- ====================================
-- CONSUMABLES CONFIGURATION
-- ====================================
-- Define consumption effects and animations for food/drink items

Config.Consumables = {}

-- ====================================
-- EXAMPLE DRINK ITEMS
-- ====================================

-- Basic Coffee
Config.Consumables['coffee'] = {
    emote = 'coffee', -- Animation/emote name (see emote.lua)
    time = 5000, -- Consumption time in milliseconds
    stats = {
        thirst = { 20, 30 }, -- Min/max thirst restored
        stress = { -2, -4 } -- Negative values reduce stress
    },
    notification = 'The coffee is energizing!',
    -- Optional: Trigger custom client event after consumption
    -- clientEvent = 'your-script:client:CaffeineEffect',
    -- clientEventData = { duration = 60000 }
}

-- Soda
Config.Consumables['soda'] = {
    emote = 'cup', -- Using generic cup emote
    time = 5000,
    stats = {
        thirst = { 30, 40 },
        stress = { -1, -2 }
    },
    notification = 'Refreshing and sweet!'
}

-- Alcoholic Drink Example
Config.Consumables['beer'] = {
    emote = 'beer',
    time = 5000,
    canRun = false, -- Can't run while drinking
    stats = {
        thirst = { 15, 25 },
        stress = { -3, -5 },
        canOD = true -- Can overdose if drinking too much
    },
    notification = 'The beer is cold and refreshing',
    clientEvent = 'eb-template:client:DrunkEffect', -- Triggers drunk effect
    clientEventData = 2 -- Drunk level (1-10)
}

-- ====================================
-- EXAMPLE FOOD ITEMS
-- ====================================

-- Burger
Config.Consumables['burger'] = {
    emote = 'burger',
    time = 5000,
    stats = {
        hunger = { 40, 50 },
        stress = { -2, -4 }
    },
    notification = 'The burger is delicious!'
}

-- Sandwich
Config.Consumables['sandwich'] = {
    emote = 'sandwich',
    time = 5000,
    stats = {
        hunger = { 30, 40 },
        stress = { -1, -3 }
    },
    notification = 'A tasty sandwich!'
}

-- Salad
Config.Consumables['salad'] = {
    emote = 'sandwich', -- Using sandwich emote as placeholder
    time = 4000,
    stats = {
        hunger = { 25, 35 },
        stress = { -2, -3 },
        -- Optional: Add health benefit
        -- health = { 5, 10 }
    },
    notification = 'Fresh and healthy!'
}

-- Fries
Config.Consumables['fries'] = {
    emote = 'sandwich', -- Placeholder emote
    time = 4000,
    stats = {
        hunger = { 20, 30 },
        stress = { -1, -2 }
    },
    notification = 'Crispy and salty!'
}

-- Wings
Config.Consumables['wings'] = {
    emote = 'sandwich', -- Placeholder emote
    time = 6000,
    stats = {
        hunger = { 35, 45 },
        stress = { -2, -4 }
    },
    notification = 'Spicy and delicious!'
}

-- Steak
Config.Consumables['cooked_steak'] = {
    emote = 'sandwich', -- Placeholder emote
    time = 8000,
    stats = {
        hunger = { 50, 60 },
        stress = { -3, -5 },
        -- Optional: Add armor for premium food
        -- armor = { 5, 10 }
    },
    notification = 'Perfectly cooked steak!'
}

-- ====================================
-- INGREDIENT ITEMS (Optional)
-- ====================================
-- Make ingredients consumable with small benefits

Config.Consumables['tomato'] = {
    emote = 'sandwich',
    time = 3000,
    stats = {
        hunger = { 5, 10 },
        stress = { 0, -1 }
    },
    notification = 'Fresh tomato!'
}

Config.Consumables['lettuce'] = {
    emote = 'sandwich',
    time = 3000,
    stats = {
        hunger = { 5, 10 },
        stress = { 0, -1 }
    },
    notification = 'Crisp lettuce!'
}

Config.Consumables['cheese'] = {
    emote = 'sandwich',
    time = 3000,
    stats = {
        hunger = { 10, 15 },
        stress = { 0, 0 }
    },
    notification = 'Tasty cheese!'
}

Config.Consumables['bread'] = {
    emote = 'sandwich',
    time = 3000,
    stats = {
        hunger = { 10, 20 },
        stress = { 0, 0 }
    },
    notification = 'Fresh bread!'
}

Config.Consumables['water'] = {
    emote = 'cup', 
    time = 3000,
    stats = {
        thirst = { 25, 35 },
        stress = { 0, -1 }
    },
    notification = 'Refreshing water!'
}


-- ====================================
-- CONSUMABLE EFFECTS GUIDE
-- ====================================
--[[
Available stat effects:
- hunger: { min, max } - Restores hunger
- thirst: { min, max } - Restores thirst  
- stress: { min, max } - Changes stress (negative reduces)
- health: { min, max } - Restores health
- armor: { min, max } - Adds armor

Optional properties:
- canRun: boolean - Can player run while consuming
- canOD: boolean - Can overdose on this item
- clientEvent: string - Event to trigger after consumption
- clientEventData: any - Data to pass to the event

Emote names must match definitions in emote.lua
]]