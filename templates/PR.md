# Pull Request template

## Title

```
<type>(<scope>): <summary>  [vX.Y.Z]
```

Example: `feat(service): status polling and IPC toggle [v0.2.0]`

---

## Summary

<!-- 2–5 sentences: what and why -->

## Phase / roadmap

- [ ] Phase 0 Bootstrap
- [ ] Phase 1 Service
- [ ] Phase 2 Widget + Shortcut
- [ ] Phase 3 Panel
- [ ] Phase 4 Polish
- [ ] Phase 5 Public 1.0
- [ ] Post-1.0 / other

## Version bump

- Previous: `x.y.z`
- New: `X.Y.Z`
- Kind: **MAJOR / MINOR / PATCH / none (meta only)**
- Rationale:

## Checklist

- [ ] `STATE.md` updated (or will be by orchestrator on merge)
- [ ] `CHANGELOG.md` has entry under Unreleased or new version section
- [ ] `plugin.toml` version matches (if plugin code changed)
- [ ] Reviewer: APPROVE
- [ ] QA: PASS (if runtime)
- [ ] No hardcoded user-facing strings without i18n keys
- [ ] `plugin_api` justified

## Network & processes

Canonical, exhaustive list of every subprocess and network call in the plugin.
Every `warp-cli` row is an argv vector prefixed with `--accept-tos --json --no-paginate
--no-ansi` and launched through the argv form of `noctalia.runAsync`; `warp-cli --version`
is the only call without the base flags. Nothing is run through a shell.

| Call | When | Data |
|------|------|------|
| `warp-cli status` (argv) | every poll tick (default 3 s), on `onEnable`, on `refresh`, and right after every mutation resolves | local CLI, no payload |
| `warp-cli settings list` (argv) | every 5th poll tick, on `refresh`, and after connect/disconnect/mode/protocol mutations | local CLI, no payload |
| `warp-cli registration show` (argv) | every 10th poll tick, on `refresh`, and after `registration new` | local CLI, no payload |
| `warp-cli registration new` (argv) | IPC / `warp.command` action `register` | local CLI; prints the Cloudflare sign-in URL, up to 30 s interactive wait |
| `warp-cli connect` (argv) | IPC / `warp.command` action `connect`, and `toggle` when the phase is not connected/connecting | local CLI, no payload |
| `warp-cli disconnect` (argv) | IPC / `warp.command` action `disconnect`, `toggle` when connected/connecting, and the panel power button during a held `connecting`/`disconnecting` | local CLI, no payload |
| `warp-cli mode <M>` (argv) | IPC / `warp.command` action `set-mode`; `<M>` whitelisted (`warp`, `doh`, `warp+doh`, `dot`, `warp+dot`, `proxy`, `tunnel_only`) | local CLI, whitelisted mode |
| `warp-cli dns families <F>` (argv) | IPC / `warp.command` action `set-families`; `<F>` whitelisted (`off`, `malware`, `full`) | local CLI, whitelisted families |
| `warp-cli tunnel protocol set <P>` (argv) | IPC / `warp.command` action `set-protocol`; `<P>` whitelisted (`WireGuard`, `MASQUE`) | local CLI, whitelisted protocol |
| `warp-cli --version` (argv) | once on service start | local CLI, no payload |
| `curl --silent --show-error --fail --max-time 10 --connect-timeout 5 https://www.cloudflare.com/cdn-cgi/trace` (argv) | trace probe: every `trace_interval_s` while `auto_trace`, on `refresh`, and ~5 s after a successful connect/disconnect/mode/protocol change; preferred when `curl` is on `PATH` | HTTPS GET to Cloudflare; response body parsed locally, status/IP/location/colo only |
| `noctalia.http` GET `https://www.cloudflare.com/cdn-cgi/trace` | same trace probe, fallback when `curl` is not on `PATH` | Cloudflare; same parser, circuit breaker and in-flight guard as the curl path |

No other subprocesses, shells, `grep`/`awk`, `sudo`/`pkexec`/`systemctl` or network
endpoints are used.

## Test plan

1. …
2. …

## Screenshots / IPC transcript

<!-- optional -->

## Breaking changes

<!-- none / describe migration -->
