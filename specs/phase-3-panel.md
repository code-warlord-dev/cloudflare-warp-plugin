# Phase 3 — Panel

**Target version:** `0.4.0` (MINOR)  
**Goal:** Полноценная declarative-панель управления WARP.

## Non-goals

- WARP+ license purchase flow
- Cloudflare Zero Trust org switcher

## Dependencies

Phase 1–2 (state + cmd queue or IPC).

## State / IPC

Uses existing keys + `warp.cmd` values:

- `set-mode:<mode>`
- `set-families:<value>`
- `set-protocol:<value>`
- `register`
- `refresh`

Or structured: `warp.cmd` = event name, `warp.cmd_payload` = payload string.  
**Prefer:** two keys `warp.cmd` + `warp.cmd_payload` for clarity.

## UI structure

```
ui.column
  ├─ header row: status label + Connect/Disconnect button
  ├─ status card: mode, families, protocol, ip, loc, last_update
  ├─ ui.select Mode
  ├─ ui.select Families
  ├─ ui.select Protocol
  ├─ actions row: Refresh | Register | Copy IP | Settings
  └─ footer: hint text
```

- Width ~380 logical px
- Floating panel
- `onOpen`: optional refresh cmd

## Files

| File | Action |
|------|--------|
| `panel.luau` | full declarative UI |
| `service.luau` | ensure setters for mode/families/protocol/register |
| `translations/*` | panel.* keys |

## Tasks

1. Service: implement set-mode / set-families / set-protocol / register via commands.luau
2. Panel layout + bindings
3. Copy IP via `noctalia.copyToClipboard`
4. Open settings via `noctalia.openSettings()` if API 15+

## Acceptance criteria

- [ ] Panel opens via IPC `panel-toggle` and via widget right-click
- [ ] Connect/Disconnect works from panel
- [ ] Changing mode in select updates system mode (verify `warp-cli settings` or status)
- [ ] Families and protocol selectors work when supported by installed client
- [ ] Copy IP works when trace.ip present
- [ ] Register shown/enabled when status=unregistered
- [ ] version 0.4.0 + CHANGELOG

## Risks

| Risk | Mitigation |
|------|------------|
| Mode names differ by client version | tolerant list; show current from state |
| Protocol change drops connectivity | notify user; still allow |

## Version bump

`0.3.0` → `0.4.0`
