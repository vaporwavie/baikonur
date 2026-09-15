#!/usr/bin/env python3
# Writes color-schemes/GrokNight.colors and GrokDay.colors from the grok palettes.
from pathlib import Path

def rgb(h):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def csv(h):
    return "{},{},{}".format(*rgb(h))

NIGHT = dict(
    id="GrokNight",
    name="GrokNight",
    window="#141414",
    window_alt="#111111",
    view="#141414",
    view_alt="#111111",
    button="#242424",
    button_alt="#1c1c1c",
    header="#0c0c0c",
    header_alt="#0a0a0a",
    header_inactive="#0a0a0a",
    tooltip="#0c0c0c",
    complementary="#0a0a0a",
    complementary_alt="#0c0c0c",
    selection="#7aa2f7",
    selection_alt="#3d59a1",
    selection_fg="#141414",
    fg="#e1e1e1",
    fg_inactive="#6c6c6c",
    fg_active="#7aa2f7",
    link="#7aa6da",
    visited="#bb9af7",
    negative="#f7768e",
    neutral="#ff9e64",
    positive="#9ece6a",
    focus="#7aa2f7",
    wm_active_bg="#0c0c0c",
    wm_active_fg="#e1e1e1",
    wm_inactive_bg="#0a0a0a",
    wm_inactive_fg="#6c6c6c",
)

DAY = dict(
    id="GrokDay",
    name="GrokDay",
    window="#f5f5f5",
    window_alt="#eaeaea",
    view="#f5f5f5",
    view_alt="#eeeeee",
    button="#eeeeee",
    button_alt="#eaeaea",
    header="#eaeaea",
    header_alt="#dedede",
    header_inactive="#eeeeee",
    tooltip="#eeeeee",
    complementary="#0a0a0a",
    complementary_alt="#0c0c0c",
    selection="#2f64d2",
    selection_alt="#28448a",
    selection_fg="#f5f5f5",
    fg="#262626",
    fg_inactive="#767676",
    fg_active="#2f64d2",
    link="#2f64d2",
    visited="#7d4bc6",
    negative="#cd3048",
    neutral="#c3691e",
    positive="#378e23",
    focus="#2f64d2",
    wm_active_bg="#eaeaea",
    wm_active_fg="#262626",
    wm_inactive_bg="#f5f5f5",
    wm_inactive_fg="#767676",
)

DAY_COMP_FG = dict(
    fg="#e1e1e1",
    fg_inactive="#6c6c6c",
    fg_active="#7aa2f7",
    link="#7aa6da",
    visited="#bb9af7",
    negative="#f7768e",
    neutral="#ff9e64",
    positive="#9ece6a",
    focus="#7aa2f7",
)


def group(name, bg, bg_alt, p):
    return f"""[{name}]
BackgroundAlternate={csv(bg_alt)}
BackgroundNormal={csv(bg)}
DecorationFocus={csv(p["focus"])}
DecorationHover={csv(p["focus"])}
ForegroundActive={csv(p["fg_active"])}
ForegroundInactive={csv(p["fg_inactive"])}
ForegroundLink={csv(p["link"])}
ForegroundNegative={csv(p["negative"])}
ForegroundNeutral={csv(p["neutral"])}
ForegroundNormal={csv(p["fg"])}
ForegroundPositive={csv(p["positive"])}
ForegroundVisited={csv(p["visited"])}
"""


def scheme(p):
    comp_p = {**p, **DAY_COMP_FG} if p["id"] == "GrokDay" else p
    sel = f"""[Colors:Selection]
BackgroundAlternate={csv(p["selection_alt"])}
BackgroundNormal={csv(p["selection"])}
DecorationFocus={csv(p["focus"])}
DecorationHover={csv(p["focus"])}
ForegroundActive={csv(p["selection_fg"])}
ForegroundInactive={csv(p["fg_inactive"])}
ForegroundLink={csv(p["link"])}
ForegroundNegative={csv(p["negative"])}
ForegroundNeutral={csv(p["neutral"])}
ForegroundNormal={csv(p["selection_fg"])}
ForegroundPositive={csv(p["positive"])}
ForegroundVisited={csv(p["visited"])}
"""
    return f"""# Grok palette from grok 1.0.30 (groknight.rs / grokday.rs).

[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

{group("Colors:Button", p["button"], p["button_alt"], p)}
{group("Colors:Complementary", p["complementary"], p["complementary_alt"], comp_p)}
{group("Colors:Header", p["header"], p["header_alt"], p)}
{group("Colors:Header][Inactive", p["header_inactive"], p["header"], p)}
{sel}
{group("Colors:Tooltip", p["tooltip"], p["header_alt"], p)}
{group("Colors:View", p["view"], p["view_alt"], p)}
{group("Colors:Window", p["window"], p["window_alt"], p)}
[General]
ColorScheme={p["id"]}
Name={p["name"]}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={csv(p["wm_active_bg"])}
activeBlend={csv(p["wm_active_fg"])}
activeForeground={csv(p["wm_active_fg"])}
inactiveBackground={csv(p["wm_inactive_bg"])}
inactiveBlend={csv(p["wm_inactive_fg"])}
inactiveForeground={csv(p["wm_inactive_fg"])}
"""


out = Path(__file__).resolve().parent.parent / "color-schemes"
out.mkdir(exist_ok=True)
for pal in (NIGHT, DAY):
    (out / f"{pal['id']}.colors").write_text(scheme(pal))
