# Push & release checklist

## Feature branch

```bash
git push -u origin HEAD
```

Open PR from branch → `main` using templates/PR.md.

## After PR merge to main

```bash
git checkout main
git pull origin main

# verify version in plugin.toml
grep '^version' cloudflare-warp/plugin.toml

# tag
git tag -a "vX.Y.Z" -m "vX.Y.Z — <short summary>"
git push origin main --tags
```

## Rules

- Never force-push `main`
- Never tag without CHANGELOG section for that version
- Orchestrator updates `STATE.md` snapshot after tag
