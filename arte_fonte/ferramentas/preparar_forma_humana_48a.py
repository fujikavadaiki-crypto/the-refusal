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

# These shapes are manually placed on the 46x48 automatic reduction. They
# preserve its proportions and silhouette: no part is stretched or rescaled.
PAINT = [
 ('capa_sombra',1,[(12,19),(18,23),(17,30),(20,33),(17,39),(10,38),(5,42),(1,37),(4,32),(9,25)]),
 ('capa_dobra',2,[(12,21),(14,21),(11,28),(8,34),(4,37),(3,36),(6,31),(10,25)]),
 ('capa_dobra_frente',2,[(14,29),(16,28),(15,33),(13,37),(10,39),(9,37)]),
 ('capa_luz_superior',14,[(12,21),(13,21),(11,25),(10,27),(9,27),(10,24)]),
 ('capa_fundo',0,[(8,34),(10,33),(9,37),(7,40),(5,41),(6,37)]),
 ('cabelo_base',8,[(16,1),(32,0),(36,7),(33,13),(28,16),(22,15),(17,16),(14,11),(16,6)]),
 ('cabelo_sombra',7,[(14,8),(20,7),(24,9),(23,12),(26,14),(24,16),(17,15),(15,12)]),
 ('cabelo_mecha_posterior',10,[(17,6),(22,4),(24,5),(22,7),(18,10),(16,10)]),
 ('cabelo_mecha_superior',11,[(20,3),(24,1),(28,2),(31,3),(29,5),(25,4),(22,5),(20,5)]),
 ('cabelo_luz_superior',12,[(25,2),(27,2),(29,3),(28,4),(25,3)]),
 ('cabelo_mecha_frente',10,[(27,5),(30,4),(34,6),(33,9),(31,10),(30,8),(27,9),(26,7)]),
 ('cabelo_fringe_sombra',3,[(25,9),(28,8),(29,10),(29,12),(27,13),(25,12)]),
 ('cabelo_fringe_luz',11,[(26,6),(28,5),(29,6),(28,8),(26,10),(25,10)]),
 ('cabelo_grupo_sombra_meio',8,[(22,5),(24,5),(24,7),(22,9),(20,10),(19,10),(20,8)]),
 ('cabelo_luz_direita',12,[(29,3),(31,4),(32,5),(31,6),(29,5),(28,4)]),
 ('cabelo_mecha_lateral',10,[(30,7),(32,6),(33,7),(32,10),(30,11),(29,10)]),
 ('rosto_base',37,[(28,11),(31,10),(32,13),(32,15),(30,18),(25,18),(23,16),(24,14),(26,14),(27,12)]),
 ('rosto_sombra',35,[(24,14),(26,14),(27,16),(28,17),(30,17),(29,18),(25,18),(23,16)]),
 ('rosto_luz',39,[(30,12),(31,12),(32,14),(31,16),(29,16),(29,15),(30,14)]),
 ('olho_perfil',3,[(28,12),(29,12),(29,14),(28,14)]),
 ('orelha',35,[(20,13),(22,13),(23,15),(21,16),(20,15)]),
 ('orelha_luz',37,[(20,13),(21,13),(21,14),(20,14)]),
 ('separacao_orelha_cabelo',3,[(23,12),(24,13),(24,15),(23,15)]),
 ('capuz_recuado',1,[(12,17),(16,16),(20,17),(24,19),(29,19),(31,18),(30,21),(26,22),(21,21),(17,19),(12,19)]),
 ('capuz_dobra',2,[(13,17),(17,17),(21,19),(25,20),(29,19),(29,20),(25,21),(20,20),(16,18),(13,18)]),
 ('capuz_luz',14,[(14,17),(17,17),(19,18),(18,19),(16,18),(14,18)]),
 ('couro_torso',8,[(18,20),(22,22),(25,22),(27,26),(27,28),(20,29),(17,26)]),
 ('couro_torso_volume',10,[(20,21),(22,22),(25,23),(25,26),(23,28),(20,27),(19,24)]),
 ('couro_torso_luz',11,[(22,22),(24,23),(25,24),(24,26),(22,26)]),
 ('ombro',10,[(16,20),(19,20),(20,22),(18,24),(15,23)]),
 ('ombro_luz',12,[(17,20),(19,21),(19,22),(17,22)]),
 ('braco_pele',35,[(17,23),(19,23),(20,25),(19,26),(16,25)]),
 ('braco_pele_luz',37,[(18,23),(19,23),(19,24),(17,24)]),
 ('braco_perto',8,[(16,26),(19,26),(20,28),(19,30),(21,32),(20,35),(17,34),(16,30)]),
 ('braco_perto_volume',10,[(17,27),(19,27),(19,30),(21,32),(20,33),(18,32),(17,29)]),
 ('braco_perto_luz',11,[(18,28),(19,28),(19,30),(20,31),(19,32),(18,30)]),
 ('braco_distante',8,[(27,25),(29,26),(29,28),(31,29),(32,31),(31,32),(29,30),(28,28)]),
 ('braco_distante_luz',11,[(28,26),(29,27),(29,28),(31,30),(30,31),(28,28)]),
 ('mao_distante',35,[(31,31),(32,31),(33,33),(31,34),(30,33)]),
 ('mao_distante_luz',37,[(32,31),(33,32),(32,33),(31,33)]),
 ('cinto',0,[(20,28),(27,28),(28,29),(25,30),(20,30)]),
 ('fivela',15,[(25,28),(26,28),(26,29),(25,29)]),
 ('detalhe_vermelho_sombra',21,[(25,30),(27,30),(27,34),(26,37),(24,36),(25,34)]),
 ('detalhe_vermelho_luz',25,[(26,30),(27,30),(27,33),(26,34)]),
 ('perna_tras',8,[(15,35),(20,35),(20,38),(18,40),(17,43),(19,46),(18,47),(11,47),(12,43),(14,40)]),
 ('perna_tras_volume',10,[(16,36),(18,36),(18,39),(16,41),(15,43),(17,45),(18,46),(14,46),(13,44),(14,41)]),
 ('perna_tras_luz',11,[(16,37),(18,37),(17,39),(15,39)]),
 ('bota_tras_luz',11,[(15,42),(16,42),(16,44),(18,45),(17,46),(14,45),(14,43)]),
 ('bota_tras_cano',11,[(13,43),(16,43),(16,44),(13,44)]),
 ('bota_tras_biqueira',12,[(15,45),(17,45),(18,46),(15,46)]),
 ('bota_tras_sola',7,[(11,46),(18,46),(19,47),(11,47)]),
 ('perna_frente',8,[(26,37),(30,38),(29,41),(30,44),(33,45),(34,47),(26,47),(25,44),(26,41)]),
 ('perna_frente_volume',10,[(27,38),(29,39),(28,41),(29,44),(32,45),(33,46),(27,46),(26,43)]),
 ('perna_frente_luz',11,[(28,40),(29,40),(29,42),(28,43),(27,42)]),
 ('bota_frente_luz',12,[(29,44),(30,44),(31,45),(32,46),(29,46),(28,45)]),
 ('bota_frente_cano',11,[(26,42),(29,42),(29,43),(26,43)]),
 ('bota_frente_sola',7,[(26,46),(33,46),(34,47),(26,47)]),
 ('mao_empunhadura',35,[(20,31),(22,31),(23,32),(22,34),(20,34),(19,33)]),
 ('mao_empunhadura_luz',37,[(21,31),(22,31),(22,32),(21,33),(20,33),(20,32)]),
 ('guarda',56,[(23,30),(24,30),(22,34),(21,34)]),
 ('guarda_luz',61,[(23,30),(24,30),(23,31),(22,31)]),
 ('lamina_sombra',15,[(24,33),(26,33),(44,44),(45,45),(43,45),(24,35)]),
 ('lamina_clara',17,[(24,33),(26,33),(44,44),(43,44),(24,34)]),
 ('lamina_fio',18,[(25,33),(27,34),(43,43),(44,44),(43,44),(25,34)]),
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
    # Manual clusters above retain volume. The final rule only removes tiny
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
