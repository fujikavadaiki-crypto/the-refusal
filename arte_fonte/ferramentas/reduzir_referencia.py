"""THE REFUSAL - reduzir_referencia.py

Transforma uma imagem de conceito (ChatGPT/folha de personagens) em QUADRO-MESTRE x1
na escala do jogo (Carrasco pequeno = 48 px de altura), na paleta do projeto.

Dependencias: Python 3.10+, numpy, scipy, Pillow (sem scikit-image).

USOS
  1) Separar uma folha com varios personagens (fundo transparente OU fundo liso):
       python reduzir_referencia.py folha  entrada.png  pasta_saida  [--nomes a,b,c]
     -> salva um PNG por personagem (sem o rotulo de texto embaixo), da esquerda para a direita.

  2) Reduzir um recorte para a altura do jogo:
       python reduzir_referencia.py reduzir recorte.png saida_x1.png --altura 52 [--paleta paleta.json] [--sem-contorno]
     -> PNG x1 (RGBA, so cores da paleta, contorno escuro 1 px) + previa _x4.png ao lado.

  3) Tudo de uma vez a partir de uma tabela JSON {"nome": altura_px, ...}:
       python reduzir_referencia.py lote pasta_recortes tabela_alturas.json pasta_saida [--paleta paleta.json]

REGRAS
  - O resultado e RASCUNHO DE ESCALA: serve de quadro-mestre para limpar a mao e depois
    separar em partes para animar. Nao e arte final.
  - Altura = do ponto mais alto ao mais baixo do desenho (sem efeitos soltos).
  - Personagens devem olhar para a DIREITA (o jogo espelha).
"""
import sys, json, os, argparse
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

AQUI = os.path.dirname(os.path.abspath(__file__))
PALETA_PADRAO = os.path.join(AQUI, '..', 'paleta', 'paleta_bosque_v1.json')
CONTORNO = (7, 4, 5)   # indice 3 da C5.1 (contorno)


# ----------------------------------------------------------------- cor (sRGB -> Lab, sem scikit-image)
def _lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def rgb2lab(rgb):
    rgb = np.asarray(rgb, float)
    l = _lin(rgb)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = l @ M.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    L = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], -1)


def carregar_paleta(caminho):
    d = json.load(open(caminho, encoding='utf-8'))
    cores = d['cores'] if isinstance(d, dict) else d
    return np.array([c['rgb'] if isinstance(c, dict) else c for c in cores], int)


# ----------------------------------------------------------------- fundo
def alfa_ou_fundo(im, tol=18):
    """Devolve RGBA. Se a imagem nao tem transparencia, remove o fundo liso por preenchimento a partir dos cantos."""
    a = np.array(im.convert('RGBA'))
    if (a[..., 3] < 250).mean() > 0.05:
        return a
    rgb = a[..., :3].astype(int)
    canto = np.median(np.array([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]]), 0)
    parecido = np.abs(rgb - canto).sum(-1) <= tol
    lab, _ = ndi.label(parecido)
    ids = {lab[0, 0], lab[0, -1], lab[-1, 0], lab[-1, -1]} - {0}
    fundo = np.isin(lab, list(ids))
    a[fundo, 3] = 0
    return a


# ----------------------------------------------------------------- folha -> recortes
def separar_folha(caminho, pasta, nomes=None, min_altura=120):
    a = alfa_ou_fundo(Image.open(caminho))
    al = a[..., 3] > 40
    lab, n = ndi.label(ndi.binary_dilation(al, iterations=6))
    objs = ndi.find_objects(lab)
    caixas = sorted([(s[1].start, s[0].start, s[1].stop, s[0].stop) for s in objs
                     if s[0].stop - s[0].start > min_altura])
    os.makedirs(pasta, exist_ok=True)
    saidas = []
    for k, (x0, y0, x1, y1) in enumerate(caixas):
        sub = al[y0:y1, x0:x1]
        linhas = sub.sum(1)
        # rotulo de texto = ultimo bloco de linhas, separado do desenho por linhas vazias
        r = len(linhas) - 1
        while r > 0 and linhas[r] == 0: r -= 1
        while r > 0 and linhas[r] > 0: r -= 1
        fim_vazio = r
        while r > 0 and linhas[r] == 0: r -= 1
        yb = r + 1
        if len(linhas) - yb > 130 or fim_vazio - r < 2:
            yb = len(linhas)
        spr = a[y0:y0 + yb, x0:x1].copy()
        spr = limpar_vizinhos(spr)
        nome = (nomes[k] if nomes and k < len(nomes) else f'personagem_{k + 1}')
        out = os.path.join(pasta, nome + '.png')
        Image.fromarray(spr).save(out)
        saidas.append(out)
        print('recorte', nome, spr.shape[1], 'x', spr.shape[0])
    return saidas


def limpar_vizinhos(a):
    """Remove pedacos pequenos de personagens vizinhos que encostam nas bordas do recorte; recorta justo."""
    m = a[..., 3] > 40
    lab, n = ndi.label(ndi.binary_dilation(m, iterations=2))
    if n == 0:
        return a
    tam = ndi.sum(m, lab, range(1, n + 1))
    maior = tam.max()
    for k in range(1, n + 1):
        comp = lab == k
        if tam[k - 1] < 0.06 * maior and (comp[:, :8].any() or comp[:, -8:].any()):
            a[comp] = 0
    m = a[..., 3] > 40
    ys, xs = np.where(m)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


# ----------------------------------------------------------------- recorte -> x1
def reduzir(a, altura, paleta, contorno=True):
    a = np.asarray(a)
    m0 = a[..., 3] > 40
    ys, xs = np.where(m0)
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    H = int(altura)
    W = max(1, round(a.shape[1] * H / a.shape[0]))
    rgb = a[..., :3].astype(np.float32)
    al = a[..., 3].astype(np.float32) / 255.0
    # media pre-multiplicada (nao deixa o fundo transparente escurecer as bordas)
    pm = np.stack([np.array(Image.fromarray(rgb[..., k] * al, 'F').resize((W, H), Image.BOX)) for k in range(3)], 2)
    aa = np.array(Image.fromarray(al, 'F').resize((W, H), Image.BOX))
    cor = np.clip(pm / np.maximum(aa[..., None], 1e-6), 0, 255)
    m = aa > 0.5
    plab = rgb2lab(paleta)
    lab = rgb2lab(cor)
    idx = np.argmin(((lab[..., None, :] - plab[None, None]) ** 2).sum(-1), -1)
    out = np.zeros((H, W, 4), np.uint8)
    out[m, :3] = paleta[idx[m]]
    out[m, 3] = 255
    if contorno:
        borda = m & ~ndi.binary_erosion(m)
        out[borda, :3] = CONTORNO
    # pixels soltos (1 px isolado sem vizinho 8-conexo) saem
    lab2, n2 = ndi.label(m, structure=np.ones((3, 3)))
    if n2:
        tam = ndi.sum(m, lab2, range(1, n2 + 1))
        for k in range(1, n2 + 1):
            if tam[k - 1] <= 2:
                out[lab2 == k] = 0
    return out


def salvar_x1(out, caminho, escala_previa=4):
    Image.fromarray(out).save(caminho)
    h, w = out.shape[:2]
    prev = Image.new('RGBA', (w + 8, h + 8), (34, 31, 33, 255))
    prev.alpha_composite(Image.fromarray(out), (4, 4))
    prev.resize(((w + 8) * escala_previa, (h + 8) * escala_previa), Image.NEAREST).save(
        caminho.replace('.png', f'_previa_x{escala_previa}.png'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('modo', choices=['folha', 'reduzir', 'lote'])
    p.add_argument('args', nargs='+')
    p.add_argument('--nomes', default=None)
    p.add_argument('--altura', type=int, default=48)
    p.add_argument('--paleta', default=PALETA_PADRAO)
    p.add_argument('--sem-contorno', action='store_true')
    o = p.parse_args()
    if o.modo == 'folha':
        separar_folha(o.args[0], o.args[1], o.nomes.split(',') if o.nomes else None)
        return
    pal = carregar_paleta(o.paleta)
    if o.modo == 'reduzir':
        a = alfa_ou_fundo(Image.open(o.args[0]))
        out = reduzir(a, o.altura, pal, not o.sem_contorno)
        salvar_x1(out, o.args[1])
        print(o.args[1], out.shape[1], 'x', out.shape[0])
    else:
        pasta, tabela, saida = o.args[:3]
        os.makedirs(saida, exist_ok=True)
        alturas = json.load(open(tabela, encoding='utf-8'))
        for nome, h in alturas.items():
            if nome.startswith('_'):
                continue
            a = alfa_ou_fundo(Image.open(os.path.join(pasta, nome + '.png')))
            out = reduzir(a, h, pal, not o.sem_contorno)
            salvar_x1(out, os.path.join(saida, nome + '_x1.png'))
            print(nome, out.shape[1], 'x', out.shape[0])


if __name__ == '__main__':
    main()
