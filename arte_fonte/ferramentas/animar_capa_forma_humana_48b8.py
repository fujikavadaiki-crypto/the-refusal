"""4.8b8: cape-only material variants on the approved 4.8b7 run.

Read-only kit rig composes all original pieces. A locked foreground retains
every visible non-cloth pixel; removing old cloth reveals the original rig
underlay, with no repainting of any other part. Columns of shaded cloth bend
with a travelling wave, rather than a rigid shift/rotation of the whole cape.
"""
from pathlib import Path
import argparse, collections, copy, csv, hashlib, json, math, re, shutil, subprocess, sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'arte_fonte/kit_rig'),str(ROOT/'.godot/forma_humana_48b6/deps')]
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from scipy import ndimage as ndi
from kitrig import Paleta,Rig,Parte,Tela,quadro_por_distancia
from kitrig.desenho import _vizinhos,componentes
from kitrig.previa import fundo_cemiterio,chao_na_tela

SOURCE=ROOT/'arte_fonte/forma_humana_v1/rig_corrida_48b7'
ART=SOURCE.parent/'rig_corrida_48b8_capa'
OUT=ROOT/'codex/evidencias_forma_humana_48b8'
BASE=SOURCE.parent/'pose_corrida_48b6/run_f0_x1.png'
EXPECTED='28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852'
REFERENCE=ROOT/'codex/diretor/referencias/skul/folhas/preview 6.webp'
REFERENCES=[REFERENCE,REFERENCE.parent/'148019.png',REFERENCE.parent/'148045.png']
PAL=Paleta.carregar(ROOT/'arte_fonte/paleta/paleta_bosque_v1.json')
AX,AY=40,56
TEMPLATE=Tela(96,64,AX,AY)
CLOTH_COLORS=[0,1,2,3,14]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def image(a):return Image.fromarray(PAL.para_rgba(a))
def idx(p):return PAL.de_rgba(np.array(Image.open(p).convert('RGBA')),estrito=True)
def textfont(n=12):return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def references():return [{'arquivo':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in REFERENCES]
def gray(a):
    b=Image.new('RGBA',(96,64),(96,96,96,255));b.alpha_composite(image(a));return b

def layer(rig,row,name,variante=None,only_brown=False):
    p=row['pose_rig'];q=p['partes'].get(name,{})
    gx,gy=(0,0) if name in p.get('fixas',rig.fixas) else (p.get('dx',0),p.get('dy',0))
    a=rig.desenhar_parte(TEMPLATE,name,gx+q.get('dx',0),gy+q.get('dy',0),
        ang=q.get('ang',0),variante=variante or q.get('variante'))
    if only_brown:a[np.isin(a,CLOTH_COLORS)]=-1
    return a

def render_original(rig,row,remove_cloth=False):
    p=row['pose_rig'];t=TEMPLATE.nova()
    t.camada(layer(rig,row,'perna_tras'));t.camada(layer(rig,row,'braco_distante'))
    c=layer(rig,row,'capa',only_brown=remove_cloth);t.camada(c)
    body=layer(rig,row,'tronco');t.camada(body)
    n=layer(rig,row,'perna_frente');n[(c>=0)|(body>=0)]=-1;t.camada(n)
    for name in ['capuz','cabeca_cabelo','braco_proximo','mao_espada']:t.camada(layer(rig,row,name))
    for x,y,color in row['ajustes_pixels']:t.a[y,x]=color
    return t.a

def cloth_native(rig):
    a=rig.partes['capa'].idx.copy();a[~np.isin(a,CLOTH_COLORS)]=-1
    # Three grey hem pixels and their dark rim were originally included in
    # the far-leg cutout. They are cloth, never a trouser/boot repaint. The
    # source part files remain byte-identical and this classification is saved.
    source0=idx(SOURCE/'quadros/run/run_f0.png')
    frag=np.zeros(a.shape,bool);frag[40,17:24]=True;frag[41,20:24]=True
    frag&=np.isin(source0,CLOTH_COLORS)
    a[frag]=source0[frag]
    return a,frag

def old_semantic(rig,row,frag):
    old=idx(SOURCE/f'quadros/run/run_f{row["quadro"]}.png')
    c=layer(rig,row,'capa');mask=np.isin(c,CLOTH_COLORS)
    late=np.zeros(mask.shape,bool)
    for name in ['tronco','capuz','cabeca_cabelo','braco_proximo','mao_espada']:late|=layer(rig,row,name)>=0
    mask&=~late
    if any(l['fase']==4 for l in row['pernas']):mask|=frag&np.isin(old,CLOTH_COLORS)&~late
    mask&=old>=0
    return mask,late

def clean_cloth(a):
    # Preserve the broad cloth volume; only dark rim and tiny colour facets
    # are cleaned. No global frame cleanup can touch other body pixels.
    m=a>=0;edge=m&~ndi.binary_erosion(m,ndi.generate_binary_structure(2,1));a[edge]=3
    for _ in range(12):
        isolated=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
        if not isolated.any():break
        for y,x in zip(*np.where(isolated)):
            vals=[int(a[y+dy,x+dx]) for dy in (-1,0,1) for dx in (-1,0,1)
                  if (dx or dy) and 0<=y+dy<64 and 0<=x+dx<96 and a[y+dy,x+dx]>=0]
            if vals:a[y,x]=collections.Counter(vals).most_common(1)[0][0]
    return a

def variant(native,k,rows):
    if k==0:return native.copy(),[0]*96
    bob=rows[k]['oscilacao_corpo_y'];prev=rows[(k-1)%8]['oscilacao_corpo_y']
    out=TEMPLATE.vazia();offsets=[]
    for x in range(96):
        t=max(0,min(1,(24-x)/16))
        # Root (x>=24) stays on the shoulder. The wave is delayed one frame
        # and its crest travels from middle toward the hem. Baseline phase
        # subtraction gives exactly zero deformation at approved f0.
        wave=2.5*t*(math.sin(2*math.pi*(k-1)/8-1.5*math.pi*t)-math.sin(-2*math.pi/8-1.5*math.pi*t))
        delta=round(t*(prev-bob)+wave);offsets.append(delta)
        for y in np.where(native[:,x]>=0)[0]:
            ny=int(y)+delta
            if 0<=ny<64:out[ny,x]=native[y,x]
    out=clean_cloth(out);out[:,24:]=native[:,24:]
    return out,offsets

def render_pose(rig,row,source_rig,source_rows,frag):
    k=row['quadro'];before=idx(SOURCE/f'quadros/run/run_f{k}.png');original=source_rows[k]
    oldmask,late=old_semantic(source_rig,original,frag)
    under=render_original(source_rig,original,remove_cloth=True)
    # Remove semantically labelled grey hem remnants from the underlay.
    if any(l['fase']==4 for l in original['pernas']):under[frag&np.isin(under,CLOTH_COLORS)]=-1
    bg=before.copy();bg[oldmask]=under[oldmask]
    cloth=layer(rig,row,'capa',variante=row['pose_rig']['partes']['capa']['variante'])
    protected=(before>=0)&~oldmask
    cloth[protected|late]=-1
    raw=cloth.copy();bg[cloth>=0]=cloth[cloth>=0]
    # Only new visible cloth may be cleaned at a compositing seam. Frozen
    # foreground RGBA remains untouched, including original f3/boots.
    if k!=0:
        for _ in range(12):
            isolated=(bg>=0)&~np.any(_vizinhos(bg)==bg,axis=0)
            edits=isolated&(cloth>=0)
            if not edits.any():break
            for y,x in zip(*np.where(edits)):
                vals=[int(bg[y+dy,x+dx]) for dy in (-1,0,1) for dx in (-1,0,1)
                      if (dx or dy) and 0<=y+dy<64 and 0<=x+dx<96 and bg[y+dy,x+dx]>=0]
                if vals:bg[y,x]=collections.Counter(vals).most_common(1)[0][0]
    union=oldmask|(raw>=0)
    return bg,oldmask,raw,union,protected,under

def generate():
    assert sha(BASE)==EXPECTED
    source_rig=Rig.carregar(SOURCE/'rig.json',PAL)
    rows0=json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['run']
    for row in rows0:assert np.array_equal(render_original(source_rig,row),idx(SOURCE/f'quadros/run/run_f{row["quadro"]}.png'))
    rig=Rig.carregar(SOURCE/'rig.json',PAL);native,frag=cloth_native(rig)
    rows=copy.deepcopy(rows0);mat=[]
    for k,row in enumerate(rows):
        a,offsets=variant(native,k,rows0)
        name=f'capa_onda_f{k}';rig.partes[name]=Parte(name,a,rig.partes['capa'].pivo,(0,0),'capa')
        row['pose_rig']['partes']['capa']={'variante':name,'dx':0,'dy':0,'ang':0}
        row['capa_variante']=name;row['capa_fase_material']=(k-1)%8
        row['capa_colunas_dy']=offsets;row['compositor']='primeiro preserva todas as peças da 4.8b7; depois substitui somente tecido visível'
        mat.append({'quadro':k,'fase_material':(k-1)%8,'colunas_dy':offsets,
                    'raiz_x_min':24,'raiz_deslocamento_local':[0,0],
                    'pivo':list(rig.partes['capa'].pivo),'amplitude_material_px':2.5})
    data=rig.salvar(ART,fonte=BASE.relative_to(ROOT).as_posix(),extra={
        'base_sha256':EXPECTED,'base_rig':SOURCE.relative_to(ROOT).as_posix(),
        'base_rig_sha256':sha(SOURCE/'rig.json'),'biblioteca':'arte_fonte/kit_rig/kitrig',
        'uso':'revisão somente da capa de run; nenhuma instalação',
        'capa':'variantes materiais de onda, raiz no ombro, barra atrasada um quadro',
        'referencias_estudadas':references(),
        'pecas_anteriores_byte_a_byte':True,'compositor':'render_pose desta ferramenta; preservação de foreground e remoção semântica do tecido antigo'})
    for p in data['partes'].values():
        if p.get('variante'):p['origem_mestre']=[0,0]
    save(ART/'rig.json',data);rig=Rig.carregar(ART/'rig.json',PAL)
    frames=[];checks=[]
    for k,row in enumerate(rows):
        a,old,cape,union,protected,under=render_pose(rig,row,source_rig,rows0,frag)
        before=idx(SOURCE/f'quadros/run/run_f{k}.png');diff=np.any(PAL.para_rgba(a)!=PAL.para_rgba(before),axis=2)
        assert not (diff&~union).any(),(k,'change outside cape union')
        assert np.array_equal(a[protected],before[protected]),(k,'other visible piece changed')
        p=ART/f'quadros/run/run_f{k}.png';p.parent.mkdir(parents=True,exist_ok=True);image(a).save(p);frames.append(a)
        for name,mask in [('capa_antiga',old),('capa_nova',cape>=0),('uniao',union),('diferencas',diff),('outras_pecas',protected)]:
            p=OUT/'mascaras'/f'{name}_f{k}.png';p.parent.mkdir(exist_ok=True);Image.fromarray((mask*255).astype('uint8')).save(p)
        removed=old&(cape<0)
        checks.append({'quadro':k,'pixels_diferentes':int(diff.sum()),'fora_uniao':int((diff&~union).sum()),
            'outras_pecas_visiveis_modificadas':int((diff&protected).sum()),
            'tecido_retirado_revela_fundo':int((removed&(under<0)).sum()),
            'tecido_retirado_revela_peca_original':int((removed&(under>=0)).sum()),
            'tecido_novo_sobre_fundo':int(((cape>=0)&(before<0)).sum()),
            'raiz_no_ombro':True,'fase_material':row['capa_fase_material']})
    assert np.array_equal(PAL.para_rgba(frames[0]),np.array(Image.open(BASE))), 'f0 must remain exact'
    image(frames[0]).save(ART/'f0_recomposta_x1.png')
    contract=json.loads((SOURCE/'contrato_ciclos.json').read_text(encoding='utf-8'))
    contract['revisao']='4.8b8 — somente capa';contract['base_48b7_commit']='c9adc51'
    for k,q in enumerate(contract['animacoes'][0]['quadros']):q['sha256']=sha(ART/q['arquivo'])
    save(ART/'contrato_ciclos.json',contract);save(ART/'poses.json',{'run':rows})
    shutil.copyfile(SOURCE/'SOLAS_ARTICULACOES.json',ART/'SOLAS_ARTICULACOES.json')
    save(ART/'CAPA_MATERIAL.json',{'referencias':references(),
        'estudo':'preview 6.webp Walk; 148019.png Walk e dobras nos golpes; 148045.png Walk/Dash: fixação junto ao corpo, curvatura do meio e retorno da ponta; não copiar sprites, ritmos ou massa do manto com foice',
        'aplicacao':'dobra e sombreamento da capa original percorrem colunas com defasagem; nenhuma imagem da referência usada como peça',
        'quadros':mat,'fragmentos_tecido_no_recorte_antigo_da_perna':np.argwhere(frag).tolist(),
        'arquivos_da_perna_intactos':True})
    save(OUT/'PRESERVACAO_PEÇAS.json',{'somente_capa':True,'f0_sha256':sha(ART/'quadros/run/run_f0.png'),
        'f0_recomposta_sha256':sha(ART/'f0_recomposta_x1.png'),'quadros':checks,
        'solas_sha256':sha(ART/'SOLAS_ARTICULACOES.json'),'solas_base_sha256':sha(SOURCE/'SOLAS_ARTICULACOES.json')})
    evidence(frames,contract,source_rig,rows0,frag);verify()

def gif(path,imgs,times):
    ends=[int(round(t/10))*10 for t in np.cumsum(times)];d=[ends[0]]+[b-a for a,b in zip(ends,ends[1:])]
    imgs[0].save(path,save_all=True,append_images=imgs[1:],duration=d,loop=0,disposal=2,optimize=False)

def evidence(frames,contract,source_rig,rows0,frag):
    before=[idx(SOURCE/f'quadros/run/run_f{k}.png') for k in range(8)]
    times=[q['ms'] for q in contract['animacoes'][0]['quadros']]
    for label,seq in [('antes',before),('depois',frames)]:
        whole=[gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB') for a in seq]
        detail=[gray(a).crop((4,22,30,45)).resize((104,92),Image.Resampling.NEAREST).convert('RGB') for a in seq]
        gif(OUT/f'run_{label}_x4.gif',whole,times);gif(OUT/f'capa_{label}_detalhe_x4.gif',detail,times)
        sheet=Image.new('RGB',(768,80),(96,96,96));d=ImageDraw.Draw(sheet)
        for k,a in enumerate(seq):sheet.paste(gray(a).convert('RGB'),(k*96,16));d.text((k*96+4,2),f'f{k}',font=textfont(10),fill='white')
        sheet.save(OUT/f'run_{label}_quadros_x1.png');sheet.resize((3072,320),Image.Resampling.NEAREST).save(OUT/f'run_{label}_quadros_x4.png')
    for detail in (False,True):
        pair=[];w,h=(104,92) if detail else (384,256)
        for k in range(8):
            card=Image.new('RGB',(w*2,h+28),(96,96,96));d=ImageDraw.Draw(card)
            for i,seq in enumerate((before,frames)):
                a=gray(seq[k])
                if detail:a=a.crop((4,22,30,45))
                a=a.resize((w,h),Image.Resampling.NEAREST).convert('RGB')
                card.paste(a,(i*w,28));d.text((i*w+6,7),'ANTES' if i==0 else 'DEPOIS',font=textfont(12 if detail else 17),fill='white')
            pair.append(card)
        gif(OUT/('CAPA_ANTES_DEPOIS_detalhe_x4.gif' if detail else 'RUN_ANTES_DEPOIS_x4.gif'),pair,times)
    comp=Image.new('RGB',(768,296),(96,96,96));d=ImageDraw.Draw(comp)
    for i,(label,a) in enumerate([('f0 APROVADA',before[0]),('f0 RECOMPOSTA — ZERO DIFERENÇAS RGBA',frames[0])]):
        comp.paste(gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB'),(i*384,32));d.text((i*384+10,10),label,font=textfont(14),fill='white')
    comp.save(OUT/'F0_RECOMPOSTA_x4.png')
    sheet=Image.new('RGB',(8*156,180),(96,96,96));d=ImageDraw.Draw(sheet)
    for k,a in enumerate(frames):
        sheet.paste(gray(a).crop((4,22,30,45)).resize((156,138),Image.Resampling.NEAREST).convert('RGB'),(k*156,28))
        d.text((k*156+8,8),f'f{k}: pano',font=textfont(12),fill='white')
    sheet.save(OUT/'CAPA_FORMATOS_x6.png')
    maskview=Image.new('RGB',(768,3*110),(24,24,24));d=ImageDraw.Draw(maskview)
    for k in range(8):
        old=np.array(Image.open(OUT/'mascaras'/f'capa_antiga_f{k}.png'))>0
        new=np.array(Image.open(OUT/'mascaras'/f'capa_nova_f{k}.png'))>0
        diff=np.array(Image.open(OUT/'mascaras'/f'diferencas_f{k}.png'))>0
        pix=np.zeros((64,96,3),np.uint8);pix[old]=[76,123,178];pix[new]=[94,173,112];pix[diff]=[233,182,78]
        x,y=(k%4)*192,(k//4)*110;maskview.paste(Image.fromarray(pix).resize((192,128),Image.Resampling.NEAREST).crop((0,16,192,112)),(x,y+14));d.text((x+4,y+2),f'f{k}',font=textfont(10),fill='white')
    d.text((8,240),'Azul: capa antiga / verde: nova / dourado: diferenças dentro da união',font=textfont(14),fill='white')
    d.text((8,270),'Todas as outras peças visíveis mantêm seus pixels RGBA.',font=textfont(14),fill='white')
    maskview.save(OUT/'MASCARAS_DIFERENCAS.png')
    close=Image.new('RGB',(4*192,164),(96,96,96));d=ImageDraw.Draw(close)
    for i,k in enumerate((6,7,0,1)):
        close.paste(gray(frames[k]).resize((192,128),Image.Resampling.NEAREST).convert('RGB'),(i*192,28))
        d.text((i*192+8,8),f'f{k} / fechamento',font=textfont(12),fill='white')
    close.save(OUT/'FECHAMENTO_f6_f7_f0_f1_x2.png')
    # Read-only crops for study, kept with evidence, never used as rig parts.
    crops=[(REFERENCE,(0,72,497,120),'ESTUDO_WALK_REFERENCIA_x4.png'),
           (REFERENCES[1],(0,84,620,145),'ESTUDO_148019_WALK_x3.png'),
           (REFERENCES[1],(0,517,584,604),'ESTUDO_148019_DOBRAS_x3.png'),
           (REFERENCES[2],(0,97,552,194),'ESTUDO_148045_WALK_x3.png'),
           (REFERENCES[2],(0,194,646,288),'ESTUDO_148045_DASH_x3.png')]
    for ref,box,name in crops:
        crop=Image.open(ref).convert('RGBA').crop(box);scale=4 if ref==REFERENCE else 3
        crop.resize((crop.width*scale,crop.height*scale),Image.Resampling.NEAREST).save(OUT/name)

def verify():
    assert sha(BASE)==EXPECTED
    source_rig=Rig.carregar(SOURCE/'rig.json',PAL);rig=Rig.carregar(ART/'rig.json',PAL)
    rows0=json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['run']
    rows=json.loads((ART/'poses.json').read_text(encoding='utf-8'))['run'];_,frag=cloth_native(source_rig)
    source_data=json.loads((SOURCE/'rig.json').read_text(encoding='utf-8'));data=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    preserved=[]
    for name,p in source_data['partes'].items():
        assert sha(ART/data['partes'][name]['arquivo'])==sha(SOURCE/p['arquivo'])==p['sha256']
        preserved.append(name)
    c=json.loads((ART/'contrato_ciclos.json').read_text(encoding='utf-8'))
    basec=json.loads((SOURCE/'contrato_ciclos.json').read_text(encoding='utf-8'))
    assert len(c['animacoes'])==1 and c['animacoes'][0]['id']=='run' and len(rows)==8
    assert [q['ms'] for q in c['animacoes'][0]['quadros']]==[41.67]*8
    assert c['animacoes'][0]['px_por_quadro']==6 and c['ancora']==[40,56] and c['canvas']==[96,64]
    assert sha(ART/'SOLAS_ARTICULACOES.json')==sha(SOURCE/'SOLAS_ARTICULACOES.json')
    checks=[];mats=[];used=set();alphainfo=[]
    for k,row in enumerate(rows):
        assert row['pernas']==rows0[k]['pernas'] and row['ajustes_pixels']==rows0[k]['ajustes_pixels']
        p=copy.deepcopy(row['pose_rig']);p['partes'].pop('capa')
        b=copy.deepcopy(rows0[k]['pose_rig']);b['partes'].pop('capa');assert p==b
        a,old,new,union,protected,under=render_pose(rig,row,source_rig,rows0,frag)
        saved=idx(ART/f'quadros/run/run_f{k}.png');before=idx(SOURCE/f'quadros/run/run_f{k}.png')
        assert np.array_equal(a,saved) and sha(ART/c['animacoes'][0]['quadros'][k]['arquivo'])==c['animacoes'][0]['quadros'][k]['sha256']
        assert not (a[56:]>=0).any();assert np.array_equal(a[protected],before[protected])
        assert np.array_equal(a[44:],before[44:]),'feet/lower legs changed'
        n,sizes=componentes(a);assert n==1,(k,'components',n,sizes)
        iso=int(((a>=0)&~np.any(_vizinhos(a)==a,axis=0)).sum());assert iso==0,(k,'isolated colour',iso)
        diff=np.any(PAL.para_rgba(a)!=PAL.para_rgba(before),axis=2);assert not (diff&~union).any()
        rgba=PAL.para_rgba(a);unique=np.unique(rgba.reshape(-1,4),axis=0)
        used.update(tuple(map(int,c)) for c in unique if c[3]);assert set(map(int,unique[:,3]))=={0,255}
        alphainfo.append({'quadro':k,'canvas':[96,64],'alpha':[0,255],'bbox':list(image(a).getbbox()),
                         'cores_opacas':int((unique[:,3]>0).sum())})
        for leg in row['pernas']:
            x,y=leg['sola'];assert a[y,x]==before[y,x]
        native=rig.partes[row['capa_variante']].idx;mats.append(native)
        assert np.array_equal(native[:,24:],rig.partes['capa_onda_f0'].idx[:,24:]),'shoulder root deformed'
        checks.append({'quadro':k,'componentes':n,'cores_isoladas':iso,'fora_uniao':0,
                       'outras_pecas_visiveis_alteradas':0,'pixels_diferentes':int(diff.sum()),'raiz_no_ombro':True})
    assert sha(ART/'quadros/run/run_f0.png')==sha(ART/'f0_recomposta_x1.png')==EXPECTED
    assert len({a.tobytes() for a in mats})==8,'cloth variants must all differ'
    # A material change cannot be explained by translating the whole piece.
    distinct=[]
    for k in range(1,8):
        scores=[]
        for dy in range(-6,7):
            moved=np.full_like(mats[0],-1)
            if dy>=0:moved[dy:]=mats[0][:64-dy]
            else:moved[:dy]=mats[0][-dy:]
            scores.append(int((moved!=mats[k]).sum()))
        assert min(scores)>0;distinct.append({'quadro':k,'min_diferenca_translacao_rigida':min(scores)})
    offsets=[r['capa_colunas_dy'] for r in rows]
    close_max=max(abs(offsets[7][x]-offsets[0][x]) for x in range(96))
    assert close_max<=2,'Abrupt f7 to f0 cloth closure'
    assert all(r['capa_colunas_dy'][23]==0 for r in rows),'Shoulder pivot moved locally'
    contour_distinct=len({(a>=0).tobytes() for a in mats});assert contour_distinct==8
    gifcheck=[]
    for name in ('run_antes_x4.gif','run_depois_x4.gif','capa_antes_detalhe_x4.gif','capa_depois_detalhe_x4.gif',
                 'CAPA_ANTES_DEPOIS_detalhe_x4.gif','RUN_ANTES_DEPOIS_x4.gif'):
        g=Image.open(OUT/name);assert g.n_frames==8
        durations=[]
        for i in range(8):
            g.seek(i);durations.append(g.info['duration'])
            if name.startswith(('run_','capa_')):
                root=SOURCE if '_antes_' in name else ART
                a=gray(idx(root/f'quadros/run/run_f{i}.png'))
                if name.startswith('capa_'):a=a.crop((4,22,30,45))
                a=a.resize(g.size,Image.Resampling.NEAREST).convert('RGB')
                assert np.array_equal(np.array(g.convert('RGB')),np.array(a)),'GIF pixels differ from source'
        assert sum(durations)==330 and durations==[40,40,50,40,40,40,40,40]
        gifcheck.append({'arquivo':name,'quadros':8,'duracoes_ms':durations,'nota':'GIF quantiza a 10 ms; contrato PNG/manifesto continua em 41,67 ms.'})
    result={'aprovado':True,'somente_capa':True,'base_sha256':EXPECTED,'f0_zero_diferencas_rgba':True,
            'partes_base_byte_identicas':preserved,'oito_variantes_distintas':True,'deformacao_material':distinct,
            'quadros':checks,'canvas':[96,64],'ancora':[40,56],'alpha':[0,255],'paleta_oficial':True,
            'atraso_parte_solta_quadros':1,'sem_instalacao':True,'referencias_estudadas':references(),
            'contornos_distintos':contour_distinct,'fechamento_f7_f0_max_deslocamento_local_px':close_max,'gifs':gifcheck}
    save(OUT/'VERIFICACAO_CAPA.json',result);print(json.dumps({k:v for k,v in result.items() if k not in ('quadros','partes_base_byte_identicas','deformacao_material')},ensure_ascii=False))
    save(OUT/'ESCALA_PALETA_ALPHA.json',{'cores_opacas_no_ciclo':len(used),'rgba_cores':sorted(list(c) for c in used),'quadros':alphainfo})

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
            draw.text((16,9),'PRÉVIA — CAPA 4.8b8 / ARTE NÃO INSTALADA',font=textfont(22),fill='#f4dec0')
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
        'simulacao_hz':60,'arte_instalada':False,'rotulo':'PRÉVIA — CAPA 4.8b8 / ARTE NÃO INSTALADA',
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
        before.update({p:sha(p) for p in OUT.iterdir() if p.is_file() and p.suffix in ('.png','.gif') and not p.name.startswith(('PREVIA','ESTUDO','CAPA_BASE'))})
        before.update({p:sha(p) for p in (OUT/'mascaras').rglob('*.png')})
        generate();changed=[p.relative_to(ROOT).as_posix() for p,h in before.items() if sha(p)!=h]
        save(OUT/'REPRODUCAO.json',{'aprovado':not changed,'arquivos_byte_a_byte':len(before),'diferencas':changed});assert not changed;return
    generate()

if __name__=='__main__':main()
