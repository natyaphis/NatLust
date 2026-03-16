# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## 1.0.9

- Added a dedicated "Sprite Animation Settings" section label above the row, column, frame, and FPS controls
- Updated the texture and sound example text to use generic `###.tga` and `###.mp3` placeholders
- Updated the default sprite animation settings to 4 rows, 8 columns, 32 frames, and 6 FPS

## 1.0.8

- Added a GitHub Actions release packaging workflow based on the IcicleBars packaging setup
- Kept the `Media/` folder in the repository while excluding media files and `.gitkeep` from packaged release zips
- Excluded `CHANGELOG.md` from packaged release zips

## 1.0.7

- Stopped tracking bundled media files in git while keeping an empty `Media/` folder in the repository
- Simplified the README and clarified that custom texture and audio files should be placed in `NatLust/Media/`
- Updated the project license to `All Rights Reserved`

## 1.0.6

- End fake lust preview automatically when the settings panel is closed
- Reduced sprite preview jitter by disabling the extra pulse animation during multi-frame playback

## 1.0.5

- Added sprite sheet playback controls for columns, rows, frames, and FPS
- Added width and height controls with live preview in the settings panel
- Improved ElvUI skin support for the settings controls, including size controls
- Reworked the settings panel layout to reduce crowding and keep related controls aligned
- Updated the default sprite settings for the bundled `pedro.tga` sheet
- Adjusted sprite sheet texcoord handling for the bundled `pedro.tga` content area

## 1.0.4

- Allowed the sound file field to be left empty to disable audio playback
- Clarified the texture and sound example text for empty-field behavior
- Split the transient settings status line from the persistent Media folder hint
- Fixed the settings status line so it no longer shifts the content below it

## 1.0.3

- Renamed the addon asset folder from `media/` to `Media/`
- Added a `Locales/` folder with English and Chinese translations for the settings UI and chat messages

## 1.0.2

- Changed the settings panel to store media file names and always load them from `Interface\\AddOns\\NatLust\\Media\\`
- Added a `Default` button to restore the default texture and sound file names
- Improved path field prefilling so saved or default file names stay visible in the settings panel
- Added additional bundled audio files in `Media/`
- Documented recommended WoW-compatible audio encoding settings in the README

## 1.0.1

- Switched default media paths to the addon `Media/` folder and updated the settings panel examples
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
