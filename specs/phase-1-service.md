# Phase 1 — Service Core

**Target version:** `0.2.0` (MINOR)
**Goal:** сервис — единственный источник правды о WARP: поллит `warp-cli` через argv,
публикует одну таблицу `warp.status`, принимает `warp.command` и IPC, выполняет мутации.

Исполнитель: **implementer**. Проверяющий: **qa**.
Контракты: [../docs/SPEC.md](../docs/SPEC.md) §3–§5; факты: [../docs/API-NOTES.md](../docs/API-NOTES.md).

## Non-goals

- UI (виджет, shortcut, панель) — Phase 2–3;
- SVG-ассеты;
- `register` (Phase 3), WARP+ license, Zero Trust;
- телеметрия туннеля (`tunnel stats`) — не входит в продукт.

## Dependencies

Phase 0 (манифест, entry-файлы, `lib/state.luau`).

## State schema

### `warp.status` — writer: **только service**

| Поле | Тип | Значения / правило |
|------|-----|--------------------|
| `schema` | number | `1` |
| `phase` | string | `unavailable` \| `unregistered` \| `disconnected` \| `connecting` \| `connected` \| `disconnecting` \| `error` \| `unknown` |
| `available` | bool | `warp-cli` в `PATH` |
| `daemonOk` | bool | последний CLI-вызов дошёл до демона |
| `registered` | bool | `registration show` exit 0 |
| `accountType` | string | `free` \| `team` \| `unknown` |
| `busy` | bool | мутация в полёте |
| `errorCode` | string | `""` \| `cli-missing` \| `daemon-down` \| `unregistered` \| `command-failed` \| `timeout` \| `decode-failed` |
| `message` | string | `stderr` ≤ 300 символов, `""` если ок |
| `mode` | string | 7 значений §5.2 или `""` |
| `families` | string | `off` \| `malware` \| `full` \| `unknown` |
| `protocol` | string | `wireguard` \| `masque` \| `unknown` |
| `alwaysOn` | bool | `settings.always_on` |
| `switchLocked` | bool | `settings.switch_locked` |
| `splitTunnelMode` | string | `exclude` \| `include` \| `""` |
| `splitTunnelCount` | number | hosts + ips |
| `trace` | table | `{ warp, ip, loc, colo, atMs }` — строки + number; `atMs = 0` = не было |
| `cliVersion` | string | `2026.8.2110.0` или `""` |
| `updatedAtMs` | number | `noctalia.nowMs()` последней успешной публикации |

Дефолт при старте: `phase = "unknown"`, `available = false`, `daemonOk = true`,
`registered = false`, `accountType = "unknown"`, `busy = false`, `errorCode = ""`,
`message = ""`, `mode = ""`, `families = "unknown"`, `protocol = "unknown"`,
`alwaysOn = false`, `switchLocked = false`, `splitTunnelMode = ""`,
`splitTunnelCount = 0`, `trace = { warp="", ip="", loc="", colo="", atMs=0 }`,
`cliVersion = ""`, `updatedAtMs = 0`.

Публикация — одной таблицей через `noctalia.state.set("warp.status", t)`, только при
изменении «отпечатка» (конкатенация значимых полей). Никаких плоских ключей.

### `warp.command` — writer: UI-entry, reader: service

| Поле | Тип | Обязательно | Значение |
|------|-----|-------------|----------|
| `seq` | number | да | `noctalia.nowMs()` |
| `action` | string | да | `toggle` \| `connect` \| `disconnect` \| `refresh` \| `set-mode` \| `set-families` \| `set-protocol` |
| `mode` | string | для `set-mode` | 7 значений |
| `families` | string | для `set-families` | `off` \| `malware` \| `full` |
| `protocol` | string | для `set-protocol` | `wireguard` \| `masque` |
| `source` | string | нет | `widget` \| `shortcut` \| `panel` \| `cli` |

Сервис:
- регистрирует `noctalia.state.watch("warp.command", handler)` на top-level;
- игнорирует `seq <= lastHandledSeq`;
- валидирует `action` и поле-payload по whitelist; мусор → строка
  `noctalia.log("cloudflare-warp: warn …")`, без CLI;
- `lastHandledSeq` — локальная переменная сервиса, а не state.

## IPC contract

Target: `code-warlord/cloudflare-warp:service`, target-селектор **`all`**.

| Event | Payload | Поведение | Реализуется |
|-------|---------|-----------|-------------|
| `toggle` | — | disconnect при `connected`/`connecting`, иначе connect | Phase 1 |
| `connect` | — | `connect` | Phase 1 |
| `disconnect` | — | `disconnect` | Phase 1 |
| `refresh` | — | status + settings + registration + trace (если разрешён) | Phase 1 |
| `set-mode` | одно из 7 | `mode <MODE>` | Phase 1 |
| `set-families` | `off`\|`malware`\|`full` | `dns families <MODE>` | Phase 1 |
| `set-protocol` | `wireguard`\|`masque` | `tunnel protocol set <WireGuard\|MASQUE>` | Phase 1 |
| `register` | — | `registration new` | Phase 3 |

Правила:

- payload — всегда строка, отсутствующий аргумент = `""` (не `nil`);
- `set-protocol` принимает любой регистр, нормализуется в lowercase для state и в
  канонический (`WireGuard`/`MASQUE`) для argv;
- `set-mode` при `switchLocked = true` → `notifyError(tr("error.mode-locked"))`, CLI не вызывается;
- каждый принятый event → одна строка лога `cloudflare-warp: ipc <event> payload=<payload>`;
- `onIpc` и `warp.command` идут в один и тот же обработчик `dispatch(action, fields, source)`
  — одна валидация, один код исполнения.

## Команды CLI

База: `local CLI = { "warp-cli", "--accept-tos", "--json", "--no-paginate", "--no-ansi" }`.

| Действие | argv | Timeout | Частота |
|----------|------|---------|---------|
| status | `… status` | 8000 | каждый `update()` |
| settings | `… settings list` | 8000 | каждый 5-й тик и после мутации |
| registration | `… registration show` | 8000 | каждый 10-й тик и после `register` |
| connect | `… connect` | 15000 | по команде |
| disconnect | `… disconnect` | 15000 | по команде |
| mode | `… mode <MODE>` | 15000 | по команде |
| families | `… dns families <MODE>` | 15000 | по команде |
| protocol | `… tunnel protocol set <PROTOCOL>` | 15000 | по команде |
| version | `{ "warp-cli", "--version" }` | 5000 | один раз при старте |

Только argv-форма. Никаких shell-строк, `grep`, `awk`, `curl`.

## Разбор и ошибки

### status

JSON `{"status":"Connected", …}` → `decoded.status`, lowercase, substring:

| Значение | `phase` |
|----------|---------|
| `connected` | `connected` |
| `connecting` / `reconnecting` | `connecting` |
| `disconnecting` | `disconnecting` |
| `disconnected` | `disconnected` |
| `registration missing` / `not registered` | `unregistered` |
| `unable to connect` | `error` |
| иное | `unknown` |

Fallback без JSON: `stdout:match("Status update:%s*(%S+)")` → та же таблица.

### settings

`decoded.settings` → `operation_mode` (lowercase → `mode`), `warp_tunnel_protocol`
(lowercase → `protocol`), `always_on`, `switch_locked`, `split_tunnel_mode`,
`split_tunnel_ips`/`split_tunnel_hosts` (только `#`, элементы `split_tunnel_ips` — объекты
`{ value, description }`, не строки).

Рядом в том же JSON есть `sources.<key>` (`"user_set"`, `"network_policy"`, …) —
это **не** значения настроек; читать только `decoded.settings`, `sources` игнорировать.

Fallback: построчный `Label: value` (`Mode:`, `WARP tunnel protocol:`, `Always On:`,
`Switch Locked:`). Если JSON декодировался, но `settings` нет — не затирать известные поля,
`errorCode = "decode-failed"`.

### registration

exit 0 → `registered = true`, `accountType = decoded.account.type or "unknown"`
(на 2026.8.2110.0: `"free"`; `managed` — отдельное булево, не используем).
exit ≠ 0 → `registered = false`, `accountType = "unknown"`.
`account.license`, `account.id`, корневой `id`, `public_key`, `device_id` **не читать в state
и не логировать** (панель/лог видят только `registered` + `accountType`).

### классификация ошибок

| Условие | `phase` | `errorCode` | `daemonOk` |
|---------|---------|-------------|------------|
| `not commandExists("warp-cli")` | `unavailable` | `cli-missing` | `false` |
| `runAsync` → `false` | `error` | `cli-missing`/`command-failed` | без изменений |
| `result.timedOut` | `error` | `timeout` | без изменений |
| exit≠0, stderr ~ `Registration`/`not registered` | `unregistered` | `unregistered` | `true` |
| exit≠0, stderr ~ `daemon`/`socket`/`connect to`/`service` | `error` | `daemon-down` | `false` |
| exit≠0 иное | `error` | `command-failed` | `true` |
| JSON не декодирован и fallback не дал `phase` | `unknown` | `decode-failed` | `true` |

### Families

- при инициализации сервиса `families` **принудительно** `unknown`
  (state переживает рестарт сервиса — старое значение не подхватывать);
- после успешного `dns families <MODE>` → `MODE`;
- после неуспешного — остаётся `unknown`;
- геттера не существует, поэтому сервис не пытается «прочитать» Families.

## Trace

```luau
noctalia.http({ url = "https://www.cloudflare.com/cdn-cgi/trace" }, function(res)
  if not res.ok then return end
  -- k=v построчно; берём warp, ip, loc, colo
end)
```

- при успехе: `trace = { warp, ip, loc, colo, atMs = noctalia.nowMs() }`;
- при ошибке: прежний `trace` не затирается, ошибка только в лог (не меняет `errorCode`);
- in-flight guard; результат старше одного `trace_interval_s` игнорируется;
- запускается по таймеру при `auto_trace = true` и всегда при `refresh`;
- никогда не блокирует status-поллинг.

## Уведомления

| Триггер | Условие | Ключи |
|---------|---------|-------|
| `disconnected` → `connected` | `notify_on_change` | `notify.connected.title` / `notify.connected.body` |
| `connected` → `disconnected` | `notify_on_change` | `notify.disconnected.title` / `notify.disconnected.body` |
| новый непустой `errorCode` ≠ `cli-missing` | `notify_on_error` | `notify.error.title` + `tr("error.<errorCode>")` |

Первая публикация после старта уведомлений не даёт. Один и тот же `errorCode` не
уведомляет повторно, пока не сменится на другой или не станет `""`.

## Настройки, используемые в Phase 1

| key | Использование |
|-----|---------------|
| `poll_interval_ms` | `noctalia.setUpdateInterval` |
| `notify_on_change` | уведомления о переходах |
| `notify_on_error` | уведомления об ошибках |
| `auto_trace` | включение таймера trace |
| `trace_interval_s` | период trace |

`show_text_in_bar`, `compact_mode` в Phase 1 не читаются (это Phase 2) — но объявлены
в манифесте с Phase 0, lint учитывает их как «прочитанные» в `widget.luau`.

## Files

| Файл | Действие |
|------|----------|
| `lib/state.luau` | `defaultStatus()`, `publish(patch)`, `setCommand(...)`, константы каналов |
| `lib/parse.luau` | чистые функции: `parseStatus`, `parseSettings`, `parseRegistration`, `parseTrace`, `classifyError` |
| `lib/commands.luau` | `argv`-билдеры + `run(base, cb, timeout)`; whitelist значений |
| `service.luau` | полный цикл, `dispatch`, `onIpc`, `state.watch`, `onConfigChanged`, `onEnable`, `onExit` |
| `translations/en.json`, `ru.json` | + `notify.*`, `error.*`, `status.*` |
| `README.md` | + список реальных процессов и network call |

`lib/*` не должны обращаться к entry-глобалам (`barWidget`, `panel`); им доступны только
`noctalia.*` и `ui.*`.

## Tasks (ordered)

1. `lib/parse.luau` — чистые функции + таблицы маппинга (без `noctalia.runAsync`).
2. `lib/commands.luau` — argv + whitelist + `run` с таймаутом.
3. `lib/state.luau` — дефолт, `publish`, отпечаток, `setCommand`.
4. `service.luau` — init: `commandExists`, настройки, `setUpdateInterval`, `watch`,
   первая публикация, `warp-cli --version`.
5. `update()` — тики: status каждый, settings 5, registration 10, trace по таймеру.
6. `dispatch()` + `onIpc` + `warp.command` (один обработчик).
7. Мутации: connect/disconnect/mode/families/protocol с `busy` и in-flight guard.
8. Уведомления.
9. `onConfigChanged`, `onEnable`, `onExit`.
10. Логи: transition, heartbeat, ipc, config, exit.
11. Прогон acceptance + отчёт (включая список всех argv и network call).

## Acceptance criteria

Перед прогоном зафиксировать baseline и выключить конкурирующие плагины:

```bash
noctalia msg plugins disable levi/warp
noctalia msg plugins disable code_warlord/warp_toggle

# baseline (записать в отчёт!)
warp-cli --accept-tos --json --no-paginate --no-ansi settings list \
  | python3 -c 'import json,sys;s=json.load(sys.stdin)["settings"];print(s["operation_mode"], s["warp_tunnel_protocol"])'
warp-cli --accept-tos --json --no-paginate --no-ansi status
```

**A. Офлайн**

- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`.
- [ ] `grep -Rn "curl\|os.execute\|io.popen" cloudflare-warp --include=*.luau` → пусто.
- [ ] `grep -Rn 'runAsync("' cloudflare-warp --include=*.luau` → пусто
      (только argv-форма `runAsync({`).
- [ ] `grep -Rn "getConfig" cloudflare-warp --include=*.luau` — все ключи объявлены в манифесте.
- [ ] В коде нет чтения `license`, `public_key`, `device_id`, `account.id`.

**B. Публикация статуса**

- [ ] Enable → в течение ~4 с в логе
      `cloudflare-warp: status phase=connected` (или фактическая фаза), и она совпадает с
      `warp-cli … status`.
- [ ] `noctalia msg plugin code-warlord/cloudflare-warp:service all refresh` →
      `ok: dispatched 1`, в логе `cloudflare-warp: ipc refresh payload=` и
      `cloudflare-warp: heartbeat … at=<n>`; `at` при повторном refresh растёт.
- [ ] Heartbeat появляется не чаще ~раз в 60 с (20 тиков) и не спамит лог.
- [ ] `families = unknown` после старта, даже если до рестарта сервиса было задано значение.
- [ ] `registered = true`, `accountType` совпадает с `registration show`; license в логе
      отсутствует (`grep -i license` по строкам плагина → пусто).

**C. Мутации (с восстановлением)**

- [ ] `… all toggle` → фаза меняется на `disconnecting`/`disconnected`, затем
      `… all toggle` возвращает `connected`. После теста `warp-cli status` = исходный.
- [ ] `… all set-mode "doh"` → `warp-cli settings list` показывает `operation_mode = "doh"`;
      вернуть baseline тем же событием.
- [ ] `… all set-protocol "wireguard"` → `settings list` показывает
      `warp_tunnel_protocol = "wireguard"`; вернуть baseline.
- [ ] `… all set-mode "bogus"` → warn в логе, CLI не вызывается, state не меняется.
- [ ] `… all set-families "bogus"` → warn, CLI не вызывается.
- [ ] `… all set-protocol "MÁSQUE"` (регистр) → принимается, в state `masque`.
- [ ] После каждой мутации `busy` снимается; повторная команда во время `busy` игнорируется.

**D. Ошибки**

- [ ] Статически: `commandExists("warp-cli")` проверяется до любого `runAsync`;
      при `false` выставляется `phase = unavailable`, `errorCode = cli-missing`.
      (Runtime-проверка «без warp-cli» требует отдельного PATH/машины и в этом окружении
      не выполняется — отметить как not-run.)
- [ ] `onConfigChanged`: изменить `poll_interval_ms` на 5000 → лог
      `cloudflare-warp: config changed poll=5000`, heartbeat реже, shell не перезапускается.
- [ ] `onExit`: disable → в логе `stopping service … (no longer active)`; на этой сборке
      Luau-хук `onExit` не вызывается (см. `docs/API-NOTES.md` §8). Процессов
      `warp-cli` не остаётся (`pgrep -af warp-cli` пусто).

**E. Уведомления**

- [ ] При `notify_on_change = true` toggle даёт ровно одно уведомление на переход.
- [ ] При `notify_on_error = true` искусственная ошибка (например, `set-mode` при
      `switch_locked`, если доступно) даёт одно уведомление, не поток.

**F. Восстановление окружения**

- [ ] `warp-cli status` = baseline.
- [ ] `settings list` mode/protocol = baseline.
- [ ] `levi/warp` и `code_warlord/warp_toggle` возвращены в исходное состояние.
- [ ] `CHANGELOG.md` содержит `0.2.0`.

## Risks

| Risk | Mitigation |
|------|------------|
| `set-families` необратим (нет геттера) | в автоматическом прогоне не вызывать с валидным значением; только invalid-value тест. Реальный вызов — вручную, с согласия владельца машины |
| Смена mode/protocol рвёт туннель | тест в конце, с восстановлением; предупредить в отчёте |
| «Дрожание» фазы (connect/disconnect) | публиковать по отпечатку + не спамить уведомления |
| Параллельные мутации | единый `actionInFlight` + `busy` в state |
| `http()` без таймаута | in-flight guard, устаревание результата |
| JSON-схема изменится | текстовый fallback + `decode-failed`, не затирать известное |

## Version bump

`0.1.0` → `0.2.0`
