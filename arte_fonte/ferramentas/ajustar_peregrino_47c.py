"""Recover rigid master boots in only the sixteen marching frames (4.7c).

Boots are native crops, never stretched. Hip/knee/ankle joints articulate;
stance advances -4 local pixels per +4 actor pixels. Approved upper layers
and every other animation are immutable. Previews/evidence are isolated.
"""
from pathlib import Path
import argparse, copy, importlib.util, json, math
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
s=importlib.util.spec_from_file_location('b',ROOT/'arte_fonte/ferramentas/ajustar_peregrino_47b.py')
b=importlib.util.module_from_spec(s);s.loader.exec_module(b)
rig=b.rig;AX,AY=rig.AX,rig.AY;PAL=rig.PAL
ART=rig.ART/'ajuste_47c';OUT=ROOT/'codex/evidencias_peregrino_47c'
TARGETS=('patrulha','perseguicao')
FX=b.FEET_X;FY=b.FEET_Y

def save(p,x):rig.save_json(p,x)
def parts():
 p={name:Image.open(b.ART/'partes'/f'{name}.png').convert('RGBA') for name in
    ('manto_marcha','corpo_marcha','cabeca_legivel','cajado_sem_sinos','sinos')}
 p['braco_tras']=Image.open(rig.ART/'partes/braco_tras.png').convert('RGBA')
 master=Image.open(rig.ART/'mestre_limpo_x1.png').convert('RGBA')
 for name,box,ankle in [('frente',(26,39,39,52),(31,40)),('tras',(12,39,25,52),(18,40))]:
  source=master.crop(box);boot=rig.clean(source)
  p['bota_'+name]=boot
  dst=ART/'partes';dst.mkdir(parents=True,exist_ok=True)
  source.save(dst/f'bota_{name}_recorte_mestre.png');boot.save(dst/f'bota_{name}_rig.png')
  p['origem_'+name]=(ankle[0]-box[0],box[3]-box[1])
 return p

def articulated_leg(p,k,front,bob,lean):
 name='frente' if front else 'tras';n=k if front else (k+4)%8
 foot=(FX[n],FY[n]);hip_x=(-1 if front else -7)+lean
 hip_y=-18+bob;ankle_x=foot[0];ankle_y=-11+foot[1]
 knee_x=round((hip_x+ankle_x)/2)+(2 if foot[1] else 0)
 knee_y=-14+bob+foot[1]//3
 im=rig.blank()
 rig.line(im,[(hip_x,hip_y),(knee_x,knee_y),(ankle_x,ankle_y)],3,8)
 rig.line(im,[(hip_x,hip_y+1),(knee_x,knee_y),(ankle_x,ankle_y)],8 if front else 7,6)
 # Cuff/knee facets reuse the standing leather bands instead of a flat strip.
 rig.line(im,[(hip_x+1,hip_y+1),(knee_x+1,knee_y),(ankle_x+1,ankle_y)],11 if front else 8,3)
 rig.ellipse(im,(knee_x-2,knee_y-2,knee_x+2,knee_y+2),10 if front else 8)
 rig.line(im,[(knee_x,knee_y-1),(knee_x+2,knee_y-1)],12 if front else 10,2)
 boot=p['bota_'+name];ox,height=p['origem_'+name]
 x=AX+foot[0]-ox;y=AY-height+foot[1]
 im.alpha_composite(boot,(x,y))
 im=rig.clean(im)
 return im,{'quadril':[hip_x,hip_y],'joelho':[knee_x,knee_y],'tornozelo':[ankle_x,ankle_y],
            'bota_xy':[x,y],'bota_dimensoes':list(boot.size),'apoio':n<=4,'fase_perna':n}

def frame(p,name,k):
 lean=3 if name=='perseguicao' else 0;bob=b.BOB[k];prev=(k-1)%8
 near,nm=articulated_leg(p,k,True,bob,lean)
 far,fm=articulated_leg(p,k,False,bob,lean)
 upper=rig.blank()
 b.offset(upper,p['braco_tras'],lean,bob)
 b.offset(upper,p['manto_marcha'],lean+b.SWAY[prev],b.BOB[prev])
 b.offset(upper,p['corpo_marcha'],lean,bob)
 b.offset(upper,p['cabeca_legivel'],lean,bob)
 b.held_staff(upper,p,lean,bob,lean+b.SWAY[prev],b.BOB[prev])
 combined=rig.blank();combined.alpha_composite(far);combined.alpha_composite(near)
 # Hem stays above both legs; exact existing upper pixels win below as well.
 combined.alpha_composite(upper);candidate=np.array(rig.clean(combined))
 base=Image.open(ART/'base_47b'/f'{name}_f{k:02d}.png').convert('RGBA');old=np.array(base)
 old_near=b.leg(FX[k],FY[k],True,bob,lean)
 n=(k+4)%8;old_far=b.leg(FX[n],FY[n],False,bob,lean)
 editable=np.array(old_near)[...,3]>0
 editable|=np.array(old_far)[...,3]>0
 editable|=np.array(near)[...,3]>0;editable|=np.array(far)[...,3]>0
 editable[:AY-23]=False
 protected=np.array(upper)[...,3]>0
 editable&=~protected
 result=old.copy();result[editable]=candidate[editable]
 # Cleanup can touch only permitted leg pixels; all approved upper pixels
 # (including hood, moss, bells and hem) remain exactly those of 4.7b.
 for _ in range(16):
  a=rig.indices(Image.fromarray(result));ns=rig.neighbors(a)
  isolated=(a>=0)&~np.any(ns==a,axis=0)
  if not isolated.any():break
  # Preserve an existing hem pixel by restoring its matching leg-side
  # neighbor at the seam; never repaint the approved upper layer.
  for y,x in np.argwhere(isolated&~editable):
   options=[]
   for dy in (-1,0,1):
    for dx in (-1,0,1):
     ny,nx=y+dy,x+dx
     if 0<=ny<rig.H and 0<=nx<rig.W and editable[ny,nx] and np.array_equal(old[ny,nx],result[y,x]):options.append((ny,nx))
   assert options,'No leg-side seam neighbor for protected pixel'
   ny,nx=options[0];result[ny,nx]=old[ny,nx]
  cleaned=np.array(rig.clean(Image.fromarray(result),outline=False,main=False))
  result[editable]=cleaned[editable]
 mask=Image.fromarray((editable*255).astype(np.uint8))
 return Image.fromarray(result),mask,{'frente':nm,'tras':fm,'secundario_quadro':prev}

def build(apply=False):
 p=parts();manifest=json.loads((rig.PACK/'manifesto_sprites.json').read_text(encoding='utf-8'))
 poses={};gifs=OUT/'depois_gifs_x4';gifs.mkdir(parents=True,exist_ok=True)
 for a in manifest['animacoes']:
  if a['id'] not in TARGETS:continue
  name=a['id'];images=[];poses[name]=[]
  for k,q in enumerate(a['quadros']):
   im,mask,pose=frame(p,name,k);poses[name].append(pose);images.append(im)
   for folder,img in [('quadros',im),('mascaras_edicao',mask)]:
    d=ART/folder;d.mkdir(exist_ok=True);img.save(d/f'{name}_f{k:02d}.png')
   if apply:
    target=rig.PACK/q['arquivo'];im.save(target);q['sha256']=rig.sha(target)
  tiles=[]
  for im in images:
   bg=Image.new('RGBA',im.size,(96,96,96,255));bg.alpha_composite(im)
   tiles.append(bg.resize((rig.W*4,rig.H*4),Image.Resampling.NEAREST).convert('RGB'))
  tiles[0].save(gifs/f'{name}_x4.gif',save_all=True,append_images=tiles[1:],duration=[q['ms'] for q in a['quadros']],loop=0,disposal=2,optimize=False)
  sheet=Image.new('RGB',(96*4*4,(64*4+20)*2),(96,96,96));draw=ImageDraw.Draw(sheet)
  for k,im in enumerate(images):
   crop=im.crop((22,28,118,92));bg=Image.new('RGBA',crop.size,(96,96,96,255));bg.alpha_composite(crop)
   sheet.paste(bg.resize((384,256),Image.Resampling.NEAREST),(k%4*384,k//4*276+20));draw.text((k%4*384+8,k//4*276+4),str(k),fill='white')
  sheet.save(ART/f'{name}_quadros_x4.png')
 save(ART/'poses.json',poses)
 save(ART/'rig.json',{'gerador':'arte_fonte/ferramentas/ajustar_peregrino_47c.py','escala':1,
 'mestre_sha256':rig.sha(rig.ART/'mestre_limpo_x1.png'),'botas':'recortes rigidos do mestre, sem escala; pernas por quadril/joelho/tornozelo',
 'cadencia_px_por_quadro':4,'upper':'pixels protegidos da 4.7b; barra do manto acima das pernas',
 'partes':{q.name:{'sha256':rig.sha(q),'dimensoes':list(Image.open(q).size)} for q in (ART/'partes').glob('*.png')}})
 if apply:save(rig.PACK/'manifesto_sprites.json',manifest)
 print({'aplicado':apply,'marchas':2,'quadros':16})

def normalize(m):
 m=copy.deepcopy(m)
 for a in m['animacoes']:
  if a['id'] in TARGETS:
   for q in a['quadros']:q['sha256']='ART_ONLY'
 return m

def verify():
 data=json.loads((rig.PACK/'manifesto_sprites.json').read_text(encoding='utf-8'))
 before=json.loads((OUT/'MANIFESTO_antes.json').read_text(encoding='utf-8'))
 assert normalize(data)==normalize(before),'Manifest contract changed'
 oldhash=json.loads((OUT/'PACOTE_SHA256_antes.json').read_text(encoding='utf-8'))
 allowed={'manifesto_sprites.json'}|{f'sprites/{n}_f{i:02d}.png' for n in TARGETS for i in range(8)}
 actual={q.relative_to(rig.PACK).as_posix():rig.sha(q) for q in rig.PACK.rglob('*') if q.is_file()}
 assert set(actual)==set(oldhash),'Package file inventory changed'
 assert all(v==actual[k] for k,v in oldhash.items() if k not in allowed),'Protected package file changed'
 checks=[]
 for a in data['animacoes']:
  for k,q in enumerate(a['quadros']):
   path=rig.PACK/q['arquivo'];im=Image.open(path);idx=rig.indices(im)
   components=rig.components(idx>=0)
   assert rig.sha(path)==q['sha256'] and im.size==(rig.W,rig.H) and q['ancora']==rig.ANCHOR
   assert len(components)==(2 if a['id']=='morte' and k>=3 else 1)
   assert not np.any((idx>=0)&~np.any(rig.neighbors(idx)==idx,axis=0)),path.name
   assert (q['hitbox'] is not None)==(q['fase']=='ACTIVE')
   for extra in q['efeitos']+[a['sombra']]:assert rig.sha(rig.PACK/extra['arquivo'])==extra['sha256']
   if a['id'] in TARGETS:
    base=np.array(Image.open(ART/'base_47b'/path.name));mask=np.array(Image.open(ART/'mascaras_edicao'/path.name))>0
    pixels=np.array(im);diff=np.any(base!=pixels,axis=2)
    assert diff.any() and not np.any(diff&~mask),'Non-leg pixels changed'
    assert pixels[AY:,:,3].sum()==0,'Pixels below feet'
    assert rig.sha(ART/'quadros'/path.name)==rig.sha(path)
    checks.append({'arquivo':q['arquivo'],'pixels_alterados':int(diff.sum()),'fora_das_pernas':0,'componentes':1,'pixels_isolados':0})
  for attack in ([a['ataque']] if isinstance(a.get('ataque'),dict) else a.get('ataque',[])):
   original=rig.tres(attack['attack_id'].removeprefix('peregrino_'))
   for phase,key in [('PREPARACAO','windup'),('ATIVO','active'),('RECUPERACAO','recovery')]:
    assert sum(a['quadros'][i]['ms'] for i in attack['fases'][phase]['quadros'])==original[key]
 for a in data['animacoes']:
  if a['id'] in TARGETS:assert len(a['quadros'])==8 and a['px_por_quadro']==4
 # Check the visible soles, not just the joint parameters: at stance they
 # are exact rigid master-crop pixels and retain their width/texture.
 poses=json.loads((ART/'poses.json').read_text(encoding='utf-8'))
 stance=[]
 for name in TARGETS:
  for k,p in enumerate(poses[name]):
   im=Image.open(rig.PACK/'sprites'/f'{name}_f{k:02d}.png')
   for side in ('frente','tras'):
    leg=p[side]
    if not leg['apoio']:continue
    boot=Image.open(ART/'partes'/f'bota_{side}_rig.png')
    x,y=leg['bota_xy'];w,h=boot.size
    assert (w,h)==(13,13),'Boot was scaled'
    assert np.array_equal(np.array(im.crop((x,y+h-3,x+w,y+h))),np.array(boot.crop((0,h-3,w,h)))),'Stance sole was stretched/repainted'
    stance.append({'anim':name,'quadro':k,'perna':side,'sola_rigida':True,'bota_px':[w,h]})
  for side in ('frente','tras'):
   for k,p in enumerate(poses[name]):
    after=poses[name][(k+1)%8][side];now=p[side]
    if now['apoio'] and after['apoio']:
     assert after['bota_xy'][0]-now['bota_xy'][0]==-4
     assert after['bota_xy'][1]==now['bota_xy'][1]
     stance.append({'anim':name,'transicao':[k,(k+1)%8],'perna':side,'avanco_personagem_px':4,'recuo_sola_px':-4,'deriva_no_apoio_por_quadro_px':0})
 save(OUT/'VERIFICACAO_PACOTE_47C.json',{'quadros_marcha':16,'pixels_upper_protegidos':True,'outros_arquivos_pacote_intactos':len(oldhash)-17,
 'contrato_integral_preservado':True,'quadros':checks,'tempos_ataques_iguais_tres':True,'solas_e_apoio':stance})
 print({'verificado':True,'marchas':2,'quadros':len(checks),'upper_intacto':True,'outras_animacoes_intactas':True})

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--preview',action='store_true');p.add_argument('--apply',action='store_true');p.add_argument('--verify',action='store_true');args=p.parse_args()
 if args.verify:verify()
 else:build(args.apply)
