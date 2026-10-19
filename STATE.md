# STATE — текущее состояние проекта

> Этот файл обновляет **Orchestrator** после каждого значимого события  
> (завершение задачи субагента, merge, блокер).  
> Читать первым при любом старте сессии.

---

## Snapshot

| Поле | Значение |
|------|----------|
| **Plugin version** | `0.0.0` |
| **Roadmap phase** | Phase 0 — Bootstrap (не начата) |
| **Branch** | `main` |
| **Last merge** | — |
| **Blockers** | нет |
| **Next action** | Phase 0: создать `cloudflare-warp/plugin.toml` + empty entries |

---

## Active work

| Agent | Task | Status | Branch / notes |
|-------|------|--------|----------------|
| — | — | idle | — |

---

## Completed this cycle

- [x] SPEC.md написан
- [x] ROADMAP / VERSIONING / CHANGELOG / STATE
- [x] AGENTS.md + skills + templates

---

## Known issues

| ID | Description | Severity | Owner |
|----|-------------|----------|-------|
| — | — | — | — |

---

## Decisions log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-19 | plugin_api = 17 | onEnable/onExit/onConfigChanged для service |
| 2026-10-19 | id = `community/cloudflare-warp` | community-plugins convention |
| 2026-10-19 | Service = single source of truth | как screen_recorder official plugin |
| 2026-10-19 | No sudo, CLI only | trusted plugin safety + UX clarity |
| 2026-10-19 | Bar icons = **SVG** via `setImage`, not Tabler glyph | бренд WARP; glyph — только fallback + catalog icon |

---

## Quick commands

```bash
# validate
noctalia validate-plugin cloudflare-warp

# IPC test (after Phase 1)
noctalia msg plugin community/cloudflare-warp:service all refresh
noctalia msg plugin community/cloudflare-warp:service all toggle
```
