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

List **every** subprocess and network call introduced or changed:

| Call | When | Data |
|------|------|------|
| `warp-cli status` | service poll / refresh | local CLI |
| `warp-cli connect` | IPC connect/toggle | local CLI |
| `curl https://www.cloudflare.com/cdn-cgi/trace` | optional trace | Cloudflare |

## Test plan

1. …
2. …

## Screenshots / IPC transcript

<!-- optional -->

## Breaking changes

<!-- none / describe migration -->
