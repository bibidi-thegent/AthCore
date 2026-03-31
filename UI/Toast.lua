-- UI/Toast.lua
-- Toast notification system for AthCore.
-- PERSISTENT toasts (guild calendar events) require manual dismiss.
-- AUTO-FADE toasts fade after TOAST_LIFE seconds.
-- Supports module-specific accent colours (whisper = purple/pink, officer = green/gold).

local ATH = AthCore
ATH.Toast = {}
local Toast = ATH.Toast

local S = ATH.Shared
local U = ATH.Utils
local T = ATH.T

local TOAST_W      = 320
local TOAST_H      = 64
local TOAST_MARGIN = 6
local TOAST_LIFE   = 7
local TOAST_FADE   = 0.5
local MAX_TOASTS   = 5

local REMINDER_SOUND = SOUNDKIT and SOUNDKIT.UI_CALENDAR_EVENT_ALARM or 5961

local PERSISTENT = {
    [ATH.TOAST.GUILD_EVENT] = true,
}

local ICONS = {
    [ATH.TOAST.GUILD_EVENT]  = "Interface\\Icons\\INV_Misc_Note_01",
    [ATH.TOAST.GUILD_MSG]    = "Interface\\Icons\\Achievement_Guild_GuildChat",
    [ATH.TOAST.OFFICER_MSG]  = "Interface\\Icons\\Achievement_Guild_Rank04",
    [ATH.TOAST.CHANNEL_MSG]  = "Interface\\Icons\\Ability_Hunter_BeastCall",
    [ATH.TOAST.WHISPER]      = "Interface\\Icons\\INV_Letter_15",
}

-- Module-specific accent colours for the left bar and title
local TOAST_ACCENT = {
    [ATH.TOAST.WHISPER]     = T.whisperAccent,   -- purple/pink
    [ATH.TOAST.OFFICER_MSG] = T.officerAccent,   -- green
    -- All others use the default gold accent
}

local activeToasts = {}
local toastPool    = {}
local anchorFrame  = nil

-- ── Anchor (draggable positioning) ──────────────────────────────────────────

local function GetAnchorPos()
    local db = ATH.DB and ATH.DB.toastAnchor
    if db then return db.point, db.relPoint, db.xOfs, db.yOfs end
    return "BOTTOMRIGHT", "BOTTOMRIGHT", -16, 80
end

local function SaveAnchorPos()
    if not anchorFrame then return end
    local p, _, rp, x, y = anchorFrame:GetPoint()
    if not ATH.DB then return end
    ATH.DB.toastAnchor = { point = p, relPoint = rp, xOfs = math.floor(x), yOfs = math.floor(y) }
end

local function EnsureAnchor()
    if anchorFrame then return anchorFrame end
    anchorFrame = CreateFrame("Frame", "AthCoreToastAnchor", UIParent, "BackdropTemplate")
    anchorFrame:SetSize(TOAST_W, 24)
    local p, rp, x, y = GetAnchorPos()
    anchorFrame:SetPoint(p, UIParent, rp, x, y)
    anchorFrame:SetMovable(true)
    anchorFrame:EnableMouse(false)
    anchorFrame:SetFrameStrata("DIALOG")
    S.SetBackdrop(anchorFrame, T.accent, T.border)
    anchorFrame:SetAlpha(0.8)

    local label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("Drag to move toasts -- /ath lock to lock")
    label:SetTextColor(1, 1, 1)
    anchorFrame._label = label

    anchorFrame:SetScript("OnDragStart", anchorFrame.StartMoving)
    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchorPos()
    end)
    anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame:Hide()
    return anchorFrame
end

function Toast.UnlockAnchor()
    local f = EnsureAnchor()
    f:EnableMouse(true)
    f:Show()
    print("|cffFFD100[AthCore]|r Toast anchor unlocked. Drag to reposition, then type |cffFFD700/ath lock|r.")
end

function Toast.LockAnchor()
    if anchorFrame then
        SaveAnchorPos()
        anchorFrame:EnableMouse(false)
        anchorFrame:Hide()
    end
    print("|cffFFD100[AthCore]|r Toast anchor locked.")
end

-- ── Positioning ───────────────────────────────────────────────────────────────

local function Reposition()
    local p, rp, x, y = GetAnchorPos()
    for i, tf in ipairs(activeToasts) do
        local yOff = (i-1) * (TOAST_H + TOAST_MARGIN)
        tf:ClearAllPoints()
        tf:SetPoint(p, UIParent, rp, x, y + yOff)
    end
end

local function Release(tf)
    for i, t in ipairs(activeToasts) do
        if t == tf then table.remove(activeToasts, i); break end
    end
    tf:Hide()
    tf:SetScript("OnUpdate", nil)
    tf:SetAlpha(1)
    table.insert(toastPool, tf)
    Reposition()
end

-- ── Frame factory ─────────────────────────────────────────────────────────────

local function AcquireFrame()
    local tf = table.remove(toastPool)
    if tf then return tf end

    tf = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    tf:SetSize(TOAST_W, TOAST_H)
    tf:SetFrameStrata("DIALOG")
    tf:EnableMouse(true)
    S.SetBackdrop(tf, T.bg, T.border)

    -- Left accent bar
    local bar = tf:CreateTexture(nil, "OVERLAY")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("BOTTOMLEFT")
    tf._bar = bar

    -- Icon
    local icon = tf:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", 10, 0)
    tf._icon = icon

    -- Title
    local titleFS = tf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetPoint("TOPLEFT", 54, -10)
    titleFS:SetWidth(TOAST_W - 80)
    tf._title = titleFS

    -- Body
    local bodyFS = tf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFS:SetPoint("TOPLEFT", 54, -28)
    bodyFS:SetWidth(TOAST_W - 80)
    bodyFS:SetWordWrap(true)
    bodyFS:SetTextColor(0.8, 0.8, 0.8)
    tf._body = bodyFS

    -- Dismiss button (persistent only)
    local xBtn = CreateFrame("Button", nil, tf, "UIPanelCloseButton")
    xBtn:SetSize(22, 22)
    xBtn:SetPoint("TOPRIGHT", -2, -2)
    xBtn:SetScript("OnClick", function() Release(tf) end)
    tf._xBtn = xBtn

    -- Hover effects
    tf:SetScript("OnEnter", function(self)
        self:SetBackdropColor(U.RGBA(T.bgHeader))
    end)
    tf:SetScript("OnLeave", function(self)
        self:SetBackdropColor(U.RGBA(T.bg))
    end)

    return tf
end

-- ── Show ──────────────────────────────────────────────────────────────────────

function Toast.Show(toastType, title, body)
    -- Respect notification settings
    local settingKey = ({
        [ATH.TOAST.GUILD_EVENT]  = "guildEvent",
        [ATH.TOAST.GUILD_MSG]    = "guildMsg",
        [ATH.TOAST.OFFICER_MSG]  = "officerMsg",
        [ATH.TOAST.CHANNEL_MSG]  = "channelMsg",
        [ATH.TOAST.WHISPER]      = "whisper",
    })[toastType]
    if settingKey and ATH.DB and ATH.DB.notifications and ATH.DB.notifications[settingKey] == false then
        return
    end

    -- Evict oldest if at cap
    if #activeToasts >= MAX_TOASTS then Release(activeToasts[1]) end

    local tf         = AcquireFrame()
    local persistent = PERSISTENT[toastType] or false

    -- Determine accent colour: module-specific or default gold
    local accentColor = TOAST_ACCENT[toastType]
    local ar, ag, ab
    if accentColor then
        ar, ag, ab = accentColor.r, accentColor.g, accentColor.b
    else
        ar, ag, ab = U.AccentRGB()
    end

    tf._bar:SetColorTexture(ar, ag, ab, 1)
    tf._title:SetTextColor(ar, ag, ab)
    tf._title:SetText(title or "")
    tf._body:SetText(body or "")
    tf._icon:SetTexture(ICONS[toastType] or "Interface\\Icons\\INV_Misc_QuestionMark")
    tf._xBtn:SetShown(persistent)

    table.insert(activeToasts, tf)
    Reposition()
    tf:Show()

    if toastType == ATH.TOAST.GUILD_EVENT then
        PlaySound(REMINDER_SOUND, "Master")
    end

    if not persistent then
        local elapsed = 0
        tf:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local remaining = TOAST_LIFE - elapsed
            if remaining <= 0 then
                Release(self)
            elseif remaining < TOAST_FADE then
                self:SetAlpha(remaining / TOAST_FADE)
            end
        end)
    end
end

-- Convenience wrappers
function Toast.ShowGuildEvent(title, body)
    Toast.Show(ATH.TOAST.GUILD_EVENT, title, body)
end

function Toast.ShowGuildMsg(sender, text)
    Toast.Show(ATH.TOAST.GUILD_MSG, "Guild Chat", sender .. ": " .. text)
end

function Toast.ShowOfficerMsg(sender, text)
    Toast.Show(ATH.TOAST.OFFICER_MSG, "Officer Chat", sender .. ": " .. text)
end

function Toast.ShowChannel(chan, sender, text)
    Toast.Show(ATH.TOAST.CHANNEL_MSG, chan, sender .. ": " .. text)
end

function Toast.ShowWhisper(text, sender)
    local short = U.ShortName(sender)
    Toast.Show(ATH.TOAST.WHISPER, "Whisper from " .. short, text)
end

-- ── Calendar event reminder scanner ──────────────────────────────────────────

local remindersSent = {}
local scanTimer     = CreateFrame("Frame")
local scanElapsed   = 0
local SCAN_INTERVAL = 60

scanTimer:SetScript("OnUpdate", function(_, dt)
    if not ATH.DB or not ATH.DB.notifications or not ATH.DB.notifications.guildEvent then return end
    scanElapsed = scanElapsed + dt
    if scanElapsed < SCAN_INTERVAL then return end
    scanElapsed = 0

    local ok, today = pcall(function() return C_DateAndTime.GetCurrentCalendarTime() end)
    if not ok or not today then return end

    local warnSecs = (ATH.DB.eventReminderMinutes or 15) * 60
    local now      = time()
    local baseTime = time({ year=today.year, month=today.month, day=today.monthDay, hour=0, min=0, sec=0 })

    C_Calendar.OpenCalendar()

    for dayOffset = 0, 1 do
        local target      = baseTime + dayOffset * 86400
        local tMonth      = tonumber(date("%m", target))
        local tDay        = tonumber(date("%d", target))
        local monthOffset = tMonth - today.month
        if monthOffset < 0 then monthOffset = monthOffset + 12 end

        local numEvents = C_Calendar.GetNumDayEvents(monthOffset, tDay)
        for i = 1, numEvents do
            pcall(function()
                local info = C_Calendar.GetDayEvent(monthOffset, tDay, i)
                if not info then return end
                local calType = rawget(info, "calendarType")
                if calType ~= "GUILD" and calType ~= "GUILD_EVENT" then return end
                local t   = info.startTime
                local ets = time({ year=t.year, month=t.month, day=t.monthDay, hour=t.hour, min=t.minute, sec=0 })
                local diff = ets - now
                local key = tostring(rawget(info, "title") or "?") .. tostring(ets)
                if diff > 0 and diff <= warnSecs and not remindersSent[key] then
                    remindersSent[key] = true
                    Toast.ShowGuildEvent(
                        "Event Starting Soon",
                        string.format('"%s" starts in ~%d min', rawget(info, "title") or "Event", math.floor(diff/60)))
                end
                if diff <= 0 then remindersSent[key] = nil end
            end)
        end
    end
end)

function Toast.Init()
    -- Scanner runs automatically via OnUpdate; nothing else needed
end
