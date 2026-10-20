--!nonstrict
-- Cloudflare WARP - shared icon and label mapping for UI entries (Phase 2).
--
-- Single source of truth for phase -> SVG path / Tabler glyph / text suffix
-- (SPEC 8.2, phase-spec "Политика иконок"), plus the bar tooltip rows.
-- Shared by widget.luau and shortcut.luau; never writes state.

local State = require("./state.luau")

local M = {}

local KNOWN_PHASES = {}
for _, phase in ipairs(State.PHASES) do
  KNOWN_PHASES[phase] = true
end

-- SVG assets, relative to the plugin directory (the host resolves relative
-- image paths against it, and noctalia.fileExists resolves them the same way).
local SVG = {
  connected = "assets/icons/warp-on.svg",
  disconnected = "assets/icons/warp-off.svg",
  connecting = "assets/icons/warp-connecting.svg",
  disconnecting = "assets/icons/warp-connecting.svg",
  unregistered = "assets/icons/warp-warn.svg",
  error = "assets/icons/warp-error.svg",
  unavailable = "assets/icons/warp-error.svg",
  unknown = "assets/icons/warp-off.svg",
}

-- Tabler glyph fallback for surfaces without SVG support (bar fallback and
-- Control Center, where shortcut.setIcon accepts glyph names only).
local GLYPH = {
  connected = "cloud-lock",
  disconnected = "cloud-off",
  connecting = "cloud",
  disconnecting = "cloud",
  unregistered = "cloud",
  error = "cloud-off",
  unavailable = "cloud-off",
  unknown = "cloud-off",
}

-- Short bar text / shortcut label suffix; callers prefix their own namespace
-- ("widget.text." / "shortcut.").
local TEXT = {
  connected = "on",
  disconnected = "off",
  connecting = "connecting",
  disconnecting = "connecting",
  unregistered = "register",
  error = "error",
  unavailable = "error",
  unknown = "unknown",
}

-- normalizePhase: map any unexpected value to "unknown" so every consumer
-- works with the closed phase set from state.luau.
function M.normalizePhase(phase: any): string
  if type(phase) == "string" and KNOWN_PHASES[phase] then
    return phase
  end
  return "unknown"
end

-- path: SVG asset for a phase; always a string (unknown maps to warp-off).
function M.path(phase: any): string
  return SVG[M.normalizePhase(phase)]
end

-- glyph: Tabler glyph for a phase (fallback / Control Center).
function M.glyph(phase: any): string
  return GLYPH[M.normalizePhase(phase)]
end

-- textKey: translation suffix for a phase ("on", "connecting", ...).
function M.textKey(phase: any): string
  return TEXT[M.normalizePhase(phase)]
end

-- tooltipRows: bar tooltip as an array of { key, value } rows (SPEC 8.2).
-- status, mode, families (only when known), protocol, ip, location,
-- updated time and the last error message/errorCode.
function M.tooltipRows(status: any): { { key: string, value: string } }
  local rows = {}
  local ok = type(status) == "table"
  local phase = M.normalizePhase(ok and status.phase or nil)
  table.insert(rows, {
    key = noctalia.tr("widget.tooltip.status"),
    value = noctalia.tr("status." .. phase),
  })
  if ok then
    if type(status.mode) == "string" and status.mode ~= "" then
      table.insert(rows, { key = noctalia.tr("widget.tooltip.mode"), value = status.mode })
    end
    if type(status.families) == "string" and status.families ~= "" and status.families ~= "unknown" then
      table.insert(rows, { key = noctalia.tr("widget.tooltip.families"), value = status.families })
    end
    if type(status.protocol) == "string" and status.protocol ~= "" and status.protocol ~= "unknown" then
      table.insert(rows, { key = noctalia.tr("widget.tooltip.protocol"), value = status.protocol })
    end
    local trace = type(status.trace) == "table" and status.trace or {}
    if type(trace.ip) == "string" and trace.ip ~= "" then
      table.insert(rows, { key = noctalia.tr("widget.tooltip.ip"), value = trace.ip })
    end
    if type(trace.loc) == "string" and trace.loc ~= "" then
      table.insert(rows, { key = noctalia.tr("widget.tooltip.location"), value = trace.loc })
    end
    local updatedAtMs = tonumber(status.updatedAtMs) or 0
    if updatedAtMs > 0 then
      table.insert(rows, {
        key = noctalia.tr("widget.tooltip.updated"),
        value = noctalia.formatTime("%H:%M", math.floor(updatedAtMs / 1000)),
      })
    end
    local message = type(status.message) == "string" and status.message or ""
    local errorCode = type(status.errorCode) == "string" and status.errorCode or ""
    if message ~= "" or errorCode ~= "" then
      table.insert(rows, {
        key = noctalia.tr("widget.tooltip.error"),
        value = message ~= "" and message or errorCode,
      })
    end
  end
  return rows
end

return M