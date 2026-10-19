# Changelog

All notable changes to the **Cloudflare WARP** Noctalia plugin are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [SemVer](https://semver.org/) — see [VERSIONING.md](./VERSIONING.md).

---

## [Unreleased]

### Added
### Changed
- Spec decision: bar/shortcut icons use **SVG assets** (`barWidget.setImage`), not Tabler glyphs; glyphs remain fallback only.
- Docs/specs re-verified against Noctalia **5.3.0** and `warp-cli 2026.8.2110.0`: `plugin_api = 24`,
  argv-only `runAsync`, one nested state table per channel, `noctalia.http` for trace, real
  `noctalia plugins lint` workflow. Added [docs/API-NOTES.md](./docs/API-NOTES.md) as the
  canonical fact sheet; Phase 0–5 specs made executable.
- Phase 0 QA on `5.3.0-1-dirty`: `plugins disable` stops the service but does **not** invoke the
  Luau `onExit` hook; Phase 0 acceptance amended to the observable `stopping service … (no longer active)`
  contract.
### Fixed
### Removed

---

## [0.1.0] - 2026-10-19

### Added
- Phase 0 bootstrap: runtime plugin under `cloudflare-warp/` with the manifest
  (`plugin_api = 24`, `version = 0.1.0`, dependency `cloudflare-warp`) and all four entries:
  service, widget, shortcut, panel.
- Full final setting set (five plugin-level, two widget-level) and nested `en`/`ru`
  translations, including every manifest `label_key`/`description_key`.
- `lib/state.luau` with the state schema and channel constants, plus valid empty
  `lib/parse.luau` and `lib/commands.luau` module stubs for Phase 1.
- Status icon set moved to `cloudflare-warp/assets/icons/` for Phase 2 (not referenced by
  code yet).

---

## [0.0.0] - 2026-10-19

### Added
- Project bootstrap: SPEC, ROADMAP, AGENTS, skills, templates, versioning policy.
- No runtime plugin code yet (pre-Phase 0).
