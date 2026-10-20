# STATE — текущее состояние проекта

> Этот файл обновляет **Orchestrator** после каждого значимого события  
> (завершение задачи субагента, merge, блокер).  
> Читать первым при любом старте сессии.

---

## Snapshot

| Поле | Значение |
|------|----------|
| **Plugin version** | `0.4.1` (commit `0176f0e`; tag pending) |
| **Roadmap phase** | Phase 3 — Panel **done** (0.4.0 + redesign v2 0.4.1) |
| **Branch** | `feat/panel-redesign-v2` |
| **Remote** | https://github.com/code-warlord-dev/cloudflare-warp-plugin |
| **Last merge** | `3cf4813` chore(release): bump 0.3.0 -> 0.4.0 (origin/main) |
| **Blockers** | `warpqa` path source wins over `warpdev`: the running host loads 0.4.0 from the stale worktree. Owner decision needed to disable/remove `warpqa` or reorder sources. |
| **Next action** | Owner visual sign-off; resolve `warpqa` precedence; push branch + PR; merge + tag `v0.4.1`; then Phase 4 |

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
| implementer | Phase 2 Widget + Shortcut (P2-T1) + fix round (State.setCommand, brand-key) | done | merged PR #3, `7653858` |
| reviewer | Phase 2 review | done | APPROVE (1 minor → fix round, 5 nit) |
| qa | Phase 2 live run на 5.3.0 | done | PASS (hot-reload, disable/enable, K-02 fallback, живые клики владельца; GUI-пункты — manual sign-off) |

| implementer | Phase 3 Panel (panel.luau, service register, icons, translations) | done | `feat/phase-3-panel` → `release-0.4.0`, merged PR #4 |
| reviewer | Phase 3 review (full + fix round) | done | APPROVE (ре-approv. после фиксов — лимит модели проверяющего; гейты верифицированы оркестратором: lint 0/0, панель без ошибок, register/refresh IPC, en/ru паритет) |
| qa | Phase 3 live run на 5.3.0 | done | PASS (панель открывается, watch-колбэк чист, register/refresh через IPC без падений; GUI — manual) |
| implementer | Panel redesign v2 (banner, hero, Mode/Protocol, Families, identity, footer) | done | working tree, `feat/panel-redesign-v2` |
| reviewer | Redesign review (2 раунда + fix round) | done | APPROVE; lint 0/0; en/ru 99/99 |
| qa | Redesign live QA + 8 screenshots | done | PASS; `docs/images/panel-*.png`; temp source/фикстуры восстановлены |
| docs | README, CHANGELOG 0.4.1, `docs/DESIGN-PANEL.md`, root README | done | docs/DESIGN-PANEL.md |
| orchestrator | Integration: STATE/ROADMAP/VERSIONING/SPEC + commit 0.4.1 | done | commit `0176f0e`; no push/merge без владельца |

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
- [x] Phase 2: widget (SVG setImage, текст, tooltip, ЛК toggle / ПК панель) + CC shortcut (label/active/enabled, ЛК toggle / ПК refresh)
- [x] Phase 2: `lib/icons.luau` — единственный маппинг phase → SVG/glyph/text + tooltipRows + normalizePhase
- [x] Phase 2: команды через `State.setCommand` (seq=nowMs), UI-энтри без runAsync/http/file reads
- [x] Phase 2: reviewer APPROVE + fix round (setCommand, brand-key, комментарий fileExists)
- [x] Phase 2: QA live PASS — hot-reload, disable/enable, K-02 fallback (одна WRN + glyph), живые клики владельца (source=widget)
- [x] Phase 2: PR #3 merged, tag `v0.3.0`
- [x] Phase 3: панель (заглушка → полная декларативная панель: header, status card, mode/families/protocol, identity, actions, footer), сервис `register` (registration new, 30 с таймаут, `error.register-pending`), `lib/icons.luau` (statusGlyph, phaseColor)
- [x] Phase 3: reviewer fix round (README, футер `warp-cli {version}`, phaseColor → icons, onFamilies render), гейты lint 0/0 + паритет en/ru
- [x] Phase 3: QA live PASS (панель открывается, watch-колбэк чист, register/refresh через IPC без падений), PR #4 merged, bump 0.4.0, CHANGELOG, STATE
- [x] Panel redesign v2 (0.4.1): banner color/idle PNG, phase accents, status-first hero + power, Mode/Protocol side by side, segmented Families, identity card, Copy IP/Settings footer, honest unknown values
- [x] Redesign gates: reviewer APPROVE ×2, lint 0/0, en/ru 99/99, live QA PASS, 8 screenshots в `docs/images/`
- [x] Redesign docs: `docs/DESIGN-PANEL.md`, plugin README Panel rewrite, root README status, CHANGELOG 0.4.1
- [x] Panel redesign v2 закоммичен `0176f0e` на `feat/panel-redesign-v2` (без push/merge/tag)


---

## Known issues

| ID | Description | Severity | Owner |
|----|-------------|----------|-------|
| K-01 | Author handle: локально есть плагины `code_warlord/*`, выбран `code-warlord`; сверить до Phase 5 | minor | orchestrator |
| K-02 | `setImage` со SVG: fallback + одна WRN проверены live (PR #3); **ручной** visual sign-off «SVG виден на баре глазами» за владельцем | minor | owner |
| K-03 | `warp-cli dns families` write-only, геттера нет → `families = unknown` до установки в сессии | known limit | implementer |
| K-04 | Нет локального Luau-тулчейна (`luau`, `luau-analyze`, `selene`) — гейт только lint + runtime-лог | minor | Phase 4 |
| K-05 | Включены конкурирующие `levi/warp` и `code_warlord/warp_toggle` — QA не трогает, фильтрует логи | minor | qa |
| K-06 | `connecting` и `warn` иконки почти неразличимы на 16 px | minor | Phase 3 (design) |
| K-07 | На `5.3.0-1-dirty` `plugins disable` не вызывает Luau `onExit`; acceptance под это поправлен | known limit | docs |
| K-08 | `cdn-cgi/trace` через `noctalia.http` падает бёрстами (`curl=28`, 30s-таймаут, опций нет) — обработано circuit breaker'ом; причина на уровне хоста/WARP-туннеля | known limit | Phase 4 / внешнее |
| K-09 | `warp.command` (state-канал) не имеет CLI-пути записи — в QA проверен только IPC; оба пути сходятся в `dispatch` | minor | qa / Phase 3 |
| K-10 | Параллельная вариация Phase 2 из `~/DEV` (другой fallback с setGlyphColor, решения в SPEC/spec/STATE) перемещена в `git stash@{0}` (main) + бэкап `/tmp/k10-parallel-backup.patch` и `/tmp/k10-icons-backup.luau` перед rebase на PR #3 — сверить и решить: отбросить или переупаковать в docs-decision | major | owner / orchestrator |
| K-11 | Source precedence: `warpqa` (stale worktree 0.4.0) идёт после `warpdev`, поэтому запущенный хост показывает старую панель. QA использует временный trailing source и восстанавливает конфиг; для постоянного показа нужен решение владельца | major | owner / orchestrator |
| K-12 | Host рисует scrollbar даже когда контент помещается (см. `scroll_view.cpp`: visible = showScrollbar); это не переполнение layout, убрать из панели нельзя | minor | host / docs |
| K-13 | `[plugin_settings] panel_placement = "attached"` на dev-хосте переопределяет manifest `floating`; манифест корректен | minor | owner / config |
| K-14 | На dev-хосте нет input-инструментов (ydotool/wtype/dotool), поэтому клики Settings/Refresh/selects проверены review + фикстурами, а не реальными нажатиями | minor | qa |

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
| 2026-10-20 | Bar-иконки: цвета свои, тонировка хостом (`currentColor`) **не** используется; `*.mono.svg` — запасной набор | тонировка хостом не проверена (K-02), мульти-цветные stroke читаемы на обеих темах; моно без тонировки рисовался бы чёрным |
| 2026-10-20 | Panel v2: 360×700, один scroll-body, фиксированный footer | при 680 обрезалась identity card; 700 вмещает все штатные состояния |
| 2026-10-20 | Версия `warp-cli` в панели не показывается | не входит в редизайн-бриф, экономит вертикаль; версия доступна в настройках плагина |
| 2026-10-20 | Unknown в Mode/Protocol = ведущая переведённая опция, offset в onChange | host select всегда выбирает option 0 и не умеет очищать выбор |
| 2026-10-20 | Families segments всегда передают fill/border, unselected — `#00000000` | reconciler сохраняет отсутствующие flex-стили → stale cyan |
| 2026-10-20 | Banner: color/idle PNG с запечённым нижним alpha-fade | у declarative UI нет gradient/overlay primitive |
| 2026-10-20 | Состояния для скриншотов — временные фикстуры, реальный WARP не мутируется | QA safety: connect/disconnect/set-* не трогали |

---

## Quick commands

```bash
# lint (offline author gate)
noctalia plugins lint cloudflare-warp

# plugin sources (later path source wins; check before visual QA)
noctalia msg plugins source list
noctalia msg plugins list | grep cloudflare-warp

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
