--!nonstrict
-- Cloudflare WARP - shared constants.
--
-- Phase 0 exposes only the state schema and channel names. Publishing and
-- patching helpers are added in Phase 1, when the service becomes the single
-- writer of the status channel.

local M = {}

M.SCHEMA = 1
M.CHANNEL_STATUS = "warp.status"
M.CHANNEL_COMMAND = "warp.command"

-- Ordered set of status phases defined by SPEC section 3.1.
M.PHASES = {
    "unavailable",
    "unregistered",
    "disconnected",
    "connecting",
    "connected",
    "disconnecting",
    "error",
    "unknown",
}

return M
