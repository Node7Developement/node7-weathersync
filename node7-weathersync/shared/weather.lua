Node7WeatherTypes = {
    { name = 'BLIZZARD',       label = 'Blizzard',        hash = 0x27EA2814 },
    { name = 'CLOUDS',         label = 'Clouds',          hash = 0x30FDAF5C },
    { name = 'DRIZZLE',        label = 'Drizzle',         hash = 0x995C7F44 },
    { name = 'FOG',            label = 'Fog',             hash = 0xD61BDE01 },
    { name = 'GROUNDBLIZZARD', label = 'Ground Blizzard', hash = 0x7F622122 },
    { name = 'HAIL',           label = 'Hail',            hash = 0x75A9E268 },
    { name = 'HIGHPRESSURE',   label = 'High Pressure',   hash = 0xF5A87B65 },
    { name = 'HURRICANE',      label = 'Hurricane',       hash = 0x320D0951 },
    { name = 'MISTY',          label = 'Misty',           hash = 0x5974E8E5 },
    { name = 'OVERCAST',       label = 'Overcast',        hash = 0xBB898D2D },
    { name = 'OVERCASTDARK',   label = 'Dark Overcast',   hash = 0x19D4F1D9 },
    { name = 'RAIN',           label = 'Rain',            hash = 0x54A69840 },
    { name = 'SANDSTORM',      label = 'Sandstorm',       hash = 0xB17F6111 },
    { name = 'SHOWER',         label = 'Shower',          hash = 0xE72679D5 },
    { name = 'SLEET',          label = 'Sleet',           hash = 0x0CA71D7C },
    { name = 'SNOW',           label = 'Snow',            hash = 0xEFB6EFF6 },
    { name = 'SNOWLIGHT',      label = 'Light Snow',      hash = 0x23FB812B },
    { name = 'SUNNY',          label = 'Sunny',           hash = 0x614A1F91 },
    { name = 'THUNDER',        label = 'Thunder',         hash = 0xB677829F },
    { name = 'THUNDERSTORM',   label = 'Thunderstorm',    hash = 0x7C1C4A13 },
    { name = 'WHITEOUT',       label = 'Whiteout',        hash = 0x2B402288 }
}

Node7WeatherByName = {}
for index = 1, #Node7WeatherTypes do
    local weather = Node7WeatherTypes[index]
    Node7WeatherByName[weather.name] = weather
end
