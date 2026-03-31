-- Core/Config.lua
-- Saved variable initialisation and defaults for AthCore.

local ATH = AthCore
ATH.Config = {}

local GLOBAL_DEFAULTS = {
    minimap         = { hide = false, pos = 45 },
    toastAnchor     = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", xOfs = -16, yOfs = 80 },
    notifications   = {
        guildEvent  = true,
        guildMsg    = false,
        officerMsg  = true,
        whisper     = true,
        channelMsg  = false,
    },
    colors = {
        accent      = "FFD100",
        online      = "33F266",
        background  = "141415",
        border      = "C29921",
        header      = "1F1F21",
        text        = "F2F2F2",
    },
    display = {
        scale       = 1.0,
        opacity     = 0.97,
    },
    lastUsedModule = nil,
}

local CHAR_DEFAULTS = {
    -- Minimal; per-char data lives in each module's own saved vars
}

local function ApplyDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                ApplyDefaults(target[k], v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            ApplyDefaults(target[k], v)
        end
    end
end

local function ApplyThemeColors()
    local U = ATH.Utils
    local T = ATH.T
    local colors = ATH.DB.colors
    local display = ATH.DB.display or {}

    -- Accent color (gold) -> T.accent, T.accentDim, T.tabActive
    local ar, ag, ab = U.HexToRGB(colors.accent or "FFD100")
    T.accent    = { r = ar,        g = ag,        b = ab,        a = 1.00 }
    T.accentDim = { r = ar * 0.70, g = ag * 0.70, b = ab * 0.70, a = 1.00 }
    T.tabActive = { r = ar,        g = ag,        b = ab,        a = 0.18 }

    -- Border color (gold border)
    local br, bg_, bb = U.HexToRGB(colors.border or "C29921")
    T.border    = { r = br,        g = bg_,       b = bb,        a = 1.00 }
    T.borderDim = { r = br * 0.67, g = bg_ * 0.67, b = bb * 0.67, a = 0.60 }

    -- Background color (dark gray)
    local alpha = display.opacity or 0.97
    local bgr, bgg, bgb = U.HexToRGB(colors.background or "141415")
    T.bg       = { r = bgr,            g = bgg,            b = bgb,            a = alpha }
    T.bgPanel  = { r = bgr + 0.02,     g = bgg + 0.02,     b = bgb + 0.02,     a = alpha - 0.02 }
    T.bgInput  = { r = bgr - 0.02,     g = bgg - 0.02,     b = bgb - 0.02,     a = 1.00 }
    T.bgRow    = { r = bgr + 0.03,     g = bgg + 0.03,     b = bgb + 0.03,     a = 0.90 }
    T.rowEven  = { r = bgr + 0.02,     g = bgg + 0.02,     b = bgb + 0.02,     a = 0.92 }
    T.rowOdd   = { r = bgr,            g = bgg,            b = bgb,            a = 0.92 }
    T.rowHover = { r = bgr + 0.10,     g = bgg + 0.08,     b = bgb + 0.01,     a = 0.85 }

    -- Header / sidebar color (dark gray header)
    local hr, hg, hb = U.HexToRGB(colors.header or "1F1F21")
    T.bgHeader = { r = hr, g = hg, b = hb, a = 1.00 }

    -- Primary text color (white)
    local tr, tg, tb = U.HexToRGB(colors.text or "F2F2F2")
    T.textPri   = { r = tr,        g = tg,        b = tb,        a = 1.00 }
    T.textMuted = { r = tr * 0.58, g = tg * 0.58, b = tb * 0.58, a = 1.00 }

    -- Online member color
    local or_, og, ob = U.HexToRGB(colors.online or "33F266")
    T.green = { r = or_, g = og, b = ob, a = 1.00 }
end

function ATH.Config.Init()
    if not AthCoreDB then AthCoreDB = {} end
    if not AthCoreCharDB then AthCoreCharDB = {} end
    ApplyDefaults(AthCoreDB, GLOBAL_DEFAULTS)
    ApplyDefaults(AthCoreCharDB, CHAR_DEFAULTS)
    ATH.DB     = AthCoreDB
    ATH.CharDB = AthCoreCharDB
    -- Apply user's saved colors to theme palette
    ApplyThemeColors()
end

-- Re-apply theme colors (called after options change)
function ATH.Config.RefreshTheme()
    ApplyThemeColors()
end
