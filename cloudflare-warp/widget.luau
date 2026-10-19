--!nonstrict
-- Cloudflare WARP - bar widget (Phase 0 placeholder).
--
-- Presentation only: a stable glyph plus the plugin name, or an icon-only bar
-- when compact_mode is on or show_text_in_bar is off. SVG status icons, live
-- status text, tooltips and clicks arrive in Phase 2; this entry does not read
-- the shared state channel.

local showText = noctalia.getConfig("show_text_in_bar") ~= false
local compact = noctalia.getConfig("compact_mode") == true

barWidget.setGlyph("cloud-lock")
barWidget.setText(if compact or not showText then "" else noctalia.tr("widget.text.brand"))
barWidget.setTooltip(noctalia.tr("widget.text.unknown"))

function update() end
