"""4.8b: approved master -> exact native rig -> only idle/run, not a package.

Uses the approved kit_rig library; no rejected masters are loaded. Parts and
uncovered joint fills are indexed pixels. Boots/sword are rigid native parts.
"""
from pathlib import Path
import argparse, collections, csv, hashlib, json, math, re, subprocess, sys
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT/'arte_fonte/kit_rig'), str(ROOT/'.godot/forma_humana_48a/deps')]
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from kitrig import Paleta, Rig, Tela, ik2, atrasar, quadro_por_distancia, mascara_membro, sombrear, mascara_segmento
from kitrig.desenho import _vizinhos, uniformizar_isolados, remover_soltos, componentes
from kitrig.previa import fundo_cemiterio, chao_na_tela

MASTER = ROOT/'arte_fonte/forma_humana_v1/forma_humana_mestre_x1.png'
EXPECTED = '204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988'
ART = MASTER.parent/'rig_48b'
OUT = ROOT/'codex/evidencias_forma_humana_48b'
PAL = Paleta.carregar(ROOT/'arte_fonte/paleta/paleta_bosque_v1.json')
AX, AY = 40, 56
TEMPLATE = Tela(96,64,AX,AY)
MX, MY = 24,50
XFOOT = [10,4,-2,-8,-10,-2,6,12]
YFOOT = [0,0,0,0,-3,-5,-5,-2]
BOB = [2,1,2,3,2,1,2,3]
LAYERS = ['coxa_tras','canela_tras','bota_tras','braco_distante','capa',
          'tronco','coxa_frente','canela_frente','bota_frente','capuz','cabeca_cabelo','braco_proximo','mao_espada']

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def image(idx): return Image.fromarray(PAL.para_rgba(idx))
def polygon(points,shape=(52,50)):
    im=Image.new('1',(shape[1],shape[0])); ImageDraw.Draw(im).polygon(points,fill=1)
    return np.array(im)
def rect(box):
    x0,y0,x1,y1=box; yy,xx=np.mgrid[:52,:50]
    return (xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)

def split():
    assert sha(MASTER)==EXPECTED,'Approved master changed'
    master=PAL.de_rgba(np.array(Image.open(MASTER)),estrito=True)
    yy,xx=np.mgrid[:52,:50]
    weapon=polygon([(21,32),(23,32),(25,34),(24,36),(22,37),(20,36),(20,34)])
    blade=(yy>=35)&(xx>=23)&np.isin(master,[16,17,18]);weapon|=blade
    pad=np.pad(blade,1);halo=np.zeros(blade.shape,bool)
    for dy in range(3):
        for dx in range(3):halo|=pad[dy:dy+52,dx:dx+50]
    # Only the visible blade rim belongs to the weapon; the trousers under
    # its diagonal must stay with their leg, rather than follow the sword.
    rim_start={35:24,36:27,37:29,38:32,39:34,40:35,41:36,42:34,43:37,44:39,45:41,46:42,47:44}
    for y,x in rim_start.items():weapon[y,x:]|=(master[y,x:]==3)&halo[y,x:]
    weapon[47,47]=True  # native dark tip, two pixels past the last steel pixel
    regions = {
      'cabeca_cabelo':dict(mascara=(yy<=16)|((yy<=20)&(xx>=18)),pivo=(27,20)),
      'mao_espada':dict(mascara=weapon,pivo=(23,34)),
      'braco_distante':dict(poligono=[(29,26),(32,28),(33,31),(36,34),(36,38),(33,37),(30,33),(28,30)],pivo=(29,26)),
      'braco_proximo':dict(poligono=[(18,22),(22,23),(23,26),(22,29),(24,32),(23,35),(20,36),(18,34),(17,29)],pivo=(20,24)),
      'capa':dict(poligono=[(13,20),(18,22),(20,27),(19,31),(17,35),(19,38),(16,41),(11,41),(8,44),(5,43),(2,40),(5,33),(10,26)],pivo=(15,23)),
      'bota_tras':dict(mascara=rect((12,44,24,50)),pivo=(17,44)),
      'bota_frente':dict(mascara=rect((27,44,38,50)),pivo=(31,44)),
      'canela_tras':dict(poligono=[(18,39),(23,40),(23,44),(12,45),(14,42)],pivo=(18,41)),
      'coxa_tras':dict(poligono=[(21,34),(26,36),(24,40),(21,42),(15,40),(17,36)],pivo=(23,36)),
      'canela_frente':dict(poligono=[(29,39),(34,40),(34,44),(27,45),(27,42)],pivo=(30,42)),
      'coxa_frente':dict(poligono=[(25,35),(30,35),(34,40),(31,42),(27,41),(25,38)],pivo=(27,36)),
      'capuz':dict(poligono=[(13,19),(18,19),(21,21),(27,22),(32,20),(34,21),(32,25),(28,26),(22,24),(18,22),(13,22)],pivo=(24,22)),
      'tronco':dict(mascara=np.ones(master.shape,bool),pivo=(25,33)),
    }
    # Joint roots were covered by the arm, sword and cloak in the master.
    # Fills are constrained to original opaque pixels and later layers hide
    # them completely in the neutral reconstruction.
    regions['tronco']['completar']=[(polygon([(18,24),(22,24),(23,29),(24,34),(19,35)]),8),
                                    (polygon([(22,28),(24,27),(25,30),(23,32)]),10)]
    rig=Rig.de_mestre(PAL,master,(MX,MY),regions,LAYERS,altura_px=48)
    data=rig.salvar(ART,fonte=MASTER.relative_to(ROOT).as_posix(),extra={
       'mestre_sha256':EXPECTED,'biblioteca':'arte_fonte/kit_rig/kitrig',
       'uso':'somente rig e idle/run para avaliação; não é pacote final',
       'articulacao_run':'quadril/joelho/tornozelo via ik2; botas nativas sem escala ou giro',
       'sobreposicao_run':'perna distante atrás; pano/tronco cobre a raiz da perna próxima; arma na frente',
       'juntas_mestre':{'quadril_tras':[23,36],'quadril_frente':[27,36],
                       'joelho_tras':[18,41],'joelho_frente':[30,42],
                       'tornozelo_tras':[17,44],'tornozelo_frente':[31,44],
                       'ombro_proximo':[20,24],'mao_espada':[23,34]},
       'completar':{'somente_regioes_escondidas':True,'tronco':[
          {'poligono':[(18,24),(22,24),(23,29),(24,34),(19,35)],'cor':8},
          {'poligono':[(22,28),(24,27),(25,30),(23,32)],'cor':10}]}})
    # The library's save writes default platform newlines; normalize only
    # this new JSON, never the approved kit or existing evidence.
    save(ART/'rig.json',data)
    loaded=Rig.carregar(ART/'rig.json',PAL)
    neutral=loaded.renderizar(Tela(50,52,MX,MY),{}).a
    assert np.array_equal(PAL.para_rgba(neutral),np.array(Image.open(MASTER))), 'Neutral reconstruction differs'
    image(neutral).save(ART/'pose_neutra_recomposta_x1.png')
    diff=np.any(PAL.para_rgba(neutral)!=np.array(Image.open(MASTER)),axis=2)
    save(OUT/'RECONSTRUCAO.json',{'rgba_identico':not diff.any(),'pixels_diferentes':int(diff.sum()),'mestre_sha256':EXPECTED,
        'partes':len(loaded.partes),'origem':MASTER.relative_to(ROOT).as_posix(),'partes_camadas':LAYERS})
    return loaded, master

def skin_clean(a, protected=None):
    a=remover_soltos(a,1,2)
    for _ in range(12):
        old=a.copy();a=uniformizar_isolados(a,passes=1)
        if protected is not None:a[protected[0]]=protected[1][protected[0]]
        if np.array_equal(a,old):break
    # A facet at a boot's seam may lose its colour neighbour when the leg
    # bends. Keep the native boot/head pixel, and connect that facet in the
    # newly exposed joint instead of repainting the approved part.
    fixed=protected[0] if protected is not None else np.zeros(a.shape,bool)
    for _ in range(8):
        isolated=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
        if not isolated.any():break
        for y,x in zip(*np.where(isolated)):
            neighbours=[(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1)
                if (dx or dy) and 0<=y+dy<a.shape[0] and 0<=x+dx<a.shape[1] and a[y+dy,x+dx]>=0]
            if fixed[y,x]:
                candidates=[p for p in neighbours if not fixed[p]]
                if candidates:
                    q=min(candidates,key=lambda p:abs(int(a[p])-int(a[y,x])));a[q]=a[y,x]
            else:
                colors=collections.Counter(int(a[p]) for p in neighbours)
                if colors:a[y,x]=colors.most_common(1)[0][0]
    return a

def leg_pose(rig,k,front,dy):
    side='frente' if front else 'tras'; phase=k if front else (k+4)%8
    foot=(XFOOT[phase],YFOOT[phase]); hip=(4 if front else 1,-15+dy)
    ankle=(foot[0],-6+foot[1]); knee=tuple(round(q) for q in ik2(hip,ankle,7,7,1))
    detail={}
    for part,target in [('coxa_'+side,hip),('canela_'+side,knee)]:
        px,py=rig.partes[part].pivo_mestre
        shift=(target[0]-(px-MX),target[1]-(py-MY))
        detail[part]={'dx':shift[0],'dy':shift[1],'ang':0}
    p=rig.partes['bota_'+side];px,py=p.pivo_mestre
    shift=(ankle[0]-(px-MX),ankle[1]-(py-MY))
    detail['bota_'+side]={'dx':shift[0],'dy':shift[1],'ang':0}
    return {'perna':side,'fase':phase,'apoio':phase<=3,'quadril':hip,'joelho':knee,
                    'tornozelo':ankle,'pe':foot,'partes':detail}

def leg_record(rig,row):
    """Rebuild the joint geometry and rigid parts from the saved pose."""
    t=TEMPLATE.nova();front=row['perna']=='frente'
    shape=mascara_membro(t,tuple(row['quadril']),tuple(row['joelho']),tuple(row['tornozelo']),2.2,2.0)
    t.camada(sombrear(shape,8 if front else 7,11 if front else 10,13 if front else 11,7,3))
    for name,p in row['partes'].items():
        layer=rig.desenhar_parte(TEMPLATE,name,p['dx'],p['dy'],ang=p['ang']);t.camada(layer)
        if name.startswith('bota_'):boot=layer
    return t.a,boot

def render_pose(rig,name,row):
    pose=row['pose_rig'];boots=[]
    if name=='idle':t=rig.renderizar(TEMPLATE.nova(),pose)
    else:
        near,nb=leg_record(rig,row['pernas'][0]);far,fb=leg_record(rig,row['pernas'][1]);boots=[fb,nb]
        t=TEMPLATE.nova();t.camada(far)
        rig.renderizar(t,pose,ordem=['braco_distante','capa','tronco'])
        clothes=rig.renderizar(TEMPLATE.nova(),pose,ordem=['capa','tronco']).a
        near[clothes>=0]=-1;t.camada(near)
        rig.renderizar(t,pose,ordem=['capuz','cabeca_cabelo','braco_proximo','mao_espada'])
    before=t.a.copy();protected=np.zeros(t.shape,bool)
    for b in boots:protected|=(b>=0)&(t.a==b)
    if name=='idle':
        head=rig.desenhar_parte(TEMPLATE,'cabeca_cabelo',0,0,ang=0)
        protected|=(head>=0)&(t.a==head)
    p=pose.get('partes',{}).get('mao_espada',{})
    weapon=rig.desenhar_parte(TEMPLATE,'mao_espada',pose.get('dx',0)+p.get('dx',0),pose.get('dy',0)+p.get('dy',0),ang=0)
    protected|=(weapon>=0)&(t.a==weapon)
    t.a=skin_clean(t.a,(protected,before))
    assert not t.corpo_abaixo_do_chao(),(name,row['quadro'],'pixels at ground')
    return t.a

def make_frames(rig):
    ref=json.loads((ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json').read_text(encoding='utf-8'))
    reference={a['id']:a for a in ref['animacoes'] if a['id'] in ('idle','run')}
    frames={};poses={};contract={'referencia_sha256':sha(ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json'),
       'animacoes':[],'nao_e_pacote_final':True,'sem_walk':True,'caminhada_usa':'run','paleta':'paleta_bosque_v1',
       'canvas':[96,64],'ancora':[AX,AY]}
    idle_bob=[0,0,-1,-1,-1,0,0,0]
    capa_lag=atrasar(BOB,1);idle_lag=atrasar(idle_bob,1)
    capa_angle=atrasar([8,10,12,10,8,10,12,10],1)
    for name in ('idle','run'):
        frames[name]=[];poses[name]=[];entries=[]
        for k in range(8):
            if name=='idle':
                fixed=['coxa_tras','canela_tras','bota_tras','coxa_frente','canela_frente','bota_frente','cabeca_cabelo']
                pose={'dx':0,'dy':idle_bob[k],'fixas':fixed,
                      'partes':{'capa':{'dy':idle_lag[k]-idle_bob[k]}}}
                row={'quadro':k,'pose_rig':pose,'cabeca_fixa':True,'pes_fixos':True,'capa_origem_quadro':(k-1)%8}
            else:
                fm=leg_pose(rig,k,False,BOB[k]);nm=leg_pose(rig,k,True,BOB[k])
                pose={'dx':2,'dy':BOB[k],'partes':{'capa':{'ang':capa_angle[k],'dy':capa_lag[k]-BOB[k]},
                   'braco_proximo':{'dy':-3},'mao_espada':{'dy':-3}}}
                row={'quadro':k,'pose_rig':pose,'pernas':[nm,fm],'capa_origem_quadro':(k-1)%8}
            result=render_pose(rig,name,row)
            frames[name].append(result);poses[name].append(row)
            folder=ART/'quadros'/name;folder.mkdir(parents=True,exist_ok=True)
            path=folder/f'{name}_f{k}.png';image(result).save(path)
            entries.append({'arquivo':path.relative_to(ART).as_posix(),'sha256':sha(path),'ms':reference[name]['quadros'][k]['ms'],
                            'ancora':[AX,AY],'quadro':k})
        contract['animacoes'].append({'id':name,'loop':True,'quadros_n':8,'quadros':entries,
             'duracao_soma_ms':sum(q['ms'] for q in entries),'duracao_nominal_referencia_ms':reference[name]['duracao_total_ms'],
             **({'px_por_quadro':6,'selecao':'floor(distancia_px/6) % 8'} if name=='run' else {})})
    save(ART/'poses.json',poses);save(ART/'contrato_ciclos.json',contract)
    return frames,poses,contract

def textfont(n=12):return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
def gray(idx):
    bg=Image.new('RGBA',(96,64),(96,96,96,255));bg.alpha_composite(image(idx));return bg

def evidence(master,frames,contract):
    original=image(master);rebuild=Image.open(ART/'pose_neutra_recomposta_x1.png')
    comp=Image.new('RGB',(480,240),(96,96,96));d=ImageDraw.Draw(comp)
    for x,title,im in [(8,'MESTRE APROVADO',original),(252,'RECOMPOSTO — 0 pixels diferentes',rebuild)]:
        bg=Image.new('RGBA',(50,52),(96,96,96,255));bg.alpha_composite(im)
        comp.paste(bg.resize((200,208),Image.Resampling.NEAREST).convert('RGB'),(x+16,30));d.text((x,8),title,font=textfont(12),fill='white')
    comp.save(OUT/'MESTRE_RECOMPOSTO_x4.png')
    tiles=Image.new('RGB',(5*180,3*228),(96,96,96));d=ImageDraw.Draw(tiles)
    rigdata=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    for i,(name,p) in enumerate(rigdata['partes'].items()):
        im=Image.open(ART/p['arquivo']);bg=Image.new('RGBA',im.size,(96,96,96,255));bg.alpha_composite(im)
        x,y=(i%5)*180,(i//5)*228
        tiles.paste(bg.resize((150,156),Image.Resampling.NEAREST).convert('RGB'),(x+12,y+32))
        px,py=p['pivo'];d.line((x+12+px*3-4,y+32+py*3,x+12+px*3+4,y+32+py*3),fill='#e3bd73')
        d.line((x+12+px*3,y+32+py*3-4,x+12+px*3,y+32+py*3+4),fill='#e3bd73')
        d.text((x+2,y+8),name,font=textfont(12),fill='white');d.text((x+2,y+200),'pivô '+str(p['pivo']),font=textfont(12),fill='white')
    tiles.save(OUT/'PARTES_PIVOS.png')
    for a in contract['animacoes']:
        name=a['id'];imgs=[gray(q).resize((384,256),Image.Resampling.NEAREST).convert('RGB') for q in frames[name]]
        cumulative=np.cumsum([q['ms'] for q in a['quadros']]);ends=[int(round(t/10))*10 for t in cumulative]
        gif_ms=[ends[0]]+[b-a for a,b in zip(ends,ends[1:])]
        imgs[0].save(OUT/f'{name}_x4.gif',save_all=True,append_images=imgs[1:],duration=gif_ms,loop=0,disposal=2,optimize=False)
        sheet=Image.new('RGB',(96*8,80),(96,96,96));d=ImageDraw.Draw(sheet)
        for i,q in enumerate(frames[name]):sheet.paste(gray(q).convert('RGB'),(i*96,16));d.text((i*96+3,2),str(i),font=textfont(10),fill='white')
        sheet.save(OUT/f'{name}_quadros_x1.png');sheet.resize((3072,320),Image.Resampling.NEAREST).save(OUT/f'{name}_quadros_x4.png')

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
                side=legrow['perna'];native_center=-1 if side=='tras' else 2
                footx=ix+facing*(legrow['pe'][0]+native_center)
                sole=iy-1+legrow['pe'][1]
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

def verify():
    assert sha(MASTER)==EXPECTED
    rig=Rig.carregar(ART/'rig.json',PAL);neutral=rig.renderizar(Tela(50,52,MX,MY),{}).a
    assert np.array_equal(PAL.para_rgba(neutral),np.array(Image.open(MASTER)))
    master=PAL.de_rgba(np.array(Image.open(MASTER)),estrito=True)
    rigdata=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    completed=[]
    for name,p in rigdata['partes'].items():
        partpath=ART/p['arquivo'];assert sha(partpath)==p['sha256']
        native=rig.partes[name].idx
        assert not ((native>=0)&(master<0)).any(),'Part completed outside original silhouette'
        assert all(isinstance(v,int) for v in p['pivo']+p['origem_mestre'])
        completed.append({'parte':name,'pixels_nativos':int(((native>=0)&(native==master)).sum()),
                          'pixels_completados_sob_outras_partes':int(((native>=0)&(native!=master)).sum())})
    c=json.loads((ART/'contrato_ciclos.json').read_text(encoding='utf-8'));poses=json.loads((ART/'poses.json').read_text(encoding='utf-8'))
    ref=json.loads((ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json').read_text(encoding='utf-8'))
    refs={a['id']:a for a in ref['animacoes']};checks=[]
    assert c['referencia_sha256']==sha(ROOT/'assets/characters/pequeno_v34A/manifesto_sprites.json')
    assert [a['id'] for a in c['animacoes']]==['idle','run']
    assert set(poses)=={'idle','run'} and c['sem_walk'] and c['caminhada_usa']=='run'
    assert c['animacoes'][1]['px_por_quadro']==6
    for a in c['animacoes']:
        assert len(a['quadros'])==8
        assert [q['ms'] for q in a['quadros']]==[q['ms'] for q in refs[a['id']]['quadros']]
        for q in a['quadros']:
            path=ART/q['arquivo'];im=Image.open(path);px=np.array(im)
            assert set(np.unique(px[...,3]))=={0,255};idx=PAL.de_rgba(px,estrito=True)
            assert q['sha256']==sha(path) and q['ancora']==[AX,AY] and im.size==(96,64)
            assert not (idx[AY:]>=0).any()
            recorded=poses[a['id']][q['quadro']]
            replay=render_pose(rig,a['id'],recorded)
            assert np.array_equal(replay,idx),'Saved rig/pose cannot reproduce frame'
            pose=recorded['pose_rig'];wp=pose.get('partes',{}).get('mao_espada',{})
            sword=rig.desenhar_parte(TEMPLATE,'mao_espada',pose.get('dx',0)+wp.get('dx',0),pose.get('dy',0)+wp.get('dy',0),ang=0)
            assert np.array_equal(idx[sword>=0],sword[sword>=0]),'Native sword or hand changed'
            head=rig.desenhar_parte(TEMPLATE,'cabeca_cabelo',0 if a['id']=='idle' else pose['dx'],0 if a['id']=='idle' else pose['dy'],ang=0)
            assert not ((head>=0)&np.isin(sword,[16,17,18])).any(),'Blade covers face/hair'
            n,sizes=componentes(idx);assert n==1,(a['id'],q['quadro'],sizes)
            isolated=int(((idx>=0)&~np.any(_vizinhos(idx)==idx,axis=0)).sum())
            assert isolated==0,(a['id'],q['quadro'],'Isolated colour')
            checks.append({'animacao':a['id'],'quadro':q['quadro'],'componentes':n,'cores_isoladas':isolated})
    idle=[PAL.de_rgba(np.array(Image.open(ART/q['arquivo']))) for q in c['animacoes'][0]['quadros']]
    assert all(np.array_equal(a[AY-3:AY,AX-12:AX+14],idle[0][AY-3:AY,AX-12:AX+14]) for a in idle), 'Idle feet moved'
    head=rig.desenhar_parte(TEMPLATE,'cabeca_cabelo',0,0,ang=0);headmask=head>=0
    assert all(np.array_equal(a[headmask],head[headmask]) for a in idle),'Idle face/hair pixels jittered'
    # Explicit actual-native-boot proof, rather than only checking joints.
    soles=[]
    for k,row in enumerate(poses['run']):
        result=PAL.de_rgba(np.array(Image.open(ART/f'quadros/run/run_f{k}.png')))
        for legrow in row['pernas']:
            name='bota_'+legrow['perna'];p=legrow['partes'][name]
            layer=rig.desenhar_parte(TEMPLATE,name,p['dx'],p['dy'],ang=0)
            mask=(layer>=0);ys,xs=np.where(mask)
            bottom=(layer>=0)&(np.indices(layer.shape)[0]>=ys.max()-1)
            # The far boot may be covered by cape/body/near limb during
            # passage; its planted sole must remain wholly visible.
            if legrow['apoio']:assert np.array_equal(result[bottom],layer[bottom]),(k,name,'Native planted sole changed')
            visible=mask&(result==layer)
            assert visible.sum()>=12,(k,name,'Boot hidden completely')
            assert p['ang']==0
            soles.append({'quadro':k,'perna':name,'apoio':legrow['apoio'],'sola_de_apoio_rgba_identica':True if legrow['apoio'] else None,
                          'pixels_bota_visiveis':int(visible.sum()),'pixels_bota_nativa':int(mask.sum()),
                          'linha_sola':int(ys.max()),'posicao_local_tornozelo':legrow['tornozelo']})
        assert row['capa_origem_quadro']==(k-1)%8
    stance=[]
    for side in (0,1):
        for k in range(8):
            a=poses['run'][k]['pernas'][side];b=poses['run'][(k+1)%8]['pernas'][side]
            if a['apoio'] and b['apoio']:
                shift=6+b['tornozelo'][0]-a['tornozelo'][0]
                assert shift==0
                stance.append({'perna':a['perna'],'quadros':[k,(k+1)%8],'deslocamento_corpo_px':6,'deslocamento_sola_mundo_px':shift})
    report={'aprovado':True,'mestre_sha256':EXPECTED,'reconstrucao_rgba_identica':True,'quadros':checks,'solas':soles,
        'apoios_por_distancia':stance,'ancora':[AX,AY],'pixel_scale':1,'alpha':[0,255],'somente_idle_run':True,
        'run_px_por_quadro':6,'biblioteca':'kit_rig','arte_instalada':False,'pacote_final':False}
    report['idle_rosto_cabelo_rgba_identicos_em_8_quadros']=True
    report['idle_pes_imoveis']=True
    report['partes_completadas']=completed
    report['replay_poses_salvas_rgba_identico_16_quadros']=True
    report['mao_espada_rgba_nativos_16_quadros']=True
    report['lamina_fora_do_rosto']=True
    report['gif_resolucao_ms']=10
    report['gif_duracao_ms']={a['id']:int(round(a['duracao_soma_ms']/10))*10 for a in c['animacoes']}
    save(OUT/'VERIFICACAO_RIG_CICLOS.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in ('quadros','solas','apoios_por_distancia')},ensure_ascii=False))

def main():
    p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');p.add_argument('--preview',action='store_true');p.add_argument('--verify-preview',action='store_true');args=p.parse_args()
    ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    if args.verify:verify();return
    if args.verify_preview:verify();verify_preview();return
    if args.preview:verify();preview();verify_preview();return
    rig,master=split();frames,poses,contract=make_frames(rig);evidence(master,frames,contract);verify()

if __name__=='__main__':main()
