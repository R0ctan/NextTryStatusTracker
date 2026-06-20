# Changelog

## Version 1.2.0

### Added

- Added player profiles with tracker notes, per-player notifications, roles, editable tags and last-seen information.
- Added tag workflows for assigning, removing, renaming and deleting player tags.
- Added optional role markers using ESO icons for raid lead, tank, healer and damage dealer.
- Added tooltip details for current character, zone, class, alliance, notes, roles, tags and available last-seen data.
- Added player management to the add-on settings and tracker-note actions to the player context menu.

### Changed

- Improved player management and separated per-player tag assignment from global tag management.
- Improved tooltip formatting: 32-pixel class and alliance icons appear after character names, online players omit redundant last-seen information and offline players use a compact last-seen line.
- Improved last-seen handling using available friend and guild roster data.
- Scaled main-list role icons with the configured text size and kept their column aligned.
- Added automatic correction of a missing `@` during manual player entry.
- Updated API compatibility to `101050 101051`.

### Fixed

- Fixed role icon rendering so texture markup is never shown as text.
- Fixed offline last-seen handling when roster data provides logout time.
- Fixed role marker spacing, tooltip icon placement and spacing between last-seen and role/tag details.
- Fixed blink refresh handling and preserved normal row backgrounds during status transitions.

## Version 1.1.0

### Added

- Added optional player location display.
- Added compact hover tooltip for online and offline players.
- Added optional friend note and guild note display in hover tooltip.
- Added right-click context menu on tracked player rows.
- Added player actions in the context menu, including whisper, group invite, travel to player, send mail, edit friend note where available and remove from tracker.
- Added configurable window anchor point with left, center and right anchoring.
- Added server-aware SavedVariables separation for different ESO servers.
- Added shared helper structure under `NextTryShared.WindowVisibility` and `NextTryShared.Chat`.
- Added ZOS-style localization using `lang/default.lua` and `lang/$(language).lua`.

### Changed

- Updated dependency declaration to `LibAddonMenu-2.0>=43`.
- Reworked HUD visibility handling to use one central visibility path.
- Tracker is now shown only in `hud` and `hudui`, except for the addon's own settings preview.
- Replaced old language table handling with `ZO_CreateStringId`, `SafeAddString` and `GetString`.
- Improved status refresh throttling.
- Improved blink handling during sorting, grouping and online-only filtering.
- Improved blink font handling so the blink text is shown without shadow and the normal status font is restored afterwards.
- Updated default player location display to enabled.
- Updated default spacing values.
- Removed configurable padding and border-size settings from the UI. The window uses no internal padding and shows a fixed 2 px border while unlocked.
- Changed online text shadow behavior so online player names no longer use a text shadow.
- Changed manual import to expect `@AccountName` explicitly.
- Improved guild ID handling.
- Improved sorting fallback behavior.

### Fixed

- Fixed LibAddonMenu warning caused by direct panel `OnShow` and `OnHide` handlers.
- Fixed visibility issues where the tracker could appear in menus or hide in the normal HUD.
- Fixed position saving and loading with different window anchor points.
- Fixed reload position jumps when using right or center anchoring.
- Fixed `SetEdgeTexture` errors caused by unsupported edge texture sizes.
- Fixed localization syntax regressions and aligned localization keys across languages.
- Fixed blink behavior when players move between online and offline groups.
- Fixed offline transition behavior with online-only display enabled.
- Fixed status-change blinking being interrupted by concurrent refreshes.
- Fixed tooltip behavior for offline players.
- Fixed note handling so friend notes and guild notes are stored separately.
- Fixed missing or inconsistent tooltip descriptions in settings.

### Technical

- Uses `NextTryShared.WindowVisibility` for centralized HUD window visibility.
- Uses `NextTryShared.Chat` for chat messages, preferring `CHAT_ROUTER:AddSystemMessage`.
- Uses server-aware SavedVariables through `GetWorldName()`.
- Uses shared, namespaced helper modules to avoid global name conflicts with other NextTry addons.
- Avoids control-based menu visibility checks for inventory, vendor, mail and similar UI panels.
- Keeps main-window hiding centralized and avoids scattered `SetHidden()` calls.
- Keeps LibAddonMenu preview handling on `LAM-PanelOpened` and `LAM-PanelClosed` callbacks.

## Version 1.0.2

### Fixed

- Replaced direct LibAddonMenu panel `OnShow` and `OnHide` handlers with official LAM panel callbacks.
- Fixed LibAddonMenu warning about setting handlers directly on a panel.
- Live preview in the addon settings remains available.

## Version 1.0.0

Initial release.

### Features

- Configurable HUD status tracker for selected friends and guild members.
- Friend list import.
- Guild roster import.
- Manual account name entry.
- Player removal from tracker list.
- Online/offline status detection.
- Configurable online and offline styles.
- Configurable background, border, padding and spacing.
- Optional online-only display.
- Sorting options.
- Optional online/offline grouping.
- Blink effect on status changes.
- Sound notification on status changes.
- Test buttons for blink and sound.
- Movable and lockable tracker window.
- Keybind for showing and hiding the tracker.
- Live preview in the addon settings.
- Multi-language support: English, German, French, Spanish, Russian and Simplified Chinese.
