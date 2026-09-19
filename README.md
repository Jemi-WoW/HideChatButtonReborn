# HideChatButtonReborn

Lightweight chat toggle button for World of Warcraft Classic Era and World of Warcraft: Forever.

## Supported clients

| Client | Interface | TOC |
|---|---|---|
| Classic Era 1.15.9 | 11509 | `HideChatButtonReborn_Vanilla.toc` |
| WoW Forever 1.60.1 | 16001 | `HideChatButtonReborn_Camelot.toc` |
| fallback | 11509, 16001 | `HideChatButtonReborn.toc` |

## Features

- One button toggles all chat frames, tabs, the dock and the chat side buttons.
- Activity indicator on the button while chat is hidden, colour-coded per channel.
- Toast popups for missed messages, per channel, with class-coloured sender names.
- Right-click the button for the missed message list.
- Drag anchor, size and opacity sliders, bottom-left / bottom-right presets.

## Forever beta notes

- **Settings do not persist between launches.** The beta client writes SavedVariables on logout but never reads them back, so the addon starts from defaults every session. This is a client bug, not an addon bug.
- Battleground chat toasts are hidden on Forever: the Retail client has no `CHAT_MSG_BATTLEGROUND` events, instance chat covers battlegrounds instead.
- `ReloadUI()` is protected on the beta. Type `/reload` instead.

## Edit Mode

Both clients ship Edit Mode. While the Edit Mode window is open the chat frames are restored so they can be moved, and hidden again when it closes.
