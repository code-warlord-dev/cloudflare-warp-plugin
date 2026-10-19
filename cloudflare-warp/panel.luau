--!nonstrict
-- Cloudflare WARP - detail panel (Phase 0 placeholder).
--
-- Phase 0 renders a header, a short placeholder and the plugin version read
-- from the manifest. Controls, status cards and state subscriptions arrive in
-- Phase 3; this entry does not read the shared state channel.

local pluginVersion = (function()
    local text = noctalia.readFile("plugin.toml")
    if type(text) ~= "string" then
        return ""
    end
    return ("\n" .. text):match('\nversion%s*=%s*"([^"]+)"') or ""
end)()

local function versionText()
    local version = if pluginVersion ~= "" then pluginVersion else "—"
    return noctalia.tr("panel.version", { version = version })
end

function onOpen(_context)
    panel.render(ui.column({ gap = 12, padding = 16, flexGrow = 1 }, {
        ui.row({ gap = 10, align = "center" }, {
            ui.glyph({ name = "cloud-lock", size = 20, color = "primary" }),
            ui.label({
                text = noctalia.tr("panel.title"),
                fontSize = 16,
                fontWeight = "bold",
            }),
        }),
        ui.label({
            text = noctalia.tr("panel.placeholder"),
            color = "on_surface_variant",
            fontSize = 13,
            maxLines = 2,
        }),
        ui.label({
            text = versionText(),
            color = "on_surface_variant",
            fontSize = 11,
        }),
    }))
end
