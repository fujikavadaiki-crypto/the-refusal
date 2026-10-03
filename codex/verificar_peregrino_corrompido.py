from pathlib import Path
import argparse, importlib.util, json, hashlib, os, concurrent.futures, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
EVIDENCE=ROOT/'codex/evidencias_peregrino_corrompido'
EVIDENCE.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('f6',ROOT/'codex/verificar_fase6.py')
f6=importlib.util.module_from_spec(spec);spec.loader.exec_module(f6)
f6.EVIDENCE=f6.previous.EVIDENCE=f6.api.EVIDENCE=EVIDENCE
f6.api.RUNTIME=ROOT/'.godot/peregrino_corrompido_47'
SOURCE=f6.PROVA.parent
SKIP={'.git','.godot','__pycache__'}
ALLOWED=('arte_fonte/peregrino_corrompido_v1', 'arte_fonte/ferramentas/gerar_peregrino_corrompido.py', 'assets/enemies/peregrino_corrompido_v1', 'codex/MANUAL_CODEX.md', 'codex/README_INTEGRACAO_P40.md', 'codex/CONTRATO_PACOTE_INIMIGO.md', 'codex/RELATORIO_PEREGRINO_CORROMPIDO.md', 'codex/evidencias_peregrino_corrompido', 'codex/verificar_peregrino_corrompido.py', 'codex/capturar_peregrino_corrompido.py', 'codex/testes/capturar_peregrino_corrompido.gd', 'codex/testes/verify_peregrino_corrompido.gd', 'codex/testes/verify_integracao_p40_f6.gd', 'codex/fixtures/peregrino_profanado_mapa.json', 'scripts/enemies/presentation/enemy_presenter.gd', 'scripts/enemies/presentation/enemy_package.gd', 'data/enemies/peregrino_mapa.json')
def sha(p): return f6.api.digest(p)
def snapshot(root, exclude=()):
 result={}
 for directory,folders,files in os.walk(root):
  rel=Path(directory).relative_to(root).as_posix()
  folders[:]=[x for x in folders if x not in SKIP and (Path(directory)/x).relative_to(root).as_posix() not in exclude]
  for name in files:
   path=Path(directory)/name; relative=path.relative_to(root).as_posix()
   if relative in exclude: continue
   result[relative]=sha(path)
 return result

def save(name,obj):
 (EVIDENCE/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def preservation(label):
 paths=[('arte_fonte',ROOT/'arte_fonte'),('referencia_P40',f6.api.REFERENCE),('prova',f6.PROVA),('checkout_original',f6.api.PRIMARY),('pacotes_aprovados',SOURCE/'pacotes')]
 data={'branch':f6.api.git('branch','--show-current'),'main':f6.api.git('rev-parse','main'),'checkout_head':f6.api.git('rev-parse','HEAD',cwd=f6.api.PRIMARY),'checkout_status':f6.api.git('status','--porcelain=v1','-uall',cwd=f6.api.PRIMARY),'exclusoes':{'todos':['.git','.godot','__pycache__'],'referencia_P40':['runtime']},'sha256':{n:snapshot(p,('runtime',) if n=='referencia_P40' else ('peregrino_corrompido_v1','ferramentas/gerar_peregrino_corrompido.py') if n=='arte_fonte' else ()) for n,p in paths}}
 data['sha256']['integracao_anterior']=snapshot(ROOT,ALLOWED)
 data['sha256']['profanado_arquivado']=snapshot(ROOT/'assets/enemies/peregrino_v1')
 data['sha256']['historico']={'ESTADO_DO_PROJETO.md':sha(SOURCE/'ESTADO_DO_PROJETO.md')}
 save('PRESERVACAO_'+label+'.json',data)
 if label=='depois':
  before=json.loads((EVIDENCE/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
  changes={n:[k for k in sorted(old.keys()|data['sha256'][n].keys()) if old.get(k)!=data['sha256'][n].get(k)] for n,old in before['sha256'].items()}
  meta={k:before[k]==data[k] for k in ['branch','main','checkout_head','checkout_status']}
  result={'preservado':not any(changes.values()) and all(meta.values()),'metadados':meta,'alteracoes':changes,'arquivos':{n:len(x) for n,x in data['sha256'].items()}}
  save('PRESERVACAO_resultado.json',result)
  print(json.dumps(result,ensure_ascii=False),flush=True)
  assert result['preservado']
 else: print({n:len(x) for n,x in data['sha256'].items()},flush=True)

def one(path,label):
 source=(ROOT/path).read_text(encoding='utf-8')
 if path.endswith('verify_peregrino_corrompido.gd'): source=source.replace('res://codex/evidencias_peregrino_corrompido/','res://codex/evidencias_peregrino_corrompido/'+label+'/')
 for number in (3,4,5,6): source=source.replace('res://codex/evidencias_integracao_p40_f%d/'%number,'res://codex/evidencias_peregrino_corrompido/'+label+'/')
 source=source.replace('res://.godot/p40_runtime_f5/','res://.godot/peregrino_corrompido_47/'+label+'/').replace('res://.godot/p40_runtime_f6/','res://.godot/peregrino_corrompido_47/'+label+'/')
 fixture=f6.api.RUNTIME/label/'fixtures'/Path(path).name
 fixture.parent.mkdir(parents=True,exist_ok=True);(EVIDENCE/label).mkdir(parents=True,exist_ok=True)
 fixture.write_text(source,encoding='utf-8',newline='\n')
 result=f6.previous.run_one(fixture.relative_to(ROOT).as_posix(),label)
 result['teste']=path
 return result

def require_passed(results, legacy=False):
 accepted={'tests/verify_carrasco_gif_test.gd','tests/verify_milestone8_2.gd'} if legacy else set()
 unexpected=[x['teste'] for x in results if not x['aprovado'] and x['teste'] not in accepted]
 if unexpected: raise RuntimeError('Falhas nao aceitas: '+', '.join(unexpected))

def tests(label):
 paths=sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'tests').glob('verify_*.gd'))+['codex/testes/verify_integracao_p40_f%d.gd'%n for n in range(1,7)]
 with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool: results=list(pool.map(lambda p:one(p,label),paths))
 save('TESTES_'+label+'.json',results)
 require_passed(results,legacy=True)
 print({'label':label,'suites':len(results),'approved':sum(t['aprovado'] for t in results),'pass':sum(t['pass'] for t in results)},flush=True)

if __name__=='__main__':
 action=sys.argv[1]
 if action=='preserve-before': preservation('antes')
 elif action=='preserve-after': preservation('depois')
 elif action=='new':
  result=one('codex/testes/verify_peregrino_corrompido.gd','novos');save('TESTES_novos.json',result);require_passed([result])
 elif action in ('before','after'): tests('antes' if action=='before' else 'depois')
