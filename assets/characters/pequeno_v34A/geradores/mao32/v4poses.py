"""Poses v4 do Carrasco pequeno A (lote ATAQUES + fluidez). Mesmo rig/paleta da v3.1.
Coordenadas locais: x = centro do tronco 15, y = topo da cabeca 0, sola 47. Angulos em graus (tela: 0 = direita, 90 = baixo, -90 = cima)."""
import sys; sys.path.insert(0, '/tmp/claude-0/p41')
import math, random
import v3poses as P0
from v4anim import lagcape
FOOT_STAND = dict(near=(13, 40, 'FL'), far=(23, 40, 'FL'))
def hand_pose(lean, th, reach, phi, L=29.0, bend=2.0, hdx=0, hdy=0):
    """braco (ombro->cotovelo->mao) + lamina (mao->ponta, comprimento L). th = angulo ombro->mao, phi = angulo da lamina."""
    sx = 11 + int(round(lean * 0.9 * (1 - 6 / 21.0))); sy = 18
    t = math.radians(th); hx = sx + reach * math.cos(t) + hdx; hy = sy + reach * math.sin(t) + hdy
    mx, my = (sx + hx) / 2.0, (sy + hy) / 2.0; ex, ey = mx - bend * math.sin(t), my + bend * math.cos(t)
    f = math.radians(phi)
    return dict(arm=[(int(round(ex)), int(round(ey))), (int(round(hx)), int(round(hy)))],
                blade=dict(p0=(int(round(hx)), int(round(hy))), p1=(int(round(hx + L * math.cos(f))), int(round(hy + L * math.sin(f))))))
def pose(lean=0, dy=0, th=40, reach=14, phi=32, near=(13, 40, 'FL'), far=(23, 40, 'FL'), trail=3, lift=0, flap=1, ph=0, L=29.0, bend=2.0, hdx=0, hdy=0, **kw):
    sp = dict(lean=lean, dy=dy, trail=trail, lift=lift, flap=flap, ph=ph, near=near, far=far); sp.update(hand_pose(lean, th, reach, phi, L, bend, hdx, hdy)); sp.update(kw)
    ta = sp.pop('thrust_auto', None)
    if ta:   # (comprimento_alem_da_ponta, espessura, pico, recuo_antes_da_ponta): lente centrada no eixo da lamina
        tx, ty = sp['blade']['p1']; ext, tm, pk, back = ta; sp['thrust'] = (tx - back, tx + ext, ty, tm, .6, pk)
    return sp
def dust(cx, cy, n, spread, up, seed, side=0, cols=(10, 12, 12, 15, 17)):
    """poeira no chao: n pixels em torno de (cx, cy); side = -1 espalha para tras, +1 para a frente, 0 simetrico"""
    r = random.Random(seed); out = []
    for i in range(n):
        dx = r.uniform(-spread, spread) if side == 0 else side * r.uniform(0, spread)
        dyy = -r.uniform(0, up) * (1 - abs(dx) / (spread + 1) * .5)
        out.append((int(round(cx + dx)), min(46, int(round(cy + dyy))), cols[r.randrange(len(cols))]))
    return out
def sparks(cx, cy, r, seed, n=10):
    rr = random.Random(seed); out = [(cx, cy, 18), (cx - 1, cy, 17), (cx + 1, cy, 17), (cx, cy - 1, 17), (cx, cy + 1, 17)]
    for i in range(n):
        a = rr.uniform(0, 2 * math.pi); d = rr.uniform(r * .5, r); out.append((int(round(cx + d * math.cos(a))), int(round(cy + d * math.sin(a))), rr.choice((18, 16, 31, 26, 41))))
    return out
# -------------------------------------------------------------------- IDLE (8 q, 2000 ms): respiracao, capa, lamina oscilando
IDLE4_MS = [280, 250, 250, 280, 250, 250, 220, 220]
def idle4(k):
    up = [0, 0, 1, 1, 1, 1, 0, 0][k]; sw = [0, 0, 1, 1, 1, 0, -1, -1][k]
    tr = [2, 1, 2, 3, 4, 4, 3, 2][k]; lift = [0, 0, 1, 1, 2, 2, 1, 0][k]; hy = [0, 0, 0, 1, 1, 1, 0, 0][k]
    hand = [(18, 31), (18, 31), (18, 31), (18, 30), (18, 30), (18, 30), (18, 31), (18, 31)][k]
    tip = [(43, 46), (43, 46), (43, 46), (43, 45), (43, 44), (43, 44), (43, 45), (43, 46)][k]
    return dict(up=up, lean=[0, 0, 0, 1, 1, 1, 0, 0][k], sway=sw, trail=tr, lift=lift, flap=[1, 1, 1, 2, 2, 2, 1, 1][k], ph=k * .9, hy=hy,
                far=(23, 40, 'FL'), near=(13, 40, 'FL'), blade=dict(p0=hand, p1=tip), arm=[(11, 26), (hand[0], hand[1])])
# -------------------------------------------------------------------- CORRIDA: contrabalanco do tronco (6 q, 8 px/q)
def run4(k):
    sp = P0.run(k); lowq = (k % 3 == 1); fl = (k % 3 == 2)
    # tronco contra-gira: perna proxima a frente (q0-1) -> tronco recua e braco/lamina vao para tras; voo (q2/q5) -> tronco avanca
    lean = [2, 3, 5, 2, 3, 5][k]; sp['lean'] = lean; sp['hx'] = [0, 0, 1, 0, 0, 1][k]
    h = [(16, 32), (16, 33), (19, 29), (17, 32), (17, 33), (20, 29)][k]
    sp['arm'] = [(11, 25 + (1 if lowq else 0)), h]
    sp['blade'] = dict(p0=h, p1=(h[0] + 30, h[1] + [-3, -5, -10, -3, -5, -10][k]))
    return sp
def run_start(k):   # partida da corrida: 2 q inclinando (substituem o ciclo q0/q1 so na partida): mesmo apoio, tronco a frente
    sp = P0.run(k); sp['lean'] = [6, 5][k]; sp['dy'] = [2, 3][k]; sp['hx'] = 1; sp['trail'] = [4, 6][k]; sp['lift'] = 0
    h = [(21, 33), (20, 33)][k]; sp['arm'] = [(14, 27), h]; sp['blade'] = dict(p0=h, p1=(h[0] + 29, h[1] - [1, 3][k]))
    sp['near'] = [(22, 41, 'UP'), (16, 40, 'FL')][k]; sp['far'] = [(6, 38, 'TK'), (4, 37, 'DN')][k]; return sp
def turn_frame():   # virada de direcao: 1 q (derrapa, tronco para tras, pes abertos, lamina baixa)
    return pose(lean=-4, dy=2, th=55, reach=13, phi=40, near=(22, 40, 'FL'), far=(5, 40, 'FL'), trail=-1, lift=3, flap=2, ph=1, hy=1)
def attack_exit():  # saida do ataque para o idle: 1 q (lamina volta ao porte, corpo se alinhando)
    return pose(lean=2, dy=2, th=55, reach=13, phi=40, near=(13, 40, 'FL'), far=(23, 40, 'FL'), trail=3, lift=1, flap=1, ph=1)
# -------------------------------------------------------------------- DASH (5 q, 350 ms): arranque + 3 + freio
DASH4_MS = [50, 70, 110, 70, 50]
def _dash4(air):
    d = [P0.dash(i) for i in range(3)]
    for q in d: q['trail'] = min(q["trail"], 17)
    arr = pose(lean=-3, dy=5, th=140, reach=14, phi=165, near=(10, 40, 'FL'), far=(22, 40, 'FL'), trail=1, lift=-1, flap=1, ph=0, hx=-1, extra=[] if air else dust(0, 46, 16, 10, 5, 11, side=-1))
    brk = pose(lean=-8, dy=3, th=60, reach=14, phi=40, near=(26, 40, 'FL'), far=(5, 40, 'FL'), trail=0, lift=5, flap=3, ph=2, hx=-2, hy=1,
               extra=[] if air else dust(2, 46, 18, 12, 6, 5, side=-1))
    if air:
        arr.update(near=(9, 34, 'TK'), far=(18, 35, 'TK'), dy=2)
        brk.update(near=(24, 36, 'TK'), far=(8, 35, 'TK'), dy=0)
        d = [P0.dash_air(i) for i in range(3)]
        for q in d: q['trail'] = min(q["trail"], 17)
    return [arr] + [dict(x) for x in d] + [brk]
def dash4(): return _dash4(False)
def dash_air4(): return _dash4(True)
# -------------------------------------------------------------------- POUSO (2 q, 120 ms): impacto
def land4(k):
    if k == 0: return pose(lean=4, dy=7, th=60, reach=13, phi=36, near=(10, 40, 'FL'), far=(26, 40, 'FL'), trail=6, lift=-3, flap=1, ph=0, cape_len=3, extra=dust(13, 46, 12, 12, 4, 21))
    return pose(lean=2, dy=3, th=55, reach=13, phi=38, near=(12, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=2, flap=1, ph=1, extra=dust(13, 46, 7, 13, 3, 22))
# -------------------------------------------------------------------- COMBO LEVE 1: horizontal baixo (460 = 130 + 110 + 220)
L1_MS = [60, 70, 50, 60, 70, 70, 80]; L1_ACTIVE = [2, 3]
def light1():
    s = [pose(lean=-2, dy=1, th=118, reach=14, phi=148, near=(12, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=0, ph=1),
         pose(lean=-4, dy=3, th=160, reach=15, phi=172, near=(9, 40, 'FL'), far=(25, 40, 'FL'), trail=2, lift=-1, ph=2, hx=-1),
         pose(lean=6, dy=3, th=45, reach=14, phi=12, near=(21, 40, 'FL'), far=(5, 40, 'DN'), trail=11, lift=1, flap=2, ph=3, arc=((18, -2), 42, 152, 38, 16, .85)),
         pose(lean=7, dy=4, th=28, reach=15, phi=14, near=(23, 40, 'FL'), far=(4, 40, 'DN'), trail=9, lift=1, flap=2, ph=4, arc=((18, -2), 42, 92, 18, 9, 1.55)),
         pose(lean=6, dy=4, th=30, reach=15, phi=20, near=(23, 40, 'FL'), far=(5, 40, 'DN'), trail=6, lift=1, ph=5),
         pose(lean=5, dy=3, th=40, reach=14, phi=26, near=(21, 40, 'FL'), far=(6, 40, 'FL'), trail=4, lift=1, ph=6),
         pose(lean=3, dy=2, th=50, reach=14, phi=30, near=(18, 40, 'FL'), far=(8, 40, 'FL'), trail=3, lift=0, ph=7)]
    return s
# -------------------------------------------------------------------- COMBO LEVE 2: diagonal subindo (520 = 160 + 110 + 250)
L2_MS = [50, 50, 60, 50, 60, 80, 80, 90]; L2_ACTIVE = [3, 4]
def light2():
    s = [pose(lean=2, dy=2, th=62, reach=14, phi=34, near=(18, 40, 'FL'), far=(6, 40, 'DN'), trail=4, lift=0, ph=1),
         pose(lean=4, dy=4, th=82, reach=17, phi=22, near=(21, 40, 'FL'), far=(4, 40, 'DN'), trail=4, lift=-1, ph=2),
         pose(lean=5, dy=5, th=90, reach=18, phi=12, near=(22, 40, 'FL'), far=(3, 40, 'DN'), trail=3, lift=-1, ph=3, hy=1),
         pose(lean=6, dy=3, th=-8, reach=15, phi=-22, near=(21, 40, 'FL'), far=(4, 40, 'DN'), trail=10, lift=2, flap=2, ph=4, arc=((14, 26), 42, 38, -78, 16, .85)),
         pose(lean=7, dy=2, th=-38, reach=15, phi=-62, near=(23, 40, 'FL'), far=(3, 40, 'DN'), trail=8, lift=3, flap=2, ph=5, arc=((14, 26), 42, -28, -92, 9, 1.55)),
         pose(lean=6, dy=2, th=-42, reach=14, phi=-52, near=(22, 40, 'FL'), far=(4, 40, 'DN'), trail=6, lift=3, ph=6),
         pose(lean=5, dy=2, th=-15, reach=14, phi=-8, near=(21, 40, 'FL'), far=(6, 40, 'FL'), trail=4, lift=2, ph=7),
         pose(lean=3, dy=2, th=40, reach=14, phi=28, near=(18, 40, 'FL'), far=(8, 40, 'FL'), trail=3, lift=1, ph=8)]
    return s
# -------------------------------------------------------------------- COMBO LEVE 3: de cima para baixo, arco maior (670 = 220 + 130 + 320)
L3_MS = [70, 70, 80, 65, 65, 80, 80, 80, 80]; L3_ACTIVE = [3, 4]
def light3():
    s = [pose(lean=-1, dy=1, th=-100, reach=12, phi=-98, near=(12, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=-1, ph=1),
         pose(lean=-4, dy=3, th=-140, reach=13, phi=-148, near=(10, 40, 'FL'), far=(25, 40, 'FL'), trail=2, lift=-1, ph=2, hx=-1),
         pose(lean=-6, dy=4, th=-155, reach=13, phi=-163, near=(9, 40, 'FL'), far=(26, 40, 'FL'), trail=2, lift=-2, ph=3, hx=-2, hy=1),
         pose(lean=7, dy=3, th=-28, reach=15, phi=22, near=(22, 40, 'FL'), far=(4, 40, 'DN'), trail=13, lift=2, flap=2, ph=4, arc=((14, 12), 50, -138, 14, 22, .85)),
         pose(lean=8, dy=5, th=22, reach=15, phi=50, near=(24, 40, 'FL'), far=(3, 40, 'DN'), trail=9, lift=2, flap=2, ph=5, arc=((14, 12), 50, -52, 58, 11, 1.6)),
         pose(lean=7, dy=5, th=28, reach=15, phi=54, near=(23, 40, 'FL'), far=(4, 40, 'DN'), trail=6, lift=2, ph=6),
         pose(lean=6, dy=4, th=34, reach=14, phi=48, near=(22, 40, 'FL'), far=(5, 40, 'DN'), trail=4, lift=1, ph=7),
         pose(lean=4, dy=3, th=40, reach=14, phi=40, near=(19, 40, 'FL'), far=(7, 40, 'FL'), trail=3, lift=1, ph=8),
         pose(lean=3, dy=2, th=50, reach=14, phi=34, near=(17, 40, 'FL'), far=(8, 40, 'FL'), trail=3, lift=0, ph=9)]
    return s
# -------------------------------------------------------------------- POS-DASH: estocada com arco RETO (500 = 120 + 110 + 270)
PD_MS = [50, 70, 50, 60, 90, 90, 90]; PD_ACTIVE = [2, 3]
def post_dash():
    s = [pose(lean=-3, dy=3, th=140, reach=14, phi=-150, near=(10, 40, 'FL'), far=(24, 40, 'FL'), trail=6, lift=0, ph=1),
         pose(lean=-5, dy=4, th=165, reach=16, phi=178, near=(8, 40, 'FL'), far=(25, 40, 'FL'), trail=3, lift=-1, ph=2, hx=-1),
         pose(lean=9, dy=5, th=8, reach=17, phi=2, L=28, near=(29, 40, 'FL'), far=(3, 40, 'DN'), trail=16, lift=1, flap=2, ph=3, thrust_auto=(36, 12, .55, 30)),
         pose(lean=10, dy=5, th=6, reach=18, phi=3, L=28, near=(30, 40, 'FL'), far=(2, 40, 'DN'), trail=13, lift=1, flap=2, ph=4, thrust_auto=(24, 6, .5, 22)),
         pose(lean=9, dy=5, th=8, reach=17, phi=4, L=28, near=(29, 40, 'FL'), far=(3, 40, 'DN'), trail=8, lift=1, ph=5),
         pose(lean=7, dy=4, th=20, reach=15, phi=14, near=(25, 40, 'FL'), far=(6, 40, 'DN'), trail=5, lift=1, ph=6),
         pose(lean=4, dy=3, th=45, reach=14, phi=32, near=(18, 40, 'FL'), far=(8, 40, 'FL'), trail=3, lift=0, ph=7)]
    return s
# -------------------------------------------------------------------- AEREO LEVE: giro com arco circular (520 = 130 + 120 + 270)
AL_MS = [60, 70, 60, 60, 90, 90, 90]; AL_ACTIVE = [2, 3]
def air_light():
    tuck = dict(near=(10, 34, 'TK'), far=(20, 35, 'TK'))
    s = [pose(lean=-2, dy=-2, th=130, reach=14, phi=160, trail=2, lift=3, ph=1, nofloor=True, **tuck),
         pose(lean=-5, dy=-2, th=-150, reach=14, phi=-166, trail=2, lift=3, ph=2, hx=-1, nofloor=True, near=(9, 33, 'TK'), far=(19, 34, 'TK')),
         pose(lean=5, dy=-2, th=-30, reach=15, phi=-28, trail=9, lift=4, flap=2, ph=3, nofloor=True, near=(12, 35, 'TK'), far=(22, 34, 'TK'), arc=((15, 24), 34, -205, 40, 15, .85)),
         pose(lean=3, dy=-1, th=70, reach=15, phi=96, trail=7, lift=4, flap=2, ph=4, nofloor=True, near=(13, 36, 'TK'), far=(22, 36, 'DN'), arc=((15, 24), 34, 18, 205, 12, 1.05)),
         pose(lean=2, dy=-2, th=60, reach=14, phi=60, trail=5, lift=5, ph=5, nofloor=True, near=(13, 37, 'DN'), far=(23, 36, 'TK')),
         pose(lean=2, dy=-2, th=55, reach=14, phi=48, trail=3, lift=5, ph=6, nofloor=True, near=(13, 38, 'DN'), far=(24, 37, 'TK')),
         pose(lean=2, dy=-1, th=50, reach=14, phi=40, trail=2, lift=4, ph=7, nofloor=True, near=(13, 38, 'DN'), far=(24, 37, 'TK'))]
    return s
# -------------------------------------------------------------------- AEREO PESADO: mergulho (770 = 250 + 130 + 390); recuperacao: segura -> impacto no pouso
AH_MS = [80, 80, 90, 65, 65, 70, 80, 90, 90, 60]; AH_ACTIVE = [3, 4]; AH_LAND_FROM = 6     # q6..q9 so rodam depois que pousa; q5 = segura no ar
def air_heavy():
    tuck = dict(near=(10, 34, 'TK'), far=(20, 35, 'TK'))
    s = [pose(lean=-2, dy=-3, th=-108, reach=12, phi=-104, trail=2, lift=3, ph=1, nofloor=True, **tuck),
         pose(lean=-5, dy=-3, th=-146, reach=13, phi=-152, trail=2, lift=3, ph=2, hx=-1, nofloor=True, near=(9, 33, 'TK'), far=(19, 34, 'TK')),
         pose(lean=-7, dy=-3, th=-158, reach=13, phi=-166, trail=3, lift=4, ph=3, hx=-2, hy=1, nofloor=True, near=(8, 32, 'TK'), far=(18, 33, 'TK')),
         pose(lean=9, dy=-4, th=-10, reach=15, phi=42, trail=14, lift=5, flap=2, ph=4, hx=2, nofloor=True, near=(2, 30, 'DN'), far=(-4, 33, 'DN'), arc=((18, 10), 54, -112, 38, 24, .85)),
         pose(lean=10, dy=-4, th=34, reach=15, phi=78, trail=12, lift=5, flap=2, ph=5, hx=2, nofloor=True, near=(1, 29, 'DN'), far=(-5, 32, 'DN'), arc=((18, 10), 54, -20, 78, 11, 1.6)),
         pose(lean=9, dy=-3, th=36, reach=15, phi=76, trail=9, lift=5, flap=2, ph=6, hx=2, nofloor=True, near=(2, 31, 'DN'), far=(-3, 34, 'DN')),
         pose(lean=6, dy=7, th=52, reach=15, phi=62, near=(11, 40, 'FL'), far=(26, 40, 'FL'), trail=6, lift=-3, ph=7, cape_len=3, hy=1, extra=dust(30, 46, 14, 14, 4, 31, side=1) + dust(0, 46, 8, 8, 3, 32, side=-1)),
         pose(lean=5, dy=5, th=50, reach=14, phi=56, near=(12, 40, 'FL'), far=(25, 40, 'FL'), trail=4, lift=2, ph=8, extra=dust(31, 46, 8, 13, 3, 33, side=1)),
         pose(lean=4, dy=3, th=48, reach=14, phi=50, near=(14, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=1, ph=9),
         pose(lean=3, dy=2, th=52, reach=14, phi=42, near=(14, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=0, ph=10)]
    return s
# -------------------------------------------------------------------- CARREGAR (segurar K): pose de carga, tremor de 1 px, brilho pulsando
CH_START_MS = [60, 60]; CH_LOOP_MS = [90, 90, 90, 90]; CH_FULL_MS = [70, 70, 70, 70]
def charge_start():
    h0 = P0.heavy(0); h1 = P0.heavy(1); return [dict(h0, glow=0), dict(h1, glow=1)]
def _charge_base(dxs, glows, extra_fn=None, lean=-6):
    out = []
    for i, (dx, g) in enumerate(zip(dxs, glows)):
        sp = pose(lean=lean, dy=4, th=-150, reach=13, phi=-163, near=(9, 40, 'FL'), far=(25, 40, 'FL'), trail=2, lift=-1 - (i % 2), flap=1, ph=3 + i, hx=-2, hy=1, dx=dx, glow=g)
        if extra_fn: sp['extra'] = extra_fn(i)
        out.append(sp)
    return out
def charge_loop(): return _charge_base([0, 1, 0, -1], [1, 2, 1, 2])
def charge_full():
    def fx(i):
        r = random.Random(100 + i); pts = []
        for j in range(5):
            x = r.randint(-24, -8); y = r.randint(-18, 4); pts.append((x, y, r.choice((18, 26, 31, 41))))
        return pts
    return _charge_base([1, -1, 1, 0], [3, 2, 3, 2], fx, lean=-7)
# -------------------------------------------------------------------- CARREGADO: heavy com arco maior e mais longo (780 = 160 + 140 + 480)
CHV_MS = [80, 80, 70, 70, 70, 70, 80, 120, 140]; CHV_ACTIVE = [2, 3]
def charged_heavy():
    s = [pose(lean=-7, dy=4, th=-152, reach=13, phi=-166, near=(9, 40, 'FL'), far=(25, 40, 'FL'), trail=2, lift=-2, ph=1, hx=-2, hy=1, glow=3),
         pose(lean=-9, dy=5, th=-160, reach=13, phi=-176, near=(8, 40, 'FL'), far=(26, 40, 'FL'), trail=2, lift=-2, ph=2, hx=-2, hy=1, glow=3),
         pose(lean=9, dy=1, th=16, reach=16, phi=30, near=(23, 40, 'FL'), far=(2, 40, 'DN'), trail=18, lift=2, flap=2, ph=3, glow=3, arc=((22, 8), 78, -206, 34, 38, .85),
              extra=[(60, 46, 18), (63, 43, 31), (58, 44, 26), (65, 46, 41), (62, 41, 26)]),
         pose(lean=8, dy=5, th=24, reach=16, phi=50, near=(25, 40, 'FL'), far=(2, 40, 'DN'), trail=14, lift=2, flap=2, ph=4, glow=2, arc=((22, 8), 78, -120, 60, 17, 1.7),
              blade=None, extra=[(64, 45, 18), (66, 42, 26), (61, 46, 31), (68, 44, 22), (63, 47, 22)]),
         pose(lean=7, dy=5, th=28, reach=16, phi=54, near=(24, 40, 'FL'), far=(3, 40, 'DN'), trail=10, lift=2, ph=5, glow=1),
         pose(lean=7, dy=5, th=30, reach=16, phi=56, near=(24, 40, 'FL'), far=(4, 40, 'DN'), trail=6, lift=2, ph=6),
         pose(lean=6, dy=4, th=34, reach=15, phi=52, near=(23, 40, 'FL'), far=(5, 40, 'DN'), trail=4, lift=1, ph=7),
         pose(lean=4, dy=3, th=40, reach=14, phi=44, near=(20, 40, 'FL'), far=(7, 40, 'FL'), trail=3, lift=1, ph=8),
         pose(lean=3, dy=2, th=50, reach=14, phi=36, near=(17, 40, 'FL'), far=(9, 40, 'FL'), trail=3, lift=0, ph=9)]
    del s[3]['blade']; s[3].update(hand_pose(8, 24, 16, 50)); return s
# -------------------------------------------------------------------- PARRY (380 = 50 + 110 + 100 + 120): guarda com a lamina na frente
PARRY_MS = [50, 110, 100, 120]
def parry():
    s = [pose(lean=1, dy=2, th=-35, reach=12, phi=-82, near=(13, 40, 'FL'), far=(24, 40, 'FL'), trail=3, lift=1, ph=1),
         pose(lean=2, dy=3, th=-10, reach=14, phi=-76, near=(15, 40, 'FL'), far=(26, 40, 'FL'), trail=5, lift=2, flap=2, ph=2, hx=0),
         pose(lean=2, dy=3, th=-8, reach=14, phi=-66, near=(15, 40, 'FL'), far=(26, 40, 'FL'), trail=4, lift=1, ph=3),
         pose(lean=1, dy=2, th=20, reach=14, phi=0, near=(14, 40, 'FL'), far=(25, 40, 'FL'), trail=3, lift=0, ph=4)]
    return s
PARRY_SPARK_MS = [50, 50, 60]
