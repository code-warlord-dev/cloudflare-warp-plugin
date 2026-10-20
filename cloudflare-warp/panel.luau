--!nonstrict
-- Cloudflare WARP - detail panel (Phase 3, redesign v2).
--
-- Renderer plus command writer: every action goes through warp.command via
-- State.setCommand(source = "panel"). This entry never runs CLI calls, never
-- touches the network and never writes warp.status; the tree re-renders on
-- state changes while the panel is open. The banner assets were derived from
-- assets/hero-banner.jpeg (connected = color, idle = cooler/dimmer).

local State = require("./lib/state.luau")
local Icons = require("./lib/icons.luau")

-- Fixed orderings shared by the selects; commands carry the canonical
-- lowercase values the service whitelists (SPEC 5.2).
local MODE_ORDER = { "warp", "doh", "warp+doh", "dot", "warp+dot", "proxy", "tunnel_only" }
local PROTOCOL_ORDER = { "wireguard", "masque" }
local FAMILIES_ORDER = { "off", "malware", "full" }

-- Visual tokens (SPEC phase-3 panel redesign section 1).
local BRAND_ORANGE = "#F6821F"
local CYAN = "#59D6FF"
local SUCCESS = "#3BE3A3"

-- Phase presentation: loud accent, banner asset and banner opacity.
local PHASE_STYLE = {
  connected = { accent = SUCCESS, banner = "assets/hero-banner-color.png", bannerOpacity = 1.0 },
  disconnected = { accent = BRAND_ORANGE, banner = "assets/hero-banner-idle.png", bannerOpacity = 1.0 },
  connecting = { accent = CYAN, banner = "assets/hero-banner-color.png", bannerOpacity = 0.65 },
  disconnecting = { accent = CYAN, banner = "assets/hero-banner-color.png", bannerOpacity = 0.65 },
  unregistered = { accent = "#FFB340", banner = "assets/hero-banner-idle.png", bannerOpacity = 0.9 },
  error = { accent = "#FF5C6C", banner = "assets/hero-banner-idle.png", bannerOpacity = 0.85 },
  unavailable = { accent = "#FF5C6C", banner = "assets/hero-banner-idle.png", bannerOpacity = 0.85 },
  unknown = { accent = "#8A93A6", banner = "assets/hero-banner-idle.png", bannerOpacity = 0.85 },
}

local COPY_FEEDBACK_MS = 1600
local REFRESH_FEEDBACK_MS = 1500
local IP_DISPLAY_MAX = 28

local status = State.defaultStatus()
local isOpen = false
local copiedUntilMs = 0
local refreshUntilMs = 0

local render -- forward declaration: callbacks below re-render after local actions.

local function nowMs()
  return tonumber(noctalia.nowMs()) or 0
end

local function applyStatus(value)
  if type(value) ~= "table" then
    return
  end
  status = value
  status.phase = Icons.normalizePhase(status.phase)
end

local function phaseStyle()
  return PHASE_STYLE[status.phase] or PHASE_STYLE.unknown
end

local function isBusy()
  return status.busy == true
end

-- Mutations require a live CLI, an idle service and a registered client.
local function controlsEnabled()
  return status.available == true and status.busy ~= true and status.registered ~= false
end

local function powerEnabled()
  local phase = status.phase
  return status.available == true and status.busy ~= true and status.registered ~= false
    and phase ~= "unregistered" and phase ~= "unavailable"
end

local function traceIp()
  local trace = type(status.trace) == "table" and status.trace or {}
  local ip = trace.ip
  return type(ip) == "string" and ip or ""
end

-- modeLabels: the seven translated mode names in MODE_ORDER order.
local function modeLabels()
  local labels = {}
  for _, id in ipairs(MODE_ORDER) do
    labels[#labels + 1] = noctalia.tr("mode." .. id)
  end
  return labels
end

-- modeIndex / protocolIndex: 0-based index into the real option list; nil when
-- the value is unknown.
local function modeIndex()
  for i, id in ipairs(MODE_ORDER) do
    if id == status.mode then
      return i - 1
    end
  end
  return nil
end

local function protocolIndex()
  for i, id in ipairs(PROTOCOL_ORDER) do
    if id == status.protocol then
      return i - 1
    end
  end
  return nil
end

-- The host select always selects option 0 for a non-empty list, so `nil`
-- cannot display its placeholder. An unknown value gets an explicit leading
-- placeholder option instead; the change handlers ignore that index.
local function selectData(labels, index, placeholder)
  if index ~= nil then
    return labels, index, 0
  end
  local options = { placeholder }
  for _, label in ipairs(labels) do
    options[#options + 1] = label
  end
  return options, 0, 1
end

-- Timers: second ticks drive the copy/refresh feedback windows.
local function syncTicks()
  panel.setWantsSecondTicks(copiedUntilMs > 0 or refreshUntilMs > 0)
end

-- Command callbacks. Guards mirror the service checks so a stray callback can
-- never emit a second command while one is in flight.
local function onModeChange(index, offset)
  local i = tonumber(index)
  offset = tonumber(offset) or 0
  if controlsEnabled() and status.switchLocked ~= true
      and i ~= nil and i >= offset and i - offset < #MODE_ORDER then
    local mode = MODE_ORDER[i - offset + 1]
    if mode ~= status.mode then
      State.setCommand("set-mode", { mode = mode, source = "panel" })
    end
  end
  -- Re-render to snap the controlled select back to the published value.
  render()
end

local function onProtocolChange(index, offset)
  local i = tonumber(index)
  offset = tonumber(offset) or 0
  if controlsEnabled() and i ~= nil and i >= offset and i - offset < #PROTOCOL_ORDER then
    local protocol = PROTOCOL_ORDER[i - offset + 1]
    if protocol ~= status.protocol then
      State.setCommand("set-protocol", { protocol = protocol, source = "panel" })
    end
  end
  render()
end

local function onFamilies(families)
  if controlsEnabled() and status.families ~= families then
    State.setCommand("set-families", { families = families, source = "panel" })
  end
  render()
end

local function onPower()
  if not powerEnabled() then
    return
  end
  State.setCommand("toggle", { source = "panel" })
end

local function onRegister()
  if status.available == true and status.registered == false and status.busy ~= true then
    State.setCommand("register", { source = "panel" })
  end
end

local function onCopyIp()
  local ip = traceIp()
  if ip == "" then
    return
  end
  local copied = noctalia.copyToClipboard(ip, "text/plain")
  if copied == false then
    return
  end
  copiedUntilMs = nowMs() + COPY_FEEDBACK_MS
  syncTicks()
  render()
end

local function onRefresh()
  if isBusy() or refreshUntilMs > 0 then
    return
  end
  refreshUntilMs = nowMs() + REFRESH_FEEDBACK_MS
  syncTicks()
  State.setCommand("refresh", { source = "panel" })
  render()
end

local function onSettings()
  noctalia.openSettings()
end

local function onCloseClicked()
  panel.close()
end

-- Tree builders --------------------------------------------------------------

local function caption(text)
  return ui.label({ text = text, fontSize = 11, color = "on_surface_variant" })
end

local function sectionLabel(text)
  return ui.label({ text = text, fontSize = 12, color = "on_surface_variant" })
end

local function shortIp(ip)
  if #ip <= IP_DISPLAY_MAX then
    return ip
  end
  return string.sub(ip, 1, 13) .. "…" .. string.sub(ip, -12)
end

-- Banner: full-bleed phase image; the PNG carries the bottom alpha fade.
local function banner()
  local style = phaseStyle()
  return ui.image({
    key = "banner",
    path = style.banner,
    width = 360,
    height = 96,
    fit = "cover",
    opacity = style.bannerOpacity,
  })
end

-- Header: small brand glyph, title, refresh (loader while working) and close.
local function headerRow()
  local busy = isBusy()
  local refreshing = refreshUntilMs > 0
  return ui.row({
    width = "100%",
    gap = 8,
    align = "center",
    paddingH = 16,
    paddingV = 8,
  }, {
    ui.glyph({ name = "cloud-lock", size = 18, color = BRAND_ORANGE }),
    ui.label({
      text = noctalia.tr("panel.title"),
      fontSize = 15,
      fontWeight = "bold",
      color = "on_surface",
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.button({
      key = "header-refresh",
      glyph = (busy or refreshing) and "loader-2" or "refresh",
      variant = "ghost",
      tooltip = noctalia.tr("panel.action.refresh"),
      enabled = not busy and not refreshing,
      onClick = onRefresh,
    }),
    ui.button({
      key = "header-close",
      glyph = "close",
      variant = "ghost",
      tooltip = noctalia.tr("panel.action.close"),
      onClick = onCloseClicked,
    }),
  })
end

local function powerButton()
  local phase = status.phase
  local disconnect = phase == "connected" or phase == "connecting" or phase == "disconnecting"
  return ui.button({
    key = "power",
    glyph = "power",
    controlSize = "md",
    glyphSize = 18,
    variant = disconnect and "outline" or "primary",
    tooltip = noctalia.tr(if disconnect then "panel.action.disconnect" else "panel.action.connect"),
    enabled = powerEnabled(),
    onClick = onPower,
  })
end

-- Hero: the one loud accent on the panel; status reads first.
local function heroCard()
  local style = phaseStyle()
  local updatedAtMs = tonumber(status.updatedAtMs) or 0
  local updated = if updatedAtMs > 0
    then noctalia.formatTime("%H:%M", math.floor(updatedAtMs / 1000))
    else "—"
  local subtitle = noctalia.tr("panel.hero.subtitle." .. status.phase)
  local errorCode = type(status.errorCode) == "string" and status.errorCode or ""
  if status.phase == "unavailable" and errorCode ~= "" then
    subtitle = noctalia.tr("error." .. errorCode)
  end
  local children = {
    ui.row({ width = "100%", gap = 10, align = "center" }, {
      ui.glyph({
        name = Icons.statusGlyph(status.phase, isBusy()),
        size = 22,
        color = style.accent,
      }),
      ui.label({
        text = noctalia.tr("status." .. status.phase),
        fontSize = 24,
        fontWeight = "bold",
        color = "on_surface",
        maxLines = 1,
        flexGrow = 1,
      }),
      powerButton(),
    }),
    ui.row({ width = "100%", gap = 8, align = "center" }, {
      ui.label({
        text = subtitle,
        fontSize = 12,
        color = "on_surface_variant",
        maxLines = 2,
        flexGrow = 1,
      }),
      ui.label({
        text = noctalia.tr("panel.updated") .. " " .. updated,
        fontSize = 11,
        color = "on_surface_variant",
      }),
    }),
  }
  if status.phase == "error" then
    if errorCode ~= "" then
      children[#children + 1] = ui.label({
        text = noctalia.tr("error." .. errorCode),
        fontSize = 11,
        color = "#FF5C6C",
        maxLines = 2,
      })
    end
    local message = type(status.message) == "string" and status.message or ""
    if message ~= "" then
      children[#children + 1] = ui.label({
        text = message,
        fontSize = 11,
        color = "on_surface_variant",
        maxLines = 2,
      })
    end
  end
  return ui.column({
    key = "hero-card",
    width = "100%",
    gap = 8,
    radius = 16,
    borderWidth = 1,
    paddingH = 16,
    paddingV = 12,
    fill = style.accent .. "14",
    border = style.accent .. "66",
  }, children)
end

local function modeColumn()
  local options, selectedIndex, offset = selectData(
    modeLabels(),
    modeIndex(),
    noctalia.tr("panel.mode.unknown")
  )
  return ui.column({ flexGrow = 1, gap = 6, align = "stretch" }, {
    sectionLabel(noctalia.tr("panel.section.mode")),
    ui.select({
      key = "mode-select",
      options = options,
      selectedIndex = selectedIndex,
      placeholder = noctalia.tr("panel.mode.unknown"),
      enabled = controlsEnabled() and status.switchLocked ~= true,
      height = 38,
      onChange = function(index)
        onModeChange(index, offset)
      end,
    }),
  })
end

local function protocolColumn()
  local options, selectedIndex, offset = selectData(
    { "WireGuard", "MASQUE" },
    protocolIndex(),
    noctalia.tr("panel.protocol.unknown")
  )
  return ui.column({ flexGrow = 1, gap = 6, align = "stretch" }, {
    sectionLabel(noctalia.tr("panel.section.protocol")),
    ui.select({
      key = "protocol-select",
      options = options,
      selectedIndex = selectedIndex,
      placeholder = noctalia.tr("panel.protocol.unknown"),
      enabled = controlsEnabled(),
      height = 38,
      onChange = function(index)
        onProtocolChange(index, offset)
      end,
    }),
  })
end

-- Controls: Mode and Protocol side by side; a lock caption sits underneath.
local function controlsSection()
  local children = {
    ui.row({
      width = "100%",
      gap = 10,
      align = "stretch",
      opacity = isBusy() and 0.55 or 1.0,
    }, {
      modeColumn(),
      protocolColumn(),
    }),
  }
  if status.switchLocked == true then
    children[#children + 1] = caption(noctalia.tr("panel.mode.locked"))
  end
  return ui.column({ width = "100%", gap = 6 }, children)
end

-- Families: custom segmented control (not a select - the value is write-only
-- and "unknown" must not be presented as a known selection).
local function familiesSegment(value)
  local selected = status.families == value
  local enabled = controlsEnabled()
  return ui.column({
    key = "families-" .. value,
    height = 38,
    radius = 9,
    flexGrow = 1,
    align = "center",
    justify = "center",
    -- Explicit colors in both states: the host reconciler keeps absent flex
    -- fill/border props, which would leave a stale cyan cell after deselect.
    fill = selected and "#59D6FF1F" or "#00000000",
    border = selected and "#59D6FF99" or "#00000000",
    borderWidth = 1,
    -- The track dims during busy; only an unregistered client dims segments
    -- on their own so the two opacities never compound.
    opacity = (not enabled and not isBusy()) and 0.55 or 1.0,
    onClick = function()
      onFamilies(value)
    end,
  }, {
    ui.label({
      text = noctalia.tr("families." .. value),
      fontSize = 12,
      fontWeight = selected and "semibold" or nil,
      color = selected and "on_surface" or "on_surface_variant",
    }),
  })
end

local function familiesSection()
  local children = {
    sectionLabel(noctalia.tr("panel.section.families")),
    ui.row({
      width = "100%",
      gap = 3,
      padding = 3,
      radius = 12,
      fill = "surface_variant/0.45",
      border = "outline/0.25",
      borderWidth = 1,
      opacity = isBusy() and 0.55 or 1.0,
    }, {
      familiesSegment(FAMILIES_ORDER[1]),
      familiesSegment(FAMILIES_ORDER[2]),
      familiesSegment(FAMILIES_ORDER[3]),
    }),
  }
  if status.families == "unknown" then
    children[#children + 1] = ui.row({ width = "100%", gap = 6, align = "center" }, {
      ui.glyph({ name = "info-circle", size = 12, color = CYAN }),
      ui.label({
        text = noctalia.tr("panel.families.unknown"),
        fontSize = 11,
        color = "on_surface_variant",
        maxLines = 2,
        flexGrow = 1,
      }),
    })
  end
  return ui.column({ width = "100%", gap = 6 }, children)
end

-- Identity: egress data from the cdn-cgi/trace probe, honest when missing.
local function identityRow(labelText, valueText)
  return ui.row({ width = "100%", gap = 8, align = "center" }, {
    ui.label({ text = labelText, fontSize = 12, color = "on_surface_variant" }),
    ui.label({
      text = valueText,
      fontSize = 12,
      color = "on_surface",
      maxLines = 1,
      textAlign = "end",
      flexGrow = 1,
    }),
  })
end

local function ipRow()
  local ip = traceIp()
  local copyControl
  if copiedUntilMs > 0 then
    copyControl = ui.column({
      key = "identity-copied",
      width = 32,
      height = 32,
      align = "center",
      justify = "center",
    }, {
      ui.glyph({ name = "check", size = 14, color = SUCCESS }),
    })
  else
    copyControl = ui.button({
      key = "identity-copy-ip",
      glyph = "copy",
      controlSize = "sm",
      glyphSize = 14,
      variant = "ghost",
      tooltip = noctalia.tr("panel.action.copy_ip"),
      enabled = ip ~= "",
      onClick = onCopyIp,
    })
  end
  return ui.row({ width = "100%", gap = 8, align = "center" }, {
    ui.label({ text = noctalia.tr("panel.identity.ip"), fontSize = 12, color = "on_surface_variant" }),
    ui.label({
      text = if ip ~= "" then shortIp(ip) else noctalia.tr("panel.trace.none"),
      fontSize = 12,
      color = "on_surface",
      maxLines = 1,
      textAlign = "end",
      flexGrow = 1,
    }),
    copyControl,
  })
end

local function identitySection()
  local trace = type(status.trace) == "table" and status.trace or {}
  local loc = type(trace.loc) == "string" and trace.loc ~= "" and trace.loc or "—"
  local colo = type(trace.colo) == "string" and trace.colo ~= "" and trace.colo or "—"
  local warp = type(trace.warp) == "string" and trace.warp or ""
  local warpValue = if warp == "on" or warp == "plus" or warp == "off"
    then noctalia.tr("panel.trace.warp." .. warp)
    else noctalia.tr("panel.trace.warp.unknown")
  local atMs = tonumber(trace.atMs) or 0
  local traced = if atMs > 0
    then noctalia.formatTime("%H:%M", math.floor(atMs / 1000))
    else noctalia.tr("panel.trace.never")
  return ui.column({
    key = "identity-card",
    width = "100%",
    gap = 5,
    radius = 16,
    padding = 12,
    fill = "surface_variant/0.35",
    border = "outline/0.35",
    borderWidth = 1,
  }, {
    ui.row({ width = "100%", gap = 8, align = "center" }, {
      ui.label({
        text = noctalia.tr("panel.section.identity"),
        fontSize = 13,
        fontWeight = "semibold",
        color = "on_surface",
        flexGrow = 1,
      }),
      ui.glyph({ name = "world", size = 14, color = CYAN }),
    }),
    ui.separator({ thickness = 1, color = "outline/0.25", spacing = 0 }),
    ipRow(),
    identityRow(noctalia.tr("panel.identity.loc"), loc),
    identityRow(noctalia.tr("panel.identity.colo"), colo),
    identityRow(noctalia.tr("panel.identity.warp"), warpValue),
    identityRow(noctalia.tr("panel.identity.time"), traced),
  })
end

-- Copy feedback replaces the outline button for ~1.6 s with an unmissable
-- success state (native buttons do not take a text color). The identity-row
-- copy control mirrors it so unregistered clients get feedback too.
local function copiedFeedback()
  return ui.column({
    key = "action-copied",
    height = 38,
    flexGrow = 1,
    radius = 10,
    borderWidth = 1,
    fill = SUCCESS .. "1F",
    border = SUCCESS .. "99",
    align = "center",
    justify = "center",
    onClick = onCopyIp,
  }, {
    ui.row({ gap = 6, align = "center", justify = "center" }, {
      ui.glyph({ name = "check", size = 16, color = SUCCESS }),
      ui.label({
        text = noctalia.tr("panel.action.copied"),
        fontSize = 13,
        fontWeight = "medium",
        color = SUCCESS,
      }),
    }),
  })
end

local function footerActions()
  local ip = traceIp()
  local children = {}
  -- Register replaces Copy IP only while the client is genuinely unregistered.
  if status.registered == false and status.available == true then
    children[#children + 1] = ui.button({
      key = "action-register",
      text = noctalia.tr("panel.action.register"),
      glyph = "user-plus",
      variant = "primary",
      flexGrow = 1,
      enabled = status.busy ~= true,
      onClick = onRegister,
    })
  elseif copiedUntilMs > 0 then
    children[#children + 1] = copiedFeedback()
  else
    children[#children + 1] = ui.button({
      key = "action-copy-ip",
      text = noctalia.tr("panel.action.copy_ip"),
      glyph = "copy",
      variant = "outline",
      flexGrow = 1,
      enabled = ip ~= "",
      onClick = onCopyIp,
    })
  end
  children[#children + 1] = ui.button({
    key = "action-settings",
    text = noctalia.tr("panel.action.settings"),
    glyph = "settings",
    variant = "ghost",
    onClick = onSettings,
  })
  return ui.row({ width = "100%", gap = 8, align = "center", paddingH = 16, paddingV = 8 }, children)
end

local function buildTree()
  local scrollChildren = {
    heroCard(),
  }
  -- Missing CLI: controls are useless, so the hero carries the error and the
  -- identity card keeps the last known values.
  if status.available == true then
    scrollChildren[#scrollChildren + 1] = controlsSection()
    scrollChildren[#scrollChildren + 1] = familiesSection()
  end
  scrollChildren[#scrollChildren + 1] = identitySection()
  return ui.column({
    width = "100%",
    gap = 0,
    padding = 0,
    align = "stretch",
    flexGrow = 1,
  }, {
    banner(),
    headerRow(),
    ui.scroll({
      key = "content-scroll",
      width = "100%",
      flexGrow = 1,
      gap = 10,
      paddingH = 16,
      paddingV = 6,
    }, scrollChildren),
    ui.separator({ thickness = 1, color = "outline/0.25" }),
    footerActions(),
  })
end

render = function()
  if not isOpen then
    return
  end
  panel.render(buildTree())
end

-- Entry lifecycle -------------------------------------------------------------

function onOpen(_context)
  isOpen = true
  applyStatus(noctalia.state.get(State.CHANNEL_STATUS))
  render()
end

function onClose()
  isOpen = false
  copiedUntilMs = 0
  refreshUntilMs = 0
  panel.setWantsSecondTicks(false)
end

-- Second ticks: clear expired feedback and stop ticking once both windows are
-- idle. Feedback lasts at least its window, until the next tick past it.
function update()
  if not isOpen then
    return
  end
  local now = nowMs()
  local changed = false
  if copiedUntilMs > 0 and now >= copiedUntilMs then
    copiedUntilMs = 0
    changed = true
  end
  if refreshUntilMs > 0 and now >= refreshUntilMs then
    refreshUntilMs = 0
    changed = true
  end
  if copiedUntilMs == 0 and refreshUntilMs == 0 then
    panel.setWantsSecondTicks(false)
  end
  if changed then
    render()
  end
end

noctalia.state.watch(State.CHANNEL_STATUS, function(value)
  applyStatus(value)
  if isOpen then
    render()
  end
end)

applyStatus(noctalia.state.get(State.CHANNEL_STATUS))
