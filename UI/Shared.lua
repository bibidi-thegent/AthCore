-- UI/Shared.lua
-- Reusable UI primitives: backdrops, scroll frames, dropdowns, dividers.

local ATH = AthCore
ATH.Shared = {}
local S = ATH.Shared
local U = ATH.Utils
local T = ATH.T

-- ── Backdrop ──────────────────────────────────────────────────────────────────

function S.SetBackdrop(frame, bgColor, borderColor, edgeSize)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = edgeSize or 1,
    })
    if bgColor     then frame:SetBackdropColor(U.RGBA(bgColor)) end
    if borderColor then frame:SetBackdropBorderColor(U.RGBA(borderColor)) end
end

-- ── Accent line (1px horizontal rule) ────────────────────────────────────────

function S.AddAccentLine(parent, anchorFrame, side)
    side = side or "BOTTOM"
    local line = parent:CreateTexture(nil, "OVERLAY")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  anchorFrame, side .. "LEFT",  0, 0)
    line:SetPoint("TOPRIGHT", anchorFrame, side .. "RIGHT", 0, 0)
    line:SetColorTexture(U.RGBA(T.border))
    return line
end

-- ── Scroll frame + text child (SimpleHTML) ────────────────────────────────────
-- Returns: scrollFrame, scrollChild, fontString (proxy)

function S.MakeChatScrollFrame(parent, x, y, w, h)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", x, y)
    sf:SetSize(w, h)
    sf:SetClipsChildren(true)

    local bg = sf:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.30)

    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(w - 20, h)
    sf:SetScrollChild(child)

    local html = CreateFrame("SimpleHTML", nil, child)
    html:SetPoint("TOPLEFT", 4, -4)
    html:SetWidth(w - 32)
    html:SetHeight(h)

    pcall(function() html:SetHyperlinksEnabled(true) end)

    local fontFile, fontSize = ChatFontNormal:GetFont()
    local customSize = ATH.DB and ATH.DB.display and ATH.DB.display.fontSize
    if customSize and customSize > 0 then fontSize = customSize end
    if fontFile then
        pcall(function() html:SetFont("p", fontFile, fontSize, "") end)
    end

    local SAFE_TOOLTIP = {
        item = true, spell = true, enchant = true, achievement = true,
        currency = true, battlepet = true, talent = true, glyph = true,
        unit = true, instancelock = true,
    }

    html:SetScript("OnHyperlinkEnter", function(self, link)
        local linkType = link:match("^([^:]+):")
        if linkType and SAFE_TOOLTIP[linkType] then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end)
    html:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
    html:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button)
    end)

    local fs = {
        SetText = function(_, text)
            local body = (text or "")
            body = body:gsub("&", "&amp;")
            body = body:gsub("<", "&lt;")
            body = body:gsub(">", "&gt;")
            body = body:gsub("\n", "<br/>")
            html:SetText("<html><body><p>" .. body .. "</p></body></html>")
            local ch = (html.GetContentHeight and html:GetContentHeight()) or 0
            if ch > 0 then html:SetHeight(ch + 8) end
        end,
        GetStringHeight = function(_)
            return (html.GetContentHeight and html:GetContentHeight()) or html:GetHeight()
        end,
        GetParent = function(_)
            return child
        end,
    }

    function sf:ScrollToBottom()
        self:SetVerticalScroll(self:GetVerticalScrollRange())
    end

    return sf, child, fs
end

-- Generic scroll frame (no fontstring, empty child for programmatic rows)
function S.MakeScrollFrame(parent, x, y, w, h, bgAlpha)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", x, y)
    sf:SetSize(w, h)
    sf:SetClipsChildren(true)

    if bgAlpha and bgAlpha > 0 then
        local bg = sf:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, bgAlpha)
    end

    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(w - 20, 1)
    sf:SetScrollChild(child)
    return sf, child
end

-- ── Chat input bar ────────────────────────────────────────────────────────────

function S.MakeChatInput(parent, x, y, w, onSend)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    box:SetSize(w - 54, 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(255)
    box:SetFontObject("ChatFontNormal")
    S.SetBackdrop(box, T.bgInput, T.border)
    box:SetTextInsets(4, 4, 2, 2)

    box:SetScript("OnEnterPressed", function(self)
        local txt = strtrim(self:GetText())
        if txt ~= "" then onSend(txt) end
        self:SetText("")
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("LEFT", box, "RIGHT", 4, 0)
    btn:SetSize(46, 22)
    btn:SetText("Send")
    btn:SetScript("OnClick", function()
        local txt = strtrim(box:GetText())
        if txt ~= "" then onSend(txt) end
        box:SetText("")
        box:ClearFocus()
    end)

    return box, btn
end

-- ── Dropdown ──────────────────────────────────────────────────────────────────

local openDropdown = nil

function S.MakeDropdown(parent, w, h, placeholder, onSelect)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    S.SetBackdrop(btn, T.bgHeader, T.border)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 8, 0)
    label:SetPoint("RIGHT", -18, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(U.RGBA(T.textMuted))
    label:SetText(placeholder)

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetText("|cffFFD100v|r")

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(200)
    S.SetBackdrop(popup, T.bg, T.border)
    popup:Hide()
    popup._rows = {}

    local function ClosePopup()
        popup:Hide()
        if openDropdown == popup then openDropdown = nil end
    end

    local sf = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     popup, 4,  -4)
    sf:SetPoint("BOTTOMRIGHT", popup, -4,  4)
    if sf.ScrollBar then sf.ScrollBar:Hide() end
    local content = CreateFrame("Frame", nil, sf)
    sf:SetScrollChild(content)

    local ITEM_H   = 30
    local MAX_SHOW = 12

    popup:EnableMouseWheel(true)
    popup:SetScript("OnMouseWheel", function(_, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * ITEM_H)))
    end)

    local function Populate(items)
        for _, r in ipairs(popup._rows) do r:Hide(); r:SetParent(nil) end
        popup._rows = {}
        if not items or #items == 0 then
            popup:SetSize(w, ITEM_H + 8)
            content:SetSize(w - 2, ITEM_H)
            return
        end

        content:SetSize(w - 2, #items * ITEM_H)

        for i, item in ipairs(items) do
            local row = CreateFrame("Button", nil, content, "BackdropTemplate")
            row:SetSize(w - 2, ITEM_H)
            row:SetPoint("TOPLEFT", 0, -(i-1)*ITEM_H)
            S.SetBackdrop(row, { r=0, g=0, b=0, a=0 }, nil)

            local indent = (item.indent or 0) * 10
            local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetPoint("TOPLEFT", row, "TOPLEFT", 8 + indent, -4)
            txt:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
            txt:SetJustifyH("LEFT")
            txt:SetJustifyV("TOP")
            txt:SetWordWrap(true)
            txt:SetNonSpaceWrap(false)

            if item.isHeader then
                txt:SetTextColor(U.RGBA(T.accent))
                txt:SetText(item.text)
                row:EnableMouse(false)
            else
                local r, g, b = item.r or 1, item.g or 1, item.b or 1
                txt:SetTextColor(r, g, b)
                txt:SetText(item.text)
                row:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(U.RGBA(T.rowHover))
                end)
                row:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                end)
                row:SetScript("OnClick", function()
                    label:SetText(item.displayText or item.text)
                    label:SetTextColor(r, g, b)
                    btn.currentValue = item.value
                    ClosePopup()
                    if onSelect then onSelect(item.value) end
                end)
            end
            table.insert(popup._rows, row)
        end

        local popH = math.min(#items * ITEM_H + 8, MAX_SHOW * ITEM_H + 8)
        popup:SetSize(w, popH)
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            ClosePopup()
        else
            if openDropdown then openDropdown:Hide() end
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
            openDropdown = popup
        end
    end)

    btn.currentValue = nil
    btn.placeholder  = placeholder
    btn._label       = label

    function btn:Populate(items) Populate(items) end

    function btn:Reset(text)
        label:SetText(text or placeholder)
        label:SetTextColor(U.RGBA(T.textMuted))
        self.currentValue = nil
    end

    function btn:SetValue(value, displayText)
        label:SetText(displayText or tostring(value))
        label:SetTextColor(U.RGBA(T.textPri))
        self.currentValue = value
    end

    return btn
end

function S.CloseOpenDropdown()
    if openDropdown then
        openDropdown:Hide()
        openDropdown = nil
    end
end

-- ── Header bar ────────────────────────────────────────────────────────────────

function S.MakeHeaderBar(parent, height, title)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT",  parent, 2, -2)
    bar:SetPoint("TOPRIGHT", parent, -2, -2)
    bar:SetHeight(height or 32)
    S.SetBackdrop(bar, T.bgHeader, nil)

    if title then
        local fs = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetPoint("LEFT", 12, 0)
        -- "Athenaeum" in gold, module title in player's class color
        local classHex = "CC66FF" -- fallback purple/pink
        local _, classKey = UnitClass("player")
        if classKey then
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
            if c then
                classHex = string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
            end
        end
        fs:SetText("|cffFFD100Athenaeum|r|cff" .. classHex .. ": " .. title .. "|r")
        bar._title = fs
    end

    local line = bar:CreateTexture(nil, "OVERLAY")
    line:SetHeight(2)
    line:SetPoint("BOTTOMLEFT",  bar)
    line:SetPoint("BOTTOMRIGHT", bar)
    line:SetColorTexture(U.RGBA(T.border))

    return bar
end

-- ── Section label ─────────────────────────────────────────────────────────────

function S.MakeLabel(parent, text, point, x, y, fontSize)
    local fs = parent:CreateFontString(nil, "OVERLAY",
        fontSize == "small" and "GameFontHighlightSmall" or "GameFontNormal")
    fs:SetPoint(point or "TOPLEFT", x or 0, y or 0)
    fs:SetTextColor(U.RGBA(T.accent))
    fs:SetText(text)
    return fs
end

-- ── Close button ──────────────────────────────────────────────────────────────

function S.MakeCloseButton(parent, onClose)
    local btn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    btn:SetPoint("TOPRIGHT", -2, -2)
    btn:SetSize(28, 28)
    btn:SetScript("OnClick", onClose or function() parent:Hide() end)
    -- Keep the close button's frame level just above its parent so it doesn't
    -- bleed through other windows that are on top.
    btn:SetFrameLevel(parent:GetFrameLevel() + 5)
    return btn
end

-- ── Resize grip ───────────────────────────────────────────────────────────────

function S.MakeResizeGrip(frame, minW, minH, dbKey)
    frame:SetResizable(true)
    frame:SetResizeBounds(minW or 600, minH or 400)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp",   function()
        frame:StopMovingOrSizing()
        -- Modules can pass a dbKey table to persist size
        if dbKey then
            dbKey.width  = math.floor(frame:GetWidth())
            dbKey.height = math.floor(frame:GetHeight())
        end
    end)
    return grip
end

-- ── Standard module window builder ────────────────────────────────────────────
-- Creates a movable, resizable, ESC-closable window with header and close button.
-- Returns the frame.

function S.MakeModuleWindow(globalName, title, width, height, dbWindow)
    local f = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
    f:SetSize(width or 890, height or 695)
    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    S.SetBackdrop(f, T.bg, T.border, 2)

    -- Position from saved vars or center
    if dbWindow and dbWindow.point then
        f:SetPoint(dbWindow.point, UIParent, dbWindow.relPoint, dbWindow.xOfs, dbWindow.yOfs)
        if dbWindow.width then f:SetSize(dbWindow.width, dbWindow.height) end
    else
        f:SetPoint("CENTER")
    end

    -- Dragging
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if dbWindow then
            local p, _, rp, x, y = self:GetPoint()
            dbWindow.point    = p
            dbWindow.relPoint = rp
            dbWindow.xOfs     = math.floor(x)
            dbWindow.yOfs     = math.floor(y)
        end
    end)

    -- Header bar
    S.MakeHeaderBar(f, 32, title)

    -- Close button
    S.MakeCloseButton(f)

    -- ESC close
    tinsert(UISpecialFrames, globalName)

    -- Apply scale
    local scale = ATH.DB and ATH.DB.display and ATH.DB.display.scale or 1.0
    f:SetScale(scale)

    -- Play a random holy magic cast sound on show
    local OPEN_SOUNDS = { 2066664, 2066666, 2066667, 2066668, 2066669 }
    f:HookScript("OnShow", function()
        local fileID = OPEN_SOUNDS[math.random(#OPEN_SOUNDS)]
        PlaySoundFile(fileID, "SFX")
    end)

    f:Hide()
    return f
end
