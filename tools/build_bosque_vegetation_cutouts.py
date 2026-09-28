"""Trace only flexible foliage tips and hanging strands from Bosque B."""

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/biomes/forest/approved/bosque_b.jpg"
DEST = ROOT / "assets/biomes/forest/approved/layers/vegetation_cutouts"

# Each contour is placed by hand in source-image pixels. Pivots mark a branch or
# the top attachment of moss/vines. The source JPEG is never modified.
REGIONS = [
    ("arch_leaf_left_tip", "canopy", (80, 149), [(58,138),(63,129),(71,126),(80,133),(82,143),(78,150),(68,148)], 0.55, 0.92),
    ("arch_leaf_right_tip", "canopy", (206, 153), [(204,140),(211,130),(222,131),(231,141),(233,153),(223,158),(213,153)], 0.55, 0.92),
    ("tree_leaf_left_tip", "canopy", (352, 283), [(331,268),(335,258),(346,257),(356,265),(355,281),(347,286)], 0.55, 0.92),
    ("tree_leaf_top_tip", "canopy", (396, 244), [(382,236),(386,223),(395,221),(405,230),(406,239),(399,245)], 0.55, 0.92),
    ("tree_leaf_right_tip", "canopy", (438, 288), [(437,273),(446,265),(458,267),(464,278),(459,290),(447,293)], 0.55, 0.92),
    ("far_tree_left_tip", "canopy", (1676, 254), [(1653,241),(1658,229),(1669,226),(1680,236),(1681,251),(1672,255)], 0.55, 0.90),
    ("far_tree_top_tip", "canopy", (1740, 194), [(1728,186),(1731,172),(1741,168),(1751,176),(1753,189),(1744,196)], 0.55, 0.90),
    ("far_tree_right_tip", "canopy", (1800, 244), [(1799,228),(1808,218),(1819,219),(1826,230),(1821,242),(1810,247)], 0.55, 0.90),
    ("arch_vine_center_tail", "vine", (148, 190), [(145,189),(151,189),(151,210),(149,234),(148,255),(145,248),(144,221)], 0.40, 0.90),
    ("arch_vine_right_tail", "vine", (165, 176), [(162,175),(168,175),(170,192),(169,215),(166,226),(163,217),(162,196)], 0.40, 0.90),
    ("trunk_vine_tail", "vine", (781, 169), [(778,168),(784,168),(785,185),(782,210),(779,208),(777,187)], 0.40, 0.89),
    ("entrance_moss_tip", "moss", (221, 332), [(216,332),(226,332),(228,341),(225,354),(221,360),(218,350)], 0.45, 0.90),
    ("early_edge_moss_tip", "moss", (484, 418), [(480,418),(490,418),(490,427),(485,440),(481,435)], 0.45, 0.90),
    ("floating_moss_left_tip", "moss", (732, 333), [(728,333),(736,333),(737,344),(733,361),(730,358),(728,345)], 0.45, 0.92),
    ("floating_moss_middle_tip", "moss", (758, 334), [(754,334),(762,334),(762,344),(759,354),(756,351)], 0.45, 0.92),
    ("floating_moss_right_tip", "moss", (807, 333), [(803,332),(811,332),(811,343),(808,354),(805,351)], 0.45, 0.92),
    ("waterfall_moss_tip", "moss", (1509, 419), [(1505,419),(1514,419),(1514,428),(1510,440),(1507,438)], 0.45, 0.90),
    ("right_ledge_moss_tip", "moss", (1807, 295), [(1802,295),(1812,295),(1811,304),(1808,318),(1805,315)], 0.45, 0.90),
    ("near_leaf_left_tip", "near", (162, 43), [(152,48),(157,39),(167,38),(174,47),(171,61),(163,67),(156,59)], 0.55, 0.83),
    ("near_leaf_mid_tip", "near", (940, 43), [(930,48),(934,39),(944,38),(952,47),(949,60),(941,66),(935,59)], 0.55, 0.83),
]


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = []
    for name, group, pivot, polygon, feather, opacity in REGIONS:
        left = max(0, min(p[0] for p in polygon) - 5)
        top = max(0, min(p[1] for p in polygon) - 5)
        right = min(source.width, max(p[0] for p in polygon) + 6)
        bottom = min(source.height, max(p[1] for p in polygon) + 6)
        box = (left, top, right, bottom)
        mask = Image.new("L", (right-left, bottom-top))
        draw = ImageDraw.Draw(mask)
        draw.polygon([(x-left, y-top) for x,y in polygon], fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(feather))
        pixels = mask.load()
        maximum = max(math.hypot(x-pivot[0], y-pivot[1]) for x,y in polygon)
        for py in range(bottom-top):
            for px in range(right-left):
                distance = math.hypot(left+px-pivot[0], top+py-pivot[1]) / maximum
                tip_weight = min(1.0, max(0.0, (distance-0.08)/0.92))
                tip_weight = tip_weight * tip_weight * (3.0-2.0*tip_weight)
                pixels[px,py] = round(pixels[px,py] * opacity * tip_weight)
        cutout = source.crop(box).convert("RGBA")
        cutout.putalpha(mask)
        cutout.save(DEST / f"{name}.png", optimize=True)
        manifest.append({"name":name, "group":group, "pivot":list(pivot), "box":list(box)})
    (DEST / "regions.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Created {len(manifest)} manually traced overlays from {SOURCE.name}")


if __name__ == "__main__":
    main()
