-- UI/ZAxis.lua
-- Frame strata/level manager for overlapping module windows.
-- Ensures the most recently clicked/shown window appears on top.

local ATH = AthCore
ATH.ZAxis = {}
local Z = ATH.ZAxis

local BASE_STRATA = "MEDIUM"
local BASE_LEVEL  = 10
local LEVEL_STEP  = 20   -- gap between modules for internal sub-frames

local registeredFrames = {}  -- { { frame, id }, ... }
local focusOrder       = {}  -- stack: most recently focused is last

function Z.Register(frame, id)
    -- Prevent double-register
    for _, entry in ipairs(registeredFrames) do
        if entry.id == id then return end
    end

    table.insert(registeredFrames, { frame = frame, id = id })

    -- Set default strata and level
    frame:SetFrameStrata(BASE_STRATA)
    frame:SetFrameLevel(BASE_LEVEL + #registeredFrames * LEVEL_STEP)

    -- Hook OnMouseDown to bring-to-front
    frame:HookScript("OnMouseDown", function()
        Z.BringToFront(id)
    end)

    -- Hook OnShow to bring-to-front
    frame:HookScript("OnShow", function()
        Z.BringToFront(id)
    end)
end

function Z.BringToFront(id)
    -- Remove from focusOrder, add to end (top)
    for i, fid in ipairs(focusOrder) do
        if fid == id then
            table.remove(focusOrder, i)
            break
        end
    end
    table.insert(focusOrder, id)

    -- Reassign frame levels based on focus order
    for i, fid in ipairs(focusOrder) do
        for _, entry in ipairs(registeredFrames) do
            if entry.id == fid then
                entry.frame:SetFrameLevel(BASE_LEVEL + i * LEVEL_STEP)
                break
            end
        end
    end
end

-- Get the topmost visible frame
function Z.GetTopVisibleFrame()
    for i = #focusOrder, 1, -1 do
        local fid = focusOrder[i]
        for _, entry in ipairs(registeredFrames) do
            if entry.id == fid and entry.frame:IsShown() then
                return entry.frame, fid
            end
        end
    end
    return nil, nil
end
