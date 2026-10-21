---
name: qa
description: Test Cloudflare WARP Noctalia plugin via noctalia CLI, IPC, and manual acceptance. Produces pass/fail reports against phase specs.
---

# QA Skill

Проверяешь **поведение**, не стиль кода. Отчёт — строго PASS/FAIL по acceptance из phase-spec.

## Окружение

- Noctalia 5.3.0 (проверено), `plugin_api = 24`.
- `warp-cli 2026.8.2110.0`, демон `warp-svc` запущен, клиент зарегистрирован.
- Плагин включён через path-source.
- Лог: `~/.cache/noctalia/noctalia.log` (не `~/.local/state/...`).

## Подготовка (обязательно)

```bash
# 1. выключить конкурирующие WARP-плагины
noctalia msg plugins disable levi/warp
noctalia msg plugins disable code_warlord/warp_toggle

# 2. baseline — записать в отчёт
warp-cli --accept-tos --json --no-paginate --no-ansi status
warp-cli --accept-tos --json --no-paginate --no-ansi settings list \
  | python3 -c 'import json,sys;s=json.load(sys.stdin)["settings"];print(s["operation_mode"], s["warp_tunnel_protocol"])'

# 3. path-source на корень репозитория
noctalia msg plugins source add warpdev path /home/code_warlord/DEV/cloudflare-warp-plugin
noctalia msg plugins list | grep cloudflare-warp
noctalia msg plugins enable code-warlord/cloudflare-warp
sleep 2
```

## Команды

```bash
# офлайн-валидация (команды validate-plugin НЕ существует)
noctalia plugins lint cloudflare-warp

# IPC сервиса
noctalia msg plugin code-warlord/cloudflare-warp:service all refresh
noctalia msg plugin code-warlord/cloudflare-warp:service all toggle
noctalia msg plugin code-warlord/cloudflare-warp:service all connect
noctalia msg plugin code-warlord/cloudflare-warp:service all disconnect
noctalia msg plugin code-warlord/cloudflare-warp:service all set-mode "doh"
noctalia msg plugin code-warlord/cloudflare-warp:service all set-protocol "wireguard"
noctalia msg plugin code-warlord/cloudflare-warp:service all set-families "off"

# панель
noctalia msg panel-toggle code-warlord/cloudflare-warp:panel

# наблюдение
tail -f ~/.cache/noctalia/noctalia.log
grep -n "cloudflare-warp" ~/.cache/noctalia/noctalia.log | tail -20
```

Ожидаемые строки лога: `loaded plugin 'code-warlord/cloudflare-warp' (4 entries)`,
`cloudflare-warp: status phase=…`, `cloudflare-warp: heartbeat … at=…`,
`cloudflare-warp: ipc <event> payload=…`, `cloudflare-warp: exit reason=…`.

## Матрица (минимум)

| # | Кейс | Ожидание |
|---|------|----------|
| 1 | lint | `0 errors, 0 warnings` |
| 2 | enable | 4 entry, service стартует, лог без ERR |
| 3 | переводы | нет `plugin translation key … not found` |
| 4 | status poll | фаза в логе = `warp-cli status` |
| 5 | refresh | `ipc refresh` + heartbeat, `at` растёт |
| 6 | toggle | connect/disconnect, затем возврат в baseline |
| 7 | set-mode | `settings list` показывает новый `operation_mode` |
| 8 | set-protocol | `settings list` показывает новый `warp_tunnel_protocol` |
| 9 | invalid payload | warn в логе, CLI не вызван, state не изменён |
| 10 | families | при старте `malware`; сегмент всегда выбран; invalid-value не меняет CLI |
| 11 | widget | SVG + текст, ЛК панель, ПК toggle |
| 12 | shortcut | checked = connected, busy → disabled |
| 13 | panel | 400×734, без scrollbar, full-bleed banner 160, hero 21, mode/protocol, Families = malware, identity, Copy IP/Settings |
| 14 | panel animations | entrance, смена акцента/баннера, sine-волна в connecting, hover; в idle frame ticks выключены |
| 15 | poll_interval | смена настройки → heartbeat реже, без рестарта shell |
| 16 | disable/enable | лог `stopping service … (no longer active)`; на 5.3.0 `onExit` не вызывается; повторный enable чистый; смена width/height применяется только так |
| 17 | hot-reload | правка `.luau` → entry перезагружается, сервис жив |
| 18 | «нет warp-cli» | статически: `commandExists` до `runAsync`; runtime — not-run, если нет чистой машины |

## Ограничения окружения

- **Families необратим**: геттера нет. Менять реальное значение только вручную и с согласия
  владельца машины; в автоматическом прогоне — лишь invalid-value тест.
- Смена mode/protocol может разорвать туннель: делать в конце, восстанавливать baseline.
- Виджет появляется в логе только после размещения на баре (ручной шаг).
- `plugins lint` не проверяет translations/панель/исполнение кода — не считать его
  доказательством работоспособности.

## Отчёт

```markdown
## QA Report — Phase N / Task …

### Environment
- Noctalia: 5.3.0
- warp-cli: 2026.8.2110.0 (installed / registered)
- Baseline: phase=…, mode=…, protocol=…
- Competing plugins disabled: levi/warp, code_warlord/warp_toggle

### Results
| # | Case | Result | Notes |
|---|------|--------|-------|
| 1 | … | PASS/FAIL/NOT-RUN | … |

### Verdict: PASS | FAIL
### Blockers
### Restored state
- `warp-cli status` = …
- mode/protocol = …
```

## Правило

Если хоть один acceptance-пункт не PASS → вердикт FAIL, без «мягких» зачётов.
Каждый NOT-RUN требует причины и не считается PASS.
