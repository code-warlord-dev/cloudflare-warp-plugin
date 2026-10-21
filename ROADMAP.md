# ROADMAP — Cloudflare WARP for Noctalia 5.x

Статус: **Active**

Текущая версия: `0.5.0` (Phase 4, Polish & i18n)

Целевая первая публичная: `1.0.0`

Правила версионирования — см. [VERSIONING.md](./VERSIONING.md).  
Каждый merge в `main` **обязан** bump'нуть версию в `plugin.toml` + запись в `CHANGELOG.md`.

---

## Phase 0 — Bootstrap (v0.1.0)

**Цель:** рабочий каркас плагина, который загружается в Noctalia.

- [x] Создать `cloudflare-warp/` с `plugin.toml`
- [x] Пустые entry: `service.luau`, `widget.luau`, `shortcut.luau`, `panel.luau`
- [x] `lib/` заготовки + `translations/en.json`, `ru.json`
- [x] README с зависимостью `cloudflare-warp`
- [x] Локальный `path`-source + enable
- [x] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`

**DoD:** плагин виден в Settings → Plugins, enable не падает.

**Bump:** `0.1.0` (MINOR — первая структура)

---

## Phase 1 — Service Core (v0.2.0)

**Цель:** единственный источник правды о статусе WARP.

- [x] `lib/parse.luau` — парсинг `warp-cli status`
- [x] `lib/commands.luau` — обёртки `runAsync` (status, connect, disconnect, mode, families, protocol)
- [x] `lib/state.luau` — хелперы чтения/записи `noctalia.state`
- [x] Polling в `update()` + `setUpdateInterval`
- [x] Запись ключей `warp.*` в state
- [x] `onIpc`: `toggle`, `connect`, `disconnect`, `refresh`
- [x] Обработка «command not found» / daemon down / unregistered
- [x] `onConfigChanged` для `poll_interval_ms`
- [x] Notify on change (если setting включён)

**DoD:** `noctalia msg plugin …:service all toggle` реально connect/disconnect; state обновляется.

**Bump:** `0.2.0` (MINOR — core feature)

---

## Phase 2 — Bar Widget + Shortcut (v0.3.0)

**Цель:** видимый статус и быстрый toggle.

- [x] Widget читает state, рисует **SVG** (`setImage`) + text + tooltip
- [x] `assets/icons/warp-{on,off,connecting,warn,error}.svg` + `lib/icons.luau`
- [x] Glyph только как fallback
- [x] `onClick` → cmd queue / IPC toggle
- [x] `onRightClick` → toggle panel
- [x] Compact mode / show_text_in_bar
- [x] Shortcut: checked state + toggle
- [x] Hot-reload `.luau` работает

**DoD:** бар показывает SVG-статус; клик переключает WARP; CC-плитка синхронна.

**Bump:** `0.3.0` (MINOR)

---

## Phase 3 — Panel (v0.4.0 → v0.4.3)

**Цель:** полноценный UI управления.

- [x] Declarative panel UI (banner, header, hero, selectors, actions)
- [x] Mode / Families / Protocol selectors → IPC
- [x] Refresh, Register, Copy IP
- [x] Отображение trace (ip, loc, warp)
- [x] Open plugin settings
- [x] Floating, 400×734, без scroll-контейнера
- [x] Panel redesign v2: phase banner, status-first hero + power, Mode/Protocol в две колонки, segmented Families, identity card, Copy IP/Settings footer, honest unknown
- [x] Owner fix round: full-bleed banner, hero 21 px, Families = Malware default, анимации входа/акцента/progress/refresh/hover, ширина 400
- [x] Side gutters 16 px: root отменяет host-inset 14 px, карточки 368 px (0.4.2)
- [x] Animated banner 160 px: 27 WebP-кадров из `wGjQl.gif`, saturation ramp 20 % → 100 %, нижний alpha-fade, forward/reverse по frame ticks (0.4.3)
- [x] Owner round 2 (0.4.3): ЛКМ = панель / ПКМ = toggle, ember-акцент disconnected, sine-волна в transition, trace-refresh после connect/disconnect
- [x] Fix round 3 (0.4.3): phase hold `connecting`/`disconnecting` до подтверждения поллингом (30 с timeout), trace через argv-`curl` (http-fallback), identity-refresh после mode/protocol
- [x] Live QA connected/disconnected/connecting + 8 screenshots + `docs/DESIGN-PANEL.md`

**DoD:** из панели можно сменить mode/families/protocol и увидеть IP; визуальные состояния подтверждены live.

**Bump:** `0.4.0` (MINOR) + `0.4.1`/`0.4.2`/`0.4.3` (PATCH — redesign v2, owner fix round, боковые поля и анимированный баннер; структура state/IPC не менялись)

---

## Phase 4 — Polish & i18n (v0.5.0)

**Цель:** готовность к community-plugins.

- [x] Полные `en.json` + `ru.json` (паритет 98 ключей, ru без заглушек)
- [x] Все settings schema + label_key (чистка: лишних настроек нет)
- [x] Error UX (daemon, not installed, unregistered) — текст + рекомендация на en/ru
- [x] Auto-trace + interval (уже в core; поведением подтверждён)
- [x] Thumbnail / preview (`thumbnail.webp` 1280×720, 64 KB)
- [x] README (install, IPC examples, known limits) — переписан по коду
- [x] `luau-analyze` clean — N/A: тулчейн локально не установлен (K-04), гейт = lint 0/0

**DoD:** нет hardcoded строк UI; ошибки понятны; docs полные.

**Bump:** `0.5.0` (MINOR)

---

## Phase 5 — Public 1.0.0

**Цель (решение владельца 2026-10-21):** публичный релиз от организации **ModernByte** —
репо `ModernByte/cloudflare-warp` (id `ModernByte/cloudflare-warp`), только пользовательский
контент (EN основной + RU, без dev-артефактов), вики 5×2; PR в `noctalia-dev/community-plugins` —
позже, отдельным одобрением владельца.

- [x] Ребренд id/author в dev-репо (PR #9, `ModernByte/cloudflare-warp`, author `Modern Byte`)
- [x] Публичный репозиторий: public, один чистый commit, tag `v1.0.0`, whitelist-состав, grep-гейт на dev/AI-термины
- [x] README.md (EN) + README.ru.md, user-facing CHANGELOG, LICENSE MIT © Modern Byte
- [x] Каталог-готовность: `thumbnail.webp` в корне плагина
- [~] Вики 5 разделов × 2 языка — страницы смонтированы (`~/DEV/wikistage`), пуш после инициализации wiki-бэкенда владельцем через Web UI
- [ ] Явный список всех `runAsync` и network calls — в README/PR body (в README есть; в upstream PR — при подаче)
- [ ] PR в `noctalia-dev/community-plugins` + прохождение CI (pending owner)

**DoD:** репозиторий организации опубликован и документирован; community-plugins — отдельный gate владельца.

**Bump:** `1.0.0` (MAJOR — первый stable public + ломающая смена id)

---

## Post-1.0 (backlog)

| Идея | Тип | Примечание |
|------|-----|------------|
| WARP+ license UI | MINOR | `warp-cli registration license` |
| Desktop widget | MINOR | optional |
| Launcher provider (`/warp`) | MINOR | quick commands |
| Graph latency / history | MINOR | needs more API |
| Multi-profile / teams | MAJOR | Cloudflare One |

---

## Зависимости между фазами

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4 ──► Phase 5
                │
                └── (lib/* используется всеми)
```

Phase 2 и 3 могут частично идти параллельно после стабилизации service IPC, но merge в main — строго по порядку bump.
