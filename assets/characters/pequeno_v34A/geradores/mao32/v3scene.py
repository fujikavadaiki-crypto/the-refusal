import sys, os, json; sys.path.insert(0, '/tmp/claude-0/mao31')
import numpy as np
from PIL import Image
import v3poses as P
P_ = '/tmp/claude-0/prova/'; OUT = '/tmp/claude-0/mao31/out/'; TX = '/tmp/claude-0/proj/prova/c1_carrasco/tex/'
base = np.array(Image.open(P_ + 'r1_d_limpo.png').convert('RGB')); AXB = 187
MS = {a: m for a, (f, n, m, s) in P.ANIMS.items()}; N = {a: n for a, (f, n, m, s) in P.ANIMS.items()}
def _diff(path): f = np.array(Image.open(path).convert('RGB')); return f, np.abs(f.astype(int) - base.astype(int)).sum(2) > 0
SPS = {}
for pr in 'AB':
    for an in P.ANIMS:
        meta = json.load(open(TX + f'c52_v31{pr}_{an}_f0.json')); ex, ey = 185 - meta['ax'], 293 - meta['ay']
        for k in range(N[an]):
            f, d = _diff(P_ + f'r1_v31{pr}_{an}_{k}.png'); a = np.array(Image.open(TX + f'c52_v31{pr}_{an}_f{k}.png'))[..., 3] > 0; s = np.array(Image.open(TX + f'c52_v31{pr}_{an}_f{k}_fx.png'))[..., 3] > 0
            mm = np.zeros(d.shape, bool); h, w = a.shape; mm[ey:ey + h, ex:ex + w] = a | s; ys, xs = np.nonzero(d & mm); SPS[(pr, an, k)] = (ys, xs, f[ys, xs])
def paste(out, s, ax):
    ys, xs, col = s; nx = xs + (ax - 185); ok = (nx >= 0) & (nx < out.shape[1]) & (ys >= 0) & (ys < out.shape[0]); out[ys[ok], nx[ok]] = col[ok]
def save(ims, durs, name): ims[0].save(OUT + name, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=2)
Y0, Y1 = 168, 318
def crop(o, x0, x1): return Image.fromarray(o[Y0:Y1, x0:x1])
def seq(an):
    if an == 'jump': return [('jump_up', 0), ('jump_up', 1), ('fall_start', 0), ('fall_start', 1)] + [('fall_loop', k % 3) for k in range(6)] + [('land', 0), ('land', 1)]
    return [(an, k) for k in range(N[an])]
for an in ('idle', 'run', 'heavy', 'dash', 'dash_ar', 'jump', 'hurt'):
    ims = []; durs = []; sq = seq(an) * (3 if an == 'run' else 1)
    for i, (a2, k) in enumerate(sq):
        o = base.copy(); sh = 0
        if an == 'run': sh = 8 * i
        if an in ('dash', 'dash_ar'): sh = int(round(0.32 * sum(MS[an][:i])))
        gap = 120 if an in ('heavy',) else 90
        paste(o, SPS[('A', a2, k)], 90 + sh); paste(o, SPS[('B', a2, k)], 90 + gap + 40 + sh + (40 if an == 'heavy' else 0))
        ims.append(crop(o, 20, 470)); ms = MS[a2][k]; durs.append(int(max(round(ms / 10.0) * 10, 20)))
    if an == 'run': durs = [50, 60] * 9
    if an in ('heavy', 'hurt', 'jump', 'dash', 'dash_ar'): durs[-1] += 350
    save(ims, durs, f'V31_{an}_AxB_cena_1x.gif'); ims[min(2, len(ims) - 1)].save(OUT + f'V31_{an}_AxB_cena_quadro.png')
print('ok')
