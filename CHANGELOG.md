# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## 1.0.1

- Switched default media paths to the addon `media/` folder and updated the settings panel examples
- Added a settings panel that can be opened with `/nl` or `/natlust`
- Added ElvUI button skin support for the settings actions
- Added chat feedback for texture and sound load failures during preview
- Added a fake lust toggle for testing start and stop behavior without the real buff
- Restored spell ID based lust detection and prioritized `C_UnitAuras` for reliable Retail aura checks
- Replaced the default placeholder media files with `pedro.tga` and `pedro.mp3`
- Fixed saved media paths so the settings panel keeps the current or default paths instead of showing blank fields

## 1.0.0

- Initial release for World of Warcraft Retail 12.0.1
- Added `UNIT_AURA` monitoring for `player`
- Added lust buff detection for Bloodlust, Heroism, Time Warp, Primal Rage, Fury of the Aspects, and Harrier's Cry
- Added duplicate trigger protection using an internal active state
- Added configurable sound playback with saved sound handle stopping
- Added configurable texture display on `UIParent`
- Added restartable animation playback for new buff activations
- Added unlock, drag, lock, reset, stop, and test slash commands
- Added SavedVariables support for media paths, size, position, alpha, color, strata, level, and animation toggle
