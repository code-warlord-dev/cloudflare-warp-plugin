# ROADMAP — Cloudflare WARP for Noctalia 5.x

Статус: **Active**  
Текущая версия: `0.0.0` (pre-release)  
Целевая первая публичная: `1.0.0`

Правила версионирования — см. [VERSIONING.md](./VERSIONING.md).  
Каждый merge в `main` **обязан** bump'нуть версию в `plugin.toml` + запись в `CHANGELOG.md`.

---

## Phase 0 — Bootstrap (v0.1.0)

**Цель:** рабочий каркас плагина, который загружается в Noctalia.

- [ ] Создать `cloudflare-warp/` с `plugin.toml`
- [ ] Пустые entry: `service.luau`, `widget.luau`, `shortcut.luau`, `panel.luau`
- [ ] `lib/` заготовки + `translations/en.json`, `ru.json`
- [ ] README с зависимостью `cloudflare-warp`
- [ ] Локальный `path`-source + enable
- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`

**DoD:** плагин виден в Settings → Plugins, enable не падает.

**Bump:** `0.1.0` (MINOR — первая структура)

---

## Phase 1 — Service Core (v0.2.0)

**Цель:** единственный источник правды о статусе WARP.

- [ ] `lib/parse.luau` — парсинг `warp-cli status`
- [ ] `lib/commands.luau` — обёртки `runAsync` (status, connect, disconnect, mode, families, protocol)
- [ ] `lib/state.luau` — хелперы чтения/записи `noctalia.state`
- [ ] Polling в `update()` + `setUpdateInterval`
- [ ] Запись ключей `warp.*` в state
- [ ] `onIpc`: `toggle`, `connect`, `disconnect`, `refresh`
- [ ] Обработка «command not found» / daemon down / unregistered
- [ ] `onConfigChanged` для `poll_interval_ms`
- [ ] Notify on change (если setting включён)

**DoD:** `noctalia msg plugin …:service all toggle` реально connect/disconnect; state обновляется.

**Bump:** `0.2.0` (MINOR — core feature)

---

## Phase 2 — Bar Widget + Shortcut (v0.3.0)

**Цель:** видимый статус и быстрый toggle.

- [ ] Widget читает state, рисует **SVG** (`setImage`) + text + tooltip
- [ ] `assets/icons/warp-{on,off,connecting,warn,error}.svg` + `lib/icons.luau`
- [ ] Glyph только как fallback
- [ ] `onClick` → cmd queue / IPC toggle
- [ ] `onRightClick` → toggle panel
- [ ] Compact mode / show_text_in_bar
- [ ] Shortcut: checked state + toggle
- [ ] Hot-reload `.luau` работает

**DoD:** бар показывает SVG-статус; клик переключает WARP; CC-плитка синхронна.

**Bump:** `0.3.0` (MINOR)

---

## Phase 3 — Panel (v0.4.0)

**Цель:** полноценный UI управления.

- [ ] Declarative panel UI (header, status card, selectors, actions)
- [ ] Mode / Families / Protocol selectors → IPC
- [ ] Refresh, Register, Copy IP
- [ ] Отображение trace (ip, loc, warp)
- [ ] Open plugin settings
- [ ] Floating, ~360–420 px

**DoD:** из панели можно сменить mode/families/protocol и увидеть IP.

**Bump:** `0.4.0` (MINOR)

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
