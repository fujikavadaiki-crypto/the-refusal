import sys; sys.path.insert(0, '/tmp/claude-0/p41')
import numpy as np, math
from scipy import ndimage as ndi
H, W = 190, 240
BX, GR = 100, 150
BY = GR - 47
ST8 = np.ones((3, 3), bool)
YY, XX = np.mgrid[0:H, 0:W]
class Cv:
    def __init__(s): s.a = -np.ones((H, W), int)
    def put(s, sp, x, y):
        for yy in range(sp.shape[0]):
            for xx in range(sp.shape[1]):
                v = sp[yy, xx]
                if v >= 0 and 0 <= y + yy < H and 0 <= x + xx < W: s.a[y + yy, x + xx] = v
    def mask(s, m, idxmap): s.a[m] = idxmap[m]
def seg_mask(p0, p1, r):
    (x0, y0), (x1, y1) = p0, p1; L2 = max((x1 - x0) ** 2 + (y1 - y0) ** 2, 1e-6)
    px, py = XX + .5 - x0, YY + .5 - y0; t = np.clip((px * (x1 - x0) + py * (y1 - y0)) / L2, 0, 1)
    return np.hypot(px - t * (x1 - x0), py - t * (y1 - y0)) <= r
def shade_capsule(full, body, light, rim, shade, outline=3):
    er = ndi.binary_erosion(full, structure=ST8, border_value=0); edge = full & ~er; inn = full & ~edge
    out = -np.ones((H, W), int); out[inn] = body; emp = ~inn
    up = np.zeros_like(inn); up[1:] = inn[1:] & emp[:-1]; rt = np.zeros_like(inn); rt[:, :-1] = inn[:, :-1] & emp[:, 1:]
    dn = np.zeros_like(inn); dn[:-1] = inn[:-1] & emp[1:]; lf = np.zeros_like(inn); lf[:, 1:] = inn[:, 1:] & emp[:, :-1]
    lit = up | rt; sh = (dn | lf) & ~lit; out[sh] = shade; out[lit] = rim
    lit2 = ndi.binary_dilation(lit, structure=ST8) & inn & ~lit & ~sh; out[lit2] = light
    out[edge] = outline; return out
def arm_sprite(sh, pts, r=3.3):
    """ombreira (couro) + manga grossa (3 tons) + luva escura; pts = [ombro, cotovelo, mao]"""
    m = seg_mask(pts[0], pts[1], r) | seg_mask(pts[1], pts[2], r * .95); hand = seg_mask(pts[2], pts[2], r + .4)
    o = shade_capsule(m | hand, 10, 12, 12, 8)
    inn = (o >= 0) & (o != 3); hi = hand & inn; o[hi] = 7
    up = np.zeros_like(hi); up[1:] = hi[1:] & ~hi[:-1]; o[up & hi] = 8
    pa = seg_mask(sh, sh, 3.9); po = shade_capsule(pa, 8, 10, 12, 7)                      # ombreira: um degrau mais escura que a manga, aro claro
    o[(po >= 0) & ~(o >= 0)] = po[(po >= 0) & ~(o >= 0)]; o[(po >= 0) & (po != 3) & (o == 3)] = po[(po >= 0) & (po != 3) & (o == 3)]
    return o
def blade_sprite(p0, p1, w=11, haft=11, hw=3.6, blood=(), tip=0.38, bloodzone=0.55):
    (x0, y0), (x1, y1) = p0, p1; L = math.hypot(x1 - x0, y1 - y0); dx, dy = (x1 - x0) / L, (y1 - y0) / L; nx, ny = -dy, dx
    if ny > 0: nx, ny = -nx, -ny
    px, py = XX + .5 - x0, YY + .5 - y0; t = px * dx + py * dy; u = px * nx + py * ny
    hf = (t >= -1.5) & (t < haft + 1) & (np.abs(u) <= hw / 2 + .5)
    bl = (t >= haft) & (t <= L) & (np.abs(u) <= w / 2) & (t <= L - (w / 2 - u) * tip)
    full = hf | bl; er = ndi.binary_erosion(full, structure=ST8, border_value=0); edge = full & ~er; inn = full & ~edge
    out = -np.ones((H, W), int)
    out[inn & hf & ~bl] = 10; out[inn & hf & ~bl & (u < -0.2)] = 7; out[inn & hf & ~bl & (u > 0.9)] = 12
    out[inn & bl] = 14
    out[edge] = 3; bedge = edge & bl & ~(hf & ~bl & (t < haft - 0.5)); out[bedge] = 16
    up = np.zeros_like(full); up[1:] = full[1:] & ~full[:-1]; out[up & bl & edge] = 18
    top = inn & bl & (u > w / 2 - 2.2); out[top & (t > haft + 2)] = 16
    bz = inn & bl & (u > -w / 2 + 2.5) & (t > haft + (L - haft) * bloodzone); out[bz] = 22
    bz2 = inn & bl & (u <= -w / 2 + 2.5) & (u > -w / 2 + 1.2) & (t > haft + (L - haft) * (bloodzone + .12)); out[bz2] = 19
    for (bx, by) in blood:
        if 0 <= by < H and 0 <= bx < W and out[by, bx] in (14, 16): out[by, bx] = 22
    poly = [(x0 + dx * t_ + nx * u_, y0 + dy * t_ + ny * u_) for t_, u_ in ((haft, -w / 2), (L, -w / 2), (L - w * .38, w / 2), (haft, w / 2))]
    return out, poly
def leg_sprites(K, A, foot, far):
    m = seg_mask(K, A, 3.3)
    s = shade_capsule(m, 7 if far else 8, 8 if far else 10, 10 if far else 12, 7)
    ft = foot.copy()
    if far:
        for k, v in ((12, 10), (10, 8), (8, 7)): ft[foot == k] = v
    return s, ft
def cape(cv, prop, sp, bx):
    trail = sp.get('trail', 0); lift = sp.get('lift', 0); fl = sp.get('flap', 0); ph = sp.get('ph', 0); dy = sp.get('dy', 0); lean = sp.get('lean', 0)
    top = prop['ty0'] + 1; bot = prop['hem'] + 5 + sp.get('cape_len', 0); xt = prop['cape_xt']
    botE = int(round(bot - lift * 0.5))
    for y in range(top, botE + 1):
        f = (y - top) / max(botE - top, 1)
        xl = int(round(xt - 11 * f ** 0.8 - trail * f ** 1.4 - lift * 0.9 * f + fl * math.sin(f * 5 + ph) * f))
        cy = BY + y + dy
        for x in range(xl, 15):
            cx = bx + x + int(round(lean * .5 * (1 - f)))
            if not (0 <= cx < W and 0 <= cy < H): continue
            edge = (x == xl) or (y == botE) or (y == top); d = x - xl
            if edge: v = 3
            elif d <= 1 or f > .88: v = 0
            elif d in (4, 5) or d == 8: v = 0 if (y + d) % 3 else 1
            else: v = 1
            if y == botE and (x - xl) % 5 in (3, 4): continue     # barra recortada
            cv.a[cy, cx] = v
def crescent(P, Ro, a0, a1, Tmax, bx, byy, power=0.85):
    """meia-lua de rastro: P = pivo local; angulos em graus (tela: x direita, y baixo); retorna indices (26 aro, 22 corpo, 19 miolo escuro) e poligono"""
    cx, cy = bx + P[0], byy + P[1]; dx, dy = XX + .5 - cx, YY + .5 - cy; r = np.hypot(dx, dy); th = np.degrees(np.arctan2(dy, dx)); t = (th - a0) / (a1 - a0)
    thick = Tmax * np.sin(np.pi * np.clip(t, 0, 1) ** power) ** 0.9
    ins = (t >= 0) & (t <= 1) & (r <= Ro) & (r >= Ro - thick) & (thick > 0.6)
    out = -np.ones((H, W), int); d = (Ro - r) / np.maximum(thick, 1e-6)
    out[ins & (d < .22)] = 26; out[ins & (d >= .22) & (d < .62)] = 22; out[ins & (d >= .62)] = 19
    tip = ins & (thick < 2.6) & ((XX + YY) % 2 == 1); out[tip] = -1
    st = (t >= 0.18) & (t <= 0.75) & (r >= Ro + 2) & (r <= Ro + 3.2) & ((XX * 3 + YY) % 5 == 0); out[st] = 22                     # fiapos de velocidade
    ts = np.linspace(0, 1, 14); th_ = lambda tt: math.radians(a0 + (a1 - a0) * tt)
    outer = [(cx + Ro * math.cos(th_(tt)), cy + Ro * math.sin(th_(tt))) for tt in ts]
    inner = [(cx + (Ro - Tmax * math.sin(math.pi * tt ** power) ** 0.9) * math.cos(th_(tt)), cy + (Ro - Tmax * math.sin(math.pi * tt ** power) ** 0.9) * math.sin(th_(tt))) for tt in ts[::-1]]
    return out, outer + inner
def arc3(P, Ro, a0, a1, Tmax, bx, byy, power=0.85):
    """ARCO v3.1 (regra geral: meia-lua CHEIA, 3 faixas + filete, 2 quadros): borda cinza-clara (16), meio marrom-escuro (10 -> 8),
    interior quase preto (5) e um filete vermelho-sangue (22). P = pivo local; angulos em graus (tela, y para baixo)."""
    cx, cy = bx + P[0], byy + P[1]; dx, dy = XX + .5 - cx, YY + .5 - cy; r = np.hypot(dx, dy); th = np.degrees(np.arctan2(dy, dx)); lo, hi = (a1, a0) if a1 < a0 else (a0, a1); th = lo + np.mod(th - lo, 360.0); t = (th - lo) / (hi - lo)
    if a1 < a0: t = 1 - t
    tt = np.clip(t, 0, 1); thick = Tmax * np.sin(np.pi * tt ** power) ** 0.8
    ins = (t >= 0) & (t <= 1) & (r <= Ro) & (r >= Ro - thick) & (thick > 0.6)
    out = -np.ones((H, W), int); d = (Ro - r) / np.maximum(thick, 1e-6); dep = Ro - r                      # d = fracao de profundidade; dep = px desde a borda externa
    out[ins & (d >= .50)] = 5                                                                              # interior quase preto
    out[ins & (d < .50)] = 8; out[ins & (d < .27)] = 10                                                    # meio marrom-escuro (2 degraus)
    fil = ins & (thick > 7) & (np.abs(d - .50) < max(.5 / max(Tmax, 1), 0.035)); out[fil] = 22             # filete vermelho entre o marrom e o preto
    out[ins & (dep < 1.6)] = 16                                                                            # borda cinza-clara (externa, ~2 px)
    thin = ins & (thick < 3.2); out[thin & ((XX + YY) % 2 == 1)] = -1; out[thin & (out == -1) & False] = -1
    hl = ins & (dep < 1.6) & (thick > 9) & (t > .25) & (t < .62) & (((XX + YY) % 3) == 0); out[hl] = 18      # pontos de brilho na borda
    ts = np.linspace(0, 1, 18); th_ = lambda q: math.radians(a0 + (a1 - a0) * q)
    thk = lambda q: Tmax * np.sin(np.pi * q ** power) ** 0.8
    outer = [(cx + (Ro + 1.5) * math.cos(th_(q)), cy + (Ro + 1.5) * math.sin(th_(q))) for q in ts]
    inner = [(cx + (Ro - thk(q) - 1.0) * math.cos(th_(q)), cy + (Ro - thk(q) - 1.0) * math.sin(th_(q))) for q in ts[::-1]]
    return out, outer + inner
def cape_chute(cv, prop, sp, bx):
    """capa-paraquedas: inflada para cima e para tras do pescoco (dome com barra recortada); sp['chute'] = escala 0..1.2, sp['chute_ph'] = fase da ondulacao"""
    from PIL import Image, ImageDraw
    s = sp['chute']; ph = sp.get('chute_ph', 0); dy = sp.get('dy', 0); lean = sp.get('lean', 0)
    nx = bx + prop['cape_xt'] + 5 + int(round(lean * .4)) + sp.get('chute_dx', 0); ny = BY + prop['ty0'] + 3 + dy                  # ponto de fixacao (nuca)
    pts = [(1, 1), (-1, -7), (-5, -14), (-11, -19), (-18, -20), (-24, -16), (-27, -9), (-27, -1), (-25, 7)]
    sc = lambda p: (nx + p[0] * s * .9, ny + p[1] * s * (1.55 if p[1] < 0 else 1))
    poly = [sc(p) for p in pts]
    hem = [(-25 + 4 * i, 7 + 6 * s + (3 if i % 2 else 0) * s + 1.5 * math.sin(ph + i)) for i in range(0, 8)]   # barra recortada (pontas)
    poly += [sc((hx, hy)) if False else (nx + hx * s * 1.0 + (0 if hx < -3 else 0), ny + hy) for hx, hy in hem[::1]]
    poly = [(x, y) for x, y in poly]
    # contorno: polilinha -> mascara
    im = Image.new('L', (W, H), 0); ImageDraw.Draw(im).polygon(poly + [(nx + 3, ny + 9 * s + 2), (nx + 2, ny + 3)], fill=255); m = np.array(im) > 0
    er = ndi.binary_erosion(m, structure=ST8, border_value=0); edge = m & ~er; inn = m & ~edge
    cv.a[inn] = 1
    y0, x0 = np.nonzero(m); cxm = x0.mean() if len(x0) else 0
    # luz: borda superior/externa clara (2), dobras radiais escuras (0)
    ang = np.arctan2(YY + .5 - ny, XX + .5 - nx)
    for i, a_ in enumerate(np.linspace(math.radians(95), math.radians(250), 6)):
        da = np.abs(np.angle(np.exp(1j * (ang - a_)))); cv.a[inn & (da < .045 + .02 * (i % 2)) & (np.hypot(XX - nx, YY - ny) > 4)] = 0
    top = inn & ~np.roll(inn, 1, 0); cv.a[top & (YY < ny - 4)] = 2
    cv.a[inn & np.roll(inn, 1, 0) & ~np.roll(inn, 2, 0) & (YY < ny - 4)] = np.where(cv.a[inn & np.roll(inn, 1, 0) & ~np.roll(inn, 2, 0) & (YY < ny - 4)] == 0, 0, 1)
    cv.a[edge] = 3
