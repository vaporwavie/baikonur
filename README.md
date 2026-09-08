# Baikonur

macOS-style Plasma 6 layout for powerstation: top bar with global menu, floating icon dock, and a Raycast-style launcher of the same name. Everything installs per user under `~/.local`, no root.

## Layout

- `install.sh` installs the third-party widgets (Panel Colorizer, Plasmusic Toolbar, Window Title), the `baikonur` desktop theme, Geist, the launcher widget, and the launcher daemon as a user service.
- `apply.sh` applies Breeze Dark and the fonts, then rebuilds both panels from `panels.js` through the Plasma scripting API. It backs up the applet config first and prints the undo command. `--dock-autohide` builds the dock in autohide mode.
- `dock.sh on|off` toggles dock autohide on the live layout. With autohide the dock reserves no space, so windows take everything below the top bar and the dock slides in from the bottom edge. It also unloads KWin's screenedge effect, which otherwise paints the Breeze glow bar on the dock's trigger edge, and `off` loads it again.
- `panels.js` is the whole panel layout, including the Panel Colorizer settings as JSON.
- `theme/baikonur` is Breeze Dark with an empty `tasks.svg`, so the dock draws no task frames. The margin hints in that file set the dock icon size.
- `launcher/plasmoid` is the Baikonur widget: two floating Plasma dialogs, Alt+Space, talks to the daemon over localhost.
- `launcher/daemon` is a Bun process on `@ff-labs/fff-bun`. Apps are indexed as stub files so fff frecency ranks them. Pins live in `~/.config/baikonur/pins.json`.

## Notes

- Dock icon pitch follows panel thickness. 60px panel with 6px theme margins gives 48px icons.
- Plasma de-floats a panel when a maximized window touches it. The dock container is drawn inset from the panel, so it never reaches the screen edge.
- Restarting plasmashell right after `apply.sh` loses panel geometry. The script waits five seconds for that reason.
