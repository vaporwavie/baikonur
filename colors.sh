#!/usr/bin/env bash
# Installs GrokNight/GrokDay and applies the scheme for the current NightTime
# breakpoint (same midpoints Plasma uses for global theme auto-switch).
# --watch stays running and switches at those times. day|night forces one scheme.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
daynight=(python3 "$here/theme/daynight.py")

install_schemes() {
  mkdir -p "$HOME/.local/share/color-schemes"
  ln -sfn "$here/color-schemes/GrokNight.colors" "$HOME/.local/share/color-schemes/GrokNight.colors"
  ln -sfn "$here/color-schemes/GrokDay.colors" "$HOME/.local/share/color-schemes/GrokDay.colors"
}

apply() {
  local scheme=$1
  local current
  current=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
  if [ "$current" = "$scheme" ]; then
    return 0
  fi
  plasma-apply-colorscheme "$scheme" >/dev/null
  echo "baikonur colors: $scheme"
}

scheme_from_nighttime() {
  local out
  out=$("${daynight[@]}")
  echo "${out%% *}"
}

install_schemes
case "${1:-}" in
  "" | once)
    apply "$(scheme_from_nighttime)"
    ;;
  day)
    apply GrokDay
    ;;
  night)
    apply GrokNight
    ;;
  --watch | watch)
    while true; do
      if ! out=$("${daynight[@]}"); then
        sleep 5
        continue
      fi
      apply "${out%% *}"
      sleep "${out##* }"
    done
    ;;
  *)
    echo "usage: $0 [once|day|night|--watch]" >&2
    exit 2
    ;;
esac
