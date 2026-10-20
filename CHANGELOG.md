# Changelog

All notable changes to the **Cloudflare WARP** Noctalia plugin are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [SemVer](https://semver.org/) — see [VERSIONING.md](./VERSIONING.md).

---

## [Unreleased]

### Added
### Changed
### Fixed
### Removed

---

## [0.2.0] - 2026-10-19

### Added
- Phase 1 service core: the service is now the single source of truth for WARP state.
  - Polls `warp-cli` via argv-only `noctalia.runAsync({...}, cb, timeoutMs)` (no shell
    strings): `status` every tick, `settings list` every 5th, `registration show` every
    10th, `version` once at start. Per-command in-flight guards.
  - Publishes one `warp.status` table through `noctalia.state.set`, only when a
    fingerprint of meaningful fields changes. Families is write-only: forced to
    `unknown` at service init, set to the mode only after a successful
    `dns families <MODE>`.
  - Consumes `warp.command` (via `noctalia.state.watch`, deduped by `seq`) and IPC
    (`onIpc`) into one `dispatch(action, fields, source)` handler with a shared
    action/payload whitelist. Garbage is logged and skipped without calling the CLI.
  - IPC events: `toggle`, `connect`, `disconnect`, `refresh`, `set-mode`,
    `set-families`, `set-protocol`. Mutations set `busy`, share one in-flight guard,
    ignore commands while busy and clear `busy` on completion/failure. `set-mode`
    honors `switchLocked` (notifyError, no CLI). `set-protocol` normalizes case for
    state and uses canonical `WireGuard`/`MASQUE` for argv.
  - Egress identity via `noctalia.http` GET to `https://www.cloudflare.com/cdn-cgi/trace`
    (the plugin's only network call): in-flight guard, result staleness check, runs on a
    timer when `auto_trace` and always on `refresh`. Never blocks status polling.
  - Notifications through `noctalia.notify`/`noctalia.notifyError`: `notify_on_change`
    on connected↔disconnected transitions, `notify_on_error` on a new non-empty
    `errorCode` (no repeat until it changes/clears). First publish after start is silent.
  - Error mapping: `cli-missing`, `daemon-down`, `timeout`, `unregistered`,
    `command-failed`, `decode-failed`, with tolerant text fallback so a JSON decode
    failure never clobbers known fields.
  - `onConfigChanged` re-reads settings and reapplies `setUpdateInterval` + trace timer;
    `onEnable`/`onExit` log.
  - `lib/parse.luau`: pure `parseStatus`, `parseSettings`, `parseRegistration`,
    `parseTrace`, `classifyError` (no entry globals, only `noctalia.*`).
  - `lib/commands.luau`: argv builders + `run` wrapper + mode/families/protocol
    whitelists.
  - `lib/state.luau`: `defaultStatus()`, `publish(patch)` with fingerprint,
    `setCommand(...)` helpers, channel constants.
  - Translations: `notify.*`, `error.*`, `status.*` keys with full en/ru parity.
- README: real IPC examples, network and process list. CHANGELOG 0.2.0 entry.

---

## [0.1.0] - 2026-10-19
- Spec decision: bar/shortcut icons use **SVG assets** (`barWidget.setImage`), not Tabler glyphs; glyphs remain fallback only.
- Docs/specs re-verified against Noctalia **5.3.0** and `warp-cli 2026.8.2110.0`: `plugin_api = 24`,
  argv-only `runAsync`, one nested state table per channel, `noctalia.http` for trace, real
  `noctalia plugins lint` workflow. Added [docs/API-NOTES.md](./docs/API-NOTES.md) as the
  canonical fact sheet; Phase 0–5 specs made executable.
- Phase 0 QA on `5.3.0-1-dirty`: `plugins disable` stops the service but does **not** invoke the
  Luau `onExit` hook; Phase 0 acceptance amended to the observable `stopping service … (no longer active)`
  contract.
### Fixed
### Removed

---

## [0.1.0] - 2026-10-19

### Added
- Phase 0 bootstrap: runtime plugin under `cloudflare-warp/` with the manifest
  (`plugin_api = 24`, `version = 0.1.0`, dependency `cloudflare-warp`) and all four entries:
  service, widget, shortcut, panel.
- Full final setting set (five plugin-level, two widget-level) and nested `en`/`ru`
  translations, including every manifest `label_key`/`description_key`.
- `lib/state.luau` with the state schema and channel constants, plus valid empty
  `lib/parse.luau` and `lib/commands.luau` module stubs for Phase 1.
- Status icon set moved to `cloudflare-warp/assets/icons/` for Phase 2 (not referenced by
  code yet).

---

## [0.0.0] - 2026-10-19

### Added
- Project bootstrap: SPEC, ROADMAP, AGENTS, skills, templates, versioning policy.
- No runtime plugin code yet (pre-Phase 0).
