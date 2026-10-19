---
name: luau
description: Luau coding conventions for Noctalia plugins — modules, style, error handling, no-stdlib assumptions.
---

# Luau Skill (Noctalia plugins)

## Language

- Luau (typed subset of Lua 5.1 + extensions)
- Prefer clear imperative style over clever metatables
- Modules (`plugin_api >= 22`): `local x = require("./lib/foo.luau")` — path must start with `./` or `../` and end in `.luau`

## Style

```luau
-- good
local function parseStatus(stdout: string): string
  if string.find(stdout, "Connected", 1, true) then
    return "connected"
  end
  return "unknown"
end
```

- Local functions by default
- Explicit returns
- Avoid global mutable state except entry lifecycle globals required by host

## Errors

- Never `error()` for expected failures (missing binary, disconnected) — set state + optional notify
- Reserve hard errors for programmer mistakes

## Async

- All `warp-cli` via `noctalia.runAsync`
- Do not nest unbounded async chains without guarding in-flight flags

```luau
local busy = false
local function refresh()
  if busy then return end
  busy = true
  noctalia.runAsync({"warp-cli", "status"}, function(result)
    busy = false
    -- …
  end)
end
```

## Types

- Use type annotations where they clarify public lib APIs
- Do not fight the sandbox — only host-provided globals (`noctalia`, `ui`, `barWidget`, …)
