# Phase 2 — Bar Widget + Control Center Shortcut

**Target version:** `0.3.0` (MINOR)  
**Goal:** Пользователь видит статус WARP в баре (SVG) и может toggle из бара и Control Center.

## Non-goals

- Полная панель настроек mode/families (Phase 3)
- Анимированный spinner beyond static connecting SVG (можно позже)

## Dependencies

Phase 1 (state keys + cmd queue / IPC toggle must work).

## Icons policy (decision 2026-10-19)

**Prefer SVG via `barWidget.setImage`, not `setGlyph`.**

Rationale: brand recognition; Tabler glyphs are generic.

| status | path (plugin-relative) | text if show_text |
|--------|------------------------|-------------------|
| connected | `assets/icons/warp-on.svg` | On |
| disconnected | `assets/icons/warp-off.svg` | Off |
| connecting | `assets/icons/warp-connecting.svg` | … |
| unregistered | `assets/icons/warp-warn.svg` | Reg |
| error | `assets/icons/warp-error.svg` | Err |
| unknown | `assets/icons/warp-off.svg` | ? |

```luau
-- preferred
barWidget.setImage("assets/icons/warp-on.svg", false, 16, 16)
barWidget.setText(show_text and "On" or "")

-- fallback if image fails / missing file
barWidget.setGlyph("cloud-lock")
```

- SVG: square viewBox, simple paths; ideally single fill for theme tint, or distinct on/off artwork.
- Do **not** embed official Cloudflare logo unless license allows; use stylized WARP mark (document in README).
- Helper: `lib/icons.luau` → `iconPath(status) -> string`.

Declarative alternative (optional):

```luau
barWidget.render(ui.row({ gap = 6, align = "center" }, {
  ui.image({ path = path, width = 16, height = 16 }),
  show_text and ui.label({ text = label }) or nil,
}))
```

## State schema

Read-only Phase 1 keys.

| Key | Writer | Purpose |
|-----|--------|---------|
| `warp.cmd` | widget/shortcut/panel | one-shot command |
| `warp.cmd_payload` | optional | payload for setters |

Service clears after handling.

## Settings

- `show_text_in_bar`
- `compact_mode` (icon only)

## Files

| File | Action |
|------|--------|
| `assets/icons/*.svg` | 5 states |
| `lib/icons.luau` | status → path |
| `widget.luau` | setImage + text + tooltip + clicks |
| `shortcut.luau` | checked + icons if API allows |
| `service.luau` | consume `warp.cmd` |

## Tasks

1. Add SVG set (or placeholders)
2. `lib/icons.luau`
3. Service `warp.cmd` consumer
4. Widget presentation + click/right-click
5. Shortcut checked + click
6. compact / show_text settings

## Acceptance criteria

- [ ] Bar shows **SVG** for connected/disconnected (not only glyph)
- [ ] Status change swaps SVG within one poll interval after toggle
- [ ] Left click toggles WARP
- [ ] Right click opens panel
- [ ] Missing SVG → glyph fallback, no crash
- [ ] compact_mode / show_text_in_bar honored
- [ ] Shortcut checked mirrors connected
- [ ] version 0.3.0 + CHANGELOG

## Risks

| Risk | Mitigation |
|------|------------|
| Host does not rasterize SVG | early test; fallback PNG 1x/2x if needed |
| No image colorize | ship explicit on/off SVGs |
| Trademark | stylized mark + README note |

## Version bump

`0.2.0` → `0.3.0`
