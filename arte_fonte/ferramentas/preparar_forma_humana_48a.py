"""Mestre 4.8a: redução do projeto + retoques de pixels escolhidos à mão.

Não instala assets. Sem rig/poses/pacote. --reduzir repete a ferramenta original;
sem essa opção, conserva a redução automática e reconstrói a limpeza/evidências.
"""
from pathlib import Path
import argparse, collections, hashlib, json, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT/'arte_fonte/forma_humana_v1'
OUT = ROOT/'codex/evidencias_forma_humana_48a'
CONCEPT = ROOT/'arte_fonte/forma_humana_conceito_v1/forma_humana_conceito_v1.png'
PALETTE = json.loads((ROOT/'arte_fonte/paleta/paleta_bosque_v1.json').read_text(encoding='utf-8'))
PAL = np.array([c['rgb'] for c in PALETTE['cores']], dtype=np.uint8)
AUTO = ART/'reducao_automatica_x1.png'
MASTER = ART/'forma_humana_mestre_x1.png'
ANCHOR = [24, 50]

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,obj):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def indices(im):
    a=np.array(im.convert('RGBA')); idx=np.full(a.shape[:2],-1,dtype=np.int16)
    for i,c in enumerate(PAL): idx[(a[...,3]>0)&np.all(a[...,:3]==c,axis=2)]=i
    assert np.all((a[...,3]==0)|(idx>=0))
    return idx

def rgba(idx):
    a=np.zeros((*idx.shape,4),np.uint8); mask=idx>=0
    a[mask,:3]=PAL[idx[mask]]; a[mask,3]=255
    return Image.fromarray(a)

def neighbors(a,fill=-2):
    p=np.pad(a,1,constant_values=fill)
    return np.stack([p[1+dy:1+dy+a.shape[0],1+dx:1+dx+a.shape[1]]
                     for dy in (-1,0,1) for dx in (-1,0,1) if dy or dx])

def components(m):
    remain=set(map(tuple,np.argwhere(m))); groups=[]
    while remain:
        start=remain.pop(); todo=[start]; group=[start]
        while todo:
            y,x=todo.pop()
            for dy in (-1,0,1):
                for dx in (-1,0,1):
                    q=(y+dy,x+dx)
                    if q in remain: remain.remove(q);todo.append(q);group.append(q)
        groups.append(group)
    return sorted(groups,key=len,reverse=True)

# Preserve the automatic reduction's shading. Only tiny eye/hand clusters
# are picked by hand, followed by the exact isolated-color rule in manual 6.3.
PAINT = [
 ('olho_perfil',3,[(28,12),(28,13)]),
 ('olho_luz',17,[(27,13),(27,14)]),
 ('mao_empunhadura_sombra',35,[(20,31),(20,32)]),
 ('mao_empunhadura_luz',37,[(19,31),(19,32)]),
 ('detalhe_vermelho',25,[(25,31),(26,31),(26,32),(25,32)]),
 ('lamina_volume',16,[(22,33),(24,33),(45,44),(45,45),(43,45),(22,35)]),
 ('lamina_fio',18,[(23,33),(25,34),(44,44),(44,45),(43,44),(23,34)]),
 ('lamina_ponta_luz',17,[(40,42),(42,43),(43,44),(41,44),(40,43)]),
]

def clean():
    idx=indices(Image.open(AUTO)); original=idx.copy(); m=idx>=0
    # Keep the largest silhouette; only tiny reduction specks are removed.
    for group in components(m)[1:]:
        for y,x in group: m[y,x]=False;idx[y,x]=-1
    # Paint selected local clusters, clipped to the proportional source mask.
    for name,color,points in PAINT:
        region=Image.new('1',(idx.shape[1],idx.shape[0]))
        ImageDraw.Draw(region).polygon(points,fill=1)
        idx[np.array(region)&m]=color
    edge=m & ~(np.roll(m,1,0)&np.roll(m,-1,0)&np.roll(m,1,1)&np.roll(m,-1,1))
    edge[0]|=m[0];edge[-1]|=m[-1];edge[:,0]|=m[:,0];edge[:,-1]|=m[:,-1]
    idx[edge]=3
    # Existing automatic shading retains volume. The final rule only removes tiny
    # single-color outliers, exactly the eight-neighbor rule in manual 6.3.
    recolored=0
    for _ in range(32):
        ns=neighbors(idx); isolated=(idx>=0)&~np.any(ns==idx,axis=0)
        if not isolated.any():break
        for y,x in np.argwhere(isolated):
            values=ns[:,y,x];values=values[values>=0]
            idx[y,x]=collections.Counter(values.tolist()).most_common(1)[0][0]
            recolored+=1
        idx[edge]=3
    assert not np.any((idx>=0)&~np.any(neighbors(idx)==idx,axis=0))
    assert len(components(idx>=0))==1
    pad=np.full((52,50),-1,dtype=np.int16);pad[2:50,2:48]=idx
    assert np.array_equal(m,idx>=0)
    save(ART/'limpeza_pixels.json',{'origem_sha256':sha(AUTO),'operacoes_manuais':[
        {'parte':n,'cor_id':c,'poligono':p} for n,c,p in PAINT],
        'pixels_alterados':int((idx!=original).sum()),'outliers_de_cor_reagrupados':recolored,
        'partes_reescaladas':0,'paleta_sha256':sha(ROOT/'arte_fonte/paleta/paleta_bosque_v1.json')})
    rgba(pad).save(MASTER)

def font(size=14):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',size)

def display(im,size):
    bg=Image.new('RGBA',size,(70,66,68,255));bg.alpha_composite(im,((size[0]-im.width)//2,(size[1]-im.height)//2))
    return bg.convert('RGB')

def evidence():
    master=Image.open(MASTER).convert('RGBA')
    master.resize((200,208),Image.Resampling.NEAREST).save(ART/'forma_humana_mestre_x4.png')
    concept=Image.open(CONCEPT).convert('RGBA'); box=concept.getchannel('A').point(lambda a:255 if a>40 else 0).getbbox()
    concept=concept.crop(box)
    # Display scaling for comparison only; the master is never transformed.
    concept=concept.resize((round(concept.width*384/concept.height),384),Image.Resampling.NEAREST)
    comp=Image.new('RGB',(1254,470),(48,44,46));d=ImageDraw.Draw(comp)
    for x,title,im in [(0,'CONCEITO APROVADO',concept),(418,'REDUÇÃO AUTOMÁTICA ×8',Image.open(AUTO).resize((368,384),Image.Resampling.NEAREST)),(836,'MESTRE LIMPO ×8',master.resize((400,416),Image.Resampling.NEAREST))]:
        target=(418,430);tile=display(im,target);comp.paste(tile,(x,40));d.text((x+12,10),title,font=font(17),fill=(240,230,220))
    comp.save(OUT/'COMPARACAO_CONCEITO_REDUCAO_MESTRE.png')
    carr=Image.open(ROOT/'assets/characters/pequeno_v34A/quadros/idle/idle_f0.png').convert('RGBA')
    pilgrim=Image.open(ROOT/'arte_fonte/peregrino_corrompido_v1/mestre_limpo_x1.png').convert('RGBA')
    scale=Image.new('RGBA',(310,115),(65,61,63,255));d=ImageDraw.Draw(scale)
    ground=84;d.line((8,ground,302,ground),fill=(180,164,148,255))
    actors=[('Humana',master,(24,50),54),('Carrasco',carr,(25,50),153),('Peregrino',pilgrim,(26,52),254)]
    for name,im,anchor,x in actors:
        scale.alpha_composite(im,(x-anchor[0],ground-anchor[1]))
        d.text((x-28,96),name,font=font(10),fill=(238,230,220,255))
    scale.save(OUT/'ESCALA_ALINHADA_x1.png')
    scale.resize((1240,460),Image.Resampling.NEAREST).save(OUT/'ESCALA_ALINHADA_x4.png')
    source=ROOT/'codex/evidencias_peregrino_47c/marcha_na_sala_x1.png'
    scene=Image.open(source).convert('RGBA')
    # This screenshot is the actual 960x540 cemetery at zoom .9. Presenters
    # compensate camera zoom, so native artwork stays x1 in screen pixels.
    # x=430 belongs to ground segment [610,414]-[720,417] in the approved map.
    foot_x=430
    foot_y=round((414+86)*.6156+(430-610*.6154)*(3*.6156)/(110*.6154))
    pos=(foot_x-ANCHOR[0],foot_y-ANCHOR[1]);scene.alpha_composite(master,pos)
    d=ImageDraw.Draw(scene);d.rectangle((9,176,546,214),fill=(17,16,18,255))
    d.text((16,181),'PRÉVIA — montagem ×1; arte NÃO instalada',font=font(17),fill=(250,232,203,255))
    d.text((16,201),'Captura do cemitério em zoom 0,9 + mestre de 48 px',font=font(11),fill=(218,210,201,255))
    d.text((410,237),'Humana',font=font(10),fill=(245,231,210,255))
    scene.save(OUT/'PREVIA_CEMITERIO_x1.png')
    save(OUT/'PREVIA_METODO.json',{'previa':True,'arte_instalada':False,'captura_base':source.relative_to(ROOT).as_posix(),
        'captura_sha256':sha(source),'zoom_captura':.9,'escala_da_montagem':1,'ancora_tela':[foot_x,foot_y],
        'posicao_inteira':list(pos),'formula_chao':'GROUND_TOPS [610,414]-[720,417]; ART_X .6154, ART_Y .6156, offset Y 86',
        'alinhamento_escala':{'humana':[24,50],'carrasco':[25,50],'peregrino':[26,52]}})

def verify():
    im=Image.open(MASTER);a=np.array(im);idx=indices(im);m=idx>=0; ys,xs=np.where(m)
    used=collections.Counter(idx[m].tolist());isolated=int(((idx>=0)&~np.any(neighbors(idx)==idx,axis=0)).sum())
    assert im.mode=='RGBA' and set(np.unique(a[...,3]))=={0,255}
    assert im.size==(50,52) and ys.max()-ys.min()+1==48 and ys.min()==2 and ys.max()==49
    assert ANCHOR==[24,50] and all(type(v)==int for v in ANCHOR)
    assert len(components(m))==1 and isolated==0
    edge=m & ~(np.roll(m,1,0)&np.roll(m,-1,0)&np.roll(m,1,1)&np.roll(m,-1,1))
    assert np.all(idx[edge]==3),'Outline changed'
    boots=components(m[47:50,:38]);assert len(boots)==2,'Two distinct soles required'
    assert a[50:,:,3].sum()==0
    assert len(set(idx[23:40,4:18].ravel())&{0,1,2,14})>=3,'Cloak volume flattened'
    assert len(set(idx[42:49,12:37].ravel())&{7,8,10,11,12})>=4,'Boot volume flattened'
    report={'aprovado':True,'arquivo':MASTER.relative_to(ROOT).as_posix(),'sha256':sha(MASTER),
        'canvas_px':list(im.size),'altura_cabelo_solas_px':48,'bbox_alpha':[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],
        'ancora_pes':ANCHOR,'chao_apos_sola':50,'olhando_para':'direita','alpha':[0,255],'componentes':1,
        'pixels_isolados_sem_mesma_cor_em_8_vizinhos':isolated,'botas_distintas':2,'cores_usadas':len(used),
        'paleta':PALETTE['nome'],'cores':[{'id':i,'rgb':PAL[i].tolist(),'pixels':n} for i,n in sorted(used.items())],
        'arte_instalada':False,'rig_animacoes_pacote_criados':False,'conceito_sha256':sha(CONCEPT),
        'prompt_sha256':sha(CONCEPT.parent/'PROMPT.txt'),'reducao_automatica_sha256':sha(AUTO)}
    save(ART/'mestre_conferido.json',report);save(OUT/'VERIFICACAO_MESTRE.json',report)
    print(json.dumps(report,ensure_ascii=False),flush=True)

def main():
    p=argparse.ArgumentParser();p.add_argument('--reduzir',action='store_true');p.add_argument('--verify',action='store_true');args=p.parse_args()
    ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    if args.verify:verify();return
    if args.reduzir:
        sys.path.insert(0,str(ROOT/'.godot/forma_humana_48a/deps'))
        import importlib.util
        spec=importlib.util.spec_from_file_location('reduce',ROOT/'arte_fonte/ferramentas/reduzir_referencia.py')
        tool=importlib.util.module_from_spec(spec);spec.loader.exec_module(tool)
        tool.salvar_x1(tool.reduzir(tool.alfa_ou_fundo(Image.open(CONCEPT)),48,PAL),str(AUTO))
    clean();evidence();verify()

if __name__=='__main__':main()
