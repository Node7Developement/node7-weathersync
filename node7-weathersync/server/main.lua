local RESOURCE = GetCurrentResourceName()
local requestCooldown = {}
local syncRequestCooldown = {}
local lastClockTick = GetGameTimer()

local state = {
    weather = Config.DefaultWeather,
    transitionSeconds = Config.DefaultTransitionSeconds,
    minuteOfDay = (Config.DefaultHour * 60) + Config.DefaultMinute,
    millisecondsPerGameMinute = Config.DefaultMillisecondsPerGameMinute,
    timeFrozen = Config.DefaultTimeFrozen
}

local function clamp(value, minimum, maximum)
    value = tonumber(value)
    if not value then return nil end
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function normalizedMinuteOfDay(value)
    value = tonumber(value) or 0
    value = value % 1440
    if value < 0 then value = value + 1440 end
    return value
end

local function updateClock()
    local now = GetGameTimer()
    local elapsed = now - lastClockTick
    lastClockTick = now

    if not state.timeFrozen and elapsed > 0 then
        state.minuteOfDay = normalizedMinuteOfDay(
            state.minuteOfDay + (elapsed / state.millisecondsPerGameMinute)
        )
    end
end

local function snapshot()
    updateClock()
    return {
        weather = state.weather,
        transitionSeconds = state.transitionSeconds,
        minuteOfDay = state.minuteOfDay,
        millisecondsPerGameMinute = state.millisecondsPerGameMinute,
        timeFrozen = state.timeFrozen
    }
end

local function notify(source, message, notificationType)
    if source <= 0 then return end

    local ok = pcall(function()
        exports['node7-core']:Notify(source, message, notificationType or 'info', 5000, 'WEATHER')
    end)

    if not ok then
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'NODE7 Weather', tostring(message) }
        })
    end
end

local function hasAccess(source)
    return source == 0 or IsPlayerAceAllowed(source, Config.AcePermission)
end

local function throttled(source)
    if source <= 0 then return false end

    local now = GetGameTimer()
    local last = requestCooldown[source] or 0
    if now - last < Config.RequestCooldownMs then
        return true
    end

    requestCooldown[source] = now
    return false
end

local function persistState()
    if not Config.PersistState then return end

    local encoded = json.encode(snapshot())
    if encoded then
        SetResourceKvp(Config.KvpKey, encoded)
    end
end

local function loadState()
    if not Config.PersistState then return end

    local raw = GetResourceKvpString(Config.KvpKey)
    if not raw or raw == '' then return end

    local ok, saved = pcall(json.decode, raw)
    if not ok or type(saved) ~= 'table' then return end

    if Node7WeatherByName[tostring(saved.weather or ''):upper()] then
        state.weather = tostring(saved.weather):upper()
    end

    state.transitionSeconds = clamp(
        saved.transitionSeconds,
        Config.MinimumTransitionSeconds,
        Config.MaximumTransitionSeconds
    ) or state.transitionSeconds

    state.minuteOfDay = normalizedMinuteOfDay(saved.minuteOfDay or state.minuteOfDay)

    state.millisecondsPerGameMinute = math.floor(clamp(
        saved.millisecondsPerGameMinute,
        Config.MinimumMillisecondsPerGameMinute,
        Config.MaximumMillisecondsPerGameMinute
    ) or state.millisecondsPerGameMinute)

    state.timeFrozen = saved.timeFrozen == true
end

local function broadcastState(target)
    TriggerClientEvent('node7-weathersync:client:sync', target or -1, snapshot())
end

local function validateAdminRequest(source)
    if not hasAccess(source) then
        notify(source, 'You do not have permission to control the weather.', 'error')
        return false
    end

    if throttled(source) then
        return false
    end

    return true
end

RegisterCommand(Config.Command, function(source)
    if source <= 0 then
        return
    end

    if not hasAccess(source) then
        notify(source, 'You do not have permission to use /' .. Config.Command .. '.', 'error')
        return
    end

    TriggerClientEvent('node7-weathersync:client:openMenu', source, snapshot())
end, false)

RegisterNetEvent('node7-weathersync:server:requestSync', function()
    local src = source
    if src <= 0 then return end

    local now = GetGameTimer()
    local lastRequest = syncRequestCooldown[src] or 0
    if now - lastRequest < Config.SyncRequestCooldownMs then return end

    syncRequestCooldown[src] = now
    broadcastState(src)
end)

RegisterNetEvent('node7-weathersync:server:setWeather', function(weatherName)
    local src = source
    if not validateAdminRequest(src) then return end

    weatherName = tostring(weatherName or ''):upper()
    if not Node7WeatherByName[weatherName] then
        notify(src, 'That weather type is not supported.', 'error')
        return
    end

    state.weather = weatherName
    persistState()
    broadcastState(-1)
    notify(src, ('Weather changed to %s.'):format(Node7WeatherByName[weatherName].label), 'success')
end)

RegisterNetEvent('node7-weathersync:server:setTime', function(hour, minute)
    local src = source
    if not validateAdminRequest(src) then return end

    hour = tonumber(hour)
    minute = tonumber(minute)

    if not hour or not minute or hour % 1 ~= 0 or minute % 1 ~= 0
        or hour < 0 or hour > 23 or minute < 0 or minute > 59 then
        notify(src, 'Enter a valid time from 00:00 through 23:59.', 'error')
        return
    end

    updateClock()
    state.minuteOfDay = (hour * 60) + minute
    lastClockTick = GetGameTimer()
    persistState()
    broadcastState(-1)
    notify(src, ('Time changed to %02d:%02d.'):format(hour, minute), 'success')
end)

RegisterNetEvent('node7-weathersync:server:setTransition', function(seconds)
    local src = source
    if not validateAdminRequest(src) then return end

    seconds = clamp(seconds, Config.MinimumTransitionSeconds, Config.MaximumTransitionSeconds)
    if not seconds then
        notify(src, 'Enter a valid transition duration.', 'error')
        return
    end

    state.transitionSeconds = math.floor(seconds)
    persistState()
    broadcastState(-1)
    notify(src, ('Weather transition set to %d seconds.'):format(state.transitionSeconds), 'success')
end)

RegisterNetEvent('node7-weathersync:server:setTimeScale', function(milliseconds)
    local src = source
    if not validateAdminRequest(src) then return end

    milliseconds = clamp(
        milliseconds,
        Config.MinimumMillisecondsPerGameMinute,
        Config.MaximumMillisecondsPerGameMinute
    )

    if not milliseconds then
        notify(src, 'Enter a valid time speed.', 'error')
        return
    end

    updateClock()
    state.millisecondsPerGameMinute = math.floor(milliseconds)
    lastClockTick = GetGameTimer()
    persistState()
    broadcastState(-1)
    notify(src, ('Time speed set to %d ms per game minute.'):format(state.millisecondsPerGameMinute), 'success')
end)

RegisterNetEvent('node7-weathersync:server:toggleTimeFreeze', function()
    local src = source
    if not validateAdminRequest(src) then return end

    updateClock()
    state.timeFrozen = not state.timeFrozen
    lastClockTick = GetGameTimer()
    persistState()
    broadcastState(-1)
    notify(src, state.timeFrozen and 'Time paused.' or 'Time resumed.', 'success')
end)

AddEventHandler('playerDropped', function()
    requestCooldown[source] = nil
    syncRequestCooldown[source] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE then return end
    persistState()
end)

loadState()
lastClockTick = GetGameTimer()

CreateThread(function()
    while true do
        Wait(Config.ServerSyncIntervalMs)
        broadcastState(-1)
    end
end)
