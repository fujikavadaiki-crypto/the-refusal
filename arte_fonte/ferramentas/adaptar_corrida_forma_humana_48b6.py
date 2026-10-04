"""4.8b6: one proportional static f0; no rig, cycle or installed asset.

Use --reduce once to repeat the existing project's reduction. Edits are indexed
pixel operations, and the head is translated directly from the approved master.
"""
from pathlib import Path
import argparse, collections, hashlib, importlib.util, json, sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'arte_fonte/forma_humana_v1'
ART = BASE/'pose_corrida_48b6'
OUT = ROOT/'codex/evidencias_forma_humana_48b6'
SOURCE = BASE/'referencia_corrida_48b5/referencia_corrida_pernas_espada.png'
MASTER = BASE/'forma_humana_mestre_x1.png'
EXPECTED = '204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988'
PALFILE = ROOT/'arte_fonte/paleta/paleta_bosque_v1.json'
PAL = np.array([c['rgb'] for c in json.loads(PALFILE.read_text(encoding='utf-8'))['cores']], np.uint8)
AX, AY = 40, 56
# Native pixel variants follow the approved reference, rather than old joints.
# # contour, s shadow, b dark leather, m middle, l light, c cuff.
LEG_COLORS={'#':3,'s':7,'b':8,'m':11,'l':13,'c':10}
FRONT_ROWS=[(40,32,'##bmll#'),(41,32,'#sbmll#'),(42,33,'#sbmll#'),
    (43,33,'#sbmll#'),(44,34,'#sbmll#'),(45,34,'#sbmll#'),(46,34,'#sbmll#'),
    (47,34,'#sbmll#'),(48,35,'#sbmll#'),(49,35,'#sbmll#'),(50,36,'#ccmml#'),
    (51,36,'#bcmlm#'),(52,36,'#bbmlm#'),(53,36,'#bbmll##'),
    (54,36,'#sbbmlll#'),(55,36,'#########')]

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,o):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def indices(im):
    a=np.array(im.convert('RGBA')); ix=np.full(a.shape[:2],-1,np.int16)
    for i,c in enumerate(PAL): ix[(a[...,3]>0)&np.all(a[...,:3]==c,axis=2)]=i
    assert ((a[...,3]==0)|(ix>=0)).all()
    return ix
def rgba(ix):
    a=np.zeros((*ix.shape,4),np.uint8); m=ix>=0
    a[m,:3]=PAL[ix[m]]; a[m,3]=255
    return Image.fromarray(a)
def neighbors(ix):
    p=np.pad(ix,1,constant_values=-2)
    return np.stack([p[1+dy:1+dy+ix.shape[0],1+dx:1+dx+ix.shape[1]] for dy in (-1,0,1) for dx in (-1,0,1) if dx or dy])
def components(m):
    todo=set(map(tuple,np.argwhere(m))); result=[]
    while todo:
        p=todo.pop(); q=[p]; group=[p]
        while q:
            y,x=q.pop()
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    n=(y+dy,x+dx)
                    if n in todo:todo.remove(n);q.append(n);group.append(n)
        result.append(group)
    return sorted(result,key=len,reverse=True)
def boundary(m):
    p=np.pad(m,1)
    return m & ~(p[:-2,1:-1]&p[2:,1:-1]&p[1:-1,:-2]&p[1:-1,2:])
def font(s=14): return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',s)
def gray(im):
    b=Image.new('RGBA',im.size,(96,96,96,255));b.alpha_composite(im);return b.convert('RGB')

def reduce():
    sys.path.insert(0,str(ROOT/'.godot/forma_humana_48b6/deps'))
    sp=importlib.util.spec_from_file_location('project_reducer',ROOT/'arte_fonte/ferramentas/reduzir_referencia.py')
    tool=importlib.util.module_from_spec(sp);sp.loader.exec_module(tool)
    cut=tool.alfa_ou_fundo(Image.open(SOURCE),tol=30)
    Image.fromarray(cut).save(ART/'fonte_sem_fundo.png')
    auto=tool.reduzir(cut,48,PAL,contorno=True)
    Image.fromarray(auto).save(ART/'reducao_automatica_recorte_x1.png')
    y,x=np.where(cut[...,3]>0)
    save(ART/'REDUCAO.json',{'ferramenta':'arte_fonte/ferramentas/reduzir_referencia.py',
        'ferramenta_sha256':sha(ROOT/'arte_fonte/ferramentas/reduzir_referencia.py'),
        'fonte_sha256':sha(SOURCE),'paleta_sha256':sha(PALFILE),'fundo_tolerancia_l1_rgb':30,
        'bbox_fonte':[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)],
        'escala_proporcional':48/(int(y.max())-int(y.min())+1),'altura_alvo':48,
        'recorte_reduzido':[auto.shape[1],auto.shape[0]],'reamostragem_reducao':'BOX premultiplicado (ferramenta do projeto)',
        'previas':'NEAREST','fundo_removido':True})

def generate():
    assert sha(MASTER)==EXPECTED
    raw=indices(Image.open(ART/'reducao_automatica_recorte_x1.png'))
    auto=np.full((64,96),-1,np.int16);auto[8:56,8:8+raw.shape[1]]=raw
    rgba(auto).save(ART/'reducao_automatica_canvas_x1.png')
    ix=auto.copy()
    # Replace all of the generated head, including its white eye, with the
    # master's exact head pixels. The approved old mask contains no completed
    # pixels: every opaque RGBA value is verified against the master below.
    headmask=np.array(Image.open(BASE/'rig_48b/partes/cabeca_cabelo.png').convert('RGBA'))[...,3]>0
    master=indices(Image.open(MASTER))
    target=np.full(ix.shape,-1,np.int16)
    yy,xx=np.where(headmask); target[yy+6,xx+9]=master[yy,xx]
    ix[8:22,:]=-1
    ix[22:27,25:48]=-1
    ix[target>=0]=target[target>=0]
    locked=target>=0
    # The neck belonged to the original collar: place the new collar behind it
    # so that exposed interior head pixels keep their exact approved values.
    ix[24:27,26]=3;ix[27,27]=3
    # Fresh native silhouettes for the reference's open step. The garment
    # remains above the roots; thighs are not compressed into the old rig.
    ix[41:50,14:32]=-1
    ix[40:56,31:58]=-1
    authored=[]
    for label,rows in [('recolhida',[]),('apoio',FRONT_ROWS)]:
        layer=np.full(ix.shape,-1,np.int16)
        colors=LEG_COLORS
        if label=='recolhida':
            # User's last crop is an exact crop of the proportional reduction.
            # Use that open, rounded knee and full cuff construction directly,
            # preserving its alpha silhouette; do not reuse the rejected rig.
            layer[41:50,14:31]=auto[41:50,14:31]
        for y,x,symbols in rows:
            for k,s in enumerate(symbols):layer[y,x+k]=colors[s]
        ix[layer>=0]=layer[layer>=0]
        rgba(layer).save(ART/f'variante_perna_{label}.png')
        authored.append({'parte':label,'paleta':colors,'linhas':rows,
            'origem_regiao_reducao':[14,41,31,50] if label=='recolhida' else None,
            'recorte_enviado_usuario':'REFERENCIA_AJUSTE_USUARIO.png' if label=='recolhida' else None})
    # Correct a straight sword explicitly in native pixels; do not rescale
    # the weapon or retain the reduction's broken width/rounded terminal.
    for x in range(32,53):
        y=39+(x-32)//2
        ix[y:y+4,x]=[3,18,16,3]
    ix[49:53,53]=[3,18,16,3]
    ix[50:53,54]=[3,18,3]
    ix[51:53,55]=[3,3]
    ix[52,56]=3
    # Hand, grip and a small discrete guard remain distinct clusters.
    for x,y,c in [(29,37,35),(30,37,37),(29,38,35),(30,38,37),
                  (31,38,43),(31,39,43),(32,38,56),(32,39,56),
                  (30,39,3),(31,40,3),(32,40,3)]: ix[y,x]=c
    # Remove background-removal/reduction flecks, retaining the full pose.
    for group in components(ix>=0)[1:]:
        for y,x in group:ix[y,x]=-1
    edge=boundary(ix>=0);ix[edge&~locked]=3
    # Regroup isolated colours only. The exact master head is locked, and a
    # neighbouring body pixel may join its group instead of changing its RGBA.
    cleanup=[]; fixed=np.zeros(ix.shape,bool)
    for _ in range(64):
        ns=neighbors(ix);iso=(ix>=0)&~np.any(ns==ix,axis=0)
        if not iso.any():break
        changed=False
        for y,x in np.argwhere(iso):
            n=[(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1) if (dy or dx) and 0<=y+dy<64 and 0<=x+dx<96 and ix[y+dy,x+dx]>=0]
            if locked[y,x] or fixed[y,x]:
                free=[p for p in n if not locked[p] and not edge[p] and not fixed[p]]
                if not free:continue
                py,px=min(free,key=lambda p:abs(int(ix[p])-int(ix[y,x])))
                color=int(ix[y,x]);fixed[py,px]=True
            else:
                py,px=y,x
                color=3 if edge[y,x] else collections.Counter(int(ix[p]) for p in n).most_common(1)[0][0]
            if int(ix[py,px])!=color:
                cleanup.append([int(px),int(py),int(ix[py,px]),color]);ix[py,px]=color;changed=True
        if not changed:break
    rgba(ix).save(ART/'run_f0_x1.png')
    rgba(ix).resize((384,256),Image.Resampling.NEAREST).save(ART/'run_f0_x4.png')
    Image.fromarray((np.any(np.array(rgba(ix))!=np.array(rgba(auto)),axis=2)*255).astype(np.uint8)).save(ART/'mascara_edicao.png')
    rgba(target).save(ART/'cabeca_mestre_transladada.png')
    save(ART/'POSE.json',{'tipo':'uma proposta estática de run f0','canvas':[96,64],
        'ancora':[AX,AY],'chao_y':55,'altura_cabelo_sola':48,'olhando_para':'direita',
        'pontos_novos':{'perna_apoio':{'quadril':[34,40],'joelho':[36,47],'tornozelo':[39,51],'centro_sola':[40,55]},
            'perna_elevada':{'quadril':[28,40],'joelho':[26,45],'tornozelo':[18,44],'centro_sola':[15,49],
                'sola_inclinada':True,'descricao_ponto_sola':'pixel inferior da sola inclinada; não centro de segmento horizontal'}},
        'cabeca':{'fonte':str(MASTER.relative_to(ROOT)).replace('\\','/'),'sha256':EXPECTED,
            'mask':str((BASE/'rig_48b/partes/cabeca_cabelo.png').relative_to(ROOT)).replace('\\','/'),
            'mask_sha256':sha(BASE/'rig_48b/partes/cabeca_cabelo.png'),'translacao':[9,6],'escala':1,'rotacao':0},
        'origem_reducao_canvas':[8,8],'limpeza_cores_isoladas':cleanup,
        'rig_ou_ciclos_atualizados':False,'sombra_embutida':False,
        'trajetoria_anterior_reutilizada':False,'f4_ou_outros_quadros_criados':False})
    save(ART/'DESENHO_PIXELS.json',{'linhas_variantes':authored,'origem_reducao':[8,8],
        'cabeca_translacao':[9,6],'espada':'x32..52; topo y39+(x-32)//2; espessura vertical 4 px; ponta x53..56',
        'contorno':'borda interna de 1 px, cor 3','receita':'arte_fonte/ferramentas/adaptar_corrida_forma_humana_48b6.py'})

def evidence():
    im=Image.open(ART/'run_f0_x1.png').convert('RGBA');auto=Image.open(ART/'reducao_automatica_canvas_x1.png').convert('RGBA')
    for scale in (1,4):gray(im).resize((96*scale,64*scale),Image.Resampling.NEAREST).save(OUT/f'PROPOSTA_f0_x{scale}.png')
    # Real evidence images, displayed proportionally, never passed to the game.
    ref=Image.open(ART/'fonte_sem_fundo.png').convert('RGBA').crop((93,125,1161,1163))
    ref=ref.resize((196,192),Image.Resampling.NEAREST)
    old=Image.open(BASE/'poses_chave_48b4/quadros/run_f0.png').convert('RGBA')
    master=Image.open(MASTER).convert('RGBA')
    tile=384; comp=Image.new('RGB',(tile*5,330),(96,96,96));d=ImageDraw.Draw(comp)
    entries=[('REFERÊNCIA 4.8b5',ref),('REDUÇÃO AUTOMÁTICA',auto.resize((384,256),Image.Resampling.NEAREST)),
        ('PROPOSTA LIMPA ×4',im.resize((384,256),Image.Resampling.NEAREST)),
        ('MESTRE APROVADO ×4',master.resize((200,208),Image.Resampling.NEAREST)),
        ('f0 4.8b4 REJEITADA ×4',old.resize((384,256),Image.Resampling.NEAREST))]
    for i,(label,picture) in enumerate(entries):
        d.text((i*tile+12,12),label,font=font(16),fill=(245,234,219))
        y=40+(32 if i==0 else 24 if i==3 else 0)
        comp.paste(gray(picture),(i*tile+(tile-picture.width)//2,y))
    comp.save(OUT/'COMPARACAO_REFERENCIA_REDUCAO_PROPOSTA.png')
    comp.crop((0,0,1152,330)).save(OUT/'REFERENCIA_REDUCAO_PROPOSTA.png')
    trio=Image.new('RGB',(1152,330),(96,96,96))
    trio.paste(comp.crop((768,0,1920,330)),(0,0))
    trio.save(OUT/'PROPOSTA_MESTRE_f0_48b4.png')
    # Also compare against the small Carrasco at the manual's native scale.
    carr=Image.open(ROOT/'assets/characters/pequeno_v34A/quadros/idle/idle_f0.png').convert('RGBA')
    scale=Image.new('RGBA',(288,88),(96,96,96,255));d=ImageDraw.Draw(scale)
    for label,actor,anchor,x in [('f0 proposta',im,(40,56),49),('Mestre',master,(24,50),145),('Carrasco',carr,(25,50),241)]:
        scale.alpha_composite(actor,(x-anchor[0],64-anchor[1]))
        d.text((x-30,72),label,font=font(10),fill=(245,234,219,255))
    scale.save(OUT/'ESCALA_ALINHADA_x1.png')
    scale.resize((1152,352),Image.Resampling.NEAREST).save(OUT/'ESCALA_ALINHADA_x4.png')
    scene_source=ROOT/'codex/evidencias_peregrino_47c/marcha_na_sala_x1.png'
    scene=Image.open(scene_source).convert('RGBA')
    feet=(430,309);position=(feet[0]-AX,feet[1]-AY)
    scene.alpha_composite(im,position);d=ImageDraw.Draw(scene)
    d.rectangle((9,176,600,215),fill=(17,16,18,255))
    d.text((16,180),'PRÉVIA — montagem ×1; pose estática, arte NÃO instalada',font=font(16),fill=(250,232,203,255))
    d.text((16,201),'Captura do cemitério em zoom 0,9 + f0 proposta de 48 px',font=font(11),fill=(218,210,201,255))
    scene.save(OUT/'PREVIA_CEMITERIO_x1.png')
    save(OUT/'PREVIA_METODO.json',{'previa':True,'arte_instalada':False,
        'captura_base':scene_source.relative_to(ROOT).as_posix(),'captura_sha256':sha(scene_source),
        'zoom':.9,'escala_arte_tela':1,'ancora_tela':feet,'posicao_inteira':position})
    aux=gray(im).resize((768,512),Image.Resampling.NEAREST);d=ImageDraw.Draw(aux)
    points=json.loads((ART/'POSE.json').read_text(encoding='utf-8'))['pontos_novos']
    for leg,c in zip(points.values(),((255,212,65),(69,210,255))):
        ps=[(leg[k][0]*8+4,leg[k][1]*8+4) for k in ('quadril','joelho','tornozelo','centro_sola')]
        d.line(ps,fill=c,width=2)
        for x,y in ps:d.ellipse((x-3,y-3,x+3,y+3),fill=c)
    aux.save(OUT/'ARTICULACOES_AUXILIAR.png')
    gray(im).crop((12,39,33,50)).resize((420,220),Image.Resampling.NEAREST).save(OUT/'PERNAS_ENCAIXE_INSPECAO.png')
    ref_user=Image.open(ART/'REFERENCIA_AJUSTE_USUARIO.png').convert('RGB')
    proposal_crop=gray(im).resize((384,256),Image.Resampling.NEAREST).crop((36,159,134,210))
    detail=Image.new('RGB',(824,248),(96,96,96));d=ImageDraw.Draw(detail)
    for x,label,picture in [(0,'RECORTE ENVIADO PELO USUÁRIO',ref_user),(412,'PROPOSTA LIMPA',proposal_crop)]:
        d.text((x+8,8),label,font=font(14),fill=(245,234,219))
        detail.paste(picture.resize((392,204),Image.Resampling.NEAREST),(x+8,32))
    detail.save(OUT/'RECORTE_USUARIO_VS_PROPOSTA.png')

def verify():
    im=Image.open(ART/'run_f0_x1.png');a=np.array(im);ix=indices(im);m=ix>=0;y,x=np.where(m)
    assert im.size==(96,64) and im.mode=='RGBA'
    assert set(np.unique(a[...,3]))=={0,255}
    assert y.min()==8 and y.max()==55 and y.max()-y.min()+1==48
    assert not a[56:,:,3].any()
    assert len(components(m))==1
    iso=int(((ix>=0)&~np.any(neighbors(ix)==ix,axis=0)).sum())
    assert iso==0, f'{iso} isolated colour pixels'
    assert (ix[boundary(m)]==3).all(),'Outline must be continuous'
    hm=np.array(Image.open(BASE/'rig_48b/partes/cabeca_cabelo.png').convert('RGBA'))
    master=np.array(Image.open(MASTER).convert('RGBA'));ys,xs=np.where(hm[...,3]>0)
    assert np.array_equal(hm[ys,xs],master[ys,xs])
    assert np.array_equal(a[ys+6,xs+9],master[ys,xs]),'Master head/face pixels changed'
    assert sha(MASTER)==EXPECTED
    assert a[55,40,3]==255 and a[49,15,3]==255,'Registered soles must belong to the boots'
    auto=np.array(Image.open(ART/'reducao_automatica_canvas_x1.png'))
    assert np.array_equal(a[41:50,14:31,3],auto[41:50,14:31,3]),'Raised leg silhouette must follow the user crop'
    user=np.array(Image.open(ART/'REFERENCIA_AJUSTE_USUARIO.png').convert('RGB'))
    ref_crop=np.array(gray(Image.fromarray(auto)).resize((384,256),Image.Resampling.NEAREST).crop((36,159,134,210)))
    assert np.array_equal(user,ref_crop),'The user reference must match the registered proportional-reduction crop'
    blade_widths=[]
    for px in range(40,53):
        py=39+(px-32)//2
        assert a[py:py+4,px,3].all(),'Blade continuity'
        blade_widths.append(4)
    assert not any(p.suffix.lower() in ('.gif','.mp4','.webm','.avi') for directory in (ART,OUT) for p in directory.rglob('*'))
    report={'aprovado_tecnicamente':True,'avaliacao_visual':'pendente do usuário',
        'canvas':[96,64],'altura_cabelo_sola_px':48,'ancora':[AX,AY],'chao_y':55,
        'bbox_alpha':[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)],
        'paleta':'paleta_bosque_v1','cores_usadas':len(np.unique(ix[m])),
        'ids_cores':np.unique(ix[m]).tolist(),'alpha':[0,255],'componentes':1,
        'cores_isoladas':iso,'contorno_continuo':True,'cabeca_rgba_identica_ao_mestre':True,
        'mestre_sha256':sha(MASTER),'fonte_sha256':sha(SOURCE),'prompt_sha256':sha(SOURCE.parent/'PROMPT.txt'),
        'proposta_sha256':sha(ART/'run_f0_x1.png'),'paleta_sha256':sha(PALFILE),
        'pixels_cabeca_reutilizados':len(ys),'largura_vertical_lamina_maior_parte_px':4,
        'afunilamento_somente_ponta_x':[53,56],'sola_apoio':[40,55],'sola_elevada':[15,49],
        'silhueta_perna_recolhida_igual_ao_recorte_usuario':True,
        'recorte_usuario_sha256':sha(ART/'REFERENCIA_AJUSTE_USUARIO.png'),
        'arte_instalada':False,'somente_f0':True,'rig_ou_ciclo_atualizado':False}
    save(OUT/'VERIFICACAO_POSE.json',report);print(json.dumps(report,ensure_ascii=False))

def main():
    p=argparse.ArgumentParser();p.add_argument('--reduce',action='store_true');p.add_argument('--verify',action='store_true');args=p.parse_args()
    ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    if args.verify:verify();return
    if args.reduce:reduce()
    generate();evidence();verify()
if __name__=='__main__':main()
