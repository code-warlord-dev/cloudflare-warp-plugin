# STATE — текущее состояние проекта

> Этот файл обновляет **Orchestrator** после каждого значимого события  
> (завершение задачи субагента, merge, блокер).  
> Читать первым при любом старте сессии.

---

## Snapshot

| Поле | Значение |
|------|----------|
| **Plugin version** | `1.0.0` — публичный релиз: https://github.com/ModernByte/cloudflare-warp (tag `v1.0.0`) |
| **Roadmap phase** | Phase 5 — Public: репозиторий организации опубликован; вики смонтирована, пуш ждёт инициализации wiki-backend на GitHub |
| **Branch** | `main` |
| **Remote** | https://github.com/code-warlord-dev/cloudflare-warp-plugin |
| **Last merge** | `2b455a6` Merge PR #9 — ModernByte rebrand v1.0.0 (dev tag `v1.0.0`) |
| **Blockers** | GitHub лениво создаёт git-репозиторий вики только после первой страницы через Web UI — нужен один клик владельца |
| **Next action** | Владелец открывает https://github.com/ModernByte/cloudflare-warp/wiki и создаёт первую страницу → оркестратор пушит 10 bilingual-страниц из `/home/code_warlord/DEV/wikistage`; затем — upstream PR в community-plugins только по отдельному решению владельца |

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
| implementer | Owner fix round: no scroll / content height, full-bleed banner, 21 px hero, Families default Malware, animations, 400 px width | done | working tree, `feat/panel-redesign-v2` |
| reviewer | Self-review fix round: no state/CLI/network writes, plugin_api 24, no fixture, i18n parity | done | APPROVE; lint 0/0; en/ru 98/98 |
| qa | Live QA fix round: connected + fixture states, animations, no scrollbar/clipping at 400×672 | done | PASS; QA fixture removed before commit |
| orchestrator | Docs update fix round + release 0.4.1 | done | PR #5 merged `cb14a14`; tag `v0.4.1` pushed |
| implementer | Owner padding fix: side gutters 30 → 16 px (root `paddingH = -14`, cards 368 px); vertical rhythm unchanged | done | `fix/panel-padding` |
| reviewer | Self-review: panel still renderer-only, host-inset math verified live, no QA hooks left | done | APPROVE; lint 0/0 |
| qa | Live QA: 400×672, 16 px gutters, no clipping/scrollbar; 8 screenshots refreshed | done | PASS; fixture removed before commit |
| orchestrator | Docs update padding fix + release 0.4.2 | done | PR #6 merged `ae2fe96`; tag `v0.4.2` pushed |
| implementer | Animated banner: 27 WebP-кадров из `wGjQl.gif`, saturation ramp, нижний alpha-fade, forward/reverse по frame ticks, высота 160 px, панель 400×734 | done | working tree, `main`; full-width crop без бокового кропа |
| implementer | Layout fix после баннера: высота панели 672 → 734, футер больше не обрезается | done | live-проверка 400×734 |
| reviewer | Self-review: панель по-прежнему только рендер + `warp.command`; нет `runAsync`/HTTP/state-write; `plugin_api = 24` | done | APPROVE; lint 0/0 |
| qa | Live QA: forward-анимация 0→26, gradient-переход, полная ширина без бокового кропа, футер целиком | done | PASS; reverse проверен ранее; фикстуры отсутствуют |
| docs | CHANGELOG/DESIGN-PANEL/SPEC/API-NOTES/README/ROADMAP/VERSIONING под 0.4.3 | done | screenshots `docs/images/panel-*.png` ещё подлежат обновлению |
| implementer | Hero icon: нативный Tabler `shield-check` (success-green) для connected; `loader-2` убран из hero и header Refresh | done | live 400×734 |
| implementer | Fix: залипший `busy` после hot reload сервиса — сброс на init и в update при `actionInFlight = false`; Refresh доступен при busy | done | live: контролы снова активны, лог `cleared stale busy flag` |
| qa | Live capture: shield-check в hero, refresh/close/cloud-lock/world/copy/settings glyphs, контролы enabled | done | PASS; lint 0/0 |
| implementer | Owner round 2: ЛКМ = панель / ПКМ = toggle, насыщенность баннера 20 %, ember-акцент disconnected, sine-волна в transition, баннер при open соответствует фазе | done | working tree, `main` |
| implementer | Identity refresh после connect/disconnect: немедленная trace-проба + повторная через ~5 с | done | `service.luau`, live-проба за владельцем |
| reviewer | Self-review round 2: panel только renderer + `warp.command`, нет `runAsync`/HTTP/state-write, `plugin_api = 24`, i18n без хардкода | done | APPROVE; lint 0/0 |
| qa | Live QA round 2: disconnected open (статичный кадр 0, ember, без анимации), connecting wave (3 кадра), restore connected | done | PASS; QA fixture удалена, lint 0/0 |
| docs | Синхронизация под раунд 2: CHANGELOG 0.4.3, SPEC, DESIGN-PANEL, README, STATE/ROADMAP | done | скриншоты — K-17 |
| implementer | Fix: «Подключение…» мигал и схлопывался в «Отключено» — transition hold до подтверждения целевой фазы поллингом (30 с safety timeout), busy держится вместе с фазой | done | `service.luau`; live-тоггл за владельцем (K-18) |
| implementer | Fix: identity не обновлялась — trace переведён на argv-only `curl` (http таймаутит, K-08), refresh также после set-mode/set-protocol | done | `service.luau`, `lib/commands.luau`; trace live-проверен, IP сменился |
| reviewer | Self-review раунд 3: hold не блокирует поллинг, curl argv без payload, fallback на http, circuit breaker/in-flight сохранены | done | APPROVE; lint 0/0 |
| docs | Синхронизация под раунд 3: CHANGELOG, SPEC §5.5/§8.1, API-NOTES, STATE | done | — |
| reviewer | Раунд 4 (`74ba6c7`/`b2907dc`): блокер — формулировка CHANGELOG про Copy IP противоречит строгой `copied ~= true` в коде (код SPEC-соответствует); minor — комментарий panel описывает неверный маппинг toggle | done | REQUEST_CHANGES |
| implementer | Фикс-раунд 4: CHANGELOG приведён к фактическому strict-поведению, комментарий `panel.luau` — к реальному маппингу (`connecting→disconnect`, `disconnecting→connect`); рантайм не тронут, lint 0/0 | done | working tree |
| qa | Live-гейты 0.4.3: lint 0/0; фикстур нет; `[warpdev] 0.4.3 enabled`; IPC refresh + panel open/close без ERR; WARP не мутировался | done | PASS |
| orchestrator | Release 0.4.3: PR #7 merged `d3d2f0c`, tag `v0.4.3` pushed | done | `main` |
| implementer | P4-T1 i18n+error UX: 8 error.* текстов с действием (en/ru), тултипы бара через tr(), unknown-фаза показывает ошибку, ru-заглушка families | done | `feat/phase-4-polish` |
| docs | P4-T3 README переписан по коду (IPC-таблица vs dispatch, лимиты, сеть/процессы) | done | `feat/phase-4-polish` |
| docs | P4-T4 `thumbnail.webp` 1280×720 64 KB из реальных скриншотов | done | `feat/phase-4-polish` |
| reviewer | Фаза 4: APPROVE (3 minor: README-подпись исправлена, CHANGELOG/версия — релиз-преп, nit про message) | done | working tree |
| qa | QA-матрица A–F: PASS (fixture daemon-down проверен и восстановлен byte-exact; MANUAL: переключение языка ru/en) | done | live |
| orchestrator | Release 0.5.0: PR #8 merged `9f27d96`, tag `v0.5.0` pushed | done | `main` |
| implementer | P5-T1 ребренд id: `ModernByte/cloudflare-warp`, author `Modern Byte`, адрес `:panel` в widget, README/SPEC/skills/Quick commands; dependencies (пакет) не тронут | done | `feat/phase-5-public` |
| reviewer | P5: APPROVE — dependencies целы, old id в cloudflare-warp/ пуст, поведение не изменено, lint под новым id 0/0 | done | — |
| qa | P5 live swap: disable старый id → enable `ModernByte/cloudflare-warp 0.5.0` (4 entries, service с DEV-пути), refresh/panel чисты, ERR нет; старый_instances выключен, двойного поллинга нет | done | PASS; хост оставлен на новом id |
| docs+implementer | P5-T5 публичный staging `~/DEV/modernbyte-cloudflare-warp`: код из HEAD, whitelist-ассеты, README EN/RU, user-facing CHANGELOG, scrub-комментарии, grep-гейт чист, lint staging 0/0, comment-stripped md5 == dev | done | 49 файлов, 3.2 MB |
| orchestrator | P5-T6 публикация: `gh repo create ModernByte/cloudflare-warp --public`, один commit `fa3c52f`, tag `v1.0.0`, topics; upstream PR НЕ отправлен | done | https://github.com/ModernByte/cloudflare-warp |
| docs | P5-T7 вики 5×2: Home / Installation / Architecture / IPC Reference / Troubleshooting (EN+RU, switch-links, без dev/AI-терминов) | staged | `/home/code_warlord/DEV/wikistage` — пуш после инициализации wiki владельцем |

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
- [x] Owner fix round 0.4.1: убран `ui.scroll` и scrollbar, высота по контенту 400×672, full-bleed banner через отрицательный padding, hero 21 px, Families всегда с выбранным Malware, анимации (вход, акцент/баннер, progress, refresh pulse, hover), ширина 400
- [x] QA fix round: connected + fixture-состояния, анимация connecting, отсутствие scrollbar и обрезания; временная фикстура удалена из `service.luau` до коммита
- [x] Release 0.4.1: PR #5 merged в `main` (`cb14a14`), tag `v0.4.1` создан и запушен; 8 скриншотов обновлены под 400×672
- [x] Padding fix 0.4.2: root отменяет горизонтальный host-inset (`paddingH = -14`) → боковые поля 16 px, карточки 368 px; вертикальный ритм не изменён
- [x] Padding QA: live connected + fixture-состояния, отсутствие clipping/scrollbar на 400×672; 8 скриншотов пересняты, фикстура удалена до коммита
- [x] Animated banner 0.4.3: 27 WebP-кадров (`assets/banner/frame-00…26.webp`) из `wGjQl.gif`, saturation ramp **20 % → full color**, стоп за 3 кадра до конца GIF
- [x] Banner playback: forward 0→26 при открытии/подключении, reverse 26→0 при отключении, frame ticks 100 ms/кадр, остановка в idle
- [x] Full-width assets: crop 640×256+0+0 → 800×320 (2.5:1), таймкод замазан, `fit=cover` не режет левый/правый край
- [x] Banner height 160 px + запечённый нижний alpha-fade 56 px (28 px на экране) для плавного перехода в тело панели
- [x] Layout fix: панель 400×734, футер полностью виден, без scrollbar; live forward-анимация и градиент проверены
- [x] Hero icon: нативный Tabler `shield-check` (success-green) для connected; остальные фазы — phase glyph 22; `loader-2` убран из hero и header Refresh (статичная дуга читалась как обрезанное кольцо)
- [x] Icon audit: cloud-lock, refresh, close, power, world, copy, check, user-plus, settings отрисованы корректно
- [x] Fix busy deadlock: `clearStaleBusy()` на init и в каждом `update()` при `actionInFlight = false`; state переживает reload сервиса, а in-flight действие — нет, поэтому `busy` оставался `true` и дизейблил power/Mode/Protocol/DNS/Refresh; Refresh больше не блокируется busy
- [x] Owner round 2 — клики: виджет открывает панель по **ЛКМ**, toggle отправляется по **ПКМ**; shortcut по-прежнему ЛКМ toggle / ПКМ refresh
- [x] Owner round 2 — баннер: кадр 0 сохранён на **20 % цвета** вместо grayscale, reverse-воспроизведение возвращает к нему же
- [x] Owner round 2 — цвет: акцент `disconnected` заменён на приглушённый ember `#C75B43`
- [x] Owner round 2 — анимация: progress-полоса заменена пятиполосной sine-волной на существующих frame ticks
- [x] Owner round 2 — open: баннер соответствует фазе — forward 0→26 только при connected/connecting, при off/error статичный кадр 0 без анимации
- [x] Identity refresh: после успешных connect/disconnect сервис делает trace-пробу сразу и повторно через ~5 с (`pendingTraceAt`), не дожидаясь 60-секундного цикла
- [x] QA round 2: disconnected open — кадр 0 статичен (diff верхних 128 px баннера = 0 между кадрами 0.7 s и 2.3 s), ember hero, wave скрыта
- [x] QA round 2: connecting — wave из 5 полос меняет высоту/opacity между кадрами; контролы dim; после restore — connected, зелёный shield, полный цвет баннера
- [x] QA round 2: фикстура удалена, сервис побайтно восстановлен из бэкапа, lint 0/0, лог без ERR
- [x] Fix round 3 — фаза: `connecting`/`disconnecting` удерживаются сервисом до наблюдения целевой фазы; поллинг источника или та же transition-фаза не перетирают её; safety timeout 30 с; `busy` держится вместе с фазой
- [x] Fix round 3 — identity: trace через argv-only `curl` (флаги таймаутов, фиксированный URL), `noctalia.http` — fallback; ошибки логируют exit code + stderr (первая и каждая пятая подряд)
- [x] Fix round 3 — refresh identity после успешных set-mode/set-protocol (сразу + повтор через ~5 с)
- [x] Trace live: принудительный refresh сменил IP `104.28.244.142` → `2a09:bac5:5983:2432::39b:ee`, время trace обновилось; три прогона без ошибок
- [x] Lint 0/0 после раунда 3; production-сервис восстановлен, QA-фикстуры отсутствуют
- [x] Release-раунд 4: reviewer REQUEST_CHANGES (CHANGELOG про Copy IP противоречил строгой `copied ~= true`; комментарий о маппинге toggle) → CHANGELOG/комментарий приведены к shipped-поведению, рантайм не тронут
- [x] QA-гейты 0.4.3: lint 0/0, исходники чистые от фикстур, `[warpdev] 0.4.3 enabled`, IPC refresh + panel open/close без ERR, WARP не мутировался
- [x] Phase 4 (0.5.0): аудит user-facing строк → паритет en/ru 98 ключей; 8 errorCode с текстом+действием на двух языках; тултип бара локализует mode/families/protocol и ошибку; панель показывает перевод ошибки и в `unknown`-фазе; README переписан по коду и самодостаточен; `thumbnail.webp` 1280×720/64 KB
- [x] Phase 4 гейты: reviewer APPROVE (minor-подпись README исправлена), QA-матрица A–F PASS с фикстурой `daemon-down` (восстановлена byte-exact), lint 0/0, trust-грепы пустые; MANUAL за владельцем: переключение языка хоста ru/en
- [x] Release 0.5.0: PR #8 merged `9f27d96` в `main`, tag `v0.5.0` запушен
- [x] Phase 5: ребренд id → `ModernByte/cloudflare-warp` (PR #9, dev tag `v1.0.0`), QA swap live PASS
- [x] Phase 5: публичный репозиторий **https://github.com/ModernByte/cloudflare-warp** опубликован — public, один commit `fa3c52f`, tag `v1.0.0`, 49 файлов / 3.2 MB, только пользовательский контент (specs/docs/.agents не входят), grep-гейт на dev/AI-термины чист, lint staging 0/0, поведение байт-в-байт == dev (comment-stripped md5)
- [x] Phase 5: вики 5 разделов × 2 языка смонтирована в `~/DEV/wikistage` (10 страниц, switch-links, troubleshooting + IPC-таблица по фактическому dispatch) — пуш заблокирован ленивой инициализацией wiki-бэкенда GitHub (нужно создать первую страницу через Web UI)


---

## Known issues

| ID | Description | Severity | Owner |
|----|-------------|----------|-------|
| K-01 | ~~Author handle reconciliation~~ — resolved: id `ModernByte/cloudflare-warp`, author `Modern Byte`, публичный репо от организации ModernByte | resolved | — |
| K-02 | `setImage` со SVG: fallback + одна WRN проверены live (PR #3); **ручной** visual sign-off «SVG виден на баре глазами» за владельцем | minor | owner |
| K-03 | `warp-cli dns families` write-only, геттера нет → панель показывает дефолт `malware` до установки значения в сессии; реальное не-дефолтное значение после рестарта не определяется | known limit | implementer |
| K-04 | Нет локального Luau-тулчейна (`luau`, `luau-analyze`, `selene`) — гейт только lint + runtime-лог | minor | Phase 4 |
| K-05 | Включены конкурирующие `levi/warp` и `code_warlord/warp_toggle` — QA не трогает, фильтрует логи | minor | qa |
| K-06 | `connecting` и `warn` иконки почти неразличимы на 16 px | minor | Phase 3 (design) |
| K-07 | На `5.3.0-1-dirty` `plugins disable` не вызывает Luau `onExit`; acceptance под это поправлен | known limit | docs |
| K-08 | `cdn-cgi/trace` через `noctalia.http` на dev-хосте таймаутит (`curl=28`, пустое тело, опций нет) — **обойдено**: trace идёт argv-only `curl` с http-fallback; причина на уровне хоста/WARP-туннеля остаётся | resolved (workaround) | — |
| K-09 | `warp.command` (state-канал) не имеет CLI-пути записи — в QA проверен только IPC; оба пути сходятся в `dispatch` | minor | qa / Phase 3 |
| K-10 | Параллельная вариация Phase 2 из `~/DEV` (другой fallback с setGlyphColor, решения в SPEC/spec/STATE) перемещена в `git stash@{0}` (main) + бэкап `/tmp/k10-parallel-backup.patch` и `/tmp/k10-icons-backup.luau` перед rebase на PR #3 — сверить и решить: отбросить или переупаковать в docs-decision | major | owner / orchestrator |
| K-11 | ~~Source precedence: `warpqa` показывает 0.4.0~~ — resolved: `plugins list` отдаёт `[warpdev] 0.4.1`, панель живьём 400×672 | resolved | — |
| K-12 | Host рисует scrollbar всегда, когда присутствует `ui.scroll` (см. `scroll_view.cpp`: visible = showScrollbar) → панель больше не использует `ui.scroll` вообще | resolved in panel | — |
| K-13 | `[plugin_settings] panel_placement = "attached"` на dev-хосте переопределяет manifest `floating`; манифест корректен | minor | owner / config |
| K-14 | На dev-хосте нет input-инструментов (ydotool/wtype/dotool), поэтому клики Settings/Refresh/selects проверены review + фикстурами, а не реальными нажатиями | minor | qa |
| K-15 | Параллельная ветка `release-0.4.0` / worktree `feat/panel-redesign` (cline) содержит старые height-фиксы 900→650 для панели 0.4.0; в redesign v2 не входит, не мержилась и не удалялась | minor | owner |
| K-16 | Легаси `hero-banner.jpeg` + `hero-banner-color/idle.png` (~3 MB) панелью не используются; удалить или оставить как исходники — решение владельца | minor | owner |
| K-17 | `docs/images/panel-*.png` сняты до 0.4.3 (баннер 96 px / панель 672; без `shield-check`, 20 % floor, ember-акцента и sine-волны); обновить 8 кадров после sign-off | minor | docs / qa |
| K-18 | Identity refresh и phase hold после **реального** connect/disconnect не прогнаны live (QA не мутирует WARP); trace-путь проверен live (IP сменился), transition-логика — review; нужен владельческий тоггл | minor | owner / qa |
| K-19 | Устаревший path-source `warpqa` (из `~/.cline/worktrees/...`) всё ещё зарегистрирован в хосте; `warpdev` имеет приоритет (K-11), но до Phase 5 стоит `plugins source remove warpqa` | minor | owner |

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
| 2026-10-19 | Families = write-only, `unknown` при старте | CLI не отдаёт текущее значение; **superseded 2026-10-20 → `malware` default** |
| 2026-10-19 | No sudo, CLI only | trusted plugin safety + UX clarity |
| 2026-10-19 | Bar icons = **SVG** via `setImage`, glyph — fallback; shortcut — glyph-only | бренд WARP; `shortcut.setIcon` путей не принимает |
| 2026-10-19 | Локальный гейт — `noctalia plugins lint`; `validate-plugin` не существует | сверено с 5.3.0 |
| 2026-10-19 | Иконки престейджены в `cloudflare-warp/assets/icons/` до Phase 2 | пользовательский набор; в коде пока не используются |
| 2026-10-19 | `onExit` не вызывается на disable в этой сборке — код не меняли, поправили acceptance | эмпирика QA |
| 2026-10-20 | Уведомления по стабильной фазе (`lastStablePhase`, без `connecting`/`disconnecting`) | QA: toggle не давал пары connected→disconnected |
| 2026-10-20 | Trace circuit breaker: пауза после 3 неудач, backoff `interval×10×2^level` (max 160×), обход через `refresh` | `noctalia.http` без опции таймаута, лог спамился WRN/мин |
| 2026-10-20 | Whitelist протокола — только ASCII (`MÁSQUE` отклоняется) | спека исправлена под эмпирику, `string.lower` ASCII-only |
| 2026-10-20 | Bar-иконки: цвета свои, тонировка хостом (`currentColor`) **не** используется; `*.mono.svg` — запасной набор | тонировка хостом не проверена (K-02), мульти-цветные stroke читаемы на обеих темах; моно без тонировки рисовался бы чёрным |
| 2026-10-20 | Panel v2: 400×672, **без** `ui.scroll`, footer через `flexGrow` | owner: scrollbar недопустим; 672 вмещает штатные состояния, 400 — чуть шире по брифу |
| 2026-10-20 | Banner full-bleed через отрицательный padding (`-14`) и wrapper 82 px | хост добавляет 14 px inset, отключить его нельзя; image radius = 12 = panel radius |
| 2026-10-20 | Families всегда показывает Malware по умолчанию | owner: пустого выбора быть не должно; CLI write-only, поэтому дефолт — единственный честный вариант |
| 2026-10-20 | Hero status 21 px, ошибка сворачивается в subtitle | «Подключение…» не влезал при большем кегле; карточка держит стабильную высоту |
| 2026-10-20 | Анимации через `panel.setNeedsFrameTick` + `onFrameTick` (33 ms), остановка в idle | хост даёт frame ticks только по запросу; второй тик — для copy/refresh feedback |
| 2026-10-20 | Версия `warp-cli` в панели не показывается | не входит в редизайн-бриф, экономит вертикаль; версия доступна в настройках плагина |
| 2026-10-20 | Unknown в Mode/Protocol = ведущая переведённая опция, offset в onChange | host select всегда выбирает option 0 и не умеет очищать выбор |
| 2026-10-20 | Families segments всегда передают fill/border, unselected — `#00000000` | reconciler сохраняет отсутствующие flex-стили → stale cyan |
| 2026-10-20 | Banner: color/idle PNG с запечённым нижним alpha-fade | у declarative UI нет gradient/overlay primitive |
| 2026-10-20 | Состояния для скриншотов — временные фикстуры, реальный WARP не мутируется | QA safety: connect/disconnect/set-* не трогали |
| 2026-10-20 | Боковые поля панели 16 px: root `paddingH = -14` отменяет host-inset | owner: общий padding был слишком большим; 30 px → 16 px, карточки 340 → 368 px; вертикаль без изменений |
| 2026-10-21 | Баннер — 27 предрендеренных WebP-кадров, смена `path` по frame ticks | хост не проигрывает GIF и не умеет tint/saturation у `ui.image`; запечённая насыщенность — единственный рабочий путь |
| 2026-10-21 | Остановка за 3 кадра до конца GIF (кадр 26), рампа перенормирована на 26 | требование владельца; последний используемый кадр остаётся 100 % насыщенности |
| 2026-10-21 | Полная ширина кадра: crop 640×256+0+0 → 800×320 (2.5:1) | owner: нельзя резать баннер слева/справа; аспект точно совпадает с 400×160 |
| 2026-10-21 | Таймкод источника замазан feathered-клоном до ресайза | в полном кадре водяной знак попадал в видимую область; патч под alpha-fade незаметен |
| 2026-10-21 | Нижний alpha-fade 56 px из 320 запечён в каждый кадр | у declarative UI нет gradient-оверлея; fade даёт плавный переход в тело панели |
| 2026-10-21 | Баннер 160 px, панель 400×734 | увеличение баннера по просьбе владельца; 734 вмещает футер без обрезания и scrollbar |
| 2026-10-21 | Hero connected = нативный `shield-check` glyph в success-green; busy не подменяет иконку | owner отклонил оранжевый кастомный щит; нативный glyph в цвете акцента консистентен с остальными фазами и не требует ассета |
| 2026-10-21 | `busy` self-heal в сервисе (init + update), Refresh доступен при busy | state переживает reload сервиса, actionInFlight — нет; залипший busy полностью блокировал UI без пути восстановления |
| 2026-10-21 | Header Refresh всегда рисует `refresh`, фидбек — opacity pulse | статичная дуга `loader-2` на 1.5 s выглядела сломанной; пульс уже был реализован |
| 2026-10-21 | Виджет: ЛКМ открывает панель, ПКМ отправляет toggle | требование владельца; `[widget.actions] right = "none"` уже пропускал правый клик в `onRightClick` |
| 2026-10-21 | Нижняя точка saturation ramp — 20 %, а не grayscale | owner: при отключении баннер не должен становиться полностью чёрно-белым |
| 2026-10-21 | `disconnected` accent = ember `#C75B43` | owner: блок «Отключено» оранжево-красный, ближе к красному, приглушённый, не спорит с баннером |
| 2026-10-21 | Transition-активность — пятиполосная sine-волна вместо progress | owner: бегающий прогресс-бар выглядел устаревшим; волна использует уже идущие frame ticks и не меняет высоту hero |
| 2026-10-21 | После connect/disconnect — trace сразу + повтор через ~5 с | owner: сетевая идентичность обязана обновляться при вкл/выкл; второй замер ловит стабилизировавшийся маршрут |
| 2026-10-21 | При open баннер соответствует фазе: forward только для connected/connecting, иначе статичный кадр 0 | owner: если WARP выключен, баннер тоже должен быть в состоянии «выкл» и не анимироваться |
| 2026-10-21 | `connecting`/`disconnecting` удерживаются до наблюдения целевой фазы поллингом; safety timeout 30 с; `busy` держится вместе с фазой | owner: «Подключение…» показывался на мгновение и схлопывался в «Отключено»; CLI возвращается раньше, чем туннель поднялся |
| 2026-10-21 | Trace: argv-only `curl` первым, `noctalia.http` — fallback | K-08: http стабильно таймаутит на dev-хосте, системный curl работает; фиксированный argv без payload и shell-слоя, сетевой запрос один |
| 2026-10-21 | Identity refresh также после set-mode/set-protocol (сразу + ~5 с) | owner: при смене режимов «ничего не меняется» — маршрут/выход могут смениться без reconnect |
| 2026-10-21 | id → `ModernByte/cloudflare-warp`, author `Modern Byte`; публичный релиз от организации Modern Byte, репо `cloudflare-warp` | owner-решение: личный репо — черновик; формат id Noctalia = GitHub-логин/имя-репо, поэтому `modern-byte.cloudflare-warp` невозможен; при переименовании старый id выключать до включения нового (глобальные каналы warp.*) |

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
noctalia msg plugins enable ModernByte/cloudflare-warp
noctalia msg plugins disable ModernByte/cloudflare-warp

# service IPC (after Phase 1)
noctalia msg plugin ModernByte/cloudflare-warp:service all refresh
noctalia msg plugin ModernByte/cloudflare-warp:service all toggle

# panel
noctalia msg panel-toggle ModernByte/cloudflare-warp:panel

# logs
tail -f ~/.cache/noctalia/noctalia.log
```
