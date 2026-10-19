# Cloudflare WARP Plugin for Noctalia 5.x

**Спецификация для разработки агентами**

| Поле | Значение |
|------|----------|
| Версия документа | 1.0.0 |
| Целевая платформа | Noctalia ≥ 5.0 (plugin_api = 17+) |
| Язык | Luau |
| Внешняя зависимость | пакет `cloudflare-warp` (`warp-cli`, `warp-svc`) |
| Plugin ID | `community/cloudflare-warp` |
| Каталог | `cloudflare-warp/` |

---

## 1. Цель и философия

Плагин даёт пользователю полный контроль над Cloudflare WARP прямо из оболочки Noctalia:

- статус в баре (иконка + цвет + tooltip);
- быстрый toggle из Control Center;
- полноценная панель с режимами, Families, протоколом и диагностикой;
- фоновый сервис, который держит актуальное состояние и рассылает его всем entry.

Плагин **не** заменяет официальный `warp-taskbar`. Он работает поверх CLI (`warp-cli`) и рассчитан на пользователей, у которых уже установлен `cloudflare-warp`.

---

## 2. Архитектура entry-точек

| Entry ID | Тип | Файл | Назначение |
|----------|-----|------|------------|
| `service` | `[[service]]` | `service.luau` | Единственный источник правды. Поллит `warp-cli`, публикует state, выполняет connect/disconnect/mode. |
| `widget` | `[[widget]]` | `widget.luau` | Bar-виджет. Читает state, рисует SVG-иконку + text, обрабатывает клики. |
| `shortcut` | `[[shortcut]]` | `shortcut.luau` | Плитка в Control Center (toggle). |
| `panel` | `[[panel]]` | `panel.luau` | Детальная панель (режим, Families, протокол, статус, кнопки). |

Рекомендуемый `plugin_api = 17` (нужен `onEnable` / `onExit` / `onConfigChanged` у service).  
При необходимости tooltip на контейнерах — поднять до 32.

Общий state-канал: `noctalia.state` (ключи с префиксом `warp.`).

---

## 3. Внешняя зависимость и команды

### 3.1. Обязательные команды `warp-cli`

| Действие | Команда | Ожидаемый вывод / поведение |
|----------|---------|-----------------------------|
| Статус | `warp-cli status` | `Status update: Connected` / `Disconnected` / `Connecting` / `Unable to connect` |
| Подключить | `warp-cli connect` | |
| Отключить | `warp-cli disconnect` | |
| Режим | `warp-cli mode <mode>` | `warp`, `doh`, `warp+doh`, `proxy`, `tunnel_only` |
| Families | `warp-cli dns families <off\|malware\|full>` | |
| Протокол | `warp-cli tunnel protocol set <WireGuard\|MASQUE>` | |
| Настройки | `warp-cli settings` | Полный dump |
| Регистрация | `warp-cli registration new` / `show` | |
| Trace | `curl -s https://www.cloudflare.com/cdn-cgi/trace` | `warp=on` / `warp=plus` |

Плагин **никогда** не вызывает `sudo`. Если демон не запущен — показывает ошибку.

### 3.2. Парсинг статуса

Сервис запускает `warp-cli status 2>&1` и парсит:

- `Connected` → `connected`
- `Disconnected` → `disconnected`
- `Connecting` / `Reconnecting` → `connecting`
- `Registration missing` / `Not registered` → `unregistered`
- ошибки → `error` + текст

Дополнительно (раз в 30–60 с или по запросу):

```bash
curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E '^(warp|ip|loc)='
```

---

## 4. State-модель (`noctalia.state`)

```luau
noctalia.state.set("warp.status", "connected")       -- connected | disconnected | connecting | unregistered | error | unknown
noctalia.state.set("warp.mode", "warp")
noctalia.state.set("warp.families", "off")           -- off | malware | full
noctalia.state.set("warp.protocol", "MASQUE")        -- WireGuard | MASQUE
noctalia.state.set("warp.error", "")
noctalia.state.set("warp.last_update", noctalia.nowMs())
noctalia.state.set("warp.trace.warp", "on")
noctalia.state.set("warp.trace.ip", "...")
noctalia.state.set("warp.trace.loc", "...")
noctalia.state.set("warp.daemon_ok", true)
```

Widget / shortcut / panel только **читают**.

---

## 5. Функционал по entry

### 5.1. Service

- Top-level: init + `setUpdateInterval(poll_ms)`.
- `update()`: poll status → parse → state → notify on change.
- `onConfigChanged()`: перечитать poll interval.
- `onIpc(event, payload)`: `toggle`, `connect`, `disconnect`, `set-mode`, `set-families`, `set-protocol`, `refresh`, `register`.
- `onEnable()` / `onExit(signal, reason)`.

Все subprocess — через `noctalia.runAsync`. Никогда не блокировать `update()`.

### 5.2. Bar Widget

**Иконки — SVG, не glyph.**  
Причина: бренд Cloudflare/WARP узнаваем; glyph из Tabler не передаёт identity. API: `barWidget.setImage(path [, watch [, width [, height]]])` (путь относительно каталога плагина) или `ui.image` внутри `barWidget.render()`.

| Status | SVG asset | Текст (если `show_text_in_bar`) |
|--------|-----------|----------------------------------|
| connected | `assets/icons/warp-on.svg` | "On" / "WARP" |
| disconnected | `assets/icons/warp-off.svg` | "Off" |
| connecting | `assets/icons/warp-connecting.svg` | "…" |
| unregistered | `assets/icons/warp-warn.svg` | "Reg" |
| error | `assets/icons/warp-error.svg` | "Err" |
| unknown | `assets/icons/warp-off.svg` | "?" |

**Требования к SVG:**

- Монохромные (один `currentColor` / `fill="#fff"`), чтобы хост мог тонировать под тему **или** готовые пары light/dark — на усмотрение implementer.
- ViewBox квадратный (например `0 0 24 24`), без лишних margins.
- Размер в баре: `setImage("assets/icons/….svg", false, 16, 16)` (или scale от bar); не растягивать огромные файлы.
- Лицензия: оригинальный Cloudflare mark только если разрешено ToS; иначе **stylized WARP mark** собственной отрисовки (щит/облако/дуга), без копирования proprietary logo 1:1. Зафиксировать в README.

**Fallback:** если SVG не загрузился — `barWidget.setGlyph("cloud-lock")` + log.

- `onClick()` → command queue / IPC toggle
- `onRightClick()` → `noctalia.togglePanel("community/cloudflare-warp:panel")`
- Tooltip: status, mode, families, ip, error

### 5.3. Control Center Shortcut

- `checked` = (status == "connected")
- `onClick()` → toggle

### 5.4. Panel

Декларативный UI:

1. Header — статус + Connect/Disconnect
2. Status card — mode, families, protocol, IP, loc
3. Mode selector
4. Families selector
5. Protocol selector
6. Actions: Refresh, Register, Copy IP, Open Settings
7. Footer — версия / docs

Все действия → IPC к service.

---

## 6. Настройки

| key | type | default | Описание |
|-----|------|---------|----------|
| `poll_interval_ms` | int | 3000 | Интервал опроса (min 1000) |
| `notify_on_change` | bool | true | Notify connect/disconnect |
| `notify_on_error` | bool | true | Notify errors |
| `auto_trace` | bool | true | Периодический cdn-cgi/trace |
| `trace_interval_s` | int | 60 | Интервал trace |
| `show_text_in_bar` | bool | true | Текст рядом с иконкой |
| `compact_mode` | bool | false | Только иконка |

---

## 7. Манифест (каркас)

```toml
id           = "community/cloudflare-warp"
name         = "Cloudflare WARP"
version      = "0.1.0"
plugin_api   = 17
author       = "community"
license      = "MIT"
icon         = "cloud-lock"   # catalog glyph only; bar uses SVG assets
description  = "Control Cloudflare WARP from the bar, control center and a dedicated panel."
tags         = ["network", "vpn", "privacy", "cloudflare"]
dependencies = ["cloudflare-warp"]

[[service]]
id    = "service"
entry = "service.luau"

[[widget]]
id    = "widget"
entry = "widget.luau"
  [widget.actions]
  right = "none"

[[shortcut]]
id    = "shortcut"
entry = "shortcut.luau"

[[panel]]
id    = "panel"
entry = "panel.luau"
```

---

## 8. Структура директории

```
cloudflare-warp/
├── plugin.toml
├── service.luau
├── widget.luau
├── shortcut.luau
├── panel.luau
├── lib/
│   ├── parse.luau
│   ├── commands.luau
│   ├── state.luau
│   └── icons.luau          # map status → asset path + setImage helper
├── translations/
│   ├── en.json
│   └── ru.json
├── assets/
│   └── icons/
│       ├── warp-on.svg
│       ├── warp-off.svg
│       ├── warp-connecting.svg
│       ├── warp-warn.svg
│       └── warp-error.svg
└── README.md
```

---

## 9. UI/UX

1. Бар — минимальный footprint; в compact только SVG-иконка (без текста).
2. Иконки — **SVG assets**, не Tabler glyph (см. §5.2). Glyph только fallback и catalog `icon`.
3. Цвета текста/tooltip — роли палитры; SVG по возможности монохром + tint, либо отдельные on/off варианты.
4. Control Center shortcut — та же SVG-пара (on/off) + checked state.
5. Панель ~360–420 px, floating, `layer = "top"`; в header можно тот же SVG крупнее.
6. Tooltip всегда информативен.

---

## 10. IPC-контракт

```bash
noctalia msg plugin community/cloudflare-warp:service all toggle
noctalia msg plugin community/cloudflare-warp:service all refresh
noctalia msg plugin community/cloudflare-warp:service all set-mode "warp+doh"
noctalia msg panel-toggle community/cloudflare-warp:panel
```

---

## 11. Риски

| Риск | Митигация |
|------|-----------|
| Формат `warp-cli` меняется | Толерантный парсер, fallback `unknown` |
| Демон не запущен | Чёткое сообщение |
| Не зарегистрирован | Отдельный status + Register |
| Proxy-mode | Не форсировать full-tunnel |
| Trusted code | Явно документировать все runAsync / network |

---

## 12. Ссылки

- https://docs.noctalia.dev/noctalia/plugins/development/
- https://docs.noctalia.dev/noctalia/plugins/development/manifest/
- https://docs.noctalia.dev/noctalia/plugins/development/entries/
- https://docs.noctalia.dev/noctalia/plugins/development/runtime-api/
- https://docs.noctalia.dev/noctalia/plugins/development/declarative-ui/
- https://github.com/noctalia-dev/official-plugins
- https://developers.cloudflare.com/warp-client/get-started/linux/
