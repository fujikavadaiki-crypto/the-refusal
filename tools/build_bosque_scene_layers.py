"""Separate the approved Bosque panels into game layers without replacing their art."""

from pathlib import Path
from PIL import Image
import numpy as np
import math

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/biomes/forest/approved"
OUT = SOURCE / "layers"
OUT.mkdir(exist_ok=True)

# Same world-space ledge coordinates as forest_slice_01.gd. The PNGs are derived
# from the untouched official panels; only their transparency and depth differ.
SURFACES = [
    [(0,180),(130,183),(200,196),(270,215),(360,225),(500,230),(580,235),(615,225),(660,205),(730,203),(800,211),(860,226),(940,238),(1040,242),(1120,240),(1170,237)],
    [(1200,162),(1250,163),(1300,165),(1430,168),(1470,170),(1510,195),(1580,216),(1690,226),(1820,231),(1960,233),(2110,242),(2290,249),(2390,247)],
    [(2500,164),(2600,165),(2730,192),(2870,209),(3000,218),(3140,226),(3300,222),(3450,222),(3540,231),(3600,242),(3675,242)],
    [(3800,160),(3850,158),(3900,158)],
]
WORLD_SCALE_X = 1300 / 1900
WORLD_SCALE_Y = 433 / 633
WORLD_TOP = -45


def surface_at(x):
    for points in SURFACES:
        if points[0][0] <= x <= points[-1][0]:
            for (ax, ay), (bx, by) in zip(points, points[1:]):
                if ax <= x <= bx:
                    return ay + (by-ay)*(x-ax)/(bx-ax)
    return None


def make_layers(letter, panel_index):
    source = Image.open(SOURCE / f"bosque_{letter}.jpg").convert("RGB")
    width, height = source.size
    mid_alpha = Image.new("L", source.size, 0)
    near_alpha = Image.new("L", source.size, 0)
    ground_alpha = Image.new("L", source.size, 0)
    canopy_alpha = Image.new("L", source.size, 0)
    mid_px = mid_alpha.load()
    near_px = near_alpha.load()
    ground_px = ground_alpha.load()
    canopy_px = canopy_alpha.load()
    for px in range(width):
        world_x = panel_index*1300 + px*WORLD_SCALE_X
        surface = surface_at(world_x)
        top = (surface - WORLD_TOP) / WORLD_SCALE_Y if surface is not None else height + 90
        for py in range(height):
            if surface is not None:
                # The real floor is a fixed game-world element with the same
                # boundary as its collision. An overlap hides mask seams.
                ground_px[px, py] = max(0, min(255, int((py-(top-20))*20)))
            # Select depth from the *content*, not a horizontal slice. Dark
            # trees, stone and roots stay fixed; pale distance and haze move.
            # A smooth vertical bias keeps the whole walkable area attached.
            r,g,b = source.getpixel((px,py))
            luminance = (r*0.25 + g*0.55 + b*0.20)
            depth = max(0.0, min(1.0, (py-215.0)/175.0))
            close = max(depth, max(0.0, min(1.0, (132.0-luminance)/82.0)))
            distant = (1.0-depth) * max(0.0, min(1.0, (luminance-105.0)/100.0))
            near_px[px, py] = int(255 * close)
            mid_px[px, py] = int(255 * (1.0-close) * (1.0-distant))
            if py < 63:
                darkness = max(0, 74 - (r+g+b)//3)
                canopy_px[px,py] = min(115, int(darkness*1.4))
    # Keep the painted composition in the mobile mid plane, with atmospheric
    # fill behind it. No newly generated scenery or character pixels.
    source.save(OUT / f"{letter}_far.png")
    for suffix, alpha in [("middle",mid_alpha),("near",near_alpha),("ground",ground_alpha),("canopy",canopy_alpha)]:
        image = source.convert("RGBA")
        image.putalpha(alpha)
        pixels = np.asarray(image).copy()
        pixels[pixels[:, :, 3] == 0, :3] = 0
        image = Image.fromarray(pixels, "RGBA")
        image.save(OUT / f"{letter}_{suffix}.png")


for letter, index in [("a",0),("b",1),("c",2)]:
    make_layers(letter,index)

# Small, isolated volumes avoid the rectangular bands of a repeating ribbon.
# Both axes fall smoothly to true zero alpha at the texture boundary.
mist = Image.new("RGBA", (180, 62), (0,0,0,0))
mist_alpha = Image.new("L", mist.size, 0)
alpha_pixels = mist_alpha.load()
for y in range(mist.height):
    for x in range(mist.width):
        a = math.exp(-(((x-65)/45)**2 + ((y-32)/15)**2)*2)
        b = math.exp(-(((x-112)/39)**2 + ((y-29)/12)**2)*2)
        taper = math.sin(math.pi*x/(mist.width-1))**2 * math.sin(math.pi*y/(mist.height-1))**2
        alpha_pixels[x,y] = int(17 * max(a,b) * taper)
mist = Image.new("RGBA", mist.size, (146,163,160,0))
mist.putalpha(mist_alpha)
mist.save(OUT / "fog_puff.png")
