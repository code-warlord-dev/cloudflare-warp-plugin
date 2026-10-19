# Phase 1 — Service Core

**Target version:** `0.2.0` (MINOR)  
**Goal:** Service — единственный источник правды; IPC управляет connect/disconnect; state публикуется.

## Non-goals

- Полный panel UI
- Families/protocol UI (можно поддержать IPC setters, UI — Phase 3)
- Desktop widget

## Dependencies

Phase 0 complete.

## State schema (writers: service only)

| Key | Type | Values |
|-----|------|--------|
| `warp.status` | string | `connected` \| `disconnected` \| `connecting` \| `unregistered` \| `error` \| `unknown` |
| `warp.mode` | string | e.g. `warp`, `doh`, `warp+doh`, `proxy`, … |
| `warp.families` | string | `off` \| `malware` \| `full` |
| `warp.protocol` | string | `WireGuard` \| `MASQUE` \| `unknown` |
| `warp.error` | string | empty if ok |
| `warp.last_update` | number | `noctalia.nowMs()` |
| `warp.daemon_ok` | bool | CLI responded |
| `warp.trace.warp` | string | optional |
| `warp.trace.ip` | string | optional |
| `warp.trace.loc` | string | optional |

## IPC contract

Target: `community/cloudflare-warp:service` + `all`

| Event | Payload | Behavior |
|-------|---------|----------|
| `refresh` | — | force status (+ optional trace) |
| `connect` | — | `warp-cli connect` then refresh |
| `disconnect` | — | `warp-cli disconnect` then refresh |
| `toggle` | — | connect if not connected, else disconnect |
| `set-mode` | mode string | `warp-cli mode <mode>` then refresh |
| `set-families` | off/malware/full | then refresh |
| `set-protocol` | WireGuard/MASQUE | then refresh |
| `register` | — | `warp-cli registration new` then refresh |

## Settings used

- `poll_interval_ms` → `setUpdateInterval`
- `notify_on_change` → notify on connected/disconnected transition
- `notify_on_error` → notifyError on error status
- `auto_trace`, `trace_interval_s` → periodic curl trace

## Files

| File | Action |
|------|--------|
| `lib/parse.luau` | Implement parseStatus(stdout) → status enum; parseSettings optional |
| `lib/commands.luau` | runAsync wrappers |
| `lib/state.luau` | setStatus helpers |
| `service.luau` | Full loop + onIpc + onConfigChanged |

## Tasks

1. parse.luau unit-style pure functions
2. commands.luau wrappers with in-flight guard
3. service update() poll loop
4. onIpc handlers
5. notifications
6. trace optional path
7. error paths (binary missing, non-zero exit)

## Acceptance criteria

- [ ] Poll updates `warp.status` at configured interval
- [ ] `… all toggle` flips connection when daemon healthy
- [ ] `… all refresh` updates `warp.last_update`
- [ ] Missing `warp-cli` → `status=error`, `daemon_ok=false`, no shell crash
- [ ] Status transition connected↔disconnected fires notify if setting true
- [ ] `onConfigChanged` applies new poll interval
- [ ] CHANGELOG 0.2.0 lists Added service core
- [ ] Network/process list documented in PR

## Risks

| Risk | Mitigation |
|------|------------|
| CLI output format drift | substring match; fallback unknown |
| Concurrent runAsync | busy flag |
| Trace blocks | separate longer interval; never block status poll |

## Version bump

`0.1.0` → `0.2.0`
