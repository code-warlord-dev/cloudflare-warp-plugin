# STATE — текущее состояние проекта

> Этот файл обновляет **Orchestrator** после каждого значимого события  
> (завершение задачи субагента, merge, блокер).  
> Читать первым при любом старте сессии.

---

## Snapshot

| Поле | Значение |
|------|----------|
| **Plugin version** | `0.2.0` (tag `v0.2.0`) |
| **Roadmap phase** | Phase 1 — Service Core **done**; следующая Phase 2 — Widget + Shortcut |
| **Branch** | `main` |
| **Remote** | https://github.com/code-warlord-dev/cloudflare-warp-plugin |
| **Last merge** | `f73fe8a` Merge PR #2 — Phase 1 service core |
| **Blockers** | нет |
| **Next action** | implementer: Phase 2 widget + shortcut по `specs/phase-2-widget.md` (target `0.3.0`; live-тест `barWidget.setImage` со SVG = K-02) |

---

## Active work

| Agent | Task | Status | Branch / notes |
|-------|------|--------|----------------|
| orchestrator | Repo bootstrap + skills → `.agents/skills/` | done | `main` @ a067b73 |
| architect | API reconciliation (Noctalia 5.3.0) + phase specs 0–5 | done | `docs/API-NOTES.md`, `docs/SPEC.md` v2 |
| implementer | Phase 0 Bootstrap (P0-T1) | done | merged PR #1 |
| reviewer | Phase 0 review | done | APPROVE (after 1 blocker fix) |
| qa | Phase 0 live run на 5.3.0 | done | PASS (GUI-пункты — вручную) |
| implementer | Phase 1 Service Core (P1-T1) + fix round 2 | done | merged PR #2 |
| reviewer | Phase 1 review (full + fix round) | done | APPROVE ×2 |
| qa | Phase 1 live run + fix re-test | done | FAIL → fixes → PASS (baseline восстановлен) |
| implementer | Phase 2 Widget + Shortcut (P2-T1) | next | target `0.3.0` |

---

## Completed this cycle

- [x] SPEC / ROADMAP / VERSIONING / CHANGELOG / STATE
- [x] AGENTS.md + 11 skills → `.agents/skills/` (harness подхытывает автоматически)
- [x] Git repo + public remote + topics
- [x] Сверка документации с реальным Noctalia 5.3.0 / `warp-cli 2026.8.2110.0`
- [x] `docs/API-NOTES.md` — канонический лист проверенных фактов
- [x] Phase 0–5 specs переписаны в executable-вид
- [x] SVG/PNG icon set добавлен, проверен, закоммичен (`c67db5e`)
- [x] Phase 0: манифест + 4 entry + lib-заготовки + en/ru translations + README
- [x] Phase 0: lint 0/0, live enable/disable/panel-toggle, WARP не тронут
- [x] Phase 0: PR #1 merged, tag `v0.1.0`
- [x] Phase 1: сервис — polling argv-only, `warp.status`/`warp.command`, IPC dispatch, мутации, trace, уведомления
- [x] Phase 1: reviewer APPROVE ×2, QA полный прогон с реальными мутациями + re-test, фикс-раунд 2
- [x] Phase 1: PR #2 merged, tag `v0.2.0`

---

## Known issues

| ID | Description | Severity | Owner |
|----|-------------|----------|-------|
| K-01 | Author handle: локально есть плагины `code_warlord/*`, выбран `code-warlord`; сверить до Phase 5 | minor | orchestrator |
| K-02 | `barWidget.setImage` с SVG не используется ни одним shipped-плагином; нужен live-тест + glyph-fallback | major | qa / Phase 2 |
| K-03 | `warp-cli dns families` write-only, геттера нет → `families = unknown` до установки в сессии | known limit | implementer |
| K-04 | Нет локального Luau-тулчейна (`luau`, `luau-analyze`, `selene`) — гейт только lint + runtime-лог | minor | Phase 4 |
| K-05 | Включены конкурирующие `levi/warp` и `code_warlord/warp_toggle` — QA не трогает, фильтрует логи | minor | qa |
| K-06 | `connecting` и `warn` иконки почти неразличимы на 16 px | minor | Phase 2 (design) |
| K-07 | На `5.3.0-1-dirty` `plugins disable` не вызывает Luau `onExit`; acceptance под это поправлен | known limit | docs |
| K-08 | `cdn-cgi/trace` через `noctalia.http` падает бёрстами (`curl=28`, 30s-таймаут, опций нет) — обработано circuit breaker'ом; причина на уровне хоста/WARP-туннеля | known limit | Phase 4 / внешнее |
| K-09 | `warp.command` (state-канал) не имеет CLI-пути записи — в QA проверен только IPC; оба пути сходятся в `dispatch` | minor | qa / Phase 3 |

---

## Decisions log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-19 | `plugin_api = 24` | относительные модули — 22, argv-форма `runAsync` — 24; выше не поднимаем |
| 2026-10-19 | id = `code-warlord/cloudflare-warp`, каталог `cloudflare-warp/` | author = GitHub-хендл; `community` — имя source, не автора |
| 2026-10-19 | Service = single source of truth | как official `screen_recorder` |
| 2026-10-19 | State = одна таблица на канал: `warp.status` + `warp.command` | атомарность, один `watch` на entry, plain data |
| 2026-10-19 | `warp-cli … --json --no-paginate --no-ansi --accept-tos`, argv-only | без shell-парсинга и инъекций; tolerant text-fallback |
| 2026-10-19 | Trace через `noctalia.http`, без `curl` | минус один subprocess в trust surface |
| 2026-10-19 | Families = write-only, `unknown` при старте | CLI не отдаёт текущее значение |
| 2026-10-19 | No sudo, CLI only | trusted plugin safety + UX clarity |
| 2026-10-19 | Bar icons = **SVG** via `setImage`, glyph — fallback; shortcut — glyph-only | бренд WARP; `shortcut.setIcon` путей не принимает |
| 2026-10-19 | Локальный гейт — `noctalia plugins lint`; `validate-plugin` не существует | сверено с 5.3.0 |
| 2026-10-19 | Иконки престейджены в `cloudflare-warp/assets/icons/` до Phase 2 | пользовательский набор; в коде пока не используются |
| 2026-10-19 | `onExit` не вызывается на disable в этой сборке — код не меняли, поправили acceptance | эмпирика QA |
| 2026-10-20 | Уведомления по стабильной фазе (`lastStablePhase`, без `connecting`/`disconnecting`) | QA: toggle не давал пары connected→disconnected |
| 2026-10-20 | Trace circuit breaker: пауза после 3 неудач, backoff `interval×10×2^level` (max 160×), обход через `refresh` | `noctalia.http` без опции таймаута, лог спамился WRN/мин |
| 2026-10-20 | Whitelist протокола — только ASCII (`MÁSQUE` отклоняется) | спека исправлена под эмпирику, `string.lower` ASCII-only |

---

## Quick commands

```bash
# lint (offline author gate)
noctalia plugins lint cloudflare-warp

# dev path source (once)
noctalia msg plugins source add warpdev path /home/code_warlord/DEV/cloudflare-warp-plugin

# enable / disable
noctalia msg plugins enable code-warlord/cloudflare-warp
noctalia msg plugins disable code-warlord/cloudflare-warp

# service IPC (after Phase 1)
noctalia msg plugin code-warlord/cloudflare-warp:service all refresh
noctalia msg plugin code-warlord/cloudflare-warp:service all toggle

# panel
noctalia msg panel-toggle code-warlord/cloudflare-warp:panel

# logs
tail -f ~/.cache/noctalia/noctalia.log
```
