"""4.8b7: approved run f0 -> exact layered rig -> eight distance-run poses.

No rejected design or old human rig is loaded. New leg pieces are continuous
hand-defined silhouettes, with a complete cuff and approved compact boot volume.
The kit is read only; this is source art and an external preview, not a package.
"""
from pathlib import Path
import argparse, collections, csv, hashlib, json, math, re, subprocess, sys
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT/'arte_fonte/kit_rig'), str(ROOT/'.godot/forma_humana_48b6/deps')]
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from kitrig import Paleta, Rig, Parte, Tela, quadro_por_distancia
from kitrig.desenho import _vizinhos, componentes
from kitrig.previa import fundo_cemiterio, chao_na_tela

BASE = ROOT/'arte_fonte/forma_humana_v1/pose_corrida_48b6/run_f0_x1.png'
EXPECTED = '28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852'
ART = BASE.parent.parent/'rig_corrida_48b7'
OUT = ROOT/'codex/evidencias_forma_humana_48b7'
PAL = Paleta.carregar(ROOT/'arte_fonte/paleta/paleta_bosque_v1.json')
AX, AY = 40, 56
TEMPLATE = Tela(96,64,AX,AY)
BOB = [0,-1,0,1,0,-1,0,0]
LAYERS = ['perna_tras','braco_distante','capa','tronco','perna_frente',
          'capuz','cabeca_cabelo','braco_proximo','mao_espada']

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def image(a): return Image.fromarray(PAL.para_rgba(a))
def polygon(points):
    p=Image.new('1',(96,64));ImageDraw.Draw(p).polygon(points,fill=1);return np.array(p)
def rect(box):
    x0,y0,x1,y1=box;yy,xx=np.mgrid[:64,:96]
    return (xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)
def move(a,dx,dy):
    out=TEMPLATE.vazia();h,w=a.shape
    x0,y0=max(0,dx),max(0,dy);x1,y1=min(w,w+dx),min(h,h+dy)
    if x1>x0 and y1>y0:out[y0:y1,x0:x1]=a[y0-dy:y1-dy,x0-dx:x1-dx]
    return out
def merge(a,b):
    a=a.copy();a[b>=0]=b[b>=0];return a

def split():
    assert sha(BASE)==EXPECTED
    master=PAL.de_rgba(np.array(Image.open(BASE)),estrito=True)
    yy,xx=np.mgrid[:64,:96]
    head=np.array(Image.open(BASE.parent/'cabeca_mestre_transladada.png'))[...,3]>0
    assert np.array_equal(np.array(Image.open(BASE))[head],np.array(Image.open(BASE.parent/'cabeca_mestre_transladada.png'))[head])
    blade=np.isin(master,[16,17,18])&(yy>=39)&(xx>=32)
    rim=ndi.binary_dilation(blade,np.ones((3,3)))&(master==3)&(xx>=32)&(yy>=39)
    weapon=blade|rim|polygon([(29,37),(33,37),(34,40),(32,42),(29,40)])
    weapon[52,52:57]=True  # entire native dark tapered tip belongs to the sword
    regions={
      'cabeca_cabelo':dict(mascara=head,pivo=(36,24)),
      'mao_espada':dict(mascara=weapon,pivo=(31,38)),
      'braco_distante':dict(poligono=[(36,31),(38,32),(41,33),(44,35),(44,38),(40,38),(36,35)],pivo=(36,31)),
      'braco_proximo':dict(poligono=[(27,28),(30,29),(32,32),(31,35),(33,37),(31,40),(27,39),(26,34),(25,32)],pivo=(28,31)),
      'perna_tras':dict(mascara=rect((14,40,32,50)),pivo=(28,40)),
      'perna_frente':dict(mascara=(yy>=40)&(xx>=32),pivo=(34,40)),
      'capa':dict(mascara=polygon([(23,26),(28,29),(27,33),(24,37),(23,41),(18,43),(15,40),(11,42),(8,38),(9,34),(15,31),(20,28)])|((xx<24)&(yy>=30)),pivo=(23,29)),
      'capuz':dict(mascara=(yy>=23)&(yy<=29),pivo=(32,27)),
      'tronco':dict(mascara=np.ones(master.shape,bool),pivo=(32,34)),
    }
    # Hidden shoulder/hip fills are only under other original opaque parts.
    regions['tronco']['completar']=[(rect((27,30,32,39)),8),(rect((29,31,31,37)),10)]
    rig=Rig.de_mestre(PAL,master,(AX,AY),regions,LAYERS,altura_px=48)
    rig.fixas=['perna_tras','perna_frente']
    assert np.array_equal(PAL.para_rgba(rig.renderizar(TEMPLATE.nova(),{}).a),np.array(Image.open(BASE)))
    image(rig.renderizar(TEMPLATE.nova(),{}).a).save(ART/'f0_recomposta_x1.png')
    save(OUT/'RECONSTRUCAO_F0.json',{'base_sha256':EXPECTED,'pixels_diferentes_rgba':0,
        'rgba_identico':True,'partes_base':len(rig.partes),'camadas':LAYERS,
        'completar':'somente pixels ocultos dentro da silhueta da base'})
    return rig,master

# Each entry is ONE coherent outline, not overlapping thigh/shin strips.
# New joints follow the approved f0 proportions; no rejected coordinates load.
# Stance sole shifts -6px at each +6px body event. Swing has its own trajectory.
GEOMETRY={
  1:dict(hip=(34,39),knee=(34,46),ankle=(33,51),sole=(34,55),
      outline=[(31,39),(36,39),(37,42),(37,45),(36,48),(36,51),(30,51),(30,48),(31,45),(31,42)]),
  2:dict(hip=(34,40),knee=(31,46),ankle=(27,51),sole=(28,55),
      outline=[(31,40),(36,40),(36,43),(35,46),(34,49),(30,52),(24,52),(24,49),(28,47),(29,44)]),
  3:dict(hip=(32,41),knee=(28,46),ankle=(22,51),sole=(22,55),
      outline=[(31,40),(36,41),(35,44),(32,47),(30,49),(25,52),(18,52),(18,49),(24,47),(27,44)]),
  5:dict(hip=(28,39),knee=(33,44),ankle=(27,43),sole=(24,48),
      outline=[(25,39),(30,39),(33,41),(35,43),(35,45),(33,47),(29,47),(25,46),(24,43),(26,42)]),
  6:dict(hip=(28,40),knee=(36,43),ankle=(34,45),sole=(35,50),
      outline=[(25,39),(30,39),(34,40),(38,42),(39,44),(38,47),(31,47),(31,44),(28,43),(25,42)]),
  7:dict(hip=(28,41),knee=(36,45),ankle=(40,48),sole=(41,53),
      outline=[(25,40),(30,40),(34,41),(39,44),(42,46),(43,49),(37,50),(35,47),(31,45),(27,44),(25,42)]),
}

def recolor(a,near):
    out=a.copy()
    mapping={7:8,8:10,10:11,11:13,13:13} if near else {13:11,11:10,10:8,8:7}
    for before,after in mapping.items():out[a==before]=after
    return out

def shade_outline(points,joints,near):
    """Hand silhouette with continuous leather facets along its direction."""
    mask=polygon(points);a=TEMPLATE.vazia()
    border=mask&~ndi.binary_erosion(mask,ndi.generate_binary_structure(2,1))
    # User adjustment: dark trousers above the visibly brown boot cuff.
    dark,mid,light=(0,1,2) if near else (0,0,1)
    a[mask]=mid;a[border]=3
    # Follow each row's actual silhouette: broad shadow, core, top-right light.
    for y in range(39,53):
        xs=np.where(mask[y]&~border[y])[0]
        if len(xs):
            a[y,xs[:max(1,len(xs)//3)]]=dark
            if len(xs)>=3:a[y,xs[-2:]]=light
    hx,hy=joints['hip'];kx,ky=joints['knee']
    # Two-pixel cloth crease reinforces a single knee without a separate block.
    for x,y in ((kx-1,ky),(kx,ky)):
        if a[y,x]>=0 and not border[y,x]:a[y,x]=dark
    return a

def boot_shadow(a):
    out=a.copy()
    for before,after in {8:7,10:8,13:11}.items():out[a==before]=after
    return out

def stance_leg(q,near):
    """A whole authored leg, with continuous six-pixel diagonal sections.

    Hip -> single knee -> shin -> heel, then a rounded shoe/toe. No cropped
    tube or old boot stamp is joined to an inclined leg. Trousers and leather
    share one coherent silhouette; the foot broadens gradually in three rows.
    """
    rows={
      1:[(39,31,36),(40,31,36),(41,31,36),(42,31,36),(43,31,36),(44,31,36),
         (45,31,36),(46,31,36),(47,31,36),(48,31,36),(49,31,36),(50,30,35),
         (51,30,35),(52,30,35),(53,30,36),(54,30,37),(55,30,38)],
      2:[(40,31,36),(41,31,36),(42,31,36),(43,30,35),(44,30,35),(45,29,34),
         (46,29,34),(47,28,33),(48,27,32),(49,26,31),(50,25,30),(51,24,29),
         (52,24,29),(53,24,30),(54,24,31),(55,24,32)],
      3:[(40,30,35),(41,30,35),(42,29,34),(43,28,33),(44,27,32),(45,26,31),
         (46,25,30),(47,24,29),(48,23,28),(49,22,27),(50,21,26),(51,20,25),
         (52,19,24),(53,18,24),(54,18,25),(55,18,26)]
    }[q]
    a=TEMPLATE.vazia();cuff={1:47,2:47,3:48}[q]
    for y,x0,x1 in rows:
        a[y,x0:x1+1]=3
        if y==55:continue
        if y<cuff:
            a[y,x0+1:x1]=1 if near else 0
            a[y,x0+1]=0;a[y,x1-1]=2 if near else 1
        else:
            a[y,x0+1:x1]=10 if near else 8
            a[y,x0+1]=8 if near else 7
            a[y,x1-2:x1]=13 if near else 11
            if y>=53:a[y,x0+2:min(x1,x0+5)]=11 if near else 10
    # The collar is leather, not a swollen knee. A small trouser crease sits
    # above it, inside the continuous thigh, without another silhouette lump.
    kx,ky=GEOMETRY[q]['knee']
    for x,y in [(kx-1,ky),(kx,ky)]:
        if a[y,x]>=0 and a[y,x]!=3 and y<cuff:a[y,x]=0
    return clean_piece(a)

def clean_piece(a):
    for _ in range(12):
        isolated=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
        if not isolated.any():break
        for y,x in zip(*np.where(isolated)):
            vals=[int(a[y+dy,x+dx]) for dy in (-1,0,1) for dx in (-1,0,1)
                  if (dx or dy) and 0<=y+dy<64 and 0<=x+dx<96 and a[y+dy,x+dx]>=0]
            if vals:a[y,x]=collections.Counter(vals).most_common(1)[0][0]
    return a

def build_legs(rig):
    near0=rig.partes['perna_frente'].idx
    far4=rig.partes['perna_tras'].idx
    boot=near0.copy();boot[:50]=-1
    tilted=far4.copy();tilted[~rect((14,43,23,50))]=-1
    # Full native boot, translated as a rigid piece; no stretched toe/calf.
    for side in ('frente','tras'):
        near=side=='frente'
        for q in range(8):
            if q==0:
                a=near0.copy() if near else recolor(near0,False)
                row=dict(hip=(34,40),knee=(36,47),ankle=(39,51),sole=(40,55))
                if not near:
                    a=near0.copy()
                    cloth=(a>=0)&(np.indices(a.shape)[0]<44)&(a!=3)
                    orig=a.copy()
                    a[cloth]=0;a[cloth&np.isin(orig,[10,11,13])]=1
                    a[44:]=boot_shadow(a)[44:]
            elif q==4:
                a=recolor(far4,True) if near else far4.copy()
                row=dict(hip=(28,40),knee=(26,45),ankle=(18,44),sole=(15,49))
            else:
                row=GEOMETRY[q]
                if q<=3:
                    a=stance_leg(q,near)
                else:
                    a=shade_outline(row['outline'],row,near)
                    sx,sy=row['sole']
                    if q==5:
                        b=move(tilted,sx-15,sy-49)
                        if near:b=recolor(b,True)
                    else:
                        b=move(boot,sx-40,sy-55)
                        if not near:b=boot_shadow(b)
                    a=merge(a,b);a=clean_piece(a)
            name=f'perna_{side}_q{q}'
            rig.partes[name]=Parte(name,a,rig.partes['perna_'+side].pivo,(0,0),'perna_'+side)

def pose_for(k):
    rows=[]
    for side,q in [('frente',k),('tras',(k+4)%8)]:
        if q==0:geom=dict(hip=(34,40),knee=(36,47),ankle=(39,51),sole=(40,55))
        elif q==4:geom=dict(hip=(28,40),knee=(26,45),ankle=(18,44),sole=(15,49))
        else:geom=GEOMETRY[q]
        rows.append({'perna':side,'fase':q,'apoio':q<=3,
            'quadril':list(geom['hip']),'joelho':list(geom['knee']),
            'tornozelo':list(geom['ankle']),'sola':list(geom['sole']),
            'variante':f'perna_{side}_q{q}'})
    sway=0  # combat carry: native hands and straight sword stay rigid together
    cape=BOB[(k-1)%8]-BOB[7]
    pose={'dx':0,'dy':BOB[k],'fixas':['perna_tras','perna_frente'],'partes':{
        'perna_frente':{'variante':rows[0]['variante']},
        'perna_tras':{'variante':rows[1]['variante']},
        'capa':{'dy':cape-BOB[k]},
        'braco_proximo':{'dx':sway},'mao_espada':{'dx':sway},
        'braco_distante':{'dx':-sway}}}
    return {'quadro':k,'pose_rig':pose,'pernas':rows,'capa_origem_quadro':(k-1)%8,
            'oscilacao_corpo_y':BOB[k],'oscilacao_capa_y':cape,'ajustes_pixels':[]}

def render_pose(rig,row):
    p=row['pose_rig'];t=TEMPLATE.nova()
    rig.renderizar(t,p,ordem=['perna_tras','braco_distante','capa','tronco'])
    clothes=rig.renderizar(TEMPLATE.nova(),p,ordem=['capa','tronco']).a
    q=p['partes']['perna_frente'];near=rig.desenhar_parte(TEMPLATE,'perna_frente',variante=q['variante'])
    near[clothes>=0]=-1;t.camada(near)
    rig.renderizar(t,p,ordem=['capuz','cabeca_cabelo','braco_proximo','mao_espada'])
    for x,y,color in row['ajustes_pixels']:t.a[y,x]=color
    return t.a

def finish_pixels(rig,row):
    a=render_pose(rig,row)
    if row['quadro']==0:return a
    # Clean only new seam pixels; preserve the rigid approved head/hand/blade.
    p=row['pose_rig'];fixed=np.zeros(a.shape,bool)
    for name in ['cabeca_cabelo','mao_espada']:
        q=p['partes'].get(name,{})
        b=rig.desenhar_parte(TEMPLATE,name,q.get('dx',0),p['dy']+q.get('dy',0))
        fixed|=(b>=0)&(a==b)
    before=a.copy()
    # The head's original collar rim used to be supplied by the cape. When
    # that cloth lags, complete the exposed dark rim instead of repainting
    # any approved hair/face pixel.
    for y,x in zip(*np.where(fixed&(a>=0)&(a!=3))):
        for dy,dx in [(0,-1),(0,1),(-1,0),(1,0)]:
            if 0<=y+dy<64 and 0<=x+dx<96 and a[y+dy,x+dx]<0:a[y+dy,x+dx]=3
    boundary=(a>=0)&~ndi.binary_erosion(a>=0,ndi.generate_binary_structure(2,1))
    a[boundary&~fixed]=3  # restore the one-pixel dark rim at newly exposed cloth seams
    for _ in range(20):
        isolated=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
        if not isolated.any():break
        for y,x in zip(*np.where(isolated)):
            n=[(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1)
               if (dx or dy) and 0<=y+dy<64 and 0<=x+dx<96 and a[y+dy,x+dx]>=0]
            if fixed[y,x]:
                n=[v for v in n if not fixed[v]]
                if n:
                    boundary=(a>=0)&~ndi.binary_erosion(a>=0,ndi.generate_binary_structure(2,1))
                    inside=[v for v in n if not boundary[v]]
                    q=min(inside or n,key=lambda v:(-v[0],abs(v[1]-x)))
                    a[q]=a[y,x]
                    # A new collar colour mate needs its own dark edge.
                    for dy,dx in [(0,-1),(0,1),(-1,0),(1,0)]:
                        ny,nx=q[0]+dy,q[1]+dx
                        if 0<=ny<64 and 0<=nx<96 and a[ny,nx]<0:a[ny,nx]=3
            elif n:a[y,x]=collections.Counter(int(a[v]) for v in n).most_common(1)[0][0]
    row['ajustes_pixels']=[[int(x),int(y),int(a[y,x])] for y,x in zip(*np.where(a!=before))]
    return a

def make_frames(rig):
    build_legs(rig)
    data=rig.salvar(ART,fonte=BASE.relative_to(ROOT).as_posix(),extra={
      'base_sha256':EXPECTED,'biblioteca':'arte_fonte/kit_rig/kitrig',
      'uso':'somente run para avaliação, sem instalação ou pacote final',
      'variantes':'silhuetas contínuas desenhadas por flexão; botas compactas sem escala',
      'camada_pano_cobre_raiz_perna_proxima':True,'atraso_capa_quadros':1,
      'cabeca_arma':'translação rígida, sem rotação ou escala'})
    # Store explicit absolute origin for full-canvas variants (same base pivot).
    for name,p in data['partes'].items():
        if p.get('variante'):p['origem_mestre']=[0,0]
    save(ART/'rig.json',data)
    rig=Rig.carregar(ART/'rig.json',PAL)
    rows=[pose_for(k) for k in range(8)];frames=[finish_pixels(rig,row) for row in rows]
    assert np.array_equal(PAL.para_rgba(frames[0]),np.array(Image.open(BASE)))
    refpath=ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json'
    ref=next(a for a in json.loads(refpath.read_text(encoding='utf-8'))['animacoes'] if a['id']=='run')
    entries=[]
    for k,a in enumerate(frames):
        p=ART/f'quadros/run/run_f{k}.png';p.parent.mkdir(parents=True,exist_ok=True);image(a).save(p)
        entries.append({'quadro':k,'arquivo':p.relative_to(ART).as_posix(),'sha256':sha(p),
            'ms':ref['quadros'][k]['ms'],'ancora':[AX,AY],'nome_referencia':ref['quadros'][k]['arquivo']})
    contract={'referencia':refpath.relative_to(ROOT).as_posix(),'referencia_sha256':sha(refpath),
      'base_sha256':EXPECTED,'nao_e_pacote_final':True,'arte_instalada':False,
      'canvas':[96,64],'ancora':[AX,AY],'chao_y':55,'paleta':'paleta_bosque_v1',
      'sem_walk':True,'caminhada_usa':'run','somente_run':True,
      'animacoes':[{'id':'run','quadros':entries,'px_por_quadro':6,'loop':True,
       'duracao_soma_ms':sum(q['ms'] for q in entries),'duracao_nominal_referencia_ms':ref['duracao_total_ms']}],
      'selecao':'floor(distancia_px / 6) mod 8','sem_sombra_embutida':True}
    save(ART/'poses.json',{'run':rows});save(ART/'contrato_ciclos.json',contract)
    save(ART/'SOLAS_ARTICULACOES.json',{'coordenadas':'canvas inteiro, âncora (40,56)',
        'chao_y':55,'desenho_novo_sem_trajetorias_rejeitadas':True,
        'quadros':[{'quadro':r['quadro'],'pernas':r['pernas']} for r in rows]})
    return frames,rows,contract

def textfont(n=12):return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def gray(a):
    b=Image.new('RGBA',(96,64),(96,96,96,255));b.alpha_composite(image(a));return b

def evidence(master,frames,rows,contract):
    sheet=Image.new('RGB',(768,80),(96,96,96));d=ImageDraw.Draw(sheet)
    for k,a in enumerate(frames):
        sheet.paste(gray(a).convert('RGB'),(k*96,16));d.text((k*96+4,2),f'f{k}',font=textfont(10),fill='white')
    sheet.save(OUT/'run_quadros_x1.png');sheet.resize((3072,320),Image.Resampling.NEAREST).save(OUT/'run_quadros_x4.png')
    imgs=[gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB') for a in frames]
    times=[q['ms'] for q in contract['animacoes'][0]['quadros']]
    ends=[int(round(t/10))*10 for t in np.cumsum(times)]
    gif_ms=[ends[0]]+[b-a for a,b in zip(ends,ends[1:])]
    imgs[0].save(OUT/'run_x4.gif',save_all=True,append_images=imgs[1:],duration=gif_ms,loop=0,disposal=2,optimize=False)
    for pairs,name in [([0,4],'f0_f4'),([2,6],'f2_f6')]:
        out=Image.new('RGB',(768,296),(96,96,96));d=ImageDraw.Draw(out)
        for i,k in enumerate(pairs):
            out.paste(imgs[k],(i*384,32));d.text((i*384+12,10),f'run f{k} — '+('troca de apoio' if k%4==0 else 'passagem elevada'),font=textfont(15),fill='white')
        out.save(OUT/f'COMPARACAO_{name}_x4.png')
    out=Image.new('RGB',(768,296),(96,96,96));d=ImageDraw.Draw(out)
    for i,a in enumerate([master,frames[0]]):
        out.paste(gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB'),(i*384,32))
        d.text((i*384+12,10),'BASE APROVADA' if i==0 else 'f0 RECOMPOSTA: ZERO DIFERENÇAS RGBA',font=textfont(14),fill='white')
    out.save(OUT/'F0_RECOMPOSTA_x4.png')
    joints=Image.new('RGB',(4*384,2*286),(96,96,96));d=ImageDraw.Draw(joints)
    for k,a in enumerate(frames):
        x,y=(k%4)*384,(k//4)*286;joints.paste(imgs[k],(x,y+24));d.text((x+8,y+6),f'f{k} — articulações auxiliares',font=textfont(13),fill='white')
        for leg in rows[k]['pernas']:
            pts=[leg[q] for q in ['quadril','joelho','tornozelo','sola']]
            pts=[(x+px*4+2,y+24+py*4+2) for px,py in pts]
            color='#e9b66c' if leg['perna']=='frente' else '#88d4cc'
            d.line(pts,fill=color,width=2)
            for px,py in pts:d.ellipse((px-3,py-3,px+3,py+3),fill=color)
    joints.save(OUT/'ARTICULACOES_AUXILIAR_x4.png')
    # Native pieces with actual pivots; variants are in rig.json/partes.
    rigdata=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    partview=Image.new('RGB',(3*384,3*286),(96,96,96));d=ImageDraw.Draw(partview)
    for i,name in enumerate(LAYERS):
        p=rigdata['partes'][name];im=Image.open(ART/p['arquivo']).convert('RGBA')
        b=Image.new('RGBA',im.size,(96,96,96,255));b.alpha_composite(im)
        x,y=(i%3)*384,(i//3)*286
        partview.paste(b.resize((384,256),Image.Resampling.NEAREST).convert('RGB'),(x,y+24))
        d.text((x+8,y+6),name+' / pivô '+str(p['pivo']),font=textfont(13),fill='white')
        px,py=p['pivo'];cx,cy=x+px*4+2,y+24+py*4+2
        d.line((cx-5,cy,cx+5,cy),fill='#dfb766');d.line((cx,cy-5,cx,cy+5),fill='#dfb766')
    partview.save(OUT/'PARTES_PIVOS_x4.png')
    legs=Image.new('RGB',(8*184,208),(96,96,96));d=ImageDraw.Draw(legs)
    for k,a in enumerate(frames):
        crop=gray(a).crop((10,36,56,60)).resize((184,96),Image.Resampling.NEAREST)
        legs.paste(crop.convert('RGB'),(k*184,22))
        d.text((k*184+8,4),f'f{k}',font=textfont(12),fill='white')
        for j,leg in enumerate(rows[k]['pernas']):
            d.text((k*184+4,126+j*32),leg['perna']+': '+('apoio' if leg['apoio'] else 'passagem'),font=textfont(12),fill='#e5b46b' if leg['perna']=='frente' else '#8bd6ce')
            d.text((k*184+4,142+j*32),'sola '+str(leg['sola']),font=textfont(11),fill='white')
    legs.save(OUT/'PERNAS_SOLAS_x4.png')
    olddir=OUT/'antes_ajuste_bota_usuario/quadros'
    if olddir.exists():
        changes=[]
        for k,a in enumerate(frames):
            old=np.array(Image.open(olddir/f'run_f{k}.png').convert('RGBA'))
            diff=np.any(old!=PAL.para_rgba(a),axis=2)
            assert not diff[:39].any(),'Boot adjustment reached head/trunk/arms'
            ys,xs=np.where(diff)
            changes.append({'quadro':k,'pixels_alterados':int(diff.sum()),
                'bbox':None if not len(xs) else [int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],
                'antes_sha256':sha(olddir/f'run_f{k}.png'),
                'depois_sha256':sha(ART/f'quadros/run/run_f{k}.png'),
                'cabeca_tronco_bracos_arma_preservados':True})
        comp=Image.new('RGB',(816,280),(96,96,96));d=ImageDraw.Draw(comp)
        for i,(label,p) in enumerate([('ANTES',olddir/'run_f5.png'),('BOTA + CALÇA ESCURA',ART/'quadros/run/run_f5.png')]):
            im=Image.open(p).convert('RGBA');b=Image.new('RGBA',im.size,(96,96,96,255));b.alpha_composite(im)
            comp.paste(b.crop((24,37,44,57)).resize((240,240),Image.Resampling.NEAREST).convert('RGB'),(i*272+8,32))
            d.text((i*272+8,10),label,font=textfont(15),fill='white')
        ref=Image.open(OUT/'REFERENCIA_USUARIO_BOTA.png').convert('RGB')
        comp.paste(ref.resize((ref.width*2,ref.height*2),Image.Resampling.NEAREST),(552,42))
        d.text((552,10),'REFERÊNCIA DO USUÁRIO',font=textfont(15),fill='white')
        comp.save(OUT/'AJUSTE_BOTA_ANTES_DEPOIS.png')
        f3comp=Image.new('RGB',(816,280),(96,96,96));d=ImageDraw.Draw(f3comp)
        for i,(label,p) in enumerate([('f3 ANTES',olddir/'run_f3.png'),('f3 BOTA + CALÇA ESCURA',ART/'quadros/run/run_f3.png')]):
            im=Image.open(p).convert('RGBA');b=Image.new('RGBA',im.size,(96,96,96,255));b.alpha_composite(im)
            f3comp.paste(b.crop((14,37,48,59)).resize((272,176),Image.Resampling.NEAREST).convert('RGB'),(i*272+2,60))
            d.text((i*272+6,12),label,font=textfont(15),fill='white')
        f3comp.paste(ref.resize((ref.width*2,ref.height*2),Image.Resampling.NEAREST),(552,42))
        d.text((552,12),'REFERÊNCIA DO USUÁRIO',font=textfont(15),fill='white')
        f3comp.save(OUT/'AJUSTE_F3_BOTA_ANTES_DEPOIS.png')
        last=OUT/'antes_refazer_f3_usuario/quadros/run_f3.png'
        if last.exists():
            out=Image.new('RGB',(768,296),(96,96,96));d=ImageDraw.Draw(out)
            for i,(label,p) in enumerate([('AFINAMENTO REJEITADO',last),('NOVA COXA / CANELA / BOTA',ART/'quadros/run/run_f3.png')]):
                im=Image.open(p).convert('RGBA');b=Image.new('RGBA',im.size,(96,96,96,255));b.alpha_composite(im)
                out.paste(b.resize((384,256),Image.Resampling.NEAREST).convert('RGB'),(i*384,32))
                d.text((i*384+12,10),label,font=textfont(14),fill='white')
            out.save(OUT/'F3_REDESENHO_ANTES_DEPOIS_x4.png')
        save(OUT/'AJUSTE_BOTA_USUARIO.json',{'somente_pernas_botas':True,
            'f0_preservada':changes[0]['pixels_alterados']==0,'quadros':changes,
            'apoios_tempos_cadencia_preservados':True,'referencia_sha256':sha(OUT/'REFERENCIA_USUARIO_BOTA.png'),
            'calca':'carvão oficial 0/1/2','bota':'couro oficial 7/8/10/11/13',
            'cano_px':6,'canela_min_px':6,'sola_nativa_apoio_px':9})

def verify():
    assert sha(BASE)==EXPECTED
    rig=Rig.carregar(ART/'rig.json',PAL)
    native=rig.renderizar(TEMPLATE.nova(),{}).a
    assert np.array_equal(PAL.para_rgba(native),np.array(Image.open(BASE)))
    data=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    for name,p in data['partes'].items():
        assert sha(ART/p['arquivo'])==p['sha256']
        assert all(isinstance(v,int) for v in p['pivo'])
    rows=json.loads((ART/'poses.json').read_text(encoding='utf-8'))['run']
    c=json.loads((ART/'contrato_ciclos.json').read_text(encoding='utf-8'))
    ref=next(a for a in json.loads((ROOT/c['referencia']).read_text(encoding='utf-8'))['animacoes'] if a['id']=='run')
    assert c['referencia_sha256']==sha(ROOT/c['referencia'])
    assert c['somente_run'] and c['sem_walk'] and c['caminhada_usa']=='run'
    assert len(c['animacoes'])==1 and len(rows)==8 and len(c['animacoes'][0]['quadros'])==8
    assert [q['ms'] for q in c['animacoes'][0]['quadros']]==[q['ms'] for q in ref['quadros']]
    checks=[];frames=[];stance=[]
    for q,row in zip(c['animacoes'][0]['quadros'],rows):
        p=ART/q['arquivo'];a=PAL.de_rgba(np.array(Image.open(p)),estrito=True);frames.append(a)
        assert Image.open(p).size==(96,64) and q['sha256']==sha(p) and q['ancora']==[40,56]
        assert set(np.unique(np.array(Image.open(p))[...,3]))=={0,255}
        assert not (a[56:]>=0).any() and np.array_equal(a,render_pose(rig,row))
        n,sizes=componentes(a)
        isolated=int(((a>=0)&~np.any(_vizinhos(a)==a,axis=0)).sum())
        assert n==1,(row['quadro'],'componentes',n,sizes)
        assert isolated==0,(row['quadro'],'cores isoladas',isolated)
        boundary=(a>=0)&~ndi.binary_erosion(a>=0,ndi.generate_binary_structure(2,1))
        assert (a[boundary]==3).all(),(row['quadro'],'contorno descontínuo')
        pose=row['pose_rig'];wp=pose['partes']['mao_espada']
        blade=rig.desenhar_parte(TEMPLATE,'mao_espada',wp['dx'],pose['dy'])
        head=rig.desenhar_parte(TEMPLATE,'cabeca_cabelo',0,pose['dy'])
        assert np.array_equal(a[blade>=0],blade[blade>=0]),'rigid blade/hand altered'
        assert np.array_equal(a[head>=0],head[head>=0]),'approved hair/face altered'
        assert not ((head>=0)&np.isin(blade,[16,17,18])).any()
        for leg in row['pernas']:
            sx,sy=leg['sola'];assert a[sy,sx]>=0,(row['quadro'],leg['perna'],'sole invisible',leg['sola'])
            assert sy==55 if leg['apoio'] else sy<55
        assert row['capa_origem_quadro']==(row['quadro']-1)%8
        checks.append({'quadro':row['quadro'],'componentes':n,'cores_isoladas':isolated,
            'pixels_opacos':int((a>=0).sum()),'replay_rgba_identico':True,
            'cabelo_rosto_e_arma_nativos':True,'contorno_escuro_continuo':True})
    assert np.array_equal(PAL.para_rgba(frames[0]),np.array(Image.open(BASE)))
    assert len({PAL.para_rgba(a).tobytes() for a in frames})==8
    gif=Image.open(OUT/'run_x4.gif');assert gif.n_frames==8
    gif_times=[]
    for k,a in enumerate(frames):
        gif.seek(k);gif_times.append(gif.info['duration'])
        assert np.array_equal(np.array(gif.convert('RGB')),np.array(gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB')))
    assert sum(gif_times)==330
    for side in ('frente','tras'):
        for k in range(8):
            a=next(l for l in rows[k]['pernas'] if l['perna']==side)
            b=next(l for l in rows[(k+1)%8]['pernas'] if l['perna']==side)
            if a['apoio'] and b['apoio']:
                delta=6+b['sola'][0]-a['sola'][0];assert delta==0
                stance.append({'perna':side,'quadros':[k,(k+1)%8],'avanco_corpo_px':6,'deslocamento_sola_mundo_px':delta})
    result={'aprovado':True,'base_sha256':EXPECTED,'f0_zero_diferencas_rgba':True,
      'quadros':checks,'oito_poses_distintas':True,'somente_run':True,'ms_por_quadro':[q['ms'] for q in ref['quadros']],
      'run_px_por_quadro':6,'apoios_por_distancia':stance,'canvas':[96,64],'ancora':[40,56],
      'chao_y':55,'paleta_oficial':True,'alpha':[0,255],'biblioteca':'kit_rig',
      'arte_instalada':False,'pacote_final':False,'gif_resolucao_ms':10,'gif_duracao_ms':330,
      'gif_rgba_visual_confere_oito_quadros':True,'gif_ms':gif_times,
      'f0_png_sha256':sha(ART/'quadros/run/run_f0.png'),'f0_recomposta_sha256':sha(ART/'f0_recomposta_x1.png')}
    save(OUT/'VERIFICACAO_RIG_CICLOS.json',result);print(json.dumps(result,ensure_ascii=False))

def human_speeds():
    """Read the current human profile; no game code is executed or changed."""
    path=ROOT/'scripts/player/player_locomotion.gd'
    source=path.read_text(encoding='utf-8')
    n,d=re.search(r'run_speed := ([\d.]+) / ([\d.]+)',source).groups()
    run=float(n)/float(d)
    ratio=float(re.search(r'walk_speed_ratio := ([\d.]+)',source).group(1))
    accel=float(re.search(r'ground_acceleration := ([\d.]+) \* P40_MOVEMENT_SCALE',source).group(1))*run/120
    zoom=float(re.search(r'zoom = Vector2\(([\d.]+)',(ROOT/'scenes/biomes/cemiterio/sala_cemiterio.tscn').read_text(encoding='utf-8')).group(1))
    assert 'P40_UNITS_PER_METER := 32.0 / 0.9' in source and zoom==0.9
    return {'fonte':path.relative_to(ROOT).as_posix(),'fonte_sha256':sha(path),
        'corrida_unidades_s':run,'caminhada_unidades_s':run*ratio,
        'corrida_m_s':run/(32/.9),'caminhada_m_s':run*ratio/(32/.9),
        'corrida_px_s':run*zoom,'caminhada_px_s':run*ratio*zoom,
        'aceleracao_px_s2':accel*zoom,'zoom_referencia':zoom,'pixel_arte':1}

def preview():
    """20 s visual simulation, outside the game, with honest continuous motion.

    The sprite changes at 6 px events; its position still advances each tick.
    The record explicitly retains the 0..5 pixel in-frame stair-step error.
    """
    speeds=human_speeds();bg=fundo_cemiterio()
    run=[Image.open(ART/f'quadros/run/run_f{k}.png').convert('RGBA') for k in range(8)]
    poses=json.loads((ART/'poses.json').read_text(encoding='utf-8'))['run']
    ffmpeg=ROOT.parent.parent/'carrasco_25d_test/codex/prototipo_escala_36_corrida/ferramentas/ffmpeg.exe'
    assert ffmpeg.exists(),'FFmpeg da ferramenta anterior não encontrado'
    dest=OUT/'PREVIA_caminhada_corrida_20s.mp4'
    args=[str(ffmpeg),'-hide_banner','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24',
          '-video_size','960x820','-framerate','30','-i','pipe:0','-an','-c:v','libx264',
          '-preset','fast','-crf','14','-pix_fmt','yuv420p','-threads','1','-movflags','+faststart',str(dest)]
    proc=subprocess.Popen(args,stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
    trace=[];events=[];saved={};font=textfont(17);small=textfont(14)
    colors={'frente':'#e5b46b','tras':'#8bd6ce'}
    try:
        for frame in range(600):
            half=frame//300;name='caminhada' if half==0 else 'corrida'
            if frame%300==0:x=250.;v=0.;direction=1;distance=0.;last_phase=0;serial=0
            for sub in range(2):
                if x>=780:direction=-1
                elif x<=230:direction=1
                target=direction*speeds[name+'_px_s'];rate=speeds['aceleracao_px_s2']/60
                v+=max(-rate,min(rate,target-v));dx=v/60;x+=dx;distance+=abs(dx)
                facing=1 if v>=0 else -1;phase=int(quadro_por_distancia(distance,6,8))
                if phase!=last_phase:
                    serial+=1
                    events.append({'tempo_s':round((frame*2+sub+1)/60,6),'modo':name,'quadro':phase,
                                   'distancia_px':round(distance,6),'evento_exato_px':math.floor(distance/6)*6,
                                   'posicao_x_px':round(x,6),'direcao':facing})
                    last_phase=phase
            ix,iy=round(x),round(chao_na_tela(x));sprite=run[phase]
            if facing<0:sprite=sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT);anchorx=95-AX
            else:anchorx=AX
            scene=bg.copy();scene.alpha_composite(sprite,(ix-anchorx,iy-AY))
            scene_draw=ImageDraw.Draw(scene)
            # Fixed world marks stay on the ground while the actor moves.
            for mark in range(228,796,6):
                gy=round(chao_na_tela(mark));major=mark%48==0
                scene_draw.line((mark,gy+4,mark,gy+(8 if major else 5)),fill='#8f8258' if major else '#5e5943')
            feet=[]
            for legrow in poses[phase]['pernas']:
                side=legrow['perna'];native_center=0
                footx=ix+facing*(legrow['sola'][0]-AX)
                sole=iy+legrow['sola'][1]-AY
                scene_draw.line((footx-2,sole+3,footx+2,sole+3),fill=colors[side])
                feet.append({'perna':side,'apoio':legrow['apoio'],'sola_x_px':footx,'sola_y_px':sole})
            trace.append({'quadro_video':frame,'tempo_s':round(frame/30,6),'modo':name,'x_px':ix,'x_continuo_px':round(x,6),
                'velocidade_px_s':round(v,6),'distancia_px':distance,'quadro_run':phase,'direcao':facing,
                'resto_entre_quadros_px':distance%6,'pes':feet})
            out=Image.new('RGB',(960,820),(25,25,25));out.paste(scene.convert('RGB'),(0,0))
            draw=ImageDraw.Draw(out);draw.rectangle((0,0,959,84),fill='#20201f')
            draw.text((16,9),'PRÉVIA — RIG NÃO INSTALADO NO JOGO',font=textfont(22),fill='#f4dec0')
            draw.text((16,42),f'{name.upper()}  {speeds[name+"_m_s"]:.3f} m/s | zoom de referência 0,9 | arte ×1',font=font,fill='white')
            draw.text((655,45),f'{frame/30:04.1f} / 20 s',font=font,fill='#cecece')
            # The inset follows the actor, but includes the fixed ground marks.
            close=scene.crop((ix-AX,iy-60,ix-AX+96,iy+4))
            out.paste(close.resize((384,256),Image.Resampling.NEAREST).convert('RGB'),(16,552))
            draw.text((424,554),'DETALHE ×4 / NEAREST',font=font,fill='white')
            draw.text((424,587),f'run f{phase}  |  troca a cada 6 px',font=font,fill='white')
            draw.text((424,619),f'deslocamento acumulado: {distance:.1f} px',font=font,fill='white')
            draw.text((424,651),f'posição inteira: {ix} px  |  avanço contínuo',font=font,fill='white')
            for i,foot in enumerate(feet):
                draw.text((424,683+i*28),f'{foot["perna"]}: {"APOIO" if foot["apoio"] else "PASSAGEM"}  /  sola x={foot["sola_x_px"]:.0f}',font=font,fill=colors[foot['perna']])
            draw.text((424,747),'Marcas fixas no chão; traço claro = posição da sola.',font=small,fill='#bcbcbc')
            draw.text((424,774),'0–10 s caminhada / 10–20 s corrida. Prévia externa.',font=small,fill='#bcbcbc')
            if frame in (90,390):
                out.save(OUT/f'PREVIA_{name}_x1.png');saved[name]=frame
            proc.stdin.write(out.tobytes())
    finally:
        proc.stdin.close()
    stderr=proc.stderr.read().decode('utf-8',errors='replace');assert proc.wait()==0,stderr
    save(OUT/'PREVIA_DESLOCAMENTO.json',{'velocidades':speeds,'quadros_video':600,'fps':30,'duracao_s':20,
        'simulacao_hz':60,'arte_instalada':False,'rotulo':'PRÉVIA — RIG NÃO INSTALADO NO JOGO',
        'fundo_sha256':sha(ROOT/'assets/biomes/cemiterio/fundo_congelado_p40.png'),
        'fundo_remendo':'somente em memória, igual ao kit; arquivo preservado',
        'sem_colisao_simulada':'segue o topo do chão da sala; não é captura de gameplay',
        'arte_scale':1,'inset_scale':4,'px_por_quadro':6,'ms_do_manifesto_alterados':False,
        'ancora_direita':[AX,AY],'ancora_canvas_espelhado':[95-AX,AY],
        'contrato_ciclos_sha256':sha(ART/'contrato_ciclos.json'),'rig_sha256':sha(ART/'rig.json'),
        'limite_quantizacao_intraquadro_px':6,'nota':'A sola compensa 6 px nas trocas de apoio; entre trocas, o PNG fixo avança com o corpo. A prévia mantém esse efeito visível.',
        'video_sha256':sha(dest),'quadros':trace,'eventos_troca':events})
    with (OUT/'PREVIA_DESLOCAMENTO.csv').open('w',encoding='utf-8',newline='') as f:
        fields=['tempo_s','modo','x_px','velocidade_px_s','distancia_px','quadro_run','direcao','resto_entre_quadros_px']
        writer=csv.DictWriter(f,fieldnames=fields,lineterminator='\n');writer.writeheader()
        for row in trace:writer.writerow({k:row[k] for k in fields})
    assert len(trace)==600 and {r['modo'] for r in trace}=={'caminhada','corrida'}
    assert all(0<=r['resto_entre_quadros_px']<6 and isinstance(r['x_px'],int) for r in trace)
    print(json.dumps({'previa':str(dest.relative_to(ROOT)),'segundos':20,'velocidades_m_s':{n:speeds[n+'_m_s'] for n in ('caminhada','corrida')}}))

def verify_preview():
    p=json.loads((OUT/'PREVIA_DESLOCAMENTO.json').read_text(encoding='utf-8'))
    video=OUT/'PREVIA_caminhada_corrida_20s.mp4'
    assert p['video_sha256']==sha(video)
    assert p['contrato_ciclos_sha256']==sha(ART/'contrato_ciclos.json') and p['rig_sha256']==sha(ART/'rig.json')
    assert p['velocidades']==human_speeds() and p['duracao_s']==20 and p['fps']==30
    assert not p['arte_instalada'] and p['px_por_quadro']==6 and p['arte_scale']==1
    rows=p['quadros'];assert len(rows)==600
    for r in rows:
        assert r['quadro_run']==quadro_por_distancia(r['distancia_px'],6,8)
        assert isinstance(r['x_px'],int) and 0<=r['resto_entre_quadros_px']<6
    amplitudes=[]
    for side in ('frente','tras'):
        group=[];key=None
        for r in rows:
            foot=next(f for f in r['pes'] if f['perna']==side);nextkey=(r['modo'],r['direcao'])
            if not foot['apoio'] or (key is not None and key!=nextkey):
                if group:amplitudes.append(max(group)-min(group));group=[]
            if foot['apoio']:group.append(foot['sola_x_px']);key=nextkey
        if group:amplitudes.append(max(group)-min(group))
    assert max(amplitudes)<=6,'Accumulated support drift beyond one 6 px frame'
    ffmpeg=ROOT.parent.parent/'carrasco_25d_test/codex/prototipo_escala_36_corrida/ferramentas/ffmpeg.exe'
    decoded=subprocess.run([str(ffmpeg),'-hide_banner','-i',str(video),'-map','0:v:0','-f','null','-'],capture_output=True,text=True,encoding='utf-8',errors='replace')
    assert decoded.returncode==0,decoded.stderr
    nframes=int(re.findall(r'frame=\s*(\d+)',decoded.stderr)[-1]);assert nframes==600
    assert 'Duration: 00:00:20.00' in decoded.stderr and '960x820' in decoded.stderr
    result={'aprovado':True,'frames_decodificados':nframes,'duracao_s':20,'fps':30,'dimensoes':[960,820],
        'arte_instalada':False,'selecao_distancia_conferida_em_600_quadros':True,
        'max_oscilacao_sola_durante_apoio_px':max(amplitudes),'sem_deriva_acumulada_alem_de_um_quadro':True,
        'nota':'PNG fixo acompanha o corpo entre eventos de 6 px; a oscilação discreta permanece visível na prévia.',
        'video_sha256':sha(video),'contrato_ciclos_sha256':sha(ART/'contrato_ciclos.json')}
    save(OUT/'VERIFICACAO_PREVIA.json',result);print(json.dumps(result,ensure_ascii=False))

def main():
    p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');p.add_argument('--preview',action='store_true');p.add_argument('--verify-preview',action='store_true');p.add_argument('--reproduce',action='store_true');args=p.parse_args()
    ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    if args.verify:verify();return
    if args.verify_preview:verify();verify_preview();return
    if args.preview:verify();preview();verify_preview();return
    if args.reproduce:
        before={p:sha(p) for p in ART.rglob('*') if p.is_file()}
        for p in OUT.iterdir():
            if p.is_file() and (p.suffix in ('.png','.gif') and not p.name.startswith(('PREVIA','base_')) or p.name in ('RECONSTRUCAO_F0.json','VERIFICACAO_RIG_CICLOS.json')):before[p]=sha(p)
        rig,master=split();frames,rows,c=make_frames(rig);evidence(master,frames,rows,c);verify()
        changed=[p.relative_to(ROOT).as_posix() for p,h in before.items() if sha(p)!=h]
        save(OUT/'REPRODUCAO.json',{'aprovado':not changed,'arquivos_byte_a_byte':len(before),
            'diferencas':changed,'base_sha256':sha(BASE),'kit_modificado':False,
            'video_verificado_separadamente':'VERIFICACAO_PREVIA.json'})
        assert not changed,changed
        print({'reproducao_byte_a_byte':len(before),'diferencas':0});return
    rig,master=split();frames,rows,c=make_frames(rig);evidence(master,frames,rows,c);verify()

if __name__=='__main__':main()
