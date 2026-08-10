[README.md](https://github.com/user-attachments/files/30882868/README.md)
[README.md](https://github.com/user-attachments/files/30769410/README.md)
# node7-weathersync


<img width="1313" height="946" alt="weathersync" src="https://github.com/user-attachments/assets/8561a935-6c01-40f8-9b8d-c64af5622840" />

Server-authoritative RedM weather and time synchronization built for the NODE7 Framework and NODE7 txAdmin recipe.

## Features

- `/weatherui` opens the existing keyboard-controlled `node7-menu` interface.
- All supported multiplayer RedM weather types.
- Exact time, weather transition duration, and time speed forms through `node7-input`.
- Dawn, morning, noon, evening, and midnight time presets.
- Pause and resume synchronized server time.
- Server-side ACE validation for the command and every state-changing event.
- Late-join synchronization and periodic authoritative state correction.# node7-weathersync

Server-authoritative RedM weather and time synchronization built for the NODE7 Framework and NODE7 txAdmin recipe.

## Features

- `/weatherui` opens the existing keyboard-controlled `node7-menu` interface.
- All supported multiplayer RedM weather types.
- Exact time, weather transition duration, and time speed forms through `node7-input`.
- Dawn, morning, noon, evening, and midnight time presets.
- Pause and resume synchronized server time.
- Server-side ACE validation for the command and every state-changing event.
- Late-join synchronization and periodic authoritative state correction.
- Resource KVP persistence without SQL.
- Optimized client clock updates and weather reapplication.

## Dependencies

- `node7-core`
- `node7-menu`
- `node7-input`

## NODE7 recipe installation

The complete recipe integration is included in the `recipe` folder.

Add to the main recipe permissions file:

```cfg
exec @node7-weathersync/permissions.cfg
```

Start after the menu and input resources:

```cfg
ensure node7-core
ensure node7-menu
ensure node7-input
ensure node7-weathersync
```

The included master txAdmin download task installs the GitHub resource into:

```text
./resources/[node7]/node7-weathersync
```

## Permission

```text
node7.weathersync.admin
```

Granted by default to:

- `group.node7_admin`
- `group.node7_owner`
- `group.admin`

## Configuration

Edit `config.lua` to change default weather, default time, transition limits, clock speed limits, synchronization intervals, and KVP persistence.

No SQL is required. Disable every other weather or time synchronization resource before starting this one.

## Time preset behavior

- Dawn: 06:00
- Morning: 09:00
- Noon: 12:00
- Evening: 20:00
- Midnight: 00:00
- Time changes use RedM multiplayer `NETWORK_OVERRIDE_CLOCK_TIME`, so presets and custom input change the actual network world time and lighting for connected players.


## Optimization

- Time changes are event-driven; there is no fast client clock polling loop.
- RedM advances the synchronized clock natively using the configured milliseconds-per-game-minute value.
- The server only performs a lightweight drift correction every 5 minutes and immediately syncs after admin changes or player load.
- Fractional minutes are converted to seconds during corrections to avoid visible backward clock stepping.

- Resource KVP persistence without SQL.
- Optimized client clock updates and weather reapplication.

## Dependencies

- `node7-core`
- `node7-menu`
- `node7-input`

## NODE7 recipe installation

The complete recipe integration is included in the `recipe` folder.

Add to the main recipe permissions file:

```cfg
exec @node7-weathersync/permissions.cfg
```

Start after the menu and input resources:

```cfg
ensure node7-core
ensure node7-menu
ensure node7-input
ensure node7-weathersync
```

The included master txAdmin download task installs the GitHub resource into:

```text
./resources/[node7]/node7-weathersync
```

## Permission

```text
node7.weathersync.admin
```

Granted by default to:

- `group.node7_admin`
- `group.node7_owner`
- `group.admin`

## Configuration

Edit `config.lua` to change default weather, default time, transition limits, clock speed limits, synchronization intervals, and KVP persistence.

No SQL is required. Disable every other weather or time synchronization resource before starting this one.
