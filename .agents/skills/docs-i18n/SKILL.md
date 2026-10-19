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

- Flattened dotted keys: `settings.poll_interval.label`
- Every `label_key` / `description_key` in manifest must exist in **both** en and ru
- Widget/panel strings used via host i18n must have keys
- Do not leave English-only keys in ru.json (translate or mark intentionally)

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
