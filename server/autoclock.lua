local QBX = exports['qb-core']:GetCoreObject()

-- Toggle duty status
RegisterNetEvent('eb-template:toggleDuty', function()
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has the restaurant job
    if Player.PlayerData.job.name ~= Config.RestaurantJob then
        return
    end
    
    -- Get current duty status
    local currentDuty = Player.PlayerData.job.onduty
    local newDuty = not currentDuty
    
    if Config.Debug then
        print(('[%s] Player %s (%s) toggling duty from %s to %s'):format(
            GetCurrentResourceName(),
            GetPlayerName(src),
            src,
            tostring(currentDuty),
            tostring(newDuty)
        ))
    end
    
    -- Toggle duty status
    Player.Functions.SetJobDuty(newDuty)
    
    -- Force sync the job update to client
    TriggerClientEvent('QBCore:Client:OnJobUpdate', src, Player.PlayerData.job)
    
    -- Send notification
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.RestaurantLabel,
        description = newDuty and 'You have been clocked in' or 'You have been clocked out',
        type = newDuty and 'success' or 'info',
        position = Config.NotificationPosition,
        icon = 'clock'
    })
    
    -- Optional: Discord logging
    if Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
        local embed = {
            {
                title = 'Duty Status Changed',
                description = ('**Player:** %s\n**Status:** %s\n**Time:** %s'):format(
                    GetPlayerName(src),
                    newDuty and 'Clocked In' or 'Clocked Out',
                    os.date('%Y-%m-%d %H:%M:%S')
                ),
                color = newDuty and 5763719 or 15548997, -- Green for in, Red for out
                footer = {
                    text = Config.RestaurantLabel
                }
            }
        }
        
        PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
            username = Config.RestaurantLabel,
            embeds = embed
        }), { ['Content-Type'] = 'application/json' })
    end
end)

-- Get duty status (for UI or other systems)
lib.callback.register('eb-template:getDutyStatus', function(source)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.PlayerData.job.onduty
end)

-- Get all on-duty employees
lib.callback.register('eb-template:getOnDutyEmployees', function(source)
    local employees = {}
    local Players = QBX.Functions.GetPlayers()
    
    for _, playerId in pairs(Players) do
        local Player = QBX.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.job.name == Config.RestaurantJob and Player.PlayerData.job.onduty then
            table.insert(employees, {
                id = playerId,
                name = GetPlayerName(playerId),
                grade = Player.PlayerData.job.grade
            })
        end
    end
    
    return employees
end)