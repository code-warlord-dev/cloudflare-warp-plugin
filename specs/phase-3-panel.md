# Phase 3 — Panel

> **Visual layer superseded (0.4.1):** актуальная редакция панели — 400×672, без
> `ui.scroll`, с full-bleed banner, анимациями и Families = Malware default — в
> [phase-3-panel-redesign.md](./phase-3-panel-redesign.md). Фрагменты ниже (manifest
> 360×700, scroll, unknown-caption) — **историческая редакция 0.4.0**. State/IPC/actions
> остаются в силе.

**Target version:** `0.4.0` (MINOR) + `0.4.1` (PATCH redesign)
**Goal:** полноценная declarative-панель: статус, mode, families, protocol, trace, регистрация,
быстрые действия. Все действия — через `warp.command`, панель сама ничего не запускает.

Исполнитель: **implementer**. Проверяющий: **qa**.
State/IPC: [../docs/SPEC.md](../docs/SPEC.md) §3–§4. UI API: [../docs/API-NOTES.md](../docs/API-NOTES.md) §10–§11.

## Non-goals

- WARP+ license purchase flow;
- Cloudflare Zero Trust org switcher;
- телеметрия туннеля (latency/loss/TLS/bytes);
- редактирование split tunnel списков;
- собственные настройки панели (используются plugin-level).

## Dependencies

Phase 1 (state + `warp.command`), Phase 2 (иконки/палитра состояний).

## Манифест панели

Уже объявлен в Phase 0, менять не нужно:

```toml
[[panel]]
id              = "panel"
entry           = "panel.luau"
width           = 360
height          = 700
placement       = "floating"
position        = "auto"
open_near_click = true
```

Размер host-owned: `width`/`height` только в манифесте, `setSize` не существует.
`layer` (нужен `plugin_api = 30`) не используем — 24 достаточно.

## State / IPC

Читает `warp.status` (таблица SPEC §3.1), пишет `warp.command` (SPEC §3.2).

| Действие UI | Запись в `warp.command` |
|-------------|--------------------------|
| Mode select | `{ seq, action = "set-mode", mode = <value>, source = "panel" }` |
| Families buttons | `{ seq, action = "set-families", families = <value>, source = "panel" }` |
| Protocol select | `{ seq, action = "set-protocol", protocol = <value>, source = "panel" }` |
| Refresh | `{ seq, action = "refresh", source = "panel" }` |
| Register | `{ seq, action = "register", source = "panel" }` |

> **Решение orchestrator (2026-10-20):** `toggle`/`connect`/`disconnect` в панельном UI
> **не выводятся** — переключение из бара и CC (Phase 2), панель фокусируется на
> конфигурации. Контракт payload сервиса не меняется (actions остаются в dispatch).

`seq = noctalia.nowMs()`. Никаких `warp.cmd`/`warp.cmd_payload`.

## UI structure

```
ui.column { gap = 12, padding = 14 }
  ├─ header: ui.glyph(status) + title + status label + Refresh + Close
  ├─ status card (fill = "surface_variant/0.4", radius = 10):
  │    phase label (цвет по фазе), message (если есть), updatedAt
  ├─ ui.scroll { flexGrow = 1 }:
  │    ├─ Mode: ui.select (7 значений)
  │    ├─ Families: 3 × ui.button (segmented) + caption
  │    ├─ Protocol: ui.select (2 значения)
  │    └─ identity: ip / loc / colo / warp + время trace
  ├─ actions: Copy IP | Register | Settings
  └─ footer: cliVersion + подсказка `warp-cli` (не версия плагина)
```

### Mode

- `options` — 7 подписей из `tr("mode.<id>")` в порядке
  `warp`, `doh`, `warp+doh`, `dot`, `warp+dot`, `proxy`, `tunnel_only`;
- `selectedIndex` = индекс `status.mode`, `-1`/`nil` если `mode == ""`;
- `onChange(index)` приходит **строкой** → `tonumber(index)`;
- при `status.switchLocked` → `enabled = false` + caption `tr("panel.mode.locked")`;
- при `status.busy` → `enabled = false`.

### Families — кнопки, не select

Причина: у `ui.select` нет «пустого» выбора, и он визуально соврёт, что текущее значение
известно. `warp-cli dns families` — write-only (API-NOTES §4).

```
ui.row { gap = 6 } {
  ui.button { text = tr("families.off"),     selected = (families == "off"),     onClick = "onFamiliesOff" },
  ui.button { text = tr("families.malware"), selected = (families == "malware"), onClick = "onFamiliesMalware" },
  ui.button { text = tr("families.full"),    selected = (families == "full"),    onClick = "onFamiliesFull" },
}
```

- ~~при `families == "unknown"` ни одна кнопка не `selected` + caption~~ — в 0.4.1
  заменено: выбранный сегмент есть всегда, неизвестное значение = Malware default;
- после успешной установки сервис публикует `families = <value>` — кнопка подсвечивается;
- кнопки disabled при `busy`.

### Protocol

`ui.select` c `["WireGuard", "MASQUE"]`; `selectedIndex` по `status.protocol`
(`wireguard` → 0, `masque` → 1, `unknown` → `nil` + placeholder `tr("panel.protocol.unknown")`).
При выборе — в команду уходит lowercase (`"wireguard"` / `"masque"`).

### Identity (trace)

| Поле | Если нет данных |
|------|------------------|
| `trace.ip` | `tr("panel.trace.none")` |
| `trace.loc` / `trace.colo` | `—` |
| `trace.warp` | `tr("panel.trace.warp." .. (warp == "plus" and "plus" or warp == "on" and "on" or "off"))` |
| `trace.atMs` | `formatTime("%H:%M", math.floor(atMs / 1000))` |

- `atMs == 0` → Copy IP disabled, вместо IP — `tr("panel.trace.none")`;
- `warp = "plus"` показывать как WARP+ (не путать с наличие license в аккаунте);
- trace-ошибка не показывается как ошибка WARP.

### Actions

| Кнопка | Условие | Действие |
|--------|---------|----------|
| Copy IP | `trace.ip ~= ""` | `noctalia.copyToClipboard(trace.ip, "text/plain")` |
| Register | `registered == false` | `warp.command.action = "register"` |
| Settings | всегда | `noctalia.openSettings()` (нужен `plugin_api ≥ 15`) |
| Refresh | всегда, кроме `busy` | `warp.command.action = "refresh"` |

### Состояния

- `busy` → дизейбл всех мутирующих контролов; в header — glyph `loader-2`/`refresh`.
- `available == false` → вместо контролов одна строка `tr("error.cli-missing")`,
  кнопка Settings остаётся.
- `phase == "unregistered"` → акцент на Register, mode/protocol disabled.
- `errorCode ~= ""` → строка ошибки цветом `error`, текст `tr("error." .. errorCode)`,
  `message` — мелким шрифтом, `maxLines = 2`.

### Перерисовка

```luau
local isOpen = false

function onOpen(_context)
  isOpen = true
  applyStatus(noctalia.state.get("warp.status"))
end

function onClose()
  isOpen = false
end

noctalia.state.watch("warp.status", function(value)
  applyStatus(value)
  if isOpen then render() end
end)
```

`panel.render(tree)` — в `onOpen` и после каждого изменения, пока панель открыта.
`panel.setNeedsFrameTick` не нужен (нет анимации).

## Files

| Файл | Действие |
|------|----------|
| `panel.luau` | заменить заглушку полной панелью |
| `lib/icons.luau` | + `statusGlyph(phase)` и цвет-роль для header (если ещё нет) |
| `translations/en.json`, `ru.json` | + `panel.*`, `mode.*`, `families.*`, `error.*` |
| `README.md` | + скриншот/описание панели, ограничение Families |

Сервис: если `register` ещё не реализован в Phase 1 — добавить обработчик здесь
(единственное разрешённое изменение сервиса в этой фазе).

## Tasks (ordered)

1. `register` в сервисе: `warp-cli registration new` (timeout 30000), затем refresh
   registration + status. Команда **интерактивная** (ждёт входа в браузере):
   `timedOut = true` → не `error`, а `notifyError(tr("error.register-pending"))`,
   `busy = false`, дальше обычный poll увидит `registered = true`.
   Реальная ошибка (exit ≠ 0 до таймаута) → `errorCode` + notify.
2. Каркас панели: header + status card + scroll-контейнер.
3. Mode select (7 значений, locked/busy).
4. Families segmented buttons + unknown-caption.
5. Protocol select.
6. Identity-блок (ip/loc/colo/warp/время).
7. Actions: Copy IP, Register, Settings, Refresh.
8. Состояния `busy` / `unavailable` / `unregistered` / `error`.
9. Локализация en + ru.
10. Прогон acceptance.

## Acceptance criteria

**A. Офлайн**

- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`.
- [ ] `grep -Rn "warp.cmd\b\|warp.cmd_payload" cloudflare-warp --include=*.luau` → пусто.
- [ ] `grep -Rn "state.set" cloudflare-warp/panel.luau` → только `warp.command`.
- [ ] `grep -Rn "runAsync\|noctalia.http" cloudflare-warp/panel.luau` → пусто.
- [ ] `grep -n "width\|height\|placement\|open_near_click" cloudflare-warp/plugin.toml`
      → 360 / 700 / floating / true.
- [ ] Все ключи `panel.*`, `mode.*`, `families.*`, `error.*` есть в en и ru.

**B. Открытие**

- [ ] `noctalia msg panel-toggle code-warlord/cloudflare-warp:panel` → exit 0, панель 360×700.
- [ ] ПК по bar-виджету открывает ту же панель.
- [ ] Escape и кнопка Close закрывают; повторный toggle тоже.
- [ ] Панель не открывает вторую копию при повторном toggle.

**C. Данные**

- [ ] Header показывает фазу, совпадающую с `warp-cli status`.
- [ ] Mode select показывает текущий `operation_mode` (сверить с `settings list`).
- [ ] Protocol select показывает текущий `warp_tunnel_protocol`.
- [ ] Identity: `ip`, `loc`, `colo` совпадают с
      `curl -s https://www.cloudflare.com/cdn-cgi/trace` (однократная сверка вручную),
      `warp=on` отображается как WARP on.
- [ ] При `auto_trace = false` и без refresh — `tr("panel.trace.none")`, Copy IP disabled.
- [ ] `families = unknown` → ни одна кнопка не подсвечена, виден caption.

**D. Действия (с восстановлением baseline)**

- [ ] Connect/Disconnect (IPC `…:service all connect/disconnect` или клик по виджету) переключает WARP; панель и виджет синхронны в пределах poll-интервала. (В панельном UI кнопки Connect/Disconnect не выводятся — решение orchestrator 2026-10-20, см. State/IPC.)
- [ ] Смена mode на `doh` → `settings list` показывает `operation_mode = "doh"`; вернуть baseline.
- [ ] Смена protocol → `settings list` отражает значение; вернуть baseline.
- [ ] Copy IP кладёт в буфер ровно `trace.ip` (проверить `noctalia msg clipboard-text`).
- [ ] Refresh обновляет `updatedAtMs`/время trace (видно по heartbeat в логе).
- [ ] Settings открывает страницу настроек **этого** плагина.
- [ ] Register виден только при `registered = false`.
- [ ] Register при незавершённом входе: по таймауту (30 с) панель **не** показывает `error`,
      приходит notify `error.register-pending`, `busy` снимается; после входа в браузере
      следующий poll переводит `registered` в `true` без ручного refresh.
- [ ] Во время `busy` контролы disabled; повторный клик не создаёт вторую команду.

**E. Ошибки**

- [ ] `available = false` (симуляция только статическая/на машине без WARP) → сообщение
      `error.cli-missing`, контролы скрыты, панель не падает.
- [ ] `switchLocked = true` → mode disabled + caption (проверить на MDM-профиле либо
      статически по коду; отметить, если не воспроизводимо).
- [ ] Панель не пишет в `warp.status` и не вызывает CLI.

**F. Финал**

- [ ] `warp-cli status` = baseline, mode/protocol = baseline.
- [ ] `CHANGELOG.md` содержит `0.4.0`.

## Risks

| Risk | Mitigation |
|------|------------|
| `ui.select` не имеет пустого выбора | ведущая unknown-опция (host выбирает option 0); Families: сегменты |
| `onChange` приходит строкой | всегда `tonumber` + проверка диапазона |
| Families необратим | предупреждение в UI-подписи не нужно, но в README — да; QA не меняет Families |
| `register` требует сети/интерактива | таймаут 30 с; `timedOut` → notify `error.register-pending`, а не `error`; панель не зависает |
| Высота 700 не вмещает контент | `ui.scroll` + `flexGrow = 1` |
| Смена protocol рвёт туннель | предупредить в README, не блокировать |

## Version bump

`0.3.0` → `0.4.0`
