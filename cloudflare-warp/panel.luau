--!nonstrict
-- Cloudflare WARP - detail panel (Phase 3).
--
-- Declarative view of warp.status plus its command writer: every action goes
-- through warp.command via State.setCommand(source = "panel"). This entry
-- never runs CLI calls, never touches the network and never writes
-- warp.status; the tree re-renders on state changes while the panel is open.

local State = require("./lib/state.luau")
local Icons = require("./lib/icons.luau")

-- Fixed orderings shared by the selects; commands carry the canonical
-- lowercase values the service whitelists (SPEC 5.2).
local MODE_ORDER = { "warp", "doh", "warp+doh", "dot", "warp+dot", "proxy", "tunnel_only" }
local PROTOCOL_ORDER = { "wireguard", "masque" }

local status = State.defaultStatus()
local isOpen = false

local function applyStatus(value)
  if type(value) ~= "table" then
    return
  end
  status = value
  status.phase = Icons.normalizePhase(status.phase)
end

local render -- forward declaration: callbacks below re-render after local actions.

-- modeLabels: the seven translated mode names in MODE_ORDER order.
local function modeLabels()
  local labels = {}
  for _, id in ipairs(MODE_ORDER) do
    labels[#labels + 1] = noctalia.tr("mode." .. id)
  end
  return labels
end

-- modeIndex: 0-based selectedIndex; -1 when the mode is unknown.
local function modeIndex()
  for i, id in ipairs(MODE_ORDER) do
    if id == status.mode then
      return i - 1
    end
  end
  return -1
end

-- protocolIndex: 0-based selectedIndex; nil (no selection) when unknown so
-- the placeholder shows instead of a made-up protocol.
local function protocolIndex()
  for i, id in ipairs(PROTOCOL_ORDER) do
    if id == status.protocol then
      return i - 1
    end
  end
  return nil
end

-- Command callbacks. Guards mirror the busy/lock checks the service enforces
-- so a stray callback can never emit a second command while one is in flight.
local function onModeChange(index)
  local i = tonumber(index)
  if status.busy ~= true and status.switchLocked ~= true
      and status.phase ~= "unregistered"
      and i ~= nil and i >= 0 and i < #MODE_ORDER then
    local mode = MODE_ORDER[i + 1]
    if mode ~= status.mode then
      State.setCommand("set-mode", { mode = mode, source = "panel" })
    end
  end
  -- Re-render to snap the controlled select back to the published value.
  render()
end

local function onProtocolChange(index)
  local i = tonumber(index)
  if status.busy ~= true and status.phase ~= "unregistered"
      and i ~= nil and i >= 0 and i < #PROTOCOL_ORDER then
    local protocol = PROTOCOL_ORDER[i + 1]
    if protocol ~= status.protocol then
      State.setCommand("set-protocol", { protocol = protocol, source = "panel" })
    end
  end
  render()
end

local function onFamilies(families)
  if status.busy == true or status.families == families then
    render()
    return
  end
  State.setCommand("set-families", { families = families, source = "panel" })
  -- Re-render to snap the buttons back to the published value.
  render()
end

local function onCopyIp()
  local trace = type(status.trace) == "table" and status.trace or {}
  if type(trace.ip) == "string" and trace.ip ~= "" then
    noctalia.copyToClipboard(trace.ip, "text/plain")
  end
end

local function onRegister()
  if status.busy == true or status.registered == true then
    return
  end
  State.setCommand("register", { source = "panel" })
end

local function onSettings()
  noctalia.openSettings()
end

local function onRefresh()
  State.setCommand("refresh", { source = "panel" })
end

local function onCloseClicked()
  panel.close()
end

-- Tree builders --------------------------------------------------------------

local function sectionLabel(text)
  return ui.label({ text = text, fontSize = 12, color = "on_surface_variant" })
end

local function caption(text)
  return ui.label({ text = text, fontSize = 11, color = "on_surface_variant" })
end

-- Header: status glyph (loader while busy), title, phase text, refresh+close.
local function headerRow()
  return ui.row({ gap = 8, align = "center", width = "100%" }, {
    ui.glyph({
      name = Icons.statusGlyph(status.phase, status.busy),
      size = 20,
      color = Icons.phaseColor(status.phase),
    }),
    ui.label({ text = noctalia.tr("panel.title"), fontSize = 15, fontWeight = "bold" }),
    ui.label({
      text = noctalia.tr("status." .. status.phase),
      fontSize = 12,
      color = Icons.phaseColor(status.phase),
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.button({
      key = "header-refresh",
      glyph = "refresh",
      variant = "ghost",
      tooltip = noctalia.tr("panel.action.refresh"),
      enabled = status.busy ~= true,
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

-- Status card: phase (colored), last update, and the error line for a live
-- client. The unavailable case renders its own line instead of the controls,
-- so the message is not duplicated here.
local function statusCard()
  local updatedAtMs = tonumber(status.updatedAtMs) or 0
  local updated = if updatedAtMs > 0
    then noctalia.formatTime("%H:%M", math.floor(updatedAtMs / 1000))
    else "—"
  local children = {
    ui.row({ gap = 8, justify = "space_between", width = "100%" }, {
      ui.label({
        text = noctalia.tr("status." .. status.phase),
        fontSize = 13,
        fontWeight = "bold",
        color = Icons.phaseColor(status.phase),
      }),
      ui.row({ gap = 4, align = "center" }, {
        ui.label({ text = noctalia.tr("panel.updated"), fontSize = 11, color = "on_surface_variant" }),
        ui.label({ text = updated, fontSize = 11, color = "on_surface_variant" }),
      }),
    }),
  }
  local errorCode = type(status.errorCode) == "string" and status.errorCode or ""
  if status.available == true and errorCode ~= "" then
    children[#children + 1] = ui.label({
      text = noctalia.tr("error." .. errorCode),
      fontSize = 12,
      color = "error",
    })
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
    gap = 4,
    padding = 10,
    radius = 10,
    fill = "surface_variant/0.4",
    width = "100%",
  }, children)
end

local function modeSection()
  local locked = status.switchLocked == true
  local enabled = status.available == true and status.busy ~= true
    and not locked and status.phase ~= "unregistered"
  local children = {
    sectionLabel(noctalia.tr("panel.section.mode")),
    ui.select({
      key = "mode-select",
      options = modeLabels(),
      selectedIndex = modeIndex(),
      enabled = enabled,
      onChange = onModeChange,
      flexGrow = 1,
    }),
  }
  if locked then
    children[#children + 1] = caption(noctalia.tr("panel.mode.locked"))
  end
  return ui.column({ gap = 6, width = "100%" }, children)
end

-- Families: segmented buttons, not a select - the value is write-only, and
-- "unknown" must not be presented as a known selection (SPEC 8.4).
local function familiesButton(value, labelKey)
  return ui.button({
    key = "families-" .. value,
    text = noctalia.tr(labelKey),
    selected = status.families == value,
    enabled = status.available == true and status.busy ~= true,
    onClick = function()
      onFamilies(value)
    end,
  })
end

local function familiesSection()
  local children = {
    sectionLabel(noctalia.tr("panel.section.families")),
    ui.row({ gap = 6, width = "100%" }, {
      familiesButton("off", "families.off"),
      familiesButton("malware", "families.malware"),
      familiesButton("full", "families.full"),
    }),
  }
  if status.families == "unknown" then
    children[#children + 1] = caption(noctalia.tr("panel.families.unknown"))
  end
  return ui.column({ gap = 6, width = "100%" }, children)
end

local function protocolSection()
  local enabled = status.available == true and status.busy ~= true
    and status.phase ~= "unregistered"
  return ui.column({ gap = 6, width = "100%" }, {
    sectionLabel(noctalia.tr("panel.section.protocol")),
    ui.select({
      key = "protocol-select",
      options = { "WireGuard", "MASQUE" },
      selectedIndex = protocolIndex(),
      placeholder = noctalia.tr("panel.protocol.unknown"),
      enabled = enabled,
      onChange = onProtocolChange,
      flexGrow = 1,
    }),
  })
end

local function identityRow(labelKey, value)
  return ui.row({ gap = 8, justify = "space_between", width = "100%" }, {
    ui.label({ text = labelKey, fontSize = 12, color = "on_surface_variant" }),
    ui.label({ text = value, fontSize = 12 }),
  })
end

-- Identity: egress data from the cdn-cgi/trace probe; atMs = 0 means the
-- probe never ran, so there is no IP to show or copy.
local function identitySection()
  local trace = type(status.trace) == "table" and status.trace or {}
  local ip = type(trace.ip) == "string" and trace.ip or ""
  local loc = if type(trace.loc) == "string" and trace.loc ~= "" then trace.loc else "—"
  local colo = if type(trace.colo) == "string" and trace.colo ~= "" then trace.colo else "—"
  local warp = type(trace.warp) == "string" and trace.warp or ""
  local warpValue = noctalia.tr("panel.trace.warp."
    .. (if warp == "plus" then "plus" else if warp == "on" then "on" else "off"))
  local atMs = tonumber(trace.atMs) or 0
  local traced = if atMs > 0
    then noctalia.formatTime("%H:%M", math.floor(atMs / 1000))
    else "—"
  return ui.column({ gap = 4, width = "100%" }, {
    sectionLabel(noctalia.tr("panel.section.identity")),
    identityRow(noctalia.tr("panel.identity.ip"), if ip ~= "" then ip else noctalia.tr("panel.trace.none")),
    identityRow(noctalia.tr("panel.identity.loc"), loc),
    identityRow(noctalia.tr("panel.identity.colo"), colo),
    identityRow(noctalia.tr("panel.identity.warp"), warpValue),
    identityRow(noctalia.tr("panel.identity.time"), traced),
  })
end

local function actionsRow()
  local trace = type(status.trace) == "table" and status.trace or {}
  local ip = type(trace.ip) == "string" and trace.ip or ""
  local children = {
    ui.button({
      key = "action-copy-ip",
      text = noctalia.tr("panel.action.copy_ip"),
      variant = "outline",
      enabled = ip ~= "",
      onClick = onCopyIp,
    }),
  }
  -- Register is only meaningful on an unregistered client with a live CLI.
  if status.registered == false then
    children[#children + 1] = ui.button({
      key = "action-register",
      text = noctalia.tr("panel.action.register"),
      variant = "primary",
      enabled = status.busy ~= true,
      onClick = onRegister,
    })
  end
  children[#children + 1] = ui.button({
    key = "action-settings",
    text = noctalia.tr("panel.action.settings"),
    variant = "ghost",
    onClick = onSettings,
  })
  return ui.row({ gap = 8, align = "center", width = "100%" }, children)
end

local function footerRow()
  local cliVersion = type(status.cliVersion) == "string" and status.cliVersion or ""
  return ui.label({
    text = noctalia.tr("panel.version", { version = if cliVersion ~= "" then cliVersion else "—" }),
    fontSize = 11,
    color = "on_surface_variant",
  })
end

local function buildTree()
  local children = {
    headerRow(),
    statusCard(),
  }
  if status.available == true then
    children[#children + 1] = ui.column({ gap = 12, width = "100%" }, {
      modeSection(),
      familiesSection(),
      protocolSection(),
      identitySection(),
    })
    children[#children + 1] = actionsRow()
  else
    -- Client missing: the controls are replaced by a single error line; the
    -- Settings action stays so the plugin remains configurable.
    children[#children + 1] = ui.label({
      text = noctalia.tr("error.cli-missing"),
      fontSize = 12,
      color = "error",
    })
    children[#children + 1] = ui.row({ gap = 8, align = "center", width = "100%" }, {
      ui.button({
        key = "action-settings",
        text = noctalia.tr("panel.action.settings"),
        variant = "ghost",
        onClick = onSettings,
      }),
    })
  end
  children[#children + 1] = footerRow()
  return ui.column({ gap = 12, padding = 14, align = "stretch" }, children)
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
end

noctalia.state.watch(State.CHANNEL_STATUS, function(value)
  applyStatus(value)
  if isOpen then
    render()
  end
end)

applyStatus(noctalia.state.get(State.CHANNEL_STATUS))
