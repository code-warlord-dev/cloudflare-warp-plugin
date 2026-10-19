# AGENTS — Orchestrator & Sub-Agent Team

Этот документ описывает **команду агентов**, которая ведёт разработку плагина Cloudflare WARP для Noctalia 5.x.

Все агенты работают в контексте:

- [docs/SPEC.md](./docs/SPEC.md)
- [ROADMAP.md](./ROADMAP.md)
- [VERSIONING.md](./VERSIONING.md)
- [STATE.md](./STATE.md)
- [CHANGELOG.md](./CHANGELOG.md)
- skills в `./.agents/skills/`

---

## 1. Роли

```
                    ┌─────────────────────┐
                    │   ORCHESTRATOR      │
                    │  (единая точка      │
                    │   принятия решений) │
                    └──────────┬──────────┘
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼──────┐    ┌───────▼───────┐   ┌───────▼───────┐
    │  Architect  │    │  Implementer  │   │   Reviewer    │
    └──────┬──────┘    └───────┬───────┘   └───────┬───────┘
           │                   │                   │
    ┌──────▼──────┐    ┌───────▼───────┐   ┌───────▼───────┐
    │ Spec Writer │    │  QA / Tester  │   │  Docs / i18n  │
    └─────────────┘    └───────────────┘   └───────────────┘
```

| Agent ID | Роль | Когда вызывать | Skills |
|----------|------|----------------|--------|
| **orchestrator** | Планирует фазы, назначает задачи, обновляет STATE, принимает merge | Всегда (входная точка) | `orchestrator`, `versioning`, `git-workflow` |
| **architect** | Декомпозирует SPEC → task specs, API contracts, IPC | Перед началом фазы / крупной фичи | `architect`, `noctalia-plugin` |
| **implementer** | Пишет Luau / plugin.toml / lib | По task-spec от architect | `implementer`, `noctalia-plugin`, `luau` |
| **reviewer** | Code review, API compliance, security (runAsync/network) | Перед каждым PR | `reviewer`, `noctalia-plugin` |
| **qa** | Ручные/IPC тесты, validate-plugin, hot-reload | После implementer | `qa`, `noctalia-runtime` |
| **docs** | README, translations, CHANGELOG entries, PR body | Параллельно / после кода | `docs-i18n` |
| **spec-writer** | Пишет детальные phase-specs в `specs/` | По запросу orchestrator | `spec-writer` |

---

## 2. Orchestrator — протокол

### 2.1. Старт сессии

1. Прочитать `STATE.md` (snapshot + active work + blockers).
2. Прочитать текущую фазу в `ROADMAP.md`.
3. Если есть blocker — решить или эскалировать человеку.
4. Выбрать **одну** следующую задачу (не параллелить критический путь без нужды).
5. Назначить субагента через prompt (см. шаблоны ниже).

### 2.2. Назначение задачи

Orchestrator выдаёт субагенту:

```
TASK: <краткий заголовок>
PHASE: <0|1|2|3|4|5>
SPEC_REF: specs/phase-N-....md  (или docs/SPEC.md §…)
ACCEPTANCE:
  - [ ] …
CONSTRAINTS:
  - version bump type: MINOR|PATCH|none
  - do not change: …
OUTPUT:
  - files to create/modify
  - update STATE.md section Active work
```

### 2.3. Приёмка

1. Субагент вернул diff / описание.
2. Orchestrator → **reviewer** (обязательно для кода).
3. Orchestrator → **qa** (для runtime-кода).
4. Orchestrator → **docs** (если UI-строки / README).
5. Все зелёные → подготовка PR по `templates/PR.md`.
6. После merge: bump version, CHANGELOG, STATE, tag.

### 2.4. Запреты для Orchestrator

- Не писать production Luau сам (только через implementer).
- Не merge без reviewer + version bump.
- Не повышать `plugin_api` без записи в CHANGELOG и решения architect.
- Не пропускать обновление `STATE.md`.

---

## 3. Субагенты — краткие контракты

### Architect

- Вход: цель фазы + SPEC.
- Выход: `specs/phase-N-*.md` с API, IPC events, state keys, file list, acceptance.
- Не пишет код.

### Implementer

- Вход: task-spec + acceptance.
- Выход: код в `cloudflare-warp/`, зелёный `validate-plugin` (локально).
- Следует skills `noctalia-plugin` и `luau`.
- Все `runAsync` / network — явно комментирует в PR notes.

### Reviewer

- Чеклист: state keys vs SPEC, IPC vs SPEC, no sudo, no secrets, time budgets, i18n keys exist, plugin_api level sufficient but not inflated.
- Вердикт: `APPROVE` | `REQUEST_CHANGES` (с пунктами).

### QA

- Команды из `.agents/skills/qa/SKILL.md`.
- Отчёт: pass/fail по acceptance + IPC transcript.

### Docs / i18n

- `translations/*.json`, README, CHANGELOG section, PR body.
- Нет hardcoded user-facing строк в `.luau`.

### Spec Writer

- Детализирует ROADMAP phase → executable spec в `specs/`.

---

## 4. Шаблон вызова субагента (для Orchestrator)

```markdown
## Agent: implementer
## Task ID: P1-T3
## Phase: 1

### Context
Read STATE.md and specs/phase-1-service.md.

### Goal
Implement onIpc handlers: toggle, connect, disconnect, refresh.

### Acceptance
- [ ] IPC toggle flips connection
- [ ] state.warp.status updates within poll_interval
- [ ] missing warp-cli → status=error, no crash

### Constraints
- plugin_api stays 17
- no new settings in this task
- bump: none (part of 0.2.0 work)

### Deliverables
- service.luau / lib/commands.luau
- short note for CHANGELOG (Added)
```

---

## 5. Communication rules

- Один агент = один фокус. Не смешивать implement + review в одном промпте.
- Все решения по API/state — через architect или orchestrator.
- Человек вмешивается только при: security, breaking change, внешние аккаунты Cloudflare, публикация PR upstream.
- Язык артефактов: **русский** для docs/STATE/ROADMAP; **английский** для user-facing en.json и code comments (как в official-plugins).

---

## 6. Definition of Done (команда)

Фаза закрыта, когда:

1. Все acceptance в phase-spec отмечены.
2. Reviewer = APPROVE.
3. QA = pass.
4. version bumped, CHANGELOG + STATE обновлены.
5. Tag создан (для main).
