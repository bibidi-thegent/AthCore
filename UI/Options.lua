-- UI/Options.lua
-- Registers AthCore in the Blizzard Settings / AddOns panel.
-- Sections: Display, Colors, Toasts, Detected Modules, Reset.
-- All content is inside a scroll frame to prevent overflow.

local ATH = AthCore
ATH.Options = {}
local OPT = ATH.Options

local U = ATH.Utils

-- ── Color swatch helper ───────────────────────────────────────────────────────

local function MakeColorRow(parent, anchor, anchorOffY, hexKey, label, defaultHex)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(300, 26)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchorOffY)

    local lbl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
    lbl:SetWidth(140)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(label)

    local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
                          edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    local hexVal = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hexVal:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    hexVal:SetTextColor(0.55, 0.55, 0.55)

    local function Refresh()
        local hex = ATH.DB.colors[hexKey] or defaultHex or "FFD100"
        local r, g, b = U.HexToRGB(hex)
        swatch:SetBackdropColor(r, g, b, 1)
        swatch:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        hexVal:SetText("#" .. hex:upper())
    end
    Refresh()

    swatch:SetScript("OnClick", function()
        local hex = ATH.DB.colors[hexKey] or defaultHex or "FFD100"
        local r, g, b = U.HexToRGB(hex)
        local prevHex = ATH.DB.colors[hexKey]

        local function OnApply()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            ATH.DB.colors[hexKey] = U.RGBToHex(nr, ng, nb)
            Refresh()
        end
        local function OnCancel()
            ATH.DB.colors[hexKey] = prevHex
            Refresh()
        end

        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                swatchFunc = OnApply, cancelFunc = OnCancel, hasOpacity = false,
            })
        else
            ColorPickerFrame.func       = OnApply
            ColorPickerFrame.cancelFunc = OnCancel
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame:SetColorRGB(r, g, b)
            ShowUIPanel(ColorPickerFrame)
        end
    end)
    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to change " .. label)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

-- ── Slider helper ───────────────────────────────────────────────────────────

local function MakeSliderRow(parent, anchor, anchorOffY, label, minVal, maxVal, step, getter, setter, formatter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(340, 36)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchorOffY)

    local lbl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
    lbl:SetWidth(140)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(label)

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    slider:SetSize(140, 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(getter())
    slider.Low:SetText("")
    slider.High:SetText("")

    local valText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valText:SetWidth(50)
    valText:SetJustifyH("LEFT")
    valText:SetTextColor(0.55, 0.55, 0.55)
    valText:SetText(formatter(getter()))

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        setter(val)
        valText:SetText(formatter(val))
    end)

    return row
end

-- ── Checkbox helper ─────────────────────────────────────────────────────────

local function MakeCheckRow(parent, anchor, anchorOffY, label, getter, setter)
    local chk = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    chk:SetSize(24, 24)
    chk:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchorOffY)
    chk:SetChecked(getter())
    chk:SetScript("OnClick", function(self) setter(self:GetChecked()) end)

    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", chk, "RIGHT", 2, 0)
    lbl:SetText(label)

    return chk
end

-- ── Section header helper ───────────────────────────────────────────────────

local function MakeSectionHeader(parent, anchor, anchorOffY, text)
    local hdr = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchorOffY)
    hdr:SetText(text)
    hdr:SetTextColor(1.00, 0.82, 0.00)
    return hdr
end

-- ── Build ─────────────────────────────────────────────────────────────────────

local function BuildPanel()
    local panel = CreateFrame("Frame")

    -- Scroll frame wrapping all content
    local sf = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", panel, 0, -4)
    sf:SetPoint("BOTTOMRIGHT", panel, -26, 4)

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(440)
    content:SetHeight(1) -- will be set at the end
    sf:SetScrollChild(content)

    -- Enable mousewheel scrolling on the panel itself
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        local cur = sf:GetVerticalScroll()
        local max = sf:GetVerticalScrollRange()
        sf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 40)))
    end)

    -- ── TITLE ────────────────────────────────────────────────────────────────

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -8)
    title:SetText("|cffFFD100Athenaeum|r  v" .. ATH.VERSION)

    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    line:SetSize(400, 1)
    line:SetColorTexture(0.76, 0.60, 0.13, 0.6)

    local reloadNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    reloadNote:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -4)
    reloadNote:SetText("Most color/display changes take effect after /reload")
    reloadNote:SetTextColor(0.55, 0.55, 0.55)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- DISPLAY
    -- ═══════════════════════════════════════════════════════════════════════════

    local dispHdr = MakeSectionHeader(content, reloadNote, -14, "Display")

    local scaleSlider = MakeSliderRow(content, dispHdr, -6, "Window Scale",
        0.50, 1.50, 0.05,
        function() return ATH.DB.display and ATH.DB.display.scale or 1.0 end,
        function(v) if ATH.DB.display then ATH.DB.display.scale = v end end,
        function(v) return math.floor(v * 100 + 0.5) .. "%" end
    )

    local opacitySlider = MakeSliderRow(content, scaleSlider, -4, "Background Opacity",
        0.30, 1.00, 0.05,
        function() return ATH.DB.display and ATH.DB.display.opacity or 0.97 end,
        function(v) if ATH.DB.display then ATH.DB.display.opacity = v end end,
        function(v) return math.floor(v * 100 + 0.5) .. "%" end
    )

    -- Minimap icon
    local mmChk = MakeCheckRow(content, opacitySlider, -8, "Show minimap icon",
        function() return not (ATH.DB.minimap and ATH.DB.minimap.hide) end,
        function(v)
            if ATH.DB.minimap then ATH.DB.minimap.hide = not v end
            ATH.MinimapIcon.SetShown(v)
        end
    )

    -- ═══════════════════════════════════════════════════════════════════════════
    -- COLORS
    -- ═══════════════════════════════════════════════════════════════════════════

    local colHdr = MakeSectionHeader(content, mmChk, -18, "Colors")

    local rowAccent  = MakeColorRow(content, colHdr,     -8,  "accent",     "Accent (Gold)",      "FFD100")
    local rowBorder  = MakeColorRow(content, rowAccent,  -4,  "border",     "Border",             "C29921")
    local rowBg      = MakeColorRow(content, rowBorder,  -4,  "background", "Background",         "141415")
    local rowHeader  = MakeColorRow(content, rowBg,      -4,  "header",     "Header / Sidebar",   "1F1F21")
    local rowText    = MakeColorRow(content, rowHeader,  -4,  "text",       "Text",               "F2F2F2")
    local rowOnline  = MakeColorRow(content, rowText,    -4,  "online",     "Online Members",     "33F266")

    -- ═══════════════════════════════════════════════════════════════════════════
    -- TOASTS
    -- ═══════════════════════════════════════════════════════════════════════════

    local toastHdr = MakeSectionHeader(content, rowOnline, -18, "Toast Notifications")

    local whisperChk = MakeCheckRow(content, toastHdr, -6, "Enable whisper toasts",
        function() return ATH.DB.notifications and ATH.DB.notifications.whisper end,
        function(v) if ATH.DB.notifications then ATH.DB.notifications.whisper = v end end
    )

    local officerChk = MakeCheckRow(content, whisperChk, -4, "Enable officer chat toasts",
        function() return ATH.DB.notifications and ATH.DB.notifications.officerMsg end,
        function(v) if ATH.DB.notifications then ATH.DB.notifications.officerMsg = v end end
    )

    local guildEventChk = MakeCheckRow(content, officerChk, -4, "Enable guild event reminders",
        function() return ATH.DB.notifications and ATH.DB.notifications.guildEvent end,
        function(v) if ATH.DB.notifications then ATH.DB.notifications.guildEvent = v end end
    )

    local toastNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    toastNote:SetPoint("TOPLEFT", guildEventChk, "BOTTOMLEFT", 26, -2)
    toastNote:SetText("Use |cffFFD700/ath unlock|r and |cffFFD700/ath lock|r to reposition toasts.")
    toastNote:SetTextColor(0.55, 0.55, 0.55)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- DETECTED MODULES
    -- ═══════════════════════════════════════════════════════════════════════════

    local modHdr = MakeSectionHeader(content, toastNote, -18, "Detected Modules")

    local modList = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    modList:SetPoint("TOPLEFT", modHdr, "BOTTOMLEFT", 0, -6)
    modList:SetJustifyH("LEFT")
    modList:SetTextColor(0.8, 0.8, 0.8)

    local function RefreshModuleList()
        local mods = ATH.Registry.GetModules()
        if #mods == 0 then
            modList:SetText("No modules detected. Install AthGuild, AthChat, AthBiS, etc.")
        else
            local lines = {}
            for _, mod in ipairs(mods) do
                table.insert(lines, "|cff33F266*|r " .. mod.label)
            end
            modList:SetText(table.concat(lines, "\n"))
        end
    end
    RefreshModuleList()

    panel:SetScript("OnShow", RefreshModuleList)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RESET
    -- ═══════════════════════════════════════════════════════════════════════════

    local resetHdr = MakeSectionHeader(content, modList, -18, "Reset")

    local resetColBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetColBtn:SetSize(130, 24)
    resetColBtn:SetPoint("TOPLEFT", resetHdr, "BOTTOMLEFT", 0, -6)
    resetColBtn:SetText("Reset Colors")
    resetColBtn:SetScript("OnClick", function()
        ATH.DB.colors.accent     = "FFD100"
        ATH.DB.colors.online     = "33F266"
        ATH.DB.colors.background = "141415"
        ATH.DB.colors.border     = "C29921"
        ATH.DB.colors.header     = "1F1F21"
        ATH.DB.colors.text       = "F2F2F2"
        ReloadUI()
    end)

    local resetDispBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetDispBtn:SetSize(130, 24)
    resetDispBtn:SetPoint("LEFT", resetColBtn, "RIGHT", 8, 0)
    resetDispBtn:SetText("Reset Display")
    resetDispBtn:SetScript("OnClick", function()
        if ATH.DB.display then
            ATH.DB.display.scale   = 1.0
            ATH.DB.display.opacity = 0.97
        end
        ReloadUI()
    end)

    -- Set scroll child height to fit all content
    -- Calculate total height from the last element
    local bottomPad = 20
    content:SetHeight(800 + bottomPad)

    -- Dynamically resize on show
    panel:HookScript("OnShow", function()
        -- Measure from top of content to bottom of last element
        local _, _, _, _, lastY = resetColBtn:GetPoint()
        -- Approximate total height
        content:SetHeight(math.abs(lastY or 0) + 50)
    end)

    return panel
end

-- ── Init / Open ───────────────────────────────────────────────────────────────

function OPT.Init()
    local panel = BuildPanel()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(panel, "AthCore")
        Settings.RegisterAddOnCategory(cat)
        OPT._category = cat
    else
        panel.name = "AthCore"
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
        OPT._panel = panel
    end
end

function OPT.Open()
    if OPT._category and Settings then
        Settings.OpenToCategory(OPT._category.ID)
    elseif OPT._panel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(OPT._panel)
    end
end
