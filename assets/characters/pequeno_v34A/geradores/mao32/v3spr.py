# Carrasco PEQUENO v3 (48 px) - proporcao A (cabeca ~31 %) e B (cabeca ~42 %). ASCII 1 char = 1 px. Paleta C5.1 (17 cores: v2 + 26 para o rastro).
import numpy as np
LEG = {'.': None, 'o': 3, 'a': 0, 'c': 1, 'C': 2, 'd': 7, 'm': 8, 'l': 10, 'L': 12, 'g': 42, 'G': 43, 'k': 3, 'e': 41, 's': 14, 'S': 16, 'W': 18, 'b': 19, 'r': 22, 'R': 26}
def spr(rows, w=None):
    w = w or max(len(r) for r in rows); out = -np.ones((len(rows), w), int)
    for y, r in enumerate(rows):
        assert len(r) == w, (y, len(r), w, r)
        for x, ch in enumerate(r):
            v = LEG[ch]
            if v is not None: out[y, x] = v
    return out
HEAD_A = spr([       # 16 x 15 = 31 % de 48
"....oooooooo....",
"..ooaccccccCCo..",
".oaaccccccccCCo.",
"oaacccccccccCCCo",
"oaacccccccccCCCo",
"oaaccaGGGGGGGGCo",
"oaacaagkkgeeggCo",
"oaacaaggggggggCo",
"oaacaagkgkgkggCo",
"oaacaagkgkgkggCo",
"oaacaaggggggggCo",
".oaccaaggggggaCo",
"..oaaccaggggaCo.",
"...ooaaccaaaCoo.",
".....oooooooo...",
])
HEAD_B = spr([       # 21 x 20 = 42 % de 48
".....oooooooooooo....",
"...ooaccccccccccCCoo.",
"..oaaccccccccccccCCCo",
".oaaccccccccccccccCCo",
"oaacccccccccccccccCCo",
"oaaccaGGGGGGGGGGGGCCo",
"oaacaagkkkggeeegggCCo",
"oaacaaggggggggggggCCo",
"oaacaagkgkgkgkgkggCCo",
"oaacaagkgkgkgkgkggCCo",
"oaacaagkgkgkgkgkggCCo",
"oaacaaggggggggggggCCo",
"oaaccaaggggggggggaCCo",
".oaccaaaggggggggaaCo.",
"..oaaccaaaggggaaCCo..",
"...ooaaccaaaaaaaCCoo.",
"....ooaaccccccccCCoo.",
".....oaacccccccCCCo..",
"......ooaccccccCCoo..",
"........oooooooooo...",
])
def make_torso(W, ext, cross, belt, pouch, folds, blood, strap, buckle_x, hemrows=1):
    R = len(ext); g = [['.'] * W for _ in range(R)]
    for r, (L, Rr) in enumerate(ext):
        for x in range(L, Rr + 1):
            if x == L or x == Rr: ch = 'o'
            elif x <= L + 2: ch = 'a'
            elif x >= Rr - 3: ch = 'C'
            else: ch = 'c'
            g[r][x] = ch
    for x in range(W):
        for r in (1, 2):
            if g[r][x] == 'c': g[r][x] = 'C'
    def put(r, x, ch):
        if 0 <= r < R and 0 <= x < W and g[r][x] != '.': g[r][x] = ch
    for r in range(strap[0], strap[1]):
        put(r, strap[2], 'o'); put(r, strap[2] + 1, 'm'); put(r, strap[2] + 2, 'l'); put(r, strap[2] + 3, 'o')
    vx, vt, vb, ht, hx0, hx1 = cross
    for r in range(vt, vb + 1): put(r, vx, 'b'); put(r, vx + 1, 'r')
    for x in range(hx0, hx1 + 1): put(ht, x, 'r'); put(ht + 1, x, 'b')
    put(ht, vx, 'b'); put(ht, vx + 1, 'r')
    bl, bm, bd = belt
    x0, x1 = min(e[0] for e in ext[bl:bd + 1]) + 1, max(e[1] for e in ext[bl:bd + 1]) - 1
    for x in range(x0, x1 + 1): put(bl, x, 'l'); put(bm, x, 'm'); put(bd, x, 'd')
    for x, ch in ((buckle_x, 'S'), (buckle_x + 1, 'W'), (buckle_x + 2, 'S')): put(bl, x, ch)
    for x, ch in ((buckle_x, 'S'), (buckle_x + 1, 'd'), (buckle_x + 2, 'S')): put(bm, x, ch)
    pr0, pr1, px0, px1 = pouch
    for r in range(pr0, pr1 + 1):
        for x in range(px0, px1 + 1): put(r, x, 'o' if (r in (pr0, pr1) or x in (px0, px1)) else ('l' if r == pr0 + 1 else 'm'))
    put((pr0 + pr1) // 2, (px0 + px1) // 2, 'S')
    for (r0, r1, x) in folds:
        for r in range(r0, r1 + 1): put(r, x, 'a'); put(r, x + 1, 'C')
    for (r, x, ch) in blood: put(r, x, ch)
    for x in range(W):
        if g[R - 1][x] != '.':
            g[R - 1][x] = 'o' if x % 5 in (0, 1, 2) else '.'
            if x % 5 in (3, 4) and g[R - 2][x] != '.': g[R - 2][x] = 'o'
    return spr([''.join(r) for r in g], W)
_extA = [(5, 15), (3, 17), (2, 18), (1, 19)] + [(0, 20)] * 5 + [(1, 20), (1, 20), (2, 19), (2, 19), (2, 19), (2, 19)] + [(1, 20)] * 3 + [(0, 20)] * 3
TORSO_A = make_torso(21, _extA, cross=(12, 4, 11, 6, 9, 16), belt=(12, 13, 14), pouch=(14, 18, 3, 7), folds=[(15, 19, 9), (15, 19, 15)],
                     blood=[(17, 11, 'b'), (17, 12, 'r'), (18, 12, 'r'), (19, 12, 'b'), (15, 17, 'r'), (16, 17, 'b'), (8, 15, 'r'), (9, 15, 'b'), (19, 18, 'r'), (18, 18, 'b')], strap=(3, 12, 4), buckle_x=9)
_extB = [(4, 12), (2, 14), (1, 15)] + [(0, 16)] * 4 + [(1, 16)] * 2 + [(0, 16)] * 7 + [(0, 16)] * 2
TORSO_B = make_torso(17, _extB, cross=(9, 4, 9, 5, 6, 12), belt=(10, 11, 12), pouch=(12, 15, 2, 5), folds=[(13, 16, 7), (13, 16, 11)],
                     blood=[(14, 8, 'b'), (14, 9, 'r'), (15, 9, 'r'), (13, 14, 'r'), (14, 14, 'b'), (7, 12, 'r'), (8, 12, 'b')], strap=(3, 10, 3), buckle_x=7)
FOOT_FLAT = spr([
"..olLLLLlo.....",
"..odmmmllo.....",
"..odmmmllo.....",
"..odmmmlllo....",
"..odmmmllllloo.",
"..odmmmmllllllo",
"..oddddddddddoo",
"...oooooooooooo",
])
FOOT_UP = spr([
"..olLLLLlo.....",
"..odmmmllo.....",
"..odmmmlllo....",
"..odmmmllllloo.",
"..oddmmmllllllo",
"..oddddddoooooo",
"..ooooooo......",
"...............",
])
FOOT_DOWN = spr([
"..olLLLLlo.....",
"..odmmmllo.....",
"...odmmmllo....",
"....oddmmllo...",
".....odddmlllo.",
"......oodmllllo",
"........oddddoo",
".........ooooo.",
])
FOOT_TUCK = spr([
"..olLLLLlo.....",
"..odmmmllo.....",
"..odmmmllo.....",
"...odmmmllo....",
"...oddmmmllo...",
"....oddddmllo..",
".....ooodddddo.",
".........ooooo.",
])
