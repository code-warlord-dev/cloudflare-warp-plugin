# Phase 0 — Bootstrap

**Target version:** `0.1.0` (MINOR)  
**Goal:** Плагин загружается в Noctalia, проходит validate, enable не падает.

## Non-goals

- Реальный вызов `warp-cli`
- UI логика
- Polling

## Dependencies

Нет (стартовая фаза).

## State schema

Не используется.

## IPC contract

Не используется.

## Settings

Минимальный набор объявлен в манифесте (defaults), чтение не обязательно в 0.1.0:

| key | type | default |
|-----|------|---------|
| `poll_interval_ms` | int | 3000 |
| `notify_on_change` | bool | true |
| `notify_on_error` | bool | true |
| `auto_trace` | bool | true |
| `trace_interval_s` | int | 60 |
| `show_text_in_bar` | bool | true |
| `compact_mode` | bool | false |

## Files to create

```
cloudflare-warp/
├── plugin.toml
├── service.luau      # empty lifecycle stubs
├── widget.luau
├── shortcut.luau
├── panel.luau
├── lib/
│   ├── parse.luau      # return module stub
│   ├── commands.luau
│   └── state.luau
├── translations/
│   ├── en.json
│   └── ru.json
└── README.md
```

### plugin.toml requirements

- `id = "community/cloudflare-warp"`
- `version = "0.1.0"`
- `plugin_api = 17`
- `dependencies = ["cloudflare-warp"]`
- All four entries declared
- Settings schema with `label_key` pointing to translation keys

### Entry stubs

Each entry file may contain only comments + minimal safe globals, e.g.:

```luau
-- service.luau Phase 0 stub
function update()
  noctalia.setUpdateInterval(60000)
end
```

Widget may show a static SVG (`assets/icons/warp-off.svg` via `setImage`) and text `"WARP"`. If SVGs are not ready yet, temporary `setGlyph("cloud-lock")` is OK — replace in Phase 2.

### translations

All settings label/description keys present in en + ru.

## Tasks (ordered)

1. Create directory tree
2. Write `plugin.toml`
3. Write stub `.luau` files
4. Write `en.json` / `ru.json`
5. Write README (dependency + how to path-source)
6. Local: add path source, enable, validate-plugin

## Acceptance criteria

- [ ] `noctalia validate-plugin cloudflare-warp` exits 0
- [ ] Plugin appears in plugins list with correct name/icon
- [ ] Enable succeeds
- [ ] Widget can be placed on bar (shows static content)
- [ ] Panel id exists (may be empty UI)
- [ ] version = 0.1.0 in plugin.toml
- [ ] CHANGELOG has 0.1.0 section

## Risks

| Risk | Mitigation |
|------|------------|
| Wrong plugin_api | Start at 17; document in README |
| id collision | Use community/ prefix |

## Version bump

`0.0.0` → `0.1.0`
