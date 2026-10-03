import sys; sys.path.insert(0, '/tmp/claude-0/mao31')
import numpy as np, math
import v3rig as R, v3spr as V
from v3rig import BX, BY, GR, H, W
FOOT = dict(FL=V.FOOT_FLAT, UP=V.FOOT_UP, DN=V.FOOT_DOWN, TK=V.FOOT_TUCK)
PROPS = {
    'A': dict(HEAD=V.HEAD_A, TORSO=V.TORSO_A, tx=5, ty0=12, hx=9, hem=32, shoulder=(11, 18), cape_xt=8, upn=11),
    'B': dict(HEAD=V.HEAD_B, TORSO=V.TORSO_B, tx=7, ty0=16, hx=7, hem=33, shoulder=(11, 22), cape_xt=9, upn=9),
}
def render(sp, pr, want=None):
    prop = PROPS[pr]; cv = R.Cv(); fx = R.Cv(); dy = sp.get('dy', 0); dx = sp.get('dx', 0); lean = sp.get('lean', 0); up = sp.get('up', 0)
    bx = BX + dx; info = {}
    ty0, hem = prop['ty0'], prop['hem']; T = prop['TORSO']; Rt = T.shape[0]
    shear = lambda y: int(round(lean * 0.9 * max(0.0, 1 - (y - ty0) / float(Rt))))
    if not sp.get('nocape'):
        if sp.get('chute'): R.cape_chute(cv, prop, sp, bx)
        else: R.cape(cv, prop, sp, bx)
    def leg(key, far):
        ax, ay, f = sp[key]; A = (bx + ax, BY + ay); K = (bx + 15 + 0.3 * (ax - 15) + (3 if far else 0), BY + hem - 3 + dy)
        s, ft = R.leg_sprites(K, A, FOOT[f], far); cv.mask(s >= 0, s); cv.put(ft, int(A[0]) - 5, int(A[1]))
    leg('far', True); leg('near', False)
    for yt in range(ty0, ty0 + Rt):
        ys = yt + 1 if (up and yt < ty0 + prop['upn']) else yt
        r = ys - ty0
        if r < 0 or r >= Rt: continue
        sx = shear(yt) + (sp.get('sway', 0) if yt >= hem - 2 else 0)
        for x in range(T.shape[1]):
            v = T[r, x]
            if v >= 0:
                cx, cy = bx + prop['tx'] + x + sx, BY + yt + dy
                if 0 <= cx < W and 0 <= cy < H: cv.a[cy, cx] = v
    hs = int(round(lean * 0.9)) + sp.get('hx', 0); hy = -up + sp.get('hy', 0)
    cv.put(prop['HEAD'], bx + prop['hx'] + hs, BY + dy + hy)
    bl = sp['blade']; (px, py), (tx, ty) = bl['p0'], bl['p1']
    p0 = (bx + px, BY + dy + py); p1 = (bx + tx, BY + dy + ty)
    s, poly = R.blade_sprite(p0, p1, w=bl.get('w', 11), haft=bl.get('haft', 11), blood=bl.get('blood', ()), bloodzone=bl.get('bz', .55))
    if not sp.get('noblade'): cv.mask(s >= 0, s)
    info['blade_poly'] = poly
    sx0, sy0 = prop['shoulder']; sx0 += shear(sy0 + 1) if False else shear(ty0 + 6)
    pts = [(bx + sx0, BY + dy + sy0 - up)] + [(bx + x, BY + dy + y) for (x, y) in sp['arm']]
    if not sp.get('noarm'): cv.mask(*(lambda a: (a >= 0, a))(R.arm_sprite(pts[0], pts)))
    c = sp.get('crescent')
    if c:
        P, Ro, a0, a1, Tm = c; o, poly = R.crescent(P, Ro, a0, a1, Tm, bx, BY + dy); fx.mask(o >= 0, o); info['cres_poly'] = poly
    ar = sp.get('arc')
    if ar:
        P_, Ro, a0, a1, Tm, pw = ar; o, poly = R.arc3(P_, Ro, a0, a1, Tm, bx, BY + dy, pw); fx.mask(o >= 0, o); info['cres_poly'] = poly
    for (x, y, col) in sp.get('extra', ()):
        if 0 <= BY + y < H and 0 <= bx + x < W: fx.a[BY + y, bx + x] = col
    cv.a[GR + 1:, :] = -1; fx.a[GR + 1:, :] = -1
    # fx nunca cobre o corpo na composicao final; devolve separado
    return (cv.a, fx.a, info)
