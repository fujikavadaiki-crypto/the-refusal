"""4.8b4: one static, hand-authored leg silhouettes; no animation export."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('human48b_readonly',ROOT/'arte_fonte/ferramentas/animar_forma_humana_48b.py')
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
import numpy as np
from PIL import Image,ImageDraw
from kitrig import Rig
from kitrig.desenho import componentes,_vizinhos
from scipy import ndimage as ndi
ART=ROOT/'arte_fonte/forma_humana_v1/poses_chave_48b4'
OUT=ROOT/'codex/evidencias_forma_humana_48b4'
SOURCE=ROOT/'arte_fonte/forma_humana_v1/poses_chave_48b3'
ORIGINAL=ROOT/'arte_fonte/forma_humana_v1/rig_48b1'
PAL=B.PAL;T=B.TEMPLATE;AX,AY=B.AX,B.AY
KEYS=(0,)
BODY=['braco_distante','capa','tronco','capuz','cabeca_cabelo','braco_proximo','mao_espada']
# Authored pixel rows, not a tube mesh or vertical source cut-outs.
# x/start and each palette symbol determine the complete visible volume.
SUPPORT_FORWARD=[
 (41,42,'##bbmm#'),(42,42,'#bbmll#'),(43,42,'#sbmll#'),
 (44,43,'#sbmll#'),(45,44,'#sbmll#'),(46,45,'#sbmll#'),
 (47,46,'#sbmlm#'),(48,46,'#sbmll#'),(49,47,'#sbbml#'),
 (50,48,'#ccmm#'),(51,48,'#cmlm#'),(52,48,'#bmlm#'),
 (53,48,'#bbmmm#'),(54,48,'#ssbmll##'),(55,48,'#########')]
# The short thigh ends midway between hip and ground; the shin returns
# diagonally to the raised heel. This replaces the low, hanging 4.8b3 knee.
FOLDED_TROUSERS=[
 (41,38,'##bbmm#'),(42,38,'#bbmll#'),(43,38,'#sbmll#'),
 (44,39,'#bmll#'),(45,39,'#bmll#'),(46,38,'#bml#'),
 (47,37,'#bmlm#'),(48,37,'#bmlm#'),(49,39,'###'),
 (44,32,'#bm#'),(45,34,'#ml#'),(46,35,'#ml#'),
 (47,37,'#mm#')]
# Separate authored boot: cuff/shaft above, short toe below and a 7 px sole.
# It is not a horizontal extension of the shin. Some shaft pixels remain
# naturally covered by the unchanged cape.
FOLDED_BOOT=[
 (43,32,'##cc#'),(44,31,'#cmm#'),(45,31,'#bml#'),
 (46,30,'#bmlm#'),(47,29,'#bbmll#'),(48,29,'#sbmll#'),
 (49,29,'#######')]
NEAR={'#':3,'s':7,'b':8,'m':11,'l':13,'c':10}
FAR={'#':3,'s':5,'b':7,'m':8,'l':11,'c':10}
DESIGNS={
 0:[('frente',SUPPORT_FORWARD,0,[44,43],[49,48],[50,50],[52,55]),
    ('tras',FOLDED_TROUSERS+FOLDED_BOOT,0,[41,43],[39,48],[33,44],[32,49])],
}

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,obj):
 p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def idx(p):return PAL.de_rgba(np.array(Image.open(p).convert('RGBA')),estrito=True)
def png(p,a):p.parent.mkdir(parents=True,exist_ok=True);B.image(a).save(p)
def authored_rows():
 frames={}
 for k,legs in DESIGNS.items():
  frames[str(k)]=[{'perna':side,'quadril':hip,'joelho':knee,'tornozelo':ankle,'ponto_sola':sole,
    'linhas_bota':[[y,x+dx,text] for y,x,text in (FOLDED_BOOT if rows is not SUPPORT_FORWARD else SUPPORT_FORWARD[-6:])],
    'caixa_bota':[sole[0]-4,sole[1]-6,sole[0]+6,sole[1]+1],
    'paleta':NEAR if side=='frente' else FAR,'linhas':[[y,x+dx,text] for y,x,text in rows]}
    for side,rows,dx,hip,knee,ankle,sole in legs]
 return {'quadro_mestre_sha256':B.EXPECTED,'quadros_propostos':[0],
   'autoria':'linhas de pixels por pose; variantes inteiras de perna e bota','poses':frames}
def paint(leg):
 a=np.full(T.shape,-1,int)
 for y,x,text in leg['linhas']:
  for j,ch in enumerate(text):
   if ch!='.':a[y,x+j]=leg['paleta'][ch]
 for x,y,color in leg.get('encaixes_raiz',[]):a[y,x]=color
 for x,y,color in leg.get('ajustes_cor',[]):a[y,x]=color
 return a
def body_mask(rig,pose):return rig.renderizar(T.nova(),pose,ordem=BODY).a>=0
def compose(rig,pose,parts,k):
 old=idx(SOURCE/f'quadros/run_f{k}.png');fixed=body_mask(rig,pose)
 a=np.full(T.shape,-1,int)
 for side in ('tras','frente'):
  layer=parts[side];a[layer>=0]=layer[layer>=0]
 a[fixed]=old[fixed]
 return a,fixed

def clean_colors(rig,pose,parts,k):
 """Keep the silhouette; merge one-pixel colour noise only on visible legs."""
 initial={side:a.copy() for side,a in parts.items()};locked=np.zeros(T.shape,bool)
 for _ in range(24):
  a,fixed=compose(rig,pose,parts,k)
  iso=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
  if not iso.any():break
  changed=False
  def setpixel(x,y,color):
   side='frente' if parts['frente'][y,x]>=0 else 'tras'
   parts[side][y,x]=color
  for y,x in sorted(zip(*np.where(iso)),key=lambda p:0 if fixed[p] else 1):
   neighbors=[(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1)
    if (dx or dy) and 0<=y+dy<64 and 0<=x+dx<96 and a[y+dy,x+dx]>=0]
   if fixed[y,x] or locked[y,x]:
    choices=[p for p in neighbors if not fixed[p] and not locked[p]]
    if choices:
     yy,xx=min(choices,key=lambda p:abs(int(a[p])-int(a[y,x])))
     setpixel(xx,yy,int(a[y,x]));locked[yy,xx]=True;changed=True
   else:
    from collections import Counter
    if neighbors:
     color=Counter(int(a[p]) for p in neighbors).most_common(1)[0][0]
     setpixel(x,y,color);changed=True
  if not changed:break
 return {side:[[int(x),int(y),int(parts[side][y,x])] for y,x in zip(*np.where(parts[side]!=initial[side]))] for side in parts}

def generate():
 assert sha(B.MASTER)==B.EXPECTED
 rig=Rig.carregar(B.ART/'rig.json',PAL)
 oldposes=json.loads((ORIGINAL/'poses.json').read_text(encoding='utf-8'))
 rows=authored_rows()
 poses={'somente_propostas_estaticas':True,'quadros_propostos':list(KEYS),'poses':[]}
 rigdata=json.loads((B.ART/'rig.json').read_text(encoding='utf-8'))
 for p in rigdata['partes'].values():p['arquivo']='../rig_48b/'+p['arquivo']
 rigdata['revisao']='4.8b4: somente f0; joelho intermediário, flexão curta e pé elevado reposicionado'
 rigdata['mestre_sha256']=B.EXPECTED
 for k in KEYS:
  original=oldposes['run'][k];parts={};legs=rows['poses'][str(k)]
  for leg in legs:
   leg['encaixes_raiz']=[[36,42,3],[40,43,44],[28,48,10]] if leg['perna']=='tras' else []
   parts[leg['perna']]=paint(leg)
  # Preserve the complete supporting leg from 4.8b3, including its shading.
  parts['frente']=idx(SOURCE/f'variantes/perna_frente_f{k}.png')
  corrections=clean_colors(rig,original['pose_rig'],parts,k)
  assert np.array_equal(parts['frente'],idx(SOURCE/f'variantes/perna_frente_f{k}.png')),'Supporting leg pixels changed'
  for leg in legs:
   side=leg['perna'];leg['ajustes_cor']=corrections[side];a=parts[side];name=f'perna_{side}_f{k}'
   if side=='frente':
    leg['ajustes_cor']=[[int(x),int(y),int(a[y,x])] for y,x in zip(*np.where(a!=paint(leg)))]
   path=ART/f'variantes/{name}.png';png(path,a)
   rigdata['partes'][name]={'arquivo':path.relative_to(ART).as_posix(),'pivo':leg['quadril'],
    'variante':True,'variante_de':'coxa_'+side,'sha256':sha(path),
    'articulacoes':{n:leg[n] for n in ('quadril','joelho','tornozelo','ponto_sola')}}
  a,fixed=compose(rig,original['pose_rig'],parts,k);png(ART/f'quadros/run_f{k}.png',a)
  masks=ART/'mascaras';masks.mkdir(exist_ok=True)
  old=idx(SOURCE/f'quadros/run_f{k}.png');legarea=((old>=0)|(a>=0))&~fixed
  Image.fromarray((fixed*255).astype(np.uint8)).save(masks/f'corpo_protegido_f{k}.png')
  Image.fromarray((legarea*255).astype(np.uint8)).save(masks/f'pernas_botas_f{k}.png')
  Image.fromarray((np.any(PAL.para_rgba(old)!=PAL.para_rgba(a),axis=2)*255).astype(np.uint8)).save(masks/f'diferenca_f{k}.png')
  poses['poses'].append({'quadro':k,'pose_corpo_original':original['pose_rig'],
   'capa_origem_quadro':original['capa_origem_quadro'],'pernas':[
    {'perna':l['perna'],'variante':f'perna_{l["perna"]}_f{k}',
     'transformacao':{'parte_base':'coxa_'+l['perna'],
       'dx':l['quadril'][0]-AX-(rig.partes['coxa_'+l['perna']].pivo_mestre[0]-B.MX),
       'dy':l['quadril'][1]-AY-(rig.partes['coxa_'+l['perna']].pivo_mestre[1]-B.MY),'ang':0},
     'articulacoes':{n:l[n] for n in ('quadril','joelho','tornozelo','ponto_sola')},
     'pe_historico_48b':original['pernas'][j]['pe'],'fase_original':original['pernas'][j]['fase'],
    'apoio_original':original['pernas'][j]['apoio'],
    'sola_48b3':next(p for p in json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['poses'] if p['quadro']==k)['pernas'][j]['articulacoes']['ponto_sola'],
    'deslocamento_sola_48b3':[l['ponto_sola'][axis]-next(p for p in json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['poses'] if p['quadro']==k)['pernas'][j]['articulacoes']['ponto_sola'][axis] for axis in (0,1)],
    'articulacoes_48b3':next(p for p in json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['poses'] if p['quadro']==k)['pernas'][j]['articulacoes'],
    'diferencas_articulacoes':{n:[l[n][axis]-next(p for p in json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))['poses'] if p['quadro']==k)['pernas'][j]['articulacoes'][n][axis] for axis in (0,1)] for n in ('quadril','joelho','tornozelo','ponto_sola')}} for j,l in enumerate(legs)]})
 save(ART/'desenhos_pixels.json',rows);save(ART/'poses.json',poses);save(ART/'rig.json',rigdata)
 save(ART/'REFERENCIA_MOVIMENTO.json',{'nao_e_manifesto_de_animacao':True,
  'referencia':'../rig_48b/contrato_ciclos.json','sha256':sha(B.ART/'contrato_ciclos.json'),
  'quadros_do_ciclo_preservado':8,'ms_por_quadro':41.67,'px_por_quadro':6,
  'velocidades_humanas_preservadas':B.human_speeds(),'animacoes_geradas':False})

def evidence():
 old=[idx(SOURCE/f'quadros/run_f{k}.png') for k in KEYS]
 new=[idx(ART/f'quadros/run_f{k}.png') for k in KEYS]
 sheet=Image.new('RGB',(224,104),(96,96,96));d=ImageDraw.Draw(sheet)
 for i,k in enumerate(KEYS):
  for j,a in enumerate((old[i],new[i])):
   sheet.paste(B.gray(a).convert('RGB'),(i*224+j*104+8,26))
   d.text((i*224+j*104+8,8),f'f{k}: '+('4.8b3' if j==0 else 'PROPOSTA'),font=B.textfont(11),fill='white')
  d.line((i*224+216,5,i*224+216,98),fill='#858585')
 sheet.save(OUT/'COMPARACAO_COMPLETA_x1.png')
 sheet.resize((896,416),Image.Resampling.NEAREST).save(OUT/'COMPARACAO_COMPLETA_x4.png')
 for k,a in zip(KEYS,new):
  B.gray(a).convert('RGB').save(OUT/f'PROPOSTA_f{k}_x1.png')
  B.gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB').save(OUT/f'PROPOSTA_f{k}_x4.png')
 master=Image.open(B.MASTER).convert('RGBA');gray=Image.new('RGBA',master.size,(96,96,96,255));gray.alpha_composite(master)
 detail=Image.new('RGB',(2*288,3*175+10),(96,96,96));d=ImageDraw.Draw(detail)
 detail.paste(gray.crop((6,31,42,51)).resize((288,160),Image.Resampling.NEAREST).convert('RGB'),(0,24))
 d.text((8,5),'MESTRE APROVADO ×8',font=B.textfont(14),fill='white')
 for i,k in enumerate(KEYS,1):
  for j,a in enumerate((old[i-1],new[i-1])):
   detail.paste(B.gray(a).crop((24,37,60,57)).resize((288,160),Image.Resampling.NEAREST).convert('RGB'),(i*288,j*175+24))
   d.text((i*288+8,j*175+5),f'f{k} / '+('4.8b3' if j==0 else 'PROPOSTA'),font=B.textfont(14),fill='white')
  mask=np.array(Image.open(ART/f'mascaras/diferenca_f{k}.png'))>0
  a=B.gray(new[i-1]);overlay=np.zeros((64,96,4),np.uint8);overlay[mask]=(70,230,160,180)
  a.alpha_composite(Image.fromarray(overlay))
  detail.paste(a.crop((24,37,60,57)).resize((288,160),Image.Resampling.NEAREST).convert('RGB'),(i*288,374))
  d.text((i*288+8,355),'ALTERAÇÕES / PERNAS E BOTAS',font=B.textfont(13),fill='white')
 detail.save(OUT/'PERNAS_MESTRE_ANTES_PROPOSTA.png')
 poses=json.loads((ART/'poses.json').read_text(encoding='utf-8'))
 joints=Image.new('RGB',(384,396),(55,55,55));d=ImageDraw.Draw(joints)
 for i,row in enumerate(poses['poses']):
  k=row['quadro'];a=B.gray(new[i]).resize((384,256),Image.Resampling.NEAREST).convert('RGB')
  joints.paste(a,(i*384,25));d.text((i*384+8,4),f'f{k} / ARTICULAÇÕES (FOLHA AUXILIAR)',font=B.textfont(14),fill='white')
  for leg in reversed(row['pernas']):
   color='#f3bd68' if leg['perna']=='frente' else '#77ddd6'
   points=[(i*384+leg['articulacoes'][n][0]*4+2,25+leg['articulacoes'][n][1]*4+2) for n in ('quadril','joelho','tornozelo','ponto_sola')]
   d.line(points,fill=color,width=2)
   for pt in points:d.ellipse((pt[0]-3,pt[1]-3,pt[0]+3,pt[1]+3),fill=color)
   if not leg['apoio_original']:
    x,y=leg['sola_48b3'];x=i*384+x*4+2;y=25+y*4+2
    d.rectangle((x-3,y-3,x+3,y+3),outline='white',width=1)
    x,y=leg['articulacoes_48b3']['joelho'];x=i*384+x*4+2;y=25+y*4+2
    d.ellipse((x-3,y-3,x+3,y+3),outline='white',width=1)
  d.text((i*384+8,282),'AMARELO: próxima / CIANO: distante',font=B.textfont(13),fill='white')
  d.text((i*384+8,306),'Quadril → joelho → tornozelo → sola',font=B.textfont(13),fill='white')
  raised=next(l for l in row['pernas'] if not l['apoio_original'])
  d.text((i*384+8,329),f'Sola elevada: {raised["sola_48b3"]} → {raised["articulacoes"]["ponto_sola"]}',font=B.textfont(13),fill='white')
  d.text((i*384+8,351),f'Joelho: {raised["articulacoes_48b3"]["joelho"]} → {raised["articulacoes"]["joelho"]}',font=B.textfont(13),fill='white')
  d.text((i*384+8,373),'Branco: círculo = joelho / quadrado = sola antigos',font=B.textfont(12),fill='white')
 joints.save(OUT/'ARTICULACOES_AUXILIAR.png')

def verify():
 assert sha(B.MASTER)==B.EXPECTED
 rig=Rig.carregar(B.ART/'rig.json',PAL);saved=Rig.carregar(ART/'rig.json',PAL)
 rigdata=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
 assert np.array_equal(PAL.para_rgba(saved.renderizar(B.Tela(50,52,B.MX,B.MY),{}).a),np.array(Image.open(B.MASTER)))
 poses=json.loads((ART/'poses.json').read_text(encoding='utf-8'))
 designs=json.loads((ART/'desenhos_pixels.json').read_text(encoding='utf-8'))
 original=json.loads((ORIGINAL/'poses.json').read_text(encoding='utf-8'))['run']
 checks=[]
 assert [r['quadro'] for r in poses['poses']]==list(KEYS)
 assert sorted(p.name for p in (ART/'quadros').glob('*.png'))==[f'run_f{k}.png' for k in KEYS]
 assert not any(p.suffix.lower() in ('.gif','.mp4','.webm','.avi') for folder in (ART,OUT) for p in folder.rglob('*'))
 reference=json.loads((ART/'REFERENCIA_MOVIMENTO.json').read_text(encoding='utf-8'))
 prior_contract=json.loads((B.ART/'contrato_ciclos.json').read_text(encoding='utf-8'))
 prior_preview=json.loads((ROOT/'codex/evidencias_forma_humana_48b1/PREVIA_DESLOCAMENTO.json').read_text(encoding='utf-8'))
 assert reference['sha256']==sha(B.ART/'contrato_ciclos.json')
 assert reference['velocidades_humanas_preservadas']==prior_preview['velocidades']
 assert prior_contract['animacoes'][1]['px_por_quadro']==reference['px_por_quadro']==6
 assert len(prior_contract['animacoes'][1]['quadros'])==reference['quadros_do_ciclo_preservado']==8
 assert all(q['ms']==reference['ms_por_quadro'] for q in prior_contract['animacoes'][1]['quadros'])
 for row in poses['poses']:
  k=row['quadro'];orig=original[k]
  assert row['pose_corpo_original']==orig['pose_rig'] and row['capa_origem_quadro']==orig['capa_origem_quadro']
  parts={}
  for l in row['pernas']:
   transform=l['transformacao']
   parts[l['perna']]=saved.desenhar_parte(T,transform['parte_base'],transform['dx'],transform['dy'],ang=0,variante=l['variante'])
   authored=next(p for p in designs['poses'][str(k)] if p['perna']==l['perna'])
   assert np.array_equal(parts[l['perna']],paint(authored)),'Registered variant/pivot replay differs'
  replay,fixed=compose(rig,row['pose_corpo_original'],parts,k)
  a=idx(ART/f'quadros/run_f{k}.png');old=idx(SOURCE/f'quadros/run_f{k}.png')
  assert np.array_equal(a,replay)
  rgba=np.array(Image.open(ART/f'quadros/run_f{k}.png'));oldrgba=np.array(Image.open(SOURCE/f'quadros/run_f{k}.png'))
  assert set(np.unique(rgba[...,3]))=={0,255}
  assert np.array_equal(rgba[fixed],oldrgba[fixed])
  area=np.array(Image.open(ART/f'mascaras/pernas_botas_f{k}.png'))>0
  diff=np.any(rgba!=oldrgba,axis=2);assert not (diff&~area).any()
  assert not (area&fixed).any() and not (a[AY:]>=0).any()
  # Leg-only canvas region is checked independently of the difference mask.
  window=np.zeros(T.shape,bool);window[41:56,24:58]=True
  assert not (diff&~window).any(),'Edit exceeds anatomical leg/boot region'
  beforeparts=[idx(SOURCE/f'variantes/perna_{side}_f{k}.png') for side in ('tras','frente')]
  allowed=(beforeparts[0]>=0)|(beforeparts[1]>=0)|(parts['tras']>=0)|(parts['frente']>=0)
  assert not (diff&~allowed).any(),'Edited pixel has no leg/boot provenance'
  for j,l in enumerate(row['pernas']):
   side=l['perna'];leg=designs['poses'][str(k)][j];p=saved.partes[l['variante']]
   assert np.array_equal(p.idx,parts[side])
   assert sha(ART/f'variantes/{l["variante"]}.png')==rigdata['partes'][l['variante']]['sha256']
   assert all(isinstance(v,int) for points in l['articulacoes'].values() for v in points)
   assert l['articulacoes']['quadril']==[AX+orig['pernas'][j]['quadril'][0],AY+orig['pernas'][j]['quadril'][1]]
   sole=l['articulacoes']['ponto_sola'];oldleg=orig['pernas'][j]
   oldsole=l['articulacoes_48b3']['ponto_sola']
   assert oldsole==l['sola_48b3']
   delta=[sole[i]-oldsole[i] for i in (0,1)]
   assert delta==l['deslocamento_sola_48b3']
   if l['apoio_original']:
    assert delta==[0,0] and sole[1]==55,'Supporting sole moved'
   else:
    q,joint,ankle=[l['articulacoes'][n] for n in ('quadril','joelho','tornozelo')]
    assert joint[1]>q[1] and joint[1]>ankle[1],'Thigh must descend; shin must return to raised heel'
    assert q[1]+3<=joint[1]<=55-6,'Knee must stay intermediate, above supporting boot'
    assert joint[0]>ankle[0] and joint[1]-ankle[1]>=3,'Shin must be diagonal, not a horizontal bar'
    assert np.linalg.norm(np.array(q)-joint)<=7 and np.linalg.norm(np.array(joint)-ankle)<=8,'Apparent segments too long for master'
    assert not (parts[side][50:]>=0).any(),'Folded leg hangs into supporting-boot region'
   assert l['articulacoes']['quadril']==l['articulacoes_48b3']['quadril']
   if side=='frente':assert np.array_equal(parts[side],idx(SOURCE/f'variantes/perna_frente_f{k}.png'))
   assert l['pe_historico_48b']==oldleg['pe'] and l['fase_original']==oldleg['fase'] and l['apoio_original']==oldleg['apoio']
   assert parts[side][sole[1],sole[0]]>=0
   boot=paint({'linhas':leg['linhas_bota'],'paleta':leg['paleta']})
   bootrow=boot[sole[1]];xs=np.where(bootrow>=0)[0]
   assert (int(xs.min())+int(xs.max()))/2==sole[0],'Sole contact centre changed'
   assert not (boot[sole[1]+1:]>=0).any(),'Boot extends below registered sole'
   # A boot's sole bounds only that boot. The intermediate knee is checked
   # independently; its position is not forced below the raised foot.
   assert not (parts[side][56:]>=0).any()
  n,sizes=componentes(a)
  isolated=int(((a>=0)&~np.any(_vizinhos(a)==a,axis=0)).sum())
  assert n==1 and isolated==0,(k,n,isolated)
  checks.append({'quadro':k,'pixels_alterados':int(diff.sum()),'pixels_do_corpo_alterados':0,
   'pixels_fora_pernas_botas_alterados':0,'componentes':n,'tamanhos':sizes,'cores_isoladas':isolated,
   'quadris_preservados':True,'apoio_preservado':True,
   'solas':[{'perna':l['perna'],'apoio':l['apoio_original'],'antes':l['sola_48b3'],
     'depois':l['articulacoes']['ponto_sola'],'delta':l['deslocamento_sola_48b3']} for l in row['pernas']],
   'replay_rgba_identico':True,'pixels_perna_apoio_alterados':0,
   'altura_joelho_recolhido_acima_do_chao_px':7,'altura_sola_elevada_acima_do_chao_px':6,
   'pontos':[{'perna':l['perna'],'antes':l['articulacoes_48b3'],'depois':l['articulacoes'],
     'diferencas':l['diferencas_articulacoes']} for l in row['pernas']]})
 save(OUT/'VERIFICACAO_POSES.json',{'conferencia_tecnica_aprovada':True,'avaliacao_visual':'pendente de avaliação do usuário',
  'mestre_sha256':B.EXPECTED,'quadros':checks,
  'somente_estaticas':[0],'animacao_gif_video_gerados':False,'paleta':'paleta_bosque_v1','alpha':[0,255],
  'ancora':[AX,AY],'pixels_do_corpo_preservados':True,'botas_redesenhadas':True,
  'f2_f6_nao_regerados':{f'run_f{k}.png':sha(ROOT/f'arte_fonte/forma_humana_v1/poses_chave_48b2/quadros/run_f{k}.png') for k in (2,6)},
  'f4_nao_regerado':sha(SOURCE/'quadros/run_f4.png'),
  'sombra_embutida':False,'quadro_neutro_recomposto_rgba_identico':True,
  'limite_anterior_de_2px_revogado':True,'trajetoria_identica_a_anterior':False})
 print(json.dumps(checks,ensure_ascii=False))

def reproduce():
 names=('COMPARACAO_COMPLETA_x1.png','COMPARACAO_COMPLETA_x4.png','PERNAS_MESTRE_ANTES_PROPOSTA.png',
  'ARTICULACOES_AUXILIAR.png','VERIFICACAO_POSES.json')+tuple(f'PROPOSTA_f{k}_x{s}.png' for k in KEYS for s in (1,4))
 def snapshot():
  files=[p for p in ART.rglob('*') if p.is_file()]+[OUT/n for n in names]
  return {p.relative_to(ROOT).as_posix():sha(p) for p in sorted(files)}
 before=snapshot();generate();evidence();verify();after=snapshot()
 changed=[p for p in before.keys()|after.keys() if before.get(p)!=after.get(p)]
 assert not changed,changed
 save(OUT/'REPRODUCAO.json',{'aprovado':True,'arquivos_conferidos':len(before),'diferencas':[],
  'segunda_geracao_sha256_identica':True,'sha256':after})
 print(f'Reprodução conferida: {len(before)} arquivos idênticos.')

def main():
 p=argparse.ArgumentParser();options=p.add_mutually_exclusive_group()
 options.add_argument('--verify',action='store_true');options.add_argument('--reproduce',action='store_true');args=p.parse_args()
 ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 if args.verify:verify();return
 if args.reproduce:reproduce();return
 generate();evidence();verify()
if __name__=='__main__':main()
