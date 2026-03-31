-- Core/Registry.lua
-- Module registration API. Modules call RegisterModule() during ADDON_LOADED
-- to appear in the minimap menu and participate in Z-axis/ESC management.

local ATH = AthCore
ATH.Registry = {}
local R = ATH.Registry

local modules     = {}   -- ordered array of module defs
local modulesByID = {}   -- id -> module def

-- ── Registration ─────────────────────────────────────────────────────────────
-- def = {
--   id       = "AthGuild",                    -- unique string key
--   label    = "Guild",                        -- display name for menu/tooltip
--   icon     = "Interface\\Icons\\...",         -- icon texture path
--   toggle   = function() end,                 -- toggle the module window
--   show     = function() end,                 -- show the module window
--   hide     = function() end,                 -- hide the module window
--   frame    = frameRef,                       -- the module's main frame (for ESC/Z-axis)
--   slash    = { "guild", "g" },               -- slash sub-commands for /ath
--   order    = 10,                             -- sort order in menu (lower = first)
-- }

function R.RegisterModule(def)
    assert(def.id and def.label and def.toggle, "RegisterModule requires id, label, toggle")
    def.order = def.order or 50

    if modulesByID[def.id] then return end

    table.insert(modules, def)
    modulesByID[def.id] = def

    -- Sort by order
    table.sort(modules, function(a, b) return a.order < b.order end)

    -- Register frame for ESC close and Z-axis management
    if def.frame then
        ATH.ZAxis.Register(def.frame, def.id)
    end

    -- Rebuild minimap menu so it includes the new module
    if ATH.MinimapIcon and ATH.MinimapIcon.RebuildMenu then
        ATH.MinimapIcon.RebuildMenu()
    end
end

-- ── Queries ──────────────────────────────────────────────────────────────────

function R.GetModules()
    return modules
end

function R.GetModule(id)
    return modulesByID[id]
end

function R.IsLoaded(id)
    return modulesByID[id] ~= nil
end

function R.GetModuleCount()
    return #modules
end

-- ── Last-used tracking ───────────────────────────────────────────────────────

function R.SetLastUsed(id)
    if ATH.DB then ATH.DB.lastUsedModule = id end
end

function R.GetLastUsed()
    local id = ATH.DB and ATH.DB.lastUsedModule
    if id and modulesByID[id] then return modulesByID[id] end
    -- Fall back to first registered module
    if #modules > 0 then return modules[1] end
    return nil
end

-- ── Slash command routing ────────────────────────────────────────────────────
-- Returns true if a module handled the slash sub-command.

function R.HandleSlash(sub)
    if not sub or sub == "" then return false end
    sub = sub:lower()
    for _, mod in ipairs(modules) do
        if mod.slash then
            for _, alias in ipairs(mod.slash) do
                if alias == sub then
                    R.SetLastUsed(mod.id)
                    mod.toggle()
                    return true
                end
            end
        end
    end
    return false
end

-- ── Hide all module windows ──────────────────────────────────────────────────

function R.HideAll()
    for _, mod in ipairs(modules) do
        if mod.hide then mod.hide() end
    end
end
