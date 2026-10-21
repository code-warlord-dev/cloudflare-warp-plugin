# DESIGN — панель Cloudflare WARP

**Статус:** `0.4.3` (PATCH, Phase 3). Панель переработана во вторую версию, прошла
fix round владельца, получила уменьшенные боковые поля и анимированный баннер
(27 кадров с запечённой насыщенностью); контракт `warp.status` / `warp.command` и IPC
не менялись.
**Источник истины:** [`cloudflare-warp/panel.luau`](../cloudflare-warp/panel.luau),
[`specs/phase-3-panel-redesign.md`](../specs/phase-3-panel-redesign.md).

Панель — это network control surface, а не админская форма. Порядок чтения:
**статус → действия → детали**. Панель только рендерит состояние и пишет команды через
`State.setCommand(..., source = "panel")`; она не запускает CLI, не делает HTTP-запросов
и не пишет `warp.status`.

## Галерея

Два кадра — `panel-connected.png` и `panel-hero-closeup.png` — пересняты под 0.4.3
(анимированный баннер 160 px, панель 400×734). Остальные шесть всё ещё показывают
раскладку 0.4.1 и ведутся как K-17 в `STATE.md`.

| Скриншот | Что показывает |
|----------|----------------|
| <img src="images/panel-connected.png" width="190" alt="Панель: подключено"> | **Connected.** Баннер остановлен на последнем кадре (полная насыщенность), зелёный hero, крупный статус, power в режиме отключения. |
| <img src="images/panel-disconnected.png" width="190" alt="Панель: отключено"> | **Disconnected.** После перехода из connected баннер откатывается к первому кадру (20 % цвета, не ч/б); приглушённый красно-оранжевый hero, power — primary. |
| <img src="images/panel-connecting.png" width="190" alt="Панель: подключение"> | **Connecting.** Баннер играет вперёд, циановый hero, живая wave-полоса, пульсирующий Refresh, контролы dim. |
| <img src="images/panel-families-selected.png" width="190" alt="Панель: выбран Malware"> | **Families selected.** Cyan низкой интенсивности; выбранный сегмент виден всегда. |
| <img src="images/panel-unknown-selects.png" width="190" alt="Панель: неизвестные Mode и Protocol"> | **Unknown selects.** Mode и Protocol показывают честный placeholder, а не выдуманное значение. |
| <img src="images/panel-copied.png" width="190" alt="Панель: IP скопирован"> | **Copied.** Success-состояние в footer и в строке identity; IPv6 в строке сокращён, в буфере — полный. |
| <img src="images/panel-hero-closeup.png" width="190" alt="Hero card крупным планом"> | **Hero close-up.** Фазовый акцент, статус, подзаголовок, «Обновлено HH:MM» и power. |
| <img src="images/panel-families-closeup.png" width="190" alt="Families крупным планом"> | **Families close-up.** Сегменты Off / Malware / Full; Malware выбран по умолчанию. |

## Карта компоновки

```
root column (gap=0, paddingH=-14, paddingV=0, align=stretch, flexGrow=1)
├─ banner-wrap column (height=146, paddingV=-14)
│   └─ ui.image 400×160, fit=cover, radius=12, path = кадр секвенции, opacity = entrance
├─ header row (paddingH=16, paddingV=8, gap=8)
│   ├─ glyph cloud-lock 18, brand-orange
│   ├─ label «Cloudflare WARP» 15 bold
│   ├─ spacer flexGrow=1
│   ├─ Refresh (ghost, refresh, pulse во время фидбека)
│   └─ Close (ghost, close)
├─ content-body column (flexGrow=1, gap=10, paddingH=16, paddingV=6, opacity=entrance)
│   ├─ hero card (radius=16, paddingH=16, paddingV=12)
│   │   ├─ row: status icon (connected — glyph shield-check, иначе phase glyph) + status 21 bold + power
│   │   ├─ row: subtitle 12 (до 2 строк) + «Обновлено HH:MM» 11
│   │   └─ connecting/disconnecting: wave из 5 полос 14 px
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
присутствует. Высота 734 подобрана под самый высокий штатный набор с баннером 160 px,
а `flexGrow=1` у content-body прижимает footer к низу, когда остаётся запас.

Баннер выходит за поля хоста: root отменяет горизонтальный inset хоста
(`paddingH = -14`), поэтому единственный боковой отступ — внутренние 16 px, а карточки
занимают 368 px из 400. Wrapper высотой 146 px получает `paddingV = -14`; изображение
400×160 начинается в точке (0,0) панели и заканчивается ровно на нижней границе wrapper.
Радиус изображения 12 совпадает с радиусом панели. Версия `warp-cli` в панели не
показывается, дублирующей кнопки закрытия нет.

## Фазы и акценты

| Фаза | Акцент | Анимация баннера | Подзаголовок (ru) |
|------|--------|------------------|-------------------|
| `connected` | success | forward на open/connect, статично на кадре 26 | Трафик защищён |
| `disconnected` | ember | статично на кадре 0 (20 % цвета) при open; reverse до кадра 0 при переходе из connected | Трафик идёт напрямую |
| `connecting` | cyan | forward, статично на кадре 26 | Защищаем трафик… |
| `disconnecting` | cyan | reverse до кадра 0 | Снимаем защиту… |
| `unregistered` | warning | статично на кадре 0 при open | Клиент не зарегистрирован |
| `error` | danger | статично на кадре 0 при open | Команда завершилась ошибкой |
| `unavailable` | danger | статично на кадре 0 при open | warp-cli не найден в PATH |
| `unknown` | neutral | статично на кадре 0 при open | Состояние неизвестно |

Баннер соответствует фазе: при открытии панели с живым туннелем
(connected/connecting) он играет вперёд до полной насыщенности, а при выключенном
WARP или ошибке сразу показан кадр 0 (20 % цвета) без анимации. Насыщенность
уменьшается только при переходе из connected/connecting в disconnecting/disconnected.

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
| Баннер: open / connect | секвенция 0 → 26, 100 ms на кадр (родная задержка GIF), стоп на кадре 26; при open в off-фазе — сразу статичный кадр 0 |
| Баннер: disconnect | секвенция 26 → 0 (или от текущего кадра), стоп на кадре 0; насыщенность гаснет вместе с кадрами |
| Акцент hero | экспоненциальное приближение, tau 140 ms |
| Connecting / disconnecting | wave из 5 полос: высота 4–14 px и opacity 0.45–1.0, синусоида со сдвигом фаз, период 900 ms; контролы и трек Families — opacity 0.55 |
| Refresh | header-иконка пульсирует между 0.55 и 1.0 с периодом 650 ms около 1.5 s |
| Families hover | заполнение и рамка сегмента плавно усиливаются, tau 70 ms |
| Кнопки | нативный hover/press хоста, без собственных анимаций |

Анимации идут на frame ticks (шаг 33 ms) через `panel.setNeedsFrameTick(true)` +
`onFrameTick(deltaMs)`; тики запрашиваются только пока есть незавершённая анимация и
выключаются в idle и при закрытии. Кадр секвенции меняется каждые 100 ms (каждые 10
тиков) — хост синхронно перезагружает WebP по новому `path`. Copy/refresh-фидбек
обслуживают second ticks.

## Цветовая система

| Токен | Значение | Назначение |
|-------|----------|------------|
| background | host-owned | Фон панели задаёт хост; плагин его не переопределяет. |
| surface card | `surface_variant/0.35` | Карточка network identity. |
| surface track | `surface_variant/0.45` | Трек segmented-контрола Families. |
| border card | `outline/0.35` | Рамки карточек. |
| border track | `outline/0.25` | Трек Families, separator. |
| brand orange | `#F6821F` | Glyph в header. |
| ember | `#C75B43` | Приглушённый красно-оранжевый акцент disconnected. |
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
| `assets/banner/frame-00.webp` … `frame-26.webp` | 800×320, 27 шт. | Кадры анимации; `frame-00` — 20 % насыщенности, `frame-26` — полная. Аспект 2.5:1 точно совпадает с 400×160, поэтому `fit = "cover"` не режет бока; `radius = 12`. |
| `assets/wGjQl.gif` | 640×298, 30 кадров | Исходник владельца; в UI не загружается, хранится для пересборки секвенции. |
| `assets/hero-banner.jpeg`, `hero-banner-color.png`, `hero-banner-idle.png` | — | Легаси v2 (0.4.1); панелью больше не используются. |

Секвенция собрана из coalesced-кадров GIF с сохранением **полной ширины** 640 px:
crop 640×256+0+0, resize 800×320 (аспект 2.5:1 = 400×160, бокового кропа нет), затем
насыщенность `sat = 20 + 80*i/26` (%). Таймкод в правом нижнем углу исходника
замазывается клонированным патчем с мягкими краями до ресайза. Используются кадры
0…26 — на три меньше, чем в GIF, по просьбе владельца; рампа идёт от 20 % до
100 %, поэтому reverse останавливается на первом кадре с остаточным цветом, а не на
полностью ч/б картинке.
В каждый кадр запечён нижний alpha-fade: последние 56 px из 320 (28 px на экране)
плавно уходят в прозрачность, поэтому баннер без шва переходит в тело панели. Хост не
умеет проигрывать GIF, тонировать `ui.image` и рисовать градиент поверх картинки,
поэтому и насыщенность, и fade запечены в кадры, а анимация — это смена `path` по frame
ticks.

## Иконки

| Иконка | Размер | Использование |
|--------|--------|---------------|
| `shield-check` (Tabler) | 22 | Hero в `connected`, цвет success `#3BE3A3`: однозначный OK-щит в акценте фазы. |
| `cloud-lock`, `refresh`, `close` | 18 | Header: бренд, обновление, закрытие. |
| `power` | 18 | Hero, кнопка подключения/отключения. |
| `world`, `copy`, `check`, `user-plus`, `settings` | 14 | Identity, фидбек копирования, Register, footer. |

`loader-2` в панели не используется: статичная дуга без вращения читается как обрезанное
кольцо. Busy выражают wave-полоса, dim и дизейбл контролов; Refresh остаётся
доступным как recovery-действие и сигналит фидбек opacity-пульсом. Собственные
двухцветные SVG для hero не нужны — нативный glyph наследует акцент фазы.

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
| Glyphs | 18 header, 22 hero (connected — `shield-check`), 14 secondary |
| Side gutters | 16 (root cancels the host's 14 px horizontal inset) |
| Card / control width | 368 inside the 400 px panel |
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
   всегда; высота 734 вмещает штатный набор, footer прижат через `flexGrow`.
6. **Обратная связь.** Copy показывает success около 1.6 с в footer и в строке IP;
   Refresh — пульсирующая иконка около 1.5 с и доступен даже при busy (recovery).
   Оба окна обслуживаются second ticks, которые выключаются, когда оба окна истекли.
7. **Длинный IPv6.** В строке показывается середина, сокращённая до ~28 символов;
   в буфер обмена всегда попадает полный адрес.
8. **Только i18n.** В `panel.luau` нет literal user-facing строк — только `noctalia.tr`
   (WireGuard/MASQUE — имена протоколов).
9. **Анимации не мешают.** Все переходы короткие, тики останавливаются в idle; панель
   остаётся мгновенно читаемой при открытии.
10. **Identity живая.** После успешных connect/disconnect и смены Mode/Protocol сервис
    пробует `cdn-cgi/trace` сразу и повторно через ~5 с; IP, location, edge, WARP и время
    trace обновляются сами, панель только отображает `warp.status`.
11. **Фаза не прыгает.** «Подключение…» / «Отключение…» держатся, пока поллинг не увидит
    целевой статус (safety timeout 30 с), поэтому hero не мигает «Отключено» между
    командой и подключением.

## Особенности хоста

- **Геометрия.** `400×734` и `floating` объявлены в манифесте, но размером и позицией
  владеет хост. Изменения `width`/`height` применяются только после
  disable/enable плагина — `config-reload` их не подхватывает. Пользовательский
  `[plugin_settings] panel_placement` может переопределить placement на лету; на
  dev-машине панель открывается как `attached`.
- **Padding.** Хост добавляет `Style::panelPadding = 14` со всех сторон. Отрицательный
  padding не клампится: root отменяет горизонтальный inset (`paddingH = -14`), а
  banner-wrapper — вертикальный сверху (`paddingV = -14`), поэтому баннер выходит на
  край панели, а боковой отступ равен 16 px.
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
