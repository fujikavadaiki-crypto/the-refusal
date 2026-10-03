"""4.7b: four art-only rig revisions. No gameplay/manifest timing edits.

--preview builds source parts/previews; --apply replaces only these 31 PNGs
and their SHA256 descriptors. --verify audits palette, shape and contract.
The original 4.7 parts/source/evidence remain archived byte-for-byte;
the public generator delegates its build/verify commands to this revision.
"""
from pathlib import Path
import argparse, copy, importlib.util, json, math
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('rig47',ROOT/'arte_fonte/ferramentas/gerar_peregrino_corrompido.py')
rig=importlib.util.module_from_spec(spec);spec.loader.exec_module(rig)
ART=rig.ART/'ajuste_47b';OUT=ROOT/'codex/evidencias_peregrino_47b'
TARGETS=('patrulha','perseguicao','ruptura','morte')
PAL=rig.PAL;AX,AY=rig.AX,rig.AY
FEET_X=[10,6,2,-2,-6,-3,3,8]
FEET_Y=[0,0,0,0,0,-4,-7,-4]
BOB=[-1,0,0,-1,-1,0,0,-1]
SWAY=[-1,0,1,1,1,0,-1,-1]

def save(p,x):rig.save_json(p,x)
def trim(im,limit):
 a=np.array(im);a[limit:]=0;return Image.fromarray(a)
def offset(im,part,x=0,y=0):rig.paste_piece(im,part,x,y)
def poly(im,pts,c):rig.poly(im,pts,c)
def line(im,pts,c,w=1):rig.line(im,pts,c,w)

def held_staff(im,parts,lean,bob,secondary_lean,secondary_bob):
 offset(im,parts['cajado_sem_sinos'],lean,bob)
 # Restore the shaft hidden by the overlapping bell extraction mask.
 line(im,[(lean+8,bob-19),(lean+26,bob-30)],3,5)
 line(im,[(lean+8,bob-19),(lean+26,bob-30)],46,3)
 line(im,[(lean+9,bob-21),(lean+25,bob-30)],48,1)
 for x in (21,26):
  line(im,[(lean+25,bob-28),(secondary_lean+x,secondary_bob-17)],3,2)
 offset(im,parts['sinos'],secondary_lean,secondary_bob)

def leg(foot_x,foot_y,front,bob=0,lean=0):
 """Replacement thigh/shin/boot; real feet exchange, no translated robe."""
 im=rig.blank();hip=(-1 if front else -7)+lean
 knee=round((hip+foot_x)/2)+(2 if foot_y else -1)
 ky=-9+(foot_y//2);bottom=-1+foot_y
 poly(im,[(hip-3,-18+bob),(hip+3,-18+bob),(knee+3,ky),
          (foot_x+3,bottom-3),(foot_x+7,bottom-1),(foot_x+7,bottom),
          (foot_x-4,bottom),(foot_x-4,bottom-4),(knee-3,ky)],3)
 color=10 if front else 8
 line(im,[(hip,-16+bob),(knee,ky),(foot_x,-4+foot_y)],color,5)
 line(im,[(hip+1,-15+bob),(knee+1,ky),(foot_x+1,-4+foot_y)],11 if front else 10,2)
 poly(im,[(foot_x-2,bottom-3),(foot_x+2,bottom-3),(foot_x+5,bottom-1),
          (foot_x-2,bottom-1)],10 if front else 8)
 line(im,[(foot_x-1,bottom-2),(foot_x+2,bottom-2)],48 if front else 10,2)
 return rig.clean(im)

def make_parts():
 original={name:Image.open(rig.ART/'partes'/f'{name}.png').convert('RGBA')
           for name in ('corpo','capuz_cabeca','manto_musgo','braco_tras','braco_cajado')}
 parts=dict(original)
 # Shorter moving hem reveals both knees/feet; source master stays untouched.
 parts['manto_marcha']=trim(original['manto_musgo'],44)
 parts['corpo_marcha']=trim(original['corpo'],39)
 parts['cabeca_legivel']=original['capuz_cabeca'].copy()
 weapon=np.array(original['braco_cajado']);bells=np.zeros_like(weapon)
 bells[28:44,42:]=weapon[28:44,42:];weapon[28:44,42:]=0
 parts['cajado_sem_sinos']=Image.fromarray(weapon)
 parts['sinos']=Image.fromarray(bells)
 # Preserve the actual hood and bone face; only a small NN rig rotation.
 parts['capuz_queda']=parts['cabeca_legivel'].rotate(-20,Image.Resampling.NEAREST,
                                                           center=(27,22),expand=False)
 for i in range(8):
  parts[f'perna_frente_{i}']=leg(FEET_X[i],FEET_Y[i],True,BOB[i])
  n=(i+4)%8;parts[f'perna_tras_{i}']=leg(FEET_X[n],FEET_Y[n],False,BOB[i])
 for name in ('manto_marcha','corpo_marcha','cabeca_legivel','cajado_sem_sinos','sinos','capuz_queda'):
  p=ART/'partes'/f'{name}.png';p.parent.mkdir(parents=True,exist_ok=True);parts[name].save(p)
 for name in (f'perna_{side}_{i}' for side in ('frente','tras') for i in range(8)):
  parts[name].save(ART/'partes'/f'{name}.png')
 return parts

def march(parts,k,lean):
 prev=(k-1)%8;bob=BOB[k];im=rig.blank()
 im.alpha_composite(leg(FEET_X[(k+4)%8],FEET_Y[(k+4)%8],False,bob,lean))
 offset(im,parts['braco_tras'],lean,bob)
 offset(im,parts['manto_marcha'],lean+SWAY[prev],BOB[prev])
 offset(im,parts['corpo_marcha'],lean,bob)
 im.alpha_composite(leg(FEET_X[k],FEET_Y[k],True,bob,lean))
 offset(im,parts['cabeca_legivel'],lean,bob)
 held_staff(im,parts,lean,bob,lean+SWAY[prev],BOB[prev])
 return rig.clean(im)

def kneeling(parts,lean,drop,secondary_drop,secondary_lean):
 im=rig.blank()
 # Replacement bent legs beneath a folded robe, all above the foot anchor.
 poly(im,[(-12,-14),(-4,-15),(1,-8),(8,-6),(10,-1),(-14,-1)],3)
 poly(im,[(-10,-12),(-5,-12),(-1,-6),(6,-5),(7,-3),(-11,-3)],8)
 line(im,[(-8,-5),(-2,-3),(4,-3)],48,2)
 offset(im,trim(parts['manto_musgo'],max(30,52-secondary_drop-2)),secondary_lean,secondary_drop)
 poly(im,[(lean-10,-28+drop),(lean+4,-29+drop),(lean+12,-10),
          (lean+10,-3),(lean-5,-3),(lean-16,-9)],3)
 poly(im,[(lean-8,-25+drop),(lean+3,-25+drop),(lean+8,-10),
          (lean+6,-5),(lean-4,-5),(lean-12,-10)],8)
 poly(im,[(lean-3,-24+drop),(lean+2,-23+drop),(lean+5,-11),
          (lean+1,-6),(lean-5,-9)],10)
 line(im,[(lean-1,-23+drop),(lean+2,-14),(lean+3,-8)],11,2)
 # The original olive back remains a substantial cluster when kneeling.
 poly(im,[(lean-16,-23+drop),(lean-11,-26+drop),(lean-7,-16),
          (lean-12,-7),(lean-20,-6),(lean-20,-13)],47)
 poly(im,[(lean-15,-20+drop),(lean-11,-21+drop),(lean-10,-14),
          (lean-15,-9),(lean-18,-11)],49)
 line(im,[(lean-14,-17),(lean-15,-12)],51,3)
 offset(im,parts['braco_tras'],lean,drop)
 held_staff(im,parts,lean,drop,secondary_lean,secondary_drop)
 # Head last: cloth/arm can never obscure the skull or the hood rim.
 offset(im,parts['cabeca_legivel'],lean,drop)
 a=np.array(im);a[AY:]=0
 return rig.clean(Image.fromarray(a))

def staff_alone(y=-5,lag=0):
 im=rig.blank()
 line(im,[(48,y),(81,y-2)],3,5)
 line(im,[(49,y),(81,y-2)],46,3)
 line(im,[(50,y-1),(79,y-3)],48,1)
 poly(im,[(76,y-5),(83,y-5),(86,y-2),(83,y),(76,y)],3)
 poly(im,[(77,y-4),(82,y-4),(84,y-2),(81,y-1),(77,y-1)],49)
 line(im,[(78,y-3),(81,y-3)],51,2)
 for x in (75+lag,83+lag):
  top=y+1
  line(im,[(x,y-1),(x,top)],3,2)
  poly(im,[(x-2,top),(x+1,top),(x+3,top+3),(x-3,top+3)],3)
  poly(im,[(x-1,top+1),(x+1,top+1),(x+1,top+2),(x-1,top+2)],56)
 im=trim(im,AY)
 return rig.clean(im)

def fallen(parts,x,bottom,staff_y,lag,settle):
 body=rig.blank()
 # Folded cloth uses dark standing browns, avoiding broad pink highlights.
 poly(body,[(-23,-4),(-19,-12),(-9,-16),(5,-16),(21,-11),
            (29,-6),(24,-1),(-20,-1)],3)
 poly(body,[(-20,-5),(-16,-10),(-8,-13),(5,-13),(20,-9),
            (23,-5),(16,-3),(-17,-3)],8)
 poly(body,[(-13,-10),(-4,-11),(9,-10),(16,-6),(7,-5),(-9,-6)],10)
 line(body,[(-8,-9),(1,-8),(10,-6)],11,2)
 # Former back moss sprawls over the corpse, distinct olive clusters.
 poly(body,[(-23,-4),(-21,-10),(-16,-14),(-9,-12),(-7,-6),
            (-14,-2),(-21,-2)],47)
 poly(body,[(-20,-8),(-16,-12),(-12,-10),(-13,-5),(-18,-4)],49)
 line(body,[(-16,-10),(-16,-6)],51,3)
 poly(body,[(-7,-11),(-3,-13),(1,-12),(3,-8),(-2,-6),(-8,-7)],47)
 line(body,[(-3,-11),(-1,-9)],49,3)
 # Hood/skull replacement is the real cleaned head turned just 20 degrees.
 head=parts['capuz_queda'];box=head.getbbox();head=head.crop(box)
 body.alpha_composite(head,(AX+x-head.width//2,AY+bottom-head.height))
 # The boot behind the cloth remains recognizable.
 line(body,[(-20,-3),(-25,-3)],48,3)
 body=rig.clean(body)
 staff=staff_alone(staff_y,lag)
 if settle:staff.save(ART/'partes/cajado_solto.png');body.save(ART/'partes/corpo_caido.png')
 body.alpha_composite(staff)
 return rig.clean(body,main=False)

def poses(name):
 if name in ('patrulha','perseguicao'):
  return [{'gait':i,'lean':3 if name=='perseguicao' else 0,'bob':BOB[i],
           'pe_frente':[FEET_X[i],FEET_Y[i]],'pe_tras':[FEET_X[(i+4)%8],FEET_Y[(i+4)%8]],
           'secundario_quadro':(i-1)%8,'manto_sinos_sway':SWAY[(i-1)%8],
           'manto_sinos_bob':BOB[(i-1)%8]} for i in range(8)]
 if name=='ruptura':
  return [{'lean':x,'drop':y} for x,y in [(-3,2),(-4,6),(-3,10),(-3,12),(-2,13),(-3,12),(-3,13)]]
 return [{'lean':-3,'drop':3},{'lean':1,'drop':12},{'lean':8,'drop':17}]+[
  {'fallen':True,'head_x':x,'head_bottom':b,'staff_y':sy,'bell_lag':lag}
  for x,b,sy,lag in [(20,-6,-15,-1),(26,-1,-6,0),(27,-1,-8,1),(27,-1,-5,0),(27,-1,-5,0)]]

def build(apply=False):
 parts=make_parts();manifest=json.loads((rig.PACK/'manifesto_sprites.json').read_text(encoding='utf-8'))
 allposes={};specs={}
 for anim in manifest['animacoes']:
  name=anim['id']
  if name not in TARGETS:continue
  pp=poses(name);allposes[name]=pp;frames=[]
  for i,p in enumerate(pp):
   previous=pp[i-1] if name=='ruptura' else pp[max(0,i-1)]
   if 'gait' in p:im=march(parts,i,p['lean'])
   elif p.get('fallen'):im=fallen(parts,p['head_x'],p['head_bottom'],p['staff_y'],p['bell_lag'],i==7)
   else:im=kneeling(parts,p['lean'],p['drop'],previous.get('drop',0),previous.get('lean',0))
   target=ART/'quadros'/f'{name}_f{i:02d}.png';target.parent.mkdir(exist_ok=True);im.save(target)
   if apply:
    path=rig.PACK/anim['quadros'][i]['arquivo'];im.save(path);anim['quadros'][i]['sha256']=rig.sha(path)
   frames.append(im)
  # All comparisons use identical canvas, scale and gray background.
  gifs=[];folder=OUT/'depois_gifs_x4';folder.mkdir(parents=True,exist_ok=True)
  for im in frames:
   bg=Image.new('RGBA',im.size,(96,96,96,255));bg.alpha_composite(im)
   gifs.append(bg.resize((rig.W*4,rig.H*4),Image.Resampling.NEAREST).convert('RGB'))
  gifs[0].save(folder/f'{name}_x4.gif',save_all=True,append_images=gifs[1:],
               duration=[q['ms'] for q in anim['quadros']],loop=0,disposal=2,optimize=False)
  # Compact sheet retains native pixels and provides frame numbers.
  box=(22,32,149,92) if name=='morte' else (22,32,119,92)
  cw,ch=box[2]-box[0],box[3]-box[1]
  sheet=Image.new('RGB',(cw*4*4,(ch*4+20)*math.ceil(len(frames)/4)),(96,96,96));d=ImageDraw.Draw(sheet)
  for i,im in enumerate(frames):
   tile=Image.new('RGBA',(cw,ch),(96,96,96,255));tile.alpha_composite(im.crop(box))
   sheet.paste(tile.resize((cw*4,ch*4),Image.Resampling.NEAREST),(i%4*cw*4,i//4*(ch*4+20)+20))
   d.text((i%4*cw*4+8,i//4*(ch*4+20)+4),str(i),fill='white')
  sheet.save(ART/f'{name}_quadros_x4.png')
 for p in sorted((ART/'partes').glob('*.png')):
  specs[p.stem]={'arquivo':p.relative_to(ART).as_posix(),'sha256':rig.sha(p),
                 'pivo':[AX,AY-18] if Image.open(p).width==rig.W else [27,22]}
 save(ART/'poses.json',allposes)
 save(ART/'rig.json',{'gerador':'arte_fonte/ferramentas/ajustar_peregrino_47b.py','partes':specs,
       'marcha':'pes alternados, 4 px/quadro; manto/musgo/sinos usam quadro anterior',
       'queda':'joelhos -> frente; capuz/rosto originais, rotacao NEAREST de 20 graus; cajado SEM braco separado',
       'componentes_morte':'um corpo principal + um cajado solto; nenhum pixel solto'})
 if apply:save(rig.PACK/'manifesto_sprites.json',manifest)
 print({'aplicado':apply,'animacoes':4,'quadros':31})

def verify():
 data=json.loads((rig.PACK/'manifesto_sprites.json').read_text(encoding='utf-8'))
 before=json.loads((OUT/'MANIFESTO_antes.json').read_text(encoding='utf-8'))
 def normalize(m):
  m=copy.deepcopy(m)
  for anim in m['animacoes']:
   if anim['id'] in TARGETS:
    for q in anim['quadros']:q['sha256']='ART_ONLY'
  return m
 assert normalize(data)==normalize(before),'Contrato alterado alem dos hashes das quatro animacoes'
 checks=[]
 standing_colors=set(np.unique(rig.indices(Image.open(rig.ART/'mestre_limpo_x1.png'))))
 for anim in data['animacoes']:
  for i,q in enumerate(anim['quadros']):
   path=rig.PACK/q['arquivo'];im=Image.open(path);a=rig.indices(im);comp=rig.components(a>=0)
   isolated=int(np.count_nonzero((a>=0)&~np.any(rig.neighbors(a)==a,axis=0)))
   assert rig.sha(path)==q['sha256'] and im.size==(rig.W,rig.H) and q['ancora']==rig.ANCHOR
   expected=2 if anim['id']=='morte' and i>=3 else 1
   assert len(comp)==expected and isolated==0,(path.name,len(comp),isolated)
   assert (q['hitbox'] is not None)==(q['fase']=='ACTIVE')
   if anim['id'] in TARGETS:
    assert np.array(im)[AY:,:,3].sum()==0,'Pixels abaixo do chao'
    # No newly invented corpse colors; feet reuse existing master steel.
    assert set(np.unique(a))<=standing_colors,(path.name,set(np.unique(a))-standing_colors)
    checks.append({'arquivo':q['arquivo'],'componentes':len(comp),'pixels_isolados':isolated,
                   'osso_claro_px':int(np.count_nonzero(np.isin(a,[17,57]))),
                   'musgo_px':int(np.count_nonzero(np.isin(a,[45,47,49,51])))})
    assert checks[-1]['osso_claro_px']>=8 and checks[-1]['musgo_px']>=15
   for extra in q['efeitos']+[anim['sombra']]:assert rig.sha(rig.PACK/extra['arquivo'])==extra['sha256']
 measurements={}
 for name in ('patrulha','perseguicao'):
  pp=poses(name);assert pp[0]['pe_frente'][0]>pp[0]['pe_tras'][0]
  assert pp[4]['pe_frente'][0]<pp[4]['pe_tras'][0]
  for i,p in enumerate(pp):assert p['secundario_quadro']==(i-1)%8
  anim=next(a for a in data['animacoes'] if a['id']==name)
  assert anim['px_por_quadro']==4 and len(set(q['sha256'] for q in anim['quadros']))==8
  # Measure actual visible pixels, rather than only trusting pose parameters.
  samples={}
  for i in (0,1,4,6):
   a=rig.indices(Image.open(rig.PACK/anim['quadros'][i]['arquivo']))
   yy=np.indices(a.shape)[0]
   ys,xs=np.nonzero((a==48)&(yy>=AY-12))
   assert len(xs)>=6,'Borda do pe perdeu leitura'
   samples[i]={'pe_frente_x_px':float(np.median(xs)-AX),'pe_frente_y_px':int(ys.max()-AY),
               'rosto_y_px':float(np.median(np.nonzero(np.isin(a,[17,57]))[0])-AY)}
  assert samples[0]['pe_frente_x_px']-samples[4]['pe_frente_x_px']>=14
  assert samples[0]['pe_frente_y_px']==samples[4]['pe_frente_y_px']==-2
  assert samples[6]['pe_frente_y_px']<=-7,'Pe nao levanta durante a passagem'
  assert samples[1]['rosto_y_px']-samples[0]['rosto_y_px']==1,'Corpo perdeu oscilacao de 1 px'
  measurements[name]=samples
  save(OUT/'VERIFICACAO_ARTE_47B.json',{'contrato_integral_preservado':True,'marchas_8_quadros_distintos':True,
       'cadencia_px_por_quadro':4,'cores_apenas_da_arte_em_pe':True,'quadros':checks,'medidas_raster_marcha':measurements})
 print({'contrato_preservado':True,'quadros_ajustados':len(checks),'marchas_distintas':True})

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--preview',action='store_true');p.add_argument('--apply',action='store_true');p.add_argument('--verify',action='store_true');args=p.parse_args()
 if args.verify:verify()
 else:build(args.apply)
