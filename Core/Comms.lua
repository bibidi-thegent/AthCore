-- Core/Comms.lua
-- Addon message layer with dispatch to registered module handlers.
-- Uses C_ChatInfo.SendAddonMessage with a simple custom serialiser.

local ATH = AthCore
ATH.Comms = {}
local C = ATH.Comms

local PREFIX = ATH.ADDON_PREFIX  -- "Athenaeum" (<=16 chars)

-- ── Registered message handlers from modules ─────────────────────────────────
local messageHandlers = {}  -- msgType -> handler(data, senderShort)

function C.RegisterHandler(msgType, handler)
    messageHandlers[msgType] = handler
end

-- ── Simple serialiser (no external lib needed) ────────────────────────────────
-- Format: "KEY=VALUE|KEY=VALUE|..."  Values must not contain | or =

local function Serialize(t)
    local parts = {}
    for k, v in pairs(t) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    return table.concat(parts, "|")
end

local function Deserialize(str)
    local t = {}
    for pair in str:gmatch("[^|]+") do
        local k, v = pair:match("^(.-)=(.+)$")
        if k then t[k] = v end
    end
    return t
end

local function Encode(msgType, payload)
    return msgType .. ":" .. Serialize(payload)
end

local function Decode(raw)
    local msgType, rest = raw:match("^([^:]+):(.+)$")
    if not msgType then return nil, nil end
    return msgType, Deserialize(rest)
end

-- ── Public send helpers ──────────────────────────────────────────────────────

function C.Send(channel, msgType, payload, target)
    local packet = Encode(msgType, payload)
    if channel == "WHISPER" then
        C_ChatInfo.SendAddonMessage(PREFIX, packet, "WHISPER", target)
    else
        C_ChatInfo.SendAddonMessage(PREFIX, packet, channel)
    end
end

function C.BroadcastVersion()
    if not IsInGuild() then return end
    C.Send("GUILD", ATH.COMM.VERSION, { ver = ATH.VERSION, name = UnitName("player") })
end

-- ── Incoming message handler ──────────────────────────────────────────────────

function C.HandleAddonMessage(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end
    local msgType, data = Decode(message)
    if not msgType or not data then return end

    local senderShort = ATH.Utils.ShortName(sender)

    -- Core handles VERSION internally
    if msgType == ATH.COMM.VERSION then
        ATH._peerVersions = ATH._peerVersions or {}
        ATH._peerVersions[senderShort] = data.ver
        return
    end

    -- Dispatch to registered module handler
    local handler = messageHandlers[msgType]
    if handler then
        -- Skip own messages for sync-type messages
        local myName = ATH._playerName or UnitName("player")
        handler(data, senderShort, myName)
    end
end

-- ── Serializer access (for modules that need direct access) ──────────────────

C.Serialize   = Serialize
C.Deserialize = Deserialize
C.Encode      = Encode
C.Decode      = Decode

-- ── Init ──────────────────────────────────────────────────────────────────────

function C.Init()
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end
