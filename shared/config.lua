Config = {}

-- ====================================
-- RESTAURANT CONFIGURATION
-- ====================================
Config.RestaurantName = 'template' -- Used for stash names and identification (lowercase, no spaces)
Config.RestaurantLabel = 'Restaurant Template' -- Display name
Config.RestaurantJob = 'restaurant' -- Must match QBCore job name

-- Debug Mode (shows zones and debug information)
Config.Debug = false

-- Discord Webhook for logging (optional - leave empty to disable)
Config.DiscordWebhook = ''

-- Notification Settings
Config.NotificationPosition = 'top-right' -- top, top-right, top-left, bottom, bottom-right, bottom-left, center-right, center-left

-- ====================================
-- AUTO CLOCK IN/OUT CONFIGURATION
-- ====================================
Config.AutoClockIn = {
    enabled = true -- Enable automatic clock in/out when entering/leaving zones
}

-- Clock In/Out Zones
-- Define the work area(s) for your restaurant
Config.ClockZones = {
    {
        id = 'restaurant_zone',
        label = 'Restaurant Work Zone',
        -- POLYZONE: Define corners of your restaurant area
        points = {
            vec3(-100.0, 100.0, 50.0), -- Replace with your coordinates
            vec3(-90.0, 100.0, 50.0),
            vec3(-90.0, 90.0, 50.0),
            vec3(-100.0, 90.0, 50.0),
        },
        thickness = 4.0, -- Height of the zone
        autoClockIn = true, -- Enable auto clock for this zone
        -- Alternative: Manual clock in point (optional)
        -- manualClock = true,
        -- coords = vec3(-95.0, 95.0, 50.0),
        -- size = vec3(1.0, 1.0, 1.0)
    }
}

-- ====================================
-- COOKING STATIONS CONFIGURATION
-- ====================================
-- Each station represents a cooking area (grill, fryer, prep station, drinks, etc.)
Config.CookingStations = {
    {
        id = 'prep_station',
        label = 'Prep Station',
        coords = vec3(-95.0, 95.0, 50.0), -- Replace with your coordinates
        size = vec3(1.5, 1.5, 1.5), -- Box zone
        rotation = 45.0,
        recipes = {'example_sandwich', 'example_salad'} -- Recipe IDs this station can make
    },
    {
        id = 'grill_station',
        label = 'Grill',
        coords = vec3(-92.0, 95.0, 50.0),
        size = vec3(1.8, 1.8, 1.5),
        rotation = 0.0,
        recipes = {'example_burger', 'example_steak'}
    },
    {
        id = 'drinks_station',
        label = 'Drinks Station',
        coords = vec3(-90.0, 95.0, 50.0),
        radius = 0.8, -- Sphere zone (alternative to box)
        recipes = {'example_coffee', 'example_soda'}
    },
    {
        id = 'fryer_station',
        label = 'Deep Fryer',
        coords = vec3(-93.0, 93.0, 50.0),
        size = vec3(1.5, 1.5, 1.5),
        rotation = 315.0,
        recipes = {'example_fries', 'example_wings'}
    }
}

-- ====================================
-- RECIPE DEFINITIONS
-- ====================================
-- Define what can be cooked at each station
Config.Recipes = {
    -- Prep Station Recipes
    ['example_sandwich'] = {
        label = 'Sandwich',
        duration = 5000, -- Time to cook in milliseconds
        requiredItems = {
            {name = 'bread', amount = 2},
            {name = 'lettuce', amount = 1},
            {name = 'cheese', amount = 1}
        },
        receivedItems = {
            {name = 'sandwich', amount = 1}
        },
        animation = {
            dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
            clip = 'coke_cut_v4_coccutter'
        }
    },
    ['example_salad'] = {
        label = 'Fresh Salad',
        duration = 4000,
        requiredItems = {
            {name = 'lettuce', amount = 2},
            {name = 'tomato', amount = 1},
            {name = 'cucumber', amount = 1}
        },
        receivedItems = {
            {name = 'salad', amount = 1}
        },
        animation = {
            dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
            clip = 'coke_cut_v5_coccutter'
        }
    },
    
    -- Grill Recipes
    ['example_burger'] = {
        label = 'Burger',
        duration = 8000,
        requiredItems = {
            {name = 'raw_patty', amount = 1},
            {name = 'burger_bun', amount = 1},
            {name = 'lettuce', amount = 1}
        },
        receivedItems = {
            {name = 'burger', amount = 1}
        },
        animation = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        }
    },
    ['example_steak'] = {
        label = 'Grilled Steak',
        duration = 10000,
        requiredItems = {
            {name = 'raw_steak', amount = 1},
            {name = 'butter', amount = 1}
        },
        receivedItems = {
            {name = 'cooked_steak', amount = 1}
        },
        animation = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        }
    },
    
    -- Drinks Station Recipes
    ['example_coffee'] = {
        label = 'Coffee',
        duration = 3000,
        requiredItems = {
            {name = 'coffee_beans', amount = 1},
            {name = 'water', amount = 1}
        },
        receivedItems = {
            {name = 'coffee', amount = 1}
        },
        animation = {
            dict = 'mp_ped_interaction',
            clip = 'handshake_guy_a'
        }
    },
    ['example_soda'] = {
        label = 'Soda',
        duration = 2000,
        requiredItems = {}, -- No ingredients required (fountain drink)
        receivedItems = {
            {name = 'soda', amount = 1}
        },
        animation = {
            dict = 'mp_ped_interaction',
            clip = 'handshake_guy_a'
        }
    },
    
    -- Fryer Recipes
    ['example_fries'] = {
        label = 'French Fries',
        duration = 6000,
        requiredItems = {
            {name = 'potato', amount = 2},
            {name = 'salt', amount = 1}
        },
        receivedItems = {
            {name = 'fries', amount = 1}
        },
        animation = {
            dict = 'amb@prop_human_bbq@male@idle_a',
            clip = 'idle_b'
        }
    },
    ['example_wings'] = {
        label = 'Chicken Wings',
        duration = 8000,
        requiredItems = {
            {name = 'raw_wings', amount = 6},
            {name = 'hot_sauce', amount = 1}
        },
        receivedItems = {
            {name = 'wings', amount = 1}
        },
        animation = {
            dict = 'amb@prop_human_bbq@male@idle_a',
            clip = 'idle_b'
        }
    }
}

-- ====================================
-- STORAGE CONFIGURATION
-- ====================================
-- Define storage areas for your restaurant
Config.Storages = {
    {
        id = 'ingredients',
        label = 'Ingredients Storage',
        coords = vec3(-98.0, 92.0, 50.0), -- Replace with your coordinates
        size = vec3(1.5, 1.5, 1.5), -- Box zone
        rotation = 45.0,
        slots = 50,
        weight = 100000, -- 100kg
        groups = {[Config.RestaurantJob] = 0} -- All restaurant employees can access
    },
    {
        id = 'counter',
        label = 'Counter Storage',
        coords = vec3(-92.0, 98.0, 50.0),
        radius = 1.2, -- Sphere zone
        slots = 10,
        weight = 10000, -- 10kg
        groups = {[Config.RestaurantJob] = 0}
    },
    {
        id = 'freezer',
        label = 'Freezer Storage',
        coords = vec3(-96.0, 92.0, 50.0),
        size = vec3(2.0, 3.0, 2.0),
        rotation = 0.0,
        slots = 30,
        weight = 50000, -- 50kg
        groups = {[Config.RestaurantJob] = 0}
    }
}

-- ====================================
-- TARGET OPTIONS CONFIGURATION
-- ====================================
Config.TargetOptions = {
    drawSprite = true,
    drawText = true,
    debugPoly = Config.Debug
}