---
name: docs-i18n
description: Maintain README, translations (en/ru), CHANGELOG entries, and PR descriptions for the Cloudflare WARP Noctalia plugin.
---

# Docs & i18n Skill

## Identity

You own user-facing text and project documentation that ships with or around the plugin.

## Files

| File | Language | Notes |
|------|----------|-------|
| `cloudflare-warp/translations/en.json` | English | Required |
| `cloudflare-warp/translations/ru.json` | Russian | Required |
| `cloudflare-warp/README.md` | English | Install, IPC, limits |
| `CHANGELOG.md` | English (Keep a Changelog) | Every release |
| `STATE.md` / `ROADMAP.md` | Russian OK | Meta |

## Translation rules

Files are **nested JSON**, not flat dotted keys. The dotted key is the *path* into the object:

```json
{
  "settings": {
    "poll_interval": {
      "label": "Poll interval",
      "description": "How often to poll warp-cli"
    }
  },
  "status": { "connected": "Connected" }
}
```

- `settings.poll_interval.label` in the manifest ↔ `translations/en.json` → `settings.poll_interval.label`.
  Never write `"settings.poll_interval.label": "..."` as a single flat key — the host resolves nested paths
  and every shipped plugin (`official/screen_recorder`, `community/warp`) uses nested objects.
- Every `label_key` / `description_key` / option label key in the manifest must exist in **both** en and ru.
- Widget/panel strings resolved through the host i18n helper must have keys in both files.
- Top-level `title` is a plain string (plugin display name), not an object.
- Do not leave English-only keys in ru.json (translate or mark intentionally).
- Parity check before Phase 5:

```bash
python3 - <<'PY'
import json, sys
base = "cloudflare-warp/translations/"
def paths(o, p=""):
    out = set()
    for k, v in o.items():
        q = f"{p}.{k}" if p else k
        out |= paths(v, q) if isinstance(v, dict) else {q}
    return out
en = paths(json.load(open(base + "en.json")))
ru = paths(json.load(open(base + "ru.json")))
missing_ru, extra_ru = sorted(en - ru), sorted(ru - en)
print("missing in ru:", missing_ru or "none")
print("extra in ru:", extra_ru or "none")
sys.exit(1 if missing_ru or extra_ru else 0)
PY
```

## README must include

1. Dependency: `cloudflare-warp`
2. Enable instructions (plugin store or path source)
3. IPC examples
4. Known limitations (no sudo, CLI surface)
5. License

## CHANGELOG entry

When implementer notes “Added X”:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- X
```

## PR body

Use `templates/PR.md`. Fill **Network & processes** section exhaustively.
