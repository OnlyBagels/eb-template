local QBX = exports['qb-core']:GetCoreObject()

-- Initialize ox_lib
lib.locale()

-- Utility function to get player
local function GetPlayer(source)
    return QBX.Functions.GetPlayer(source)
end

-- Utility function to check job
local function HasJob(source, jobName)
    local Player = GetPlayer(source)
    return Player and Player.PlayerData.job.name == jobName
end

-- Utility function to check if on duty
local function IsOnDuty(source)
    local Player = GetPlayer(source)
    return Player and Player.PlayerData.job.name == Config.RestaurantJob and Player.PlayerData.job.onduty
end

-- Export utility functions
exports('GetPlayer', GetPlayer)
exports('HasJob', HasJob)
exports('IsOnDuty', IsOnDuty)

-- Version check (optional)
CreateThread(function()
    print(string.format('^2[%s]^7 Resource started successfully', GetCurrentResourceName()))
    if Config.Debug then
        print(string.format('^3[%s]^7 Debug mode is enabled', GetCurrentResourceName()))
    end
end)