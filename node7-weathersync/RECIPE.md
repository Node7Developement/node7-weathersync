# NODE7 Recipe Integration

This resource is packaged for the NODE7 framework and its txAdmin recipe.

## GitHub repository layout

Upload the complete `node7-weathersync` folder to the repository so the repository contains:

```text
node7-weathersync/
  fxmanifest.lua
  config.lua
  permissions.cfg
  client/
  server/
  shared/
  recipe/
```

## Main txAdmin recipe

Add the task from:

```text
recipe/txadmin-download-task.yaml
```

The task installs the resource to:

```text
./resources/[node7]/node7-weathersync
```

## Main permissions file

Add this line to the main NODE7 recipe `permissions.cfg`:

```cfg
exec @node7-weathersync/permissions.cfg
```

The resource permission file grants `/weatherui` access to the existing NODE7 admin, owner, and standard txAdmin admin groups.

## Main server configuration

Start the resource after its NODE7 UI dependencies:

```cfg
ensure node7-core
ensure node7-menu
ensure node7-input
ensure node7-weathersync
```

No SQL import is required. Run only one weather/time synchronization resource.
