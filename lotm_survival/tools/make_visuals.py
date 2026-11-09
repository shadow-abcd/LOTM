#!/usr/bin/env python3
"""Generates every raster asset for the Godot project (icons, sprites, textures, UI, portraits).
Run from the project root:  python3 tools/make_visuals.py [path/to/original_web_project]
Needs: pillow, numpy, scipy.
"""
import math, os, sys, shutil, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from scipy.ndimage import gaussian_filter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = sys.argv[1] if len(sys.argv) > 1 else None   # original web project (for painted sheets)
A = os.path.join(ROOT, "assets")
for d in ("icons", "sprites", "ui", "portraits", "textures", "fonts"):
    os.makedirs(os.path.join(A, d), exist_ok=True)
random.seed(7); np.random.seed(7)

# ───────────────────────────── ICONS ─────────────────────────────
S = 256          # draw size, downscaled to 96
W = (255, 255, 255, 255)

def canvas():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def rot(pts, cx, cy, ang):
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]

def rrect(d, cx, cy, w, h, ang=0.0, fill=W):
    pts = [(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)]
    d.polygon(rot(pts, cx, cy, ang), fill=fill)

def ring(d, cx, cy, r, w, fill=W):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=fill, width=w)

def disc(d, cx, cy, r, fill=W):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)

def line(d, pts, w=14):
    d.line(pts, fill=W, width=w, joint="curve")
    for x, y in (pts[0], pts[-1]):
        disc(d, x, y, w / 2)

def erase(im, fn):
    m = Image.new("L", (S, S), 0)
    fn(ImageDraw.Draw(m))
    a = im.getchannel("A")
    a = ImageChops.subtract(a, m)
    im.putalpha(a)

def star_pts(cx, cy, ro, ri, n, off=-math.pi / 2):
    return [(cx + (ro if i % 2 == 0 else ri) * math.cos(off + i * math.pi / n),
             cy + (ro if i % 2 == 0 else ri) * math.sin(off + i * math.pi / n)) for i in range(2 * n)]

ICONS = {}
def icon(name):
    def deco(fn):
        ICONS[name] = fn
        return fn
    return deco

@icon("settings")
def _(im, d):
    for i in range(4):
        rrect(d, 128, 128, 54, 226, i * math.pi / 4)
    disc(d, 128, 128, 88)
    erase(im, lambda m: m.ellipse([128 - 34, 128 - 34, 128 + 34, 128 + 34], fill=255))

@icon("equipment")  # sword + shield
def _(im, d):
    d.polygon([(128, 30), (214, 62), (206, 150), (128, 226), (50, 150), (42, 62)], fill=W)
    erase(im, lambda m: m.polygon([(128, 58), (188, 80), (182, 144), (128, 196), (74, 144), (68, 80)], fill=255))
    rrect(d, 128, 120, 16, 124); rrect(d, 128, 150, 70, 14)
    d.polygon([(128, 54), (138, 76), (118, 76)], fill=W)

@icon("inventory")
def _(im, d):
    d.rounded_rectangle([46, 96, 210, 226], 26, fill=W)
    ring(d, 128, 90, 44, 16)
    erase(im, lambda m: m.rounded_rectangle([96, 140, 160, 168], 12, fill=255))

@icon("study")
def _(im, d):
    d.polygon([(30, 70), (120, 56), (120, 206), (30, 220)], fill=W)
    d.polygon([(226, 70), (136, 56), (136, 206), (226, 220)], fill=W)
    erase(im, lambda m: [m.line([(48, 100 + i * 28, ), (104, 92 + i * 28)], fill=255, width=7) for i in range(4)])

@icon("grimoire")
def _(im, d):
    d.rounded_rectangle([50, 30, 206, 226], 14, fill=W)
    erase(im, lambda m: m.rounded_rectangle([70, 50, 186, 206], 8, fill=255))
    ring(d, 128, 128, 40, 9)
    d.polygon(star_pts(128, 128, 26, 10, 4), fill=W)

@icon("rack")      # picture frame / relic rack
def _(im, d):
    d.rectangle([30, 40, 226, 216], fill=W)
    erase(im, lambda m: m.rectangle([52, 62, 204, 194], fill=255))
    ring(d, 128, 128, 36, 12); disc(d, 128, 128, 12)

@icon("shelf")
def _(im, d):
    rrect(d, 128, 204, 210, 18); rrect(d, 128, 120, 210, 18)
    rrect(d, 70, 78, 36, 66); rrect(d, 118, 66, 30, 78); d.polygon([(170, 120), (200, 120), (186, 60)], fill=W)
    disc(d, 62, 168, 22); rrect(d, 128, 174, 48, 52); rrect(d, 190, 176, 36, 48)

@icon("desk")
def _(im, d):
    rrect(d, 128, 132, 220, 20); rrect(d, 54, 188, 18, 86); rrect(d, 202, 188, 18, 86)
    d.polygon([(70, 120), (120, 40), (130, 46), (84, 126)], fill=W)  # quill
    d.polygon([(150, 120), (190, 70), (200, 78), (170, 124)], fill=W)

@icon("cabinet")
def _(im, d):
    d.rounded_rectangle([54, 24, 202, 232], 12, fill=W)
    erase(im, lambda m: [m.rounded_rectangle([70, 40 + i * 62, 186, 88 + i * 62], 6, fill=255) for i in range(3)])
    for i in range(3):
        disc(d, 128, 64 + i * 62, 9)

@icon("altar")
def _(im, d):
    d.polygon([(70, 226), (186, 226), (170, 150), (86, 150)], fill=W)
    rrect(d, 128, 146, 130, 18)
    d.polygon([(128, 24), (166, 84), (150, 120), (106, 120), (90, 84)], fill=W)
    erase(im, lambda m: m.polygon([(128, 66), (144, 94), (128, 110), (112, 94)], fill=255))

@icon("auction")   # gavel
def _(im, d):
    rrect(d, 100, 88, 110, 56, -0.7); rrect(d, 150, 140, 22, 130, -0.7)
    rrect(d, 128, 224, 150, 18)

@icon("pathways")  # forked road
def _(im, d):
    line(d, [(128, 230), (128, 140), (70, 60)], 22); line(d, [(128, 140), (186, 60)], 22)
    d.polygon([(50, 70), (96, 40), (84, 90)], fill=W); d.polygon([(206, 70), (160, 40), (172, 90)], fill=W)

@icon("bestiary")  # skull
def _(im, d):
    d.ellipse([42, 28, 214, 180], fill=W); d.rounded_rectangle([82, 150, 174, 226], 18, fill=W)
    erase(im, lambda m: [m.ellipse([70, 84, 118, 132], fill=255), m.ellipse([138, 84, 186, 132], fill=255),
                         m.polygon([(128, 130), (142, 160), (114, 160)], fill=255)] +
                        [m.rectangle([98 + i * 20, 190, 106 + i * 20, 226], fill=255) for i in range(3)])

@icon("codex")
def _(im, d):
    d.rounded_rectangle([60, 40, 196, 216], 12, fill=W)
    erase(im, lambda m: [m.rectangle([84, 74 + i * 30, 172, 82 + i * 30], fill=255) for i in range(4)])
    ring(d, 60, 128, 22, 12); ring(d, 196, 128, 22, 12)

@icon("whisper")   # envelope
def _(im, d):
    d.rounded_rectangle([26, 60, 230, 200], 16, fill=W)
    erase(im, lambda m: m.line([(36, 74), (128, 142), (220, 74)], fill=255, width=12))

@icon("map")
def _(im, d):
    ring(d, 128, 128, 100, 16)
    d.polygon([(128, 48), (150, 128), (128, 208), (106, 128)], fill=W)
    d.polygon([(48, 128), (128, 106), (208, 128), (128, 150)], fill=W)
    erase(im, lambda m: m.ellipse([112, 112, 144, 144], fill=255))

@icon("audio")
def _(im, d):
    d.polygon([(30, 104), (80, 104), (130, 56), (130, 200), (80, 152), (30, 152)], fill=W)
    for r in (40, 72):
        d.arc([130 - r, 128 - r, 130 + r, 128 + r], -50, 50, fill=W, width=14)

@icon("music")
def _(im, d):
    d.ellipse([40, 150, 104, 206], fill=W); d.ellipse([140, 130, 204, 186], fill=W)
    rrect(d, 98, 100, 14, 112); rrect(d, 198, 80, 14, 112)
    d.polygon([(92, 38), (206, 14), (206, 60), (92, 84)], fill=W)

@icon("sfx")
def _(im, d):
    for i, h in enumerate([50, 110, 170, 90, 140, 60, 100]):
        rrect(d, 40 + i * 30, 128, 16, h)

@icon("graphics")
def _(im, d):
    d.rounded_rectangle([24, 44, 232, 178], 14, fill=W)
    erase(im, lambda m: m.rectangle([44, 62, 212, 160], fill=255))
    rrect(d, 128, 196, 22, 28); rrect(d, 128, 218, 90, 14)
    d.polygon([(70, 140), (110, 96), (138, 126), (160, 100), (196, 140)], fill=W)

@icon("controls")
def _(im, d):
    d.rounded_rectangle([20, 76, 236, 184], 50, fill=W)
    erase(im, lambda m: [m.rectangle([50, 118, 90, 136], fill=255), m.rectangle([61, 107, 79, 147], fill=255),
                         m.ellipse([160, 104, 182, 126], fill=255), m.ellipse([186, 130, 208, 152], fill=255)])

@icon("gameplay")
def _(im, d):
    d.polygon([(128, 24), (214, 74), (214, 182), (128, 232), (42, 182), (42, 74)], fill=W)
    erase(im, lambda m: m.polygon([(128, 60), (184, 92), (184, 164), (128, 196), (72, 164), (72, 92)], fill=255))
    d.polygon(star_pts(128, 128, 34, 14, 4), fill=W)

@icon("accessibility")
def _(im, d):
    disc(d, 128, 52, 26); rrect(d, 128, 98, 160, 20)
    d.polygon([(118, 100), (138, 100), (146, 150), (178, 232), (156, 236), (128, 180), (100, 236), (78, 232), (110, 150)], fill=W)

@icon("pause")
def _(im, d):
    rrect(d, 92, 128, 40, 160); rrect(d, 164, 128, 40, 160)

@icon("play")
def _(im, d):
    d.polygon([(70, 36), (214, 128), (70, 220)], fill=W)

@icon("home")
def _(im, d):
    d.polygon([(128, 28), (230, 116), (204, 116), (204, 220), (52, 220), (52, 116), (26, 116)], fill=W)
    erase(im, lambda m: m.rounded_rectangle([104, 150, 152, 220], 8, fill=255))

@icon("back")
def _(im, d):
    line(d, [(210, 128), (56, 128)], 26); line(d, [(112, 62), (46, 128), (112, 194)], 26)

@icon("close")
def _(im, d):
    line(d, [(54, 54), (202, 202)], 26); line(d, [(202, 54), (54, 202)], 26)

@icon("check")
def _(im, d):
    line(d, [(44, 136), (100, 192), (212, 66)], 28)

@icon("lock")
def _(im, d):
    d.arc([68, 24, 188, 144], 180, 360, fill=W, width=24); rrect(d, 80, 90, 24, 50); rrect(d, 176, 90, 24, 50)
    d.rounded_rectangle([50, 112, 206, 232], 20, fill=W)
    erase(im, lambda m: [m.ellipse([112, 148, 144, 180], fill=255), m.rectangle([122, 170, 134, 202], fill=255)])

@icon("unlock")
def _(im, d):
    d.arc([68, 14, 188, 134], 180, 330, fill=W, width=24); rrect(d, 80, 80, 24, 50)
    d.rounded_rectangle([50, 112, 206, 232], 20, fill=W)
    erase(im, lambda m: [m.ellipse([112, 148, 144, 180], fill=255), m.rectangle([122, 170, 134, 202], fill=255)])

@icon("coin")
def _(im, d):
    disc(d, 128, 128, 102); erase(im, lambda m: m.ellipse([40, 40, 216, 216], fill=255))
    disc(d, 128, 128, 90); erase(im, lambda m: m.ellipse([58, 58, 198, 198], fill=255))
    disc(d, 128, 128, 76)
    erase(im, lambda m: [m.rectangle([120, 76, 136, 180], fill=255), m.rectangle([98, 100, 158, 112], fill=255)])

@icon("diamond")
def _(im, d):
    d.polygon([(70, 30), (186, 30), (232, 96), (128, 232), (24, 96)], fill=W)
    erase(im, lambda m: [m.line([(24, 96), (232, 96)], fill=255, width=8), m.line([(70, 30), (100, 96), (128, 232)], fill=255, width=8),
                         m.line([(186, 30), (156, 96), (128, 232)], fill=255, width=8)])

@icon("heart")
def _(im, d):
    d.ellipse([28, 42, 134, 148], fill=W); d.ellipse([122, 42, 228, 148], fill=W)
    d.polygon([(34, 112), (222, 112), (128, 228)], fill=W)

@icon("shield")
def _(im, d):
    d.polygon([(128, 24), (216, 56), (208, 150), (128, 232), (48, 150), (40, 56)], fill=W)
    erase(im, lambda m: m.polygon([(128, 60), (180, 80), (176, 140), (128, 190), (80, 140), (76, 80)], fill=255))

@icon("sword")
def _(im, d):
    d.polygon([(206, 24), (232, 50), (110, 172), (84, 146)], fill=W)
    rrect(d, 96, 158, 90, 20, -0.785); rrect(d, 62, 194, 20, 62, -0.785); disc(d, 44, 212, 14)

@icon("charm")
def _(im, d):
    ring(d, 128, 52, 26, 12); line(d, [(128, 78), (128, 96)], 10)
    d.polygon([(128, 92), (206, 150), (128, 232), (50, 150)], fill=W)
    erase(im, lambda m: m.polygon([(128, 130), (160, 156), (128, 190), (96, 156)], fill=255))

@icon("artifact")
def _(im, d):
    ring(d, 128, 150, 70, 26); d.polygon([(128, 20), (160, 66), (128, 100), (96, 66)], fill=W)

@icon("potion")
def _(im, d):
    rrect(d, 128, 40, 50, 22); rrect(d, 128, 74, 34, 56)
    d.polygon([(110, 100), (146, 100), (214, 200), (196, 232), (60, 232), (42, 200)], fill=W)
    erase(im, lambda m: m.polygon([(84, 168), (172, 168), (188, 196), (176, 210), (80, 210), (68, 196)], fill=255))

@icon("scroll")
def _(im, d):
    d.rounded_rectangle([60, 50, 196, 206], 8, fill=W)
    d.ellipse([36, 28, 96, 80], fill=W); d.ellipse([160, 176, 220, 228], fill=W)
    erase(im, lambda m: [m.rectangle([84, 84 + i * 24, 172, 92 + i * 24], fill=255) for i in range(4)])

@icon("star")
def _(im, d):
    d.polygon(star_pts(128, 132, 108, 46, 5), fill=W)

@icon("flame")
def _(im, d):
    d.polygon([(128, 18), (196, 100), (212, 160), (186, 218), (128, 238), (70, 218), (44, 160), (68, 106), (96, 140), (104, 84)], fill=W)
    erase(im, lambda m: m.polygon([(128, 130), (162, 170), (150, 212), (128, 222), (106, 212), (94, 170)], fill=255))

@icon("eye")
def _(im, d):
    d.polygon([(16, 128), (70, 70), (128, 52), (186, 70), (240, 128), (186, 186), (128, 204), (70, 186)], fill=W)
    erase(im, lambda m: m.ellipse([78, 78, 178, 178], fill=255)); disc(d, 128, 128, 30)

@icon("timer")
def _(im, d):
    ring(d, 128, 142, 88, 18); rrect(d, 128, 28, 50, 18); line(d, [(128, 142), (128, 90)], 14); line(d, [(128, 142), (164, 164)], 14)

@icon("sigil")
def _(im, d):
    ring(d, 128, 128, 106, 12); ring(d, 128, 128, 66, 10)
    d.polygon(star_pts(128, 128, 100, 38, 3), outline=W, width=10)
    d.polygon(star_pts(128, 128, 100, 38, 3, math.pi / 2), outline=W, width=10)

@icon("plus")
def _(im, d):
    rrect(d, 128, 128, 40, 180); rrect(d, 128, 128, 180, 40)

@icon("minus")
def _(im, d):
    rrect(d, 128, 128, 180, 40)

@icon("info")
def _(im, d):
    ring(d, 128, 128, 104, 16); disc(d, 128, 78, 14); rrect(d, 128, 148, 22, 82)

@icon("fullscreen")
def _(im, d):
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = 128 + sx * 92, 128 + sy * 92
            rrect(d, cx - sx * 24, cy, 50, 20); rrect(d, cx, cy - sy * 24, 20, 50)

@icon("vibration")
def _(im, d):
    d.rounded_rectangle([88, 36, 168, 220], 16, fill=W)
    erase(im, lambda m: m.rounded_rectangle([102, 60, 154, 190], 6, fill=255))
    for x in (40, 216):
        rrect(d, x, 128, 14, 100)
    for x in (16, 240):
        rrect(d, x, 128, 12, 54)

@icon("joystick")
def _(im, d):
    ring(d, 128, 128, 108, 14); disc(d, 128, 128, 52)
    for a in range(4):
        ang = a * math.pi / 2
        d.polygon(rot([(128, 22), (146, 50), (110, 50)], 128, 128, ang), fill=W)

@icon("dash")
def _(im, d):
    for i, y in enumerate((70, 128, 186)):
        line(d, [(20 + i * 12, y), (150 + i * 4, y)], 16)
    d.polygon([(150, 52), (240, 128), (150, 204)], fill=W)

@icon("levelup")
def _(im, d):
    for i in range(3):
        line(d, [(60, 180 - i * 52), (128, 128 - i * 52), (196, 180 - i * 52)], 22)

@icon("gem")
def _(im, d):
    d.polygon([(76, 40), (180, 40), (226, 100), (128, 224), (30, 100)], fill=W)
    erase(im, lambda m: [m.polygon([(76, 40), (128, 100), (180, 40)], outline=255, width=8),
                         m.line([(30, 100), (226, 100)], fill=255, width=8)])

@icon("crown")
def _(im, d):
    d.polygon([(28, 202), (28, 82), (80, 134), (128, 54), (176, 134), (228, 82), (228, 202)], fill=W)
    for x in (28, 128, 228):
        disc(d, x, 66 if x == 128 else 80, 14)
    erase(im, lambda m: m.rectangle([28, 180, 228, 190], fill=255))

@icon("save")
def _(im, d):
    d.rounded_rectangle([30, 30, 226, 226], 18, fill=W)
    erase(im, lambda m: [m.rectangle([70, 30, 186, 100], fill=255), m.rounded_rectangle([60, 140, 196, 226], 8, fill=255)])
    rrect(d, 158, 66, 20, 50)

@icon("reset")
def _(im, d):
    d.arc([36, 36, 220, 220], 40, 330, fill=W, width=24)
    d.polygon([(190, 20), (240, 100), (150, 90)], fill=W)

@icon("quit")
def _(im, d):
    d.rounded_rectangle([34, 30, 150, 226], 10, fill=W)
    erase(im, lambda m: m.rectangle([56, 52, 128, 204], fill=255))
    line(d, [(110, 128), (222, 128)], 22); d.polygon([(190, 84), (244, 128), (190, 172)], fill=W)

@icon("keyboard")
def _(im, d):
    d.rounded_rectangle([14, 64, 242, 192], 18, fill=W)
    erase(im, lambda m: [m.rectangle([34 + c * 36, 84 + r * 34, 56 + c * 36, 100 + r * 34], fill=255)
                         for r in range(2) for c in range(6)] + [m.rectangle([66, 154, 190, 172], fill=255)])

@icon("effects")
def _(im, d):
    d.polygon(star_pts(128, 128, 112, 24, 4), fill=W)
    d.polygon(star_pts(196, 60, 40, 10, 4), fill=W); d.polygon(star_pts(60, 196, 34, 8, 4), fill=W)

@icon("shake")
def _(im, d):
    for dx in (-20, 0, 20):
        d.rounded_rectangle([64 + dx, 70, 192 + dx, 186], 14, outline=(255, 255, 255, 255 - abs(dx) * 7), width=12)

@icon("language")
def _(im, d):
    ring(d, 128, 128, 104, 14); d.ellipse([70, 24, 186, 232], outline=W, width=12)
    rrect(d, 128, 128, 208, 12); rrect(d, 128, 128, 12, 208)

@icon("difficulty")
def _(im, d):
    d.polygon([(128, 20), (230, 220), (26, 220)], fill=W)
    erase(im, lambda m: [m.rectangle([118, 90, 138, 164], fill=255), m.ellipse([116, 182, 140, 206], fill=255)])

@icon("boss")
def _(im, d):
    d.ellipse([46, 40, 210, 190], fill=W); d.polygon([(54, 90), (30, 20), (90, 60)], fill=W); d.polygon([(202, 90), (226, 20), (166, 60)], fill=W)
    erase(im, lambda m: [m.polygon([(70, 100), (116, 120), (70, 136)], fill=255), m.polygon([(186, 100), (140, 120), (186, 136)], fill=255)])
    d.rectangle([96, 180, 160, 226], fill=W)

@icon("fate")  # tarot card / reroll
def _(im, d):
    d.rounded_rectangle([60, 26, 196, 230], 16, fill=W)
    erase(im, lambda m: m.rounded_rectangle([76, 42, 180, 214], 8, fill=255))
    d.polygon(star_pts(128, 128, 44, 16, 6), fill=W)

@icon("storm")
def _(im, d):
    d.polygon([(150, 12), (60, 140), (118, 140), (92, 244), (200, 100), (140, 100)], fill=W)

@icon("wind")
def _(im, d):
    d.arc([30, 70, 190, 160], 180, 360, fill=W, width=16); d.arc([60, 110, 220, 200], 0, 180, fill=W, width=16)
    line(d, [(30, 126), (170, 126)], 16)

@icon("compass")
def _(im, d):
    ring(d, 128, 128, 104, 14)
    d.polygon([(168, 88), (150, 150), (88, 168), (106, 106)], fill=W)

@icon("coins")
def _(im, d):
    for i, (x, y) in enumerate(((90, 100), (150, 150), (96, 180))):
        d.ellipse([x - 62, y - 28, x + 62, y + 28], fill=W)
        erase(im, lambda m, x=x, y=y: m.ellipse([x - 50, y - 18, x + 50, y + 18], fill=255))
        d.ellipse([x - 38, y - 12, x + 38, y + 12], fill=W)

@icon("thread")
def _(im, d):
    d.arc([40, 20, 216, 176], 20, 340, fill=W, width=12)
    d.arc([70, 70, 190, 230], 200, 520, fill=W, width=12)
    disc(d, 128, 214, 14)

@icon("orbit")
def _(im, d):
    ring(d, 128, 128, 40, 14)
    d.ellipse([20, 74, 236, 182], outline=W, width=10); disc(d, 220, 108, 14); disc(d, 36, 148, 14)

@icon("zap")
def _(im, d):
    d.polygon([(150, 12), (60, 140), (118, 140), (92, 244), (200, 100), (140, 100)], fill=W)

@icon("book")
def _(im, d):
    d.rounded_rectangle([56, 28, 206, 228], 12, fill=W)
    erase(im, lambda m: [m.rectangle([76, 56, 186, 70], fill=255), m.rectangle([76, 90, 160, 102], fill=255)])
    d.rectangle([56, 190, 206, 206], fill=(0, 0, 0, 0))

@icon("moon")
def _(im, d):
    disc(d, 128, 128, 104); erase(im, lambda m: m.ellipse([100, 30, 250, 180], fill=255))

@icon("skull")
def _(im, d):
    ICONS["bestiary"](im, d)

@icon("sun")
def _(im, d):
    disc(d, 128, 128, 56)
    for i in range(12):
        rrect(d, 128, 128, 14, 236 if i % 2 == 0 else 190, i * math.pi / 12)
    erase(im, lambda m: m.ellipse([60, 60, 196, 196], fill=255)); disc(d, 128, 128, 50)

def build_icons():
    out = os.path.join(A, "icons")
    for name, fn in ICONS.items():
        im, d = canvas()
        fn(im, d)
        im = im.resize((96, 96), Image.LANCZOS)
        im.save(os.path.join(out, f"{name}.png"))
    print("icons:", len(ICONS))

# ───────────────────────── SPRITES / PARTICLES ─────────────────────────
def radial(size, power=2.0, color=(255, 255, 255)):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    r = np.sqrt((x - size / 2 + .5) ** 2 + (y - size / 2 + .5) ** 2) / (size / 2)
    a = np.clip(1 - r, 0, 1) ** power
    arr = np.zeros((size, size, 4), np.uint8)
    arr[..., 0], arr[..., 1], arr[..., 2] = color
    arr[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

def build_particles():
    o = os.path.join(A, "sprites")
    radial(128, 2.2).save(f"{o}/glow.png")
    radial(64, 1.2).save(f"{o}/soft_dot.png")
    # spark: 4-point star
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon(star_pts(32, 32, 30, 3, 4), fill=W); im = im.filter(ImageFilter.GaussianBlur(0.8)); im.save(f"{o}/spark.png")
    # ring
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([10, 10, 246, 246], outline=W, width=10)
    im.filter(ImageFilter.GaussianBlur(3)).save(f"{o}/ring.png")
    # smoke blob
    n = gaussian_filter(np.random.rand(128, 128), 9); n = (n - n.min()) / (n.max() - n.min())
    yy, xx = np.mgrid[0:128, 0:128]; fall = np.clip(1 - np.hypot(xx - 64, yy - 64) / 64, 0, 1)
    arr = np.zeros((128, 128, 4), np.uint8); arr[..., :3] = 255; arr[..., 3] = (n * fall ** 1.2 * 255).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(f"{o}/smoke.png")
    # projectile bolt (horizontal, pointing right)
    im = Image.new("RGBA", (96, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([8, 8, 88, 24], fill=(255, 255, 255, 120)); d.ellipse([40, 11, 90, 21], fill=W)
    im.filter(ImageFilter.GaussianBlur(1.5)).save(f"{o}/bolt.png")
    # orbit blade
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(32, 2), (48, 36), (32, 62), (16, 36)], fill=W); d.polygon([(32, 14), (40, 36), (32, 52), (24, 36)], fill=(255, 255, 255, 90))
    im.save(f"{o}/blade.png")
    # fragments, pickups
    im = Image.new("RGBA", (48, 48), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(24, 2), (42, 22), (24, 46), (6, 22)], fill=W); d.line([(6, 22), (42, 22)], fill=(0, 0, 0, 90), width=2)
    im.save(f"{o}/fragment.png")
    # slash arc
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.arc([8, 8, 120, 120], 200, 340, fill=W, width=10); im.filter(ImageFilter.GaussianBlur(1.6)).save(f"{o}/slash.png")
    # shadow
    n = Image.new("RGBA", (96, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(n); d.ellipse([4, 4, 92, 36], fill=(0, 0, 0, 150))
    n.filter(ImageFilter.GaussianBlur(5)).save(f"{o}/shadow.png")
    # vignette (alpha only, white center transparent)
    sz = 256; yy, xx = np.mgrid[0:sz, 0:sz]; r = np.hypot(xx - sz / 2, yy - sz / 2) / (sz / 2 * 1.2)
    arr = np.zeros((sz, sz, 4), np.uint8); arr[..., :3] = 255; arr[..., 3] = (np.clip(r, 0, 1) ** 2.4 * 255).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(f"{o}/vignette.png")

# enemies: stylised silhouettes with glowing eyes
def enemy(name, kind, tint, eye=(255, 190, 120), size=128):
    sc = 4; sz = size * sc
    im = Image.new("RGBA", (sz, sz), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    dark = tuple(int(c * .38) for c in tint) + (255,); mid = tuple(int(c * .66) for c in tint) + (255,)
    lite = tint + (255,)
    cx = sz / 2
    def P(pts): return [(x * sc, y * sc) for x, y in pts]
    if kind == "husk":
        d.polygon(P([(64, 14), (84, 34), (88, 70), (100, 118), (28, 118), (40, 70), (44, 34)]), fill=mid)
        d.polygon(P([(64, 14), (74, 34), (64, 118), (54, 34)]), fill=dark)
        d.ellipse(P([(54, 28), (74, 44)]), fill=dark)
    elif kind == "hound":
        d.polygon(P([(14, 70), (40, 52), (84, 54), (110, 40), (118, 56), (100, 70), (108, 108), (96, 108), (88, 80), (44, 82), (38, 108), (26, 108), (30, 82)]), fill=mid)
        d.polygon(P([(100, 38), (112, 22), (116, 44)]), fill=dark)
    elif kind == "wisp":
        d.ellipse(P([(34, 24), (94, 84)]), fill=mid)
        d.polygon(P([(34, 56), (94, 56), (84, 118), (74, 96), (64, 122), (54, 96), (44, 118)]), fill=mid)
    elif kind == "brute":
        d.ellipse(P([(24, 18), (104, 70)]), fill=mid); d.rounded_rectangle(P([(18, 56), (110, 124)]), 18 * sc, fill=mid)
        d.rounded_rectangle(P([(2, 60), (26, 116)]), 8 * sc, fill=dark); d.rounded_rectangle(P([(102, 60), (126, 116)]), 8 * sc, fill=dark)
    elif kind == "tree":     # standing ash
        d.rounded_rectangle(P([(52, 20), (78, 124)]), 8 * sc, fill=mid)
        d.polygon(P([(64, 40), (112, 20), (116, 28), (68, 56)]), fill=lite)
        d.polygon(P([(60, 56), (16, 40), (14, 48), (56, 70)]), fill=mid)
        d.ellipse(P([(36, 4), (92, 40)]), fill=dark)
    elif kind == "climber":
        d.polygon(P([(46, 44), (82, 44), (90, 110), (70, 124), (58, 124), (38, 110)]), fill=mid)
        d.ellipse(P([(50, 20), (78, 48)]), fill=mid); d.polygon(P([(72, 42), (94, 4), (100, 8), (82, 50)]), fill=lite)
    elif kind == "salt":
        d.polygon(P([(64, 10), (96, 40), (100, 120), (28, 120), (32, 40)]), fill=lite)
        d.polygon(P([(64, 10), (74, 40), (64, 120), (54, 40)]), fill=mid)
        for i in range(3): d.line(P([(58 + i * 6, 76), (58 + i * 6, 92)]), fill=dark, width=4 * sc)
    elif kind == "shard":
        d.polygon(P([(64, 6), (100, 50), (88, 120), (40, 124), (26, 54)]), fill=mid)
        d.polygon(P([(64, 6), (74, 52), (50, 118), (40, 124), (26, 54)]), fill=lite)
        d.line(P([(64, 6), (66, 124)]), fill=dark, width=2 * sc)
    elif kind == "graft":
        for a in range(10):
            ang = a * math.tau / 10; d.line(P([(64, 66), (64 + 54 * math.cos(ang), 66 + 54 * math.sin(ang))]), fill=dark, width=6 * sc)
        d.ellipse(P([(34, 36), (94, 96)]), fill=mid)
    elif kind == "lamp":
        d.polygon(P([(48, 20), (80, 20), (96, 124), (32, 124)]), fill=mid)
        d.ellipse(P([(48, 14), (80, 46)]), fill=dark)
        d.line(P([(96, 60), (110, 60)]), fill=lite, width=3 * sc); d.rounded_rectangle(P([(104, 60), (120, 84)]), 3 * sc, fill=(255, 205, 110, 255))
    elif kind == "boss":
        d.polygon(P([(64, 10), (112, 66), (124, 124), (4, 124), (16, 66)]), fill=dark)
        d.polygon(P([(40, 20), (52, 4), (64, 18), (76, 4), (88, 20)]), fill=(210, 170, 70, 255))
        d.polygon(P([(64, 26), (96, 70), (104, 124), (24, 124), (32, 70)]), fill=mid)
    # eyes
    if kind not in ("tree", "boss", "graft"):
        ey = {"hound": 54, "wisp": 48, "brute": 46, "shard": 44, "climber": 34, "lamp": 30}.get(kind, 38)
        for ex in ((54, 74) if kind != "hound" else (100, 108)):
            d.ellipse(P([(ex - 4, ey - 3), (ex + 4, ey + 3)]), fill=eye + (255,))
    elif kind == "tree": d.ellipse(P([(58, 36), (70, 44)]), fill=eye + (255,))
    elif kind == "boss":
        for ex in (50, 78): d.ellipse(P([(ex - 5, 58), (ex + 5, 66)]), fill=(255, 235, 150, 255))
    elif kind == "graft":
        d.ellipse(P([(54, 56), (74, 76)]), fill=eye + (255,))
    # rim light
    rim = im.filter(ImageFilter.GaussianBlur(2 * sc)); glow = Image.new("RGBA", im.size, tint + (0,))
    glow.putalpha(rim.getchannel("A").point(lambda v: int(v * .35)))
    out = Image.alpha_composite(glow, im).resize((size, size), Image.LANCZOS)
    out.save(os.path.join(A, "sprites", f"enemy_{name}.png"))

def build_enemies():
    specs = [("husk", "husk", (150, 140, 135)), ("hound", "hound", (160, 120, 100)), ("wisp", "wisp", (140, 150, 190)),
             ("brute", "brute", (120, 120, 130)), ("standing_ash", "tree", (154, 149, 140)), ("slow_ascender", "climber", (127, 151, 166)),
             ("reciting_choir", "salt", (205, 205, 215)), ("reflection_that_stays", "shard", (170, 190, 215)),
             ("grafter", "graft", (155, 217, 79)), ("lamplighter", "lamp", (200, 160, 90)), ("boss", "boss", (120, 90, 130))]
    for n, k, t in specs:
        enemy(n, k, t, size=192 if k == "boss" else 128)

# player sprites + portraits from painted sheets
def keyed(img):
    """black background -> alpha"""
    arr = np.asarray(img.convert("RGB")).astype(np.float32)
    lum = arr.max(axis=2)
    alpha = np.clip((lum - 14) / 48, 0, 1)
    out = np.dstack([arr, alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")

def build_painted():
    if not SRC or not os.path.isdir(SRC):
        print("no source project given, skipping painted crops"); return
    img = os.path.join(SRC, "public", "images")
    ch = Image.open(os.path.join(img, "_sheet-characters.jpg")).convert("RGB")
    w, h = ch.size
    names = ["dawnbringer", "wanderer", "hollow_seer"]
    for i, n in enumerate(names):
        crop = ch.crop((i * w // 3, 0, (i + 1) * w // 3, h))
        keyed_img = keyed(crop); bb = keyed_img.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
        keyed_img = keyed_img.crop(bb)
        keyed_img.thumbnail((256, 340), Image.LANCZOS); keyed_img.save(os.path.join(A, "portraits", f"hero_{n}.png"))
        sp = keyed_img.copy(); sp.thumbnail((88, 120), Image.LANCZOS); sp.save(os.path.join(A, "sprites", f"player_{n}.png"))
        crop.resize((w // 3 // 2, h // 2), Image.LANCZOS).save(os.path.join(A, "portraits", f"card_{n}.jpg"), quality=86)
    rl = Image.open(os.path.join(img, "_sheet-relics.jpg")).convert("RGB"); rw, rh = rl.size
    rel = ["cold_iron_ring", "quill_of_incident", "puppeteers_thread", "silent_bell"]
    for i, n in enumerate(rel):
        x, y = (i % 2) * rw // 2, (i // 2) * rh // 2
        rl.crop((x + 40, y + 40, x + rw // 2 - 40, y + rh // 2 - 40)).resize((256, 256), Image.LANCZOS).save(os.path.join(A, "portraits", f"relic_{n}.jpg"), quality=88)
    bs = Image.open(os.path.join(img, "_sheet-bestiary.jpg")).convert("RGB"); bw, bh = bs.size
    bn = ["hound", "knight", "eye", "lamplighter", "gilded", "bell", "lamp_man", "spider", "crowned"]
    for i, n in enumerate(bn):
        x, y = (i % 3) * bw // 3, (i // 3) * bh // 3
        bs.crop((x + 22, y + 18, x + bw // 3 - 22, y + bh // 3 - 22)).resize((320, 213), Image.LANCZOS).save(os.path.join(A, "portraits", f"beast_{n}.jpg"), quality=86)
    # study room + key art backdrops
    for src, dst in (("study-room.jpg", "study_room.jpg"), ("warmaker-fight.jpg", "title_art.jpg")):
        p = os.path.join(img, src)
        if os.path.exists(p):
            im = Image.open(p).convert("RGB"); im.thumbnail((1280, 1280), Image.LANCZOS); im.save(os.path.join(A, "textures", dst), quality=82)
    cw = os.path.join(SRC, "artifacts", "source-sheets", "place-cinder-wold.jpg")
    if os.path.exists(cw):
        im = Image.open(cw).convert("RGB"); im.thumbnail((1280, 1280)); im.save(os.path.join(A, "textures", "place_cinder_wold.jpg"), quality=82)
    # actors (vector) - Godot imports SVG natively
    act = os.path.join(img, "actors")
    if os.path.isdir(act):
        os.makedirs(os.path.join(A, "sprites", "actors"), exist_ok=True)
        for f in os.listdir(act):
            shutil.copy(os.path.join(act, f), os.path.join(A, "sprites", "actors", f))
    # vfx sheet 4x4 -> frames
    vp = os.path.join(img, "_sheet-vfx.png")
    if os.path.exists(vp):
        v = Image.open(vp).convert("RGBA"); vw, vh = v.size; os.makedirs(os.path.join(A, "sprites", "vfx"), exist_ok=True)
        for r in range(4):
            for c in range(4):
                cell = v.crop((c * vw // 4, r * vh // 4, (c + 1) * vw // 4, (r + 1) * vh // 4)).convert("RGB")
                a = np.asarray(cell).astype(np.float32); lum = a.max(axis=2); alpha = np.clip((lum - 10) / 60, 0, 1)
                out = Image.fromarray(np.dstack([a, alpha * 255]).astype(np.uint8), "RGBA"); out.thumbnail((192, 192), Image.LANCZOS)
                out.save(os.path.join(A, "sprites", "vfx", f"vfx_{r * 4 + c:02d}.png"))

# tileable ground textures
def tile_noise(size, sigmas, weights, seed):
    rng = np.random.default_rng(seed); acc = np.zeros((size, size), np.float32)
    for s, w in zip(sigmas, weights):
        n = gaussian_filter(rng.random((size, size)).astype(np.float32), s, mode="wrap"); n = (n - n.min()) / (n.max() - n.min() + 1e-6); acc += n * w
    return acc / sum(weights)

PLACES = {
    "cinder_wold": ((38, 34, 32), (86, 70, 62), "#E0613A"),
    "drowned_stair": ((18, 34, 44), (52, 92, 110), "#6FD3E8"),
    "salt_seminary": ((52, 46, 62), (140, 128, 156), "#5E3A78"),
    "glass_verge": ((26, 30, 44), (104, 120, 160), "#B9A0E0"),
    "slow_orchard": ((26, 38, 24), (90, 122, 62), "#9BD94F"),
    "lantern_field": ((16, 14, 18), (54, 44, 36), "#F2C14E"),
}
def build_ground():
    for i, (pid, (c0, c1, _)) in enumerate(PLACES.items()):
        n = tile_noise(512, (3, 9, 28), (.3, .4, .6), 100 + i)
        fine = tile_noise(512, (1.2,), (1,), 200 + i)
        t = np.clip(n * .8 + fine * .2, 0, 1)[..., None]
        arr = np.array(c0) * (1 - t) + np.array(c1) * t
        if pid == "glass_verge":
            yy, xx = np.mgrid[0:512, 0:512]; cells = ((xx // 64 + yy // 64) % 2)[..., None]; arr = arr * (.85 + .15 * cells)
        if pid == "salt_seminary":
            grains = (np.random.default_rng(5).random((512, 512)) > .985)[..., None]; arr = np.clip(arr + grains * 90, 0, 255)
        Image.fromarray(arr.astype(np.uint8), "RGB").save(os.path.join(A, "textures", f"ground_{pid}.png"))

# UI frames
def build_ui():
    o = os.path.join(A, "ui")
    # nine-patch panel frame 96x96, margin 28
    s = 96; im = Image.new("RGBA", (s, s), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([1, 1, s - 2, s - 2], 14, fill=(12, 10, 16, 235), outline=(122, 98, 62, 255), width=2)
    d.rounded_rectangle([6, 6, s - 7, s - 7], 10, outline=(70, 56, 40, 220), width=1)
    for (x, y) in ((8, 8), (s - 9, 8), (8, s - 9), (s - 9, s - 9)):
        d.polygon([(x - 5, y), (x, y - 5), (x + 5, y), (x, y + 5)], fill=(190, 150, 80, 255))
    im.save(f"{o}/panel.png")
    # slot frames, one per rarity
    cols = {"common": (150, 150, 150), "uncommon": (110, 190, 120), "rare": (90, 150, 230), "epic": (170, 110, 220), "mythic": (240, 190, 80), "empty": (70, 66, 76)}
    for k, c in cols.items():
        im = Image.new("RGBA", (96, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
        d.rounded_rectangle([2, 2, 93, 93], 12, fill=(16, 14, 22, 235), outline=c + (255,), width=3)
        if k != "empty":
            d.rounded_rectangle([7, 7, 88, 88], 8, outline=c + (110,), width=1)
        im.save(f"{o}/slot_{k}.png")
    # divider ornament
    im = Image.new("RGBA", (512, 24), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for x0, x1 in ((10, 230), (282, 502)):
        d.line([(x0, 12), (x1, 12)], fill=(150, 120, 70, 220), width=2)
    d.polygon([(256, 2), (270, 12), (256, 22), (242, 12)], fill=(200, 160, 90, 255)); disc(d, 238, 12, 3, (200, 160, 90, 255)); disc(d, 274, 12, 3, (200, 160, 90, 255))
    im.save(f"{o}/divider.png")
    # sidebar tab backgrounds
    for k, c in (("tab", (24, 20, 30, 255)), ("tab_active", (62, 46, 30, 255))):
        im = Image.new("RGBA", (96, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
        d.rounded_rectangle([2, 2, 93, 93], 14, fill=c, outline=(150, 118, 70, 255) if "active" in k else (70, 60, 52, 255), width=2); im.save(f"{o}/{k}.png")
    # app icon
    ic = Image.new("RGBA", (256, 256), (14, 10, 20, 255)); d = ImageDraw.Draw(ic)
    ring(d, 128, 128, 112, 8, (180, 140, 80, 255)); ring(d, 128, 128, 84, 4, (130, 100, 60, 255))
    d.polygon(star_pts(128, 128, 90, 30, 4), fill=(220, 180, 100, 255)); d.polygon(star_pts(128, 128, 90, 30, 4, 0), fill=(220, 180, 100, 255)); disc(d, 128, 128, 20, (14, 10, 20, 255))
    ic.save(os.path.join(ROOT, "icon.png"))
    # fonts
    for f, n in (("/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf", "serif.ttf"), ("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", "serif_bold.ttf"),
                 ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "sans.ttf")):
        if os.path.exists(f): shutil.copy(f, os.path.join(A, "fonts", n))

if __name__ == "__main__":
    build_icons(); build_particles(); build_enemies(); build_painted(); build_ground(); build_ui()
    print("visuals done")
