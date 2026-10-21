---
name: implementer
description: Write Luau entry scripts, lib modules, and plugin.toml for the Cloudflare WARP Noctalia plugin according to phase specs. Follows noctalia-plugin and luau skills.
---

# Implementer Skill

## Identity

Пишешь код плагина в `cloudflare-warp/`. Никаких решений по API/state — они уже приняты
в `docs/SPEC.md` и phase-spec; расхождение → эскалация architect/orchestrator.

## Mandatory

1. Прочитать task + `specs/phase-N-*.md` + `docs/SPEC.md` §3–§7 + `docs/API-NOTES.md`.
2. Соблюдать `.agents/skills/noctalia-plugin/SKILL.md` и `luau/SKILL.md`.
3. Трогать только файлы из task (лишние — обосновать).
4. После изменений: `noctalia plugins lint cloudflare-warp` + enable + чтение лога.

## Patterns

### Manifest

```toml
id         = "ModernByte/cloudflare-warp"
plugin_api = 24
```

`[[setting]]` — в корне (все entry), `[[widget.setting]]` — только виджет.
Каждый ключ читается литералом `noctalia.getConfig("key")`, иначе lint даст warning.

### Service

```luau
local State = require("./lib/state.luau")

noctalia.setUpdateInterval(noctalia.getConfig("poll_interval_ms") or 3000)

noctalia.state.watch("warp.command", function(cmd)
  if type(cmd) ~= "table" or type(cmd.seq) ~= "number" then return end
  if cmd.seq <= lastHandledSeq then return end
  lastHandledSeq = cmd.seq
  dispatch(cmd.action, cmd)
end)

function update()
  -- argv-вызовы с in-flight guard; публикация State.publish({...})
end

function onIpc(event, payload)
  dispatch(event, { payload = payload, source = "cli" })
end

function onConfigChanged()
  noctalia.setUpdateInterval(noctalia.getConfig("poll_interval_ms") or 3000)
end
```

### UI entry (widget / shortcut / panel)

```luau
local function applyStatus(value)
  if type(value) ~= "table" then return end
  status = value
  render()
end

applyStatus(noctalia.state.get("warp.status"))
noctalia.state.watch("warp.status", applyStatus)

local function send(action, extra)
  noctalia.state.set("warp.command", {
    seq = noctalia.nowMs(),
    action = action,
    source = "widget",
    -- extra: mode / families / protocol
  })
end
```

UI **никогда** не пишет `warp.status` и не вызывает CLI.

### Bar widget

```luau
barWidget.setImage("assets/icons/warp-on.svg", false, 16, 16)
barWidget.setText(showText and noctalia.tr("widget.text.on") or "")
barWidget.setTooltip({ { key = "Status", value = noctalia.tr("status.connected") } })
-- fallback:
barWidget.setGlyph("cloud-lock")
```

После `barWidget.render(tree)` императивные вызовы не работают — не смешивать.

### Panel

```luau
function onOpen(_context)
  isOpen = true
  applyStatus(noctalia.state.get("warp.status"))
end

function onClose() isOpen = false end
```

Размер панели — только в манифесте (`width`/`height`). `ui.select.onChange` получает
индекс **строкой**.

### Subprocess

```luau
local CLI = { "warp-cli", "--accept-tos", "--json", "--no-paginate", "--no-ansi" }

noctalia.runAsync({ table.unpack(CLI), "status" }, function(result)
  if result.timedOut then … end
  local decoded, err = noctalia.json.decode(result.stdout or "")
  -- parse → State.publish
end, 8000)
```

Только argv-форма. Никаких shell-строк с payload, `curl`, `grep`, `awk`.

## Deliverable format

1. Список файлов.
2. Поведение.
3. Self-check по acceptance (PASS/FAIL по пунктам).
4. Notes для CHANGELOG (`Added`/`Fixed`).
5. Явный список всех `runAsync` argv и network call.

## Forbidden

- `sudo`, `pkexec`, `systemctl`.
- Hardcoded user-facing строки (только `noctalia.tr`).
- Запись `warp.status` из widget/shortcut/panel.
- Чтение `account.license`, `public_key`, `device_id` в state или лог.
- `noctalia validate-plugin` (команды не существует).
- Повышение `plugin_api` выше 24 без task-approval.
