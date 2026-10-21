# Phase 3 — Panel Redesign v2

**Target version:** `0.4.1` (PATCH — UI revision внутри Phase 3; state/IPC не меняются)
**Base:** `origin/main` @ `3cf4813` (Phase 3 panel 0.4.0)
**Entry:** `cloudflare-warp/panel.luau`
**Asset:** `cloudflare-warp/assets/hero-banner.jpeg` (source for the two derived PNGs)

> **Superseded (0.4.3):** баннер заменён анимированной секвенцией — 27 WebP-кадров
> 800×320 в `assets/banner/` (источник `assets/wGjQl.gif`, запечённая насыщенность
> 20 → 100 %), высота 160 px, панель 400×734. Актуальные параметры —
> [docs/DESIGN-PANEL.md](../docs/DESIGN-PANEL.md). §2 и `ui.image`/геометрия в §3 ниже —
> историческая редакция 0.4.1.

Цель — заменить «админскую форму» на премиальный network control surface:
статус → действия → детали, один loud-акцент, честные unknown-значения там, где CLI
их реально отдаёт, и живой отклик на действия.

---

## 1. Visual system

| Token | Value | Use |
|-------|-------|-----|
| `brand-orange` | `#F6821F` | header glyph, disconnected hero accent |
| `brand-warm` | `#FFA53B` | optional warm highlight (not large areas) |
| `cyan` | `#59D6FF` | Families selection, data accent, connecting |
| `success` | `#3BE3A3` | connected hero accent |
| `danger` | `#FF5C6C` | error/unavailable hero accent |
| `warning` | `#FFB340` | unregistered hero accent |
| `neutral` | `#8A93A6` | unknown hero accent |
| `surface-card` | role `surface_variant/0.35` | identity card, controls |
| `outline` | role `outline/0.35` | card borders |
| text primary | role `on_surface` | titles, status, values |
| text secondary | role `on_surface_variant` | labels, captions, timestamps |

Правила:

- Один «кричащий» акцент за раз: hero border/fill. Families selected — cyan **низкой
  интенсивности** (`#59D6FF1F` fill, `#59D6FF99` border). Header glyph — маленький оранжевый.
- Радиусы: hero 16, segments 9, segmented track 12, identity 16, controls host-default.
- Тёмная тема — целевая; поверхности/текст берём из role-токенов, чтобы light theme
  оставалась читаемой. Бренд-акценты — hex.
- Hex с альфой — 8 цифр (`#RRGGBBAA`), role с альфой — `role/0.35`.
- Никаких literal user-facing строк в `panel.luau`; только `noctalia.tr`.

---

## 2. Assets (banner)

Сделать из `assets/hero-banner.jpeg` два PNG 720×192 (с запасом для панели 400×96):

```bash
cd cloudflare-warp/assets
magick hero-banner.jpeg -resize 720x -gravity center -crop 720x192+0+0 +repage /tmp/hero-color.png
# bottom alpha fade: last 80 px → transparent
magick -size 720x192 xc:white \
  \( -size 720x80 gradient:white-black \) -geometry +0+112 -compose over -composite /tmp/hero-mask.png
magick /tmp/hero-color.png /tmp/hero-mask.png -alpha off -compose CopyOpacity -composite hero-banner-color.png
# idle: cooler, desaturated, dimmer
magick /tmp/hero-color.png -modulate 65,35,100 -fill '#1A2A4A' -colorize 18% /tmp/hero-idle-base.png
magick /tmp/hero-idle-base.png /tmp/hero-mask.png -alpha off -compose CopyOpacity -composite hero-banner-idle.png
```

- `hero-banner-color.png` — connected (full brightness).
- `hero-banner-idle.png` — disconnected / unregistered / error / unavailable.
- Connecting/disconnecting — color asset с `opacity = 0.65`.
- Исходный JPEG оставить в репозитории (README/соцсети), PNG — UI.

Banner в панели: root отменяет горизонтальный host-inset (`paddingH = -14`), а
banner-wrapper-колонка `height = 82` получает `paddingV = -14` и содержит
`ui.image({ path = ..., width = 400, height = 96, radius = 12, fit = "cover",
opacity = <по фазе × entrance> })`. Изображение начинается в точке (0,0) панели,
боковой отступ равен 16 px; нижний fade — из PNG.

---

## 3. Panel layout

Manifest: `width = 400`, `height = 672`, `placement = "floating"`, `position = "auto"`,
`open_near_click = true`. Высота фиксированная (host-owned); `ui.scroll` **не
используется**, потому что хост всегда рисует его scrollbar.

> Решения после live-прогона и fix round владельца: 400×672 вместо 360×700; scroll
> убран полностью; version caption убран; power — `md`; hero status 21 px, чтобы
> «Подключение…» помещалось; ошибка свёрнута в subtitle; footer прижат `flexGrow`;
> боковые поля 16 px — root отменяет host-inset 14 px (`paddingH = -14`).

```
root column (gap=0, paddingH=-14, paddingV=0, align="stretch", flexGrow=1)
├─ banner-wrap column (height=82, paddingV=-14)
│   └─ ui.image (400×96, radius=12)
├─ header row (paddingH=16, paddingV=8, align=center, gap=8)
│   ├─ glyph cloud-lock 18 brand-orange
│   ├─ label "Cloudflare WARP" 15 bold
│   ├─ spacer flexGrow=1
│   ├─ refresh ui.button glyph=refresh|loader-2, ghost, pulse во время фидбека
│   └─ close   ui.button glyph=close, ghost
├─ content-body column (flexGrow=1, gap=10, paddingH=16, paddingV=6, opacity=entrance)
│   ├─ hero/status card (radius=16, borderWidth=1, paddingH=16, paddingV=12)
│   │   ├─ row: status glyph 22 accent + status label 21 bold + power button
│   │   ├─ row: subtitle 12 secondary (flexGrow=1, maxLines=2) + "Обновлено HH:MM" 11
│   │   └─ connecting/disconnecting: ui.progress 3 px
│   ├─ controls row (gap=10)
│   │   ├─ column flexGrow=1: label "Режим" + ui.select
│   │   └─ column flexGrow=1: label "Протокол" + ui.select
│   ├─ (optional caption under row) mode locked
│   ├─ families: label + segmented row (без caption)
│   └─ identity card (radius=16, padding=12, gap=5)
│       ├─ title row "Сетевая идентичность" 13 semibold + glyph world cyan
│       ├─ separator
│       └─ 5 key/value rows: IP (+copy), Локация, Edge, WARP, Трассировка
├─ separator outline/0.25
├─ footer actions row (paddingH=16, paddingV=8, gap=8)
```

### Hero / status

Фазы:

| phase | accent | banner | subtitle key |
|-------|--------|--------|--------------|
| connected | success | color, 1.0 | `panel.hero.subtitle.connected` |
| disconnected | brand-orange | idle, 1.0 | `panel.hero.subtitle.disconnected` |
| connecting | cyan | color, 0.65 | `panel.hero.subtitle.connecting` |
| disconnecting | cyan | color, 0.65 | `panel.hero.subtitle.disconnecting` |
| unregistered | warning | idle, 0.9 | `panel.hero.subtitle.unregistered` |
| error | danger | idle, 0.85 | `panel.hero.subtitle.error` |
| unavailable | danger | idle, 0.85 | `panel.hero.subtitle.unavailable` |
| unknown | neutral | idle, 0.85 | `panel.hero.subtitle.unknown` |

- Hero fill: `#RRGGBB14` (accent at ~8%); border: `#RRGGBB66`; text status — `on_surface`.
- Status glyph: `Icons.statusGlyph(phase, busy)`; busy → `loader-2`.
- Power button (`glyph="power"`, `controlSize="md"`):
  - connected/connecting/disconnecting → `variant="outline"`, tooltip «Отключить WARP»;
  - остальные → `variant="primary"`, tooltip «Подключить WARP»;
  - `enabled = available and not busy and phase not in {unregistered, unavailable}`;
  - `onClick` → `State.setCommand("toggle", { source = "panel" })`.
- `updatedAtMs > 0` → `noctalia.formatTime("%H:%M", floor(ms/1000))`, иначе `—`.
- Error: свернуть `noctalia.tr("error." .. errorCode)` и `status.message` в subtitle
  через `" — "` (maxLines=2), чтобы карточка не меняла высоту. `unavailable` —
  subtitle `error.cli-missing`, контролы скрыты.

### Controls

- Mode: 7 подписей `mode.<id>` в порядке `warp, doh, warp+doh, dot, warp+dot, proxy,
  tunnel_only`; известное значение → `options = labels`, `selectedIndex = index`.
  Host-select всегда выбирает option 0, поэтому unknown → ведущая опция
  `panel.mode.unknown` + `selectedIndex = 0`; обработчик игнорирует этот индекс.
  `onChange` → `tonumber`, offset, bounds, guard, только если значение изменилось.
- Protocol: `["WireGuard", "MASQUE"]`; та же схема unknown с ведущей опцией
  `panel.protocol.unknown`; в команду lowercase.
- Disabled: `available == false`, `busy`, `registered == false`; Mode дополнительно
  `switchLocked`. Caption `panel.mode.locked` под рядом.
- При `busy` — `opacity = 0.55` на controls row и Families.

### Families (DNS filtering)

- Segmented control: outer row `fill="surface_variant/0.45"`, `border="outline/0.25"`,
  `borderWidth=1`, `radius=12`, `padding=3`, `gap=3`; три сегмента `height=38`, `radius=9`,
  `flexGrow=1`, `align="center"`, `justify="center"`, `onClick` на весь сегмент.
- Selected: `fill="#59D6FF1F"`, `border="#59D6FF99"`, `borderWidth=1`,
  label `on_surface` semibold. Unselected: **явные** `fill="#00000000"`,
  `border="#00000000"`, `borderWidth=1` (host сохраняет отсутствующие flex-стили —
  иначе после смены значения остаётся stale cyan), label `on_surface_variant`.
- Выбранный сегмент есть всегда: `families` вне `off|malware|full` презентуется как
  `malware` (Cloudflare default). Caption про unknown удалён.
- Hover: `onHover="familiesHover"` (стабильное имя), fill/border усиливаются с tau 70 ms.
- Клик → `State.setCommand("set-families", { families = value, source = "panel" })`
  только если значение отличается и не busy.

### Identity

- IP: полный или сокращённый IPv6 (середина → `…`, максимум ~28 символов), `maxLines=1`,
  `textAlign="end"`; рядом ghost-кнопка `copy` 32 px. Копируется **полный** IP.
- Пусто: `panel.trace.none` = «неизвестно»; copy disabled.
- Локация / Edge: код или `—`.
- WARP: `panel.trace.warp.on|plus|off`; пусто → `panel.trace.warp.unknown`.
- Трассировка: время `trace.atMs` или `panel.trace.never` («не выполнялась»).
- Карточка: `fill="surface_variant/0.35"`, `border="outline/0.35"`, `borderWidth=1`,
  `radius=16`, `padding=12`, `gap=5`.

### Footer

- Copy IP: `variant="outline"`, `glyph="copy"`, `flexGrow=1`, enabled только при непустом IP.
- Register: `variant="primary"`, `glyph="user-plus"`, `flexGrow=1` — **только**
  `registered == false`; заменяет Copy IP.
- Settings: `variant="ghost"`, `glyph="settings"`.
- Copy feedback: на ~1.6 с текст «Скопировано», glyph `check`, цвет success; используется
  `panel.setWantsSecondTicks(true)` + `update()` (очистка на первом тике после дедлайна),
  затем ticks выключаются. Кнопка copy в identity-строке в это окно заменяется на
  success-check, чтобы feedback был и у незарегистрированного клиента (Register занял footer).
- Manual refresh: локальный `refreshUntilMs` 1.5 с, header refresh показывает `loader-2`
  и disabled; ticks как у copy.

---

## 4. Behavior / guards

- Panel — renderer + command writer: **никаких** `runAsync`, `noctalia.http`, `state.set`
  кроме `warp.command` через `State.setCommand`; `warp.status` не писать.
- Анимации: `panel.setNeedsFrameTick(true)` + `onFrameTick(deltaMs)`, шаг 33 ms;
  entrance 420 ms; акцент tau 140 ms; баннер tau 180 ms; progress 1600 ms;
  banner pulse 2200 ms; refresh pulse 650 ms; hover tau 70 ms. Тики выключаются,
  когда анимаций нет, и при закрытии.
- `onOpen` → `applyStatus(state.get)` до `isOpen = true`, затем сброс animated state,
  `entranceT = 0`, frame ticks, render.
- `state.watch` → обновить `status`, render если open.
- `onClose` → `isOpen = false`, `panel.setWantsSecondTicks(false)`, сбросить feedback.
- Все мутирующие callbacks проверяют `busy`, `available`, `registered`; повторный клик
  не создаёт вторую команду.
- Refresh / Settings / Close работают всегда (Refresh disabled при busy).
- `noctalia.openSettings()` для настроек; `panel.close()` для закрытия.
- Регистрация: `State.setCommand("register", { source = "panel" })`; сервис уже умеет
  `register` (0.4.0), не менять его.
- `plugin_api` остаётся **24**. `panel.setWantsSecondTicks` доступен с 18.
- Никаких новых settings.

---

## 5. i18n (en + ru, полный паритет)

Добавить/обновить:

```
panel.title
panel.updated
panel.mode.unknown
panel.mode.locked
panel.protocol.unknown
panel.section.mode
panel.section.protocol
panel.section.families        // ru: "DNS-фильтрация"
panel.section.identity
panel.identity.ip|loc|colo|warp|time
panel.trace.none
panel.trace.never
panel.trace.warp.on|plus|off|unknown
panel.hero.subtitle.connected|disconnected|connecting|disconnecting|unregistered|error|unavailable|unknown
panel.action.copy_ip|copied|settings|register|refresh|close|connect|disconnect
```

`mode.*`, `families.*`, `error.*`, `status.*` уже есть — переиспользовать.

---

## 6. Acceptance

**Offline**
- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`.
- [ ] `grep -Rn "runAsync\|noctalia.http" cloudflare-warp/panel.luau` → пусто.
- [ ] `grep -Rn "state.set" cloudflare-warp/panel.luau` → только через `State.setCommand`
      (нет прямого `noctalia.state.set`).
- [ ] en/ru: одинаковый набор ключей; все `panel.*` резолвятся.
- [ ] `plugin.toml`: 0.4.1, panel 400×672, `plugin_api = 24`.
- [ ] Assets: `hero-banner-color.png`, `hero-banner-idle.png` 720×192, alpha у нижнего края.

**Visual (live, 5.3.0)**
- [ ] Connected: баннер яркий, hero green, статус читается первым, «Обновлено» видно.
- [ ] Disconnected: баннер приглушён, hero orange, контролы активны, power primary.
- [ ] Connecting: баннер 0.65, hero cyan, `loader-2` в header и hero, контролы dim.
- [ ] Families selected — cyan низкой интенсивности; неизвестное значение показывает Malware.
- [ ] Banner выходит на край панели без боковых полей; нижний fade виден.
- [ ] IP-строка не ломает сетку на длинном IPv6; copy кладёт полный IP.
- [ ] Все hit-target ≥ 32 px; selects/segments ≥ 38 px.
- [ ] Нет scrollbar и обрезанного контента при 400×672 во всех штатных состояниях.
- [ ] Анимации: entrance, смена акцента/баннера, progress и banner pulse в connecting,
      refresh pulse, hover сегментов; в idle frame ticks выключены.
- [ ] Скриншоты: connected / disconnected / connecting + close-up hero + close-up families.

**Runtime**
- [ ] Панель открывается/закрывается toggle, Escape, close.
- [ ] Правка `.luau` подхватывается hot-reload без ошибок в логе.
- [ ] Copy IP → clipboard (`noctalia msg clipboard-text`), feedback «Скопировано».
- [ ] Settings открывает страницу плагина.
- [ ] Refresh обновляет `updatedAtMs`/trace (видно по логу/цифрам).
- [ ] Во время `busy` контролы disabled; второй клик не создаёт команду.
- [ ] `available=false` (статическая проверка/симуляция) — контролы скрыты, Settings есть.
- [ ] WARP state на машине не менялся (кроме случаев, явно согласованных с владельцем).

**Screenshots / docs**
- [ ] `docs/assets/panel-connected.png`, `panel-disconnected.png`, `panel-connecting.png`,
      `panel-hero-closeup.png`, `panel-families-closeup.png`.
- [ ] `docs/DESIGN-PANEL.md` — цветовая система и правила.
- [ ] README: секция Panel + connected screenshot.

---

## 7. Constraints

- `service.luau` меняется только bootstrap-публикацией `families = "malware"`;
  `state.luau` — только дефолт `families`. `commands.luau`, `widget.luau`,
  `shortcut.luau` не трогать (register уже есть).
- Не добавлять debug/preview-код в поставляемый `panel.luau`; скриншоты других состояний —
  временные фикстуры, полностью откатить перед коммитом.
- `noctalia plugins lint` — единственный локальный гейт; runtime-лог — второй.
- Существующий источник `warpqa` (worktree 0.4.0) может перехватывать загрузку; после
  bump 0.4.1 проверить `noctalia msg plugins list | grep warp` и при необходимости
  использовать source `warpdev` (path = этот репозиторий). Не удалять `warpqa` без согласия.
