# VERSIONING — Semantic Versioning & Merge Policy

Плагин следует **SemVer 2.0.0**: `MAJOR.MINOR.PATCH`.

Версия живёт **только** в:

1. `cloudflare-warp/plugin.toml` → `version = "X.Y.Z"`
2. `CHANGELOG.md` (запись на каждый релиз)
3. git tag `vX.Y.Z` (создаётся после merge в `main`)

---

## Правила bump

| Изменение | Bump | Пример |
|-----------|------|--------|
| Ломающее изменение API плагина / state keys / IPC events | **MAJOR** | переименование `warp.status` → `warp.connection` |
| Новая функциональность (entry, setting, mode, UI-блок) | **MINOR** | добавлен panel, новый setting |
| Багфикс, i18n fix, docs, refactor без API-change | **PATCH** | парсер status, опечатка в tooltip |
| Только docs / CI / templates в meta-репо | **нет bump плагина** | правки AGENTS.md |

Pre-1.0 (`0.x.y`):

- `0.MINOR.PATCH` — MINOR = фаза roadmap, PATCH = фиксы внутри фазы.
- Первый публичный stable = `1.0.0`.

---

## Обязательный процесс при merge в `main`

1. Ветка feature/fix названа: `feat/…`, `fix/…`, `chore/…`.
2. PR проходит чеклист (templates/PR.md).
3. Перед merge автор **обязан**:
   - определить тип bump по таблице;
   - обновить `version` в `plugin.toml`;
   - добавить секцию в `CHANGELOG.md` (Keep a Changelog);
   - обновить `STATE.md` (текущая версия + статус фазы).
4. Merge commit message содержит `vX.Y.Z`.
5. После merge — tag `vX.Y.Z` и push tags.

**Запрещено** merge в `main` без bump версии плагина (исключение: pure meta-изменения вне `cloudflare-warp/`).

---

## Карта версий (Version Map)

| Версия | Фаза | Содержание | Статус |
|--------|------|------------|--------|
| 0.1.0 | Phase 0 | Bootstrap: manifest, empty entries, i18n stubs | released |
| 0.2.0 | Phase 1 | Service core: poll, state, IPC toggle/connect | released |
| 0.3.0 | Phase 2 | Bar widget + Control Center shortcut | released |
| 0.4.0 | Phase 3 | Full panel UI | released |
| 0.4.1 | Phase 3 | Panel redesign v2 (banner/hero/segmented/identity), no state/IPC change | released |
| 0.4.2 | Phase 3 | Panel side gutters 30 → 16 px, no state/IPC change | released |
| 0.4.3 | Phase 3 | Animated 27-frame panel banner (20–100 % saturation, bottom fade), 400×734 panel, wave transition, LMB panel / RMB toggle, trace refresh on connect, phase hold, argv-curl trace | prepared |
| 0.5.0 | Phase 4 | Polish, full i18n, error UX, README | planned |
| 1.0.0 | Phase 5 | Public release / community-plugins | planned |
| 1.x.y | Post-1.0 | Backlog features | backlog |

При hotfix на уже выпущенную линию: `1.0.1`, `1.0.2`…  
Новая фича после 1.0.0 → `1.1.0`.

---

## Совместимость plugin_api

- Стартовый `plugin_api = 24` (относительные модули — 22, argv-форма `runAsync` — 24).
- Повышение API level = как минимум MINOR, предпочтительно с note в CHANGELOG.
- Не повышать API без реальной необходимости (теряем пользователей на старых Noctalia).
