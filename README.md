# Cloudflare WARP — Noctalia 5.x Plugin (meta project)

Этот репозиторий/каталог — **мета-проект** для агентной разработки плагина Cloudflare WARP под Noctalia 5.x.

Сам runtime-плагин будет жить в подкаталоге `cloudflare-warp/` (создаётся в Phase 0).

## Документы

| Файл | Назначение |
|------|------------|
| [docs/SPEC.md](./docs/SPEC.md) | Полная продуктовая и техническая спецификация |
| [ROADMAP.md](./ROADMAP.md) | Фазы 0→5 |
| [VERSIONING.md](./VERSIONING.md) | SemVer + map версий |
| [CHANGELOG.md](./CHANGELOG.md) | История изменений |
| [STATE.md](./STATE.md) | Живой статус (читать первым) |
| [AGENTS.md](./AGENTS.md) | Оркестратор и субагенты |
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

См. [STATE.md](./STATE.md). Сейчас: **0.0.0**, Phase 0 не начата.
