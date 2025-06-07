local QBX = exports['qb-core']:GetCoreObject()

-- Helper function to get random value between two numbers
local function GetRandomValue(range)
    if type(range) == 'table' and #range == 2 then
        local min, max = range[1], range[2]
        return math.random(math.min(min, max), math.max(min, max))
    elseif type(range) == 'number' then
        return range
    else
        return 0
    end
end

-- Event handler for when item is consumed
RegisterNetEvent('eb-template:server:consumed', function(itemName)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    local itemData = Config.Consumables[itemName]
    if not itemData then
        print('[ERROR] Consumable not found:', itemName)
        return
    end
    
    -- Apply status effects
    if itemData.stats then
        local currentMetadata = Player.PlayerData.metadata
        
        if itemData.stats.hunger then
            local hungerAmount = GetRandomValue(itemData.stats.hunger)
            local newHunger = math.min((currentMetadata.hunger or 100) + hungerAmount, 100)
            Player.Functions.SetMetaData('hunger', newHunger)
            
            if Config.Debug then
                print(('[%s] %s consumed %s: Hunger %d -> %d (+%d)'):format(
                    GetCurrentResourceName(), GetPlayerName(src), itemName, 
                    currentMetadata.hunger or 100, newHunger, hungerAmount
                ))
            end
        end
        
        if itemData.stats.thirst then
            local thirstAmount = GetRandomValue(itemData.stats.thirst)
            local newThirst = math.min((currentMetadata.thirst or 100) + thirstAmount, 100)
            Player.Functions.SetMetaData('thirst', newThirst)
            
            if Config.Debug then
                print(('[%s] %s consumed %s: Thirst %d -> %d (+%d)'):format(
                    GetCurrentResourceName(), GetPlayerName(src), itemName, 
                    currentMetadata.thirst or 100, newThirst, thirstAmount
                ))
            end
        end
        
        if itemData.stats.stress then
            local stressAmount = GetRandomValue(itemData.stats.stress)
            local currentStress = currentMetadata.stress or 0
            local newStress = math.max(currentStress + stressAmount, 0)
            Player.Functions.SetMetaData('stress', newStress)
            
            if Config.Debug then
                print(('[%s] %s consumed %s: Stress %d -> %d (%s%d)'):format(
                    GetCurrentResourceName(), GetPlayerName(src), itemName, 
                    currentStress, newStress, 
                    stressAmount >= 0 and '+' or '', stressAmount
                ))
            end
        end
        
        if itemData.stats.armor then
            TriggerClientEvent('eb-template:client:AddArmor', src, GetRandomValue(itemData.stats.armor))
        end
        
        if itemData.stats.health then
            TriggerClientEvent('eb-template:client:AddHealth', src, GetRandomValue(itemData.stats.health))
        end
    end
    
    -- Send notification
    if itemData.notification then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Consumed',
            description = itemData.notification,
            type = 'success',
            position = Config.NotificationPosition or 'top-right'
        })
    end
    
    -- Trigger custom client effects
    if itemData.clientEvent then
        TriggerClientEvent(itemData.clientEvent, src, itemData.clientEventData)
    end
    
    -- Log consumption if debug enabled
    if Config.Debug then
        print('[CONSUMABLES]', GetPlayerName(src), 'consumed', itemName)
    end
end)

-- Export to add custom consumables from other resources
exports('RegisterConsumable', function(itemName, itemData)
    if Config.Consumables[itemName] then
        print('[WARNING] Consumable', itemName, 'already exists, overwriting...')
    end
    
    Config.Consumables[itemName] = itemData
    return true
end)

-- Export to get all consumables
exports('GetConsumables', function()
    return Config.Consumables
end)

-- Export to get specific consumable data
exports('GetConsumable', function(itemName)
    return Config.Consumables[itemName]
end)

-- Check player metadata on resource start for debugging
if Config.Debug then
    CreateThread(function()
        Wait(5000) -- Wait for everything to initialize
        print(('[%s] Consumable system initialized'):format(GetCurrentResourceName()))
        
        local count = 0
        for _ in pairs(Config.Consumables) do
            count = count + 1
        end
        print(('[%s] Total consumables registered: %d'):format(GetCurrentResourceName(), count))
    end)
end