local QBX = exports['qb-core']:GetCoreObject()

-- Variables
local isConsuming = false
local currentProp = nil
local currentSecondProp = nil

-- Helper function to load animation dictionary
local function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    
    RequestAnimDict(dict)
    local timeout = 1000
    while not HasAnimDictLoaded(dict) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    
    return HasAnimDictLoaded(dict)
end

-- Helper function to create and attach prop
local function CreateProp(model, ped, bone, placement)
    local modelName = model
    if type(model) == 'number' then
        print('[ERROR] Model provided as hash instead of string:', model)
        return nil
    end
    
    lib.requestModel(modelName)
    local modelHash = GetHashKey(modelName)
    
    local prop = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), 
        placement[1], placement[2], placement[3],
        placement[4], placement[5], placement[6], 
        true, true, false, false, 1, true)
    
    return prop
end

-- Clean up props
local function CleanupProps()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
    if currentSecondProp and DoesEntityExist(currentSecondProp) then
        DeleteEntity(currentSecondProp)
        currentSecondProp = nil
    end
end

-- Animation handler
local function PlayConsumptionAnim(itemData, itemName)
    local emoteKey = itemData.emote
    if not emoteKey or not Config.Emotes[emoteKey] then
        print('[ERROR] Invalid emote:', emoteKey)
        return
    end
    
    local emote = Config.Emotes[emoteKey]
    local ped = PlayerPedId()
    
    -- Load animation
    if not LoadAnimDict(emote.dict) then
        print('[ERROR] Failed to load animation dict:', emote.dict)
        return
    end
    
    -- Play animation
    local flag = emote.emoteLoop and 49 or 0
    if emote.emoteMoving then
        flag = emote.emoteLoop and 51 or 48
    end
    
    TaskPlayAnim(ped, emote.dict, emote.anim, 8.0, -8.0, -1, flag, 0, false, false, false)
    
    -- Handle custom prop models if defined
    local propModel = emote.prop
    if Config.CustomProps and Config.CustomProps[itemName] then
        propModel = Config.CustomProps[itemName]
    end
    
    -- Create main prop
    if propModel then
        if IsModelValid(GetHashKey(propModel)) then
            currentProp = CreateProp(propModel, ped, emote.bone, emote.placement)
        else
            print('[WARNING] Prop model not found:', propModel)
            print('Make sure custom props are properly streamed')
        end
    end
    
    -- Create second prop if exists
    if emote.secondProp then
        if IsModelValid(GetHashKey(emote.secondProp)) then
            currentSecondProp = CreateProp(emote.secondProp, ped, emote.secondPropBone, emote.secondPropPlacement)
        else
            print('[WARNING] Second prop model not found:', emote.secondProp)
        end
    end
    
    -- Handle duration
    local duration = itemData.time or 5000
    SetTimeout(duration, function()
        ClearPedTasks(ped)
        CleanupProps()
        RemoveAnimDict(emote.dict)
        isConsuming = false
    end)
end

-- Health effect handler
RegisterNetEvent('eb-template:client:AddHealth', function(amount)
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    
    SetEntityHealth(ped, math.min(health + amount, maxHealth))
end)

-- Armor effect handler
RegisterNetEvent('eb-template:client:AddArmor', function(amount)
    local ped = PlayerPedId()
    local armor = GetPedArmour(ped)
    
    SetPedArmour(ped, math.min(armor + amount, 100))
end)

-- Drunk effect handler
RegisterNetEvent('eb-template:client:DrunkEffect', function(level)
    local ped = PlayerPedId()
    
    if level > 0 then
        local clipset = 'MOVE_M@DRUNK@SLIGHTLYDRUNK'
        if level > 3 then
            clipset = 'MOVE_M@DRUNK@MODERATEDRUNK'
        end
        if level > 6 then
            clipset = 'MOVE_M@DRUNK@VERYDRUNK'
        end
        
        SetPedMovementClipset(ped, clipset, 1.0)
        
        if level > 3 then
            AnimpostfxPlay('Rampage', 10000, true)
        end
        
        SetTimeout(level * 30000, function()
            ResetPedMovementClipset(ped, 1.0)
            AnimpostfxStopAll()
        end)
    else
        ResetPedMovementClipset(ped, 1.0)
        AnimpostfxStopAll()
    end
end)

-- Energy boost effect handler (example custom effect)
RegisterNetEvent('eb-template:client:EnergyBoost', function(data)
    local ped = PlayerPedId()
    local duration = data.duration or 120000
    local speedBoost = data.speedBoost or 1.2
    
    -- Apply speed boost
    SetRunSprintMultiplierForPlayer(PlayerId(), speedBoost)
    
    -- Visual effect
    AnimpostfxPlay('FocusIn', 2000, false)
    
    -- Notification
    lib.notify({
        title = 'Energy Boost',
        description = 'You feel energized!',
        type = 'success',
        duration = 5000
    })
    
    -- Remove effect after duration
    SetTimeout(duration, function()
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        AnimpostfxPlay('FocusOut', 2000, false)
        
        lib.notify({
            title = 'Energy Boost',
            description = 'The energy boost has worn off',
            type = 'inform',
            duration = 3000
        })
    end)
end)

-- Main consumable function for ox_inventory
local function useConsumable(data, slot)
    local itemName = data.name
    if not itemName then return end
    
    -- Get consumable config
    local itemData = Config.Consumables[itemName]
    if not itemData then 
        lib.notify({
            title = 'Error',
            description = 'This item cannot be consumed',
            type = 'error'
        })
        return false
    end
    
    local ped = PlayerPedId()
    
    -- Check if already consuming
    if isConsuming then
        lib.notify({
            title = 'Busy',
            description = 'You are already consuming something',
            type = 'error'
        })
        return false
    end
    
    -- Check if in vehicle and item allows running
    if IsPedInAnyVehicle(ped, false) and not (itemData.canRun == true) then
        lib.notify({
            title = 'Cannot Consume',
            description = 'You cannot consume this in a vehicle',
            type = 'error'
        })
        return false
    end
    
    -- Check if dead or cuffed
    if IsEntityDead(ped) or IsPedCuffed(ped) then
        lib.notify({
            title = 'Cannot Consume',
            description = 'You cannot consume this right now',
            type = 'error'
        })
        return false
    end
    
    -- Item was successfully used, play animation
    isConsuming = true
    PlayConsumptionAnim(itemData, itemName)
    
    -- Trigger server to apply effects
    TriggerServerEvent('eb-template:server:consumed', itemName)
    
    -- Key thread to cancel animation
    CreateThread(function()
        while isConsuming do
            Wait(0)
            -- Press E to cancel
            if IsControlJustPressed(0, 38) then
                ClearPedTasks(ped)
                CleanupProps()
                isConsuming = false
                lib.notify({
                    title = 'Cancelled',
                    description = 'You stopped consuming',
                    type = 'inform'
                })
                break
            end
        end
    end)
    
    return true
end

-- Export for ox_inventory
exports('useConsumable', useConsumable)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    ClearPedTasks(PlayerPedId())
    CleanupProps()
    AnimpostfxStopAll()
    ResetPedMovementClipset(PlayerPedId(), 1.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)