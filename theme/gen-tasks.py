#!/usr/bin/env python3
# Writes theme/baikonur/widgets/tasks.svg: the dock task frames (running pill, active pill, hover background).
from pathlib import Path

FRAME, TOP, BOTTOM, SIDE = 60, 4, 8, 1
CAP, PILL_H, PILL_Y = 1.5, 3, 11
BG_INSET, BG_R = 2, 12

STATES = {
    "normal": dict(pill=6, color="Text", alpha=0.45),
    "minimized": dict(pill=6, color="Text", alpha=0.2),
    "focus": dict(pill=16, color="Highlight", alpha=1),
    "attention": dict(pill=16, color="NegativeText", alpha=1),
    "hover": dict(pill=0),
}

def el(id, w, h, x, y, body):
    return f'<g id="{id}" transform="translate({x} {y})"><rect width="{w}" height="{h}" fill="none"/>{body}</g>'

def fill(color, alpha):
    return f'class="ColorScheme-{color}" fill="currentColor" fill-opacity="{alpha}"'

def bg(part, cw):
    f = fill("Text", 0.1)
    i, r, e = BG_INSET, BG_R, 16
    return {
        "topleft": f'<path d="M{i+r},{i} H{cw} V{e} H{i} V{i+r} A{r},{r} 0 0 1 {i+r},{i} Z" {f}/>',
        "topright": f'<path d="M0,{i} H{cw-i-r} A{r},{r} 0 0 1 {cw-i},{i+r} V{e} H0 Z" {f}/>',
        "bottomleft": f'<path d="M{i},0 H{cw} V{e-i} H{i+r} A{r},{r} 0 0 1 {i},{e-i-r} Z" {f}/>',
        "bottomright": f'<path d="M0,0 H{cw-i} V{e-i-r} A{r},{r} 0 0 1 {cw-i-r},{e-i} H0 Z" {f}/>',
        "top": f'<rect y="{i}" width="1" height="{e-i}" {f}/>',
        "bottom": f'<rect width="1" height="{e-i}" {f}/>',
        "left": f'<rect x="{i}" width="{cw-i}" height="1" {f}/>',
        "right": f'<rect width="{cw-i}" height="1" {f}/>',
        "center": f'<rect width="1" height="1" {f}/>',
    }[part]

def pill(part, cw, s):
    f = fill(s["color"], s["alpha"])
    y, h, c = PILL_Y, PILL_H, CAP
    return {
        "bottomleft": f'<path d="M{cw},{y} a{c},{c} 0 0 0 0,{h} Z" {f}/>',
        "bottomright": f'<path d="M0,{y} a{c},{c} 0 0 1 0,{h} Z" {f}/>',
        "bottom": f'<rect y="{y}" width="1" height="{h}" {f}/>',
    }.get(part, "")

def prefix(name, s, hovered):
    cw = (FRAME - s["pill"]) // 2 if s["pill"] else 16
    out = []
    for part, w, h in [("topleft", cw, 16), ("top", 1, 16), ("topright", cw, 16), ("left", cw, 1), ("center", 1, 1),
                       ("right", cw, 1), ("bottomleft", cw, 16), ("bottom", 1, 16), ("bottomright", cw, 16)]:
        body = (bg(part, cw) if hovered else "") + (pill(part, cw, s) if s["pill"] else "")
        out.append((f"{name}-{part}", w, h, body))
    for side, v in [("top", TOP), ("bottom", BOTTOM), ("left", SIDE), ("right", SIDE)]:
        out.append((f"{name}-hint-{side}-margin", 1 if side in ("left", "right") else v, v if side in ("top", "bottom") else 1, ""))
    return out

items = [(f"hint-{s}-margin", 1, v, "") for s, v in [("top", TOP), ("bottom", BOTTOM)]] + \
        [(f"hint-{s}-margin", SIDE, 1, "") for s in ("left", "right")]
for name, s in STATES.items():
    items += prefix(name, s, name == "hover")
    if name != "hover":
        items += prefix(f"{name}-hover", s, True)

x = y = 0
rowh = 0
body = []
for id, w, h, inner in items:
    if x + w > 400:
        x, y, rowh = 0, y + rowh + 4, 0
    body.append(el(id, w, h, x, y, inner))
    x += w + 4
    rowh = max(rowh, h)

style = "".join(f".ColorScheme-{k}{{color:{v};}}" for k, v in
                [("Text", "#232629"), ("Highlight", "#3daee9"), ("NegativeText", "#da4453")])
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="400" height="{y+rowh}">'
       f'<style id="current-color-scheme" type="text/css">{style}</style>' + "".join(body) + "</svg>\n")
Path(__file__).with_name("baikonur").joinpath("widgets", "tasks.svg").write_text(svg)
