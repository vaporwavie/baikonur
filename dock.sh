#!/usr/bin/env bash
# Switches the dock between always visible and autohide on the live layout. Autohide reserves no space, so windows get everything below the top bar.
# KWin's screenedge effect draws the Breeze glow bar on the dock's trigger edge, so autohide turns that effect off and off turns it back on.
set -euo pipefail
case "${1:-}" in
  on) mode=autohide; edge=false; effect=unloadEffect ;;
  off) mode=none; edge=true; effect=loadEffect ;;
  *) echo "usage: $0 on|off" >&2; exit 2 ;;
esac
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
  "panels().forEach(function (p) { if (p.location == \"bottom\") p.hiding = \"$mode\"; });" | grep -v '^s ""$' || true
kwriteconfig6 --file kwinrc --group Plugins --key screenedgeEnabled "$edge"
busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects "$effect" s screenedge >/dev/null
echo "dock autohide: $1"
