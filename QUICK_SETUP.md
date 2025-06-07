# Quick Setup Guide - Restaurant Template

Follow these steps to get your restaurant running quickly.

## Step 1: Basic Configuration

Edit `shared/config.lua` and change these 3 lines:

```lua
Config.RestaurantName = 'burgershot'     -- lowercase, no spaces
Config.RestaurantLabel = 'Burger Shot'    -- Display name
Config.RestaurantJob = 'burgershot'       -- Must match QBCore job
```

## Step 2: Update ALL Event Names

### Find & Replace These Events:

**In client files:**

- `'eb-template:toggleDuty'` → `'burgershot:toggleDuty'`
- `'eb-template:completeCooking'` → `'burgershot:completeCooking'`
- `'eb-template:server:consumed'` → `'burgershot:server:consumed'`
- `'eb-template:client:AddHealth'` → `'burgershot:client:AddHealth'`
- `'eb-template:client:AddArmor'` → `'burgershot:client:AddArmor'`
- `'eb-template:client:DrunkEffect'` → `'burgershot:client:DrunkEffect'`
- `'eb-template:client:EnergyBoost'` → `'burgershot:client:EnergyBoost'`

**In server files:**

- All matching event names (same as above)

### Find & Replace These Callbacks:

**In both client and server files:**

- `'eb-template:getDutyStatus'` → `'burgershot:getDutyStatus'`
- `'eb-template:getOnDutyEmployees'` → `'burgershot:getOnDutyEmployees'`
- `'eb-template:checkIngredients'` → `'burgershot:checkIngredients'`
- `'eb-template:pos:getNearbyPlayerOptions'` → `'burgershot:pos:getNearbyPlayerOptions'`
- `'eb-template:pos:createTransaction'` → `'burgershot:pos:createTransaction'`
- `'eb-template:pos:getTransactions'` → `'burgershot:pos:getTransactions'`
- `'eb-template:pos:getDailyReport'` → `'burgershot:pos:getDailyReport'`

## Step 3: Update Food(s)

**In `shared/consumable.lua`**, Setup your food/drink.

```lua
Config.Consumables['soda'] = {
    emote = 'cup', -- Using generic cup emote
    time = 5000,
    stats = {
        thirst = { 30, 40 },
        stress = { -1, -2 }
    },
    notification = 'Refreshing and sweet!'
}
```

## Step 4: Add Items to ox_inventory

Add your items to `ox_inventory/data/items.lua`:

### Example Food Item:

```lua
['burger'] = {
    label = 'Burger',
    weight = 300,
    stack = true,
    close = true,
    description = 'A delicious burger',
    consume = 1,
    client = {
        image = 'burger.png',
        export = 'eb-burgershot.useConsumable'
    }
},
```

### Example Drink Item:

```lua
['coffee'] = {
    label = 'Coffee',
    weight = 200,
    stack = true,
    close = true,
    description = 'Freshly brewed coffee',
    consume = 1,
    client = {
        image = 'coffee.png',
        export = 'eb-burgershot.useConsumable'
    }
},
```

### Example Ingredient (Non-consumable):

```lua
['raw_patty'] = {
    label = 'Raw Patty',
    weight = 150,
    stack = true,
    close = true,
    description = 'Raw beef patty - needs cooking'
},
```

## Step 5: Add Job to QBCore

In `qbx_core/shared/jobs.lua`:

```lua
 ['catcafe'] = {
        label = 'Cat Cafe',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [1] = {
                name = 'Trainee',
                payment = 35
            },
            [2] = {
                name = 'Barista',
                payment = 45
            },
            [3] = {
                name ='Team Lead',
                payment = 55
            },
            [4] = {
                name = 'Manager',
                payment = 75
            },
            [5] = {
                name = 'Owner/Operator',  -- KP and Serenity
                isboss = true,
                bankAuth = true,
                payment = 100
            }
        }
    },
```

## Step 6: Set Your Coordinates

Update these in `shared/config.lua`:

### Work Zone (for auto clock-in):

```lua
Config.ClockZones = {
    {
        id = 'burgershot_zone',
        points = {
            vec3(-1193.87, -897.38, 13.98),  -- Corner 1
            vec3(-1183.44, -884.27, 13.98),  -- Corner 2
            vec3(-1178.24, -891.77, 13.98),  -- Corner 3
            vec3(-1188.67, -904.88, 13.98),  -- Corner 4
        },
        thickness = 5.0,
        autoClockIn = true
    }
}
```

### Cooking Stations:

```lua
Config.CookingStations = {
    {
        id = 'grill',
        label = 'Grill',
        coords = vec3(-1202.79, -897.27, 13.98),  -- Your coords
        size = vec3(1.8, 1.5, 1.0),
        rotation = 304.0,
        recipes = {'burger', 'bacon'}  -- Your recipes
    }
}
```

## Step 7: Rename Resource Folder

1. Rename `eb-template` to `eb-burgershot` (or your restaurant name)
2. Update `fxmanifest.lua` name to match

## Step 8: Start the Resource

Add to your `server.cfg`:

```
ensure eb-burgershot
```

## Common Item Examples

### Food Items:

```lua
['sandwich'] = {
    label = 'Sandwich',
    weight = 250,
    stack = true,
    close = true,
    description = 'Fresh sandwich',
    consume = 1,
    client = {
        image = 'sandwich.png',
        export = 'eb-burgershot.useConsumable'
    }
},

['fries'] = {
    label = 'French Fries',
    weight = 150,
    stack = true,
    close = true,
    description = 'Crispy golden fries',
    consume = 1,
    client = {
        image = 'fries.png',
        export = 'eb-burgershot.useConsumable'
    }
},
```

### Drink Items:

```lua
['soda'] = {
    label = 'Soda',
    weight = 330,
    stack = true,
    close = true,
    description = 'Refreshing soda',
    consume = 1,
    client = {
        image = 'soda.png',
        export = 'eb-burgershot.useConsumable'
    }
},

['water'] = {
    label = 'Water Bottle',
    weight = 500,
    stack = true,
    close = true,
    description = 'Fresh water',
    consume = 1,
    client = {
        image = 'water.png',
        export = 'eb-burgershot.useConsumable'
    }
},
```

### Ingredients (Non-consumable):

```lua
['lettuce'] = {
    label = 'Lettuce',
    weight = 50,
    stack = true,
    close = true,
    description = 'Fresh lettuce leaves'
},

['cheese'] = {
    label = 'Cheese Slice',
    weight = 30,
    stack = true,
    close = true,
    description = 'Sliced cheese'
},

['bread'] = {
    label = 'Bread',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh bread'
},
```

## Checklist

- [ ] Changed restaurant name, label, and job in config
- [ ] Replaced ALL `eb-template:` events with your restaurant name
- [ ] Updated export references in consumables
- [ ] Added all items to ox_inventory with correct export
- [ ] Added job to QBCore
- [ ] Set up all coordinates (zones, stations, storage, POS)
- [ ] Renamed resource folder
- [ ] Updated fxmanifest.lua name

## Tips

1. **Use Find & Replace**: Use your editor's find & replace (Ctrl+Shift+F) to quickly change all event names
2. **Test One Station First**: Get one cooking station working before adding all of them
3. **Images**: Put item images in `ox_inventory/web/images/`
4. **Debug Mode**: Set `Config.Debug = true` to see zones while setting up
