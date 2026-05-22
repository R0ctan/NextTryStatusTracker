# Changelog

## Version 1.0.1

Bugfix release.

### Fixed

- Fixed an issue where the tracker window could reappear while inventory, map or other ESO menus were open
- Improved visibility handling for the "Enable Addon", "Show Tracker Window" and "Show Preview in Settings" options
- Added additional scene state checks to keep the tracker hidden while menus are active

### Changed

- Updated add-on version to 1.0.1
- Updated AddOnVersion to 10001

## Version 1.0.0

Initial release.

### Features

- Configurable HUD status tracker for selected friends and guild members
- Friend list import
- Guild roster import
- Manual account name entry
- Player removal from tracker list
- Online/offline status detection
- Configurable online and offline styles
- Configurable background, border, padding and spacing
- Optional online only display
- Sorting options
- Optional online/offline grouping
- Blink effect on status changes
- Sound notification on status changes
- Test buttons for blink and sound
- Movable and lockable tracker window
- Keybind for showing and hiding the tracker
- Live preview in the addon settings
- Multi language support: English, German, French, Spanish, Russian and Simplified Chinese

### Technical

- Modular code structure
- Separate files for core logic, UI, animation and settings
- Settings via LibAddonMenu-2.0
- SavedVariables support
- Debounced status refresh
- Optimized guild roster checks
- Font string caching