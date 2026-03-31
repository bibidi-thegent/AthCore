-- AthCore.lua
-- Entry point for AthCore: event frame, slash commands, initialization.

local ATH = AthCore

-- ── Slash commands ────────────────────────────────────────────────────────────

SLASH_ATHCORE1 = "/ath"
SLASH_ATHCORE2 = "/athcore"

SlashCmdList["ATHCORE"] = function(input)
    local sub = strtrim(input or ""):lower()

    if sub == "" then
        -- Toggle last-used module or show menu hint
        local last = ATH.Registry.GetLastUsed()
        if last then
            ATH.Registry.SetLastUsed(last.id)
            last.toggle()
        else
            print("|cffFFD100[AthCore]|r No modules detected. Right-click the minimap icon for options.")
        end
        return
    end

    if sub == "unlock" then
        ATH.Toast.UnlockAnchor()
        return
    end

    if sub == "lock" then
        ATH.Toast.LockAnchor()
        return
    end

    if sub == "options" or sub == "config" or sub == "settings" then
        ATH.Options.Open()
        return
    end

    if sub == "hide" then
        ATH.Registry.HideAll()
        return
    end

    if sub == "help" then
        print("|cffFFD100[AthCore]|r Commands:")
        print("  |cffFFD700/ath|r              - Toggle last module")
        print("  |cffFFD700/ath <module>|r      - Open a module (guild, stats, bis, notes, epgp, chat)")
        print("  |cffFFD700/ath options|r       - Open settings")
        print("  |cffFFD700/ath unlock|r        - Unlock toast position")
        print("  |cffFFD700/ath lock|r          - Lock toast position")
        print("  |cffFFD700/ath hide|r          - Hide all windows")
        return
    end

    -- Try module slash routing
    if ATH.Registry.HandleSlash(sub) then return end

    -- Unknown command
    print("|cffFFD100[AthCore]|r Unknown command: " .. sub .. ". Type |cffFFD700/ath help|r for a list.")
end

-- ── Event frame ───────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame", "AthCoreEventFrame")
ATH._eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "AthCore" then
            ATH.Config.Init()
            ATH.Comms.Init()
            ATH.MinimapIcon.Init()
            ATH.Toast.Init()
            ATH.Options.Init()
            print("|cffFFD100[AthCore]|r v" .. ATH.VERSION .. " loaded. |cffFFD700/ath|r to open.")
        end

    elseif event == "PLAYER_LOGIN" then
        ATH.Utils.CachePlayerInfo()
        ATH.Comms.BroadcastVersion()
        if ATH.DB.minimap then
            ATH.MinimapIcon.SetShown(not ATH.DB.minimap.hide)
        end

    elseif event == "CHAT_MSG_ADDON" then
        ATH.Comms.HandleAddonMessage(...)
    end
end)
