# Cloudflare WARP — Noctalia plugin

Control Cloudflare WARP from the Noctalia bar, Control Center and a dedicated panel.

> **Status: Phase 3 — service, bar widget, shortcut and panel are live.** The
> service is the single source of truth for WARP state: it polls `warp-cli`,
> publishes one `warp.status` table and executes whitelisted mutations from
> IPC and the `warp.command` channel. The bar widget and Control Center
> shortcut render live state and toggle WARP; the panel exposes the full
> control surface (mode, families, protocol, identity, registration).

## Dependency

The plugin requires Cloudflare's official `cloudflare-warp` package, which provides
`warp-cli` and the `warp-svc` daemon:

- <https://developers.cloudflare.com/warp-client/get-started/linux/>

WARP itself must already be installed and registered. The plugin never runs `sudo`,
`pkexec` or `systemctl`; it works through the user-facing CLI only.

### Terms of service

Every `warp-cli` invocation passes `--accept-tos`. This means the plugin accepts
Cloudflare's WARP terms of service **on your behalf**; review them before enabling the
plugin.

## Installation (path source)

The repository root is a Noctalia plugin source; the plugin itself lives in the
`cloudflare-warp/` directory (the suffix of its id).

```bash
noctalia msg plugins source add warpdev path /path/to/cloudflare-warp-plugin
noctalia msg plugins list | grep cloudflare-warp
noctalia msg plugins enable code-warlord/cloudflare-warp
```

To remove the development source later:

```bash
noctalia msg plugins disable code-warlord/cloudflare-warp
noctalia msg plugins source remove warpdev
```

## Entries

| Entry | Type | What it does |
|-------|------|--------------|
| `service` | service | Headless owner of WARP state: polls `warp-cli`, publishes `warp.status`, consumes `warp.command` and IPC. |
| `widget` | bar widget | Phase status SVG icon, short status text and tooltip; toggles WARP on click. |
| `shortcut` | Control Center | Live tile synced to `warp.status`; toggles WARP on click, refreshes on right click. |
| `panel` | floating panel | Full control surface: status card, mode, families, protocol, identity, registration actions. |

## Interactions

| Surface | Left click | Right click |
|---------|-----------|-------------|
| Bar widget | Toggle WARP (`warp.command` action `toggle`) | Open the plugin panel |
| Control Center tile | Toggle WARP (`warp.command` action `toggle`) | Refresh status (`warp.command` action `refresh`) |

Toggle clicks are ignored while the service reports `busy`, and the tile is
disabled while `warp-cli` is unavailable. The bar shows per-phase SVG icons;
the Control Center tile uses Tabler glyphs (`cloud-lock` / `cloud-off`)
because `shortcut.setIcon` accepts glyph names only — SVG icons are used in
the bar.

## Panel

The panel opens with a right click on the bar widget or via
`noctalia msg panel-toggle code-warlord/cloudflare-warp:panel`. The host owns
the fixed 400×672 geometry. The manifest requests `placement = "floating"`;
a user `[plugin_settings] panel_placement` value can override placement at
runtime (the development host currently runs it attached). The panel has no
scroll container — the host draws a scrollbar whenever one is present — so
the height is tuned to the tallest regular state and the footer is anchored
with `flexGrow`. Layout, top to bottom:

- **Banner** — full-bleed 400×96 phase image with a bottom alpha fade; the
  root cancels the host's 14 px horizontal inset so the only side gutter is
  16 px (cards are 368 px wide), and the banner wrapper pulls the top inset;
  the image radius matches the panel. Full colour for connected, colour at
  0.65 opacity while connecting/disconnecting, and a dimmed idle image for
  disconnected/error/unregistered/unknown;
- **Header** — cloud glyph, "Cloudflare WARP", Refresh (with a short loader)
  and Close; there is no duplicate close control;
- **Hero card** — 21 px phase status, one-line subtitle, "Updated HH:MM" and
  the power button; the accent is green when connected, orange when
  disconnected, cyan while transitioning, red for error/unavailable, amber
  for unregistered and grey for unknown. While connecting/disconnecting a
  thin progress bar runs under the subtitle;
- **Mode and Protocol** — two equal select columns; Mode is additionally
  disabled while a policy locks it;
- **DNS filtering** — segmented Off / Malware / Full control; one segment is
  always selected, and an unset/unknown value is presented as the Cloudflare
  default **Malware**;
- **Network identity** — egress IP with a copy control, location, edge, WARP
  flag and trace time, each shown honestly when missing;
- **Footer** — Copy IP (outline) and Settings (ghost); Register (primary)
  replaces Copy IP only while the client is unregistered.

![Connected panel](../docs/images/panel-connected.png)

More states and the full visual system: [docs/DESIGN-PANEL.md](../docs/DESIGN-PANEL.md).

Copy IP shows a success state in the footer and next to the identity IP for
about 1.6 s (driven by second ticks); Refresh shows a pulsing loader for about
1.5 s. The panel animates its entrance, eases the hero accent and banner
opacity when the phase changes, pulses the banner and progress bar while
connecting/disconnecting, and highlights Families segments on hover. Frame
ticks are requested only while an animation is active and stop when idle.
Long IPv6 addresses are middle-truncated in the display but copied in full.
There is no `warp-cli` version caption in the panel.

Every panel action is written to the `warp.command` state channel and
executed by the service. The panel is a renderer and command writer only: no
`runAsync`, no HTTP, no CLI calls and no `warp.status` writes.

### Families limitation

`warp-cli dns families` is write-only: the client exposes no getter, so the
plugin cannot read the current value. The segmented control therefore always
shows the Cloudflare default **Malware** until a value is set in the current
service session. A selection applies immediately and can only be set, never
reverted from the plugin — there is no way back to the previous value, and
after a restart the plugin shows *Malware* again even though the client keeps
the last applied setting.

### Warnings

- Changing the **protocol** restarts the WARP tunnel and briefly drops
  connectivity; the plugin does not block the change.
- **Register** runs the interactive `warp-cli registration new`: it waits up
  to 30 seconds for the browser sign-in. A timeout is reported as a
  "registration still waiting for the sign-in" notification, **not** as an
  error; once the sign-in completes, the next poll marks the client as
  registered.

## IPC

The service entry implements `onIpc` and watches the `warp.command` state channel.
Both paths route into one `dispatch(action, fields, source)` handler with the same
whitelist validation.

```bash
# Out-of-order status + settings + registration + trace refresh
noctalia msg plugin code-warlord/cloudflare-warp:service all refresh
# Toggle: disconnect when connected/connecting, otherwise connect
noctalia msg plugin code-warlord/cloudflare-warp:service all toggle
# Explicit connect / disconnect
noctalia msg plugin code-warlord/cloudflare-warp:service all connect
noctalia msg plugin code-warlord/cloudflare-warp:service all disconnect
# Interactive registration (waits for the browser sign-in, up to 30s)
noctalia msg plugin code-warlord/cloudflare-warp:service all register
# Mutations (payload is always a string; missing argument arrives as "")
noctalia msg plugin code-warlord/cloudflare-warp:service all set-mode warp+doh
noctalia msg plugin code-warlord/cloudflare-warp:service all set-families malware
noctalia msg plugin code-warlord/cloudflare-warp:service all set-protocol MASQUE
```

IPC events: `toggle`, `connect`, `disconnect`, `refresh`, `register`, `set-mode`,
`set-families`, `set-protocol`.

Valid mode values: `warp`, `doh`, `warp+doh`, `dot`, `warp+dot`, `proxy`, `tunnel_only`.
Valid families values: `off`, `malware`, `full`. Valid protocol values: `wireguard`,
`masque` (any case). Anything else is logged as a warning and skipped — no CLI call,
no state change.

UI entries do not call IPC from scripts; they write a table to the `warp.command`
channel (`seq`, `action`, optional `mode`/`families`/`protocol`, optional `source`) and
the service watches it.

## Network and processes

- **Processes:** argv-only `warp-cli` calls (never a shell string). The service polls
  `status` every tick, `settings list` every 5th tick and `registration show` every 10th
  tick; mutations (`connect`, `disconnect`, `mode`, `dns families`, `tunnel protocol set`)
  run on demand. All calls go through `noctalia.runAsync({...}, cb, timeoutMs)` with a
  per-command timeout. No `curl`, no `grep`/`awk`, no `os.execute`, no `io.popen`.
- **Network:** one HTTPS `GET` to `https://www.cloudflare.com/cdn-cgi/trace` via
  `noctalia.http` when network-identity tracking is enabled (default: every 60 seconds,
  and on every `refresh`). This is the plugin's only network call.

## Icons and trademarks

`assets/icons/` contains original stylized WARP status icons (color and mono variants).
They are not the official Cloudflare logo and are not copied from Cloudflare artwork.
"Cloudflare", "WARP" and the Cloudflare logo are trademarks of Cloudflare, Inc. This
plugin is an independent community project and is not affiliated with or endorsed by
Cloudflare.

## License

MIT.
