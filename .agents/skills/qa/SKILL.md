---
name: qa
description: Test Cloudflare WARP Noctalia plugin via noctalia CLI, IPC, and manual acceptance. Produces pass/fail reports against phase specs.
---

# QA Skill

## Identity

You verify **behavior**, not code style.

## Environment assumptions

- Noctalia 5.x running under Niri (or compatible)
- Plugin enabled via path source or installed source
- `cloudflare-warp` package installed (or explicitly test “not installed” path)

## Commands

```bash
# validate manifest + entries
noctalia validate-plugin cloudflare-warp

# list / enable
noctalia msg plugins list
noctalia msg plugins enable community/cloudflare-warp

# service IPC
noctalia msg plugin community/cloudflare-warp:service all refresh
noctalia msg plugin community/cloudflare-warp:service all toggle
noctalia msg plugin community/cloudflare-warp:service all connect
noctalia msg plugin community/cloudflare-warp:service all disconnect
noctalia msg plugin community/cloudflare-warp:service all set-mode "doh"

# panel
noctalia msg panel-toggle community/cloudflare-warp:panel

# logs
# ~/.cache/noctalia/noctalia.log
```

## Test matrix (minimum)

| Case | Expect |
|------|--------|
| warp-cli present, registered, disconnected | status=disconnected; toggle → connected |
| connected | toggle → disconnected |
| warp-cli missing | status=error; no crash; message clear |
| daemon down | daemon_ok=false or error |
| unregistered | status=unregistered |
| change poll_interval_ms | interval changes without full shell restart |
| hot-reload service.luau | continues polling |
| widget on bar | glyph/text reflects state within ~poll interval |
| shortcut | checked tracks connection |

## Report format

```markdown
## QA Report — Phase N / Task …

### Environment
- Noctalia: …
- cloudflare-warp: installed | missing
- Registration: yes | no

### Results
| # | Case | Result | Notes |
|---|------|--------|-------|
| 1 | … | PASS/FAIL | … |

### Verdict: PASS | FAIL
### Blockers
- …
```

## Rule

If acceptance criteria in the phase-spec are not all PASS → FAIL (no soft pass).
