"""4.8b1: direction-specific trouser variants, with immutable motion/boots.

Only this revision's folders are written. The 4.8b renderer/kit are imported
as read-only libraries; their globals are rebound in memory for the preview.
"""
from pathlib import Path
import argparse, collections, copy, hashlib, importlib.util, json, math, shutil, sys
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('human48b_readonly',ROOT/'arte_fonte/ferramentas/animar_forma_humana_48b.py')
B = importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from kitrig import Rig
from kitrig.desenho import componentes, _vizinhos
SOURCE = ROOT/'arte_fonte/forma_humana_v1/rig_48b'
ART = SOURCE.parent/'rig_48b1'
OUT = ROOT/'codex/evidencias_forma_humana_48b1'
PAL = B.PAL
T = B.TEMPLATE
AX,AY = B.AX,B.AY
# Only knees can move locally. Hips, ankles, soles and phase are read intact.
# The folded phase lifts the thigh forward and lets the calf fall behind it.
KNEES = {
    'frente':[(6,-9),(7,-10),(2,-9),(-2,-8),(-3,-11),(3,-10),(9,-14),(9,-11)],
    'tras':[( -4,-10),(2,-10),(7,-14),(7,-10),(6,-9),(5,-10),(0,-9),(-3,-8)],
}
S4=np.array([[0,1,0],[1,1,1],[0,1,0]],bool)

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def idx(path):return PAL.de_rgba(np.array(Image.open(path).convert('RGBA')),estrito=True)
def png(path,a):path.parent.mkdir(parents=True,exist_ok=True);B.image(a).save(path)
def original_poses():return json.loads((SOURCE/'poses.json').read_text(encoding='utf-8'))
def base_rig():return Rig.carregar(SOURCE/'rig.json',PAL)

def provenance(rig,row):
    """Track the old compositor's owners, not inferred RGB colour labels."""
    pose=row['pose_rig'];near,nb=B.leg_record(rig,row['pernas'][0]);far,fb=B.leg_record(rig,row['pernas'][1])
    owners=np.zeros(T.shape,np.uint8)
    owners[far>=0]=1
    for names in (['braco_distante','capa','tronco'],):
        layer=rig.renderizar(T.nova(),pose,ordem=names).a;owners[layer>=0]=0
    clothes=rig.renderizar(T.nova(),pose,ordem=['capa','tronco']).a
    near[clothes>=0]=-1;owners[near>=0]=2
    layer=rig.renderizar(T.nova(),pose,ordem=['capuz','cabeca_cabelo','braco_proximo','mao_espada']).a
    owners[layer>=0]=0
    old=idx(SOURCE/f'quadros/run/run_f{row["quadro"]}.png')
    bootboxes=np.zeros(T.shape,bool)
    boots=[fb,nb]
    for boot in boots:
        yy,xx=np.where(boot>=0);bootboxes|=boot>=0
        # Whole native boot plus the two sole rows, including transparent
        # corners: no foot silhouette or ground contact can change.
        bootboxes[yy.max()-1:yy.max()+1,xx.min():xx.max()+1]=True
    visible_legs=(owners>0)&(old>=0)&~bootboxes
    protected=((owners==0)&(old>=0))|bootboxes
    # Keep the existing dark garment attachment at the trouser root. These
    # pixels connect the fixed cape/hem to the limb and are not joint facets.
    garment=(owners==0)&(old>=0)&~bootboxes
    attachment=(owners>0)&(old==3)&ndi.binary_dilation(garment,structure=np.ones((3,3)))
    protected|=attachment;visible_legs&=~attachment
    return old,visible_legs,protected,bootboxes,boots

def polygon(points):
    im=Image.new('1',(T.w,T.h));ImageDraw.Draw(im).polygon([(round(AX+p[0]),round(AY+p[1])) for p in points],fill=1)
    return np.array(im)

def mesh(hip,knee,ankle,side):
    """One continuous volume, shared knee edge, without overlapping caps.

    Each segment is shaped along its actual direction. The knee shares a
    bevelled section, not a disk over two vertical strips. The light follows
    the outside surface of the whole trouser volume, including the bend.
    """
    h,k,a=[np.array(p,float) for p in (hip,knee,ankle)]
    u=(k-h)/np.linalg.norm(k-h);v=(a-k)/np.linalg.norm(a-k)
    n0=np.array([-u[1],u[0]]);n1=np.array([-v[1],v[0]])
    joint=n0+n1
    if np.linalg.norm(joint)<.1:joint=n0
    joint/=np.linalg.norm(joint)
    radius=2.25
    # Limit the knee section instead of allowing an acute miter to form a knot.
    kr=min(2.6,2.0/max(.5,abs(float(np.dot(joint,n0)))))
    thigh=polygon([h-n0*radius,k-joint*kr,k+joint*kr,h+n0*radius])
    calf=polygon([k-joint*kr,a-n1*2.0,a+n1*2.0,k+joint*kr])
    whole=thigh|calf
    inner=ndi.binary_erosion(whole,structure=S4,border_value=0)
    out=np.full(T.shape,-1,int);out[whole]=3
    base,light,shadow=(8,11,7) if side=='frente' else (7,10,5)
    out[inner]=base
    lit=(inner&~np.roll(inner,1,0))|(inner&~np.roll(inner,-1,1))
    dark=((inner&~np.roll(inner,-1,0))|(inner&~np.roll(inner,1,1)))&~lit
    out[dark]=shadow;out[lit]=light
    # Source leather facets stay in groups: no extra knee plate or cuff.
    return np.where(thigh,out,-1),np.where(calf,out,-1),whole

def local_clean(a,edit,protected,old):
    """Only editable trouser pixels can change; neighbours preserve fixed art."""
    stable=protected.copy()
    for _ in range(20):
        iso=(a>=0)&~np.any(_vizinhos(a)==a,axis=0)
        if not iso.any():break
        previous=a.copy()
        for y,x in sorted(zip(*np.where(iso)),key=lambda p:0 if stable[p] else 1):
            near=[(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1)
                  if (dx or dy) and 0<=y+dy<T.h and 0<=x+dx<T.w]
            if edit[y,x] and not stable[y,x]:
                colors=collections.Counter(int(a[p]) for p in near if a[p]>=0)
                if colors:a[y,x]=colors.most_common(1)[0][0]
            else:
                options=[p for p in near if edit[p] and not stable[p] and a[p]>=0]
                if options:
                    p=min(options,key=lambda q:(old[q]!=a[y,x],abs(int(a[q])-int(a[y,x]))))
                    a[p]=a[y,x];stable[p]=True
                else:
                    # A fixed boot highlight may have depended on the old cuff.
                    # Retain its existing neighbour rather than repainting the
                    # boot or extending the original silhouette.
                    options=[p for p in near if edit[p] and not stable[p]
                             and old[p]==a[y,x]]
                    if options:a[options[0]]=a[y,x];stable[options[0]]=True
        if np.array_equal(previous,a):break
    return a

def compose(source_rig,variant_rig,oldrow,row):
    """Replay the revised rig over the immutable, original non-leg drawing."""
    old,oldlegs,protected,bootmask,boots=provenance(source_rig,oldrow)
    newlegs=np.full(T.shape,-1,int)
    for leg in reversed(row['pernas']):
        for name in ('coxa_'+leg['perna'],'canela_'+leg['perna']):
            p=leg['partes'][name]
            layer=variant_rig.desenhar_parte(T,name,p['dx'],p['dy'],ang=0,variante=p['variante'])
            newlegs[layer>=0]=layer[layer>=0]
    corridor=oldlegs|ndi.binary_dilation(newlegs>=0,structure=S4)
    corridor[AY:]=False;edit=corridor&~protected
    result=old.copy();result[oldlegs&edit]=-1
    change=(newlegs>=0)&edit;result[change]=newlegs[change]
    result=local_clean(result,edit,protected,old)
    return result,edit,bootmask,protected,boots

def generate():
    assert sha(B.MASTER)==B.EXPECTED
    rig=base_rig();poses=original_poses();revised=copy.deepcopy(poses)
    rigdata=json.loads((SOURCE/'rig.json').read_text(encoding='utf-8'))
    for p in rigdata['partes'].values():p['arquivo']='../rig_48b/'+p['arquivo']
    rigdata['revisao']='4.8b1: somente coxas/joelhos/canelas de run'
    rigdata['rig_anterior_sha256']=sha(SOURCE/'rig.json')
    rigdata['variantes_run']='geometria orientada; seção compartilhada no joelho; luz próxima/distante'
    rigdata['botas_e_movimento']='originais 4.8b; sem escala, giro, alteração de trajetória ou cadência'
    for row in revised['run']:
        k=row['quadro']
        for leg in row['pernas']:
            side=leg['perna'];leg['joelho_anterior']=leg['joelho'];leg['joelho']=list(KNEES[side][k])
            thigh,calf,_=mesh(leg['quadril'],leg['joelho'],leg['tornozelo'],side)
            for part,arr,pivot in [('coxa_'+side,thigh,leg['quadril']),('canela_'+side,calf,leg['joelho'])]:
                name=f'{part}_run_f{k}';path=ART/f'variantes/{name}.png';png(path,arr)
                rigdata['partes'][name]={'arquivo':path.relative_to(ART).as_posix(),'pivo':[AX+pivot[0],AY+pivot[1]],
                    'variante':True,'variante_de':part,'sha256':sha(path)}
                px,py=rig.partes[part].pivo_mestre
                leg['partes'][part]={'dx':pivot[0]-(px-B.MX),'dy':pivot[1]-(py-B.MY),'ang':0,'variante':name}
    save(ART/'rig.json',rigdata);save(ART/'poses.json',revised)
    shutil.copyfile(SOURCE/'poses.json',ART/'poses_movimento_original.json')
    loaded=Rig.carregar(ART/'rig.json',PAL)
    neutral=loaded.renderizar(B.Tela(50,52,B.MX,B.MY),{}).a
    assert np.array_equal(PAL.para_rgba(neutral),np.array(Image.open(B.MASTER)))
    contract=json.loads((SOURCE/'contrato_ciclos.json').read_text(encoding='utf-8'))
    for a in contract['animacoes']:
        if a['id']=='idle':
            for q in a['quadros']:q['arquivo']='../rig_48b/'+q['arquivo']
    proofs=[]
    for row in revised['run']:
        k=row['quadro'];old=idx(SOURCE/f'quadros/run/run_f{k}.png')
        result,edit,bootboxes,protected,boots=compose(rig,loaded,poses['run'][k],row)
        assert np.array_equal(result[~edit],old[~edit])
        assert np.array_equal(result[bootboxes],old[bootboxes])
        path=ART/f'quadros/run/run_f{k}.png';png(path,result)
        a=next(a for a in contract['animacoes'] if a['id']=='run')
        a['quadros'][k]['sha256']=sha(path)
        mask=Image.fromarray((edit*255).astype(np.uint8));(ART/'mascaras_edicao').mkdir(exist_ok=True)
        mask.save(ART/f'mascaras_edicao/run_f{k}.png')
        diff=np.any(PAL.para_rgba(result)!=PAL.para_rgba(old),axis=2)
        Image.fromarray((diff*255).astype(np.uint8)).save(ART/f'mascaras_edicao/diferenca_f{k}.png')
        proofs.append({'quadro':k,'pixels_alterados':int(diff.sum()),'pixels_fora_da_mascara_alterados':0,
            'pixels_das_botas_alterados':0,'mascara_edicao':f'mascaras_edicao/run_f{k}.png',
            'diferenca_rgba':f'mascaras_edicao/diferenca_f{k}.png','quadris_joelhos_tornozelos':[
                {'perna':l['perna'],'quadril':l['quadril'],'joelho_antes':l['joelho_anterior'],'joelho_depois':l['joelho'],
                 'tornozelo':l['tornozelo'],'pe':l['pe'],'apoio':l['apoio']} for l in row['pernas']]})
    save(ART/'contrato_ciclos.json',contract)
    save(OUT/'MASCARAS_POSES_SOLAS.json',{'quadros':proofs,'alteracao_local_joelho_permitida':True,
        'poses_movimento_original_sha256':sha(SOURCE/'poses.json'),'pes_apoio_passagem_iguais':True,
        'corpo_capa_arma_iguais':True,'botas_rgba_iguais':True,'fora_das_pernas_rgba_iguais':True})

def evidence():
    old=[idx(SOURCE/f'quadros/run/run_f{k}.png') for k in range(8)]
    new=[idx(ART/f'quadros/run/run_f{k}.png') for k in range(8)]
    shutil.copyfile(ROOT/'codex/evidencias_forma_humana_48b/run_x4.gif',OUT/'run_antes_x4.gif')
    ims=[B.gray(a).resize((384,256),Image.Resampling.NEAREST).convert('RGB') for a in new]
    ims[0].save(OUT/'run_depois_x4.gif',save_all=True,append_images=ims[1:],duration=[40,40,50,40,40,40,40,40],loop=0,disposal=2,optimize=False)
    sheet=Image.new('RGB',(768,80),(96,96,96));draw=ImageDraw.Draw(sheet)
    for k,a in enumerate(new):sheet.paste(B.gray(a).convert('RGB'),(k*96,16));draw.text((k*96+3,2),f'f{k}',font=B.textfont(10),fill='white')
    sheet.save(OUT/'run_quadros_x1.png');sheet.resize((3072,320),Image.Resampling.NEAREST).save(OUT/'run_quadros_x4.png')
    comp=Image.new('RGB',(8*152,3*122),(96,96,96));draw=ImageDraw.Draw(comp)
    for k in range(8):
        for j,arr in enumerate([old[k],new[k]]):
            view=B.gray(arr).crop((20,34,58,60)).resize((152,104),Image.Resampling.NEAREST)
            comp.paste(view.convert('RGB'),(152*k,j*122+18));draw.text((152*k+3,j*122+2),f'f{k} '+('ANTES' if j==0 else 'DEPOIS'),font=B.textfont(11),fill='white')
        rgba=B.gray(new[k]);overlay=Image.new('RGBA',rgba.size,(0,0,0,0));ma=np.array(Image.open(ART/f'mascaras_edicao/run_f{k}.png'))>0
        oa=np.array(overlay);oa[ma]=(95,210,130,140);overlay=Image.fromarray(oa)
        rgba.alpha_composite(overlay);comp.paste(rgba.crop((20,34,58,60)).resize((152,104),Image.Resampling.NEAREST).convert('RGB'),(152*k,262))
        draw.text((152*k+3,246),'ÁREA EDITÁVEL',font=B.textfont(11),fill='white')
    comp.save(OUT/'PERNAS_ANTES_DEPOIS_MASCARA_x4.png')
    master=Image.open(B.MASTER).convert('RGBA');gray=Image.new('RGBA',master.size,(96,96,96,255));gray.alpha_composite(master)
    comparison=Image.new('RGB',(5*192,180),(96,96,96));draw=ImageDraw.Draw(comparison)
    comparison.paste(gray.crop((9,31,41,51)).resize((192,120),Image.Resampling.NEAREST).convert('RGB'),(0,30));draw.text((4,8),'MESTRE APROVADO ×6',font=B.textfont(12),fill='white')
    for i,k in enumerate((0,4,2,6),1):
        comparison.paste(B.gray(new[k]).crop((20,36,52,56)).resize((192,120),Image.Resampling.NEAREST).convert('RGB'),(i*192,30))
        draw.text((i*192+4,8),f'RUN f{k} ×6',font=B.textfont(12),fill='white')
    comparison.save(OUT/'PERNAS_MESTRE_COMPARACAO.png')
    soles=Image.new('RGB',(1216,280),(96,96,96));draw=ImageDraw.Draw(soles);source_rig=base_rig()
    poses=original_poses()
    for k in range(8):
        _,_,_,bootmask,_=provenance(source_rig,poses['run'][k])
        for j,arr in enumerate((old[k],new[k])):
            only_boots=np.where(bootmask,arr,-1)
            view=B.gray(only_boots).crop((20,38,58,60)).resize((152,88),Image.Resampling.NEAREST)
            soles.paste(view.convert('RGB'),(152*k,24+j*108))
            draw.text((152*k+4,6+j*108),f'f{k} BOTAS '+('ANTES' if j==0 else 'DEPOIS'),font=B.textfont(11),fill='white')
        for j,l in enumerate(poses['run'][k]['pernas']):
            draw.text((152*k+4,232+18*j),f'{l["perna"]}: pe {tuple(l["pe"])}',font=B.textfont(11),fill='white')
    soles.save(OUT/'BOTAS_SOLAS_ANTES_DEPOIS_x4.png')

def verify():
    assert sha(B.MASTER)==B.EXPECTED
    original=original_poses();new=json.loads((ART/'poses.json').read_text(encoding='utf-8'))
    assert original['idle']==new['idle']
    assert sha(SOURCE/'poses.json')==sha(ART/'poses_movimento_original.json')
    rig=Rig.carregar(ART/'rig.json',PAL);source_rig=base_rig()
    neutral=rig.renderizar(B.Tela(50,52,B.MX,B.MY),{}).a
    assert np.array_equal(PAL.para_rgba(neutral),np.array(Image.open(B.MASTER)))
    rigdata=json.loads((ART/'rig.json').read_text(encoding='utf-8'))
    variant_checks=[]
    for name,p in rigdata['partes'].items():
        path=ART/p['arquivo'];assert sha(path)==p['sha256']
        assert all(isinstance(v,int) for v in p['pivo'])
        if p.get('variante'):
            px=np.array(Image.open(path));assert set(np.unique(px[...,3]))=={0,255}
            PAL.de_rgba(px,estrito=True)
            variant_checks.append({'parte':name,'sha256':sha(path),'pivo':p['pivo']})
    assert len(variant_checks)==32
    previous_gif=ROOT/'codex/evidencias_forma_humana_48b/run_x4.gif'
    assert sha(previous_gif)==sha(OUT/'run_antes_x4.gif')
    old_gif=Image.open(previous_gif);new_gif=Image.open(OUT/'run_depois_x4.gif')
    assert old_gif.n_frames==new_gif.n_frames==8 and old_gif.size==new_gif.size==(384,256)
    gif_times=[]
    for k in range(8):
        old_gif.seek(k);new_gif.seek(k)
        assert old_gif.info['duration']==new_gif.info['duration']
        gif_times.append(new_gif.info['duration'])
        expected=B.gray(idx(ART/f'quadros/run/run_f{k}.png')).resize((384,256),Image.Resampling.NEAREST).convert('RGB')
        assert np.array_equal(np.array(new_gif.convert('RGB')),np.array(expected))
    old_contract=json.loads((SOURCE/'contrato_ciclos.json').read_text(encoding='utf-8'))
    contract=json.loads((ART/'contrato_ciclos.json').read_text(encoding='utf-8'));checks=[];sole_checks=[]
    normalized=copy.deepcopy(contract)
    for a,b in zip(old_contract['animacoes'],normalized['animacoes']):
        for q0,q1 in zip(a['quadros'],b['quadros']):
            q1['arquivo']=q0['arquivo'];q1['sha256']=q0['sha256']
    assert normalized==old_contract,'A cycle parameter changed'
    for a,b in zip(old_contract['animacoes'],contract['animacoes']):
        assert a['id']==b['id'] and len(b['quadros'])==8
        assert [q['ms'] for q in a['quadros']]==[q['ms'] for q in b['quadros']]
        if a['id']=='run':assert a['px_por_quadro']==b['px_por_quadro']==6
        else:
            for q in b['quadros']:assert sha(ART/q['arquivo'])==q['sha256']
    for k,(oldrow,newrow) in enumerate(zip(original['run'],new['run'])):
        normalized=copy.deepcopy(newrow)
        for l0,l1 in zip(oldrow['pernas'],normalized['pernas']):
            assert l1.pop('joelho_anterior')==l0['joelho'];l1['joelho']=l0['joelho']
            for name in ('coxa_'+l1['perna'],'canela_'+l1['perna']):l1['partes'][name]=l0['partes'][name]
        assert normalized==oldrow,'A non-leg pose or trajectory changed'
        assert oldrow['pose_rig']==newrow['pose_rig'] and oldrow['capa_origem_quadro']==newrow['capa_origem_quadro']
        old,legs,protected,boots,_=provenance(source_rig,oldrow)
        result=idx(ART/f'quadros/run/run_f{k}.png');edit=np.array(Image.open(ART/f'mascaras_edicao/run_f{k}.png'))>0
        replay,expected_mask,_,_,_=compose(source_rig,rig,oldrow,newrow)
        assert np.array_equal(replay,result),'Saved rig/poses cannot reproduce the frame'
        assert np.array_equal(expected_mask,edit),'Saved edit mask differs from the declared leg corridor'
        old_rgba=np.array(Image.open(SOURCE/f'quadros/run/run_f{k}.png'))
        new_rgba=np.array(Image.open(ART/f'quadros/run/run_f{k}.png'))
        assert np.array_equal(old_rgba[~edit],new_rgba[~edit])
        assert np.array_equal(old_rgba[boots],new_rgba[boots])
        difference=np.any(old_rgba!=new_rgba,axis=2)
        recorded=np.array(Image.open(ART/f'mascaras_edicao/diferenca_f{k}.png'))>0
        assert np.array_equal(difference,recorded) and not (difference&~edit).any()
        assert np.array_equal(old[~edit],result[~edit]) and np.array_equal(old[boots],result[boots])
        assert not (edit&protected).any() and not (result[AY:]>=0).any()
        for l0,l1 in zip(oldrow['pernas'],newrow['pernas']):
            for key in ('perna','fase','apoio','quadril','tornozelo','pe'):assert l0[key]==l1[key]
            assert l0['partes']['bota_'+l0['perna']]==l1['partes']['bota_'+l1['perna']]
            bootname='bota_'+l1['perna'];bp=l1['partes'][bootname]
            native=rig.desenhar_parte(T,bootname,bp['dx'],bp['dy'],ang=0)
            yy,xx=np.where(native>=0);sole=(native>=0)&(np.indices(native.shape)[0]>=yy.max()-1)
            assert np.array_equal(old_rgba[sole],new_rgba[sole])
            sole_checks.append({'quadro':k,'perna':l1['perna'],'fase':l1['fase'],'apoio':l1['apoio'],
                'pe_antes':l0['pe'],'pe_depois':l1['pe'],'linha_sola_antes':int(yy.max()),
                'linha_sola_depois':int(yy.max()),'mascara_sola_sha256':hashlib.sha256(sole.tobytes()).hexdigest(),
                'pixels_sola_rgba_identicos':True})
            for name in ('coxa_'+l1['perna'],'canela_'+l1['perna']):
                p=l1['partes'][name];layer=rig.desenhar_parte(T,name,p['dx'],p['dy'],ang=0,variante=p['variante'])
                expected=idx(ART/f'variantes/{p["variante"]}.png')
                assert np.array_equal(layer,expected),'Variant pivot registration differs'
        count,sizes=componentes(result);assert count==1,(k,sizes)
        isolated=int(((result>=0)&~np.any(_vizinhos(result)==result,axis=0)).sum())
        assert isolated==0,(k,'Isolated colours',isolated)
        px=np.array(Image.open(ART/f'quadros/run/run_f{k}.png'));assert set(np.unique(px[...,3]))=={0,255}
        checks.append({'quadro':k,'componentes':count,'cores_isoladas':isolated,'fora_mascara_rgba_identico':True,
            'botas_rgba_identicas':True,'replay_rgba_identico':True,'pixels_alterados':int(difference.sum()),
            'mascara_sha256':sha(ART/f'mascaras_edicao/run_f{k}.png')})
    save(OUT/'VERIFICACAO_PERNAS.json',{'aprovado':True,'quadros':checks,'mestre_sha256':B.EXPECTED,
        'paleta':'paleta_bosque_v1','alpha':[0,255],'ancora':[AX,AY],'ms_iguais':True,'px_por_quadro':6,
        'articulacoes_modificadas':['joelho'],'trajetorias_solas_iguais':True,'corpo_capa_arma_iguais':True,
        'idle_neutra_mestre_preservados':True,'arte_instalada':False,'variantes_orientadas':variant_checks,
        'solas':sole_checks,'replay_rig_poses_8_quadros_rgba_identico':True,
        'gif_quadros_ms_antes_depois':gif_times,'gif_antes_copia_sha256_identica':True})
    print('4.8b1: oito quadros conferidos; só pernas editadas, botas/movimento intactos.')

def preview():
    # Read-only original renderer, only rebinding its destinations in memory.
    B.ART=ART;B.OUT=OUT;B.preview();B.verify_preview()
    old=json.loads((ROOT/'codex/evidencias_forma_humana_48b/PREVIA_DESLOCAMENTO.json').read_text(encoding='utf-8'))
    new=json.loads((OUT/'PREVIA_DESLOCAMENTO.json').read_text(encoding='utf-8'))
    assert old['quadros']==new['quadros'] and old['eventos_troca']==new['eventos_troca']
    assert old['velocidades']==new['velocidades']
    save(OUT/'PREVIA_MOVIMENTO_COMPARACAO.json',{'aprovado':True,'quadros_comparados':600,
        'posicao_velocidade_distancia_fase_solas_iguais':True,'eventos_troca_iguais':True,'duracao_s':20,
        'oscilacao_6px_preservada':True,'arte_instalada':False})

def reproduce():
    evidence_names=('MASCARAS_POSES_SOLAS.json','VERIFICACAO_PERNAS.json',
        'run_antes_x4.gif','run_depois_x4.gif','run_quadros_x1.png','run_quadros_x4.png',
        'PERNAS_ANTES_DEPOIS_MASCARA_x4.png','PERNAS_MESTRE_COMPARACAO.png','BOTAS_SOLAS_ANTES_DEPOIS_x4.png')
    def snapshot():
        paths=sorted(p for p in ART.rglob('*') if p.is_file())+[OUT/n for n in evidence_names]
        return {p.relative_to(ROOT).as_posix():sha(p) for p in paths}
    before=snapshot();generate();evidence();verify();after=snapshot()
    differences=[p for p in before.keys()|after.keys() if before.get(p)!=after.get(p)]
    assert not differences,differences
    save(OUT/'REPRODUCAO.json',{'aprovado':True,'arquivos_conferidos':len(before),
        'segunda_geracao_sha256_identica':True,'diferencas':differences,'sha256':after})
    print(f'Reprodução idêntica: {len(before)} arquivos.')

def main():
    parser=argparse.ArgumentParser();options=parser.add_mutually_exclusive_group()
    for flag in ('verify','preview','reproduce'):options.add_argument('--'+flag,action='store_true')
    args=parser.parse_args()
    ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    if args.verify:verify();return
    if args.preview:verify();preview();return
    if args.reproduce:reproduce();return
    generate();evidence();verify()

if __name__=='__main__':main()
