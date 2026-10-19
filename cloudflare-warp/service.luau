--!nonstrict
-- Cloudflare WARP - headless service (Phase 0 bootstrap).
--
-- Phase 0 deliberately does not touch WARP: it reads the plugin-level settings,
-- applies the poll interval and logs one bootstrap line. No subprocesses, no
-- network calls, no state writes and no IPC handlers yet.

local State = require("./lib/state.luau")

local function readSettings()
    return {
        poll_interval_ms = noctalia.getConfig("poll_interval_ms") or 3000,
        notify_on_change = noctalia.getConfig("notify_on_change"),
        notify_on_error = noctalia.getConfig("notify_on_error"),
        auto_trace = noctalia.getConfig("auto_trace"),
        trace_interval_s = noctalia.getConfig("trace_interval_s") or 60,
    }
end

local settings = readSettings()

noctalia.setUpdateInterval(settings.poll_interval_ms)
noctalia.log("cloudflare-warp: bootstrap ok schema=" .. State.SCHEMA)

-- Empty tick: polling starts in Phase 1.
function update() end

function onEnable()
    noctalia.log("cloudflare-warp: enabled")
end

function onExit(_signal, reason)
    noctalia.log("cloudflare-warp: exit reason=" .. tostring(reason))
end

function onConfigChanged()
    settings = readSettings()
    noctalia.setUpdateInterval(settings.poll_interval_ms)
    noctalia.log("cloudflare-warp: config changed")
end
