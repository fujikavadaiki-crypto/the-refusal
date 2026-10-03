"""Poses v5 (pequeno A v3.3): CORRIDA v2 (8 q, 6 px/q), partida (1 q), freio (1 q), DASH com SMEAR (arranque / smear 1 / smear 2 / freio)."""
import sys; sys.path.insert(0, '/tmp/claude-0/p41'); sys.path.insert(0, '/tmp/claude-0/p41/v6')
import math
import v6rig
import v4poses as V4
from v4poses import pose, dust, hand_pose
import v4anim as A
RUN_PX = 6; RUN_N = 8; RUN_MS = 1000.0 * RUN_PX / 144.0       # 41,67 ms por quadro (144 px/s, 48 px por ciclo, igual a antes)
NEAR8 = [(25, 41, 'UP'), (19, 40, 'FL'), (14, 40, 'DN'), (6, 35, 'TK'), (10, 31, 'TK'), (17, 33, 'TK'), (24, 37, 'UP'), (28, 40, 'UP')]
DY8 = [3, 4, 3, 2, 3, 4, 3, 2]
LEAN8 = [11, 12, 11, 10, 11, 12, 11, 10]
HY8 = [0, 1, 0, -1, 0, 1, 0, -1]
HAND8 = [(13, 30), (13, 31), (14, 30), (14, 29), (13, 30), (13, 31), (14, 30), (14, 29)]
TIPY8 = [33, 36, 34, 31, 33, 36, 34, 31]
def run8(k):
    lean = LEAN8[k]; h = HAND8[k]
    sp = dict(lean=lean, dy=DY8[k], hy=0, hx=1, trail=0, lift=0, flap=1, ph=0, near=NEAR8[k], far=NEAR8[(k + 4) % 8],
              arm=[(h[0] + 1, h[1] - 6), h], blade=dict(p0=h, p1=(h[0] - 29, TIPY8[k])),
              stream=dict(L=34, rise=10, ht=8, amp=3.6, ph=k * math.pi / 2))
    sp['hy'] = [0, 1, 0, 0, 0, 1, 0, 0][k]
    return sp
def run_start():
    h = (14, 31)
    return dict(lean=13, dy=5, hx=1, hy=1, trail=0, lift=0, flap=1, ph=0, near=(24, 41, 'UP'), far=(4, 38, 'DN'),
                arm=[(15, 25), h], blade=dict(p0=h, p1=(h[0] - 28, 36)), stream=dict(L=22, rise=3, ht=9, amp=1.2, ph=0.5))
def run_stop():
    h = (22, 31)
    h = (12, 30)
    return dict(lean=-5, dy=3, hx=-1, hy=1, trail=0, lift=0, flap=1, ph=0, near=(27, 40, 'FL'), far=(5, 40, 'FL'),
                arm=[(11, 25), h], blade=dict(p0=h, p1=(h[0] - 26, 38)), stream=dict(L=16, rise=8, ht=8, amp=1.2, ph=2.0), flap_fwd=dict(L=20, rise=2, ph=0.8))
STREAM_RUN_PREV = dict(L=34, rise=10, ht=9, amp=3.6, ph=3 * math.pi / 2)
def lag5(seq, prev=None, loop=False):
    """capa SEMPRE viva (atraso de 1 quadro): onda/comprimento da capa vem do quadro anterior; pose do corpo, do atual. Mantem as chaves da v4 e 'stream'."""
    seq = [dict(s) for s in seq]; out = []
    for k, sp in enumerate(seq):
        sp = dict(sp); src = seq[k - 1] if k > 0 else (prev if prev is not None else (seq[-1] if loop else None))
        if src is not None:
            for key in ('trail', 'lift', 'flap', 'ph', 'cape_len', 'chute', 'chute_ph', 'chute_dx'):
                if key in src: sp[key] = src[key]
                elif key in sp and key in ('chute', 'chute_ph', 'chute_dx'): del sp[key]
            if 'stream' in sp:
                ps = src.get('stream') if isinstance(src, dict) else None
                if ps is not None and not sp['stream'].get('fwd') and not ps.get('fwd'): sp['stream'] = dict(sp['stream'], ph=ps['ph'], L=ps['L'], rise=ps['rise'], amp=ps['amp'])
        out.append(sp)
    return out
# ---------------------------------------------------------------------------------- DASH
DASH5_MS = [50, 60, 190, 50]                                                     # arranque / SMEAR (1 q) / pose esticada / freio = 350 ms
def _dash5(air):
    D = lambda ex: [] if air else ex
    arr = pose(lean=9, dy=6, th=130, reach=13, phi=172, near=(21, 40, 'FL'), far=(4, 40, 'FL'), trail=0, lift=0, flap=1, ph=0, hx=1, hy=1,
               extra=D(dust(-4, 46, 16, 10, 5, 11, side=-1)))
    arr['stream'] = dict(L=18, rise=2, ht=9, amp=1.0, ph=0.4)
    arr['blade'] = dict(p0=(13, 33), p1=(-15, 38)); arr['arm'] = [(14, 26), (13, 33)]
    # SMEAR: 1 q, virgula COMPACTA (capuz na frente, corpo grosso que afina numa cauda curva), ~1,3x o corpo
    s1 = dict(smear=True, Ls=53, T0=30, tp=1.1, bend=15, be=1.7, hr=.22, yc=32, hx=29, hy=14, ph=0.3, wob=0.8, Tt=2.2, extra=D(dust(-20, 46, 12, 18, 3, 41, side=-1)))
    # POSE ESTICADA: corpo inclinado e baixo, perna da frente esticada, perna de tras arrastando, capa LONGA reta para tras, lamina recolhida junto as costas
    ext = dict(lean=15, dy=5, hy=1, hx=3, trail=0, lift=0, flap=1, ph=0, near=(29, 40, 'UP'), far=(-1, 37, 'DN'),
               arm=[(13, 26), (7, 31)], blade=dict(p0=(7, 31), p1=(-13, 36)), stream=dict(L=56, rise=3, ht=7, amp=1.1, ph=1.2),
               extra=D(dust(-6, 46, 12, 22, 3, 42, side=-1)))
    brk = pose(lean=-6, dy=3, th=60, reach=14, phi=40, near=(27, 40, 'FL'), far=(5, 40, 'FL'), trail=0, lift=0, flap=1, ph=2, hx=-2, hy=1,
               extra=D(dust(2, 46, 18, 12, 6, 5, side=-1)))
    brk['stream'] = dict(L=24, rise=8, ht=8, amp=1.4, ph=2.0, fwd=True); brk['flap_fwd'] = dict(L=20, rise=2, ph=0.8)
    brk['arm'] = [(11, 25), (12, 30)]; brk['blade'] = dict(p0=(12, 30), p1=(-14, 38))
    if air:
        arr.update(near=(9, 34, 'TK'), far=(18, 35, 'TK'), dy=2); brk.update(near=(24, 36, 'TK'), far=(8, 35, 'TK'), dy=0)
        ext.update(near=(27, 36, 'FL'), far=(2, 35, 'DN'), dy=3)
        s1['nofloor'] = True; ext['nofloor'] = True
    return [arr, s1, ext, brk]
def dash5(): return _dash5(False)
def dash_air5(): return _dash5(True)
def render5(sp, pr='A'):
    if sp.get('smear'): return v6rig.smear(sp, pr)
    b, f, i = A.render4(sp, pr)
    if sp.get('flap_fwd'):
        from v4anim_base import PROPS
        v6rig.fwd_flap(b, PROPS[pr], sp, 100 + sp.get('dx', 0))
        if not sp.get('nofloor'): b[v6rig.GR + 1:, :] = -1
    return b, f, i
