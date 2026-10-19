# Cloudflare WARP — Noctalia plugin

Control Cloudflare WARP from the Noctalia bar, Control Center and a dedicated panel.

> **Status: 0.1.0 (Phase 0 bootstrap).** All four entries load and render
> placeholders. Live status, connect/disconnect, mode/Families/protocol controls and
> egress identity arrive in later phases.

## Dependency

The plugin requires Cloudflare's official `cloudflare-warp` package, which provides
`warp-cli` and the `warp-svc` daemon:

- <https://developers.cloudflare.com/warp-client/get-started/linux/>

WARP itself must already be installed and registered. The plugin never runs `sudo`,
`pkexec` or `systemctl`; it works through the user-facing CLI only.

### Terms of service

Every `warp-cli` invocation (from Phase 1 onward) passes `--accept-tos`. This means the
plugin accepts Cloudflare's WARP terms of service **on your behalf**; review them before
enabling the plugin.

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
| `service` | service | Headless owner of WARP state. Phase 1 adds polling and commands. |
| `widget` | bar widget | `cloud-lock` glyph plus `WARP` text. Phase 2 adds status icons and clicks. |
| `shortcut` | Control Center | Static off-state tile. Phase 2 makes it a live toggle. |
| `panel` | floating panel | Header, placeholder and version. Phase 3 adds controls. |

Bar clicks (Phase 2) will follow the project convention: **left click toggles WARP, right
click opens the panel**. This is the opposite of `levi/warp`.

## IPC (Phase 1+)

The service entry does not implement `onIpc` yet, so these commands are documented for
the upcoming phase and currently dispatch without effect:

```bash
noctalia msg plugin code-warlord/cloudflare-warp:service all refresh
noctalia msg plugin code-warlord/cloudflare-warp:service all toggle
noctalia msg plugin code-warlord/cloudflare-warp:service all connect
noctalia msg plugin code-warlord/cloudflare-warp:service all disconnect
noctalia msg panel-toggle code-warlord/cloudflare-warp:panel
```

## Network and processes

- **Phase 0 (this release):** none. The plugin starts no processes and makes no network
  requests; it only reads its settings and renders placeholders.
- **Planned (Phase 1+):** argv-only `warp-cli` calls (status, settings, registration,
  connect/disconnect and mode/Families/protocol mutations), plus one HTTPS `GET` to
  `https://www.cloudflare.com/cdn-cgi/trace` when network-identity tracking is enabled
  (default: once every 60 seconds). No shell strings, no `curl`.

## Icons and trademarks

`assets/icons/` contains original stylized WARP status icons (color and mono variants).
They are not the official Cloudflare logo and are not copied from Cloudflare artwork.
"Cloudflare", "WARP" and the Cloudflare logo are trademarks of Cloudflare, Inc. This
plugin is an independent community project and is not affiliated with or endorsed by
Cloudflare.

## License

MIT.
