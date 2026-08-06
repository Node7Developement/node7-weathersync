# node7-weathersync

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
