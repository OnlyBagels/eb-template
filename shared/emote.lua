-- ====================================
-- EMOTE CONFIGURATION
-- ====================================
-- Define animations and props for consumable items

Config = Config or {}
Config.Emotes = {
    -- ====================================
    -- DRINK EMOTES
    -- ====================================
    
    coffee = { 
        dict = "amb@world_human_drinking@coffee@male@idle_a", 
        anim = "idle_c",
        prop = 'p_amb_coffeecup_01', -- Default coffee cup prop
        bone = 28422,
        placement = { 0.0, 0.0, 0.0, 0.0, 0.0, 130.0 },
        emoteLoop = true,
        emoteMoving = true
    },
    
    cup = { 
        dict = "amb@world_human_drinking@coffee@male@idle_a", 
        anim = "idle_c",
        prop = 'prop_plastic_cup_02', -- Generic cup
        bone = 28422,
        placement = { 0.0, 0.0, 0.0, 0.0, 0.0, 130.0 },
        emoteLoop = true,
        emoteMoving = true
    },
    
    bottle = { 
        dict = "mp_player_intdrink", 
        anim = "loop_bottle",
        prop = 'prop_ld_flow_bottle', -- Water bottle
        bone = 60309,
        placement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        emoteLoop = true,
        emoteMoving = true
    },
    
    beer = {
        dict = "mp_player_intdrink", 
        anim = "loop_bottle",
        prop = 'prop_amb_beer_bottle', -- Beer bottle
        bone = 18905,
        placement = { 0.12, 0.008, 0.03, 240.0, -60.0, 0.0 },
        emoteLoop = true,
        emoteMoving = true
    },
    
    wine = {
        dict = "anim@heists@humane_labs@finale@keycards", 
        anim = "ped_a_enter_loop",
        prop = 'prop_drink_redwine', -- Wine glass
        bone = 18905,
        placement = { 0.10, -0.03, 0.03, -100.0, 0.0, -10.0 },
        emoteMoving = true,
        emoteLoop = true
    },
    
    -- ====================================
    -- FOOD EMOTES
    -- ====================================
    
    burger = { 
        dict = "mp_player_inteat@burger", 
        anim = "mp_player_int_eat_burger",
        prop = 'prop_cs_burger_01', -- Burger prop
        bone = 18905,
        placement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 },
        emoteMoving = true
    },
    
    sandwich = { 
        dict = "mp_player_inteat@burger", 
        anim = "mp_player_int_eat_burger",
        prop = 'prop_sandwich_01', -- Sandwich prop
        bone = 18905,
        placement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 },
        emoteMoving = true
    },
    
    donut = {
        dict = "mp_player_inteat@burger", 
        anim = "mp_player_int_eat_burger",
        prop = 'prop_amb_donut', -- Donut prop
        bone = 18905,
        placement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 },
        emoteMoving = true
    },
    
    -- Bowl with utensil (for soups, salads, etc.)
    bowl = {
        dict = "anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1", 
        anim = "base_idle",
        prop = 'prop_cs_bowl_01', -- Bowl
        bone = 60309,
        placement = { 0.0, 0.0300, 0.0100, 0.0, 0.0, 0.0 },
        secondProp = 'prop_cs_fork', -- Fork/spoon
        secondPropBone = 28422,
        secondPropPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
        emoteLoop = true,
        emoteMoving = true
    },
    
    -- ====================================
    -- GENERIC EMOTES
    -- ====================================
    
    generic_eat = {
        dict = "mp_player_inteat@burger", 
        anim = "mp_player_int_eat_burger",
        -- No prop, just animation
        emoteMoving = true
    },
    
    generic_drink = {
        dict = "mp_player_intdrink", 
        anim = "loop_bottle",
        -- No prop, just animation
        emoteMoving = true,
        emoteLoop = true
    }
}

-- ====================================
-- CUSTOM PROP MODELS
-- ====================================
-- If you have custom props, define them here
-- These would need to be streamed in your resource
Config.CustomProps = {
    -- Examples:
    -- custom_burger = 'your_custom_burger_prop',
    -- custom_coffee = 'your_custom_coffee_prop',
    -- custom_pizza = 'your_custom_pizza_prop',
}

-- ====================================
-- EMOTE CONFIGURATION GUIDE
-- ====================================
--[[
Emote Structure:
- dict: Animation dictionary
- anim: Animation name
- prop: Prop model name (optional)
- bone: Bone index to attach prop
- placement: { x, y, z, rotX, rotY, rotZ }
- secondProp: Second prop model (optional, for utensils)
- secondPropBone: Bone for second prop
- secondPropPlacement: Placement for second prop
- emoteLoop: Should animation loop
- emoteMoving: Can move while performing

Common Bone IDs:
- 18905: Right hand
- 57005: Left hand  
- 28422: Right wrist
- 60309: Left wrist
- 58866: Head

To add new emotes:
1. Find appropriate animation dict/clip
2. Find or create prop model
3. Adjust placement values for proper positioning
4. Test in-game and fine-tune
]]