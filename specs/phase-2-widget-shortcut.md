# Phase 2 — Bar Widget + Control Center Shortcut

**Target version:** `0.3.0` (MINOR)
**Goal:** пользователь видит состояние WARP в баре (SVG) и может переключать его из бара и
Control Center; shortcut синхронен с сервисом.

Исполнитель: **implementer**. Проверяющий: **qa**.
State/IPC: [../docs/SPEC.md](../docs/SPEC.md) §3–§4. Иконки: [../docs/API-NOTES.md](../docs/API-NOTES.md) §11.

## Non-goals

- панель с mode/families/protocol (Phase 3);
- анимация connecting (статичный SVG достаточно);
- телеметрия туннеля;
- изменения в сервисе, кроме обработки `warp.command` (уже в Phase 1).

## Dependencies

Phase 1: `warp.status` публикуется, `warp.command` обрабатывается.

## Политика иконок

**Бар — SVG через `barWidget.setImage`, не `setGlyph`.**
Причина: узнаваемость бренда WARP, glyph из Tabler не передаёт состояние.

```luau
barWidget.setImage("assets/icons/warp-on.svg", false, 16, 16)
barWidget.setText(showText and noctalia.tr("widget.text.on") or "")

-- fallback, если файл не найден/не отрисован
barWidget.setGlyph("cloud-lock")
```

Императивный путь обязателен: после `barWidget.render(tree)` вызовы
`setImage/setText/setGlyph` не дают эффекта (host пишет warning в лог).

| `phase` | SVG | Текст (`show_text_in_bar`, не `compact_mode`) |
|---------|-----|-----------------------------------------------|
| `connected` | `assets/icons/warp-on.svg` | `tr("widget.text.on")` |
| `disconnected` | `assets/icons/warp-off.svg` | `tr("widget.text.off")` |
| `connecting`, `disconnecting` | `assets/icons/warp-connecting.svg` | `tr("widget.text.connecting")` |
| `unregistered` | `assets/icons/warp-warn.svg` | `tr("widget.text.register")` |
| `error`, `unavailable` | `assets/icons/warp-error.svg` | `tr("widget.text.error")` |
| `unknown` | `assets/icons/warp-off.svg` | `tr("widget.text.unknown")` |

Требования к SVG:

- `viewBox="0 0 24 24"`, квадрат, без внешних отступов;
- один `fill`/`currentColor`, чтобы хост мог тонировать; без встроенных градиентов;
- размер в баре — 16×16 (`setImage(path, false, 16, 16)`);
- собственная стилизованная отрисовка (щит/облако/дуга), **не** копия официального логотипа
  Cloudflare 1:1 — note про trademark в README.

`lib/icons.luau` — единственное место маппинга: `path(phase)`, `glyph(phase)`, `textKey(phase)`.

## Shortcut: ограничение API

`shortcut.setIcon(on, off)` принимает **только glyph-имена**, не пути к SVG
(сверено с документацией и живым `levi/warp`).

```luau
shortcut.setLabel(noctalia.tr(labelKey(phase)))
shortcut.setIcon("cloud-lock", "cloud-off")   -- on, off
shortcut.setActive(phase == "connected" or phase == "connecting")
shortcut.setEnabled(status.available and not status.busy)
```

SVG-пара в Control Center в Phase 2 **не делается** — это не упрощение, а предел API.
Зафиксировать в README/CHANGELOG, чтобы не выглядело недоделкой.

## State schema

Только чтение `warp.status` (таблица, см. SPEC §3.1). Запись — только в `warp.command`.

| Канал | Кто пишет | Что |
|-------|-----------|-----|
| `warp.status` | service | читают widget и shortcut через `get` + `watch` |
| `warp.command` | widget, shortcut | `{ seq, action, source }` |

`seq = noctalia.nowMs()` — обязателен, иначе сервис может проигнорировать команду как
повтор (правило `seq <= lastHandledSeq`).

Старые ключи `warp.cmd` / `warp.cmd_payload` **не используются** — их нет.

## Settings

Только widget-scope, объявлены с Phase 0:

| key | Эффект |
|-----|--------|
| `show_text_in_bar` | `false` → `barWidget.setText("")` |
| `compact_mode` | `true` → текста нет независимо от `show_text_in_bar` |

Настройки читаются на top-level виджета; после изменения host перестраивает widget-entry,
поэтому `onConfigChanged` не нужен.

## Files

| Файл | Действие |
|------|----------|
| `assets/icons/warp-on.svg` | новый |
| `assets/icons/warp-off.svg` | новый |
| `assets/icons/warp-connecting.svg` | новый |
| `assets/icons/warp-warn.svg` | новый |
| `assets/icons/warp-error.svg` | новый |
| `lib/icons.luau` | новый: `path`, `glyph`, `textKey`, `tooltipRows` |
| `widget.luau` | заменить заглушку: state, иконка, текст, tooltip, клики |
| `shortcut.luau` | заменить заглушку: label/icon/active/enabled, клики |
| `translations/en.json`, `ru.json` | + `widget.text.*`, `widget.tooltip.*`, `shortcut.*` |
| `README.md` | + раздел про клики и про glyph в Control Center |

Сервис не меняется. Если для кликов понадобится что-то ещё — это сигнал, что Phase 1
сделан неверно; эскалировать, а не патчить сервис.

## Tasks (ordered)

1. Нарисовать 5 SVG (24×24, монохром).
2. `lib/icons.luau` — маппинг phase → path/glyph/textKey.
3. `widget.luau`: `applyStatus(table)`, `render()`, `watch` + первичный `get`.
4. Tooltip: массив строк `{ key, value }` — status, mode, families (если ≠ unknown),
   protocol, ip (если есть), message/errorCode.
5. Клики: ЛК → `toggle` (игнор при `busy`), ПК → `togglePanel`.
6. `shortcut.luau`: label/icon/active/enabled + ЛК toggle, ПК refresh (опционально).
7. Локализация всех строк, en + ru.
8. Fallback: отсутствующий SVG → glyph + одна строка в лог (не спамить).

## Acceptance criteria

**A. Офлайн**

- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`.
- [ ] Все 5 SVG на месте и валидны:
      `for f in cloudflare-warp/assets/icons/*.svg; do python3 -c "import xml.etree.ElementTree as E,sys;E.parse(sys.argv[1])" "$f" || echo "BAD $f"; done`
      → нет `BAD`.
- [ ] `grep -Rn "warp.cmd\b\|warp.cmd_payload" cloudflare-warp --include=*.luau` → пусто.
- [ ] `grep -Rn "state.set" cloudflare-warp/widget.luau cloudflare-warp/shortcut.luau`
      → только `warp.command`, ни одной записи в `warp.status`.
- [ ] В `widget.luau`/`shortcut.luau` нет `runAsync`, `http`, чтения файлов.

**B. Бар**

- [ ] Виджет размещён на баре: видна **SVG**-иконка (не glyph) и текст `On`/`Off`.
- [ ] `noctalia msg plugin code-warlord/cloudflare-warp:service all toggle` → в течение
      одного poll-интервала иконка и текст меняются на противоположные.
- [ ] ЛК по виджету переключает WARP (проверить `warp-cli status`).
- [ ] ПК по виджету открывает панель (`code-warlord/cloudflare-warp:panel`).
      Если панель не открывается — проверить `[widget.actions] right = "none"` в манифесте.
- [ ] `compact_mode = true` → текста нет, иконка есть.
- [ ] `show_text_in_bar = false` → текста нет; `compact_mode = false` не возвращает текст.
- [ ] Tooltip содержит статус; при `connected` — mode/protocol/ip; при `unknown` — не врёт
      про Families.
- [ ] Переименовать `warp-on.svg` → при `connected` виджет показывает glyph `cloud-lock`,
      не падает, в логе одна запись про fallback. Вернуть файл.
- [ ] В логе нет `setText/setGlyph/setImage … have no visible effect` (значит `render()` не
      вызывается).

**C. Control Center**

- [ ] Плитка видна, подпись соответствует фазе, иконка `cloud-lock`/`cloud-off`.
- [ ] `setActive` = true при `connected`/`connecting`, false иначе.
- [ ] При `busy` плитка disabled.
- [ ] Клик по плитке переключает WARP и виджет синхронизируется в пределах интервала.

**D. Устойчивость**

- [ ] Hot-reload: правка `widget.luau` на сохранении перезагружает entry, виджет
      продолжает обновляться, сервис не перезапускается.
- [ ] Disable/enable плагина: виджет и плитка не «залипают» в старом состоянии.
- [ ] `warp-cli status` после тестов = baseline.
- [ ] `CHANGELOG.md` содержит `0.3.0`.

## Risks

| Risk | Mitigation |
|------|------------|
| Хост не растеризует SVG | ранняя проверка в Phase 2; fallback glyph; при провале — PNG 1x/2x |
| Нет тонировки SVG | отдельные on/off артефакты, один `fill` |
| `setIcon` не принимает SVG | принято как ограничение API, задокументировать |
| Клик не доходит до `onRightClick` | `right = "none"` в манифесте |
| Текст «прыгает» из-за длины | фиксированные короткие строки в `widget.text.*` |
| Trademark | стилизованный знак + note в README |

## Version bump

`0.2.0` → `0.3.0`
