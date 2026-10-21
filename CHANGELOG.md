# Changelog

All notable changes to the **Cloudflare WARP** Noctalia plugin are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [SemVer](https://semver.org/) — see [VERSIONING.md](./VERSIONING.md).

---

## [0.4.3] - 2026-10-21

### Added
- Animated hero banner derived from the owner-provided `assets/wGjQl.gif`: 27 WebP frames
  (`assets/banner/frame-00.webp` … `frame-26.webp`, 800×320) with a baked saturation ramp
  from 20% color (frame 0) to full color (frame 26) and a baked bottom alpha fade that
  blends the banner into the panel body. The 2.5:1 asset maps exactly to the 400×160
  display box, so the full GIF width is preserved and nothing is cropped left or right.
  Opening the panel with a live tunnel
  (connected/connecting) plays 0 → 26 at the GIF's native 100 ms/frame and holds the last
  frame; leaving connected/connecting for disconnecting/disconnected plays 26 → 0 and
  fades the color back down to 20%, keeping the banner visibly tinted when disconnected.
  Opening the panel while WARP is off (or in an error phase) shows frame 0 statically
  with no animation, so the banner always matches the phase.
  The sequence stops three frames before the GIF end per the owner's
  request; the ramp is remapped over the used frames so frame 26 is fully saturated.
- Banner playback runs on `panel.setNeedsFrameTick` / `onFrameTick` (33 ms ticks) and
  stops at both endpoints; the static frame persists until the next transition.
- Network identity is refreshed after every successful connect and disconnect: the
  service probes `cdn-cgi/trace` immediately and once more about 5 s later, when the
  tunnel route has settled, instead of waiting for the 60 s trace cycle. Mode and
  Protocol changes trigger the same immediate + delayed probe.
- Trace probing prefers an argv-only `curl` call
  (`--silent --show-error --fail --max-time 10 --connect-timeout 5`) when the binary
  exists and falls back to `noctalia.http`; both paths feed the same parser, circuit
  breaker and in-flight guard.
- The `connected` hero status now uses the native Tabler `shield-check` glyph in the
  success accent (`#3BE3A3`) instead of the ambiguous busy arc, so the OK state reads at
  a glance without adding a custom asset.

### Changed
- The bar widget now opens the panel on left click and sends `toggle` on right click;
  the previous bindings were the other way around.
- Banner height 96 → 160 px (wrapper 82 → 146 px); the panel was raised 672 → 734 px so
  the full layout, including the footer, fits without scrolling.
- The `disconnected` hero accent is a muted ember red-orange (`#C75B43`) instead of the
  brand orange, so the status block belongs to the banner's dimmed palette instead of
  competing with it.
- The connecting/disconnecting activity indicator is a five-bar sine wave (3 px bars,
  4–14 px tall, 900 ms period, opacity 0.45–1.0) driven by the existing frame ticks,
  replacing the running progress bar.
- The hero status icon no longer swaps to `loader-2` while the service is busy; activity
  is already shown by the transition wave and dimmed controls. Other phases keep
  their phase glyph at 22 px.
- The header Refresh button always uses the standard `refresh` glyph and signals feedback
  only through its opacity pulse; the static `loader-2` arc looked like a broken ring.

### Fixed
- Stale `busy` no longer freezes the panel: the service clears the flag on reload and
  whenever a poll sees no action in flight. A service hot reload during a mutation used
  to leave `busy = true` forever, disabling power, Mode, Protocol, DNS filtering and
  Refresh with no way to recover from the UI.
- Refresh is always available while no refresh feedback is running; it no longer waits
  for `busy`, so it also serves as a recovery action.
- The panel footer is no longer clipped at the bottom edge: the height added for the
  taller banner covers the content plus the host's bottom inset.
- The banner is now a single `ui.image` whose `path` swaps per frame; the old static
  `hero-banner-color.png` / `hero-banner-idle.png` assets are no longer referenced by the
  panel.
- Banner opacity is entrance-only now; connected vs disconnected is expressed solely by
  the frame sequence's saturation, while the phase accent lives in the hero card.
- The connecting phase no longer flashes and collapses back to «Отключено»: after a
  successful `connect`/`disconnect` the service holds the transitional phase and `busy`
  until a status poll observes the target phase or a 30 s safety timeout expires, so the
  panel goes «Отключено» → «Подключение…» → «Подключено» without an intermediate jump.
- Network identity updates on this host again: `noctalia.http` requests to
  `cdn-cgi/trace` consistently timed out (curl=28, empty body, no timeout option), so
  the service switched to the argv-only `curl` probe above. Trace failures now log the
  exit code and stderr once and every fifth retry instead of only a generic status.
- Copy IP shows the copied feedback only on an explicit `true` from `copyToClipboard`
  (strict, per SPEC): a non-`false` host result such as nil no longer counts as success
  and no longer triggers the feedback.
- The held `connecting`/`disconnecting` poll now clears `errorCode` and `message`, so a
  stale error string can no longer stay visible under «Подключение…».
- The delayed identity probe (after connect/disconnect and mode/protocol changes) re-arms
  itself 5 s later when a trace is already in flight instead of being dropped by the
  in-flight guard, so the post-change identity refresh is no longer lost.
- The power button stays enabled during a held `connecting`/`disconnecting` so the user can
  cancel or retry (toggle maps `connecting` → disconnect, `disconnecting` → connect), while
  the other mutating controls remain dimmed.
- The service no longer resets `families` to `malware` on reload: it keeps the value already
  published on the state channel, so the user's last choice survives a service hot reload
  even though the CLI value itself is write-only.
- Documentation corrections: SPEC §2/§10 now state the shipped click binding (LMB opens the
  panel, RMB toggles WARP) without the «инверсия» claim, and `templates/PR.md` carries the
  canonical, complete subprocess and network table.

---

## [0.4.2] - 2026-10-20

### Changed
- Panel side gutters reduced from 30 px to 16 px: the root now cancels the host's fixed
  14 px horizontal inset, leaving the inner 16 px as the only side padding. Cards,
  selects and the footer grew from 340 px to 368 px inside the 400 px panel. The banner
  keeps its full-bleed top treatment and the vertical rhythm is unchanged.

---

## [0.4.1] - 2026-10-20

### Added
- Panel redesign v2 (`cloudflare-warp/panel.luau`): full-bleed 400×96 banner with a
  bottom alpha fade, phase-accented hero card with large status, one-line subtitle,
  "Updated HH:MM" and power button, side-by-side Mode/Protocol selects, segmented DNS
  families control, network identity card and footer actions.
- Animated presentation, driven by host frame ticks and stopped when idle: entrance
  fade, eased accent/banner transitions on phase changes, a ping-pong progress bar plus
  banner pulse while connecting/disconnecting, a pulsing Refresh loader, and hover
  highlights on Families segments (native buttons animate their own hover/press).
- Hero banner assets `assets/hero-banner-color.png` (connected; connecting/disconnecting
  at 0.65 opacity) and `assets/hero-banner-idle.png` (dimmed for
  disconnected/error/unavailable/unregistered/unknown), derived from
  `assets/hero-banner.jpeg`.
- Copy feedback for about 1.6 s in the footer and next to the identity IP, and a
  ~1.5 s loader during Refresh; both windows use second ticks that stop when idle.
- `panel.hero.subtitle.disconnecting` for the transition state, with en/ru key parity
  (98/98).

### Changed
- Panel geometry and layout: 400×672, `floating`, reordered as banner → header → hero →
  controls → details → footer. The old phase line and footer `warp-cli` version caption
  are removed; the header remains the single close control.
- The panel no longer uses a scroll container: the host draws a scrollbar whenever
  `ui.scroll` is present (even when content fits), so the height is tuned to the tallest
  regular state and the footer is anchored with `flexGrow`.
- The banner bleeds to the panel edge: its wrapper cancels the host's 14 px inset with
  negative padding and the image radius matches the 12 px panel radius.
- Hero status is 21 px so the long Russian "Подключение…" state fits; multi-part error
  details fold into the subtitle row instead of adding layout height.
- Families always shows a selection: the CLI value is write-only, so an unset/unknown
  value is presented as the Cloudflare default **Malware** (Вредоносные). The unknown
  caption and its translation key are removed; the service and state defaults are now
  `families = "malware"`.
- Header is reduced to cloud glyph, title, Refresh and Close; the status card is replaced
  by the hero card; Mode and Protocol share one row; Families is a segmented control on
  a dimmed track; identity moved into a card; Copy IP and Settings are footer buttons.
- Long IPv6 addresses are middle-truncated to fit the identity row, while the clipboard
  always receives the full address.
- Panel remains a renderer and command writer: every action uses
  `State.setCommand(..., source = "panel")`; no `runAsync`, HTTP, CLI calls or
  `warp.status` writes.

### Fixed
- Families segments no longer keep a stale cyan fill/border after another option is
  selected; unselected segments now use explicit transparent fill and border.
- No visible scrollbar in any panel state.

### Known limits
- `warp-cli dns families` is write-only: the value is never read back, so the panel
  always falls back to the **Malware** default until a value is set in the current
  service session; a real non-default value is not detected after a restart.
- The 672 px panel height is host-owned and fixed. It fits every regular state
  (connected, disconnected, connecting, unregistered); an unusual two-line error plus
  the `switchLocked` caption may need a few extra pixels, and scrolling is intentionally
  not used.
- A user `[plugin_settings] panel_placement` value can override the manifest's `floating`
  placement at runtime (currently `attached` on the development host).

---

## [0.4.0] - 2026-10-20

### Added
- Phase 3 control panel: status card, mode (7) / families (3) / protocol (2) selectors, network identity, Copy IP / Register / Settings / Refresh actions (`cloudflare-warp/panel.luau`). All writes via `State.setCommand` source=`panel`; no runAsync, HTTP or file reads in the panel entry.
- Service: `register` action → `warp-cli registration new`, 30 s timeout; a timed-out interactive sign-in reports `error.register-pending` (notify) instead of an error state; success refreshes registration + status.
- `lib/icons.luau`: `statusGlyph` + `phaseColor` (SPEC 10.3).
- Translations: `panel.*`, `mode.*`, `families.*`, `error.register-pending` with full en/ru parity.

### Known limits
- `warp-cli registration new` is interactive (browser sign-in); without a browser it cannot complete — the 30 s timeout surfaces `register-pending` rather than failing the plugin.

---

## [0.3.0] - 2026-10-20

### Added
- Phase 2 bar widget + Control Center shortcut, both live-bound to the service state channel.
  - Bar widget: per-phase SVG icon via `barWidget.setImage(path, false, 16, 16)`, short status
    text (`show_text_in_bar` / `compact_mode` respected) and a detail tooltip
    (status, mode, families when known, protocol, IP/loc from trace, updated time, error).
    Falls back to a Tabler glyph when the phase SVG asset is missing: one warning per
    entry lifetime via `noctalia.fileExists()` probe, never spam.
  - Left click toggles WARP (`warp.command`, ignored while `busy`); right click opens the
    plugin panel via `noctalia.togglePanel`.
  - Control Center shortcut: phase label, `cloud-lock`/`cloud-off` glyphs, active when
    connected/connecting, disabled when unavailable/busy. Left click toggles, right click
    refreshes. `shortcut.setIcon` accepts glyph names only — glyph-only tiles in Control
    Center are an API limit, not an omission; SVG is bar-only.
  - New shared `lib/icons.luau`: single phase -> SVG path / glyph / text mapping plus
    tooltip rows and `normalizePhase` (closed phase set from `lib/state.luau`).
  - UI entries write commands through the existing `State.setCommand` helper
    (`seq = noctalia.nowMs()`); no `runAsync`, no HTTP, no file reads in widget/shortcut.
  - Translations: `widget.text.*`, `widget.tooltip.*`, `shortcut.*` with full en/ru parity;
    removed unused `widget.text.brand`.
- README: Interactions section (clicks for widget and shortcut) and the Control Center
  glyph note.

### Known limits
- Phase 2 live-tested on 5.3.0: hot-reload, disable/enable, SVG fallback and real widget
  clicks verified; visual confirmation of SVG rasterization on the bar is a manual
  checklist item (glyph fallback covers hosts without SVG support).

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
