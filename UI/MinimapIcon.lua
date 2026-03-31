-- UI/MinimapIcon.lua
-- Single LibDBIcon minimap button with dynamic right-click menu
-- built from Registry-registered modules.

local ATH = AthCore
ATH.MinimapIcon = {}
local MI = ATH.MinimapIcon

local LDB     = LibStub and LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0",     true)

local dataObj   = nil
local menuFrame = nil

-- ── Dynamic right-click menu ─────────────────────────────────────────────────

local function ShowMenu(anchor)
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "AthCoreMinimapMenu", UIParent, "UIDropDownMenuTemplate")
    end

    UIDropDownMenu_Initialize(menuFrame, function(_, level)
        if level ~= 1 then return end

        -- Header
        local hdr = UIDropDownMenu_CreateInfo()
        hdr.text         = "|cffFFD100Athenaeum|r"
        hdr.isTitle      = true
        hdr.notCheckable = true
        UIDropDownMenu_AddButton(hdr)

        -- Dynamically list all registered modules
        local mods = ATH.Registry.GetModules()
        for _, mod in ipairs(mods) do
            local entry = UIDropDownMenu_CreateInfo()
            entry.text         = mod.label
            entry.icon         = mod.icon
            entry.notCheckable = true
            entry.func = function()
                ATH.Registry.SetLastUsed(mod.id)
                mod.toggle()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(entry)
        end

        -- Separator
        local sep = UIDropDownMenu_CreateInfo()
        sep.text = ""; sep.disabled = true; sep.notCheckable = true
        UIDropDownMenu_AddButton(sep)

        -- Toast lock/unlock
        local toastEntry = UIDropDownMenu_CreateInfo()
        local isUnlocked = _G["AthCoreToastAnchor"] and _G["AthCoreToastAnchor"]:IsShown()
        toastEntry.text         = isUnlocked and "Lock Toasts" or "Unlock Toasts"
        toastEntry.notCheckable = true
        toastEntry.func = function()
            if isUnlocked then
                ATH.Toast.LockAnchor()
            else
                ATH.Toast.UnlockAnchor()
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(toastEntry)

        -- Options
        local optEntry = UIDropDownMenu_CreateInfo()
        optEntry.text         = "Options"
        optEntry.notCheckable = true
        optEntry.func = function()
            ATH.Options.Open()
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(optEntry)
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, -5)
end

-- ── Left-click: toggle last-used module ──────────────────────────────────────

local function OnLeftClick()
    local last = ATH.Registry.GetLastUsed()
    if last then
        ATH.Registry.SetLastUsed(last.id)
        last.toggle()
    end
    -- If no modules registered, left-click does nothing (right-click shows options)
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function MI.Init()
    if not LDB or not LDBIcon then
        MI._BuildFallback()
        return
    end

    dataObj = LDB:NewDataObject("AthCore", {
        type  = "data source",
        label = "Athenaeum",
        text  = "Athenaeum",
        icon  = "Interface\\AddOns\\AthCore\\Textures\\AthIcon",
        OnClick = function(self, btn)
            if btn == "RightButton" then
                ShowMenu(self)
            else
                OnLeftClick()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffFFD100Athenaeum|r")
            tt:AddLine(" ")
            tt:AddLine("|cffFFD700Left-click|r to toggle last module")
            tt:AddLine("|cffFFD700Right-click|r for quick access")
            local count = ATH.Registry.GetModuleCount()
            if count > 0 then
                tt:AddLine(" ")
                tt:AddLine(count .. " module(s) loaded", 0.55, 0.55, 0.55)
            end
        end,
    })

    if not ATH.DB.minimap then ATH.DB.minimap = { hide = false } end
    LDBIcon:Register("AthCore", dataObj, ATH.DB.minimap)
end

function MI.SetShown(shown)
    if LDBIcon then
        if shown then
            LDBIcon:Show("AthCore")
        else
            LDBIcon:Hide("AthCore")
        end
    end
end

-- Called by Registry when a new module registers (menu is built dynamically on open,
-- so no actual rebuild needed -- this is a hook point for future use)
function MI.RebuildMenu()
    -- Menu is generated dynamically each time it opens; nothing to do here
end

-- ── Fallback minimap button (no LibDBIcon) ────────────────────────────────────

function MI._BuildFallback()
    local btn = CreateFrame("Button", "AthCoreMinimapBtn", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameLevel(8)
    btn:SetNormalTexture("Interface\\AddOns\\AthCore\\Textures\\AthIcon")
    btn:GetNormalTexture():SetSize(20, 20)
    btn:GetNormalTexture():SetPoint("CENTER")

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(54, 54)
    overlay:SetPoint("TOPLEFT", btn, 0, 0)

    local db = ATH.DB.minimap or {}
    btn:SetShown(not db.hide)

    local function UpdatePos()
        local pos   = db.pos or 45
        local angle = math.rad(pos)
        btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle)*80, math.sin(angle)*80)
    end
    UpdatePos()

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local cx, cy = Minimap:GetCenter()
            local mx, my = GetCursorPosition()
            local scale  = Minimap:GetEffectiveScale()
            mx, my = mx/scale, my/scale
            local angle = math.deg(math.atan2(my-cy, mx-cx))
            db.pos = angle
            UpdatePos()
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)
    btn:SetScript("OnClick", function(self, mbtn)
        if mbtn == "RightButton" then
            ShowMenu(self)
        else
            OnLeftClick()
        end
    end)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    MI._btn = btn
    function MI.SetShown(shown) btn:SetShown(shown) end
end
