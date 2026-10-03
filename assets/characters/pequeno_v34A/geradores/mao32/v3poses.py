import math
# pontos em coordenadas locais normalizadas (x: centro do tronco = 15; y: topo do capuz = 0, sola = 47). ombro vem da proporcao.
IDLE_MS = [330, 280, 280, 330, 280, 280, 220]
def idle(k):
    up = [0, 0, 1, 1, 1, 0, 0][k]; sw = [0, 0, 1, 1, 0, -1, -1][k]
    tr = [2, 1, 1, 2, 3, 3, 2][k]; lift = [0, 0, 0, 1, 2, 1, 0][k]; hy = [0, 0, 0, 1, 1, 0, 0][k]     # a capa atrasa 1 quadro em relacao ao peito
    return dict(up=up, lean=[0, 0, 0, 1, 1, 0, 0][k], sway=sw, trail=tr, lift=lift, flap=1, ph=k * .9, hy=hy,
                far=(23, 40, 'FL'), near=(13, 40, 'FL'), blade=dict(p0=(18, 30), p1=(43, 46)), arm=[(11, 26), (18, 31 - (1 if k in (3, 4) else 0))])
# ---------------- CORRIDA 6 q, 8 px/quadro, 55,56 ms (144 px/s)
RUN_PX = 8; RUN_MS = 1000.0 * 8 / 144; RUN_N = 6
PH6 = [(24, 41, 'UP'), (16, 40, 'FL'), (6, 36, 'TK'), (9, 33, 'TK'), (20, 36, 'TK'), (25, 39, 'UP')]
DY6 = [0, 3, -2, 0, 3, -2]
def run(k):
    fl = (k % 3 == 2); low = (k % 3 == 1)
    h = (18, 31 + (1 if low else 0) - (2 if fl else 0))
    tr = [9, 8, 11, 9, 8, 11][k]; lift = [1, 0, 3, 1, 0, 3][k]       # capa: estica no voo, assenta no apoio baixo
    return dict(dy=DY6[k], lean=[3, 4, 2, 3, 4, 2][k], hy=[0, 1, -1, 0, 1, -1][k], sway=-1 if k % 2 else 0, trail=tr, lift=lift, flap=2, ph=k * 1.7,
                near=PH6[k], far=PH6[(k + 3) % 6], blade=dict(p0=(h[0], h[1] - 4), p1=(h[0] + 30, h[1] - 4 + (-9 if fl else (-4 if k % 3 == 0 else -6)))),
                arm=[(12, 25), (h[0], h[1] - 2)])
# ---------------- DASH (chao) 3 q, 350 ms; DASH NO AR 3 q   (v3.1: pose esticada + capa arrastando; 1-3 quadros)
DASH_MS = [90, 170, 90]
def _speed(k, n):
    ex = []
    for j, (yy, ln) in enumerate(((13, 11), (21, 15), (29, 9), (37, 13), (43, 8))):
        for t in range(ln): ex.append((-8 - t - (k * 3) % 6 - 4 * (j % 2), yy + (k % 2) * (1 if j % 2 else -1), 14 if t > 2 else 16))
    return ex if n else []
def dash(k):
    near = [(28, 40, 'UP'), (3, 40, 'DN'), (17, 40, 'FL')][k]; far = [(3, 40, 'DN'), (24, 38, 'TK'), (24, 40, 'FL')][k]
    lean = [8, 10, 4][k]; dy = [3, 4, 2][k]; tr = [19, 27, 11][k]; st = k < 2
    return dict(dy=dy, lean=lean, hx=1 if st else 0, trail=tr, lift=[0, -1, 1][k], flap=1, ph=k, near=near, far=far, sway=-2 if st else 0, cape_len=[1, 3, 0][k],
                blade=dict(p0=(15, 27), p1=(-14, 33)) if st else dict(p0=(17, 29), p1=(40, 45)), arm=[(9, 24), (15, 27)] if st else [(11, 26), (17, 29)],
                extra=_speed(k, st))
def dash_air(k):
    s = dash(k); tk = [(10, 34, 'TK'), (6, 35, 'TK'), (14, 36, 'TK')][k]; tf = [(17, 36, 'TK'), (14, 37, 'TK'), (21, 37, 'TK')][k]
    s.update(near=tk, far=tf, dy=[0, 0, 0][k], lean=[9, 11, 5][k]); return s
# ---------------- PULO: subida 2 + queda inicio 2 + queda laco 3 + pouso 2
JUMPUP_MS = [60, 80]; FALLS_MS = [70, 70]; FALLL_MS = [90, 90, 90]; LAND_MS = [50, 70]
def jump_up(k):
    if k == 0: return dict(dy=-2, lean=1, hy=-1, trail=0, lift=-2, flap=1, ph=0, near=(14, 41, 'DN'), far=(19, 40, 'DN'), blade=dict(p0=(19, 24), p1=(43, 8)), arm=[(12, 20), (19, 24)], cape_len=3)   # esticado; capa fica para baixo
    return dict(dy=-3, lean=2, hy=-1, trail=2, lift=-1, flap=2, ph=1, near=(14, 34, 'TK'), far=(22, 33, 'TK'), blade=dict(p0=(19, 24), p1=(47, 14)), arm=[(12, 21), (19, 24)], cape_len=1)
def fall_start(k):
    if k == 0: return dict(dy=-3, lean=1, hy=-1, trail=2, lift=2, flap=3, ph=2, near=(15, 36, 'TK'), far=(23, 35, 'TK'), blade=dict(p0=(19, 25), p1=(48, 23)), arm=[(12, 21), (19, 25)])
    return dict(dy=-2, lean=2, trail=1, lift=5, flap=3, ph=3, near=(13, 38, 'DN'), far=(24, 37, 'TK'), blade=dict(p0=(19, 26), p1=(42, 44)), arm=[(11, 22), (19, 26)], cape_len=-2, chute=0.55, chute_ph=1.0)
def fall_loop(k):
    c = [(13, 38, 'DN'), (14, 39, 'TK'), (12, 37, 'DN')][k]; f = [(24, 37, 'TK'), (23, 38, 'DN'), (25, 36, 'TK')][k]
    return dict(dy=-1 + (k == 1), lean=2, trail=[1, 2, 1][k], lift=[6, 4, 7][k], flap=3, ph=4 + 2 * k, near=c, far=f,
                blade=dict(p0=(19, 26), p1=(41 + k, 44 - k)), arm=[(11, 21 + (k == 1)), (19, 26)], chute=[1.0, 0.86, 1.12][k], chute_ph=2.1 * k)
def land(k):
    if k == 0: return dict(dy=5, lean=3, trail=5, lift=-2, flap=1, ph=0, near=(12, 40, 'FL'), far=(26, 40, 'FL'), blade=dict(p0=(18, 34), p1=(42, 46)), arm=[(11, 28), (18, 34)], cape_len=2)
    return dict(dy=2, lean=1, trail=2, lift=1, flap=1, ph=1, near=(13, 40, 'FL'), far=(23, 40, 'FL'), blade=dict(p0=(18, 31), p1=(43, 46)), arm=[(11, 26), (18, 31)])
# ---------------- HURT 3 q
HURT_MS = [60, 60, 60]
def hurt(k):
    ex = [(25 + 2 * i, 18 - i * 2 + (k % 2), 22) for i in range(4)] + [(31, 14 - k, 22), (28, 20 + k, 19), (34, 17, 22)] if k < 2 else [(26, 22, 22), (29, 26, 19)]
    return [dict(dy=-1, lean=-6, hx=-2, trail=-3, lift=1, flap=2, ph=0, near=(8, 40, 'DN'), far=(21, 40, 'UP'), blade=dict(p0=(9, 31), p1=(30, 45)), arm=[(5, 25), (8, 30)], extra=ex),
            dict(dy=0, lean=-8, hx=-3, hy=1, trail=-4, lift=2, flap=2, ph=1, near=(7, 40, 'DN'), far=(20, 40, 'FL'), blade=dict(p0=(8, 33), p1=(28, 46)), arm=[(4, 26), (7, 32)], extra=ex),
            dict(dy=1, lean=-3, hx=-1, trail=2, lift=0, flap=1, ph=2, near=(11, 40, 'FL'), far=(22, 40, 'FL'), blade=dict(p0=(14, 31), p1=(37, 46)), arm=[(9, 27), (14, 31)], extra=ex)][k]
# ---------------- GOLPE PESADO v3.1 (receita do machado): PREP 4 q (320 ms) + ARCO GIGANTE 2 q (140 ms) + PARADO COM A LAMINA NO CHAO 3 q (430 ms) = 890 ms
HEAVY_MS = [80, 80, 80, 80, 70, 70, 150, 140, 140]; HEAVY_ACTIVE = [4, 5]
ARC_P = (20, 12); ARC_R = 62
def heavy(k):
    if k == 0: return dict(dy=1, lean=-1, trail=3, lift=0, flap=1, ph=0, near=(13, 40, 'FL'), far=(24, 40, 'FL'), blade=dict(p0=(18, 27), p1=(46, 13)), arm=[(12, 24), (18, 27)])
    if k == 1: return dict(dy=2, lean=-3, trail=4, lift=-1, flap=1, ph=1, near=(12, 40, 'FL'), far=(25, 40, 'FL'), blade=dict(p0=(12, 16), p1=(26, -11)), arm=[(7, 19), (12, 16)])
    if k == 2: return dict(dy=3, lean=-3, trail=2, lift=-1, flap=1, ph=2, near=(12, 40, 'FL'), far=(25, 40, 'FL'), blade=dict(p0=(8, 8), p1=(-12, -15)), arm=[(5, 13), (8, 8)])
    if k == 3: return dict(dy=4, lean=-6, hx=-2, trail=5, lift=-1, flap=1, ph=3, near=(9, 40, 'FL'), far=(24, 40, 'FL'), blade=dict(p0=(2, 4), p1=(-24, -12)), arm=[(2, 12), (2, 5)])
    if k == 4: return dict(dy=0, lean=7, trail=15, lift=1, flap=2, ph=4, near=(22, 40, 'FL'), far=(4, 40, 'DN'), blade=dict(p0=(27, 12), p1=(52, 29)), arm=[(21, 22), (27, 12)],
                           arc=(ARC_P, ARC_R, -170, 24, 30, .85))
    if k == 5: return dict(dy=4, lean=6, trail=11, lift=2, flap=2, ph=5, near=(24, 40, 'FL'), far=(3, 40, 'DN'), blade=dict(p0=(27, 24), p1=(53, 45), blood=[(46, 41), (48, 42), (44, 40)], bz=.4),
                           arm=[(21, 26), (27, 24)], arc=(ARC_P, ARC_R, -104, 46, 13, 1.7),
                           extra=[(54, 44, 18), (56, 41, 18), (52, 42, 16), (57, 45, 16), (55, 47, 22), (53, 46, 22), (58, 43, 22), (51, 45, 18)])
    base = dict(dy=4, lean=3, hy=0, flap=1, near=(22, 40, 'FL'), far=(5, 40, 'DN'), blade=dict(p0=(26, 24), p1=(52, 44), blood=[(46, 40), (48, 41), (44, 39)], bz=.4), arm=[(19, 22), (26, 24)])
    if k == 6: base.update(trail=3, lift=3, ph=6, extra=[(53, 46, 22), (51, 47, 22), (55, 47, 19), (57, 46, 22), (48, 47, 19)])
    if k == 7: base.update(trail=2, lift=2, ph=7, extra=[(53, 46, 22), (55, 47, 19), (48, 47, 19)])
    if k == 8: base.update(trail=1, lift=1, ph=8, dy=3, lean=2, extra=[(53, 46, 22), (48, 47, 19)])
    return base
ANIMS = {  # nome: (funcao, n, ms[], meia-largura sombra)
    'idle': (idle, 7, IDLE_MS, 14), 'run': (run, 6, [RUN_MS] * 6, 14), 'dash': (dash, 3, DASH_MS, 16), 'dash_ar': (dash_air, 3, DASH_MS, 16),
    'jump_up': (jump_up, 2, JUMPUP_MS, 12), 'fall_start': (fall_start, 2, FALLS_MS, 12), 'fall_loop': (fall_loop, 3, FALLL_MS, 12), 'land': (land, 2, LAND_MS, 14),
    'hurt': (hurt, 3, HURT_MS, 13), 'heavy': (heavy, 9, HEAVY_MS, 17)}
