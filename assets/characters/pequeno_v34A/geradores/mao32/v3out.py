import sys, os, json, math, pickle; sys.path.insert(0, '/tmp/claude-0/mao31'); sys.path.insert(0, '/tmp/claude-0/proj/prova/c1_carrasco/geradores')
import numpy as np
import v3anim as A, v3poses as P, v3rig as R
from c51_lib import PAL
from c51_gen import save, TEX
AXL = R.BX + 15; S = R.GR
def build(prs='AB'):
    out = {}
    for pr in prs:
        out[pr] = {}
        for an, (fn, n, ms, sw) in P.ANIMS.items():
            fr = [A.render(fn(k), pr) for k in range(n)]
            sh = np.zeros((R.H, R.W), bool)
            for dy, w in ((2, sw), (3, sw - 3)): sh[S + dy, AXL - w:AXL + w + 1] = True
            allm = sh.copy()
            for b, f, _ in fr: allm |= (b >= 0) | (f >= 0)
            ys, xs = np.nonzero(allm); y0, y1, x0, x1 = max(ys.min() - 1, 0), ys.max(), max(xs.min() - 1, 0), xs.max() + 1
            cr = lambda a: a[y0:y1 + 1, x0:x1 + 1]
            d = dict(body=[cr(b) for b, f, i in fr], fx=[cr(f) for b, f, i in fr], shadow=cr(sh), ax=AXL - x0, ay=S + 2 - y0, ms=ms, n=n, crop=(x0, y0, x1, y1),
                     blade=[[(x - x0, y - y0) for x, y in i['blade_poly']] for b, f, i in fr], cres=[[(x - x0, y - y0) for x, y in i['cres_poly']] if 'cres_poly' in i else None for b, f, i in fr])
            out[pr][an] = d
            for k in range(n):
                m = d['body'][k].copy(); f = d['fx'][k]; z = (m < 0) & (f >= 0); m[z] = f[z]       # cena: rastro atras do corpo
                a = m >= 0; h, w = m.shape; rgb = np.zeros((h, w, 3), np.float32); rgb[a] = PAL[m[a]] / 255.0
                nm = f'c52_v31{pr}_{an}_f{k}'; save(rgb, a.astype(np.float32), (d['ax'], d['ay']), TEX, nm, dict(anim=f'v31{pr}_{an}', frame=k, n=n, ms=ms[k]))
                s3 = np.zeros((h, w, 3), np.float32); s3[d['shadow']] = PAL[3] / 255.0
                save(s3, d['shadow'].astype(np.float32), (d['ax'], d['ay']), TEX, nm + '_fx', dict(anim=f'v31{pr}_{an}', frame=k, camada='sombra'))
    pickle.dump(out, open('/tmp/claude-0/mao31/frames.pkl', 'wb')); return out
if __name__ == '__main__':
    o = build()
    for pr in o:
        cols = set()
        for d in o[pr].values():
            for b, f in zip(d['body'], d['fx']): cols |= set(np.unique(b[b >= 0]).tolist()) | set(np.unique(f[f >= 0]).tolist())
        print(pr, 'cores', len(cols), {an: (d['body'][0].shape, d['ax'], d['ay']) for an, d in o[pr].items()})
