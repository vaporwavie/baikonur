#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
plugin=baikonur-window-scale
scripts="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts"
target="$scripts/$plugin"

if [[ -e "$target" && ! -L "$target" ]]; then
  echo "Refusing to replace an existing directory: $target" >&2
  exit 1
fi

mkdir -p "$scripts"
ln -sfnT "$here/kwin/$plugin" "$target"
kwriteconfig6 --file kwinrc --group Plugins --key "${plugin}Enabled" true
busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s "$plugin" >/dev/null
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
for ((attempt = 0; attempt < 50; attempt++)); do
  if [[ "$(busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s "$plugin")" == "b true" ]]; then
    echo "Window scaling enabled: Alt+Shift+= grows, Alt+Shift+- shrinks."
    exit 0
  fi
  sleep 0.1
done
echo "Window scaling is enabled in kwinrc, but KWin did not load it." >&2
exit 1
