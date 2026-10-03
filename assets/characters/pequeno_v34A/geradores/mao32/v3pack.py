#!/usr/bin/env python3
import os, sys, json, shutil, hashlib, zipfile, pickle, math
sys.path.insert(0, '/tmp/claude-0/mao31'); sys.path.insert(0, '/tmp/claude-0/proj/prova/c1_carrasco/geradores')
import numpy as np
from PIL import Image, ImageDraw
from c51_lib import PAL
import v3anim as A, v3poses as P, v3rig as R
C1 = '/tmp/claude-0/proj/prova/c1_carrasco'; PALD = C1 + '/paleta'; OUT = '/tmp/claude-0/p31pack'; C52B = '/tmp/claude-0/c52bpkg/pacote_sprites_c52b'
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
PALSET = {tuple(c) for c in PAL.astype(int)}
FR = pickle.load(open('/tmp/claude-0/mao31/frames.pkl', 'rb'))
def rgba(m):
    h, w = m.shape; o = np.zeros((h, w, 4), np.uint8); a = m >= 0; o[a, :3] = PAL[m[a]]; o[a, 3] = 255; return o
def wr(path, arr): os.makedirs(os.path.dirname(path), exist_ok=True); Image.fromarray(arr, 'RGBA').save(path); return sha(path)
NOTAS = {'idle': 'respiracao (peito sobe, cabeca atrasa 1 px) + capa atrasada 1 quadro; 2000 ms em laco',
         'run': 'corrida 6 quadros: 144 px/s / 8 px por quadro = 18 quadros/s = 55,56 ms; ciclo 333 ms avanca 48 px (passo 24 px). Apoio: pe proximo q0-1, distante q3-4; voo q2 e q5. O GIF usa 50/60 ms so por limite de 10 ms do formato.',
         'dash': 'dash no chao, 3 quadros (90/170/90 ms = 350): pose esticada + capa arrastando; 3,5 m = 112 px em 350 ms (320 px/s); fiapos de velocidade na camada de efeito',
         'dash_ar': 'dash no ar, 3 quadros: mesmas fases, pernas recolhidas, sem gravidade; a sombra fica no chao',
         'jump_up': 'pulo - SUBIDA (2 q); altura vem da fisica (nao ha deslocamento vertical no sprite)', 'fall_start': 'queda - INICIO (2 q), depois entra em fall_loop',
         'fall_loop': 'queda - LACO (3 q, repete enquanto cai): capa inflada para cima como paraquedas (pulsa entre os quadros)', 'land': 'pouso (2 q), 120 ms', 'hurt': 'damage_remaining 180 ms = 3 x 60 ms; respingos na camada de efeito',
         'heavy': 'receita do machado: 4 q de preparacao (320 ms, lamina sobe acima do ombro) + 2 q de ARCO GIGANTE (140 ms, 2x a altura) + 3 q parado com a lamina no chao (430 ms) = 890 ms; hitbox dos quadros ATIVO = arco (+ lamina)'}
def hitbox(an, k, d, pr):
    sp = P.heavy(k); x0, y0 = d['crop'][0], d['crop'][1]; ax, ay = int(d['ax']), int(d['ay']) - 1
    b_, f_, info = A.render(sp, pr); poly_r = [(x - x0, y - y0) for x, y in info['cres_poly']]; poly_b = d['blade'][k]
    # cobertura: pixels do arco (todas as faixas) e de lamina (14/16/18) cobertos pelos poligonos
    h, w = d['body'][k].shape; mk = Image.new('L', (w, h), 0); dr = ImageDraw.Draw(mk); dr.polygon([tuple(p) for p in poly_r], fill=255); dr.polygon([tuple(p) for p in poly_b], fill=255); cov = np.array(mk) > 0
    fx = np.isin(d['fx'][k], (5, 8, 10, 16, 18, 22)); body = d['body'][k]; bl = np.isin(body, (14, 16, 18))
    tot = fx.sum() + bl.sum(); ins = (fx & cov).sum() + (bl & cov).sum()
    xs = [p[0] for p in poly_r + poly_b]; ys = [p[1] for p in poly_r + poly_b]; x0_, y0_, x1_, y1_ = math.floor(min(xs)), math.floor(min(ys)), math.ceil(max(xs)), math.ceil(max(ys))
    rel = lambda poly: [[round(x - ax, 1), round(y - ay, 1)] for x, y in poly]
    return {'fase': 'ATIVO', 'tipo': 'arco + lamina', 'origem': 'poligono do ARCO (meia-lua cheia, 3 faixas) neste quadro + poligono da lamina desenhada; px relativos a ancora (x direita, y baixo)',
            'arco': {'poligono': rel(poly_r)}, 'lamina': {'poligono': rel(poly_b)}, 'retangulo_uniao': [x0_ - ax, y0_ - ay, x1_ - x0_, y1_ - y0_],
            'cobertura_pixels_pct': round(100 * ins / max(tot, 1), 1), 'espelha_com_a_direcao': 'inverter x quando o Carrasco olha para a esquerda'}
def build(pr, capsula):
    PK = f'{OUT}/pacote_pequeno_v31{pr}'
    if os.path.exists(PK): shutil.rmtree(PK)
    os.makedirs(PK); shutil.copy(PALD + '/carrasco_c51_travada.gpl', PK + '/paleta/carrasco_c51_travada.gpl') if os.makedirs(PK + '/paleta', exist_ok=True) is None else None
    shutil.copy(PALD + '/carrasco_c51_travada.json', PK + '/paleta/carrasco_c51_travada.json'); pal_sha = sha(PK + '/paleta/carrasco_c51_travada.gpl')
    old = json.load(open(C52B + '/manifesto_sprites.json')); assert old['paleta']['sha256'] == pal_sha
    anims = []; usadas = set()
    for an, (fn, n, ms, sw) in P.ANIMS.items():
        d = FR[pr][an]; ax = int(d['ax']); ay = int(d['ay']) - 1; quadros = []; efs = []
        sh = d['shadow']; h, w = sh.shape; s2 = np.zeros((h, w, 4), np.uint8); sh2 = np.zeros_like(sh); sh2[:-1] = sh[1:]; s2[sh2, :3] = PAL[3]; s2[sh2, 3] = 255
        assert set(np.nonzero(sh2.any(1))[0]) == {ay, ay + 1}
        sarq = f'sombras/{an}_sombra.png'; shs = wr(f'{PK}/{sarq}', s2)
        for k in range(n):
            b = d['body'][k]; assert not (b[ay:] >= 0).any(), (an, k)
            arq = f'quadros/{an}/{an}_f{k}.png'; hh = wr(f'{PK}/{arq}', rgba(b)); ys, xs = np.nonzero(b >= 0); usadas |= set(np.unique(b[b >= 0]).tolist())
            q = {'arquivo': arq, 'largura': int(w), 'altura': int(h), 'ancora': [ax, ay], 'pivo': [ax, ay], 'ms': round(float(ms[k]), 2), 'sha256': hh, 'nome_origem': f'c52_v31{pr}_{an}_f{k}',
                 'corpo_bbox': [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                 'sombra': {'arquivo': sarq, 'ancora': [ax, ay], 'largura': int(w), 'altura': int(h), 'pixels': int(sh2.sum()), 'sha256': shs}, 'hitbox': None}
            f = d['fx'][k]
            if (f >= 0).any():
                earq = f'efeitos/{an}_fx_f{k}.png'; eh = wr(f'{PK}/{earq}', rgba(f)); usadas |= set(np.unique(f[f >= 0]).tolist())
                ativo = (an == 'heavy' and k in P.HEAVY_ACTIVE and 'arc' in P.heavy(k))
                efs.append({'quadro': k, 'arquivo': earq, 'ancora': [ax, ay], 'largura': int(w), 'altura': int(h), 'camada': 'atras_do_corpo (ou sobre o cenario, atras da lamina)',
                            'fase': 'ATIVO' if ativo else 'todas', 'pixels': int((f >= 0).sum()), 'sha256': eh})
            if an == 'heavy' and k in P.HEAVY_ACTIVE: q['hitbox'] = hitbox(an, k, d, pr)
            quadros.append(q)
        a_ = {'id': an, 'tipo': 'animacao', 'loop': an in ('idle', 'run', 'fall_loop'), 'quadros_n': n, 'duracao_total_ms': round(float(sum(ms)), 2), 'nota_tempo': NOTAS[an], 'quadros': quadros,
              'sombra': {'por_quadro': False, 'arquivo': sarq, 'aplica_a': 'todos os quadros; fica no chao (nao acompanha o voo)'}, 'efeitos': efs,
              'capa': 'movimento secundario: a capa atrasa/antecipa o corpo (trail/lift/flap por quadro); faz parte do corpo (nao e camada separada)',
              'camadas': 'ORDEM DE TRAS PARA FRENTE: capa -> bota distante -> bota proxima -> tronco/pano (a barra cobre as pernas) -> cabeca -> LAMINA (por cima das botas) -> braco/ombreira; efeitos atras do corpo.'}
        if an == 'run': a_.update(px_por_quadro=8, velocidade_px_s=144, ms_por_quadro=round(P.RUN_MS, 2))
        if an in ('dash', 'dash_ar'): a_.update(deslocamento_total_px=112, velocidade_px_s=320, nota_desloc='mover o personagem 0,32 px/ms durante os 350 ms (nao por quadro)')
        if an == 'heavy': a_['fases'] = {'PREPARACAO': {'quadros': [0, 1, 2, 3], 'ms': 320}, 'ATIVO': {'quadros': [4, 5], 'ms': 140}, 'RECUPERACAO (parado, lamina no chao)': {'quadros': [6, 7, 8], 'ms': 430}}
        anims.append(a_)
    assert {tuple(PAL[i].astype(int)) for i in usadas} <= PALSET
    cores = sorted(usadas); hp = {'A': 15, 'B': 20}[pr]
    man = {'pacote': f'pacote_pequeno_v31{pr}', 'versao': f'Carrasco pequeno v3.1{pr} (48 px, cabeca {round(100 * hp / 48)} %)', 'personagem': 'O Carrasco', 'data': '2026-10-02',
           'status': 'TESTE para avaliacao (nao aprovado). v3.1 = v3 + receita do machado (arco gigante de 3 faixas, preparacao 4 / arco 2 / parado 3), dash em 3 quadros, queda com capa-paraquedas. Estudo de estilo; nada copiado de outro jogo. v2 e v3 intactas.',
           'formato': 'mesmo do pacote_sprites_c52b: animacoes[] com quadros (arquivo, ms, ancora), sombra em arquivo proprio, efeitos em camada separada, paleta travada; MAIS hitbox por quadro ATIVO',
           'cores': 'SAIDA (o que se ve): todo pixel opaco e uma das cores da paleta C5.1; alfa 0/255.',
           'paleta': {'arquivo': 'paleta/carrasco_c51_travada.gpl', 'cores': 44, 'travada': True, 'sha256': pal_sha},
           'cores_usadas': {'quantidade': len(cores), 'indices': cores, 'rgb': [PAL[i].tolist() for i in cores], 'papeis': {'contorno': [3], 'pano_frio': [0, 1, 2], 'couro': [7, 8, 10, 12], 'mascara': [42, 43], 'olho': [41], 'aco': [14, 16, 18], 'sangue': [19, 22], 'arco': {'borda_cinza_clara': [16, 18], 'meio_marrom_escuro': [10, 8], 'interior_quase_preto': [5], 'filete_sangue': [22]}}},
           'proporcao': {'altura_idle_px': 48, 'cabeca_px': hp, 'cabeca_pct': round(100 * hp / 48, 1), 'mascara_px': '8 x 9' if pr == 'A' else '12 x 10'},
           'ancora_convencao': 'ancora = pixel (x,y) do quadro nos pes, na linha logo abaixo da sola (corpo termina em y-1, sombra ocupa y e y+1). Todos os quadros de UMA animacao compartilham canvas e ancora; x = centro do tronco.',
           'capsula_sugerida': capsula, 'animacoes': anims, 'prova': {'tira': 'prova/tira_x2.png', 'pes_corrida': 'verificacao/pes_corrida.json'}}
    json.dump(man, open(PK + '/manifesto_sprites.json', 'w'), ensure_ascii=False, indent=1); return PK, man
def capsula(pr):
    d = FR[pr]['idle']; ax, ay = d['ax'], d['ay']; core = []
    for k in range(7):
        sp = P.idle(k); sp.update(nocape=True, noblade=True, noarm=True); b, f, i = A.render(sp, pr); x0, y0, x1, y1 = d['crop']; core.append(b[y0:y1 + 1, x0:x1 + 1] >= 0)
    full = [b >= 0 for b in d['body']]; sole = ay - 2; res = {}
    for r in (6, 7, 8, 9, 10):
        o = {}
        for nm, Ls in (('nucleo', core), ('tudo', full)):
            tot = ins = 0
            for m in Ls:
                ys, xs = np.nonzero(m); top = sole + 1 - 46; dx = np.abs(xs + .5 - (ax + .5)); inside = np.where(ys < top + r, dx ** 2 + (ys + .5 - (top + r)) ** 2 <= r * r, dx <= r); tot += len(ys); ins += inside.sum()
            o[nm] = round(100 * ins / tot, 1)
        res[r] = o
    return res
def verif(pr, PK):
    res = {'px_por_quadro': 8, 'ms_por_quadro': round(P.RUN_MS, 2), 'velocidade_px_s': 144.0, 'metodo': 'renderiza so a bota; coluna mundo = coluna do canvas + 8*k; calcanhar = menor coluna da bota nas 3 linhas de baixo; ponta = maior coluna na linha da sola', 'apoios': {}}
    for foot, ks in (('near', (0, 1)), ('far', (3, 4))):
        for k in ks:
            sp = P.run(k); other = 'far' if foot == 'near' else 'near'; sp[other] = (-300, 40, 'FL'); sp.update(nocape=True, noblade=True, noarm=True, dy=-80, lean=0)
            b, f, i = A.render(sp, pr); rows = b[R.GR - 2:R.GR + 1]; xs = np.nonzero((rows >= 0).any(0))[0]; sole = np.nonzero(b[R.GR] >= 0)[0]
            res['apoios'][f'{foot}_f{k}'] = {'calcanhar_mundo': int(xs.min() + 8 * k), 'ponta_mundo': int(sole.max() + 8 * k)}
    d = res['apoios']; res['patinacao_calcanhar_px'] = {'proximo': abs(d['near_f0']['calcanhar_mundo'] - d['near_f1']['calcanhar_mundo']), 'distante': abs(d['far_f3']['calcanhar_mundo'] - d['far_f4']['calcanhar_mundo'])}
    os.makedirs(PK + '/verificacao', exist_ok=True); json.dump(res, open(PK + '/verificacao/pes_corrida.json', 'w'), indent=1); return res
if __name__ == '__main__':
    for pr in 'AB':
        cap = capsula(pr); print(pr, cap)
        sel = next(r for r in (6, 7, 8, 9, 10) if cap[r]['nucleo'] >= 70)
        c = {'forma': 'capsula vertical', 'raio_px': sel, 'altura_px': 46, 'raio_m': round(sel / 32, 2), 'altura_m': round(46 / 32, 2), 'base': 'na linha dos pes (ancora), eixo no x da ancora (centro do tronco)',
             'escala': '1 m = 32 px (mapa atual); referencia aprovada 0,31 x 2,20 m para o sprite de 72 px, reduzida por 48/72',
             'cobertura_idle_por_raio_px': {str(r): v for r, v in cap.items()}, 'regra': 'menor raio com >= 70 % do nucleo (cabeca, tronco, pernas) dentro', 'nota': 'proposta; calibrar em jogo. Capa, braco, lamina e rastro ficam fora (solto).'}
        PK, man = build(pr, c); v = verif(pr, PK); print(pr, len(man['animacoes']), man['cores_usadas']['quantidade'], v['patinacao_calcanhar_px'], [(q['hitbox']['cobertura_pixels_pct'], q['hitbox']['retangulo_uniao']) for q in man['animacoes'][-1]['quadros'] if q['hitbox']])
