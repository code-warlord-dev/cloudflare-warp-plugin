# Phase 4 — Polish & i18n

**Target version:** `0.5.0` (MINOR)  
**Goal:** Готовность к community-plugins: i18n, error UX, README, analyze clean.

## Non-goals

- New features beyond SPEC

## Dependencies

Phases 0–3.

## Tasks

1. Audit all user-facing strings → keys in en.json + ru.json
2. Error messages for: not installed, daemon down, unregistered, generic error
3. README: install, path source, IPC table, limitations, license
4. Optional preview.png in assets/
5. Run `luau-analyze` if available; fix diagnostics
6. Double-check settings advanced flags / visible_when if needed
7. Confirm no secrets, no sudo, process list complete

## Acceptance criteria

- [ ] ru.json covers 100% of keys in en.json
- [ ] Switching Noctalia UI language shows Russian labels for settings
- [ ] README complete per docs-i18n skill
- [ ] validate-plugin still green
- [ ] QA full matrix PASS (.agents/skills/qa)
- [ ] version 0.5.0 + CHANGELOG

## Version bump

`0.4.0` → `0.5.0`
