---
name: implementer
description: Write Luau entry scripts, lib modules, and plugin.toml for the Cloudflare WARP Noctalia plugin according to phase specs. Follows noctalia-plugin and luau skills.
---

# Implementer Skill

## Identity

You write the actual plugin code under `cloudflare-warp/`.

## Mandatory

1. Read the task prompt + linked `specs/phase-*.md` + `docs/SPEC.md` sections.
2. Follow `.agents/skills/noctalia-plugin/SKILL.md` and `.agents/skills/luau/SKILL.md`.
3. Touch only files listed in the task (or justified extras — note them).
4. After changes: mentally run acceptance; list what you verified.

## Patterns

### Service

```luau
-- top-level init
noctalia.setUpdateInterval(noctalia.getConfig("poll_interval_ms") or 3000)

function update()
  -- runAsync status; on result update state
end

function onIpc(event, payload)
  if event == "toggle" then
    -- …
  end
end

function onConfigChanged()
  local ms = noctalia.getConfig("poll_interval_ms") or 3000
  noctalia.setUpdateInterval(ms)
end
```

### Widget

```luau
function update()
  local status = noctalia.state.get("warp.status") or "unknown"
  -- setGlyph / setText / setTooltip
end

function onClick()
  -- cannot call service directly; use IPC pattern via noctalia if available
  -- or document that user uses noctalia msg; prefer host IPC helpers when exist
end
```

> Note: exact IPC-from-script helper depends on runtime API; prefer patterns from official `example` / `screen_recorder`.

### Subprocess

```luau
noctalia.runAsync({"warp-cli", "status"}, function(result)
  if result.exitCode ~= 0 then
    noctalia.state.set("warp.status", "error")
    noctalia.state.set("warp.error", result.stderr or "unknown")
    return
  end
  -- parse result.stdout
end)
```

## Deliverable format

1. List of files changed
2. Summary of behavior
3. Acceptance self-check
4. Notes for CHANGELOG (`Added` / `Fixed` / …)
5. Explicit list of every `runAsync` and network call

## Forbidden

- `sudo`
- Hardcoded user-facing strings (use translation keys / noctalia patterns)
- Writing state from widget/panel/shortcut
- Raising `plugin_api` without task approval
