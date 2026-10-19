---
name: git-workflow
description: Branch naming, commit messages, PR flow, and push rules for the Cloudflare WARP plugin monorepo/meta project.
---

# Git Workflow Skill

## Branches

| Prefix | Use |
|--------|-----|
| `feat/` | MINOR-bound work |
| `fix/` | PATCH |
| `chore/` | meta, CI, skills |
| `docs/` | documentation only |
| `phase-N/` | optional long-running phase branch |

Examples: `feat/service-ipc-toggle`, `fix/parse-connecting-state`

## Commits

Follow `templates/COMMIT.md`.

Subject: imperative, ≤72 chars.  
Body: why + acceptance impact.  
Footer: `Phase: N` optional.

## PR

1. One logical unit (prefer one phase task cluster)
2. Fill `templates/PR.md` completely
3. Network & processes section mandatory for any `runAsync`
4. Version bump **in the same PR** if targeting main merge

## Push

- Force-push only on personal feature branches, never `main`
- After merge to main: tag `vX.Y.Z` and push tags

## Main protection (policy)

- Reviewer APPROVE required
- QA PASS for runtime changes
- VERSIONING skill satisfied
