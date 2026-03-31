# AthCore - Athenaeum Core

The foundation for the **Athenaeum** modular addon suite.

## Overview

AthCore provides the shared infrastructure for all Athenaeum modules: a single minimap icon, toast notification system, unified dark gray & gold theme, and shared UI utilities. Install AthCore once, then add any combination of Athenaeum modules to customize your experience.

## Features

- **Single Minimap Icon** with adaptive right-click menu showing all installed modules
- **Toast Notifications** with customizable positioning and per-type toggles
- **Unified Theme** - Dark grays, white text, gold accents (fully customizable)
- **Smart Window Management** - Z-axis stacking, ESC-to-close, window scale/opacity controls
- **Addon Communication** - Shared guild-wide message layer for leaderboards, EPGP, and keystone sync

## Available Modules

Install any combination alongside AthCore:

- **AthCore_Guild** - Guild roster, M+ leaderboards, guild keystones, dungeon teleports
- **AthCore_Chat** - Whisper toasts (purple/pink) and officer chat toasts (green/gold)
- **AthCore_BiS** - SimC CSV import, BiS loadout comparison with crafted/tier overrides
- **AthCore_Stats** - Stat priorities and consumables/enchants (with DK runeforge support)
- **AthCore_Notes** - Raid and M+ strategy notes with difficulty-specific breakdowns
- **AthCore_EPGP** - EPGP loot distribution with standings, history, and officer controls

Each module is fully standalone but gains unified theming, minimap presence, and toast integration when AthCore is installed.

## Commands

| Command | Description |
|---------|-------------|
| `/ath` | Toggle last-used module |
| `/ath <module>` | Open a specific module |
| `/ath options` | Open settings |
| `/ath unlock` / `/ath lock` | Reposition toast notifications |
| `/ath hide` | Hide all windows |

## Feedback & Issues

Report bugs or suggest features on the project's issue tracker.
