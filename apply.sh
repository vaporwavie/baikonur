#!/usr/bin/env bash
# Applies the macOS-style Plasma layout. KRunner stays the launcher (Alt+Space). Reversible: restores from the backup path printed below.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
autohide=false
case "${1:-}" in
  --dock-autohide) autohide=true ;;
  "") ;;
  *) echo "usage: $0 [--dock-autohide]" >&2; exit 2 ;;
esac
bak="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$bak"
echo "backup: $bak"

"$here/theme.sh"

font='Geist,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'
for k in font menuFont toolBarFont; do kwriteconfig6 --file kdeglobals --group General --key "$k" "$font"; done
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont 'Geist,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'
kwriteconfig6 --file kdeglobals --group WM --key activeFont 'Geist,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1'

sed -i -E "/^activate widget [0-9]+=/d" "$HOME/.config/kglobalshortcutsrc"
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "var dockAutohide = $autohide; var wallpaper = \"file://$HOME/.local/share/wallpapers/baikonur/\"; $(cat "$here/panels.js")" | grep -v '^s ""$' || true
sleep 5
if $autohide; then "$here/dock.sh" on; fi
echo "panels applied. Undo: cp '$bak' ~/.config/plasma-org.kde.plasma.desktop-appletsrc && plasmashell --replace &"
