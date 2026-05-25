## NextTry StatusTracker 1.1.0

### Highlights

- Optional player location display
- Hover tooltip for online and offline players
- Friend and guild notes in the hover tooltip
- Right-click player context menu
- Configurable window anchor point
- Server-aware SavedVariables for EU, NA and PTS separation
- Reworked HUD visibility handling
- ZOS-style localization via `lang/default.lua` and `lang/$(language).lua`

### Fixed and improved

- Fixed visibility issues in menus and HUD scenes
- Fixed position jumps after `/reloadui`
- Fixed blink behavior during sorting, grouping and online-only filtering
- Fixed LibAddonMenu panel callback warning
- Fixed `SetEdgeTexture` errors with unsupported border sizes
- Improved status refresh throttling and localization handling

### Requirement

- LibAddonMenu-2.0 r43 or newer
