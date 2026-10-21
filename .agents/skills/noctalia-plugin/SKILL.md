---
name: noctalia-plugin
description: Domain knowledge for Noctalia 5.x Luau plugins — manifest, entries, state, IPC, declarative UI, runtime API. Required for implementer, architect, and reviewer on this project.
---

# Noctalia Plugin Skill

Сверено с Noctalia 5.3.0. Подробности и доказательства — `docs/API-NOTES.md`.

## Core facts

- Плагин = каталог с `plugin.toml` + `.luau` entry.
- Entry живут в изолированных Luau VM, вне UI-треда, с бюджетом времени.
- Доверенный код: установка = запуск пользовательского скрипта.
- Hot-reload: `.luau` по сохранению; `plugin.toml` — через `noctalia msg config-reload`.
- `plugin_api` — **самый старый** уровень, покрывающий все возможности. Уровни 3…34.
- Обязательные поля манифеста: `id`, `name`, `version` (`X.Y.Z`), `plugin_api`.

## Этот проект

| Поле | Значение |
|------|----------|
| id / каталог | `ModernByte/cloudflare-warp` / `cloudflare-warp/` |
| `plugin_api` | **24** (модули 22 + argv `runAsync` 24) |
| entries | `service`, `widget`, `shortcut`, `panel` |
| state | `warp.status` (пишет service) / `warp.command` (пишут UI) |

## Entry kinds

| Таблица | Kind | Lifecycle |
|---------|------|-----------|
| `[[service]]` | headless | `update`, `onIpc`, `onConfigChanged`, `onEnable`, `onExit(signal, reason)` |
| `[[widget]]` | bar | `update`, `onClick`, `onRightClick`, `onScroll`, `onIpc` |
| `[[shortcut]]` | control center | `update`, `onClick`, `onRightClick` |
| `[[panel]]` | popup | `onOpen(context)`, `onClose`, `update`, `onIpc` |

Адрес entry: `author/plugin:entry-id`. IPC-target для service — **`all`**.

## State

```luau
noctalia.state.set("warp.status", { phase = "connected", … })  -- одна таблица
noctalia.state.get("warp.status")
noctalia.state.watch("warp.status", function(value) … end)      -- только на изменение
```

- Канал per-plugin, in-memory, переживает рестарт сервиса, не переживает выключение плагина.
- Только plain data. Один ключ = одна таблица (атомарно), не десятки плоских ключей.
- Service — единственный writer `warp.status`; UI — единственный writer `warp.command`.

## Config

```luau
noctalia.getConfig("poll_interval_ms")  -- только объявленные ключи
```

- Plugin-level: `[[setting]]` в корне манифеста (видят все entry).
- Widget presentation: `[[widget.setting]]` (видит только виджет).
- Каждый ключ обязан читаться литералом, иначе `noctalia plugins lint` даст warning.
- `label_key` обязателен; литеральные `label`/`description` отклоняются.

## Subprocess

```luau
noctalia.runAsync({ "warp-cli", "--accept-tos", "--json", "status" }, function(result)
  -- result = { exitCode, stdout, stderr, timedOut, … }
end, 8000)   -- 3-й аргумент: timeout ms (проверено)
```

- argv-форма требует `plugin_api = 24`; shell-строка (`runAsync("cmd")`) — `/bin/sh -c`.
- Любой payload/настройка/путь — только argv, никогда не в shell-строку.
- `commandExists(name)` проверять до запуска.
- `noctalia.http({ url = … }, cb)` → `res = { ok, status, body }`; без timeout.
- `noctalia.json.decode(s)` → `value, err`.

## UI

- Императивный бар: `setImage(path, watch, w, h)`, `setText`, `setGlyph`, `setTooltip`,
  `setGlyphColor`, `setVisible`. После `barWidget.render(tree)` императивные вызовы
  **не работают**.
- Shortcut: `setLabel`, `setIcon(onGlyph, offGlyph)`, `setActive`, `setEnabled` — только glyph.
- Declarative: `ui.column/row/scroll/label/glyph/image/box/button/toggle/select/input/…`.
- `ui.select.onChange` получает **индекс строкой**; `ui.input` — uncontrolled.
- Панель: размер только в манифесте (`width`/`height`), `panel.render` в `onOpen`.
- `openSettings` — 15, `nowMs` — 12, `[widget.actions]` — 14.

## Проверка и IPC

```bash
noctalia plugins lint cloudflare-warp          # НЕ validate-plugin — такой команды нет
noctalia msg plugin ModernByte/cloudflare-warp:service all refresh
noctalia msg panel-toggle ModernByte/cloudflare-warp:panel
tail -f ~/.cache/noctalia/noctalia.log
```

`plugins lint` проверяет только settings ↔ `getConfig` и наличие entry-файлов.
Translations, панельные опции и исполнение кода он не проверяет — гейт это enable + лог.

## Внешние ссылки

- https://docs.noctalia.dev/noctalia/plugins/development/
- официальные референсы: `noctalia/screen_recorder` (service+state), `noctalia/example`
- community-plugins: один плагин на PR, полный список network/process вызовов
