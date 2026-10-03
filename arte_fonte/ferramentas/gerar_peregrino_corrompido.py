"""Rig deterministico do mestre v2, sem escalar sprites ou alterar IA/tuning.

Uso: python arte_fonte/ferramentas/gerar_peregrino_corrompido.py [--verify]
Fontes fornecidas ficam intactas; limpeza, partes e poses ficam em arte_fonte.
"""
from pathlib import Path
import argparse, collections, hashlib, json, math, re, shutil
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'arte_fonte/inimigos_mestre_x1/peregrino_corrompido_x1.png'
ART = ROOT / 'arte_fonte/peregrino_corrompido_v1'
PACK = ROOT / 'assets/enemies/peregrino_corrompido_v1'
EVIDENCE = ROOT / 'codex/evidencias_peregrino_corrompido'
PAL = np.array([c['rgb'] for c in json.loads((ROOT/'arte_fonte/paleta/paleta_bosque_v1.json').read_text(encoding='utf-8'))['cores']],dtype=np.uint8)
W, H, AX, AY = 160, 104, 54, 90
ANCHOR = [AX, AY]

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save_json(p, obj):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def neighbors(a, fill=-2):
    padded=np.pad(a,1,constant_values=fill)
    return np.stack([padded[1+dy:1+dy+a.shape[0],1+dx:1+dx+a.shape[1]] for dy in (-1,0,1) for dx in (-1,0,1) if dx or dy])
def components(mask):
    remaining=set(map(tuple,np.argwhere(mask))); result=[]
    while remaining:
        start=remaining.pop(); todo=[start]; part=[start]
        while todo:
            y,x=todo.pop()
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    q=(y+dy,x+dx)
                    if q in remaining: remaining.remove(q);todo.append(q);part.append(q)
        result.append(part)
    return sorted(result,key=len,reverse=True)
def indices(image):
    a=np.asarray(image.convert('RGBA')); out=np.full(a.shape[:2],-1,dtype=np.int16)
    for i,c in enumerate(PAL):out[(a[...,3]>0)&np.all(a[...,:3]==c,axis=2)]=i
    assert np.all((a[...,3]==0)|(out>=0)), 'Cor fora da paleta'
    return out
def rgba(a):
    out=np.zeros(a.shape+(4,),np.uint8);mask=a>=0;out[mask,:3]=PAL[a[mask]];out[mask,3]=255
    return Image.fromarray(out)
def clean(image, outline=True, main=True):
    a=indices(image)
    if main:
        for part in components(a>=0)[1:]:
            for y,x in part:a[y,x]=-1
    if outline:
        mask=a>=0;edge=mask&~np.all(neighbors(mask.astype(int),0)==1,axis=0);a[edge]=3
    for _ in range(16):
        ns=neighbors(a); spots=np.argwhere((a>=0)&~np.any(ns==a,axis=0))
        if not len(spots):break
        b=a.copy()
        for y,x in spots:
            values=ns[:,y,x];values=values[values>=0]
            if len(values):b[y,x]=collections.Counter(values.tolist()).most_common(1)[0][0]
        if np.array_equal(a,b):break
        a=b
    return rgba(a)
def blank():return Image.new('RGBA',(W,H))
def poly(image, pts, color):ImageDraw.Draw(image).polygon([(round(AX+x),round(AY+y)) for x,y in pts],fill=tuple(PAL[color])+ (255,))
def line(image, pts, color, width=1):ImageDraw.Draw(image).line([(round(AX+x),round(AY+y)) for x,y in pts],fill=tuple(PAL[color])+(255,),width=width)
def ellipse(image, box, color):ImageDraw.Draw(image).ellipse(tuple(round(v+(AX if i%2==0 else AY)) for i,v in enumerate(box)),fill=tuple(PAL[color])+(255,))

def split_master():
    original=Image.open(SOURCE).convert('RGBA');a=indices(original)
    face=Image.new('1',original.size);ImageDraw.Draw(face).polygon([(34,12),(39,13),(39,20),(34,25),(29,23),(30,17)],fill=1)
    m=np.asarray(face)&(a>=0);lum=np.asarray(original)[...,:3].mean(-1)
    a[m&(lum>45)]=53;a[m&(lum>65)]=57;a[m&(lum>90)]=17
    master=clean(rgba(a));ART.mkdir(parents=True,exist_ok=True);master.save(ART/'mestre_limpo_x1.png')
    # Polygons are hand-selected on the 56x52 master; uncovered cloth belongs
    # to the torso. Source colors are retained, not repainted from old artwork.
    regions={
      'manto_musgo':([(0,15),(17,13),(23,24),(20,37),(12,50),(0,49)],(18,29)),
      'perna_tras':([(13,39),(26,39),(26,52),(13,52)],(21,40)),
      'perna_frente':([(26,39),(38,39),(38,52),(26,52)],(30,40)),
      'capuz_cabeca':([(12,0),(43,0),(44,24),(38,28),(22,27),(12,15)],(27,25)),
      'braco_cajado':([(24,29),(35,29),(44,22),(56,20),(56,44),(40,43),(30,40),(24,35)],(27,31)),
      'braco_tras':([(12,26),(21,27),(26,35),(24,39),(15,38),(12,32)],(18,28)),
    }
    selected=np.zeros((52,56),bool);parts={};specs={}
    for name,(pts,pivot) in regions.items():
        mask=Image.new('1',(56,52));ImageDraw.Draw(mask).polygon(pts,fill=1);m=np.asarray(mask)&(np.asarray(master)[...,3]>0);selected|=m
        a=np.asarray(master).copy();a[~m]=0;parts[name]=Image.fromarray(a);specs[name]={'pivo':list(pivot),'origem_mestre':[0,0]}
    a=np.asarray(master).copy();a[selected]=0;parts['corpo']=Image.fromarray(a);specs['corpo']={'pivo':[27,33],'origem_mestre':[0,0]}
    # Restore the torso and shoulder surfaces hidden by detachable arm/head.
    torso=parts['corpo'];d=ImageDraw.Draw(torso)
    d.polygon([(20,27),(30,26),(34,38),(29,43),(20,41),(17,33)],fill=tuple(PAL[8])+(255,))
    d.polygon([(24,28),(30,28),(32,38),(27,41),(23,38)],fill=tuple(PAL[11])+(255,))
    d.line([(25,29),(29,31),(30,37)],fill=tuple(PAL[12])+(255,),width=2)
    for name,im in parts.items():
        p=ART/'partes'/f'{name}.png';p.parent.mkdir(parents=True,exist_ok=True);im.save(p);specs[name]['arquivo']=p.relative_to(ART).as_posix();specs[name]['sha256']=sha(p)
    save_json(ART/'rig.json',{'fonte':SOURCE.relative_to(ROOT).as_posix(),'sha256_fonte':sha(SOURCE),'altura_px':52,'ancora_mestre':[27,52],'camadas':['perna_tras','braco_tras','manto_musgo','corpo','perna_frente','capuz_cabeca','braco_cajado'],'partes':specs,'rotacao_maxima_graus':20,'variantes_extremas':'armas desenhadas em poses distintas; corpo caido desenhado, sem escala/rotacao global','pixels_completados':'tronco e ombro sob o braco/capuz; ligacoes do quadril durante a marcha'})
    return parts,master

def paste_piece(canvas,part,dx=0,dy=0):
    canvas.alpha_composite(part,(AX-27+int(dx),AY-52+int(dy)))
def staff_variant(hand, end, lag=0):
    im=blank();hx,hy=hand;ex,ey=end
    # Sleeve and forearm replace the blade-bearing part for extreme poses.
    line(im,[(0,-25),(hx*.45,-24),(hx,hy)],3,9)
    line(im,[(0,-25),(hx*.45,-24),(hx,hy)],8,7)
    line(im,[(1,-27),(hx*.45,-26),(hx,hy-2)],12,3)
    ellipse(im,(hx-3,hy-3,hx+3,hy+3),3);ellipse(im,(hx-2,hy-2,hx+2,hy+1),55)
    line(im,[(hx-5,hy+2),(ex,ey)],3,5);line(im,[(hx-5,hy+2),(ex,ey)],46,3);line(im,[(hx-3,hy+1),(ex,ey-1)],48,1)
    # Olive cluster at the end and two bronze bells hanging after the motion.
    cy=ey-12 if ey>hy+12 else ey
    ellipse(im,(ex-4,cy-4,ex+4,cy+3),3);ellipse(im,(ex-3,cy-3,ex+3,cy+2),49)
    line(im,[(ex-2,cy-2),(ex+2,cy-2)],54,2)
    for bx,by in [(ex-4+lag,cy+8),(ex+3+lag,cy+5)]:
        line(im,[(ex,cy+1),(bx,by)],3,2)
        poly(im,[(bx-2,by),(bx+2,by),(bx+3,by+5),(bx-3,by+5)],3)
        poly(im,[(bx-1,by+1),(bx+1,by+1),(bx+2,by+4),(bx-2,by+4)],56)
        line(im,[(bx-1,by+1),(bx-1,by+3)],61,1)
    return im

def draw_pose(parts,pose):
    im=blank();dx=pose.get('lean',0);dy=pose.get('bob',0);lag=max(-2,min(2,pose.get('lag',0)+pose.get('bell_lag',0)))
    gait=pose.get('gait'); crouch=pose.get('crouch',0)
    if pose.get('fallen'):
        # A replacement piece for the collapsed robe (no squashing/scaling).
        poly(im,[(-16,-7),(-10,-14),(7,-17),(25,-12),(30,-3),(20,-1),(-12,-1)],3)
        poly(im,[(-12,-7),(-8,-12),(7,-14),(22,-10),(26,-4),(17,-3),(-10,-3)],8)
        poly(im,[(-7,-10),(7,-12),(20,-8),(19,-5),(-3,-6)],11)
        line(im,[(-6,-9),(5,-6),(18,-7)],12,2)
        poly(im,[(-15,-4),(-11,-10),(-5,-8),(0,-3),(-12,-2)],47)
        poly(im,[(-9,-7),(-6,-7),(-2,-3),(-7,-3)],50)
        poly(im,[(20,-9),(22,-20),(32,-23),(43,-16),(42,-4),(30,-2)],3)
        poly(im,[(23,-10),(25,-18),(32,-20),(39,-15),(39,-6),(30,-5)],11)
        poly(im,[(31,-16),(38,-14),(38,-8),(33,-6),(29,-9)],57)
        poly(im,[(32,-13),(35,-13),(35,-10),(32,-10)],3)
        line(im,[(25,-18),(29,-19),(33,-18)],14,2)
        line(im,[(23,-18),(19,-23),(20,-27)],3,2)
        line(im,[(22,-20),(25,-26),(25,-29)],3,2)
        im.alpha_composite(staff_variant((22,-8),(47,-16),lag))
        return clean(im)
    for name in ['perna_tras','braco_tras','manto_musgo','corpo','perna_frente','capuz_cabeca']:
        sx,sy=dx,dy+crouch
        if name.startswith('perna'):
            sx,sy=0,0
            if gait is not None:
                n=(gait+(4 if name=='perna_tras' else 0))%8
                target=[8,4,0,-4,-8,-5,0,5][n]
                sx=target-(-6 if name=='perna_tras' else 5)
                sy=[0,0,0,0,0,-3,-5,-2][n]
            if crouch:sy=0;sx=3 if name=='perna_frente' else -3
            # Fill the pixels previously hidden behind the shirt at the hip.
            x=3 if name=='perna_frente' else -5
            line(im,[(dx+x,-13+crouch),(x+sx,-8+sy)],3,8)
            line(im,[(dx+x,-13+crouch),(x+sx,-8+sy)],8 if name=='perna_tras' else 11,5)
        if name=='manto_musgo':
            secondary=pose.get('secondary',pose)
            sx=secondary.get('lean',0)-lag
            sy=secondary.get('bob',0)+secondary.get('crouch',0)
        if name=='capuz_cabeca':sx+=pose.get('head_x',0);sy+=pose.get('head_y',0)
        paste_piece(im,parts[name],sx,sy)
    if pose.get('staff'):
        hand,end=pose['staff'];im.alpha_composite(staff_variant(hand,end,lag))
    else:paste_piece(im,parts['braco_cajado'],dx,dy+crouch+lag)
    return clean(im)

def crescent(center,radius,a0,a1,thickness):
    # Equivalent to arc_e: three broad bands and one thin interior filament.
    yy,xx=np.indices((H,W));dx=xx+.5-AX-center[0];dy=yy+.5-AY-center[1]
    r=np.hypot(dx,dy);theta=np.degrees(np.arctan2(dy,dx));lo=min(a0,a1);hi=max(a0,a1);theta=lo+np.mod(theta-lo,360)
    t=(theta-lo)/(hi-lo);t=np.clip(t,0,1) if a1>=a0 else 1-np.clip(t,0,1)
    thick=thickness*np.sin(np.pi*t**.85)**.8
    mask=(theta>=lo)&(theta<=hi)&(r<=radius)&(r>=radius-thick)&(thick>.6)&(xx>=AX)&(yy<AY)
    dep=(radius-r)/np.maximum(thick,1e-6);a=np.full((H,W),-1,np.int16)
    a[mask]=47;a[mask&(dep<.65)]=50;a[mask&(dep<.32)]=58;a[mask&(radius-r<1.6)]=61
    a[mask&(thick>6)&(abs(dep-.65)<.07)]=54
    im=clean(rgba(a),outline=False,main=False)
    ts=np.linspace(0,1,20)
    outer=[];inner=[]
    for q in ts:
        angle=math.radians(a0+(a1-a0)*q);th=thickness*np.sin(np.pi*q**.85)**.8
        outer.append([round(center[0]+radius*math.cos(angle),2),round(center[1]+radius*math.sin(angle),2)])
        inner.append([round(center[0]+(radius-th)*math.cos(angle),2),round(center[1]+(radius-th)*math.sin(angle),2)])
    polygon=outer+inner[::-1]
    for axis,bound,greater in [(0,0,True),(1,-1,False)]:
        clipped=[]
        for i,p in enumerate(polygon):
            q=polygon[(i+1)%len(polygon)];inside=lambda v:v[axis]>=bound if greater else v[axis]<=bound
            if inside(p):clipped.append(p)
            if inside(p)!=inside(q):
                t=(bound-p[axis])/(q[axis]-p[axis]);r=[p[j]+t*(q[j]-p[j]) for j in range(2)];r[axis]=bound;clipped.append(r)
        polygon=clipped
    unique=[]
    for p in polygon:
        p=[round(v,2) for v in p]
        if not unique or unique[-1]!=p:unique.append(p)
    if unique and unique[0]==unique[-1]:unique.pop()
    return im,{'fase':'ACTIVE','poligono':unique}

def warning(body,red,level):
    a=indices(body);mask=a>=0;outside=mask.copy()
    for _ in range(level):outside=outside|np.any(neighbors(outside.astype(int),0)==1,axis=0)
    border=outside&~mask; near=mask|np.any(neighbors(mask.astype(int),0)==1,axis=0)
    out=np.full((H,W),-1,np.int16);out[border]=26 if red else 16;out[border&near]=41 if red else 18
    return clean(rgba(out),outline=False,main=False)
def times(ms,n):q,r=divmod(ms,n);return [q+(i<r) for i in range(n)]
def tres(attack):
    p=ROOT/'data/attacks'/f'peregrino_{attack}.tres';s=p.read_text(encoding='utf-8')
    vals={k:round(float(re.search(k+r'_seconds\s*=\s*([0-9.]+)',s)[1])*1000) for k in ['windup','active','recovery']}
    vals['parry_class']=re.search(r'parry_class\s*=\s*&"([^"]+)"',s)[1];vals['arquivo']=p.relative_to(ROOT).as_posix();return vals
def descriptor(p,anchor=ANCHOR):
    with Image.open(p) as im:w,h=im.size
    return {'arquivo':p.relative_to(PACK).as_posix(),'sha256':sha(p),'largura':w,'altura':h,'ancora':anchor}

def build():
    if (ART/'ajuste_47c/rig.json').exists():
        import runpy
        revised=runpy.run_path(str(ROOT/'arte_fonte/ferramentas/ajustar_peregrino_47c.py'))
        revised['build'](apply=True);revised['verify']();return
    # Once 4.7b is installed, keep its four revised animations when rerunning
    # the public generator. All other approved 4.7 artwork remains archived.
    if (ART/'ajuste_47b/rig.json').exists():
        import runpy
        revised=runpy.run_path(str(ROOT/'arte_fonte/ferramentas/ajustar_peregrino_47b.py'))
        revised['build'](apply=True);revised['verify']();return
    parts,master=split_master()
    for d in ['sprites','efeitos','sombras','paleta']:(PACK/d).mkdir(parents=True,exist_ok=True)
    shadow=Image.new('RGBA',(30,7));ImageDraw.Draw(shadow).ellipse((1,1,28,5),fill=tuple(PAL[3])+(120,));shadow.save(PACK/'sombras/chao.png');shadow_spec=descriptor(PACK/'sombras/chao.png',[15,3])
    palette=PACK/'paleta/paleta_bosque_v1.json';shutil.copyfile(ROOT/'arte_fonte/paleta/paleta_bosque_v1.json',palette)
    anims=[];rig_poses={}; previews=EVIDENCE/'gifs_x4';previews.mkdir(parents=True,exist_ok=True)
    def animation(name,poses,durations,phases=None,attacks=None,loop=False,loop_start=0,distance=0):
        frames=[];gifs=[];phases=phases or ['ALL']*len(poses)
        for k,(pose,ms,phase) in enumerate(zip(poses,durations,phases)):
            previous=poses[k-1] if loop else poses[max(0,k-1)]
            pose['secondary']={key:previous.get(key,0) for key in ['lean','bob','crouch']}
            if pose.get('staff') and previous.get('staff'):
                delta=previous['staff'][1][0]-pose['staff'][1][0]
                pose['bell_lag']=int(np.sign(delta))
            body=draw_pose(parts,pose);p=PACK/'sprites'/f'{name}_f{k:02d}.png';body.save(p);frame=descriptor(p);frame.update(ms=int(ms),fase=phase,hitbox=None,efeitos=[])
            effects=[]
            if phase=='WINDUP':
                fx=warning(body,name=='ataque_penitencia',min(3,1+pose.get('warn',0)));effects.append((fx,'aviso','atras_do_corpo','brilho_de_aviso'))
            if phase=='ACTIVE':
                fx,hit=crescent(*pose['arc']);frame['hitbox']=hit;effects.append((fx,'arco','frente_do_corpo','arco_musgo_bronze'))
                # The staff itself is part of the damage area, not just the FX.
                hand,end=pose['staff'];shaft=[[max(0,hand[0]),min(-1,hand[1]-4)],[max(0,end[0]),min(-1,end[1]-5)],[max(0,end[0]+3),min(-1,end[1]+7)],[max(0,hand[0]),min(-1,hand[1]+4)]]
                frame['hitbox']={'fase':'ACTIVE','retangulos':[[1,-42,12,34]],'poligono':hit['poligono'],'lamina':{'poligono':shaft}}
                # decode_hitbox accepts rectangles plus a polygon; extent follows
                # the full visible crescent and the proximal staff swing.
            combined=Image.new('RGBA',(W,H),(96,96,96,255))
            for fx,suffix,layer,kind in effects:
                ep=PACK/'efeitos'/f'{name}_f{k:02d}_{suffix}.png';fx.save(ep);spec=descriptor(ep);spec.update(fase=phase,camada=layer,tipo=kind);frame['efeitos'].append(spec)
                if layer=='atras_do_corpo':combined.alpha_composite(fx)
            combined.alpha_composite(body)
            for fx,suffix,layer,kind in effects:
                if layer=='frente_do_corpo':combined.alpha_composite(fx)
            gifs.append(combined.resize((W*4,H*4),Image.Resampling.NEAREST).convert('RGB'))
            frames.append(frame)
        anim={'id':name,'loop':loop,'quadros':frames,'sombra':shadow_spec}
        if loop_start:anim['loop_inicio_quadro']=loop_start
        if distance:anim['px_por_quadro']=distance
        if attacks:anim['ataque']=attacks if len(attacks)>1 else attacks[0]
        anims.append(anim);rig_poses[name]=poses
        gifs[0].save(previews/f'{name}_x4.gif',save_all=True,append_images=gifs[1:],duration=durations,loop=0,disposal=2,optimize=False)
        # Contact sheet without filtering for manual QA of leg alternation/poses.
        sheet=Image.new('RGB',(W*4*min(4,len(gifs)),H*4*math.ceil(len(gifs)/4)),(96,96,96))
        for k,im in enumerate(gifs):sheet.paste(im,(k%4*W*4,k//4*H*4))
        sheet.save(ART/f'{name}_quadros_x4.png')
    animation('idle',[{'bob':v,'lag':[0,0,1,1,0,0][k],'head_y':-1 if k in (2,3) else 0} for k,v in enumerate([0,-1,-1,0,1,0])],times(550,6),loop=True)
    for name,lean,ms in [('patrulha',0,round(4/(29*.9)*1000)),('perseguicao',3,round(4/(64*.9)*1000))]:
        animation(name,[{'gait':k,'lean':lean,'bob':[-1,0,0,-1,-1,0,0,-1][k],'lag':[-1,-1,0,1,1,1,0,-1][k]} for k in range(8)],[ms]*8,loop=True,distance=4)
    animation('alerta',[{'lean':-2,'head_x':-1},{'lean':-1,'bob':-1},{'lean':1,'head_y':-1}],times(280,3))
    animation('dano',[{'lean':-5,'head_x':-2,'head_y':-1,'lag':-2},{'lean':-2,'bob':1,'lag':-1}],[50,50])
    animation('ruptura',[{'lean':v,'crouch':y,'head_y':1,'lag':k%2} for k,(v,y) in enumerate([(-3,2),(-4,5),(-3,8),(-3,9),(-2,10),(-3,10),(-3,9)])],[70,70,90,180,180,180,180],loop=True,loop_start=3)
    animation('morte',[{'lean':-3,'crouch':3},{'lean':3,'crouch':9},{'lean':7,'crouch':13},{'fallen':True,'lag':-1},{'fallen':True,'lag':0},{'fallen':True,'lag':1},{'fallen':True,'lag':0},{'fallen':True,'lag':0}],[60,80,100,110,110,120,140,400])
    def attack_spec(key,offset,nw,na,nr):
        t=tres(key);ranges=[list(range(offset,offset+nw)),list(range(offset+nw,offset+nw+na)),list(range(offset+nw+na,offset+nw+na+nr))]
        return {'attack_id':'peregrino_'+key,'tres':dict(t,windup_ms=t['windup'],active_ms=t['active'],recovery_ms=t['recovery']),'fases':{phase:{'quadros':r,'ms':t[label]} for phase,label,r in zip(['PREPARACAO','ATIVO','RECUPERACAO'],['windup','active','recovery'],ranges)}}
    def swing(key,reverse=False):
        t=tres(key);nw=3 if key in ['corte','estocada','corte_duplo_1'] else 2 if key=='corte_duplo_2' else 4;nr=1 if key=='corte_duplo_1' else 3
        wind=[{'lean':-k,'bob':1,'staff':[(6-k,-29-k*3),(20-k*2,-40-k*5)],'warn':k,'lag':0 if k==0 else -1} for k in range(nw)]
        if key in ['estocada','investida']:
            active=[{'lean':3+k,'staff':[(17+k*3,-26),(48+k*5,-26)],'lag':-k,'arc':[(25,-4),35+k*3,-140,-40,13]} for k in range(2)]
        elif key=='penitencia':
            wind=[{'lean':-1,'bob':1,'staff':[(9,-30-k*3),(19,-51-k*3)],'warn':k,'lag':-1} for k in range(nw)]
            active=[{'lean':3,'crouch':5,'staff':[(24,-28),(24,-2)],'lag':k,'arc':[(7,-25),40, -75 if k==0 else -95,38,14+k*3]} for k in range(2)]
        else:
            active=[{'lean':2+k*2,'staff':[(12,-31+k*8),(42,-43+k*35)],'lag':1-k,'arc':[(4,-28),43+k, -100, -5 if k==0 else 48,13+k*3]} for k in range(2)]
            if reverse:
                active.reverse()
        recover=[{'lean':max(0,3-k),'staff':[(13,-22),(31,-8-k*4)],'lag':1 if k<2 else 0} for k in range(nr)]
        poses=wind+active+recover;return poses,times(t['windup'],nw)+times(t['active'],2)+times(t['recovery'],nr),['WINDUP']*nw+['ACTIVE']*2+['RECOVERY']*nr,attack_spec(key,0,nw,2,nr)
    for key in ['corte','estocada','investida','penitencia']:
        p,m,f,s=swing(key);animation('ataque_'+key,p,m,f,[s])
    p1,m1,f1,s1=swing('corte_duplo_1');p2,m2,f2,s2=swing('corte_duplo_2',True)
    for phase in s2['fases'].values():phase['quadros']=[i+len(p1) for i in phase['quadros']]
    animation('ataque_corte_duplo',p1+p2,m1+m2,f1+f2,[s1,s2])
    manifest={'pacote':'peregrino_corrompido_v1','versao':1,'personagem':'Peregrino Corrompido','status':'para avaliacao da tarefa 4.7','fonte':{'mestre':SOURCE.relative_to(ROOT).as_posix(),'sha256':sha(SOURCE),'recorte':'arte_fonte/referencias/inimigos_v2/recortes/peregrino_corrompido.png'},'altura_referencia_px':52,'paleta':{'arquivo':palette.relative_to(PACK).as_posix(),'sha256':sha(palette),'cores':62,'travada':True},'hurtbox_sugerida':{'raio_px':7,'altura_px':48,'descricao':'tronco e capuz, sem galhos/arma; pes conservados'},'estados_ia':json.loads((ROOT/'data/enemies/peregrino_mapa.json').read_text())['estados'],'animacoes':anims}
    save_json(PACK/'manifesto_sprites.json',manifest);save_json(ART/'poses.json',rig_poses)
    # Save extreme arm replacements as editable rig parts as well.
    for name,hand,end in [('alto',(4,-38),(12,-57)),('horizontal',(20,-26),(53,-26)),('cravado',(24,-28),(24,-2)),('baixo',(12,-23),(42,-8))]:
        p=ART/'partes'/f'braco_cajado_{name}.png';staff_variant(hand,end).save(p)
        rig=json.loads((ART/'rig.json').read_text(encoding='utf-8'));rig['partes']['braco_cajado_'+name]={'arquivo':p.relative_to(ART).as_posix(),'sha256':sha(p),'pivo':[AX,AY-25],'variante':True};save_json(ART/'rig.json',rig)
    rig=json.loads((ART/'rig.json').read_text(encoding='utf-8'));rig['movimento_secundario']='manto/musgo usam lean/bob/crouch do quadro anterior; sinos atrasam a direcao da ponta do cajado em 1 quadro';save_json(ART/'rig.json',rig)
    comparison=Image.new('RGB',(116*4,68*4),(40,36,39))
    for x,im in [(2,Image.open(SOURCE)),(58,master)]:
        tile=Image.new('RGBA',(116,68));tile.alpha_composite(im,(x,8));comparison.paste(tile.resize((464,272),Image.Resampling.NEAREST),(0,0),tile.resize((464,272),Image.Resampling.NEAREST))
    comparison.save(ART/'limpeza_antes_depois_x4.png')
    player_manifest=json.loads((ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json').read_text(encoding='utf-8'))
    idle=next(a for a in player_manifest['animacoes'] if a['id']=='idle')['quadros'][0]
    player=Image.open(ROOT/'assets/characters/pequeno_v34A'/idle['arquivo']).convert('RGBA');player=player.crop(player.getbbox())
    scale=Image.new('RGBA',(128,68),(40,36,39,255));scale.alpha_composite(player,(8,60-player.height));scale.alpha_composite(master,(65,60-master.height))
    scale.save(ART/'escala_carrasco_corrompido_x1.png');scale.resize((512,272),Image.Resampling.NEAREST).save(ART/'escala_carrasco_corrompido_x4.png')
    verify()

def verify():
    if (ART/'ajuste_47c/rig.json').exists():
        import runpy
        runpy.run_path(str(ROOT/'arte_fonte/ferramentas/ajustar_peregrino_47c.py'))['verify']();return
    if (ART/'ajuste_47b/rig.json').exists():
        import runpy
        runpy.run_path(str(ROOT/'arte_fonte/ferramentas/ajustar_peregrino_47b.py'))['verify']();return
    data=json.loads((PACK/'manifesto_sprites.json').read_text(encoding='utf-8'));checks=[];unique=set();timings=[]
    assert len(data['animacoes'])==12
    for anim in data['animacoes']:
        for f in anim['quadros']:
            p=PACK/f['arquivo'];im=Image.open(p);a=indices(im);mask=a>=0
            isolated=int(np.count_nonzero(mask&~np.any(neighbors(a)==a,axis=0)))
            assert sha(p)==f['sha256'] and f['ancora']==ANCHOR and im.size==(W,H)
            assert len(components(mask))==1 and isolated==0,(p.name,len(components(mask)),isolated)
            assert (f['hitbox'] is not None)==(f['fase']=='ACTIVE')
            unique.add(sha(p));checks.append({'arquivo':f['arquivo'],'sha256':sha(p),'componentes':1,'pixels_isolados':isolated,'fase':f['fase']})
            for spec in f['efeitos']+[anim['sombra']]:
                p=PACK/spec['arquivo'];assert sha(p)==spec['sha256'];indices(Image.open(p))
        for spec in ([anim['ataque']] if isinstance(anim.get('ataque'),dict) else anim.get('ataque',[])):
            original=tres(spec['attack_id'].removeprefix('peregrino_'));sums={}
            for phase,key in [('PREPARACAO','windup'),('ATIVO','active'),('RECUPERACAO','recovery')]:
                total=sum(anim['quadros'][i]['ms'] for i in spec['fases'][phase]['quadros']);assert total==original[key];sums[phase]=total
            timings.append({'attack_id':spec['attack_id'],'fases_ms':sums,'igual_tres':True})
    assert len(unique)>50,'Rig sem variacao de poses'
    save_json(EVIDENCE/'VERIFICACAO_ARTE.json',{'animacoes':12,'quadros':len(checks),'quadros_unicos':len(unique),'altura_mestre':52,'paleta':62,'fonte_sha256':sha(SOURCE),'tempos':timings,'quadros_verificados':checks})
    print({'animacoes':12,'quadros':len(checks),'quadros_unicos':len(unique),'ataques_tempos_preservados':len(timings)})

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');args=p.parse_args()
    verify() if args.verify else build()
