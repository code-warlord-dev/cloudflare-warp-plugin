--!nonstrict
-- Cloudflare WARP - headless service (Phase 1).
--
-- Single source of truth for WARP state: polls warp-cli via argv-only
-- runAsync, publishes one warp.status table, consumes warp.command and IPC,
-- and executes whitelisted mutations.

local State = require("./lib/state.luau")
local Parse = require("./lib/parse.luau")
local Commands = require("./lib/commands.luau")

local TRACE_URL = "https://www.cloudflare.com/cdn-cgi/trace"
local HEARTBEAT_TICKS = 20
local SETTINGS_EVERY = 5
local REGISTRATION_EVERY = 10
-- Trace circuit breaker: suspend auto-trace after N consecutive failures and
-- back off exponentially (multiplier = 10 * 2^level, level capped at 4).
local TRACE_FAIL_SUSPEND_AT = 3
local TRACE_BACKOFF_MAX = 4

local settings = {
  poll_interval_ms = 3000,
  notify_on_change = true,
  notify_on_error = true,
  auto_trace = true,
  trace_interval_s = 60,
}

local function readSettings()
  return {
    poll_interval_ms = noctalia.getConfig("poll_interval_ms") or 3000,
    notify_on_change = noctalia.getConfig("notify_on_change"),
    notify_on_error = noctalia.getConfig("notify_on_error"),
    auto_trace = noctalia.getConfig("auto_trace"),
    trace_interval_s = noctalia.getConfig("trace_interval_s") or 60,
  }
end

-- In-flight guards (one per command type + one shared mutation guard).
local statusInFlight = false
local settingsInFlight = false
local registrationInFlight = false
local actionInFlight = false
local traceInFlight = false
local traceSentAt = 0

local tick = 0
local lastTraceAt = 0
local traceFailCount = 0
local traceBackoffLevel = 0
local traceSuspendedUntil = 0
local lastHandledSeq = 0

-- Notification tracking.
local lastPhase = nil
local lastStablePhase = nil
local lastErrorCode = ""
local firstPublish = true

local function isStablePhase(phase)
  -- "connecting" / "disconnecting" are transitional: a user disconnect goes
  -- connected -> disconnecting -> disconnected, so the direct pair is never
  -- observed. Notifications compare the last two *stable* phases instead.
  return phase ~= nil and phase ~= "connecting" and phase ~= "disconnecting"
end

local function notifyIfNeeded()
  local cur = noctalia.state.get(State.CHANNEL_STATUS) or State.defaultStatus()
  if firstPublish then
    firstPublish = false
    lastPhase = cur.phase
    if isStablePhase(cur.phase) then
      lastStablePhase = cur.phase
    end
    lastErrorCode = cur.errorCode
    return
  end
  if lastPhase ~= nil and cur.phase ~= lastPhase then
    noctalia.log("cloudflare-warp: transition " .. tostring(lastPhase) .. " -> " .. tostring(cur.phase))
  end
  local stable = cur.phase
  if not isStablePhase(stable) then
    stable = nil
  end
  if stable ~= nil then
    if settings.notify_on_change and lastStablePhase ~= nil then
      if lastStablePhase == "disconnected" and stable == "connected" then
        noctalia.notify(noctalia.tr("notify.connected.title"), noctalia.tr("notify.connected.body"))
      elseif lastStablePhase == "connected" and stable == "disconnected" then
        noctalia.notify(noctalia.tr("notify.disconnected.title"), noctalia.tr("notify.disconnected.body"))
      end
    end
    lastStablePhase = stable
  end
  if settings.notify_on_error and cur.errorCode ~= "" and cur.errorCode ~= "cli-missing" and cur.errorCode ~= lastErrorCode then
    noctalia.notifyError(noctalia.tr("notify.error.title"), noctalia.tr("error." .. cur.errorCode))
  end
  lastPhase = cur.phase
  lastErrorCode = cur.errorCode
end

local function publish(patch)
  local changed = State.publish(patch)
  if changed then
    notifyIfNeeded()
    local cur = noctalia.state.get(State.CHANNEL_STATUS) or State.defaultStatus()
    noctalia.log("cloudflare-warp: status phase=" .. tostring(cur.phase)
      .. " mode=" .. tostring(cur.mode or "")
      .. " errorCode=" .. tostring(cur.errorCode or ""))
  end
  return changed
end

local function refreshStatus()
  if statusInFlight then
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  statusInFlight = true
  local ok = Commands.run(Commands.statusArgv(), function(result)
    statusInFlight = false
    if result.timedOut then
      local phase, errorCode, daemonOk = Parse.classifyError(result)
      publish({
        phase = phase,
        available = true,
        errorCode = errorCode,
        message = Parse.truncate(result.stderr, 300),
      })
      return
    end
    if result.exitCode ~= 0 then
      local phase, errorCode, daemonOk = Parse.classifyError(result)
      local patch = {
        phase = phase,
        available = true,
        errorCode = errorCode,
        message = Parse.truncate(result.stderr, 300),
      }
      if daemonOk ~= nil then
        patch.daemonOk = daemonOk
      end
      publish(patch)
      return
    end
    local phase, decodeFailed = Parse.parseStatus(result.stdout)
    if decodeFailed then
      publish({
        phase = "unknown",
        available = true,
        daemonOk = true,
        errorCode = "decode-failed",
        message = Parse.truncate(result.stderr, 300),
      })
    else
      publish({
        phase = phase,
        available = true,
        daemonOk = true,
        errorCode = "",
        message = "",
      })
    end
  end, 8000)
  if not ok then
    statusInFlight = false
    local code = noctalia.commandExists("warp-cli") and "command-failed" or "cli-missing"
    publish({
      phase = "error",
      available = noctalia.commandExists("warp-cli"),
      errorCode = code,
      message = noctalia.tr("error." .. code),
    })
  end
end

local function refreshSettings()
  if settingsInFlight or actionInFlight then
    return
  end
  if not noctalia.commandExists("warp-cli") then
    return
  end
  settingsInFlight = true
  local ok = Commands.run(Commands.settingsArgv(), function(result)
    settingsInFlight = false
    if result.timedOut then
      noctalia.log("cloudflare-warp: settings timeout")
      return
    end
    if result.exitCode ~= 0 then
      noctalia.log("cloudflare-warp: settings failed: " .. Parse.truncate(result.stderr, 300))
      return
    end
    local parsed = Parse.parseSettings(result.stdout)
    if not parsed.ok then
      if parsed.decodeFailed then
        publish({ errorCode = "decode-failed" })
      end
      return
    end
    local patch = {}
    if parsed.mode ~= nil then patch.mode = parsed.mode end
    if parsed.protocol ~= nil then patch.protocol = parsed.protocol end
    if parsed.alwaysOn ~= nil then patch.alwaysOn = parsed.alwaysOn end
    if parsed.switchLocked ~= nil then patch.switchLocked = parsed.switchLocked end
    if parsed.splitTunnelMode ~= nil then patch.splitTunnelMode = parsed.splitTunnelMode end
    if parsed.splitTunnelCount ~= nil then patch.splitTunnelCount = parsed.splitTunnelCount end
    publish(patch)
  end, 8000)
  if not ok then
    settingsInFlight = false
    noctalia.log("cloudflare-warp: settings launch failed")
  end
end

local function refreshRegistration()
  if registrationInFlight or actionInFlight then
    return
  end
  if not noctalia.commandExists("warp-cli") then
    return
  end
  registrationInFlight = true
  local ok = Commands.run(Commands.registrationArgv(), function(result)
    registrationInFlight = false
    if result.timedOut then
      noctalia.log("cloudflare-warp: registration timeout")
      return
    end
    local registered, accountType = Parse.parseRegistration(result.stdout, result.exitCode)
    publish({
      registered = registered,
      accountType = accountType,
    })
  end, 8000)
  if not ok then
    registrationInFlight = false
    noctalia.log("cloudflare-warp: registration launch failed")
  end
end

local function refreshTrace(bypassSuspension)
  if traceInFlight then
    return
  end
  local now = noctalia.nowMs()
  if bypassSuspension == true then
    -- Manual refresh clears the breaker so a user-initiated probe can
    -- recover immediately.
    traceSuspendedUntil = 0
  elseif now < traceSuspendedUntil then
    -- Circuit breaker open: auto-trace stays suspended (no log spam).
    return
  end
  traceInFlight = true
  traceSentAt = now
  noctalia.http({ url = TRACE_URL }, function(res)
    traceInFlight = false
    local now = noctalia.nowMs()
    local elapsed = now - traceSentAt
    if elapsed > settings.trace_interval_s * 1000 then
      return
    end
    local body = res.body
    if res.ok ~= true or type(body) ~= "string" or body == "" then
      traceFailCount += 1
      if traceFailCount % 5 == 1 then
        noctalia.log("cloudflare-warp: trace failed status=" .. tostring(res.status))
      end
      if traceFailCount >= TRACE_FAIL_SUSPEND_AT and now >= traceSuspendedUntil then
        local waitS = math.floor(settings.trace_interval_s * 10 * 2 ^ math.min(traceBackoffLevel, TRACE_BACKOFF_MAX))
        traceSuspendedUntil = now + waitS * 1000
        traceBackoffLevel = math.min(traceBackoffLevel + 1, TRACE_BACKOFF_MAX)
        noctalia.log("cloudflare-warp: trace suspended after " .. traceFailCount
          .. " failures, retry in " .. waitS .. "s")
      end
      return
    end
    traceFailCount = 0
    traceBackoffLevel = 0
    traceSuspendedUntil = 0
    local t = Parse.parseTrace(body)
    publish({
      trace = { warp = t.warp, ip = t.ip, loc = t.loc, colo = t.colo, atMs = noctalia.nowMs() },
    })
  end)
end

local function handleMutationResult(result)
  if result.timedOut then
    publish({
      busy = false,
      phase = "error",
      errorCode = "timeout",
      message = Parse.truncate(result.stderr, 300),
    })
    return
  end
  if result.exitCode ~= 0 then
    local phase, errorCode, daemonOk = Parse.classifyError(result)
    local patch = {
      busy = false,
      phase = phase,
      errorCode = errorCode,
      message = Parse.truncate(result.stderr, 300),
    }
    if daemonOk ~= nil then
      patch.daemonOk = daemonOk
    end
    publish(patch)
    return
  end
  publish({ busy = false })
  refreshStatus()
  refreshSettings()
end

local function doConnect()
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring connect")
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  actionInFlight = true
  publish({
    busy = true,
    phase = "connecting",
    available = true,
    errorCode = "",
    message = "",
  })
  local ok = Commands.run(Commands.connectArgv(), function(result)
    actionInFlight = false
    handleMutationResult(result)
  end, 15000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function doDisconnect()
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring disconnect")
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  actionInFlight = true
  publish({
    busy = true,
    phase = "disconnecting",
    available = true,
    errorCode = "",
    message = "",
  })
  local ok = Commands.run(Commands.disconnectArgv(), function(result)
    actionInFlight = false
    handleMutationResult(result)
  end, 15000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function doToggle()
  local cur = noctalia.state.get(State.CHANNEL_STATUS) or State.defaultStatus()
  if cur.phase == "connected" or cur.phase == "connecting" then
    doDisconnect()
  else
    doConnect()
  end
end

local function doSetMode(mode)
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring set-mode")
    return
  end
  local cur = noctalia.state.get(State.CHANNEL_STATUS) or State.defaultStatus()
  if cur.switchLocked then
    noctalia.notifyError(noctalia.tr("notify.error.title"), noctalia.tr("error.mode-locked"))
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  local prevMode = cur.mode
  actionInFlight = true
  publish({
    busy = true,
    mode = mode,
    errorCode = "",
    message = "",
  })
  local ok = Commands.run(Commands.modeArgv(mode), function(result)
    actionInFlight = false
    if result.timedOut or result.exitCode ~= 0 then
      handleMutationResult(result)
      publish({ mode = prevMode })
      return
    end
    publish({ busy = false, mode = mode })
    refreshStatus()
    refreshSettings()
  end, 15000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function doSetFamilies(families)
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring set-families")
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  actionInFlight = true
  publish({ busy = true, errorCode = "", message = "" })
  local ok = Commands.run(Commands.familiesArgv(families), function(result)
    actionInFlight = false
    if result.timedOut or result.exitCode ~= 0 then
      handleMutationResult(result)
      return
    end
    publish({ busy = false, families = families })
  end, 15000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function doSetProtocol(protocol)
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring set-protocol")
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  local canonical = protocol == "masque" and "MASQUE" or "WireGuard"
  actionInFlight = true
  publish({ busy = true, errorCode = "", message = "" })
  local ok = Commands.run(Commands.protocolArgv(canonical), function(result)
    actionInFlight = false
    if result.timedOut or result.exitCode ~= 0 then
      handleMutationResult(result)
      return
    end
    publish({ busy = false, protocol = protocol })
    refreshSettings()
  end, 15000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function doRefresh()
  refreshStatus()
  refreshSettings()
  refreshRegistration()
  refreshTrace(true)
end

local function doRegister()
  if actionInFlight then
    noctalia.log("cloudflare-warp: warn action in flight, ignoring register")
    return
  end
  if not noctalia.commandExists("warp-cli") then
    publish({
      phase = "unavailable",
      available = false,
      daemonOk = false,
      errorCode = "cli-missing",
      message = noctalia.tr("error.cli-missing"),
    })
    return
  end
  actionInFlight = true
  publish({ busy = true, errorCode = "", message = "" })
  local ok = Commands.run(Commands.registerArgv(), function(result)
    actionInFlight = false
    if result.timedOut then
      -- registration new is interactive: it prints a URL and waits for the
      -- browser sign-in. The timeout only cuts our wait, the client may still
      -- complete the flow, so this is not an error - the regular poll picks
      -- up registered = true once the user finishes.
      publish({ busy = false })
      noctalia.notifyError(
        noctalia.tr("notify.error.title"),
        noctalia.tr("error.register-pending")
      )
      return
    end
    if result.exitCode ~= 0 then
      handleMutationResult(result)
      return
    end
    publish({ busy = false })
    refreshRegistration()
    refreshStatus()
  end, 30000)
  if not ok then
    actionInFlight = false
    publish({
      busy = false,
      phase = "error",
      errorCode = "command-failed",
      message = noctalia.tr("error.command-failed"),
    })
  end
end

local function dispatch(action, fields, source)
  fields = type(fields) == "table" and fields or {}
  source = tostring(source or "")

  local payload = ""
  local valid = false

  if action == "toggle" or action == "connect" or action == "disconnect"
      or action == "refresh" or action == "register" then
    valid = true
  elseif action == "set-mode" then
    payload = tostring(fields.mode or "")
    valid = Commands.MODES[payload] ~= nil
  elseif action == "set-families" then
    payload = tostring(fields.families or "")
    valid = Commands.FAMILIES[payload] ~= nil
  elseif action == "set-protocol" then
    payload = string.lower(tostring(fields.protocol or ""))
    valid = Commands.PROTOCOLS[payload] ~= nil
  end

  if not valid then
    noctalia.log("cloudflare-warp: warn rejected action=" .. tostring(action)
      .. " payload=" .. tostring(fields.mode or fields.families or fields.protocol or ""))
    return
  end

  noctalia.log("cloudflare-warp: ipc " .. action .. " payload=" .. payload .. " source=" .. source)

  if action == "toggle" then
    doToggle()
  elseif action == "connect" then
    doConnect()
  elseif action == "disconnect" then
    doDisconnect()
  elseif action == "refresh" then
    doRefresh()
  elseif action == "register" then
    doRegister()
  elseif action == "set-mode" then
    doSetMode(payload)
  elseif action == "set-families" then
    doSetFamilies(payload)
  elseif action == "set-protocol" then
    doSetProtocol(payload)
  end
end

local function onCommand(cmd)
  if type(cmd) ~= "table" then
    noctalia.log("cloudflare-warp: warn invalid command (expected table)")
    return
  end
  local seq = tonumber(cmd.seq) or 0
  if seq > 0 then
    if seq <= lastHandledSeq then
      return
    end
    lastHandledSeq = seq
  end
  dispatch(tostring(cmd.action or ""), cmd, tostring(cmd.source or ""))
end

function onIpc(event, payload)
  event = tostring(event or "")
  payload = tostring(payload or "")
  local fields = {}
  if event == "set-mode" then
    fields.mode = payload
  elseif event == "set-families" then
    fields.families = payload
  elseif event == "set-protocol" then
    fields.protocol = payload
  end
  dispatch(event, fields, "ipc")
end

function update()
  tick += 1
  refreshStatus()
  if tick % SETTINGS_EVERY == 0 then
    refreshSettings()
  end
  if tick % REGISTRATION_EVERY == 0 then
    refreshRegistration()
  end
  local now = noctalia.nowMs()
  if settings.auto_trace and (now - lastTraceAt) >= settings.trace_interval_s * 1000 then
    if now < traceSuspendedUntil then
      -- Circuit breaker open: skip without consuming the timer slot, so the
      -- probe runs promptly once the suspension expires.
      lastTraceAt = 0
    else
      lastTraceAt = now
      refreshTrace()
    end
  end
  if tick % HEARTBEAT_TICKS == 0 then
    local cur = noctalia.state.get(State.CHANNEL_STATUS) or State.defaultStatus()
    noctalia.log("cloudflare-warp: heartbeat phase=" .. cur.phase .. " at=" .. tostring(cur.updatedAtMs))
  end
end

function onConfigChanged()
  settings = readSettings()
  noctalia.setUpdateInterval(settings.poll_interval_ms)
  lastTraceAt = 0
  noctalia.log("cloudflare-warp: config changed poll=" .. tostring(settings.poll_interval_ms))
end

function onEnable()
  noctalia.log("cloudflare-warp: enabled")
  if not statusInFlight then
    refreshStatus()
  end
end

function onExit(_signal, reason)
  noctalia.log("cloudflare-warp: exit reason=" .. tostring(reason))
end

local function readVersion()
  if not noctalia.commandExists("warp-cli") then
    return
  end
  Commands.run(Commands.versionArgv(), function(result)
    if result.timedOut or result.exitCode ~= 0 then
      return
    end
    local version = tostring(result.stdout or "")
    version = version:match("%d+%.%d+%.%d+%.%d+") or version:match("^%s*(.-)%s*$")
    if version and version ~= "" then
      State.publish({ cliVersion = version })
    end
  end, 5000)
end

-- Init
settings = readSettings()
noctalia.setUpdateInterval(settings.poll_interval_ms)
noctalia.log("cloudflare-warp: bootstrap ok schema=" .. State.SCHEMA)
noctalia.state.watch(State.CHANNEL_COMMAND, onCommand)
State.publish({ families = "malware" })
readVersion()
refreshStatus()