import sys; sys.path.insert(0, '/tmp/claude-0/p41'); sys.path.insert(0, '/tmp/claude-0/proj/prova/c1_carrasco/geradores')
import numpy as np
from PIL import Image, ImageDraw
import v4anim as A, v4rig as R
from c51_lib import PAL
def comp(sp, pr='A'):
    b, f, i = A.render4(sp, pr); m = b.copy(); z = (m < 0) & (f >= 0); m[z] = f[z]; return m, i
def sheet(seqs, name, S=3, per_row=8, margin=3, box=None, labels=None, bg=(112, 112, 112), upto=None):
    """seqs: lista de dicts de pose; desenha em grade com legenda do indice."""
    ms = [comp(sp)[0] for sp in seqs]
    ys = [np.nonzero((m >= 0).any(1))[0] for m in ms]; xs = [np.nonzero((m >= 0).any(0))[0] for m in ms]
    if box is None:
        x0 = min(x.min() for x in xs) - margin; x1 = max(x.max() for x in xs) + margin; y0 = min(y.min() for y in ys) - margin; y1 = max(R.GR + 3, max(y.max() for y in ys) + margin)
        x0 = max(x0, 0); y0 = max(y0, 0)
    else: x0, y0, x1, y1 = box
    tiles = []
    for k, m in enumerate(ms):
        c = m[y0:y1, x0:x1]; o = np.zeros(c.shape + (3,), np.uint8); o[:] = bg; gy = R.GR + 1 - y0
        if 0 <= gy < o.shape[0]: o[gy:] = (96, 96, 96)
        a = c >= 0; o[a] = PAL[c[a]]; im = Image.fromarray(np.kron(o, np.ones((S, S, 1), np.uint8))); d = ImageDraw.Draw(im); d.text((3, 2), (labels[k] if labels else str(k)), fill=(255, 255, 200)); tiles.append(np.array(im))
    h, w = tiles[0].shape[:2]; rows = []
    for r in range(0, len(tiles), per_row):
        row = tiles[r:r + per_row]
        while len(row) < per_row: row.append(np.full((h, w, 3), 112, np.uint8))
        rows.append(np.concatenate(row, 1))
    Image.fromarray(np.concatenate(rows, 0)).save(name); return (x0, y0, x1, y1)
