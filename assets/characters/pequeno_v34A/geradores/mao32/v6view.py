import sys; sys.path.insert(0,'/tmp/claude-0/p41'); sys.path.insert(0,'/tmp/claude-0/p41/v6')
import numpy as np, v6poses as P, v4anim as A, v4rig as R
from PIL import Image, ImageDraw
sys.path.insert(0,'/tmp/claude-0/proj/prova/c1_carrasco/geradores')
from c51_lib import PAL
def comp(sp):
    b,f,i = P.render5(sp); m=b.copy(); z=(m<0)&(f>=0); m[z]=f[z]; return m
def sheet(seqs,name,S=3,per_row=8,labels=None,box=(30,90,170,156),bg=(112,112,112)):
    x0,y0,x1,y1=box; tiles=[]
    for k,sp in enumerate(seqs):
        m=comp(sp)[y0:y1,x0:x1]; o=np.zeros(m.shape+(3,),np.uint8); o[:]=bg; gy=R.GR+1-y0; o[gy:]=(96,96,96)
        a=m>=0; o[a]=PAL[m[a]]; im=Image.fromarray(np.kron(o,np.ones((S,S,1),np.uint8))); d=ImageDraw.Draw(im); d.text((3,2),(labels[k] if labels else str(k)),fill=(255,255,200)); tiles.append(np.array(im))
    h,w=tiles[0].shape[:2]; rows=[]
    for r in range(0,len(tiles),per_row):
        row=tiles[r:r+per_row]
        while len(row)<per_row: row.append(np.full((h,w,3),112,np.uint8))
        rows.append(np.concatenate(row,1))
    Image.fromarray(np.concatenate(rows,0)).save(name)
if __name__=='__main__':
    run=P.lag5([P.run8(k) for k in range(8)],loop=True)
    pass #sheet(run,'run8.png',S=3,per_row=4,labels=['r%d'%i for i in range(8)])
    mis=P.lag5([P.run_start()],prev=dict(stream=dict(L=14,rise=1,ht=9,amp=.5,ph=0)))+P.lag5([P.run_stop()],prev=P.run8(3))+P.lag5(P.dash5(),prev=dict(stream=dict(L=14,rise=1,ht=9,amp=.5,ph=0)))
    sheet(mis,'misc6.png',S=3,per_row=3,labels=['start','stop','d0','d1','d2','d3'])
    sheet(P.lag5(P.dash5(),prev=dict(stream=dict(L=14,rise=1,ht=9,amp=.5,ph=0))),'dash6.png',S=3,per_row=2,labels=['arr 50','smear 60','ext 190','freio 50'],box=(30,90,200,156))
    sheet(P.lag5(P.dash_air5(),prev=dict(stream=dict(L=14,rise=1,ht=9,amp=.5,ph=0))),'dash6_ar.png',S=3,per_row=2,labels=['arr 50','smear 60','ext 190','freio 50'],box=(30,70,200,156))
