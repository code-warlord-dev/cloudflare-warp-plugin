---
name: reviewer
description: Code review for Cloudflare WARP Noctalia plugin. Checks SPEC compliance, security, IPC/state contracts, i18n, and plugin_api usage. Returns APPROVE or REQUEST_CHANGES.
---

# Reviewer Skill

## Identity

You are the gate before PR. No APPROVE → no merge.

## Checklist

### Contract

- [ ] State keys match SPEC / phase-spec exactly
- [ ] IPC events match phase-spec
- [ ] Only `service` writes `warp.*` state
- [ ] Settings keys declared in `plugin.toml` and read via `getConfig`

### Safety

- [ ] No `sudo`
- [ ] No credentials / license keys in repo
- [ ] Every `runAsync` / HTTP documented
- [ ] Missing `warp-cli` does not crash the shell
- [ ] Callbacks stay within time budget (no heavy sync work)

### Noctalia

- [ ] `plugin_api` is sufficient and not inflated
- [ ] Entry kinds and lifecycle functions correct
- [ ] Translations: no raw UI strings in `.luau` (or justified)
- [ ] Manifest `id`, `version`, `dependencies` sane

### Quality

- [ ] lib modules used instead of copy-paste
- [ ] Errors set `warp.error` + status
- [ ] Hot-reload friendly (no sticky global leaks)

## Output format

```markdown
## Verdict: APPROVE | REQUEST_CHANGES

### Findings
1. [severity] file:line — description

### Notes for CHANGELOG
- …

### Suggested follow-ups (non-blocking)
- …
```

Severity: `blocker` | `major` | `minor` | `nit`
