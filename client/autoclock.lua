local clockZones = {}
local isInZone = false
local lastToggleTime = 0
local TOGGLE_COOLDOWN = 2000 -- 2 second cooldown between toggles

-- Force refresh player job data
local function RefreshPlayerJob()
    -- QBOX uses a different method to get player data
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData and playerData.job then
        PlayerJob = playerData.job
        if Config.Debug then
            print(('[%s] Refreshed job data: %s, On duty: %s'):format(GetCurrentResourceName(), PlayerJob.name, tostring(PlayerJob.onduty)))
        end
    end
end

-- Function to safely toggle duty with cooldown
local function SafeToggleDuty(action)
    local currentTime = GetGameTimer()
    if currentTime - lastToggleTime < TOGGLE_COOLDOWN then
        if Config.Debug then
            print(('[%s] Toggle duty on cooldown, skipping...'):format(GetCurrentResourceName()))
        end
        return false
    end
    
    lastToggleTime = currentTime
    TriggerServerEvent('eb-template:toggleDuty')
    return true
end

-- Zone callback functions
local function onEnterZone(self)
    if Config.Debug then
        print(('[%s] onEnter callback triggered for zone: %s'):format(GetCurrentResourceName(), self.id))
    end
    
    if not HasRestaurantJob() then return end
    
    isInZone = true
    
    -- Refresh job data to ensure we have the latest
    RefreshPlayerJob()
    
    if Config.Debug then
        print(('[%s] Current duty status after refresh: %s'):format(GetCurrentResourceName(), PlayerJob and tostring(PlayerJob.onduty) or 'nil'))
    end
    
    -- Clock IN when entering (only if off duty)
    if PlayerJob and not PlayerJob.onduty then
        if Config.Debug then
            print(('[%s] Player is OFF duty, clocking IN...'):format(GetCurrentResourceName()))
        end
        SafeToggleDuty('in')
    elseif Config.Debug then
        print(('[%s] Player is already ON duty, skipping clock in'):format(GetCurrentResourceName()))
    end
end

local function onExitZone(self)
    if Config.Debug then
        print(('[%s] onExit callback triggered for zone: %s'):format(GetCurrentResourceName(), self.id))
    end
    
    if not HasRestaurantJob() then return end
    
    isInZone = false
    
    -- Refresh job data to ensure we have the latest
    RefreshPlayerJob()
    
    if Config.Debug then
        print(('[%s] Current duty status after refresh: %s'):format(GetCurrentResourceName(), PlayerJob and tostring(PlayerJob.onduty) or 'nil'))
    end
    
    -- Clock OUT when leaving (only if on duty)
    if PlayerJob and PlayerJob.onduty then
        if Config.Debug then
            print(('[%s] Player is ON duty, clocking OUT...'):format(GetCurrentResourceName()))
        end
        SafeToggleDuty('out')
    elseif Config.Debug then
        print(('[%s] Player is already OFF duty, skipping clock out'):format(GetCurrentResourceName()))
    end
end

-- Create clock zones
CreateThread(function()
    Wait(1000) -- Wait for initialization
    
    for _, zone in ipairs(Config.ClockZones) do
        if zone.autoClockIn and Config.AutoClockIn.enabled then
            local zoneInstance
            
            -- Create polyzone
            if zone.points then
                zoneInstance = lib.zones.poly({
                    points = zone.points,
                    thickness = zone.thickness or 4.0,
                    debug = Config.Debug,
                    onEnter = onEnterZone,
                    onExit = onExitZone
                })
            -- Create box zone
            elseif zone.size then
                zoneInstance = lib.zones.box({
                    coords = zone.coords,
                    size = zone.size,
                    rotation = zone.rotation or 0,
                    debug = Config.Debug,
                    onEnter = onEnterZone,
                    onExit = onExitZone
                })
            -- Create sphere zone
            else
                zoneInstance = lib.zones.sphere({
                    coords = zone.coords,
                    radius = zone.radius or 2.0,
                    debug = Config.Debug,
                    onEnter = onEnterZone,
                    onExit = onExitZone
                })
            end
            
            -- Store zone reference
            zoneInstance.id = zone.id -- Add id to zone for debugging
            clockZones[zone.id] = zoneInstance
            
            if Config.Debug then
                print(('[%s] Created auto clock zone: %s'):format(GetCurrentResourceName(), zone.id))
            end
        end
        
        -- Also create target zones for manual clock in/out
        if zone.manualClock then
            local targetOptions = {
                {
                    name = 'clock_' .. zone.id,
                    label = 'Time Clock',
                    icon = 'fa-solid fa-clock',
                    distance = 2.0,
                    groups = {[Config.RestaurantJob] = 0},
                    onSelect = function()
                        SafeToggleDuty('manual')
                    end
                }
            }
            
            if zone.size then
                exports.ox_target:addBoxZone({
                    coords = zone.coords,
                    size = zone.size,
                    rotation = zone.rotation or 0,
                    debug = Config.Debug,
                    drawSprite = Config.TargetOptions.drawSprite,
                    options = targetOptions
                })
            else
                exports.ox_target:addSphereZone({
                    coords = zone.coords,
                    radius = zone.radius or 1.0,
                    debug = Config.Debug,
                    drawSprite = Config.TargetOptions.drawSprite,
                    options = targetOptions
                })
            end
        end
    end
    
    -- Check if player is already in zone after creating zones
    Wait(1500) -- Longer wait to ensure everything is loaded
    
    if not HasRestaurantJob() then return end
    
    RefreshPlayerJob() -- Refresh before checking
    
    local playerCoords = GetEntityCoords(cache.ped)
    
    -- Check if player is in zone on resource start
    for zoneId, zone in pairs(clockZones) do
        if zone:contains(playerCoords) then
            if Config.Debug then
                print(('[%s] Player is inside zone on resource start'):format(GetCurrentResourceName()))
                print(('[%s] Current duty status: %s'):format(GetCurrentResourceName(), PlayerJob and tostring(PlayerJob.onduty) or 'nil'))
            end
            isInZone = true
            
            -- Only provide information, don't auto-toggle
            if Config.Debug then
                if PlayerJob and PlayerJob.onduty then
                    print(('[%s] Player is in zone and ON duty'):format(GetCurrentResourceName()))
                else
                    print(('[%s] Player is in zone and OFF duty'):format(GetCurrentResourceName()))
                end
            end
            break
        end
    end
    
    if not isInZone and Config.Debug then
        print(('[%s] Player is NOT in zone on resource start'):format(GetCurrentResourceName()))
        if PlayerJob and PlayerJob.onduty then
            print(('[%s] Player is outside zone but ON duty'):format(GetCurrentResourceName()))
        else
            print(('[%s] Player is outside zone and OFF duty'):format(GetCurrentResourceName()))
        end
    end
end)

-- Debug command to check zone status
if Config.Debug then
    RegisterCommand('clockdebug', function()
        RefreshPlayerJob() -- Force refresh before debug
        print('=== CLOCK DEBUG INFO ===')
        print(('[%s] In Zone: %s'):format(GetCurrentResourceName(), tostring(isInZone)))
        print(('[%s] Has Job: %s'):format(GetCurrentResourceName(), tostring(HasRestaurantJob())))
        print(('[%s] Job Name: %s'):format(GetCurrentResourceName(), PlayerJob and PlayerJob.name or 'none'))
        print(('[%s] On Duty: %s'):format(GetCurrentResourceName(), tostring(PlayerJob and PlayerJob.onduty)))
        print(('[%s] Last Toggle: %d ms ago'):format(GetCurrentResourceName(), GetGameTimer() - lastToggleTime))
        
        local playerCoords = GetEntityCoords(cache.ped)
        print(('[%s] Player Coords: %.2f, %.2f, %.2f'):format(GetCurrentResourceName(), playerCoords.x, playerCoords.y, playerCoords.z))
        
        -- Check if currently in zone
        for zoneId, zone in pairs(clockZones) do
            local inZone = zone:contains(playerCoords)
            print(('[%s] Zone %s contains player: %s'):format(GetCurrentResourceName(), zoneId, tostring(inZone)))
        end
        
        -- Check server duty status
        local serverDuty = lib.callback.await('eb-template:getDutyStatus', false)
        print(('[%s] Server duty status: %s'):format(GetCurrentResourceName(), tostring(serverDuty)))
        
        print('=======================')
    end, false)
    
    -- Force clock in command for testing
    RegisterCommand('forceclockin', function()
        if HasRestaurantJob() then
            print(('[%s] Force triggering clock in'):format(GetCurrentResourceName()))
            SafeToggleDuty('in')
        end
    end, false)
    
    -- Force clock out command for testing
    RegisterCommand('forceclockout', function()
        if HasRestaurantJob() then
            print(('[%s] Force triggering clock out'):format(GetCurrentResourceName()))
            SafeToggleDuty('out')
        end
    end, false)
    
    -- Refresh job data command
    RegisterCommand('refreshjob', function()
        RefreshPlayerJob()
        print(('[%s] Job data refreshed'):format(GetCurrentResourceName()))
    end, false)
    
    -- Monitor duty changes
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        if Config.Debug then
            print(('[%s] Job update event received: %s, On duty: %s'):format(GetCurrentResourceName(), job.name, tostring(job.onduty)))
        end
        -- Update our cached job data
        PlayerJob = job
    end)
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Don't automatically clock out on resource stop
        if Config.Debug then
            print(('[%s] Resource stopping, zones will be cleaned up'):format(GetCurrentResourceName()))
        end
        -- Zones are automatically cleaned up by ox_lib
        clockZones = {}
    end
end)