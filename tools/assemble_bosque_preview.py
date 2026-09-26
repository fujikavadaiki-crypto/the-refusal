"""Package engine-rendered traversal frames as four small review clips."""

from pathlib import Path
from PIL import Image
import sys

frames_dir = Path(sys.argv[1])
output_dir = Path(sys.argv[2])
output_dir.mkdir(parents=True, exist_ok=True)
for section in range(1, 5):
    files = sorted(frames_dir.glob(f"section_{section}_*.png"))
    if not files:
        raise SystemExit(f"No rendered frames for section {section}")
    frames = []
    for file in files:
        image = Image.open(file).convert("RGB")
        image = image.resize((640, 360), Image.Resampling.LANCZOS)
        frames.append(image.quantize(colors=192, method=Image.Quantize.FASTOCTREE))
    destination = output_dir / f"bosque_movimento_trecho_{section}.gif"
    frames[0].save(destination, save_all=True, append_images=frames[1:],
                   duration=83, loop=0, optimize=False, disposal=2)
    print(destination, len(files), destination.stat().st_size)
