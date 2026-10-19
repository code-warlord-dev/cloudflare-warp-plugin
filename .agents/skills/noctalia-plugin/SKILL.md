---
name: noctalia-plugin
description: Domain knowledge for Noctalia 5.x Luau plugins — manifest, entries, state, IPC, declarative UI, runtime API. Required for implementer, architect, and reviewer on this project.
---

# Noctalia Plugin Skill

## Core facts

- Plugin = directory with `plugin.toml` + `.luau` entries
- Entries run in **isolated Luau VMs**, off UI thread, time-budgeted
- Trusted code: treat as user scripts
- Hot-reload: `.luau` on save; manifest on config reload
- `plugin_api` = oldest required API level (cumulative). Prefer lowest needed.

## Entry kinds

| Table | Kind | UI | Lifecycle highlights |
|-------|------|-----|----------------------|
| `[[service]]` | headless | no | `update`, `onIpc`, `onConfigChanged`, `onEnable`, `onExit` |
| `[[widget]]` | bar | barWidget.* or render | `update`, clicks, scroll, `onIpc` |
| `[[shortcut]]` | control center | tile | click, `onIpc` |
| `[[panel]]` | popup | panel.render(ui.*) | `onOpen`, `onClose`, `update` |
| `[[desktop_widget]]` | desktop | desktopWidget.render | |
| `[[launcher_provider]]` | launcher | onQuery/onActivate | |

Address: `author/plugin:entry-id`  
Service IPC target: **`all`**

## State

```luau
noctalia.state.set("key", value)
noctalia.state.get("key")
-- process-lifetime; survives service restart
```

## Config

```luau
noctalia.getConfig("setting_key")  -- only declared keys
```

## Subprocess

```luau
noctalia.runAsync(cmdOrArgv, function(result) end)
-- result: stdout, stderr, exitCode (per runtime API)
noctalia.runAsync(cmd) -- fire-and-forget
```

## UI

- Imperative bar: `barWidget.setGlyph`, `setText`, `setTooltip`, …
- Declarative: `ui.column`, `ui.row`, `ui.button`, `ui.select`, `ui.toggle`, …
- Colors: palette roles (`primary`, `on_surface`, `success`…) preferred

## IPC testing

```bash
noctalia msg plugin author/plugin:entry target event [payload]
noctalia msg panel-toggle author/plugin:panel
```

## Official references

- https://docs.noctalia.dev/noctalia/plugins/development/
- official-plugins: `example`, `screen_recorder`
- community-plugins contribution rules: one plugin per PR, account for network/process

## This project specifics

- id: `community/cloudflare-warp`
- service owns all `warp.*` keys
- dependency metadata: `cloudflare-warp`
- start `plugin_api = 17`
