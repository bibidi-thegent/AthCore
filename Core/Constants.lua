-- Core/Constants.lua
-- All shared constants, enumerations, and the theme palette for AthCore.

AthCore = AthCore or {}
local ATH = AthCore

ATH.VERSION      = "1.1.1"
ATH.ADDON_NAME   = "AthCore"
ATH.ADDON_PREFIX = "Athenaeum" -- C_ChatInfo.SendAddonMessage prefix (max 16 chars)

-- ── Toast types ───────────────────────────────────────────────────────────────
ATH.TOAST = {
    GUILD_EVENT  = 1,  -- persistent until dismissed
    GUILD_MSG    = 2,  -- auto-fade
    OFFICER_MSG  = 3,  -- auto-fade (green/gold accent)
    CHANNEL_MSG  = 4,  -- auto-fade
    WHISPER      = 5,  -- auto-fade (purple/pink accent)
}

-- ── Addon comm message types ──────────────────────────────────────────────────
ATH.COMM = {
    VERSION      = "VER",
    LEADERBOARD  = "LB",
    COUNCIL_CHAT = "CC",
    LOOT_DIST    = "LD",
    PVP_LB       = "PL",
    EPGP_SYNC    = "EP",
    EPGP_AWARD   = "EA",
    EPGP_DECAY   = "ED",
    KEYSTONE     = "KS",  -- guild keystone sync
}

-- ── EPGP slot multipliers & formula constants ───────────────────────────────
ATH.EPGP = {
    BASE_GP         = 500,
    STANDARD_ILVL   = 639,
    ILVL_DENOMINATOR= 13,
    DEFAULT_DECAY   = 15,
    MIN_EP          = 0,
    SLOT_MULTIPLIER = {
        INVTYPE_HEAD           = 1.00,
        INVTYPE_CHEST          = 1.00,
        INVTYPE_ROBE           = 1.00,
        INVTYPE_LEGS           = 1.00,
        INVTYPE_SHOULDER       = 0.75,
        INVTYPE_HAND           = 0.75,
        INVTYPE_WAIST          = 0.75,
        INVTYPE_FEET           = 0.75,
        INVTYPE_CLOAK          = 0.56,
        INVTYPE_WRIST          = 0.56,
        INVTYPE_NECK           = 0.56,
        INVTYPE_FINGER         = 0.56,
        INVTYPE_TRINKET        = 1.25,
        INVTYPE_2HWEAPON       = 2.00,
        INVTYPE_WEAPONMAINHAND = 1.50,
        INVTYPE_WEAPON         = 1.50,
        INVTYPE_WEAPONOFFHAND  = 1.00,
        INVTYPE_HOLDABLE       = 1.00,
        INVTYPE_SHIELD         = 1.00,
        INVTYPE_RANGED         = 1.50,
        INVTYPE_RANGEDRIGHT    = 1.50,
    },
}

-- ── BiS slot map ──────────────────────────────────────────────────────────────
ATH.SLOT_MAP = {
    { id = "HeadSlot",          label = "Head",      emptyIcon = 136511 },
    { id = "NeckSlot",          label = "Neck",      emptyIcon = 136519 },
    { id = "ShoulderSlot",      label = "Shoulder",  emptyIcon = 136526 },
    { id = "BackSlot",          label = "Back",      emptyIcon = 136512 },
    { id = "ChestSlot",         label = "Chest",     emptyIcon = 136513 },
    { id = "WristSlot",         label = "Wrist",     emptyIcon = 136530 },
    { id = "MainHandSlot",      label = "Main Hand", emptyIcon = 136518 },
    { id = "SecondaryHandSlot", label = "Off Hand",  emptyIcon = 136524 },
    { id = "HandsSlot",         label = "Hands",     emptyIcon = 136515 },
    { id = "WaistSlot",         label = "Waist",     emptyIcon = 136529 },
    { id = "LegsSlot",          label = "Legs",      emptyIcon = 136517 },
    { id = "FeetSlot",          label = "Feet",      emptyIcon = 136514 },
    { id = "Finger0Slot",       label = "Ring 1",    emptyIcon = 136516 },
    { id = "Finger1Slot",       label = "Ring 2",    emptyIcon = 136516 },
    { id = "Trinket0Slot",      label = "Trinket 1", emptyIcon = 136528 },
    { id = "Trinket1Slot",      label = "Trinket 2", emptyIcon = 136528 },
}

-- ── Spec ID map ───────────────────────────────────────────────────────────────
ATH.SPEC_IDS = {
    DEATHKNIGHT = { Blood = 250, Frost = 251, Unholy = 252 },
    DEMONHUNTER = { Havoc = 577, Vengeance = 581, Devourer = 577 },
    DRUID       = { Balance = 102, Feral = 103, Guardian = 104, Restoration = 105 },
    EVOKER      = { Devastation = 1467, Preservation = 1468, Augmentation = 1473 },
    HUNTER      = { BeastMastery = 253, Marksmanship = 254, Survival = 255 },
    MAGE        = { Arcane = 62, Fire = 63, Frost = 64 },
    MONK        = { Brewmaster = 268, Windwalker = 269, Mistweaver = 270 },
    PALADIN     = { Holy = 65, Protection = 66, Retribution = 70 },
    PRIEST      = { Discipline = 256, Holy = 257, Shadow = 258 },
    ROGUE       = { Assassination = 259, Outlaw = 260, Subtlety = 261 },
    SHAMAN      = { Elemental = 262, Enhancement = 263, Restoration = 264 },
    WARLOCK     = { Affliction = 265, Demonology = 266, Destruction = 267 },
    WARRIOR     = { Arms = 71, Fury = 72, Protection = 73 },
}

ATH.CLASS_IDS = {
    WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5, DEATHKNIGHT=6,
    SHAMAN=7, MAGE=8, WARLOCK=9, MONK=10, DRUID=11, DEMONHUNTER=12, EVOKER=13,
}

-- ── Theme / colour palette (Dark Gray + Gold) ────────────────────────────────
ATH.T = {
    -- Backgrounds (dark grays)
    bg         = { r=0.08, g=0.08, b=0.09, a=0.97 },
    bgPanel    = { r=0.10, g=0.10, b=0.11, a=0.95 },
    bgHeader   = { r=0.12, g=0.12, b=0.13, a=1.00 },
    bgInput    = { r=0.06, g=0.06, b=0.07, a=1.00 },
    bgRow      = { r=0.11, g=0.11, b=0.12, a=0.90 },

    -- Borders and accents (gold)
    border     = { r=0.76, g=0.60, b=0.13, a=1.00 },
    borderDim  = { r=0.50, g=0.40, b=0.10, a=0.60 },
    accent     = { r=1.00, g=0.82, b=0.00, a=1.00 },
    accentDim  = { r=0.70, g=0.57, b=0.00, a=1.00 },

    -- Utility colours
    gold       = { r=1.00, g=0.82, b=0.00, a=1.00 },
    green      = { r=0.20, g=0.95, b=0.40, a=1.00 },
    red        = { r=1.00, g=0.30, b=0.30, a=1.00 },
    teal       = { r=0.20, g=0.85, b=0.85, a=1.00 },

    -- Text
    textPri    = { r=0.95, g=0.95, b=0.95, a=1.00 },
    textMuted  = { r=0.55, g=0.55, b=0.55, a=1.00 },

    -- Row alternation
    rowEven    = { r=0.10, g=0.10, b=0.11, a=0.92 },
    rowOdd     = { r=0.08, g=0.08, b=0.09, a=0.92 },
    rowHover   = { r=0.18, g=0.16, b=0.10, a=0.85 },
    rowBiS     = { r=0.06, g=0.16, b=0.08, a=0.92 },

    -- Tab states
    tabActive  = { r=1.00, g=0.82, b=0.00, a=0.18 },
    tabInact   = { r=0.00, g=0.00, b=0.00, a=0.00 },

    -- Toast-specific accent overrides
    whisperAccent  = { r=0.80, g=0.30, b=0.70 },
    officerAccent  = { r=0.40, g=0.80, b=0.30 },
}

-- Medal colours for leaderboard top-3
ATH.MEDAL = { "FFD700", "C0C0C0", "CD7F32" }
