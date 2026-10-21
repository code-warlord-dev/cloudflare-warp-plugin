# Phase 5 — Public 1.0.0

**Target version:** `1.0.0` (MAJOR — первый stable public)
**Goal:** подготовленный PR в `noctalia-dev/community-plugins`.

## Non-goals

- гарантия merge (upstream PR открывает человек);
- новые фичи;
- смена `plugin_api` вверх без необходимости.

## Dependencies

Phases 0–4, QA PASS, reviewer APPROVE.

## Tasks

1. Проверить компоновку source-репозитория: каталог `cloudflare-warp/` совпадает с
   суффиксом id `ModernByte/cloudflare-warp`.
2. `catalog.toml` (если репозиторий публикуется как source) с обязательными полями
   `id`, `name`, `plugin_api`; `version`, `author`, `license`, `icon`, `description`,
   `tags`, `dependencies` — по факту манифеста.
3. `thumbnail.webp` в корне плагина (требование community-plugins).
4. README: финальные ограничения (Families write-only, glyph в Control Center,
   `--accept-tos`, клики ЛК/ПК), IPC-таблица, полный список процессов и network call.
5. PR body по `templates/PR.md`: таблица **всех** `runAsync` argv и одного HTTPS GET.
6. CI `community-plugins` проходит (там же полная валидация манифеста, переводов и
   thumbnail — локально её не заменить).
7. Тег `v1.0.0` после merge в `main` этого репозитория.
8. Человек открывает upstream PR.

## Acceptance criteria

- [ ] `version = "1.0.0"`, `plugin_api = 24` (не выше).
- [ ] `noctalia plugins lint cloudflare-warp` → `0 errors, 0 warnings`.
- [ ] `noctalia msg plugins enable ModernByte/cloudflare-warp` на чистом профиле →
      лог без ошибок и без `plugin translation key … not found`.
- [ ] `catalog.toml` (если есть) проходит проверку полей; `plugin_api` — положительное целое.
- [ ] `thumbnail.webp` на месте, ≤ 1 МБ.
- [ ] README содержит: зависимость, установку, IPC, ограничения, лицензию, trust surface.
- [ ] `CHANGELOG.md` содержит `1.0.0` с полным списком возможностей.
- [ ] PR body заполнен по шаблону, включая все процессы и единственный network call.
- [ ] Нет открытых blocker-issue.
- [ ] **Хендл автора сверен с GitHub.** Локально у автора уже есть плагины под
      `code_warlord` (подчёркивание), а id проекта — `code-warlord`. До открытия PR
      убедиться, что `author`/id совпадает с реальным GitHub-хендлом; иначе переименовать
      id и каталог (до 1.0.0 это дешево).

## Risks

| Risk | Mitigation |
|------|------------|
| CI отклоняет манифест/переводы | локальный lint + скрипт паритета ключей + `thumbnail.webp` |
| Дублирование функционала `levi/warp` | README явно описывает отличие (Families/protocol/registration/egress) |
| Несовпадение хендла автора | проверка до PR, переименование id |
| `plugin_api = 24` отсекает старые Noctalia | осознанно: модули + argv; при необходимости — release-строки в catalog |
| Проверка «без warp-cli» не воспроизводится локально | CI/чистый профиль, отметить в PR |

## Version bump

`0.5.0` → `1.0.0`
