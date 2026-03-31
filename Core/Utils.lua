-- Core/Utils.lua
-- Shared helper functions used across all modules.

local ATH = AthCore
ATH.Utils = {}
local U = ATH.Utils

-- ── Colour helpers ────────────────────────────────────────────────────────────

function U.RGBA(c, a)
    return c.r, c.g, c.b, a ~= nil and a or (c.a or 1)
end

function U.HexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1,2), 16) / 255,
           tonumber(hex:sub(3,4), 16) / 255,
           tonumber(hex:sub(5,6), 16) / 255
end

function U.RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function U.Colorize(hex, text)
    return "|cff" .. hex .. text .. "|r"
end

function U.ClassColor(classKey)
    if not classKey then return 1, 1, 1 end
    local key = classKey:upper():gsub("%s+", ""):gsub("%-", "")
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

function U.ClassColorHex(classKey)
    local r, g, b = U.ClassColor(classKey)
    return U.RGBToHex(r, g, b)
end

-- ── String helpers ────────────────────────────────────────────────────────────

function U.ShortName(fullName)
    if not fullName then return "Unknown" end
    local ok, result = pcall(string.match, fullName, "^([^%-]+)")
    if ok and result then return result end
    return "Unknown"
end

function U.FormatTimestamp(ts)
    return date("%H:%M", ts or time())
end

function U.FormatTime(ts)
    return date("%H:%M:%S", ts or time())
end

function U.FormatNumber(n)
    if not n then return "0" end
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(n)
end

-- ── Player / guild helpers ────────────────────────────────────────────────────

ATH._playerName    = ""
ATH._playerClass   = ""
ATH._playerGuild   = ""
ATH._isOfficer     = false
ATH._isRaidLeader  = false

function U.CachePlayerInfo()
    ATH._playerName  = UnitName("player") or ""
    local _, cls     = UnitClass("player")
    ATH._playerClass = cls or ""
    ATH._playerGuild = GetGuildInfo("player") or ""
    ATH._isOfficer   = U.DetectOfficer()
end

function U.DetectOfficer()
    if not IsInGuild() then return false end
    local myName = UnitName("player")
    local total  = GetNumGuildMembers()
    for i = 1, total do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if name and U.ShortName(name) == myName then
            return rankIndex <= 1
        end
    end
    return false
end

function U.IsOfficer()   return ATH._isOfficer   end
function U.IsRaidLeader()
    return UnitIsGroupLeader("player") and (IsInRaid() or IsInGroup())
end

function U.GetOnlineMembers()
    local members = {}
    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, rank, rankIndex, level, _, zone, note, _, online, status, class =
            GetGuildRosterInfo(i)
        if online and name then
            table.insert(members, {
                name      = U.ShortName(name),
                fullName  = name,
                rank      = rank,
                rankIndex = rankIndex,
                level     = level,
                zone      = zone or "",
                class     = class or "WARRIOR",
                status    = status,
            })
        end
    end
    return members
end

function U.GetRosterSummary()
    local members = U.GetOnlineMembers()
    local byRank  = {}
    for _, m in ipairs(members) do
        local rn = m.rank or "Unknown"
        byRank[rn] = (byRank[rn] or 0) + 1
    end
    return { totalOnline = #members, byRank = byRank }
end

-- ── Spec helpers ──────────────────────────────────────────────────────────────

function U.GetPlayerSpecInfo()
    local _, classKey = UnitClass("player")
    local specIndex   = GetSpecialization()
    if not specIndex or not classKey then return classKey, nil, nil, nil end

    local specID, specName, _, icon = GetSpecializationInfo(specIndex)

    local engKey = ""
    if ATH.SPEC_IDS[classKey] then
        for k, id in pairs(ATH.SPEC_IDS[classKey]) do
            if id == specID then engKey = k; break end
        end
    end
    if engKey == "" then
        engKey = (specName or ""):gsub("%s+", "")
    end

    return classKey, engKey, specName, icon
end

function U.GetSpecIcon(specName, classKey)
    local classID = ATH.CLASS_IDS[classKey]
    if not classID then return nil end
    local num = GetNumSpecializationsForClassID and GetNumSpecializationsForClassID(classID) or 0
    for i = 1, num do
        local _, name, _, icon = GetSpecializationInfoForClassID(classID, i)
        if name == specName then return icon end
    end
    return nil
end

-- ── Item link builder ─────────────────────────────────────────────────────────

function U.BuildItemLink(itemID, bonusStr)
    if not itemID then return nil end
    if bonusStr and bonusStr ~= "" then
        local count = 0
        for _ in bonusStr:gmatch("[^:]+") do count = count + 1 end
        return "item:" .. itemID .. "::::::::::::" .. count .. ":" .. bonusStr
    end
    return "item:" .. itemID
end

-- ── Backdrop helper ───────────────────────────────────────────────────────────

function U.SetBackdrop(frame, bgC, borderC, edgeSize)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = edgeSize or 1,
    })
    if bgC     then frame:SetBackdropColor(U.RGBA(bgC)) end
    if borderC then frame:SetBackdropBorderColor(U.RGBA(borderC)) end
end

-- ── Accent colour (from DB, falls back to constant) ───────────────────────────

function U.AccentRGB()
    local hex = ATH.DB and ATH.DB.colors and ATH.DB.colors.accent or "FFD100"
    return U.HexToRGB(hex)
end
