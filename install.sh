#!/usr/bin/env bash
# One-time setup: widgets, theme, fonts, launcher daemon. Everything lands under ~/.local, no root.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"

widget() { kpackagetool6 -t Plasma/Applet -i "$1" 2>/dev/null || kpackagetool6 -t Plasma/Applet -u "$1"; }

curl -sfL -o "$tmp/pc.plasmoid" https://github.com/luisbocanegra/plasma-panel-colorizer/releases/download/v8.0.0/plasmoid-panel-colorizer-v8.0.0.plasmoid
widget "$tmp/pc.plasmoid"
curl -sfL -o "$tmp/pm.plasmoid" https://github.com/ccatterina/plasmusic-toolbar/releases/download/v4.3.1/plasmusic-toolbar-v4.3.1.plasmoid
widget "$tmp/pm.plasmoid"
git clone -q --depth 1 https://github.com/dhruv8sh/plasma6-window-title-applet "$tmp/wt"
sed -i '/org.kde.plasma.private.appmenu/d' "$tmp/wt/contents/ui/main.qml"
widget "$tmp/wt"
widget "$here/launcher/plasmoid"

mkdir -p "$HOME/.local/share/plasma/desktoptheme"
ln -sfn "$here/theme/baikonur" "$HOME/.local/share/plasma/desktoptheme/baikonur"
mkdir -p "$HOME/.local/share/wallpapers"
ln -sfn "$here/wallpaper/baikonur" "$HOME/.local/share/wallpapers/baikonur"
mkdir -p "$HOME/.local/share/color-schemes"
ln -sfn "$here/color-schemes/GrokNight.colors" "$HOME/.local/share/color-schemes/GrokNight.colors"
ln -sfn "$here/color-schemes/GrokDay.colors" "$HOME/.local/share/color-schemes/GrokDay.colors"

if ! fc-list | grep -q Geist; then
  curl -sfL -o "$tmp/geist.zip" https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip
  unzip -qo "$tmp/geist.zip" -d "$tmp/geist"
  mkdir -p "$HOME/.local/share/fonts/Geist"
  cp "$tmp"/geist/geist-font/Geist/otf/Geist-{Light,Regular,Medium,SemiBold,Bold}.otf "$HOME/.local/share/fonts/Geist/"
  cp "$tmp"/geist/geist-font/GeistMono/otf/GeistMono-{Regular,Medium,Bold}.otf "$HOME/.local/share/fonts/Geist/"
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null
fi

(cd "$here/launcher/daemon" && bun install --silent)
mkdir -p "$HOME/.config/baikonur" "$HOME/.config/systemd/user"
[ -f "$HOME/.config/baikonur/pins.json" ] || cp "$here/launcher/pins.example.json" "$HOME/.config/baikonur/pins.json"
for u in baikonur.service baikonur-theme.service baikonur-theme.path; do ln -sfn "$here/systemd/$u" "$HOME/.config/systemd/user/$u"; done
systemctl --user daemon-reload
systemctl --user enable --now baikonur.service baikonur-theme.path

"$here/window-scale.sh"

rm -rf "$tmp"
echo "installed. now run: $here/apply.sh"
