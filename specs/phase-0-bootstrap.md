# Phase 0 — Bootstrap

**Target version:** `0.1.0` (MINOR)
**Goal:** плагин загружается в Noctalia 5.3.0, все 4 entry стартуют без ошибок, панель
открывается, `noctalia plugins lint` даёт `0 errors, 0 warnings`.

Исполнитель: **implementer**. Проверяющий: **qa**.
Референс фактов: [../docs/API-NOTES.md](../docs/API-NOTES.md), схема — [../docs/SPEC.md](../docs/SPEC.md) §3, §6, §7.

## Non-goals

- любые вызовы `warp-cli` (в Phase 0 плагин не порождает процессов);
- запись в `noctalia.state` и обработка IPC;
- polling, notifications, trace;
- SVG-ассеты и `lib/icons.luau`;
- реальные данные WARP в UI.

## Dependencies

Нет. `warp-cli` в Phase 0 не требуется (плагин должен включаться и на машине без WARP).

## State schema

Не используется. В Phase 0 **ни один** файл не вызывает `noctalia.state.set/get/watch`.

`lib/state.luau` содержит только константы и возвращает таблицу:

| Поле модуля | Значение |
|-------------|----------|
| `SCHEMA` | `1` |
| `CHANNEL_STATUS` | `"warp.status"` |
| `CHANNEL_COMMAND` | `"warp.command"` |
| `PHASES` | массив строк §3.1 SPEC |

## IPC contract

Не реализуется. `onIpc` в Phase 0 отсутствует — сервис игнорирует IPC (Noctalia пишет
`ok: dispatched 1`, обработчика нет).

## Settings

Объявить **весь финальный** набор (SPEC §6), чтобы манифест больше не менялся по составу.
Каждая настройка обязана читаться литеральным `noctalia.getConfig("<key>")`, иначе lint
даст warning «declared setting … is never read».

| key | scope | type | default | min/max |
|-----|-------|------|---------|---------|
| `poll_interval_ms` | plugin | int | 3000 | 1000 / 60000 |
| `notify_on_change` | plugin | bool | true | — |
| `notify_on_error` | plugin | bool | true | — |
| `auto_trace` | plugin | bool | true | — |
| `trace_interval_s` | plugin | int | 60 | 15 / 3600, `visible_when` auto_trace=true |
| `show_text_in_bar` | widget | bool | true | — |
| `compact_mode` | widget | bool | false | — |

В Phase 0 значения только читаются и складываются в локальный снимок сервиса; поведение
появится в Phase 1–2.

## Files to create

```
cloudflare-warp/
├── plugin.toml
├── service.luau
├── widget.luau
├── shortcut.luau
├── panel.luau
├── lib/
│   ├── state.luau
│   ├── parse.luau
│   └── commands.luau
├── translations/
│   ├── en.json
│   └── ru.json
└── README.md
```

Ничего вне этого списка. `.luau`-файлы в `lib/` — валидные модули (`return M`), даже если
пока пустые: `parse.luau` и `commands.luau` начнут использоваться в Phase 1, но создаются
сейчас по ROADMAP.

### plugin.toml

Скопировать каркас из SPEC §7 без изменений, кроме `version` (должен быть `0.1.0`).
Обязательные проверки:

- `id = "code-warlord/cloudflare-warp"`, `author = "code-warlord"`;
- `plugin_api = 24` (не 17 и не выше);
- `version = "0.1.0"`;
- `dependencies = ["cloudflare-warp"]`;
- ровно 4 entry: `service`, `widget`, `shortcut`, `panel`;
- `[widget.actions] right = "none"` присутствует;
- `[[panel]]` с `width = 380`, `height = 460`, `placement = "floating"`,
  `position = "auto"`, `open_near_click = true`.

### service.luau

Поведение:

- `local State = require("./lib/state.luau")` в самом верху — это доказывает, что
  `plugin_api = 24` реально покрывает модули;
- прочитать 5 plugin-level настроек в локальный снимок `settings`;
- `noctalia.setUpdateInterval(settings.poll_interval_ms)`;
- `noctalia.log("cloudflare-warp: bootstrap ok schema=" .. State.SCHEMA)`;
- `function update() end` — пустой тик;
- `onEnable()` / `onExit(_signal, reason)` — только лог;
- `onConfigChanged()` — перечитать `poll_interval_ms` и применить `setUpdateInterval`;
- никаких `runAsync`, `http`, `state.*`.

### widget.luau

Поведение:

- прочитать `show_text_in_bar`, `compact_mode` через `noctalia.getConfig`;
- `barWidget.setGlyph("cloud-lock")` (SVG — Phase 2, чтобы не блокировать Phase 0
  непроверенной растеризацией);
- `barWidget.setText` → `"WARP"` либо `""` при `compact_mode`/`show_text_in_bar = false`;
- `barWidget.setTooltip(noctalia.tr("widget.text.unknown"))`;
- `function update() end`;
- без `onClick`/`onRightClick` — они появятся в Phase 2;
- без чтения state.

### shortcut.luau

Поведение:

- `shortcut.setLabel(noctalia.tr("shortcut.off"))`;
- `shortcut.setIcon("cloud-lock", "cloud-off")`;
- `shortcut.setActive(false)`, `shortcut.setEnabled(true)`;
- без `onClick` и без state.

### panel.luau

Поведение:

- `function onOpen(_context)` → `panel.render(...)` с заголовком `tr("panel.title")` и
  одной строкой `tr("panel.placeholder")` + `tr("panel.version")` с версией плагина;
- без контролов и без state.

### translations/en.json и ru.json

Вложенный JSON (не плоские ключи), путь ключа = dotted-ключ. Минимум для Phase 0
(в обоих файлах одинаковый набор):

```
title
settings.poll_interval.label
settings.poll_interval.description
settings.notify_on_change.label
settings.notify_on_error.label
settings.auto_trace.label
settings.auto_trace.description
settings.trace_interval.label
settings.trace_interval.description
settings.show_text_in_bar.label
settings.compact_mode.label
widget.text.unknown
shortcut.off
panel.title
panel.placeholder
panel.version
```

`ru.json` — реальный русский текст, не копия английского.

### README.md

Минимум: что это, зависимость `cloudflare-warp`, `--accept-tos` (плагин принимает ToS
Cloudflare от имени пользователя), установка через path-source, список entry, IPC-примеры
пометить как «Phase 1+», лицензия MIT MIT.

## Tasks (ordered)

1. Создать дерево каталогов.
2. `plugin.toml` по SPEC §7, `version = "0.1.0"`.
3. `lib/state.luau` (константы) + пустые `parse.luau`, `commands.luau`.
4. `service.luau` (require + снимок настроек + логи).
5. `widget.luau`, `shortcut.luau`, `panel.luau` — заглушки по контракту выше.
6. `translations/en.json`, `translations/ru.json`.
7. `README.md`.
8. Локально: lint → path-source → enable → визуальная проверка → disable.
9. Запись в `CHANGELOG.md` (секция `0.1.0`) и отчёт implementer.

## Acceptance criteria

Все пункты проверяются на Noctalia 5.3.0 без `validate-plugin` (такой команды нет).

**A. Офлайн**

- [ ] `cd /home/code_warlord/DEV/cloudflare-warp-plugin && noctalia plugins lint cloudflare-warp`
      → exit 0, вывод `code-warlord/cloudflare-warp` / `ok` / `0 errors, 0 warnings`.
- [ ] `python3 -c "import tomllib;d=tomllib.load(open('cloudflare-warp/plugin.toml','rb'));print(d['id'],d['plugin_api'],d['version'])"`
      → `code-warlord/cloudflare-warp 24 0.1.0`.
- [ ] `grep -RnE "runAsync|noctalia\.http|io\.popen|os\.execute" cloudflare-warp --include=*.luau`
      → пусто (Phase 0 не порождает процессов).
- [ ] `grep -Rn "state\." cloudflare-warp --include=*.luau | grep -v "lib/state.luau"` → пусто.
- [ ] Наборы ключей en/ru совпадают:
      `python3 - <<'PY'` … сравнение **путей** вложенных ключей … `PY`
      (тот же сниппет, что в Phase 4 spec / `docs-i18n` skill).
- [ ] В `translations/*.json` присутствуют все `label_key`/`description_key` из манифеста.

**B. Загрузка**

- [ ] `noctalia msg plugins source add warpdev path /home/code_warlord/DEV/cloudflare-warp-plugin`
      → `ok`.
- [ ] `noctalia msg plugins list | grep cloudflare-warp`
      → `code-warlord/cloudflare-warp [warpdev] 0.1.0 disabled`.
- [ ] `noctalia msg plugins enable code-warlord/cloudflare-warp` → `ok …`.
- [ ] Через 2 с в `~/.cache/noctalia/noctalia.log` есть:
      `loaded plugin 'code-warlord/cloudflare-warp' (4 entries)`;
      `started service 'code-warlord/cloudflare-warp:service'`;
      `[script-runtime] cloudflare-warp: bootstrap ok schema=1`.
- [ ] В логе нет строк, содержащих `code-warlord/cloudflare-warp`, со словами
      `error`, `ERR`, `disabled after repeated timeouts`.
- [ ] В логе нет `[plugin-i18n] plugin translation key … not found` для наших ключей.

**C. UI**

- [ ] Виджет `code-warlord/cloudflare-warp:widget` добавляется на бар через
      Settings → Bar: показывает glyph `cloud-lock` и текст `WARP`.
- [ ] `compact_mode = true` → текст исчезает, glyph остаётся (применяется после
      переоткрытия настроек/перестройки виджета).
- [ ] Shortcut виден в Control Center, подпись из `shortcut.off`, иконка `cloud-lock`,
      не активен.
- [ ] `noctalia msg panel-toggle code-warlord/cloudflare-warp:panel` → exit 0, панель
      открывается с заголовком и placeholder; повторная команда закрывает.
      (Ошибка `unknown panel` = FAIL.)

**D. Выключение и чистота**

- [ ] `noctalia msg plugins disable code-warlord/cloudflare-warp` → `ok`, в логе
      `onExit` reason `disable` (строка `cloudflare-warp: exit reason=disable`).
- [ ] После disable в логе нет новых строк нашего плагина (никаких «фоновых» процессов).
- [ ] `noctalia msg plugins source remove warpdev` → `ok`; `plugins list` больше не
      содержит `cloudflare-warp`.
- [ ] `warp-cli status` не изменился (Phase 0 не трогает WARP).
- [ ] `CHANGELOG.md` содержит секцию `0.1.0` с записью Added.
- [ ] `STATE.md` обновлён **orchestrator**, не implementer.

## QA notes

- Перед прогоном выключить конкурирующие плагины, которые тоже управляют WARP:
  `noctalia msg plugins disable levi/warp` и
  `noctalia msg plugins disable code_warlord/warp_toggle`. Иначе несколько плагинов
  одновременно поллят `warp-cli`, а логи и панели путаются. После прогона вернуть как было.
- `noctalia msg plugins enable` отвечает `ok (exporting in background)` — дать ~1–2 с
  перед чтением лога.
- Виджет не появляется в логе, пока не размещён на баре: entry создаётся только при
  размещении. Для Phase 0 это ручной шаг QA.

## Risks

| Risk | Mitigation |
|------|------------|
| `plugin_api = 24` не поддержан сборкой | `noctalia --version` должен быть 5.3.0 (проверено на `v5.3.0`); иначе lint/enable покажет «unsupported plugin_api» |
| Манифест невалиден (TOML/поля) | lint + `tomllib` + enable; lint не ловит семантику — enable обязателен |
| Кириллица в JSON ломает парсер | UTF-8 без BOM, валидировать `python3 -m json.tool` |
| Заглушка виджета выглядит «сломанной» | glyph + текст `WARP`, tooltip «unknown» |

## Version bump

`0.0.0` → `0.1.0`
