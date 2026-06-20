# NextTry StatusTracker

NextTry StatusTracker is a configurable status tracker addon for The Elder Scrolls Online.

It shows a small movable HUD window with selected friends and guild members and updates their online/offline status. It can also show the current zone, notes, roles, tags and a compact hover tooltip.

## Features

- Track selected friends and guild members
- Import players from your friend list
- Import players from your guild rosters
- Optional player location display
- Hover tooltip for online and offline players
- Friend and guild notes in the hover tooltip
- Private tracker notes, textured role icons and editable player tags
- Per-player status-change notifications
- Last-seen time with last known character and zone
- Right-click player context menu
- Optional online-only display
- Alphabetical, online-first or offline-first sorting
- Optional online/offline grouping
- Optional blink effect on status changes
- Optional sound on status changes
- Configurable online and offline appearance
- Configurable font size, font style, colors, background, border and spacing
- Movable and lockable HUD window
- Keybind to show or hide the tracker window
- Configurable window anchor point
- Live preview in the addon settings
- Manual account name entry as fallback
- Server-aware SavedVariables for EU, NA and PTS separation
- Multi-language support: English, German, French, Spanish, Russian and Simplified Chinese

## Supported languages

- English
- German
- French
- Spanish
- Russian
- Simplified Chinese

## Requirements

This addon requires:

- LibAddonMenu-2.0 r43 or newer

Please install and enable LibAddonMenu-2.0 before using this addon.

## Installation

Download the addon ZIP file and extract it into your ESO AddOns folder:

```text
Documents\Elder Scrolls Online\live\AddOns\
```

The final folder should look like this:

```text
Documents\Elder Scrolls Online\live\AddOns\NextTryStatusTracker\
```

## Usage

Open the ESO settings menu and go to:

```text
Settings → Addons → NextTry StatusTracker
```

There you can configure the tracker window, import and manage players, change colors, test blinking, test sounds and adjust sorting or display options.

## Player import

Players can be added from your friend list, from your guild rosters or manually by entering an account name.

Manual entry accepts an account name with or without the leading `@`; a missing `@` is added automatically. The online/offline status can only be detected reliably if the player can be found in your friend list or in one of your guild rosters.

## Hover tooltip

The hover tooltip can show:

```text
@AccountName
Char: current_character_name [class icon] [alliance icon]
Zone: current zone

Note:
note text

Tracker note:
private tracker note

Last seen: 2 hours ago in last known zone on character last_character_name [class icon] [alliance icon]
Roles: [tank icon] [healer icon] [DD icon]
Tags: Dungeon, Raid
```

Friend notes are preferred. If no friend note is available, a guild note can be shown instead. Online players show the current character and zone without a redundant "Last seen: just now" block. Offline players use the compact last-seen line with the last known character, zone and available class or alliance icons.

The tooltip omits empty sections. Class and alliance use 32-pixel icons directly after the character name when available; readable text remains as a fallback when an icon cannot be shown. Raid lead uses the ESO group-leader icon, while `[RL]` is only a technical fallback.

## Right-click context menu

Right-clicking a tracked player opens a small context menu with useful player actions such as whisper, group invite, travel to player, send mail, edit friend notes where available, edit the private tracker note, toggle notifications and remove the player.

## Notes

The tracker window is normally shown only in the ESO HUD and HUD UI scenes. It hides in menus such as map, inventory, guild, group, mail and other non-HUD scenes. The only intended exception is the live preview in the addon's own settings panel.

## Author

Author: R0ctan  
AI-assisted development: Auralith / ChatGPT

## License

This project is licensed under the MIT License.
