--!nonstrict
-- Cloudflare WARP - Control Center tile (Phase 0 placeholder).
--
-- Static tile: shows the off-state label and the glyph pair. Active state and
-- click handling arrive in Phase 2; this entry does not read the shared state channel.

shortcut.setLabel(noctalia.tr("shortcut.off"))
shortcut.setIcon("cloud-lock", "cloud-off")
shortcut.setActive(false)
shortcut.setEnabled(true)
