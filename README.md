# NatLust

NatLust is a lightweight World of Warcraft addon for Retail 12.0.1 that plays a custom sound and shows a custom texture when the player gains a lust-style buff.

Supported buffs:

- Bloodlust
- Heroism
- Time Warp
- Primal Rage
- Fury of the Aspects
- Harrier's Cry

## Features

- Watches `UNIT_AURA` for `player` only
- Detects supported buffs through a single aura scan function
- Prevents duplicate start and stop triggers with an internal active state
- Plays a configurable sound file and stops it when the buff ends
- Shows a configurable texture on `UIParent`
- Restarts the animation from the beginning on each new trigger
- Supports unlock and drag to reposition the display frame
- Saves texture path, sound path, size, position, alpha, color, strata, level, and animation toggle
- Does not require Ace3, WeakAuras, or any third-party libraries

## Installation

1. Copy the `NatLust` folder into your WoW addons directory:

   `World of Warcraft/_retail_/Interface/AddOns/`

2. Make sure these files exist:

   - `NatLust.toc`
   - `NatLust.lua`
   - `Media/texture.tga`
   - `Media/lust.mp3`

3. Start the game or reload the UI with `/reload`.

## Default Resources

- Texture: `Interface\\AddOns\\NatLust\\Media\\texture.tga`
- Sound: `Interface\\AddOns\\NatLust\\Media\\lust.mp3`

Replace the placeholder files in `Media/` with your own assets if needed.

## Audio Compatibility

World of Warcraft can be picky about custom audio files. For the most reliable playback, use:

- `MP3`
- `44.1 kHz`
- `128 kbps` or `192 kbps`
- Stereo
- Minimal metadata and no embedded cover art

If a file exists in `Media/` but still does not play, re-encode it to the format above first.

## Commands

- `/natlust test` - Show the texture and play the sound once for testing
- `/natlust stop` - Stop the sound and hide the display
- `/natlust unlock` - Unlock the frame and show the anchor for dragging
- `/natlust lock` - Lock the frame in place
- `/natlust reset` - Reset saved settings to default values

## Saved Variables

NatLust stores its settings in `NatLustDB` with the following keys:

- `texturePath`
- `soundPath`
- `point`
- `relativePoint`
- `x`
- `y`
- `width`
- `height`
- `alpha`
- `colorR`
- `colorG`
- `colorB`
- `colorA`
- `strata`
- `level`
- `enableAnimation`

## Notes

- The addon only reacts when the player has one of the supported buffs.
- `test` mode is manual and can be stopped with `/natlust stop`.
- If the configured media path is invalid, WoW will fail to play or display that resource.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
