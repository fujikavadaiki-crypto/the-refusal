#!/usr/bin/env python3
"""Empacota o Carrasco pequeno A v3.3 (CORRIDA v2 + DASH com SMEAR; resto igual a v3.2): pacote_pequeno_v34A com manifesto, quadros, efeitos, sombras, hitbox por quadro ATIVO."""
import os, sys, json, shutil, hashlib, math, re
sys.path.insert(0, '/tmp/claude-0/p41'); sys.path.insert(0, '/tmp/claude-0/p41/v6'); sys.path.insert(0, '/tmp/claude-0/proj/prova/c1_carrasco/geradores')
import numpy as np
from PIL import Image, ImageDraw
from c51_lib import PAL
import v4anim as A, v4poses as V, v3poses as P0, v4rig as R, v6poses as P5
from v4anim import lagcape
OUT = '/tmp/claude-0/p41/pack6'; PK = OUT + '/pacote_pequeno_v34A'; TRES = '/tmp/claude-0/p40/proj/data/attacks/'
V31 = '/tmp/claude-0/p31pack/pacote_pequeno_v31A'
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
PALSET = {tuple(c) for c in PAL.astype(int)}
AXL = R.BX + 15; S = R.GR
IDLE_CAPE = dict(trail=3, lift=0, flap=1, ph=0); AIR_CAPE = dict(trail=2, lift=4, flap=2, ph=2)
def tres(name):
    t = open(TRES + name + '.tres').read(); g = lambda k: float(re.search(k + r' = ([0-9.]+)', t).group(1)); return dict(windup=g('windup_seconds'), active=g('active_seconds'), recovery=g('recovery_seconds'))
# nome: (poses, ms, loop, sombra_meia_largura, prev_cape, ataque{id, n_prep, n_ativo, ativos, clip_floor})
def seqs():
    run8 = [P5.run8(k) for k in range(8)]
    H = [P0.heavy(k) for k in range(9)]
    d = {
     'idle': (lambda: lagcape([V.idle4(k) for k in range(8)], loop=True), V.IDLE4_MS, True, 14, None, None),
     'run': (lambda: P5.lag5(run8, loop=True), [P5.RUN_MS] * 8, True, 14, None, None),
     'run_start': (lambda: P5.lag5([P5.run_start()], prev=IDLE_CAPE), [50], False, 14, None, None),
     'run_stop': (lambda: P5.lag5([P5.run_stop()], prev=dict(stream=P5.STREAM_RUN_PREV)), [66], False, 14, None, None),
     'turn': (lambda: lagcape([V.turn_frame()], prev=dict(trail=8, lift=1, flap=2, ph=1)), [50], False, 14, None, None),
     'attack_exit': (lambda: lagcape([V.attack_exit()], prev=IDLE_CAPE), [66], False, 14, None, None),
     'dash': (lambda: P5.lag5(P5.dash5(), prev=IDLE_CAPE), P5.DASH5_MS, False, 16, None, None),
     'dash_ar': (lambda: P5.lag5(P5.dash_air5(), prev=AIR_CAPE), P5.DASH5_MS, False, 16, None, None),
     'jump_up': (lambda: lagcape([P0.jump_up(k) for k in range(2)], prev=IDLE_CAPE), P0.JUMPUP_MS, False, 12, None, None),
     'fall_start': (lambda: lagcape([P0.fall_start(k) for k in range(2)], prev=dict(trail=2, lift=-1, flap=2, ph=1)), P0.FALLS_MS, False, 12, None, None),
     'fall_loop': (lambda: lagcape([P0.fall_loop(k) for k in range(3)], prev=dict(trail=1, lift=5, flap=3, ph=3, chute=0.55, chute_ph=1.0), loop=True), P0.FALLL_MS, True, 12, None, None),
     'land': (lambda: lagcape([V.land4(0), V.land4(1)], prev=dict(trail=1, lift=6, flap=3, ph=4)), [50, 70], False, 15, None, None),
     'hurt': (lambda: lagcape([P0.hurt(k) for k in range(3)], prev=IDLE_CAPE), P0.HURT_MS, False, 13, None, None),
     'heavy': (lambda: lagcape(H, prev=IDLE_CAPE), P0.HEAVY_MS, False, 17, None, dict(id='carrasco_heavy', prep=4, ativos=[4, 5], clip_floor=True)),
     'light1': (lambda: lagcape(V.light1(), prev=IDLE_CAPE), V.L1_MS, False, 16, None, dict(id='carrasco_light_1', prep=2, ativos=V.L1_ACTIVE, clip_floor=True)),
     'light2': (lambda: lagcape(V.light2(), prev=IDLE_CAPE), V.L2_MS, False, 16, None, dict(id='carrasco_light_2', prep=3, ativos=V.L2_ACTIVE, clip_floor=True)),
     'light3': (lambda: lagcape(V.light3(), prev=IDLE_CAPE), V.L3_MS, False, 17, None, dict(id='carrasco_light_3', prep=3, ativos=V.L3_ACTIVE, clip_floor=True)),
     'post_dash': (lambda: lagcape(V.post_dash(), prev=dict(trail=14, lift=0, flap=1, ph=2)), V.PD_MS, False, 18, None, dict(id='carrasco_post_dodge', prep=2, ativos=V.PD_ACTIVE, clip_floor=True)),
     'air_light': (lambda: lagcape(V.air_light(), prev=AIR_CAPE), V.AL_MS, False, 15, None, dict(id='carrasco_air_light', prep=2, ativos=V.AL_ACTIVE, clip_floor=False)),
     'air_heavy': (lambda: lagcape(V.air_heavy(), prev=AIR_CAPE), V.AH_MS, False, 17, None, dict(id='carrasco_air_heavy', prep=3, ativos=V.AH_ACTIVE, clip_floor=False, pouso_a_partir=V.AH_LAND_FROM)),
     'charge_start': (lambda: lagcape(V.charge_start(), prev=IDLE_CAPE), V.CH_START_MS, False, 15, None, None),
     'charge_loop': (lambda: lagcape(V.charge_loop(), prev=dict(trail=2, lift=-1, flap=1, ph=3), loop=True), V.CH_LOOP_MS, True, 15, None, None),
     'charge_full': (lambda: lagcape(V.charge_full(), prev=dict(trail=2, lift=-1, flap=1, ph=3), loop=True), V.CH_FULL_MS, True, 15, None, None),
     'charged_heavy': (lambda: lagcape(V.charged_heavy(), prev=dict(trail=2, lift=-1, flap=1, ph=3)), V.CHV_MS, False, 19, None, dict(id='carrasco_charged_heavy', prep=2, ativos=V.CHV_ACTIVE, clip_floor=True)),
     'parry': (lambda: lagcape(V.parry(), prev=IDLE_CAPE), V.PARRY_MS, False, 15, None, None),
    }
    return d
def rgba(m):
    h, w = m.shape; o = np.zeros((h, w, 4), np.uint8); a = m >= 0; o[a, :3] = PAL[m[a]]; o[a, 3] = 255; return o
def wr(path, arr): os.makedirs(os.path.dirname(path), exist_ok=True); Image.fromarray(arr, 'RGBA').save(path); return sha(path)
def clip_poly(poly, keep):
    """Sutherland-Hodgman contra um semiplano; keep(p) -> distancia assinada >= 0 dentro."""
    out = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]; da, db = keep(a), keep(b)
        if da >= 0: out.append(a)
        if (da >= 0) != (db >= 0):
            t = da / (da - db); out.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
    return out
def area(poly): return 0.5 * sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))
def hitbox_for(info, body, fx, sp, atk, ay_full):
    """poligonos (px relativos a ancora) RECORTADOS: so a parte a frente do corpo (x >= 0) e acima do chao (y <= 0, exceto aereos)."""
    ax_full = AXL; rel = lambda poly: [(x - ax_full, y - ay_full) for x, y in poly]
    clip_floor = atk['clip_floor']
    def cut(poly):
        p = clip_poly(rel(poly), lambda q: q[0] - 0.0)
        if clip_floor and p: p = clip_poly(p, lambda q: 0.0 - q[1])
        return p if len(p) >= 3 and abs(area(p)) >= 1.0 else []
    parts = {}
    ar = info.get('cres_poly') or info.get('thrust_poly'); bl = info['blade_poly']
    if ar: parts['arco'] = cut(ar)
    parts['lamina'] = cut(bl)
    # cobertura medida: pixels do arco (5,8,10,16,18,22) e da lamina (14,16,18) a frente do corpo (x>=0, y<=0) dentro dos poligonos
    from PIL import ImageDraw
    mk = Image.new('L', (R.W, R.H), 0); dr = ImageDraw.Draw(mk)
    for k, p in parts.items():
        if p: dr.polygon([(x + ax_full, y + ay_full) for x, y in p], fill=255)
    cov = np.array(mk) > 0
    XXr = R.XX - ax_full; YYr = R.YY - ay_full
    front = (XXr + .5 >= 0) & ((YYr + .5 <= 0) if clip_floor else True)
    fxm = np.isin(fx, (5, 8, 10, 16, 18, 22)); blm = np.isin(body, (14, 16, 18)) & A.poly_mask(info['blade_poly'])
    tot = (fxm & front).sum() + (blm & front).sum(); ins = (fxm & front & cov).sum() + (blm & front & cov).sum()
    allp = [pt for p in parts.values() for pt in p]
    if allp: x0, y0, x1, y1 = math.floor(min(p[0] for p in allp)), math.floor(min(p[1] for p in allp)), math.ceil(max(p[0] for p in allp)), math.ceil(max(p[1] for p in allp)); uni = [x0, y0, x1 - x0, y1 - y0]
    else: uni = [0, 0, 0, 0]
    # pixels do arco/lamina ATRAS do corpo (x<0), excluidos do dano
    back = (fxm & ~front).sum() + (blm & ~front).sum()
    r1 = lambda poly: [[round(x, 1), round(y, 1)] for x, y in poly]
    hb = {'fase': 'ATIVO', 'tipo': 'arco/lamina recortados a frente do corpo', 'origem': 'poligono do arco (ou lente da estocada) + poligono da lamina, RECORTADOS: so x >= 0 (da cabeca para a frente) ' + ('e y <= 0 (ate o chao)' if clip_floor else '(golpe aereo: sem corte no chao)') + '; px relativos a ancora (x direita, y baixo)',
          'recorte': {'x_minimo': 0, 'y_maximo': 0 if clip_floor else None}, 'retangulo_uniao': uni,
          'cobertura_pixels_pct': round(100 * ins / max(tot, 1), 1), 'pixels_atras_do_corpo_excluidos': int(back), 'espelha_com_a_direcao': 'inverter x quando o Carrasco olha para a esquerda'}
    for k, p in parts.items():
        if p: hb[k] = {'poligono': r1(p)}
    return hb
def spark_frames():
    """faisca do parry: 3 quadros (cruz -> estrela -> fagulhas), 25x25, ancora no centro."""
    out = []; c = 12
    def px(a, x, y, col):
        if 0 <= x < 25 and 0 <= y < 25: a[y, x] = col
    for k in range(3):
        a = -np.ones((25, 25), int)
        if k == 0:
            for d in range(-3, 4): px(a, c + d, c, 18 if abs(d) < 2 else 17); px(a, c, c + d, 18 if abs(d) < 2 else 17)
            px(a, c, c, 18)
        elif k == 1:
            for d in range(-9, 10):
                col = 18 if abs(d) < 3 else (17 if abs(d) < 6 else (16 if abs(d) < 8 else 31))
                px(a, c + d, c, col); px(a, c, c + d, col)
            for d in range(-5, 6):
                col = 17 if abs(d) < 3 else 31
                px(a, c + d, c + d, col); px(a, c + d, c - d, col)
            for (x, y) in ((c - 2, c - 2), (c + 2, c + 2), (c - 2, c + 2), (c + 2, c - 2)): px(a, x, y, 18)
            px(a, c, c, 18)
        else:
            import random; r = random.Random(7)
            for i in range(14):
                ang = i * (2 * math.pi / 14) + .2; d = r.uniform(6, 11); px(a, int(round(c + d * math.cos(ang))), int(round(c + d * math.sin(ang))), (18, 17, 31, 26, 16)[i % 5])
            for d in (9, 10): px(a, c + d, c, 31); px(a, c - d, c, 31); px(a, c, c + d, 31); px(a, c, c - d, 31)
        out.append(a)
    return out
NOTAS = {'idle': 'respiracao (peito sobe, cabeca atrasa 1 px), lamina oscilando e capa viva (atraso de 1 quadro); 2000 ms em laco',
         'run': 'CORRIDA v2: 8 q a 6 px/q (41,67 ms, 144 px/s, 48 px por ciclo): tronco MUITO inclinado (~26 graus), corpo baixo, capa LONGA em onda (atraso de 1 q, ponta +-3 px por passo), cabeca sobe 1 px, lamina baixa arrastando atras, pernas curtas; cada pe fica no chao 3 q sem deslizar',
         'run_stop': 'FREIO da corrida: 1 q (derrapa, tronco para tras, capa passa para a frente das pernas), 66 ms',
         'run_start': 'PARTIDA da corrida: 1 q inclinando forte (corpo baixo, capa ainda caida), mostrado nos primeiros 6 px', 'turn': 'VIRADA de direcao: 1 q (derrapa, tronco para tras, pes abertos), 50 ms',
         'attack_exit': 'SAIDA do ataque para o idle: 1 q (lamina volta ao porte), 66 ms', 'dash': 'dash no chao, 4 q = 350 ms: ARRANQUE (corpo comprimido + poeira) 50 / SMEAR (1 q, virgula compacta ~1,3x o corpo) 60 / POSE ESTICADA (corpo inclinado, capa longa reta, lamina recolhida) 190 / FREIO (derrapa, capa para a frente + poeira) 50; 112 px = 0,32 px/ms; a nevoa de sangue (fantasmas, mais curta) e feita pelo apresentador',
         'dash_ar': 'dash no ar, 4 q = 350 ms: mesmo arranque / smear 60 / pose esticada 190 / freio, sem poeira', 'jump_up': 'subida (2 q)', 'fall_start': 'queda - inicio (2 q)', 'fall_loop': 'queda - laco (3 q): capa paraquedas', 'land': 'POUSO: 2 q de impacto (agachar fundo + poeira / levantar), 120 ms',
         'hurt': 'dano: 3 x 60 ms', 'heavy': 'heavy: prep 4 q (320) / arco gigante 2 q (140) / parado 3 q (430) = 890 ms; DANO so a frente do corpo (x >= 0) ate o chao',
         'light1': 'leve 1 - horizontal baixo: prep 2 q (130) / ativo 2 q (110) / recup 3 q (220) = 460 ms; arco menor que o do heavy',
         'light2': 'leve 2 - diagonal subindo: prep 3 q (160) / ativo 2 q (110) / recup 3 q (250) = 520 ms', 'light3': 'leve 3 - de cima para baixo, arco maior: prep 3 q (220) / ativo 2 q (130) / recup 4 q (320) = 670 ms',
         'post_dash': 'pos-dash - estocada com arco RETO (lente): prep 2 q (120) / ativo 2 q (110) / recup 3 q (270) = 500 ms', 'air_light': 'aereo leve - giro com arco circular: prep 2 q (130) / ativo 2 q (120) / recup 3 q (270) = 520 ms',
         'air_heavy': 'aereo pesado - mergulho: prep 3 q (250) / ativo 2 q (130) / recup 5 q (390): q5 = segura no ar; q6..q9 = IMPACTO NO POUSO (rodam a partir do instante em que toca o chao)',
         'charge_start': 'carregar - entrada: 2 q (60 ms cada), mesmas poses do inicio do heavy (um toque rapido segue direto para o heavy)', 'charge_loop': 'carregar - laco 4 q x 90 ms: tremor de 1 px + brilho vermelho pulsando na lamina',
         'charge_full': 'carregar - PRONTO (>= 1,0 s): laco 4 q x 70 ms, brilho forte + fagulhas', 'charged_heavy': 'golpe carregado: prep 2 q (160) / arco MAIOR e mais longo 2 q (140) / recup 5 q (480) = 780 ms',
         'parry': 'parry: 4 q = 380 ms (guarda subindo 50 / guarda 110 / segura 100 / volta 120); ativo 0-160 ms'}
def build():
    if os.path.exists(PK): shutil.rmtree(PK)
    os.makedirs(PK + '/paleta')
    for f in ('carrasco_c51_travada.gpl', 'carrasco_c51_travada.json'): shutil.copy(V31 + '/paleta/' + f, PK + '/paleta/' + f)
    old = json.load(open(V31 + '/manifesto_sprites.json')); pal_sha = sha(PK + '/paleta/carrasco_c51_travada.gpl'); assert old['paleta']['sha256'] == pal_sha
    anims = []; usadas = set(); FRAMES = {}; sq = seqs()
    for an, (fn, ms, loop, sw, _, atk) in sq.items():
        poses = fn(); n = len(poses); assert len(ms) == n, (an, len(ms), n)
        rend = [P5.render5(sp) for sp in poses]; nofl = any(sp.get('nofloor') for sp in poses)
        shm = np.zeros((R.H, R.W), bool)
        for dy_, w_ in ((2, sw), (3, sw - 3)): shm[S + dy_, AXL - w_:AXL + w_ + 1] = True
        allm = shm.copy()
        for b, f, _i in rend: allm |= (b >= 0) | (f >= 0)
        ys, xs = np.nonzero(allm); y0, y1, x0, x1 = max(ys.min() - 1, 0), ys.max(), max(xs.min() - 1, 0), xs.max() + 1
        crop = lambda a: a[y0:y1 + 1, x0:x1 + 1]
        ax = AXL - x0; ay = S + 1 - y0; h, w = crop(rend[0][0]).shape
        sh2 = np.zeros((R.H, R.W), bool); sh2[S + 1, AXL - sw:AXL + sw + 1] = True; sh2[S + 2, AXL - (sw - 3):AXL + (sw - 3) + 1] = True; shc = crop(sh2)
        s2 = np.zeros((h, w, 4), np.uint8); s2[shc, :3] = PAL[3]; s2[shc, 3] = 255; sarq = f'sombras/{an}_sombra.png'; shs = wr(f'{PK}/{sarq}', s2)
        quadros = []; efs = []
        assert total_ok(ms)
        for k in range(n):
            b = crop(rend[k][0]); f = crop(rend[k][1])
            if not nofl: assert not (b[ay:] >= 0).any(), (an, k)
            arq = f'quadros/{an}/{an}_f{k}.png'; hh = wr(f'{PK}/{arq}', rgba(b)); yy, xx = np.nonzero(b >= 0); usadas |= set(np.unique(b[b >= 0]).tolist())
            q = {'arquivo': arq, 'largura': int(w), 'altura': int(h), 'ancora': [int(ax), int(ay)], 'pivo': [int(ax), int(ay)], 'ms': round(float(ms[k]), 2), 'sha256': hh, 'nome_origem': f'v4_A_{an}_f{k}',
                 'corpo_bbox': [int(xx.min()), int(yy.min()), int(xx.max()), int(yy.max())],
                 'sombra': {'arquivo': sarq, 'ancora': [int(ax), int(ay)], 'largura': int(w), 'altura': int(h), 'pixels': int(shc.sum()), 'sha256': shs}, 'hitbox': None}
            ativo = bool(atk and k in atk['ativos'])
            if (f >= 0).any():
                earq = f'efeitos/{an}_fx_f{k}.png'; eh = wr(f'{PK}/{earq}', rgba(f)); usadas |= set(np.unique(f[f >= 0]).tolist())
                efs.append({'quadro': k, 'arquivo': earq, 'ancora': [int(ax), int(ay)], 'largura': int(w), 'altura': int(h), 'camada': 'atras_do_corpo', 'fase': 'ATIVO' if (ativo and ('arc' in poses[k] or 'thrust' in poses[k])) else 'todas', 'pixels': int((f >= 0).sum()), 'sha256': eh})
            if ativo: q['hitbox'] = hitbox_for(rend[k][2], rend[k][0], rend[k][1], poses[k], atk, S + 1)
            quadros.append(q)
        a_ = {'id': an, 'tipo': 'animacao', 'loop': bool(loop), 'quadros_n': n, 'duracao_total_ms': round(float(sum(ms)), 2), 'nota_tempo': NOTAS[an], 'quadros': quadros,
              'sombra': {'por_quadro': False, 'arquivo': sarq, 'aplica_a': 'todos os quadros; fica no chao (nao acompanha o voo)'}, 'efeitos': efs,
              'capa': 'capa SEMPRE viva: o movimento de cada quadro vem do quadro ANTERIOR (atraso de 1 quadro em relacao ao corpo); faz parte do corpo',
              'camadas': 'ORDEM DE TRAS PARA FRENTE: capa -> bota distante -> bota proxima -> tronco/pano -> cabeca -> LAMINA -> braco/ombreira; efeitos atras do corpo.'}
        if an == 'run': a_.update(px_por_quadro=6, velocidade_px_s=144, ms_por_quadro=round(P5.RUN_MS, 2), apoios=[1, 5])
        if an in ('dash', 'dash_ar'): a_.update(deslocamento_total_px=112, velocidade_px_s=320, nota_desloc='mover o personagem 0,32 px/ms durante os 350 ms (nao por quadro)')
        if atk:
            t = tres(atk['id'].replace('carrasco_', 'carrasco_')); np_ = atk['prep']; na = len(atk['ativos']); tot = lambda a, b: round(sum(ms[a:b]), 2)
            fases = {'PREPARACAO': {'quadros': list(range(0, np_)), 'ms': tot(0, np_)}, 'ATIVO': {'quadros': list(atk['ativos']), 'ms': tot(np_, np_ + na)}, 'RECUPERACAO': {'quadros': list(range(np_ + na, n)), 'ms': tot(np_ + na, n)}}
            exp = (round(t['windup'] * 1000, 2), round(t['active'] * 1000, 2), round(t['recovery'] * 1000, 2)); got = (fases['PREPARACAO']['ms'], fases['ATIVO']['ms'], fases['RECUPERACAO']['ms']); assert exp == got, (an, exp, got)
            assert list(atk['ativos']) == list(range(np_, np_ + na))
            a_['ataque'] = {'attack_id': atk['id'], 'tres': {'windup_ms': exp[0], 'active_ms': exp[1], 'recovery_ms': exp[2]}, 'fases': fases, 'soma_confere_com_tres': True, 'dano_recortado': 'so a frente do corpo' + (' e acima do chao' if atk['clip_floor'] else '')}
            if 'pouso_a_partir' in atk: a_['ataque']['pouso_a_partir'] = atk['pouso_a_partir']
        anims.append(a_); FRAMES[an] = (rend, (x0, y0, x1, y1), (ax, ay))
    # faisca do parry (efeito solto, por cima do corpo)
    sk = spark_frames(); sq_ = []
    for k, a in enumerate(sk):
        arq = f'efeitos/parry_spark_f{k}.png'; hh = wr(f'{PK}/{arq}', rgba(a)); usadas |= set(np.unique(a[a >= 0]).tolist()); sq_.append({'arquivo': arq, 'largura': 25, 'altura': 25, 'ancora': [12, 12], 'ms': float(V.PARRY_SPARK_MS[k]), 'sha256': hh, 'sombra': None, 'hitbox': None})
    anims.append({'id': 'parry_spark', 'tipo': 'efeito_solto', 'loop': False, 'quadros_n': 3, 'duracao_total_ms': float(sum(V.PARRY_SPARK_MS)), 'nota_tempo': 'faisca ao aparar (160 ms = parry_succeeded): desenhar POR CIMA do corpo, com a ancora (centro) em pes + posicao_relativa_aos_pes (x espelha)', 'posicao_relativa_aos_pes': [25, -25], 'quadros': sq_, 'efeitos': [], 'sombra': {}})
    assert {tuple(PAL[i].astype(int)) for i in usadas} <= PALSET
    cores = sorted(usadas)
    man = {'pacote': 'pacote_pequeno_v34A', 'versao': 'Carrasco pequeno v3.4A (48 px, cabeca 31 %) - CORRIDA v2 + DASH com SMEAR curto', 'personagem': 'O Carrasco', 'data': '2026-10-02',
           'status': 'TESTE para avaliacao (nao aprovado). v3.4 = v3.3A (corrida aprovada) com o DASH refeito (smear compacto de 1 q + pose esticada); v3.3 = v3.2A com a CORRIDA refeita (8 q, tronco muito inclinado, capa longa em onda, lamina baixa), partida de 1 q, FREIO de 1 q e o DASH com SMEAR de 1 q (arranque 50 / smear 60 / pose esticada 190 / freio 50). Golpes, hitbox e tempos dos ataques identicos a v3.2A. v3.2A e v3.1 intactas.',
           'formato': 'mesmo da v3.1: animacoes[] com quadros (arquivo, ms, ancora), sombra em arquivo proprio, efeitos em camada separada, paleta travada; hitbox por quadro ATIVO (recortada a frente do corpo); animacoes de ataque trazem `ataque` (fases e soma = .tres)',
           'cores': 'SAIDA: todo pixel opaco e uma das cores da paleta C5.1; alfa 0/255.', 'paleta': {'arquivo': 'paleta/carrasco_c51_travada.gpl', 'cores': 44, 'travada': True, 'sha256': pal_sha},
           'cores_usadas': {'quantidade': len(cores), 'indices': cores, 'rgb': [PAL[i].tolist() for i in cores]}, 'proporcao': old['proporcao'], 'ancora_convencao': old['ancora_convencao'], 'capsula_sugerida': old['capsula_sugerida'],
           'rastro_dash': {'regra': 'a cada ~40 ms do dash (chao e ar), uma copia do quadro atual na posicao em que estava, em vermelho-sangue escuro (indice 22 da paleta, RGB 116,3,6), alfa 0,5 -> 0 em ~110 ms, no maximo 3 (v3.3: nevoa mais curta); pixels inteiros, NEAREST. Mais curto no ataque pos-dash. Feito pelo apresentador (nao e arte neste pacote).', 'indice_paleta': 22, 'rgb': [116, 3, 6], 'vida_s': 0.11, 'vida_curta_s': 0.08, 'maximo': 3, 'maximo_curto': 2, 'intervalo_s': 0.04},
           'animacoes': anims, 'prova': {'tira': 'prova/tira_x2.png', 'pes_corrida': 'verificacao/pes_corrida.json'}}
    json.dump(man, open(PK + '/manifesto_sprites.json', 'w'), ensure_ascii=False, indent=1)
    return man, FRAMES
def total_ok(ms): return all(m > 0 for m in ms)
def verif():
    res = {'px_por_quadro': 6, 'ms_por_quadro': round(P5.RUN_MS, 2), 'velocidade_px_s': 144.0,
           'metodo': 'renderiza so a bota; calcanhar = menor coluna da bota nas 3 linhas de baixo; ponta = maior coluna na linha do chao; posicao no mundo = coluna + 6 px x quadro (o corpo anda 6 px por quadro)', 'apoios': {}}
    import v4anim as A_
    for foot, base in (('near', 0), ('far', 4)):
        for kk in (0, 1, 2):
            k = (base + kk) % 8
            sp = P5.run8(k); other = 'far' if foot == 'near' else 'near'; sp[other] = (-300, 40, 'FL'); sp.update(nocape=True, noblade=True, noarm=True, dy=-80, lean=0); sp.pop('stream', None)
            b, f, i = A_.render4(sp); rows = b[R.GR - 2:R.GR + 1]; xs = np.nonzero((rows >= 0).any(0))[0]; sole = np.nonzero(b[R.GR] >= 0)[0]
            res['apoios'][f'{foot}_f{k}'] = {'tipo': sp[foot][2], 'calcanhar_mundo': int(xs.min() + 6 * kk), 'ponta_mundo': int(sole.max() + 6 * kk)}
    d = res['apoios']; slip = {}
    for foot, ks in (('near', (0, 1, 2)), ('far', (4, 5, 6))):
        a, b_, c = [d[f'{foot}_f{k}'] for k in ks]
        slip[foot] = {'calcanhar_q1_vs_q0': abs(a['calcanhar_mundo'] - b_['calcanhar_mundo']), 'ponta_q2_vs_q1': abs(b_['ponta_mundo'] - c['ponta_mundo'])}
    res['patinacao_px'] = slip
    res['regra_apoio'] = 'cada pe fica no chao em 3 quadros (UP -> FL -> DN): o calcanhar nao desliza do 1o para o 2o; a ponta nao desliza do 2o para o 3o (calcanhar levanta girando na ponta)'
    os.makedirs(PK + '/verificacao', exist_ok=True); json.dump(res, open(PK + '/verificacao/pes_corrida.json', 'w'), indent=1); return res
if __name__ == '__main__':
    man, FR = build(); v = verif(); print('anims', len(man['animacoes']), 'cores', man['cores_usadas']['quantidade'], v['patinacao_px'])
    for a in man['animacoes']:
        hb = [(q['hitbox']['cobertura_pixels_pct'], q['hitbox']['pixels_atras_do_corpo_excluidos'], q['hitbox']['retangulo_uniao']) for q in a['quadros'] if q.get('hitbox')]
        if hb: print(a['id'], hb)
