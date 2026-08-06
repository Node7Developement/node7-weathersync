local SET_WEATHER_TYPE = 0x59174F1AFE095B5A
local CLEAR_OVERRIDE_WEATHER = 0x80A398F16FFE3CC3
local SET_CLOCK_TIME = 0x3A52C59FFB2DEED8
local PAUSE_CLOCK = 0x4D1A590C92BF377E
local SET_MILLISECONDS_PER_GAME_MINUTE = 0x04EEDB3848DACF68

local syncedState = nil
local receivedAt = 0
local lastAppliedWeather = nil

local function notify(message, notificationType)
    local ok = pcall(function()
        exports['node7-core']:Notify(message, notificationType or 'info', 5000, 'WEATHER')
    end)

    if not ok then
        TriggerEvent('chat:addMessage', {
            args = { 'NODE7 Weather', tostring(message) }
        })
    end
end

local function formatTime(minuteOfDay)
    minuteOfDay = math.floor((tonumber(minuteOfDay) or 0) % 1440)
    local hour = math.floor(minuteOfDay / 60)
    local minute = minuteOfDay % 60
    return ('%02d:%02d'):format(hour, minute)
end

local function currentMinuteOfDay()
    if not syncedState then return 0 end

    local minuteOfDay = tonumber(syncedState.minuteOfDay) or 0
    local millisecondsPerGameMinute = tonumber(syncedState.millisecondsPerGameMinute)
        or Config.DefaultMillisecondsPerGameMinute

    if millisecondsPerGameMinute < 1 then
        millisecondsPerGameMinute = Config.DefaultMillisecondsPerGameMinute
    end

    if syncedState.timeFrozen then
        return minuteOfDay % 1440
    end

    local elapsed = GetGameTimer() - receivedAt
    return (minuteOfDay + (elapsed / millisecondsPerGameMinute)) % 1440
end

local function applyWeather(force)
    if not syncedState then return end

    local weather = Node7WeatherByName[syncedState.weather]
    if not weather then return end

    if force or lastAppliedWeather ~= weather.name then
        Citizen.InvokeNative(CLEAR_OVERRIDE_WEATHER)
        Citizen.InvokeNative(
            SET_WEATHER_TYPE,
            weather.hash,
            true,
            true,
            true,
            tonumber(syncedState.transitionSeconds) or 0.0,
            false
        )
        lastAppliedWeather = weather.name
    else
        Citizen.InvokeNative(
            SET_WEATHER_TYPE,
            weather.hash,
            true,
            true,
            false,
            0.0,
            false
        )
    end
end

local function applyClock()
    if not syncedState then return end

    local minuteOfDay = currentMinuteOfDay()
    local hour = math.floor(minuteOfDay / 60)
    local minute = math.floor(minuteOfDay % 60)

    Citizen.InvokeNative(PAUSE_CLOCK, true, 0)
    Citizen.InvokeNative(
        SET_MILLISECONDS_PER_GAME_MINUTE,
        math.floor(tonumber(syncedState.millisecondsPerGameMinute) or Config.DefaultMillisecondsPerGameMinute)
    )
    Citizen.InvokeNative(SET_CLOCK_TIME, hour, minute, 0)
end

local function showInput(data)
    if GetResourceState('node7-input') ~= 'started' then
        notify('node7-input is not started.', 'error')
        return nil
    end

    local ok, result = pcall(function()
        return exports['node7-input']:ShowInput(data)
    end)

    if not ok then
        notify('The NODE7 input form could not be opened.', 'error')
        return nil
    end

    return result
end

local function openWeatherMenu(stateOverride)
    if stateOverride then
        syncedState = stateOverride
        receivedAt = GetGameTimer()
    end

    if not syncedState then
        TriggerServerEvent('node7-weathersync:server:requestSync')
        notify('Weather state is still loading.', 'info')
        return
    end

    if GetResourceState('node7-menu') ~= 'started' then
        notify('node7-menu is not started.', 'error')
        return
    end

    local weatherItems = {}
    for index = 1, #Node7WeatherTypes do
        local weather = Node7WeatherTypes[index]
        weatherItems[#weatherItems + 1] = {
            header = weather.label,
            txt = weather.name,
            checked = syncedState.weather == weather.name,
            keepOpen = false,
            params = {
                event = 'node7-weathersync:client:chooseWeather',
                args = { weather = weather.name }
            }
        }
    end

    local timeItems = {}
    for index = 1, #Config.TimePresets do
        local preset = Config.TimePresets[index]
        timeItems[#timeItems + 1] = {
            header = preset.label,
            txt = ('Set time to %02d:%02d'):format(preset.hour, preset.minute),
            params = {
                event = 'node7-weathersync:client:chooseTimePreset',
                args = { hour = preset.hour, minute = preset.minute }
            }
        }
    end

    timeItems[#timeItems + 1] = {
        header = 'Custom Time',
        txt = 'Enter an exact hour and minute with NODE7 Input.',
        params = { event = 'node7-weathersync:client:openTimeInput' }
    }

    timeItems[#timeItems + 1] = {
        header = syncedState.timeFrozen and 'Resume Time' or 'Pause Time',
        txt = syncedState.timeFrozen and 'Allow the synchronized clock to advance.' or 'Keep the synchronized clock at its current time.',
        variant = syncedState.timeFrozen and 'success' or 'warning',
        params = { event = 'node7-weathersync:client:toggleTimeFreeze' }
    }

    local settingsItems = {
        {
            header = 'Weather Transition',
            txt = ('Current: %d seconds'):format(syncedState.transitionSeconds),
            rightLabel = ('%ds'):format(syncedState.transitionSeconds),
            params = { event = 'node7-weathersync:client:openTransitionInput' }
        },
        {
            header = 'Time Speed',
            txt = ('Current: %d milliseconds per game minute'):format(syncedState.millisecondsPerGameMinute),
            rightLabel = tostring(syncedState.millisecondsPerGameMinute),
            params = { event = 'node7-weathersync:client:openTimeScaleInput' }
        }
    }

    local currentWeather = Node7WeatherByName[syncedState.weather] or Node7WeatherByName[Config.DefaultWeather]

    exports['node7-menu']:openMenu({
        title = 'NODE7 Weather Control',
        subtitle = ('%s • %s'):format(currentWeather.label, formatTime(currentMinuteOfDay())),
        categories = {
            { label = 'Weather', items = weatherItems },
            { label = 'Time', items = timeItems },
            { label = 'Settings', items = settingsItems }
        }
    })
end

RegisterNetEvent('node7-weathersync:client:sync', function(newState)
    if type(newState) ~= 'table' then return end

    local weatherName = tostring(newState.weather or ''):upper()
    if not Node7WeatherByName[weatherName] then
        weatherName = Config.DefaultWeather
    end

    newState.weather = weatherName
    newState.transitionSeconds = tonumber(newState.transitionSeconds) or Config.DefaultTransitionSeconds
    newState.minuteOfDay = tonumber(newState.minuteOfDay) or ((Config.DefaultHour * 60) + Config.DefaultMinute)
    newState.millisecondsPerGameMinute = tonumber(newState.millisecondsPerGameMinute)
        or Config.DefaultMillisecondsPerGameMinute
    newState.timeFrozen = newState.timeFrozen == true

    local weatherChanged = lastAppliedWeather ~= weatherName
    syncedState = newState
    receivedAt = GetGameTimer()

    if weatherChanged then
        applyWeather(true)
    end

    applyClock()
end)

RegisterNetEvent('node7-weathersync:client:openMenu', function(serverState)
    openWeatherMenu(serverState)
end)

RegisterNetEvent('node7-weathersync:client:chooseWeather', function(args)
    if type(args) ~= 'table' or not args.weather then return end
    TriggerServerEvent('node7-weathersync:server:setWeather', args.weather)
end)

RegisterNetEvent('node7-weathersync:client:chooseTimePreset', function(args)
    if type(args) ~= 'table' then return end
    TriggerServerEvent('node7-weathersync:server:setTime', args.hour, args.minute)
end)

RegisterNetEvent('node7-weathersync:client:openTimeInput', function()
    local minuteOfDay = currentMinuteOfDay()
    local result = showInput({
        header = 'Set Server Time',
        submitText = 'Set Time',
        requireCategoryReview = false,
        showPageNavigation = false,
        inputs = {
            {
                type = 'number',
                text = 'Hour',
                name = 'hour',
                default = math.floor(minuteOfDay / 60),
                min = 0,
                max = 23,
                step = 1,
                isRequired = true
            },
            {
                type = 'number',
                text = 'Minute',
                name = 'minute',
                default = math.floor(minuteOfDay % 60),
                min = 0,
                max = 59,
                step = 1,
                isRequired = true
            }
        }
    })

    if not result then return end
    TriggerServerEvent('node7-weathersync:server:setTime', result.hour, result.minute)
end)

RegisterNetEvent('node7-weathersync:client:openTransitionInput', function()
    local result = showInput({
        header = 'Weather Transition',
        submitText = 'Save',
        requireCategoryReview = false,
        showPageNavigation = false,
        inputs = {
            {
                type = 'number',
                text = 'Transition duration in seconds',
                name = 'seconds',
                default = syncedState and syncedState.transitionSeconds or Config.DefaultTransitionSeconds,
                min = Config.MinimumTransitionSeconds,
                max = Config.MaximumTransitionSeconds,
                step = 1,
                isRequired = true
            }
        }
    })

    if not result then return end
    TriggerServerEvent('node7-weathersync:server:setTransition', result.seconds)
end)

RegisterNetEvent('node7-weathersync:client:openTimeScaleInput', function()
    local result = showInput({
        header = 'Time Speed',
        submitText = 'Save',
        requireCategoryReview = false,
        showPageNavigation = false,
        inputs = {
            {
                type = 'number',
                text = 'Real milliseconds per game minute',
                name = 'milliseconds',
                description = 'Lower values make the in-game clock move faster.',
                default = syncedState and syncedState.millisecondsPerGameMinute or Config.DefaultMillisecondsPerGameMinute,
                min = Config.MinimumMillisecondsPerGameMinute,
                max = Config.MaximumMillisecondsPerGameMinute,
                step = 250,
                isRequired = true
            }
        }
    })

    if not result then return end
    TriggerServerEvent('node7-weathersync:server:setTimeScale', result.milliseconds)
end)

RegisterNetEvent('node7-weathersync:client:toggleTimeFreeze', function()
    TriggerServerEvent('node7-weathersync:server:toggleTimeFreeze')
end)

AddEventHandler('Node7Core:Client:OnPlayerLoaded', function()
    Wait(1000)
    TriggerServerEvent('node7-weathersync:server:requestSync')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Wait(1000)
    TriggerServerEvent('node7-weathersync:server:requestSync')
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Citizen.InvokeNative(PAUSE_CLOCK, false, 0)
    Citizen.InvokeNative(CLEAR_OVERRIDE_WEATHER)
end)

CreateThread(function()
    while true do
        if syncedState then
            applyClock()
            Wait(Config.ClientClockUpdateMs)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.WeatherReapplyIntervalMs)
        if syncedState then
            applyWeather(false)
        end
    end
end)
