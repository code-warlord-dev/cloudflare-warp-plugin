# ROADMAP — Cloudflare WARP for Noctalia 5.x

Статус: **Active**

Текущая версия: `0.4.2` (Phase 3, panel redesign v2)

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

## Phase 3 — Panel (v0.4.0 → v0.4.2)

**Цель:** полноценный UI управления.

- [x] Declarative panel UI (banner, header, hero, selectors, actions)
- [x] Mode / Families / Protocol selectors → IPC
- [x] Refresh, Register, Copy IP
- [x] Отображение trace (ip, loc, warp)
- [x] Open plugin settings
- [x] Floating, 400×672, без scroll-контейнера
- [x] Panel redesign v2: phase banner, status-first hero + power, Mode/Protocol в две колонки, segmented Families, identity card, Copy IP/Settings footer, honest unknown
- [x] Owner fix round: full-bleed banner, hero 21 px, Families = Malware default, анимации входа/акцента/progress/refresh/hover, ширина 400
- [x] Side gutters 16 px: root отменяет host-inset 14 px, карточки 368 px (0.4.2)
- [x] Live QA connected/disconnected/connecting + 8 screenshots + `docs/DESIGN-PANEL.md`

**DoD:** из панели можно сменить mode/families/protocol и увидеть IP; визуальные состояния подтверждены live.

**Bump:** `0.4.0` (MINOR) + `0.4.1`/`0.4.2` (PATCH — redesign v2, owner fix round и боковые поля; структура state/IPC не менялись)

---

## Phase 4 — Polish & i18n (v0.5.0)

**Цель:** готовность к community-plugins.

- [ ] Полные `en.json` + `ru.json`
- [ ] Все settings schema + label_key
- [ ] Error UX (daemon, not installed, unregistered)
- [ ] Auto-trace + interval
- [ ] Thumbnail / preview
- [ ] README (install, IPC examples, known limits)
- [ ] `luau-analyze` clean

**DoD:** нет hardcoded строк UI; ошибки понятны; docs полные.

**Bump:** `0.5.0` (MINOR)

---

## Phase 5 — Public 1.0.0

**Цель:** PR в `noctalia-dev/community-plugins`.

- [ ] Catalog entry / thumbnail
- [ ] PR по шаблону (см. templates/PR.md)
- [ ] CI `community-plugins` проходит (полная валидация манифеста, переводов, thumbnail)
- [ ] Явный список всех `runAsync` и network calls в PR body
- [ ] Semver `1.0.0`

**DoD:** merged в community-plugins (или готов к merge).

**Bump:** `1.0.0` (MAJOR — первый stable public)

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
