Config = {}

Config.Command = 'weatherui'
Config.AcePermission = 'node7.weathersync.admin'

Config.DefaultWeather = 'SUNNY'
Config.DefaultTransitionSeconds = 10
Config.DefaultHour = 12
Config.DefaultMinute = 0
Config.DefaultMillisecondsPerGameMinute = 2000
Config.DefaultTimeFrozen = false

Config.MinimumTransitionSeconds = 0
Config.MaximumTransitionSeconds = 120
Config.MinimumMillisecondsPerGameMinute = 250
Config.MaximumMillisecondsPerGameMinute = 60000

Config.ServerSyncIntervalMs = 10000
Config.ClientClockUpdateMs = 500
Config.WeatherReapplyIntervalMs = 60000
Config.RequestCooldownMs = 500
Config.SyncRequestCooldownMs = 1000
Config.PersistState = true
Config.KvpKey = 'node7-weathersync:state'

Config.TimePresets = {
    { label = 'Dawn', hour = 6, minute = 0 },
    { label = 'Morning', hour = 9, minute = 0 },
    { label = 'Noon', hour = 12, minute = 0 },
    { label = 'Evening', hour = 18, minute = 0 },
    { label = 'Midnight', hour = 0, minute = 0 }
}
