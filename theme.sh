#!/usr/bin/env bash
# Reapplies the Baikonur desktop theme when something (a look-and-feel switch) reset it to Breeze.
set -euo pipefail
[ "$(kreadconfig6 --file plasmarc --group Theme --key name)" = baikonur ] && exit 0
plasma-apply-desktoptheme baikonur >/dev/null
