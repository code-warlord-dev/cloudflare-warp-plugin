# API-NOTES — сверка с реальностью (Noctalia 5.3.0)

Аудит фактов, на которых держатся SPEC и phase-specs. Все утверждения ниже проверены
локально 2026-10-19; сомнительные места помечены явно.

**Окружение проверки**

| Компонент | Значение |
|-----------|----------|
| Noctalia | `noctalia v5.3.0 (5.3.0-1-dirty)` |
| Поддерживаемые `plugin_api` | 3 … 34 (по документации и бинарю) |
| `warp-cli` | `2026.8.2110.0` (build 2026-10-12), установлен, зарегистрирован |
| Состояние WARP на момент аудита | `Connected` / `NetworkHealthy` (не менялось) |
| Лог shell | `~/.cache/noctalia/noctalia.log` |
| Materialized plugins | `~/.local/state/noctalia/plugins/materialized/<source>/<dir>` |

---

## 1. `plugin_api = 24` — почему именно 24

API-уровни кумулятивны: в манифесте указывается **самый старый** уровень, покрывающий все
используемые возможности.

| Возможность | Мин. уровень | Используем |
|-------------|--------------|------------|
| `noctalia.nowMs()` | 12 | да (`updatedAtMs`, `seq`, `trace.atMs`) |
| `[widget.actions]` | 14 | да (`right = "none"`) |
| `noctalia.openSettings()` | 15 | да (панель) |
| `onEnable()` / `onExit(signal, reason)` | 17 | да (service) |
| `require("./lib/x.luau")` | **22** | да (`lib/*.luau`) |
| `noctalia.runAsync({...}, cb, timeoutMs)` | **24** | да (все вызовы `warp-cli`) |

Итого: **24** — минимум, покрывающий относительные модули и argv-форму `runAsync`.
Выше 24 не поднимаем: `getSetting` (26), `getColor` (31), `tooltip` на контейнерах (32),
`layer` панели (30), `hover_highlight` (34) не нужны.

Подтверждение на живых плагинах: `community/github-notifications` и
`community/github-activity` объявляют `plugin_api = 24` и используют одновременно
`require("./lib/…")` и argv-форму `runAsync`.

**Не использовать** `plugin_api = 17` из старых документов: на 17 модули и argv недоступны.

---

## 2. Идентификатор и каталог

| Поле | Значение |
|------|----------|
| id | `code-warlord/cloudflare-warp` |
| author | `code-warlord` |
| каталог | `cloudflare-warp/` (суффикс id = имя каталога, требование source-репозиториев) |

Сообщество использует GitHub-хендл автора (`levi/warp`, `code_warlord/screenshot`,
`code_warlord/warp_toggle`). Решение Orchestrator — `code-warlord` (дефис).
**Риск:** локально у автора уже опубликованы плагины под `code_warlord` (подчёркивание).
Перед Phase 5 нужно сверить хендл на GitHub; если он `code-warlord-dev` или `code_warlord`,
id придётся переименовать (до 1.0.0 это дешёво, после — MAJOR).

`id` не может быть `community/cloudflare-warp`: `community` — имя source, а не автора.

---

## 3. `warp-cli`: JSON-контракт

Базовая форма (проверена на всех командах ниже):

```
warp-cli --accept-tos --json --no-paginate --no-ansi <command…>
```

`--accept-tos` обязателен для неинтерактивной работы (принимает ToS Cloudflare от имени
пользователя — это надо указать в README плагина).

### 3.1. `status`

```json
{ "status": "Connected", "reason": "NetworkHealthy" }
```

`status` — человекочитаемая строка, не enum. Встречаются как минимум:
`Connected`, `Disconnected`, `Connecting`, `Disconnecting`, `Reconnecting`,
`Unable to connect`, `Registration missing`.

Текстовый fallback (если JSON не декодировался):

```
Status update: Connected
Network: healthy
```

### 3.2. `settings list`

```json
{
  "settings": {
    "always_on": true,
    "switch_locked": false,
    "operation_mode": "warp",
    "split_tunnel_mode": "exclude",
    "split_tunnel_hosts": [],
    "split_tunnel_ips": [ { "value": "10.0.0.0/8", "description": "" } ],
    "warp_tunnel_protocol": "masque",
    "post_quantum_config": "enabled_with_downgrades",
    "enable_pmtud": true
  },
  "sources": { "operation_mode": "user_set", "warp_tunnel_protocol": "network_policy" }
}
```

Используем только: `operation_mode`, `warp_tunnel_protocol`, `always_on`,
`switch_locked`, `split_tunnel_mode`, `split_tunnel_ips`, `split_tunnel_hosts`.
`warp_tunnel_protocol` — **lowercase** (`masque` | `wireguard`).
`split_tunnel_ips` — массив **объектов** `{value, description}`, поэтому для счётчика нужен
`#`, а не склейка строк. `sources` — происхождение значения (`user_set` / `network_policy` /
`derived` / `override`), это **не** значения настроек: читать только `decoded.settings`.

Текстовый fallback: строки вида `(<source>)\t<Label>: <value>`:

```
(user set)	Mode: Warp
(network policy)	WARP tunnel protocol: MASQUE
(derived)	Always On: true
(override)	Switch Locked: false
(user set)	DNS logging until: SystemTime { … }
```

### 3.3. `registration show`

Успех — JSON с `id`, `device_id`, `public_key`, `managed`, `account`
(`type`, `id`, `license`), `alternate_networks`. Незарегистрированный клиент — **ненулевой
exit code**.

**Безопасность:** `account.license`, `account.id`, `public_key`, `device_id` — учётные
данные. Их нельзя писать в `noctalia.state`, в лог и в README. В state попадают только
`registered` (bool) и `accountType` (`free` | `team`).

### 3.4. Мутации

| Действие | argv | Значения |
|----------|------|----------|
| connect | `connect` | — |
| disconnect | `disconnect` | — |
| mode | `mode <MODE>` | `warp`, `doh`, `warp+doh`, `dot`, `warp+dot`, `proxy`, `tunnel_only` |
| families | `dns families <MODE>` | `off`, `malware`, `full` |
| protocol | `tunnel protocol set <PROTOCOL>` | `WireGuard`, `MASQUE` |
| register | `registration new` | — |

`mode`, `dns families`, `tunnel protocol set` — точные имена субкоманд (сверено с `--help`).

**`registration new` — интерактивная команда:** печатает URL и ждёт завершения входа в
браузере. Таймаут `runAsync` её не «проваливает», а обрывает ожидание; после таймаута
регистрация может завершиться уже без нас, поэтому:
`timedOut = true` → **не** `error`, а `notifyError(tr("error.register-pending"))` +
`busy = false` + обычный `refresh` через интервал (следующий poll увидит `registered = true`).

---

## 4. Families — write-only (ключевое ограничение)

```
$ warp-cli dns families
error: the following required arguments were not provided:
  <MODE>
```

Геттера нет ни в JSON, ни в текстовом режиме, ни в `settings list`. Значение `dns families`
не отражается в `settings list`.

Следствие для state:

- `families = "unknown"` при старте сервиса;
- после успешного `dns families <X>` в **текущем** runtime — `families = X`;
- после рестарта сервиса снова `unknown` (state-канал переживает рестарт, поэтому сервис
  обязан перезаписать поле на `unknown` при инициализации, а не подхватывать старое);
- панель не должна показывать предвыбранное значение Families как факт.

---

## 5. Trace вместо `curl`

`warp=on|plus|off`, публичный egress `ip`, страна `loc`, edge `colo` отдаёт
`https://www.cloudflare.com/cdn-cgi/trace`:

```
fl=…
h=www.cloudflare.com
ip=104.28.244.142
ts=…
colo=WAW
loc=UA
warp=on
gateway=off
```

Реализация — `noctalia.http({ url = … }, cb)`, **без** дочернего `curl`.
Это убирает один процесс из trust surface и один shell-слой.

```luau
noctalia.http({ url = "https://www.cloudflare.com/cdn-cgi/trace" }, function(res)
  -- res = { ok = bool, status = number, body = string }
end)
```

В проверенной сигнатуре (`{ url, method?, headers?, body? }`) поля таймаута нет.
Защита — in-flight guard + игнор результата, если он старше одного `trace_interval_s`.

`noctalia.http` появился на ранних уровнях (в runtime-документации — с 9), так что на выбор 24
не влияет.

---

## 6. State-канал: одна таблица на канал

`noctalia.state.set/get/watch` передаёт **plain data** (строки, числа, булевы, таблицы).
Значения копируются между VM; канал живёт в памяти процесса и не переживает выключение
плагина, но переживает рестарт сервиса.

Официальный паттерн (`noctalia/screen_recorder`): сервис публикует один ключ `status`
целиком, UI пишет один ключ `command`. Один `watch` на entry, атомарное обновление,
никакой рассинхронизации полей.

Наш вариант (решение Orchestrator):

| Канал | Writer | Readers |
|-------|--------|---------|
| `warp.status` | **только service** | widget, shortcut, panel |
| `warp.command` | widget, shortcut, panel | **только service** |

`warp.command` — единственный канал, который пишут UI-entry. Это не нарушение правила
«service — единственный источник правды»: правда о WARP живёт в `warp.status`, а
`warp.command` — очередь намерений.

Проверено эмпирически: таблица с вложенной таблицей (`trace`) корректно проходит
`set` → `get`; `watch` не вызывается в момент регистрации, только на изменение.

---

## 7. IPC: что реально работает

```
noctalia msg plugin <author/plugin:entry> <target> <event> [payload]
noctalia msg panel-toggle <author/plugin:panel>
```

- target для сервиса — **`all`** (у service нет output);
- payload всегда приходит **строкой**; при отсутствии аргумента это `""`, а не `nil`
  (проверено: `onIpc("ping", "")`);
- неизвестная панель: `error: unknown panel …`, exit 1;
- отправка: `ok: dispatched 1`.

Внутри плагина IPC из скрипта недоступен — UI-entry общаются с сервисом только через
`warp.command`, сервис читает его через `noctalia.state.watch`.

---

## 8. Локальная проверка (без `validate-plugin`)

**Команды `noctalia validate-plugin` не существует.** Локальный авторский инструмент —
`noctalia plugins lint`; полная валидация (catalog, translations, thumbnail, CI-правила)
происходит в CI `community-plugins`.

```bash
# офлайн-проверка: settings ↔ getConfig, наличие entry-файлов
noctalia plugins lint cloudflare-warp
```

Что lint реально проверяет (проверено на синтетическом плагине):

| Уровень | Пример сообщения |
|---------|------------------|
| error | `entry 'ghost' points at a missing file 'ghost.luau'` |
| error | `service.luau:2 reads undeclared setting 'x' (did you mean 'declared_read'?)` |
| warn | `declared setting 'declared_unread' (plugin-level) is never read` |

Exit code: `1` при наличии error, `0` иначе. Формат успеха:

```
code-warlord/cloudflare-warp
  ok

0 errors, 0 warnings
```

Важно: lint **не** проверяет TOML-семантику, translation-ключи, панельные опции и не
исполняет код. Зелёный lint ≠ загружаемый плагин. Настоящий гейт — enable + лог.

```bash
# path-source указывает на КОРЕНЬ репозитория: плагин лежит в cloudflare-warp/,
# имя каталога совпадает с суффиксом id
noctalia msg plugins source add warpdev path /home/code_warlord/DEV/cloudflare-warp-plugin
noctalia msg plugins list | grep cloudflare-warp
noctalia msg plugins enable code-warlord/cloudflare-warp
noctalia msg plugins disable code-warlord/cloudflare-warp
noctalia msg plugins source remove warpdev
```

Проверено: `source add` возвращает `ok`, плагин появляется в `plugins list` как
`code-warlord/cloudflare-warp [warpdev] 0.1.0 disabled`, enable отвечает
`ok (exporting in background)`.

Горячая перезагрузка: правки `.luau` подхватываются file-watcher’ом; изменения
`plugin.toml` — только через `noctalia msg config-reload`.

---

## 9. Асинхронный API: проверенные сигнатуры

| Вызов | Факт |
|-------|------|
| `noctalia.runAsync(argv, cb, timeoutMs)` | argv-форма и третий аргумент-таймаут работают |
| `noctalia.runAsync(cmd)` | shell-строка через `/bin/sh -c`, без захвата вывода |
| callback `result` | `{ exitCode, stdout, stderr, timedOut, stdoutTruncated, stderrTruncated }` |
| `noctalia.json.decode(s)` | возвращает `value, err` (два значения) |
| `noctalia.http(req, cb)` | `req = { url, method?, headers?, body? }`; `res = { ok, status, body }` |
| `noctalia.state.set/get/watch` | plain data, копирование между VM |

Эмпирическая проверка таймаута: `runAsync({"sleep","5"}, cb, 1000)` → callback через
~1013 ms, `timedOut = true`, `exitCode = 143`. Значит третий аргумент — именно бюджет
времени, а не что-то иное.

`runAsync` в argv-форме **не** использует shell: пайпы, редиректы и подстановки в ней
недоступны, а значения не нужно квотировать. Любой пользовательский payload (mode,
families, protocol) обязан идти только через argv и только после whitelist-проверки.

---

## 10. Манифест и настройки

- `id`, `name`, `version`, `plugin_api` — обязательны; `version` строго `MAJOR.MINOR.PATCH`.
- Настройки плагина — `[[setting]]` **в корне** манифеста, общие для всех entry.
- Настройки представления виджета — `[[widget.setting]]` (только этот виджет).
- `label_key` обязателен; литеральные `label`/`description` отклоняются.
- `translations/en.json` обязателен при наличии настроек; `ru.json` — требование проекта.
- `[[panel]]`: `width`, `height` (px или `"fill"`), `placement` (`attached`|`floating`),
  `position`, `open_near_click`; `layer` требует 30 (не используем).
- `[widget.actions]` принимает жесты (`left`, `right`, `middle`, `scroll_up`, …); значение
  `"none"` **снимает** биндинг (ошибка в бинаре: `action is empty (use "none" to unbind)`).
  Мы объявляем `right = "none"` явно, чтобы правый клик гарантированно доходил до
  `onRightClick` (в `levi/warp` биндинга нет и клик работает — «none» это страховка,
  а не обязательное условие). Значение с `panel-toggle` требует id панели
  (`… needs a panel id`).
- Встроенный `middle` открывает настройки плагина; `onMiddleClick` без `middle = "none"`
  не вызывается.

---

## 11. Иконки

| Surface | API | Ограничение |
|---------|-----|-------------|
| Bar widget | `barWidget.setImage("assets/icons/x.svg", false, 16, 16)` | относительный путь от каталога плагина |
| Bar fallback | `barWidget.setGlyph("cloud-lock")` | glyph, не SVG |
| Shortcut | `shortcut.setIcon(onGlyph, offGlyph)` | **только glyph-имена**, SVG не принимает |

`barWidget.setImage` в живых плагинах не встречается, но присутствует в бинаре
(`setText/setGlyph/setImage/setFont/setColor`) и описан в runtime-документации. Риск
растеризации SVG хостом остаётся — поэтому fallback на glyph обязателен, а в Phase 0
используется только glyph.

Смешивать нельзя: после `barWidget.render(tree)` императивные `setImage/setText/setGlyph`
не дают эффекта (в лог пишется предупреждение). Выбираем императивный путь для бара.

---

## 12. Формат переводов

Проверено на всех установленных плагинах: `translations/<lang>.json` — **вложенный** JSON,
где путь ключа совпадает с dotted-ключом (`settings.poll_interval.label`).

```json
{ "settings": { "poll_interval": { "label": "Refresh interval", "description": "…" } } }
```

`noctalia.tr("settings.poll_interval.label")` резолвит такую вложенность. Плоские ключи
(`"settings.poll_interval.label": "…"`) в установленных плагинах не используются, поэтому
проект принимает вложенную форму как канон.

Отсутствующий ключ виден в логе как
`[plugin-i18n] plugin translation key '<key>' not found` — это готовый QA-чек.

---

## 13. Отличия от `levi/warp` (v1.2.0, `plugin_api = 3`)

| Возможность | `levi/warp` | Наш плагин |
|-------------|-------------|------------|
| Connect/disconnect | да | да |
| Mode (7 значений) | да | да |
| **Families** | нет | да (с честным `unknown`) |
| **Tunnel protocol** | только чтение (из `tunnel stats`) | чтение + **setter** |
| **Registration** | нет отдельного состояния | `registered`, `accountType`, `register` |
| **Egress IP / loc / colo / warp=on\|plus** | нет (показывает endpoint и latency туннеля) | да, через `cdn-cgi/trace` |
| Метрики туннеля (latency, loss, TLS, bytes) | да | **нет** (вне scope) |
| Иконки бара | Tabler glyph | **SVG** по состоянию + glyph-fallback |
| i18n | en | **en + ru** |
| Форма `runAsync` | shell-строка | **argv** (без shell) |
| Клики бара | ЛК — панель, ПК — toggle | **ЛК — toggle, ПК — панель** |

Позиционирование: мы не надмножество. Мы про **управление и сетевую идентичность**
(Families, протокол, регистрация, egress), `levi/warp` — про телеметрию туннеля.
В README это надо сказать прямо, без обещаний «всё как у них плюс ещё».

---

## 14. Антипаттерны (проверено как нерабочие/запрещённые)

| Не делать | Почему |
|-----------|--------|
| `noctalia validate-plugin` | команды нет |
| `curl` для trace | лишний процесс; есть `noctalia.http` |
| shell-строка с payload | инъекция; использовать argv |
| `warp-cli dns families` без аргумента как getter | exit 2, значения не отдаёт |
| `plugin_api = 17` | нет модулей (22) и argv (24) |
| `community/cloudflare-warp` | `community` — source, не автор |
| `account.license` / `public_key` в state или лог | секрет |
| `sudo`, `systemctl` | вне scope, требует прав |
| `setImage` после `barWidget.render` | не даёт эффекта |
| `[[widget.setting]]` для серверных настроек | сервис не увидит widget-scope |
