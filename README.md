# Restaurant Template for FiveM (QBox)

A comprehensive restaurant management system template for FiveM servers using the QBox framework with Ox dependencies.

## Features

- 🍳 **Dynamic Cooking System** - Multiple cooking stations with configurable recipes
- 📦 **Storage Management** - Organized storage areas using ox_inventory
- 💳 **Advanced POS System** - Complete point-of-sale with tax, combos, and reports
- ⏰ **Auto Clock In/Out** - Zone-based automatic duty management
- 🍔 **Consumables System** - Items with custom effects and animations
- 📊 **Manager Functions** - Transaction logs and daily reports
- 🎯 **Fully Configurable** - Easy to customize for any restaurant theme

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)
- [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) (Optional - for POS banking features)

## Installation

1. **Download and rename** the template folder to your restaurant name (e.g., `eb-burgershot`)

2. **Add to your server.cfg:**

   ```cfg
   ensure eb-yourrestaurant
   ```

3. **Configure the basics** in `shared/config.lua`:

   ```lua
   Config.RestaurantName = 'yourrestaurant'
   Config.RestaurantLabel = 'Your Restaurant Name'
   Config.RestaurantJob = 'yourjob'
   ```

4. **Add the job** to your QBCore shared config or job management system

5. **Set up items** in ox_inventory for all ingredients and products

## Quick Setup Guide

### 1. Define Your Restaurant Area

Edit the work zone in `shared/config.lua`:

```lua
Config.ClockZones = {
    {
        id = 'restaurant_zone',
        points = {
            vec3(-100.0, 100.0, 50.0), -- Your corner coordinates
            vec3(-90.0, 100.0, 50.0),
            vec3(-90.0, 90.0, 50.0),
            vec3(-100.0, 90.0, 50.0),
        },
        thickness = 4.0,
        autoClockIn = true
    }
}
```

### 2. Set Up Cooking Stations

Add your cooking areas:

```lua
Config.CookingStations = {
    {
        id = 'grill',
        label = 'Grill Station',
        coords = vec3(x, y, z),
        size = vec3(1.5, 1.5, 1.5),
        recipes = {'burger', 'steak'} -- Your recipe IDs
    }
}
```

### 3. Create Recipes

Define what can be cooked:

```lua
Config.Recipes = {
    ['burger'] = {
        label = 'Burger',
        duration = 8000,
        requiredItems = {
            {name = 'raw_patty', amount = 1},
            {name = 'burger_bun', amount = 1}
        },
        receivedItems = {
            {name = 'burger', amount = 1}
        }
    }
}
```

### 4. Configure Storage

Set up storage locations:

```lua
Config.Storages = {
    {
        id = 'ingredients',
        label = 'Ingredients Fridge',
        coords = vec3(x, y, z),
        size = vec3(2.0, 2.0, 2.0),
        slots = 50,
        weight = 100000
    }
}
```

### 5. Add Consumables

Make items consumable with effects:

```lua
Config.Consumables['burger'] = {
    emote = 'burger',
    time = 5000,
    stats = {
        hunger = { 40, 50 },
        stress = { -2, -4 }
    },
    notification = 'Delicious burger!'
}
```

## File Structure

```
eb-template/
├── client/
│   ├── main.lua          # Core client functions
│   ├── cooking.lua       # Cooking system
│   ├── storage.lua       # Storage zones
│   ├── consumable.lua    # Consumable handler
│   ├── autoclock.lua     # Auto duty system
│   └── pos.lua           # POS interface
├── server/
│   ├── main.lua          # Core server functions
│   ├── cooking.lua       # Cooking validation
│   ├── storage.lua       # Storage registration
│   ├── consumable.lua    # Consumption effects
│   ├── autoclock.lua     # Duty management
│   └── pos.lua           # POS transactions
├── shared/
│   ├── config.lua        # Main configuration
│   ├── consumable.lua    # Consumable definitions
│   ├── emote.lua         # Animation definitions
│   └── pos.lua           # POS configuration
├── stream/               # Custom props (optional)
├── fxmanifest.lua
└── README.md
```

## Configuration Examples

### Restaurant Type

**Example:**

```lua
Config.RestaurantName = 'burgershot'
Config.RestaurantLabel = 'Burger Shot'
Config.RestaurantJob = 'burgershot'

-- Stations: Grill, Fryer, Drinks
-- Products: Burgers, Fries, Sodas
```


## Advanced Features

### Batch Cooking

Players can cook multiple items at once with smart time scaling:

- 1-20 items: +3.6s per item
- 20-50 items: +2.6s per item
- 50-100 items: +2.0s per item

### POS System

- Supports individual items and combo meals
- Automatic tax calculation
- Customer selection from nearby players
- Transaction logging and reports
- Manager-only features for viewing sales

### Auto Clock System

- Automatically clocks in when entering work zone
- Clocks out when leaving the restaurant
- Optional manual clock points
- Prevents rapid toggling with cooldown

## Customization Tips

1. **Adding New Stations**: Copy an existing station in config and modify coordinates/recipes
2. **Custom Props**: Add to `stream/` folder and update `fxmanifest.lua`
3. **New Effects**: Add client events in consumable definitions
4. **Price Balancing**: Consider your server economy when setting prices
5. **Zone Sizes**: Adjust zone sizes based on your restaurant layout

## Troubleshooting

**Players can't cook:**

- Ensure they have the correct job and are on duty
- Check zone coordinates and sizes
- Verify recipe items exist in ox_inventory

**Storage not working:**

- Check stash names match the format: `restaurantname_stashid`
- Ensure ox_inventory is started before this resource

**POS errors:**

- Verify Renewed-Banking is installed (if using banking features)
- Check business account exists with job name
- Ensure customer is within range (10 units)

## Support

For issues or questions:

1. Check the configuration files for detailed comments
2. Enable `Config.Debug = true` for zone visualization
3. Check server console for error messages
4. Ensure all dependencies are up to date

## License

This template is provided as-is for use in FiveM servers. Feel free to modify and distribute as needed.

## Credits

- Built for QBox Framework
- Uses Overextended's excellent ox libraries
- Inspired by various restaurant scripts in the FiveM community
- Bagelbites99 for putting it all together for a lovely little template :)
