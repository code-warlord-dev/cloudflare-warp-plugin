# Commit message template

```
<type>(<scope>): <short imperative summary>

<optional body — why, not how>

Phase: <N>
```

## Types

| type | When |
|------|------|
| `feat` | New user-visible capability (→ MINOR) |
| `fix` | Bug fix (→ PATCH) |
| `refactor` | No behavior change |
| `docs` | Documentation / i18n only |
| `chore` | Tooling, skills, CI |
| `test` | QA scripts / fixtures |
| `style` | Formatting only |

## Scope (examples)

`service`, `widget`, `panel`, `shortcut`, `lib`, `manifest`, `i18n`, `meta`

## Examples

```
feat(service): poll warp-cli status and publish noctalia.state

Implements Phase 1 core loop. Missing binary sets status=error.

Phase: 1
```

```
fix(lib): treat Reconnecting as connecting status
```

```
chore(meta): add reviewer skill checklist
```

## Rules

- One logical change per commit when practical
- Do not put version bump alone without CHANGELOG in the same commit/PR
- No Conventional Commits tools required — humans/agents follow this template
