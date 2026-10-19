---
name: versioning
description: Enforce SemVer, CHANGELOG, and merge bump policy for the Cloudflare WARP plugin. Used by orchestrator on every main merge.
---

# Versioning Skill

## Source of truth

1. `cloudflare-warp/plugin.toml` → `version`
2. `CHANGELOG.md`
3. git tag `vX.Y.Z`

## Algorithm (orchestrator)

1. Diff against previous release tag: what changed under `cloudflare-warp/`?
2. Classify:
   - **MAJOR** — breaking state keys, IPC rename, removed settings, plugin_api drop support story
   - **MINOR** — new feature, new entry, new setting, new IPC event
   - **PATCH** — fix, i18n, docs inside plugin, refactor no API change
3. Bump `plugin.toml`
4. Move Unreleased notes → new `## [X.Y.Z] - date` in CHANGELOG
5. Update STATE.md snapshot version
6. Tag after merge

## Pre-1.0

Phases map to `0.N.0` as in VERSIONING.md.  
Hotfixes inside a phase: `0.N.P`.

## Forbidden

- Merge to main with dirty version (code changed, version not)
- Using prerelease suffixes in `plugin.toml` (Noctalia rejects them)
