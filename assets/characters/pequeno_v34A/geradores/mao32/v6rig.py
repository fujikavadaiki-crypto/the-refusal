"""v5 (pequeno A v3.3): capa em onda (corrida), capa para a frente (freio) e SMEAR do dash. Mesmo rig/paleta; so acrescenta desenhos."""
import sys; sys.path.insert(0, '/tmp/claude-0/p41')
import numpy as np, math
import v4rig as R, v4anim as A, v3spr as V
from v4rig import BX, BY, GR, H, W, XX, YY, ST8
from scipy import ndimage as ndi
_orig_cape = R.cape
def _fill_band(cv, cols, xs, yu, yl, ph, s_of, cut=None, light=True, fold=(.36, .66), tail_dark=.78):
    """preenche colunas x com y de yu a yl: contorno 3, miolo 1, filetes escuros 0 tracejados e luz 2 na borda de cima."""
    for i, x in enumerate(xs):
        s = s_of[i]; a = yu[i]; b = yl[i]
        y0 = int(math.ceil(a)); y1 = int(math.floor(b))
        if y1 < y0: continue
        for y in range(y0, y1 + 1):
            if cut is not None and x < cut(y): continue
            if not (0 <= y < H and 0 <= x < W): continue
            t = (y - a) / max(b - a, 1e-6)
            if y == y0 or y == y1: v = 3
            elif s > tail_dark: v = 0 if (x + y) % 4 else 1
            elif y == y0 + 1 and light and s > .08: v = 2 if (x // 2) % 3 else 1
            elif any(abs(t - f) < max(.5 / max(b - a, 1), .07) for f in fold) and ((x // 3) + int(round(fold[0] * 10))) % 2 == 0: v = 0
            else: v = 1
            cv.a[y, x] = v
def cape_stream(cv, prop, sp, bx):
    """capa LONGA arrastando para tras e ondulando: duas bordas (cima: nuca; baixo: barra) que se juntam numa ponta recortada; a onda viaja para tras.
    sp['stream'] = dict(L comprimento, rise quanto a barra sobe ate a ponta, ht espessura da ponta, amp amplitude da onda (px), ph fase, fwd=False)"""
    st = sp['stream']; dy = sp.get('dy', 0); lean = sp.get('lean', 0)
    ty0, hem = prop['ty0'], prop['hem']; tx = prop['tx']
    L = st['L']; rise = st['rise']; ht = st['ht']; amp = st['amp']; ph = st['ph']
    shear = lambda r: int(round(lean * 0.9 * max(0.0, 1 - r / 21.0)))
    xT = bx + tx + 2 + shear(2); yT = BY + ty0 + 2 + dy                  # nuca
    xB = bx + tx + 1; yB = BY + hem + 3 + dy                              # barra junto ao corpo
    xe = xB - L; xs = list(range(max(xT, xB) + 3, xe - 1, -1)); n = len(xs); x0 = xs[0]
    yu = []; yl = []; ss = []
    yTailL = yB - rise; yTailU = yTailL - ht
    for x in xs:
        s = (x0 - x) / float(max(x0 - xe, 1)); wu = amp * math.sin(ph - 6.2 * s) * (s ** 1.05); wl = amp * math.sin(ph - 6.2 * s - 0.9) * (s ** 1.05)
        scal = 1.0 if (s > .25 and (x // 3) % 2 == 0) else 0.0                       # barra recortada (dentes)
        yu.append(yT + (yTailU - yT) * (s ** 0.9) + wu); yl.append(yB + (yTailL - yB) * (s ** 1.25) + wl - scal); ss.append(s)
    cut = lambda y: xe + ((y * 3 + int(round(ph * 2))) % 4) - 1
    _fill_band(cv, None, xs, yu, yl, ph, ss, cut=cut)
def _cape(cv, prop, sp, bx):
    if 'stream' in sp: cape_stream(cv, prop, sp, bx)
    else: _orig_cape(cv, prop, sp, bx)
R.cape = _cape
# ---------------------------------------------------------------------------------------- CAPA PARA A FRENTE (freio)
def fwd_flap(b, prop, sp, bx):
    """freio: a capa, por inercia, passa para a FRENTE das pernas (pintada sobre as botas, abaixo da barra do tronco). sp['flap_fwd'] = dict(L, rise, ph)"""
    st = sp['flap_fwd']; dy = sp.get('dy', 0); hem = prop['hem']
    y_top = BY + hem + dy + 1; x0 = bx + 12; L = st['L']; ph = st['ph']
    for i in range(L):
        s_ = i / float(max(L - 1, 1)); x = x0 + i
        u = y_top + 1.5 * s_ + 2.2 * math.sin(ph + 3.4 * s_) * s_
        l = u + 8 * (1 - s_) ** 0.9 + 2 - st['rise'] * s_ ** 1.2
        for y in range(int(math.ceil(u)), int(math.floor(l)) + 1):
            if not (0 <= y < H and 0 <= x < W): continue
            if y > GR: continue
            edge = (y == int(math.ceil(u))) or (y == int(math.floor(l))) or i == L - 1
            if i > L - 4 and (y * 3 + x) % 4 == 0: continue
            t = (y - u) / max(l - u, 1e-6)
            b[y, x] = 3 if edge else (0 if (t > .62 or (x // 3) % 3 == 0) else 1)
# ---------------------------------------------------------------------------------------- SMEAR
def smear(sp, pr='A'):
    """quadro de SMEAR do dash: capuz na frente, corpo e capa esticados numa faixa em virgula/meia-lua (~2x o comprimento normal), so em tons da paleta:
    capa escura (0/1/2) + filete vermelho (22/26) + borda clara (16/18) + couro do corpo (8/10). Sem desenho de rastro fora da faixa."""
    from v4anim_base import PROPS
    prop = PROPS[pr]; cv = R.Cv(); fx = R.Cv(); bx = BX
    Ls = sp['Ls']; T0 = sp['T0']; bend = sp['bend']; yc0 = BY + sp['yc']; ph = sp.get('ph', 0); xh = bx + sp['hx']; Tt = sp.get('Tt', 3.5)
    m = np.zeros((H, W), bool); ysu = {}; ysl = {}; xs = list(range(int(xh), int(xh - Ls) - 1, -1))
    for x in xs:
        s = (xh - x) / float(Ls)
        T = Tt + (T0 - Tt) * max(0.0, 1 - s ** sp.get('tp', 1.7)) ** 1.05
        hr = sp.get('hr', 0.0)
        if hr and s < hr: T *= math.sqrt(max(0.0, 1 - ((hr - s) / hr) ** 2)) * 0.8 + 0.2        # ponta grossa arredondada junto ao capuz
        yc = yc0 - bend * s ** sp.get('be', 1.4) + sp.get('wob', 0) * math.sin(ph - 4.5 * s) * s
        u = yc - T * 0.45; l = yc + T * 0.55 + (0.10 * T if .12 < s < .55 else 0.0) + 1.3 * math.sin(ph - 7.0 * s) * s
        if s > .22 and (x // 3) % 2 == 0: l -= 1.0                                   # barra recortada da capa
        ysu[x] = u; ysl[x] = l
        for y in range(int(math.ceil(u)), int(math.floor(l)) + 1):
            if 0 <= y < H and 0 <= x < W: m[y, x] = True
    xe = int(xh - Ls)
    for y in range(H):
        for x in range(xe, xe + 3):
            if 0 <= x < W and m[y, x] and ((y * 3 + x) % 4 == 0): m[y, x] = False
    er = ndi.binary_erosion(m, structure=ST8, border_value=0); edge = m & ~er; inn = m & ~edge
    cv.a[inn] = 1; cv.a[edge] = 3
    for x in xs:
        s = (xh - x) / float(Ls); u = ysu[x]; l = ysl[x]; T = l - u
        col = np.nonzero(inn[:, x])[0]
        if len(col) == 0: continue
        top = col.min()
        for y in col:
            tt = (y - u) / max(T, 1e-6)
            if tt > .70: cv.a[y, x] = 0
            elif tt > .56 and (x // 2) % 2: cv.a[y, x] = 0
        if s > .05: cv.a[top, x] = (16 if (x % 5) else 18) if (x // 2) % 3 else 2        # borda clara no topo
        if .26 > s >= .0 and T >= 8:                                                     # couro do corpo (ombro/braco) junto do capuz
            for y in col:
                tt = (y - u) / max(T, 1e-6)
                if .12 < tt < .38: cv.a[y, x] = 10 if (x + y) % 5 else 12
                elif .38 <= tt < .46: cv.a[y, x] = 8
        if .10 < s < .94 and T >= 5:
            yr = int(round(u + .46 * T))
            if m[yr, x] and cv.a[yr, x] != 3: cv.a[yr, x] = 22 if (x // 4) % 3 else 26
            if T >= 12 and s < .62 and m[yr + 1, x] and cv.a[yr + 1, x] != 3 and (x % 3): cv.a[yr + 1, x] = 22
    if sp.get('blade', True):                                                            # lamina arrastando: fio claro colado sob a faixa
        for x in xs:
            s = (xh - x) / float(Ls)
            if .30 < s < .90:
                y = int(math.floor(ysl[x])) + 1 + sp.get('bl_dy', 0)
                if 0 <= y < H and cv.a[y, x] < 0: cv.a[y, x] = 16 if (x % 4) else 18
                if s < .55 and 0 <= y + 1 < H and cv.a[y + 1, x] < 0: cv.a[y + 1, x] = 14
                if s < .45 and 0 <= y + 2 < H and cv.a[y + 2, x] < 0: cv.a[y + 2, x] = 3
    HEAD = prop['HEAD']; hh, hw = HEAD.shape
    cv.put(HEAD, int(round(xh - hw / 2.0 + sp.get('head_dx', 3))), BY + sp['hy'])
    for (x, y, col) in sp.get('extra', ()):
        if 0 <= BY + y < H and 0 <= bx + x < W: fx.a[BY + y, bx + x] = col
    if not sp.get('nofloor'): cv.a[GR + 1:, :] = -1; fx.a[GR + 1:, :] = -1
    return cv.a, fx.a, {'blade_poly': [(0, 0), (1, 0), (1, 1)]}
