#!/usr/bin/env bash
# Installs GrokNight/GrokDay color schemes and applies the one that matches
# the OS color-scheme preference (1 dark, 2 light, else GrokNight).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/.local/share/color-schemes"
ln -sfn "$here/color-schemes/GrokNight.colors" "$HOME/.local/share/color-schemes/GrokNight.colors"
ln -sfn "$here/color-schemes/GrokDay.colors" "$HOME/.local/share/color-schemes/GrokDay.colors"

pref=1
if out=$(busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings Read ss org.freedesktop.appearance color-scheme 2>/dev/null); then
  pref=${out##* }
fi
if [ "$pref" = 2 ]; then
  plasma-apply-colorscheme GrokDay >/dev/null
else
  plasma-apply-colorscheme GrokNight >/dev/null
fi
