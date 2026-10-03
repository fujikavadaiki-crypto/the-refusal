"""render4: render do rig v3.1 + extensoes v4 (brilho da lamina, lente de estocada, poeira/faiscas por extras, capa com atraso de 1 quadro)."""
import sys; sys.path.insert(0, '/tmp/claude-0/p41')
import numpy as np, math
from PIL import Image, ImageDraw
import v4rig as R, v4anim_base as B
from v4rig import BX, BY, GR, H, W, XX, YY, ST8
from scipy import ndimage as ndi
GLOW = {1: {16: 22, 18: 27}, 2: {16: 26, 18: 31, 14: 22}, 3: {16: 41, 14: 26, 18: 18}}
DITH = {1: False, 2: True, 3: False}
def poly_mask(poly):
    im = Image.new('L', (W, H), 0); ImageDraw.Draw(im).polygon([tuple(p) for p in poly], fill=255); return np.array(im) > 0
def lens3(x0, x1, y, tmax, bx, byy, power=0.7, peak=0.55):
    """ARCO RETO (estocada): lente horizontal em 3 faixas (borda cinza-clara 16 / marrom 10-8 / interior quase preto 5) + filete vermelho 22.
    x0..x1, y locais; tmax = espessura maxima (px); pico em `peak` (0..1) a partir de x0."""
    ys, xs = YY, XX; t = (xs + .5 - (bx + x0)) / float(x1 - x0)
    tt = np.clip(t, 0, 1)
    prof = np.where(tt < peak, np.sin(0.5 * np.pi * np.abs(tt / peak) ** power), np.cos(0.5 * np.pi * np.abs((tt - peak) / (1 - peak)) ** 1.6))
    half = 0.5 * tmax * np.clip(prof, 0, 1)
    d = np.abs(ys + .5 - (byy + y)); ins = (t >= 0) & (t <= 1) & (d <= half) & (half > 0.6)
    out = -np.ones((H, W), int); fr = d / np.maximum(half, 1e-6)
    out[ins & (fr < .45)] = 5; out[ins & (fr >= .45)] = 8; out[ins & (fr >= .70)] = 10
    fil = ins & (half > 2.2) & (np.abs(fr - .45) < max(.5 / max(tmax / 2, 1), .06)); out[fil] = 22
    out[ins & (half - d < 1.4)] = 16
    thin = ins & (half < 2.4); out[thin & ((XX + YY) % 2 == 1)] = -1
    hl = ins & (half - d < 1.4) & (half > 4) & (t > .3) & (t < .7) & ((XX % 3) == 0); out[hl] = 18
    ts = np.linspace(0, 1, 16); hf = lambda q: 0.5 * tmax * (np.sin(0.5 * np.pi * (q / peak) ** power) if q < peak else np.cos(0.5 * np.pi * ((q - peak) / (1 - peak)) ** 1.6))
    top = [(bx + x0 + (x1 - x0) * q, byy + y - hf(q) - 1) for q in ts]; bot = [(bx + x0 + (x1 - x0) * q, byy + y + hf(q) + 1) for q in ts[::-1]]
    return out, top + bot
def render4(sp, pr='A'):
    """-> (body, fx, info). Glow/lente/halo entram aqui; arco, extras e capa vem do renderer base."""
    sp = dict(sp)
    th = sp.pop('thrust', None); glow = sp.pop('glow', 0)
    b, f, info = B.render(sp, pr)
    bx = BX + sp.get('dx', 0); byy = BY + sp.get('dy', 0)
    if glow:
        bm = poly_mask(info['blade_poly']); bm = ndi.binary_dilation(bm, structure=ST8)
        for src, dst in GLOW[glow].items():
            sel = bm & (b == src)
            if src == 14 and DITH[glow]: sel &= (((XX + YY) % 2) == 0)
            b[sel] = dst
        r1 = ndi.binary_dilation(bm, structure=ST8) & ~bm & (b < 0) & (f < 0); r2 = ndi.binary_dilation(bm, structure=ST8, iterations=2) & ~ndi.binary_dilation(bm, structure=ST8) & (b < 0) & (f < 0)
        f[r1] = (19, 22, 26)[glow - 1]
        if glow >= 3: f[r2 & (((XX + YY) % 2) == 1)] = 22
    if th:
        x0, x1, y, tm = th[:4]; o, poly = lens3(x0, x1, y, tm, bx, byy, *th[4:]); f[o >= 0] = o[o >= 0]; info['thrust_poly'] = poly
        if not sp.get('nofloor'): f[GR + 1:, :] = -1
    return b, f, info
def lagcape(seq, prev=None, loop=False):
    """capa SEMPRE viva: o movimento da capa de cada quadro vem do quadro ANTERIOR (atraso de 1 quadro em relacao ao corpo).
    seq = lista de dicts de pose; prev = pose anterior (acao anterior) ou None; loop = o primeiro usa o ultimo."""
    out = []
    for k, sp in enumerate(seq):
        sp = dict(sp); src = seq[k - 1] if k > 0 else (prev if prev is not None else (seq[-1] if loop else None))
        if src is not None:
            for key in ('trail', 'lift', 'flap', 'ph', 'cape_len', 'chute', 'chute_ph', 'chute_dx'):
                if key in src: sp[key] = src[key]
                elif key in sp and key in ('chute', 'chute_ph', 'chute_dx'): del sp[key]
        out.append(sp)
    return out
