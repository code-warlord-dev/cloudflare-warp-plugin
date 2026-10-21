# Cloudflare WARP Plugin for Noctalia 5.x

**Спецификация для разработки агентами**

| Поле | Значение |
|------|----------|
| Версия документа | 2.0.0 (сверено с Noctalia 5.3.0) |
| Целевая платформа | Noctalia 5.x; проверено на `v5.3.0` (`plugin_api = 24`) |
| Язык | Luau |
| Внешняя зависимость | пакет `cloudflare-warp` (`warp-cli`, `warp-svc`) |
| Plugin ID | `code-warlord/cloudflare-warp` |
| Каталог | `cloudflare-warp/` |
| Аудит API | [API-NOTES.md](./API-NOTES.md) — обязателен к прочтению |

---

## 1. Цель и философия

Плагин даёт пользователю полный контроль над Cloudflare WARP прямо из оболочки Noctalia:

- статус в баре (SVG-иконка + текст + tooltip);
- быстрый toggle из бара и Control Center;
- панель с режимами, Families, протоколом, регистрацией и сетевой идентичностью;
- фоновый сервис — единственный источник правды о состоянии WARP.

Плагин **не** заменяет официальный `warp-taskbar` и работает поверх CLI (`warp-cli`) у
пользователей, у которых уже установлен `cloudflare-warp`.

**Позиционирование против `levi/warp`** (единственный конкурирующий плагин, v1.2.0):
Families, tunnel protocol setter, состояние регистрации, egress-идентичность
(`ip` / `loc` / `colo` / `warp=on|plus`), полная локализация en+ru, SVG-иконки состояния,
argv-форма `runAsync` (без shell). Телеметрия туннеля (latency, loss, TLS, bytes) в scope
не входит — это сильная сторона `levi/warp`. Подробное сравнение: API-NOTES §13.

---

## 2. Архитектура entry-точек

| Entry ID | Тип | Файл | Назначение |
|----------|-----|------|------------|
| `service` | `[[service]]` | `service.luau` | Единственный источник правды: поллит `warp-cli`, публикует `warp.status`, потребляет `warp.command`. |
| `widget` | `[[widget]]` | `widget.luau` | Bar-виджет: SVG + текст + tooltip, ЛК панель, ПК toggle. |
| `shortcut` | `[[shortcut]]` | `shortcut.luau` | Плитка Control Center: glyph-пара, checked = connected. |
| `panel` | `[[panel]]` | `panel.luau` | Детальная панель управления. |

Полный id entry: `code-warlord/cloudflare-warp:<entry>`.

**`plugin_api = 24`** — минимум для относительных модулей (22) и argv-формы `runAsync` (24).
Обоснование по уровням: [API-NOTES.md §1](./API-NOTES.md#1-plugin_api--24--почему-именно-24).

---

## 3. Модель состояния

Один ключ — одна таблица. UI-entry только читают `warp.status`; сервис только пишет его.
`warp.command` — наоборот (см. §4).

### 3.1. `warp.status` (writer: service)

```luau
{
  schema = 1,
  phase = "connected",
  available = true,
  daemonOk = true,
  registered = true,
  accountType = "free",
  busy = false,
  errorCode = "",
  message = "",
  mode = "warp",
  families = "malware",
  protocol = "masque",
  alwaysOn = true,
  switchLocked = false,
  splitTunnelMode = "exclude",
  splitTunnelCount = 26,
  trace = { warp = "on", ip = "104.28.244.142", loc = "UA", colo = "WAW", atMs = 1792437046000 },
  cliVersion = "2026.8.2110.0",
  updatedAtMs = 1792437046000,
}
```

| Поле | Тип | Значения / правило |
|------|-----|--------------------|
| `schema` | number | `1`. Меняется только при ломающем изменении полей. |
| `phase` | string | `unavailable` \| `unregistered` \| `disconnected` \| `connecting` \| `connected` \| `disconnecting` \| `error` \| `unknown` |
| `available` | bool | `warp-cli` найден в `PATH` (`noctalia.commandExists`) |
| `daemonOk` | bool | последний вызов CLI дошёл до демона |
| `registered` | bool | `registration show` завершился с кодом 0 |
| `accountType` | string | `free` \| `team` \| `unknown` (из `account.type`; **никогда** license/id) |
| `busy` | bool | мутирующая команда в полёте |
| `errorCode` | string | `""` \| `cli-missing` \| `daemon-down` \| `unregistered` \| `command-failed` \| `timeout` \| `decode-failed` |
| `message` | string | сырой текст ошибки CLI (English), `""` если всё хорошо |
| `mode` | string | `warp` \| `doh` \| `warp+doh` \| `dot` \| `warp+dot` \| `proxy` \| `tunnel_only` \| `""` |
| `families` | string | `off` \| `malware` \| `full` \| `unknown` — write-only CLI; дефолт и презентация — `malware` (§3.3) |
| `protocol` | string | `wireguard` \| `masque` \| `unknown` |
| `alwaysOn` | bool | `settings.always_on` из `warp-cli settings --json` (корневой объект `settings`) |
| `switchLocked` | bool | `settings.switch_locked` — блокирует смену mode |
| `splitTunnelMode` | string | `exclude` \| `include` \| `""` |
| `splitTunnelCount` | number | `#split_tunnel_hosts + #split_tunnel_ips` (элементы — объекты `{value,description}`) |
| `trace` | table | `{ warp: string, ip: string, loc: string, colo: string, atMs: number }`; `atMs = 0` — не запрашивался |
| `cliVersion` | string | `2026.8.2110.0`, `""` если не удалось прочитать |
| `updatedAtMs` | number | `noctalia.nowMs()` последней успешной публикации статуса |

Правила публикации:

- публикуется целиком одной таблицей (никаких плоских `warp.mode` и т.п.);
- дефолт при старте: `phase = "unknown"`, `available = false`, `registered = false`,
  `families = "malware"`, `protocol = "unknown"`, `mode = ""`, `trace.atMs = 0`;
- сервис сравнивает таблицу по «отпечатку» (конкатенация значимых полей) и не пишет,
  если ничего не изменилось;
- `busy = true` ставится **до** запуска мутации, снимается в callback.

### 3.2. `warp.command` (writer: UI-entry, reader: service)

```luau
{
  seq = 1792437046123,
  action = "set-mode",
  mode = "warp+doh",
  source = "panel",
}
```

| Поле | Тип | Обязательно | Значение |
|------|-----|-------------|----------|
| `seq` | number | да | `noctalia.nowMs()` на момент записи; сервис игнорирует `seq <= lastHandledSeq` |
| `action` | string | да | `toggle` \| `connect` \| `disconnect` \| `refresh` \| `set-mode` \| `set-families` \| `set-protocol` \| `register` |
| `mode` | string | для `set-mode` | одно из 7 значений §5.2 |
| `families` | string | для `set-families` | `off` \| `malware` \| `full` |
| `protocol` | string | для `set-protocol` | `wireguard` \| `masque` |
| `source` | string | нет | `widget` \| `shortcut` \| `panel` \| `cli` — только для лога |

Сервис обязан провалидировать каждое поле по whitelist **до** построения argv. Ни одно
поле команды не попадает в shell-строку.

### 3.3. Ограничение Families

`warp-cli dns families` — **write-only**: геттера нет, значение не появляется в
`settings list` (проверено, см. API-NOTES §4).

- при инициализации сервиса `families` принудительно `malware` (Cloudflare default);
- после успешного `dns families <X>` — `X`;
- после рестарта сервиса — снова `malware` (state переживает рестарт, поэтому сервис
  перезаписывает поле, а не читает старое);
- панель всегда показывает один выбранный сегмент: неизвестное значение презентуется
  как `malware` (UI — §8.4); реальное не-дефолтное значение после рестарта не читается.

---

## 4. IPC-контракт

### 4.1. Сервис

```
noctalia msg plugin code-warlord/cloudflare-warp:service all <event> [payload]
```

| Event | Payload | Поведение | С какой фазы |
|-------|---------|-----------|--------------|
| `toggle` | — | disconnect, если `phase` ∈ {`connected`,`connecting`}, иначе connect | 1 |
| `connect` | — | `warp-cli connect` | 1 |
| `disconnect` | — | `warp-cli disconnect` | 1 |
| `refresh` | — | внеочередной status + settings + trace (если разрешён) | 1 |
| `set-mode` | `warp`\|`doh`\|`warp+doh`\|`dot`\|`warp+dot`\|`proxy`\|`tunnel_only` | `warp-cli mode <M>` | 1 |
| `set-families` | `off`\|`malware`\|`full` | `warp-cli dns families <F>` | 1 |
| `set-protocol` | `wireguard`\|`masque` (регистр не важен) | `warp-cli tunnel protocol set <WireGuard\|MASQUE>` | 1 |
| `register` | — | `warp-cli registration new` | 3 |

Правила:

- payload всегда **строка**; отсутствующий аргумент приходит как `""`, а не `nil`;
- неизвестный event или payload вне whitelist → строка в лог `noctalia.log("cloudflare-warp: warn …")`
  (у `noctalia.log` нет уровней — префикс в тексте), состояние не меняется, команда не выполняется;
- каждый принятый event пишется в лог одной строкой
  `cloudflare-warp: ipc <event> payload=<payload>`;
- `set-mode` при `switchLocked = true` → `notifyError(tr("error.mode-locked"))`, без вызова CLI.

### 4.2. Панель

```
noctalia msg panel-toggle code-warlord/cloudflare-warp:panel
```

Внутри скрипта: `noctalia.togglePanel("code-warlord/cloudflare-warp:panel")`.

### 4.3. Внутренний канал

UI-entry не могут вызывать IPC из скрипта. Они пишут таблицу в `warp.command` (§3.2),
сервис получает её через `noctalia.state.watch("warp.command", fn)`.

---

## 5. Внешняя зависимость и команды

### 5.1. argv-база

```luau
local CLI = { "warp-cli", "--accept-tos", "--json", "--no-paginate", "--no-ansi" }
```

`--accept-tos` означает принятие ToS Cloudflare от имени пользователя — это фиксируется в
README плагина.

| Действие | argv (suffix) | Timeout, ms | Когда |
|----------|---------------|-------------|-------|
| status | `status` | 8000 | каждый `update()` |
| settings | `settings`, `list` | 8000 | каждый 5-й тик и после мутации |
| registration | `registration`, `show` | 8000 | каждый 10-й тик и после `register` |
| connect | `connect` | 15000 | по команде |
| disconnect | `disconnect` | 15000 | по команде |
| mode | `mode`, `<MODE>` | 15000 | по команде |
| families | `dns`, `families`, `<MODE>` | 15000 | по команде |
| protocol | `tunnel`, `protocol`, `set`, `<PROTOCOL>` | 15000 | по команде |
| register | `registration`, `new` | 30000 | по команде |
| version | `warp-cli --version` (без JSON-флагов) | 5000 | один раз при старте сервиса |

Все вызовы — **только argv-форма**: `noctalia.runAsync({...}, cb, timeoutMs)`.

### 5.2. Разбор status

JSON: `{"status":"Connected","reason":"NetworkHealthy"}`.

| `status` (lowercase, substring) | `phase` |
|---------------------------------|---------|
| `connected` | `connected` |
| `connecting`, `reconnecting` | `connecting` |
| `disconnecting` | `disconnecting` |
| `disconnected` | `disconnected` |
| `registration missing`, `not registered` | `unregistered` |
| `unable to connect` | `error` |
| иное | `unknown` |

Текстовый fallback при ошибке `json.decode`: `stdout:match("Status update:%s*(%S+)")`.

### 5.3. Разбор settings

JSON: `decoded.settings` (см. API-NOTES §3.2).

Текстовый fallback (построчный `Label: value`):

| Поле state | Паттерн | Нормализация |
|------------|---------|--------------|
| `mode` | `Mode:%s*([^\n]+)` | trim + lowercase |
| `protocol` | `WARP tunnel protocol:%s*(%S+)` | lowercase |
| `alwaysOn` | `Always On:%s*(%S+)` | `== "true"` |
| `switchLocked` | `Switch Locked:%s*(%S+)` | `== "true"` |

Если JSON декодировался, но `settings` отсутствует — считать ответ неуспешным
(`errorCode = "decode-failed"`) и не затирать уже известные поля.

### 5.4. Классификация ошибок

| Условие | `phase` | `errorCode` | `daemonOk` |
|---------|---------|-------------|------------|
| `not commandExists("warp-cli")` | `unavailable` | `cli-missing` | `false` |
| `runAsync` вернул `false` (не запустилось) | `error` | `cli-missing` \| `command-failed` | как было |
| `result.timedOut` | `error` | `timeout` | как было |
| exit ≠ 0 и stderr ~ `Registration`/`not registered` | `unregistered` | `unregistered` | `true` |
| exit ≠ 0 и stderr ~ `daemon`/`socket`/`connect to`/`service` | `error` | `daemon-down` | `false` |
| exit ≠ 0 иное | `error` | `command-failed` | `true` |
| JSON не декодировался и текстовый парсер не дал `phase` | `unknown` | `decode-failed` | `true` |

`message` = `stderr` (обрезанный до 300 символов) либо `""`.

### 5.5. Trace (egress identity)

На dev-хосте `noctalia.http` к `cdn-cgi/trace` стабильно падает (`curl=28`, пустое тело,
опции таймаута нет — K-08), поэтому сервис сначала пробует argv-only `curl`, а
`noctalia.http` оставляет fallback'ом при отсутствии бинарника:

```luau
-- argv, без shell; те же флаги задают таймаут транспорта
{ "curl", "--silent", "--show-error", "--fail",
  "--max-time", "10", "--connect-timeout", "5", TRACE_URL }

-- fallback
noctalia.http({ url = TRACE_URL }, function(res) … end)
```

Обе ветки сходятся в один парсер и один набор guard'ов: in-flight, circuit breaker,
игнор устаревшего результата. Разбор: строки `k=v`; берём `warp` (`on`|`off`|`plus`), `ip`,
`loc`, `colo`. Успех → `trace = {…, atMs = nowMs()}`. Ошибка/`not res.ok`/таймаут →
оставить прежний `trace`, увеличить **внутренний** счётчик неудач (не поле state;
используется только для rate-limit лога — писать раз в N подряд, а не каждый тик).
Диагностика — exit code + `stderr` в лог при первой и каждой пятой подряд неудаче.
Никогда не блокирует статус-поллинг.

Частота: `auto_trace = true` → раз в `trace_interval_s`; `false` → только по `refresh`.
Внеочередные пробы: сразу после успешных connect/disconnect, set-mode/set-protocol и
повторно примерно через 5 с (`pendingTraceAt`).

Сеть: один HTTPS GET к `www.cloudflare.com` раз в 60 с по умолчанию. Это единственный
network call плагина и он должен быть указан в README и PR.

### 5.6. Уведомления

| Триггер | Условие |
|---------|---------|
| `connected` ↔ `disconnected` | `notify_on_change = true`, первая публикация после старта не считается |
| новый непустой `errorCode` (кроме `cli-missing`) | `notify_on_error = true`, не чаще одного раза на код |
| `register` завершился по таймауту | всегда `notifyError(tr("error.register-pending"))`; `errorCode` не ставится |

Тексты — только через `noctalia.tr(...)`.

---

## 6. Настройки

Plugin-level (`[[setting]]` в корне) — общие для service и panel:

| key | type | default | min/max | Описание |
|-----|------|---------|---------|----------|
| `poll_interval_ms` | int | 3000 | 1000 / 60000 | Интервал опроса статуса |
| `notify_on_change` | bool | true | — | Уведомлять о connect/disconnect |
| `notify_on_error` | bool | true | — | Уведомлять о новых ошибках |
| `auto_trace` | bool | true | — | Периодический `cdn-cgi/trace` |
| `trace_interval_s` | int | 60 | 15 / 3600 | Интервал trace; `visible_when = { key = "auto_trace", values = ["true"] }` |

Widget-scope (`[[widget.setting]]`) — только представление бара:

| key | type | default | Описание |
|-----|------|---------|----------|
| `show_text_in_bar` | bool | true | Показывать текст рядом с иконкой |
| `compact_mode` | bool | false | Только иконка (перекрывает `show_text_in_bar`) |

Правило: каждая объявленная настройка должна читаться литеральным
`noctalia.getConfig("<key>")` — иначе `noctalia plugins lint` даёт warning.

---

## 7. Манифест (каркас)

```toml
id           = "code-warlord/cloudflare-warp"
name         = "Cloudflare WARP"
version      = "0.1.0"
plugin_api   = 24
author       = "code-warlord"
license      = "MIT"
icon         = "cloud-lock"
description  = "Control Cloudflare WARP from the bar, Control Center and a dedicated panel."
tags         = ["network", "vpn", "privacy", "cloudflare"]
dependencies = ["cloudflare-warp"]

[[setting]]
key             = "poll_interval_ms"
type            = "int"
label_key       = "settings.poll_interval.label"
description_key = "settings.poll_interval.description"
default         = 3000
min             = 1000
max             = 60000

[[setting]]
key         = "notify_on_change"
type        = "bool"
label_key   = "settings.notify_on_change.label"
default     = true

[[setting]]
key         = "notify_on_error"
type        = "bool"
label_key   = "settings.notify_on_error.label"
default     = true

[[setting]]
key             = "auto_trace"
type            = "bool"
label_key       = "settings.auto_trace.label"
description_key = "settings.auto_trace.description"
default         = true

[[setting]]
key             = "trace_interval_s"
type            = "int"
label_key       = "settings.trace_interval.label"
description_key = "settings.trace_interval.description"
default         = 60
min             = 15
max             = 3600
visible_when    = { key = "auto_trace", values = ["true"] }

[[service]]
id    = "service"
entry = "service.luau"

[[widget]]
id    = "widget"
entry = "widget.luau"

[widget.actions]
right = "none"

[[widget.setting]]
key       = "show_text_in_bar"
type      = "bool"
label_key = "settings.show_text_in_bar.label"
default   = true

[[widget.setting]]
key       = "compact_mode"
type      = "bool"
label_key = "settings.compact_mode.label"
default   = false

[[shortcut]]
id    = "shortcut"
entry = "shortcut.luau"

[[panel]]
id             = "panel"
entry          = "panel.luau"
width          = 400
height         = 734
placement      = "floating"
position       = "auto"
open_near_click = true
```

`[widget.actions] right = "none"` обязателен: без него правый клик перехватывается
действием, и `onRightClick` не вызывается.

---

## 8. Функционал по entry

### 8.1. Service

- Top-level: `commandExists`, чтение настроек, `setUpdateInterval`, регистрация
  `state.watch("warp.command", …)`, первая публикация `warp.status`, чтение `cliVersion`.
- `update()`: статус каждый тик; settings/registration — по счётчику тиков; trace — по таймеру.
- `onIpc(event, payload)` — §4.1.
- `onConfigChanged()` — перечитать настройки, применить `setUpdateInterval`, сбросить таймер trace.
- `onEnable()` — лог + внеочередной `refresh` (не дублировать, если он уже идёт).
- `onExit(signal, reason)` — лог; detached-процессы не убиваем (короткие вызовы CLI).
- Все вызовы — с in-flight guard на каждый тип команды; мутации — через общий `actionInFlight`.
- `busy` из state блокирует повторные мутации на стороне UI.
- Успешный connect/disconnect обязательно обновляет сетевую идентичность: trace-проба
  сразу после команды и повторно примерно через 5 с, когда маршрут стабилизируется.
  То же — после успешных set-mode/set-protocol.
- `connecting`/`disconnecting` — удерживаемая фаза: после успешного connect/disconnect
  сервис публикует transition и не заменяет его результатом поллинга, пока не увидит
  целевую фазу либо не истечёт 30 с. `busy = true` держится вместе с фазой, поэтому UI
  не прыгает «Подключение…» → «Отключено» → «Подключено».

### 8.2. Bar Widget

Императивный путь (не `barWidget.render`):

```luau
barWidget.setImage(iconPath(phase), false, 16, 16)   -- SVG
barWidget.setText(text)                               -- "" если compact/hidden
barWidget.setTooltip(rows)                            -- массив { key, value }
barWidget.setVisible(true)
```

| `phase` | SVG | Текст |
|---------|-----|-------|
| `connected` | `assets/icons/warp-on.svg` | `tr("widget.text.on")` |
| `disconnected` | `assets/icons/warp-off.svg` | `tr("widget.text.off")` |
| `connecting` / `disconnecting` | `assets/icons/warp-connecting.svg` | `tr("widget.text.connecting")` |
| `unregistered` | `assets/icons/warp-warn.svg` | `tr("widget.text.register")` |
| `error` / `unavailable` | `assets/icons/warp-error.svg` | `tr("widget.text.error")` |
| `unknown` | `assets/icons/warp-off.svg` | `tr("widget.text.unknown")` |

- Fallback: `barWidget.setGlyph("cloud-lock")`, если файл иконки не найден/не отрисован.
- `onClick()` → `noctalia.togglePanel("code-warlord/cloudflare-warp:panel")`.
- `onRightClick()` → `warp.command = { seq, action = "toggle", source = "widget" }`
  (игнорировать при `busy`).
- Tooltip — массив строк: status, mode, families (если известен), protocol, ip, error.
- Подписка: `noctalia.state.watch("warp.status", applyStatus)` + первичный `get`.
- Состояние читается только из state; никаких CLI-вызовов из виджета.

### 8.3. Control Center Shortcut

`shortcut.setLabel`, `shortcut.setIcon(onGlyph, offGlyph)`, `shortcut.setActive`,
`shortcut.setEnabled`.

- SVG здесь недоступен: `setIcon` принимает только glyph-имена (`"cloud-lock"` /
  `"cloud-off"`); это ограничение API, а не упрощение.
- `setActive(phase == "connected" or phase == "connecting")`.
- `setEnabled(available and not busy)`.
- `onClick()` → toggle; `onRightClick()` → refresh.
- `onExit` не нужен (нет ресурсов).

### 8.4. Panel

Визуальная редакция v2 — [specs/phase-3-panel-redesign.md](../specs/phase-3-panel-redesign.md);
контракт state/IPC ниже не меняется. Декларативный `panel.render(ui.…)` в `onOpen`
и после каждого изменения.

```
ui.column
  ├─ banner-wrap (paddingV = -14) → image 400×160 (кадр секвенции assets/banner/, saturation ramp + bottom alpha fade)
  ├─ header: cloud glyph, title, Refresh, Close
  ├─ content-body (flexGrow=1, без ui.scroll)
  │   ├─ hero: status icon (connected — glyph shield-check, иначе phase glyph) + status + subtitle + «Обновлено HH:MM» + power (+ wave в transition)
  │   ├─ Mode | Protocol          (два равных столбца)
  │   ├─ Families: segmented, всегда есть выбранный сегмент
  │   └─ identity card: IP (+copy), loc, colo, WARP, trace time
  └─ footer: Copy IP | Register (если !registered) | Settings
```

- Баннер при открытии соответствует фазе: `connected`/`connecting` — forward 0 → 26;
  `disconnecting` — reverse; прочие (off/error/unavailable/unregistered/unknown) —
  статичный кадр 0 (20 % цвета) без анимации. Reverse также играет при переходе из
  connected/connecting в disconnecting/disconnected.
- Families — **сегменты**, а не `ui.select`: у `select` нет «пустого» выбора, и он визуально
  соврёт про текущее значение. Сегменты — `ui.column` с onClick на всю ячейку; выбранный
  сегмент есть всегда: неизвестное write-only значение презентуется как `malware`.
  Unselected обязан передавать явные `fill="#00000000"` / `border="#00000000"`: host
  сохраняет отсутствующие flex-стили.
- Mode/Protocol — `ui.select`; `onChange(index)` приходит строкой → `tonumber`.
  Host выбирает option 0 для непустого списка, поэтому unknown = ведущая опция
  `panel.mode.unknown` / `panel.protocol.unknown`, а обработчик вычитает offset.
- Протокол в state — lowercase, в UI — `WireGuard` / `MASQUE`.
- `trace.atMs == 0` → вместо IP показывать `tr("panel.trace.none")`, Copy IP disabled.
- После успешного connect/disconnect identity обновляется без ожидания 60-секундного
  цикла: немедленная trace-проба + повторная через ~5 с. Смена Mode/Protocol даёт те же
  две пробы.
- Время trace — `noctalia.formatTime("%H:%M", math.floor(trace.atMs / 1000))`.
- Copy IP: `noctalia.copyToClipboard(trace.ip, "text/plain")`; feedback только при `true`
  (host возвращает bool), полный IP попадает в буфер даже если строка сокращена.
- Settings: `noctalia.openSettings()`.
- Register: `warp.command.action = "register"`; показывать/включать только при `!registered`,
  заменяет Copy IP в footer.
- `busy` → дизейбл всех мутирующих контролов + dim; активность в transition показывает
  пятиполосная sine-волна (3 px бары, высота 4–14 px, период 900 ms, opacity 0.45–1.0).
  Hero-иконка не подменяется спиннером.
- Размер: `width = 400`, `height = 734` (host-owned, задаётся в манифесте; изменения
  применяются после disable/enable плагина). Scroll-контейнер не используется: хост
  рисует scrollbar всегда, поэтому высота подобрана под штатные состояния.
- Отступы: root отменяет горизонтальный host-inset (`paddingH = -14`), поэтому
  единственный боковой отступ — внутренние 16 px, а карточки занимают 368 px.
  Banner-wrapper отменяет только верхний inset (`paddingV = -14`); вертикальный
  ритм контента не меняется.

---

## 9. Структура директории

```
cloudflare-warp/
├── plugin.toml
├── service.luau                 # P0 stub → P1 полный
├── widget.luau                  # P0 stub → P2
├── shortcut.luau                # P0 stub → P2
├── panel.luau                   # P0 stub → P3
├── lib/
│   ├── state.luau               # P0: константы каналов + schema; P1: publish/patch
│   ├── parse.luau               # P0: пустой модуль; P1: парсеры
│   ├── commands.luau            # P0: пустой модуль; P1: argv + run-обёртки
│   └── icons.luau               # P2: phase → svg path / glyph / text key
├── translations/
│   ├── en.json
│   └── ru.json
├── assets/
│   ├── banner/                  # P3: 27 кадров из wGjQl.gif
│   │   └── frame-00…26.webp
│   └── icons/
│       ├── warp-on.svg          # P2
│       ├── warp-off.svg         # P2
│       ├── warp-connecting.svg  # P2
│       ├── warp-warn.svg        # P2
│       └── warp-error.svg       # P2
├── thumbnail.webp               # P4
└── README.md
```

Каждый модуль обязан возвращать ровно одно не-`nil` значение (`return M`).
`require` — только `./lib/<name>.luau` (относительный, с расширением).

---

## 10. UI/UX

1. Бар — минимальный footprint; в `compact_mode` только SVG 16×16.
2. SVG — собственная стилизованная отрисовка WARP-состояния, `viewBox="0 0 24 24"`,
   `currentColor`/один `fill`. Официальный логотип Cloudflare не копировать 1:1;
   в README — note про trademark.
3. Цвета текста — роли палитры (`primary`, `on_surface_variant`, `error`, `success`).
4. Клики: ЛК — панель, ПК — toggle WARP (`warp.command`, action `toggle`); у `levi/warp`
   ЛК тоже панель, поэтому инверсии относительно него нет.
5. Панель — floating, `position = "auto"`, `open_near_click = true`, 400×734, без scroll.
6. Tooltip всегда информативен и локализован.
7. Тексты статуса: `connected`, `disconnected`, `connecting`, `disconnecting`,
   `unregistered`, `error`, `unavailable`, `unknown` — все через `tr("status.<phase>")`.

---

## 11. Локальная валидация и тестирование

Команды `noctalia validate-plugin` **не существует**. Реальный workflow:

```bash
# 1. офлайн: settings ↔ getConfig, наличие entry-файлов
noctalia plugins lint cloudflare-warp

# 2. path-source на КОРЕНЬ репозитория (каталог cloudflare-warp/ = суффикс id)
noctalia msg plugins source add warpdev path /home/code_warlord/DEV/cloudflare-warp-plugin

# 3. видимость и включение
noctalia msg plugins list | grep cloudflare-warp
noctalia msg plugins enable code-warlord/cloudflare-warp

# 4. IPC и панель
noctalia msg plugin code-warlord/cloudflare-warp:service all refresh
noctalia msg plugin code-warlord/cloudflare-warp:service all toggle
noctalia msg panel-toggle code-warlord/cloudflare-warp:panel

# 5. наблюдение
tail -f ~/.cache/noctalia/noctalia.log

# 6. выключение и уборка
noctalia msg plugins disable code-warlord/cloudflare-warp
noctalia msg plugins source remove warpdev
```

- `.luau` — hot-reload по сохранению; `plugin.toml` — `noctalia msg config-reload`;
  изменения panel `width`/`height` на 5.3.0 требуют disable/enable плагина.
- `plugins lint` возвращает exit 1 при error-level проблемах, но **не** проверяет
  translations, панельные опции и не исполняет код. Зелёный lint ≠ рабочий плагин;
  настоящий гейт — enable + чистый лог.
- Полная валидация манифеста/каталога/thumbnail — только CI `community-plugins` (Phase 5).

---

## 12. Риски

| Риск | Митигация |
|------|-----------|
| Формат `warp-cli` меняется | JSON-first + текстовый fallback + `unknown` |
| Нет геттера Families | write-only: панель показывает default `malware`, значение не читается и не откатывается |
| Демон не запущен | `daemonOk=false` + `errorCode=daemon-down`, без падения |
| Клиент не зарегистрирован | `phase=unregistered`, кнопка Register (P3) |
| `switch_locked` (MDM) | блокировать смену mode + объяснить в UI |
| SVG не растеризуется хостом | glyph-fallback + проверка в Phase 2 |
| `http()` без timeout | in-flight guard + устаревание по `atMs` |
| payload → shell | только argv + whitelist |
| license/public_key утекут в state | в state только `registered`/`accountType` |
| Два WARP-плагина включены | QA выключает `levi/warp` и `code_warlord/warp_toggle` |

---

## 13. Ссылки

- [docs/API-NOTES.md](./API-NOTES.md) — проверенные факты и ограничения
- https://docs.noctalia.dev/noctalia/plugins/development/
- https://docs.noctalia.dev/noctalia/plugins/development/manifest/
- https://docs.noctalia.dev/noctalia/plugins/development/entries/
- https://docs.noctalia.dev/noctalia/plugins/development/runtime-api/
- https://docs.noctalia.dev/noctalia/plugins/development/declarative-ui/
- https://docs.noctalia.dev/noctalia/plugins/development/plugin-api/
- https://docs.noctalia.dev/noctalia/plugins/development/workflow/
- https://github.com/noctalia-dev/official-plugins (`screen_recorder`, `example`)
- https://developers.cloudflare.com/warp-client/get-started/linux/
