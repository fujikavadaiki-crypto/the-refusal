import sys, os, json; sys.path.insert(0, '/tmp/claude-0/mao31')
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import v3poses as P
OUT = '/tmp/claude-0/mao31/out/'; os.makedirs(OUT, exist_ok=True); PK = {pr: f'/tmp/claude-0/p31pack/pacote_pequeno_v31{pr}/' for pr in 'AB'}
BG = (112, 112, 112); SC = 4
try: FONT = ImageFont.load_default(size=18)
except TypeError: FONT = ImageFont.load_default()
MAN = {pr: json.load(open(PK[pr] + 'manifesto_sprites.json')) for pr in 'AB'}
def L(p): return np.array(Image.open(p).convert('RGBA'))
def comp(pr, an, k):
    a = [x for x in MAN[pr]['animacoes'] if x['id'] == an][0]; q = a['quadros'][k]; b = L(PK[pr] + q['arquivo']); s = L(PK[pr] + q['sombra']['arquivo'])
    fx = [e for e in a['efeitos'] if e['quadro'] == k]; f = L(PK[pr] + fx[0]['arquivo']) if fx else None
    return b, s, f, tuple(q['ancora'])
def draw(c, im, ox, oy):
    ys, xs = np.nonzero(im[..., 3] > 0); ny, nx = ys + oy, xs + ox; ok = (ny >= 0) & (ny < c.shape[0]) & (nx >= 0) & (nx < c.shape[1]); c[ny[ok], nx[ok]] = im[ys[ok], xs[ok], :3]
def tile(pr, an, k, W_, H_, gy, cx, dx=0):
    c = np.zeros((H_, W_, 3), np.uint8); c[:] = BG; c[gy + 2:, :] = (96, 96, 96); b, s, f, (ax, ay) = comp(pr, an, k); ox = cx - ax + dx; oy = gy - ay
    draw(c, s, ox, oy)
    if f is not None: draw(c, f, ox, oy)
    draw(c, b, ox, oy); return c
def save(ims, durs, name): ims[0].save(OUT + name, save_all=True, append_images=ims[1:], duration=durs, loop=0, disposal=2)
def seq(an):
    if an == 'jump': return [('jump_up', 0), ('jump_up', 1), ('fall_start', 0), ('fall_start', 1), ('fall_loop', 0), ('fall_loop', 1), ('fall_loop', 2), ('fall_loop', 0), ('fall_loop', 1), ('fall_loop', 2), ('land', 0), ('land', 1)]
    n = len([a for a in MAN['A']['animacoes'] if a['id'] == an][0]['quadros']); return [(an, k) for k in range(n)]
MS = {a: m for a, (f, n, m, s) in P.ANIMS.items()}
def gif_an(an, W_=104, H_=96, gy=84, move=0):
    ims = []; durs = []
    for i, (a2, k) in enumerate(seq(an)):
        ta = tile('A', a2, k, W_, H_, gy, W_ // 2, move * i if move else 0); tb = tile('B', a2, k, W_, H_, gy, W_ // 2, move * i if move else 0)
        c = np.concatenate([ta, tb], 1); im = Image.fromarray(np.kron(c, np.ones((SC, SC, 1), np.uint8))); d = ImageDraw.Draw(im)
        d.text((10, 6), f'A  cabeca 31 %  {an}', fill=(235, 235, 235), font=FONT); d.text((W_ * SC + 10, 6), f'B  cabeca 42 %  {an}', fill=(235, 235, 235), font=FONT)
        ims.append(im); durs.append(int(max(round(MS[a2][k] / 10.0) * 10, 20)))
    if an in ('heavy', 'hurt', 'jump', 'dash', 'dash_ar'): durs[-1] += 350
    save(ims, durs, f'V31_{an}_AxB_x4.gif'); ims[min(2, len(ims) - 1)].save(OUT + f'V31_{an}_AxB_x4_quadro.png')
for an, kw in (('idle', {}), ('run', {}), ('heavy', dict(W_=150, H_=118, gy=108)), ('dash', {}), ('dash_ar', {}), ('jump', {}), ('hurt', {})): gif_an(an, **kw)
# tiras x2 por proporcao
for pr in 'AB':
    rows = []
    for an in P.ANIMS:
        n = len([a for a in MAN[pr]['animacoes'] if a['id'] == an][0]['quadros']); tiles = [tile(pr, an, k, *((150, 118, 108, 75) if an == 'heavy' else (96, 100, 90, 40))) for k in range(n)]; rows.append(np.concatenate(tiles, 1))
    Wd = max(r.shape[1] for r in rows); rows = [np.pad(r, ((0, 0), (0, Wd - r.shape[1]), (0, 0)), constant_values=112) for r in rows]
    Image.fromarray(np.kron(np.concatenate(rows, 0), np.ones((2, 2, 1), np.uint8))).save(OUT + f'V31{pr}_tira_x2.png')
print('ok', sorted(os.listdir(OUT)))
