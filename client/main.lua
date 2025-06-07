local QBX = exports['qb-core']:GetCoreObject()

-- Initialize ox_lib
lib.locale()

-- Cache player job
PlayerJob = nil

-- Update job when player data changes
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = exports.qbx_core:GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

-- Initialize on resource start
CreateThread(function()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData then
        PlayerJob = playerData.job
    end
end)

-- Check if player has restaurant job
function HasRestaurantJob()
    return PlayerJob and PlayerJob.name == Config.RestaurantJob
end

-- Check if player is on duty
function IsOnDuty()
    return PlayerJob and PlayerJob.name == Config.RestaurantJob and PlayerJob.onduty
end

-- Export functions for other resources
exports('HasRestaurantJob', HasRestaurantJob)
exports('IsOnDuty', IsOnDuty)