"""Art-only 4.7b: isolated regressions, exact manifest contract and SHA256 audit."""
from pathlib import Path
import copy, importlib.util, json, sys, shutil
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('f7',ROOT/'codex/verificar_peregrino_corrompido.py')
f7=importlib.util.module_from_spec(spec);spec.loader.exec_module(f7)
OUT=ROOT/'codex/evidencias_peregrino_47b';OUT.mkdir(parents=True,exist_ok=True)
f7.EVIDENCE=f7.f6.EVIDENCE=f7.f6.previous.EVIDENCE=f7.f6.api.EVIDENCE=OUT
f7.f6.api.RUNTIME=ROOT/'.godot/peregrino_47b'
TARGETS=('patrulha','perseguicao','ruptura','morte')
PACK=ROOT/'assets/enemies/peregrino_corrompido_v1'
ALLOWED=('codex/evidencias_peregrino_47b','codex/verificar_peregrino_47b.py','codex/RELATORIO_PEREGRINO_47B.md',
 'codex/testes/foto_peregrino_47b.gd','arte_fonte/ferramentas/ajustar_peregrino_47b.py',
 'arte_fonte/ferramentas/gerar_peregrino_corrompido.py',
 'arte_fonte/peregrino_corrompido_v1/ajuste_47b',
 'assets/enemies/peregrino_corrompido_v1/manifesto_sprites.json')+tuple(
 'assets/enemies/peregrino_corrompido_v1/sprites/%s_f%02d.png'%(name,i)
 for name,count in zip(TARGETS,(8,8,7,8)) for i in range(count))

def save(name,value):f7.save(name,value)
def normal_manifest(data):
 data=copy.deepcopy(data)
 for a in data['animacoes']:
  if a['id'] in TARGETS:
   for q in a['quadros']:q['sha256']='ART_ONLY'
 return data

def preserve(label):
 roots={'integracao_protegida':ROOT,'prova':f7.f6.PROVA,'P40':f7.f6.api.REFERENCE,
        'original':f7.f6.api.PRIMARY,'pacotes_aprovados':f7.SOURCE/'pacotes'}
 data={'branch':f7.f6.api.git('branch','--show-current'),'main':f7.f6.api.git('rev-parse','main'),
       'original_head':f7.f6.api.git('rev-parse','HEAD',cwd=f7.f6.api.PRIMARY),
       'original_status':f7.f6.api.git('status','--porcelain=v1','-uall',cwd=f7.f6.api.PRIMARY),
       'sha256':{name:f7.snapshot(p,ALLOWED if name=='integracao_protegida' else ('runtime',) if name=='P40' else ()) for name,p in roots.items()}}
 data['sha256']['historico']={'ESTADO_DO_PROJETO.md':f7.sha(f7.SOURCE/'ESTADO_DO_PROJETO.md')}
 save('PRESERVACAO_'+label+'.json',data)
 if label=='antes':
  save('MANIFESTO_antes.json',json.loads((PACK/'manifesto_sprites.json').read_text(encoding='utf-8')))
  save('PACOTE_SHA256_antes.json',f7.snapshot(PACK))
  for name in TARGETS:
   dest=OUT/'antes_gifs_x4';dest.mkdir(exist_ok=True)
   shutil.copyfile(ROOT/'codex/evidencias_peregrino_corrompido/gifs_x4'/f'{name}_x4.gif',dest/f'{name}_x4.gif')
  print({n:len(v) for n,v in data['sha256'].items()},flush=True)
 else:
  old=json.loads((OUT/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
  # The old generator now delegates to the revised art-only builder/verifier.
  # Baseline recorded its original hash; protect every other existing file.
  protected=copy.deepcopy(old['sha256'])
  protected['integracao_protegida'].pop('arte_fonte/ferramentas/gerar_peregrino_corrompido.py',None)
  changes={n:[k for k in sorted(v.keys()|data['sha256'][n].keys()) if v.get(k)!=data['sha256'][n].get(k)] for n,v in protected.items()}
  metadata={k:old[k]==data[k] for k in ('branch','main','original_head','original_status')}
  before=json.loads((OUT/'MANIFESTO_antes.json').read_text(encoding='utf-8'))
  after=json.loads((PACK/'manifesto_sprites.json').read_text(encoding='utf-8'))
  contract=normal_manifest(before)==normal_manifest(after)
  result={'preservado':not any(changes.values()) and all(metadata.values()) and contract,
          'metadados':metadata,'contrato_tempos_ancoras_areas_cadencia_preservado':contract,
          'alteracoes':changes,'arquivos':{n:len(v) for n,v in data['sha256'].items()},
          'excecoes_autorizadas':list(ALLOWED)}
  # A pre-existing untracked director diary was edited concurrently outside
  # this task. Keep its difference visible, never restore or stage that file.
  external='codex/diretor/DIARIO_DIRETOR.md'
  tracked=set(f7.f6.api.git('ls-files').splitlines())
  result['alteracoes_externas']=[]
  for path in changes['integracao_protegida']:
   if path==external and path not in tracked:
    result['alteracoes_externas'].append({'arquivo':path,'versionado':False,
      'sha256_antes':old['sha256']['integracao_protegida'].get(path),
      'sha256_depois':data['sha256']['integracao_protegida'].get(path),
      'nota':'Arquivo preexistente fora do Git, alterado durante a tarefa; nenhuma operacao desta tarefa escreveu nele. Preservado em disco, fora do commit.'})
  unexplained={n:[p for p in paths if not (n=='integracao_protegida' and p==external and p not in tracked)] for n,paths in changes.items()}
  result['preservacao_da_tarefa_confirmada']=not any(unexplained.values()) and all(metadata.values()) and contract
  result['alteracoes_nao_explicitadas']=unexplained
  save('PRESERVACAO_resultado.json',result);print(result,flush=True);assert result['preservacao_da_tarefa_confirmada']

def one(path,label):
 source=(ROOT/path).read_text(encoding='utf-8')
 for n in (3,4,5,6):source=source.replace('res://codex/evidencias_integracao_p40_f%d/'%n,'res://codex/evidencias_peregrino_47b/'+label+'/')
 source=source.replace('res://codex/evidencias_peregrino_corrompido/','res://codex/evidencias_peregrino_47b/'+label+'/')
 for name in ('p40_runtime_f5','p40_runtime_f6','peregrino_corrompido_47'):
  source=source.replace('res://.godot/'+name+'/','res://.godot/peregrino_47b/'+label+'/')
 fixture=f7.f6.api.RUNTIME/label/'fixtures'/Path(path).name;fixture.parent.mkdir(parents=True,exist_ok=True)
 (OUT/label).mkdir(parents=True,exist_ok=True);fixture.write_text(source,encoding='utf-8',newline='\n')
 result=f7.f6.previous.run_one(fixture.relative_to(ROOT).as_posix(),label);result['teste']=path;return result

f7.one=one
if __name__=='__main__':
 action=sys.argv[1]
 if action.startswith('preserve-'):preserve('antes' if action.endswith('before') else 'depois')
 elif action in ('before','after'):f7.tests('antes' if action=='before' else 'depois')
 elif action=='new':
  r=one('codex/testes/verify_peregrino_corrompido.gd','novos');save('TESTES_novos.json',r);f7.require_passed([r])
