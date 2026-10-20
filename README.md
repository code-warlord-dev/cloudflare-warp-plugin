# Cloudflare WARP — Noctalia 5.x Plugin (meta project)

Этот репозиторий/каталог — **мета-проект** для агентной разработки плагина Cloudflare WARP под Noctalia 5.x.

Runtime-плагин живёт в подкаталоге [`cloudflare-warp/`](./cloudflare-warp/).

## Документы

| Файл | Назначение |
|------|------------|
| [docs/SPEC.md](./docs/SPEC.md) | Полная продуктовая и техническая спецификация |
| [ROADMAP.md](./ROADMAP.md) | Фазы 0→5 |
| [VERSIONING.md](./VERSIONING.md) | SemVer + map версий |
| [CHANGELOG.md](./CHANGELOG.md) | История изменений |
| [STATE.md](./STATE.md) | Живой статус (читать первым) |
| [AGENTS.md](./AGENTS.md) | Оркестратор и субагенты |
| [docs/API-NOTES.md](./docs/API-NOTES.md) | Проверенные факты о Noctalia 5.3.0 / warp-cli / `plugins lint` |
| [docs/DESIGN-PANEL.md](./docs/DESIGN-PANEL.md) | Визуальная система и правила панели (0.4.1) |
| [specs/](./specs/) | Executable specs по фазам |
| [.agents/skills/](./.agents/skills/) | Skills для агентов |
| [templates/](./templates/) | Commit / PR / Push |

## Команда агентов

См. [AGENTS.md](./AGENTS.md).

Кратко:

- **Orchestrator** — планирует, назначает, мержит, bump версии
- **Architect / Spec Writer** — specs
- **Implementer** — Luau
- **Reviewer** — gate
- **QA** — IPC и acceptance
- **Docs/i18n** — переводы и README плагина

## Правила

1. Каждый merge в `main`, затрагивающий `cloudflare-warp/`, **обязан** bump'нуть версию.
2. Feature → MINOR, fix → PATCH, breaking → MAJOR (см. VERSIONING.md).
3. Service — единственный writer state `warp.*`.
4. Никакого `sudo` в плагине.

## Статус

См. [STATE.md](./STATE.md). Сейчас: **0.4.1**, Phase 3 завершена — сервис, bar widget,
Control Center shortcut и панель работают. Следующая — Phase 4 (polish, full i18n,
error UX, README).

Локальный гейт качества — `noctalia plugins lint cloudflare-warp` (команды `noctalia validate-plugin`
не существует).
