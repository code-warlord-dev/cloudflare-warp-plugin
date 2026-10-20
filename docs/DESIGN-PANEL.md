# DESIGN — панель Cloudflare WARP

**Статус:** `0.4.1` (PATCH, Phase 3). Панель переработана во вторую версию и прошла
fix round владельца; контракт `warp.status` / `warp.command` и IPC не менялись.
**Источник истины:** [`cloudflare-warp/panel.luau`](../cloudflare-warp/panel.luau),
[`specs/phase-3-panel-redesign.md`](../specs/phase-3-panel-redesign.md).

Панель — это network control surface, а не админская форма. Порядок чтения:
**статус → действия → детали**. Панель только рендерит состояние и пишет команды через
`State.setCommand(..., source = "panel")`; она не запускает CLI, не делает HTTP-запросов
и не пишет `warp.status`.

## Галерея

Скриншоты сняты на живом хосте Noctalia 5.3.0 при размере панели 400×672; close-up
вырезаны из тех же кадров.

| Скриншот | Что показывает |
|----------|----------------|
| <img src="images/panel-connected.png" width="190" alt="Панель: подключено"> | **Connected.** Полноцветный баннер, зелёный hero, крупный статус, power в режиме отключения. |
| <img src="images/panel-disconnected.png" width="190" alt="Панель: отключено"> | **Disconnected.** Приглушённый баннер, оранжевый hero, power — primary. |
| <img src="images/panel-connecting.png" width="190" alt="Панель: подключение"> | **Connecting.** Баннер с opacity 0.65, циановый hero, progress-полоса, loader в header, контролы dim. |
| <img src="images/panel-families-selected.png" width="190" alt="Панель: выбран Malware"> | **Families selected.** Cyan низкой интенсивности; выбранный сегмент виден всегда. |
| <img src="images/panel-unknown-selects.png" width="190" alt="Панель: неизвестные Mode и Protocol"> | **Unknown selects.** Mode и Protocol показывают честный placeholder, а не выдуманное значение. |
| <img src="images/panel-copied.png" width="190" alt="Панель: IP скопирован"> | **Copied.** Success-состояние в footer и в строке identity; IPv6 в строке сокращён, в буфере — полный. |
| <img src="images/panel-hero-closeup.png" width="190" alt="Hero card крупным планом"> | **Hero close-up.** Фазовый акцент, статус, подзаголовок, «Обновлено HH:MM» и power. |
| <img src="images/panel-families-closeup.png" width="190" alt="Families крупным планом"> | **Families close-up.** Сегменты Off / Malware / Full; Malware выбран по умолчанию. |

## Карта компоновки

```
root column (gap=0, padding=0, align=stretch, flexGrow=1)
├─ banner-wrap column (height=82, padding=-14 со всех сторон)
│   └─ ui.image 400×96, fit=cover, radius=12, opacity по фазе × entrance
├─ header row (paddingH=16, paddingV=8, gap=8)
│   ├─ glyph cloud-lock 18, brand-orange
│   ├─ label «Cloudflare WARP» 15 bold
│   ├─ spacer flexGrow=1
│   ├─ Refresh (ghost, refresh | loader-2, pulse во время фидбека)
│   └─ Close (ghost, close)
├─ content-body column (flexGrow=1, gap=10, paddingH=16, paddingV=6, opacity=entrance)
│   ├─ hero card (radius=16, paddingH=16, paddingV=12)
│   │   ├─ row: status glyph 22 + status 21 bold + power
│   │   ├─ row: subtitle 12 (до 2 строк) + «Обновлено HH:MM» 11
│   │   └─ connecting/disconnecting: progress 3 px
│   ├─ controls row (gap=10): Mode | Protocol, два равных столбца
│   ├─ optional caption: mode locked
│   ├─ families: label + segmented track (без caption)
│   └─ identity card (radius=16, padding=12, gap=5)
│       ├─ title 13 semibold + glyph world 14 cyan
│       ├─ separator outline/0.25
│       └─ IP (+copy), Location, Edge, WARP, Traced
├─ separator outline/0.25
└─ footer actions (paddingH=16, paddingV=8, gap=8)
    ├─ Copy IP (outline) | Register (primary, пока не зарегистрирован)
    └─ Settings (ghost)
```

`ui.scroll` не используется: хост всегда рисует scrollbar, если scroll-контейнер
присутствует. Высота 672 подобрана под самый высокий штатный набор, а `flexGrow=1`
у content-body прижимает footer к низу, когда остаётся запас.

Баннер выходит за поля хоста: wrapper высотой 82 px получает `padding = -14`, поэтому
изображение 400×96 начинается в точке (0,0) панели и заканчивается ровно на нижней
границе wrapper. Радиус изображения 12 совпадает с радиусом панели; нижний alpha-fade
зашит в PNG. Версия `warp-cli` в панели не показывается, дублирующей кнопки закрытия нет.

## Фазы и акценты

| Фаза | Акцент | Баннер | Opacity | Подзаголовок (ru) |
|------|--------|--------|---------|-------------------|
| `connected` | success | color | 1.0 | Трафик защищён |
| `disconnected` | brand-orange | idle | 1.0 | Трафик идёт напрямую |
| `connecting` | cyan | color | 0.65 | Защищаем трафик… |
| `disconnecting` | cyan | color | 0.65 | Снимаем защиту… |
| `unregistered` | warning | idle | 0.9 | Клиент не зарегистрирован |
| `error` | danger | idle | 0.85 | Команда завершилась ошибкой |
| `unavailable` | danger | idle | 0.85 | warp-cli не найден в PATH |
| `unknown` | neutral | idle | 0.85 | Состояние неизвестно |

Hero fill — акцент с alpha `14`, border — с alpha `66`. Power: для `connected`,
`connecting` и `disconnecting` — `outline` и «Отключить WARP», иначе `primary` и
«Подключить WARP»; кнопка disabled при `busy`, `available = false`, `registered = false`,
`unregistered` или `unavailable`. Mode дополнительно disabled при `switchLocked`.
Ошибка сворачивается в subtitle одной-двумя строками (`error.<code> — message`), чтобы
карточка не меняла высоту.

## Анимации

| Что | Как |
|-----|-----|
| Вход панели | 420 ms, `easeOutCubic` для opacity баннера и content-body |
| Смена фазы | баннер коротко проседает до 0.35, затем плавно проявляется новый ассет |
| Акцент и opacity баннера | экспоненциальное приближение, tau 140 ms / 180 ms |
| Connecting / disconnecting | progress-полоса 0.12…1.0 с периодом 1600 ms; баннер пульсирует ±0.06 с периодом 2200 ms; контролы и трек Families — opacity 0.55 |
| Refresh | header-иконка пульсирует между 0.55 и 1.0 с периодом 650 ms около 1.5 s |
| Families hover | заполнение и рамка сегмента плавно усиливаются, tau 70 ms |
| Кнопки | нативный hover/press хоста, без собственных анимаций |

Анимации идут на frame ticks (шаг 33 ms) через `panel.setNeedsFrameTick(true)` +
`onFrameTick(deltaMs)`; тики запрашиваются только пока есть незавершённая анимация и
выключаются в idle и при закрытии. Copy/refresh-фидбек обслуживают second ticks.

## Цветовая система

| Токен | Значение | Назначение |
|-------|----------|------------|
| background | host-owned | Фон панели задаёт хост; плагин его не переопределяет. |
| surface card | `surface_variant/0.35` | Карточка network identity. |
| surface track | `surface_variant/0.45` | Трек segmented-контрола Families. |
| border card | `outline/0.35` | Рамки карточек. |
| border track | `outline/0.25` | Трек Families, separator. |
| brand orange | `#F6821F` | Glyph в header, акцент disconnected. |
| brand warm | `#FFA53B` | Тёплый highlight, только малые площади. |
| cyan | `#59D6FF` | Акцент connecting/disconnecting, data-glyph, выбранный Families. |
| success | `#3BE3A3` | Акцент connected, подтверждение копирования. |
| danger | `#FF5C6C` | Акцент error/unavailable и текст ошибки. |
| warning | `#FFB340` | Акцент unregistered. |
| neutral | `#8A93A6` | Акцент unknown. |
| text primary | `on_surface` | Заголовки, статус, значения. |
| text secondary | `on_surface_variant` | Подписи, caption, время. |

Hero-акцент интерполируется между фазами, поэтому в кадре он может быть на несколько
единиц светлее/темнее табличного значения. Hex с прозрачностью — восемь цифр
(`#RRGGBBAA`); role-токены — `role/0.35`. Тёмная тема целевая, но поверхности и текст
берутся из ролей, поэтому светлая тема остаётся читаемой.

## Ассеты баннера

| Актив | Размер | Использование |
|-------|--------|---------------|
| `assets/hero-banner-color.png` | 720×192 (2×) | connected; connecting/disconnecting с opacity 0.65. |
| `assets/hero-banner-idle.png` | 720×192 (2×) | disconnected, unregistered, error, unavailable, unknown; opacity 0.9/0.85. |
| `assets/hero-banner.jpeg` | исходник | Не используется в UI; хранится как источник для пересборки PNG. |

Оба PNG уже содержат нижний alpha-fade (последние 80 px из 192). В панели изображение
рисуется как 400×96 с `fit = "cover"` и `radius = 12`.

## Типографика, отступы, радиусы

| Элемент | Размер / значение |
|---------|-------------------|
| Title | 15, bold |
| Hero status | 21, bold, одна строка |
| Identity title | 13, semibold |
| Section label | 12 |
| Значения и subtitle | 12 |
| Captions, updated, trace | 11 |
| Footer feedback text | 13 |
| Glyphs | 18 header, 22 hero, 14 secondary |
| Header padding | 16 по горизонтали, 8 по вертикали |
| Content padding | 16 по горизонтали, 6 по вертикали, gap 10 |
| Hero padding | 16 / 12 |
| Identity padding | 12, gap 5 |
| Footer padding | 16 / 8, gap 8 |
| Controls / select height | 38 |
| Families segment | 38, radius 9 |
| Icon / copy hit target | 32 |
| Radii | hero и identity 16, segmented track 12, copy feedback 10; banner и панель 12; selects и кнопки — host-default |

## UX-правила

1. **Статус первым.** Hero отвечает на вопрос «что сейчас», только потом идут контролы
   и справочные данные.
2. **Один loud-акцент.** Кричит только hero. Families использует cyan низкой
   интенсивности (`#59D6FF1F` fill, `#59D6FF99` border), header glyph — маленький
   оранжевый.
3. **Честный unknown, кроме Families.** Mode/Protocol получают ведущую опцию
   «Неизвестно». Families всегда показывает выбор: CLI не отдаёт значение, поэтому
   непустое состояние презентуется как дефолт Cloudflare **Malware**. Disabled-состояния
   показывают opacity 0.55, а не ложное значение.
4. **Комфортные цели.** Интерактивные элементы не меньше 32 px; selects и сегменты —
   38 px; клик по Families работает по всей площади сегмента.
5. **Без прокрутки.** `ui.scroll` не используется, потому что хост рисует scrollbar
   всегда; высота 672 вмещает штатный набор, footer прижат через `flexGrow`.
6. **Обратная связь.** Copy показывает success около 1.6 с в footer и в строке IP;
   Refresh — пульсирующий loader около 1.5 с. Оба окна обслуживаются second ticks,
   которые выключаются, когда оба окна истекли.
7. **Длинный IPv6.** В строке показывается середина, сокращённая до ~28 символов;
   в буфер обмена всегда попадает полный адрес.
8. **Только i18n.** В `panel.luau` нет literal user-facing строк — только `noctalia.tr`
   (WireGuard/MASQUE — имена протоколов).
9. **Анимации не мешают.** Все переходы короткие, тики останавливаются в idle; панель
   остаётся мгновенно читаемой при открытии.

## Особенности хоста

- **Геометрия.** `400×672` и `floating` объявлены в манифесте, но размером и позицией
  владеет хост. Изменения `width`/`height` применяются только после
  disable/enable плагина — `config-reload` их не подхватывает. Пользовательский
  `[plugin_settings] panel_placement` может переопределить placement на лету; на
  dev-машине панель открывается как `attached`.
- **Padding.** Хост добавляет `Style::panelPadding = 14` со всех сторон. Отрицательный
  padding не клампится и позволяет баннеру выйти на край панели.
- **Scrollbar.** Хост рисует полосу прокрутки всегда, когда присутствует `ui.scroll`,
  даже если контент помещается; поэтому панель от scroll-контейнера отказалась.
- **Frame ticks.** `panel.setNeedsFrameTick(true)` запрашивает кадры, `onFrameTick`
  приходит с delta; после выключения флага и закрытия панели тики прекращаются.
- **Second ticks.** Панель запрашивает их только на время copy/refresh-фидбека и
  отключает, когда оба окна закрыты.
- **Families write-only.** CLI не отдаёт текущее значение: до первого применения в
  сессии панель показывает `malware`, после перезапуска снова `malware`; прочитать или
  откатить выбор нельзя.
- **Тема.** Плагин не задаёт фон панели и не форсирует тему; role-токены сохраняют
  контраст в светлой и тёмной теме.
- **Контракт.** Любое действие — только команда в `warp.command`; запись `warp.status`,
  CLI-вызовы, `runAsync` и HTTP из панели запрещены.
