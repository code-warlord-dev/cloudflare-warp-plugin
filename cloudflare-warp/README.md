# Cloudflare WARP — Noctalia plugin

Control Cloudflare WARP from the Noctalia bar, Control Center and a dedicated panel.

> **Status: 0.2.0 (Phase 1 service core).** The service is the single source of
> truth for WARP state: it polls `warp-cli`, publishes one `warp.status` table and
> executes whitelisted mutations from IPC and the `warp.command` channel. The bar
> widget, shortcut and panel still render placeholders (Phase 2–3).

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
| `widget` | bar widget | `cloud-lock` glyph plus `WARP` text. Phase 2 adds status icons and clicks. |
| `shortcut` | Control Center | Static off-state tile. Phase 2 makes it a live toggle. |
| `panel` | floating panel | Header, placeholder and version. Phase 3 adds controls. |

Bar clicks (Phase 2) will follow the project convention: **left click toggles WARP, right
click opens the panel**. This is the opposite of `levi/warp`.

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
# Mutations (payload is always a string; missing argument arrives as "")
noctalia msg plugin code-warlord/cloudflare-warp:service all set-mode warp+doh
noctalia msg plugin code-warlord/cloudflare-warp:service all set-families malware
noctalia msg plugin code-warlord/cloudflare-warp:service all set-protocol MASQUE
```

IPC events: `toggle`, `connect`, `disconnect`, `refresh`, `set-mode`, `set-families`,
`set-protocol`. `register` arrives in Phase 3.

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
