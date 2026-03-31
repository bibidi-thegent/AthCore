# AthCore - Athenaeum Core

AthCore is the foundation addon for the Athenaeum modular addon suite for World of Warcraft (Midnight). It provides shared infrastructure that all Athenaeum modules use.

## What AthCore Does

- **Single Minimap Icon** - One unified minimap button for all Athenaeum modules. Left-click toggles your last-used module. Right-click opens a quick-access menu showing all detected modules.
- **Toast Notifications** - A shared toast notification system with customizable positioning. Whisper toasts appear in purple/pink, officer chat toasts in green/gold, and guild event reminders in the default gold accent.
- **Unified Theme** - Dark gray backgrounds with white text and gold accents. All module windows share the same look. Colors are fully customizable via the options panel.
- **Z-Axis Management** - When multiple module windows are open, clicking a window brings it to the front. ESC closes the topmost window.
- **Shared UI Utilities** - Common UI components (scroll frames, dropdowns, headers, backdrops) that modules use to maintain visual consistency.
- **Addon Communication** - A shared message layer for guild-wide data sync (leaderboards, EPGP standings, keystones, etc.).
- **Options Panel** - Blizzard Settings integration for window scale, opacity, color customization, toast toggles, and module detection.

## Modular Addons

AthCore is designed to work with these standalone modules (install any combination):

| Module | Description |
|--------|-------------|
| **AthCore_Guild** | Guild roster, M+ leaderboards, keystone viewer, dungeon teleports |
| **AthCore_Chat** | Whisper and officer chat toast notifications |
| **AthCore_BiS** | SimC CSV import, BiS loadout management with slot overrides |
| **AthCore_Stats** | Stat priorities and consumables/enchants per spec |
| **AthCore_Notes** | Raid boss and M+ dungeon strategy notes with difficulty breakdowns |
| **AthCore_EPGP** | Effort Points / Gear Points loot distribution system |

Each module works standalone but gains unified theming, minimap integration, and toast routing when AthCore is installed.

## Slash Commands

- `/ath` - Toggle last-used module
- `/ath <module>` - Open a specific module (guild, stats, bis, notes, epgp)
- `/ath options` - Open the settings panel
- `/ath unlock` - Unlock toast position for repositioning
- `/ath lock` - Lock toast position
- `/ath hide` - Hide all module windows
- `/ath help` - Show command list

## Installation

1. Download and extract to `World of Warcraft/_retail_/Interface/AddOns/AthCore/`
2. Install any desired module addons (AthCore_Guild, AthCore_Stats, etc.) alongside it
3. Reload your UI or restart WoW
