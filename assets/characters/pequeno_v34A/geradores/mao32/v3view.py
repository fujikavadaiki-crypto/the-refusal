import sys; sys.path.insert(0, '/tmp/claude-0/mao'); sys.path.insert(0, '/tmp/claude-0/mao2')
import numpy as np
from PIL import Image
import mao_view as MV
import v2rig as R
def strip(frames, S=5, box=(24, 30, 100, 96)):
    x0, y0, x1, y1 = box
    ims = [MV.show(f[y0:y1, x0:x1], S) for f in frames]; w = sum(i.width for i in ims); o = Image.new('RGB', (w, ims[0].height))
    x = 0
    for i in ims: o.paste(i, (x, 0)); x += i.width
    return o
