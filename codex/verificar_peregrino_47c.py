"""4.7c: isolated suites and complete SHA256 audit with explicit diary changes."""
from pathlib import Path
import copy, importlib.util, json, sys, shutil
ROOT=Path(__file__).resolve().parents[1]
s=importlib.util.spec_from_file_location('f7',ROOT/'codex/verificar_peregrino_corrompido.py')
f7=importlib.util.module_from_spec(s);s.loader.exec_module(f7)
OUT=ROOT/'codex/evidencias_peregrino_47c';OUT.mkdir(parents=True,exist_ok=True)
f7.EVIDENCE=f7.f6.EVIDENCE=f7.f6.previous.EVIDENCE=f7.f6.api.EVIDENCE=OUT
f7.f6.api.RUNTIME=ROOT/'.godot/peregrino_47c'
PACK=ROOT/'assets/enemies/peregrino_corrompido_v1'
ART=ROOT/'arte_fonte/peregrino_corrompido_v1/ajuste_47c'
TARGETS=('patrulha','perseguicao')
ALLOWED=('codex/evidencias_peregrino_47c','codex/verificar_peregrino_47c.py','codex/RELATORIO_PEREGRINO_47C.md',
 'codex/capturar_peregrino_47c.py','codex/testes/capturar_peregrino_47c.gd',
 'arte_fonte/ferramentas/ajustar_peregrino_47c.py','arte_fonte/ferramentas/gerar_peregrino_corrompido.py',
 'arte_fonte/peregrino_corrompido_v1/ajuste_47c','assets/enemies/peregrino_corrompido_v1/manifesto_sprites.json')+tuple(
 'assets/enemies/peregrino_corrompido_v1/sprites/%s_f%02d.png'%(name,i) for name in TARGETS for i in range(8))

def save(name,x):f7.save(name,x)
def normal_manifest(m):
 m=copy.deepcopy(m)
 for a in m['animacoes']:
  if a['id'] in TARGETS:
   for q in a['quadros']:q['sha256']='ART_ONLY'
 return m

def preservation(label):
 roots={'integracao_protegida':ROOT,'prova':f7.f6.PROVA,'P40':f7.f6.api.REFERENCE,
        'original':f7.f6.api.PRIMARY,'pacotes_aprovados':f7.SOURCE/'pacotes'}
 d={'branch':f7.f6.api.git('branch','--show-current'),'main':f7.f6.api.git('rev-parse','main'),
 'original_head':f7.f6.api.git('rev-parse','HEAD',cwd=f7.f6.api.PRIMARY),
 'original_status':f7.f6.api.git('status','--porcelain=v1','-uall',cwd=f7.f6.api.PRIMARY),
 'sha256':{n:f7.snapshot(p,ALLOWED if n=='integracao_protegida' else ('runtime',) if n=='P40' else ()) for n,p in roots.items()},
 'exclusoes_autorizadas':list(ALLOWED),'cache_ignorado':['.git','.godot','__pycache__','P40/runtime']}
 d['sha256']['historico']={'ESTADO_DO_PROJETO.md':f7.sha(f7.SOURCE/'ESTADO_DO_PROJETO.md')}
 save('PRESERVACAO_'+label+'.json',d)
 if label=='antes':
  save('MANIFESTO_antes.json',json.loads((PACK/'manifesto_sprites.json').read_text(encoding='utf-8')))
  save('PACOTE_SHA256_antes.json',f7.snapshot(PACK))
  base=ART/'base_47b';base.mkdir(parents=True,exist_ok=True)
  for name in TARGETS:
   gifs=OUT/'antes_gifs_x4';gifs.mkdir(exist_ok=True)
   shutil.copyfile(ROOT/'codex/evidencias_peregrino_47b/depois_gifs_x4'/f'{name}_x4.gif',gifs/f'{name}_x4.gif')
   for i in range(8):shutil.copyfile(PACK/'sprites'/f'{name}_f{i:02d}.png',base/f'{name}_f{i:02d}.png')
  print({n:len(v) for n,v in d['sha256'].items()},flush=True);return
 old=json.loads((OUT/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
 changes={n:[{'arquivo':p,'antes':v.get(p),'depois':d['sha256'][n].get(p)} for p in sorted(v.keys()|d['sha256'][n].keys()) if v.get(p)!=d['sha256'][n].get(p)] for n,v in old['sha256'].items()}
 diary='codex/diretor/DIARIO_DIRETOR.md'
 external=[x for x in changes['integracao_protegida'] if x['arquivo']==diary]
 unexplained={n:[x for x in v if not (n=='integracao_protegida' and x['arquivo']==diary)] for n,v in changes.items()}
 meta={k:d[k]==old[k] for k in ('branch','main','original_head','original_status')}
 contract=normal_manifest(json.loads((OUT/'MANIFESTO_antes.json').read_text(encoding='utf-8')))==normal_manifest(json.loads((PACK/'manifesto_sprites.json').read_text(encoding='utf-8')))
 result={'protegidos_preservados':not any(unexplained.values()) and all(meta.values()) and contract,
 'preservacao_integral':not any(changes.values()) and all(meta.values()) and contract,
 'metadados':meta,'contrato_preservado':contract,'alteracoes_todas':changes,
 'alteracoes_externas_autorizadas_diario':external,'outras_diferencas':unexplained,
 'arquivos':{n:len(v) for n,v in d['sha256'].items()}}
 save('PRESERVACAO_resultado.json',result);print(result,flush=True);assert result['protegidos_preservados']

def one(path,label):
 text=(ROOT/path).read_text(encoding='utf-8')
 for prefix in ['evidencias_integracao_p40_f%d'%i for i in (3,4,5,6)]+['evidencias_peregrino_corrompido','evidencias_peregrino_47b']:
  text=text.replace('res://codex/'+prefix+'/','res://codex/evidencias_peregrino_47c/'+label+'/')
 for prefix in ('p40_runtime_f5','p40_runtime_f6','peregrino_corrompido_47','peregrino_47b'):
  text=text.replace('res://.godot/'+prefix+'/','res://.godot/peregrino_47c/'+label+'/')
 fixture=f7.f6.api.RUNTIME/label/'fixtures'/Path(path).name;fixture.parent.mkdir(parents=True,exist_ok=True)
 (OUT/label).mkdir(parents=True,exist_ok=True);fixture.write_text(text,encoding='utf-8',newline='\n')
 result=f7.f6.previous.run_one(fixture.relative_to(ROOT).as_posix(),label);result['teste']=path;return result

f7.one=one
if __name__=='__main__':
 action=sys.argv[1]
 if action.startswith('preserve-'):preservation('antes' if action.endswith('before') else 'depois')
 elif action in ('before','after'):f7.tests('antes' if action=='before' else 'depois')
 elif action=='new':
  r=one('codex/testes/verify_peregrino_corrompido.gd','novos');save('TESTES_novos.json',r);f7.require_passed([r])
