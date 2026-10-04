"""4.8b4: regression in isolated evidence and a complete immutable-source audit."""
from pathlib import Path
import hashlib, importlib.util, json, subprocess, sys
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('f7', ROOT/'codex/verificar_peregrino_corrompido.py')
f7 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(f7)
OUT = ROOT/'codex/evidencias_forma_humana_48b6'
OUT.mkdir(parents=True, exist_ok=True)
f7.EVIDENCE = f7.f6.EVIDENCE = f7.f6.previous.EVIDENCE = f7.f6.api.EVIDENCE = OUT
f7.f6.api.RUNTIME = ROOT/'.godot/forma_humana_48b6'
ALLOWED = ('arte_fonte/forma_humana_v1/pose_corrida_48b6',
           'arte_fonte/ferramentas/adaptar_corrida_forma_humana_48b6.py',
           'codex/evidencias_forma_humana_48b6',
           'codex/verificar_forma_humana_48b6.py',
           'codex/RELATORIO_FORMA_HUMANA_48B6.md')

def save(name, obj):
    (OUT/name).write_text(json.dumps(obj, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')

def preservation(label):
    roots = {'integracao_protegida': ROOT, 'prova': f7.f6.PROVA,
             'P40': f7.f6.api.REFERENCE, 'original': f7.f6.api.PRIMARY,
             'pacotes_aprovados': f7.SOURCE/'pacotes', 'referencias_elenco': f7.SOURCE/'referencias/elenco'}
    data = {'branch': f7.f6.api.git('branch', '--show-current'),
            'main': f7.f6.api.git('rev-parse', 'main'),
            'original_head': f7.f6.api.git('rev-parse', 'HEAD', cwd=f7.f6.api.PRIMARY),
            'original_status': f7.f6.api.git('status', '--porcelain=v1', '-uall', cwd=f7.f6.api.PRIMARY),
            'sha256': {n: f7.snapshot(p, ALLOWED if n == 'integracao_protegida' else ('runtime',) if n == 'P40' else ()) for n,p in roots.items()},
            'exclusoes_da_etapa': list(ALLOWED), 'cache_ignorado': ['.git', '.godot', '__pycache__', 'P40/runtime']}
    data['sha256']['historico'] = {'ESTADO_DO_PROJETO.md': f7.sha(f7.SOURCE/'ESTADO_DO_PROJETO.md')}
    data['mestre_aprovado'] = f7.sha(ROOT/'arte_fonte/forma_humana_v1/forma_humana_mestre_x1.png')
    assert data['mestre_aprovado'] == '204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988'
    data['conceito_original'] = f7.snapshot(ROOT/'arte_fonte/forma_humana_conceito_v1')
    assert data['branch'] == 'feature/integracao-p40'
    save('PRESERVACAO_'+label+'.json', data)
    if label == 'antes':
        print({n: len(v) for n,v in data['sha256'].items()}, flush=True)
        return
    old = json.loads((OUT/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
    changes = {n: [{'arquivo': p, 'antes': v.get(p), 'depois': data['sha256'][n].get(p)}
                   for p in sorted(v.keys() | data['sha256'][n].keys()) if v.get(p) != data['sha256'][n].get(p)]
               for n,v in old['sha256'].items()}
    meta = {k: data[k] == old[k] for k in ('branch', 'main', 'original_head', 'original_status', 'conceito_original', 'mestre_aprovado')}
    diary = [x for x in changes['integracao_protegida'] if x['arquivo'].startswith('codex/diretor/')]
    result = {'preservado': not any(changes.values()) and all(meta.values()), 'metadados': meta,
              'alteracoes_todas': changes, 'alteracoes_externas_diretor': diary,
              'arquivos': {n: len(v) for n,v in data['sha256'].items()}, 'conceito_original': data['conceito_original']}
    save('PRESERVACAO_resultado.json', result)
    print(json.dumps(result, ensure_ascii=False), flush=True)
    assert result['preservado'], 'Protected files changed; all differences are reported above.'

def one(path, label):
    text = (ROOT/path).read_text(encoding='utf-8')
    for prefix in ['evidencias_integracao_p40_f%d'%i for i in (3,4,5,6)] + ['evidencias_peregrino_corrompido', 'evidencias_peregrino_47b', 'evidencias_peregrino_47c', 'evidencias_forma_humana_48a']:
        text = text.replace('res://codex/'+prefix+'/', 'res://codex/evidencias_forma_humana_48b6/'+label+'/')
    for prefix in ('p40_runtime_f5', 'p40_runtime_f6', 'peregrino_corrompido_47', 'peregrino_47b', 'peregrino_47c', 'forma_humana_48a'):
        text = text.replace('res://.godot/'+prefix+'/', 'res://.godot/forma_humana_48b6/'+label+'/')
    fixture = f7.f6.api.RUNTIME/label/'fixtures'/Path(path).name
    fixture.parent.mkdir(parents=True, exist_ok=True)
    (OUT/label).mkdir(parents=True, exist_ok=True)
    fixture.write_text(text, encoding='utf-8', newline='\n')
    result = f7.f6.previous.run_one(fixture.relative_to(ROOT).as_posix(), label)
    result['teste'] = path
    return result

f7.one = one

def tests(label):
    f7.tests(label)
    real = one('codex/testes/verify_peregrino_corrompido.gd', label+'_pacote_real')
    save('TESTE_PACOTE_REAL_'+label+'.json', real)
    f7.require_passed([real])
    if label == 'depois':
        old = json.loads((OUT/'TESTES_antes.json').read_text(encoding='utf-8'))
        new = json.loads((OUT/'TESTES_depois.json').read_text(encoding='utf-8'))
        assert len(old) == len(new) == 25
        comparison = [{'teste': a['teste'], 'aprovado_antes': a['aprovado'], 'aprovado_depois': b['aprovado'],
                       'pass_antes': a['pass'], 'pass_depois': b['pass']} for a,b in zip(old,new)]
        save('TESTES_COMPARACAO.json', comparison)
        assert all(a['teste'] == b['teste'] and a['aprovado'] == b['aprovado'] and a['pass'] == b['pass'] for a,b in zip(old,new))

def audit_art():
    baseline = json.loads((OUT/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
    old = baseline['sha256']['integracao_protegida']
    prefixes = ('arte_fonte/forma_humana_v1/', 'arte_fonte/forma_humana_conceito_v1/',
                'codex/evidencias_forma_humana_48', 'codex/RELATORIO_FORMA_HUMANA_48',
                'arte_fonte/ferramentas/animar_forma_humana_48b.py',
                'arte_fonte/ferramentas/corrigir_pernas_forma_humana_48b1.py',
                'arte_fonte/ferramentas/propor_pernas_forma_humana_48b2.py',
                'arte_fonte/ferramentas/propor_pernas_forma_humana_48b3.py')
    previous = {p:h for p,h in old.items() if p.startswith(prefixes)}
    changes = [{'arquivo':p, 'antes':h, 'depois':f7.sha(ROOT/p) if (ROOT/p).is_file() else None}
               for p,h in previous.items() if not (ROOT/p).is_file() or f7.sha(ROOT/p) != h]
    director = {p:h for p,h in old.items() if p.startswith('codex/diretor/')}
    kit = {p:h for p,h in old.items() if p.startswith('arte_fonte/kit_rig/')}
    f2f6 = {p:h for p,h in previous.items() if p.startswith('arte_fonte/forma_humana_v1/poses_chave_48b2/')
            and ('f2' in p or 'f6' in p)}
    result = {'preservado':not changes,'arquivos_arte_e_evidencias_anteriores':len(previous),
              'diferencas':changes,'sha256':previous,'f2_f6_preservados':f2f6, 'f4_preservado':{p:h for p,h in previous.items() if p.startswith('arte_fonte/forma_humana_v1/poses_chave_48b3/') and 'f4' in p},
              'diretor':{'arquivos':len(director),'sha256':director,'incluido_no_commit':False},
              'kit_pendente':{'arquivos':len(kit),'sha256':kit,'incluido_no_commit':False}}
    save('AUDITORIA_ARTE_ANTERIOR.json', result)
    assert result['preservado'], changes
    print({'arte_anterior':len(previous), 'f2_f6':len(f2f6), 'diferenças':len(changes)}, flush=True)

def deliveries():
    data = {}
    for relative in ALLOWED + ('arte_fonte/forma_humana_v1/referencia_corrida_48b5',):
        root = ROOT/relative
        paths = root.rglob('*') if root.is_dir() else [root]
        for p in sorted(paths):
            if p.is_file() and p != OUT/'SHA256_ENTREGAS.json':
                data[p.relative_to(ROOT).as_posix()] = {'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
                                                      'bytes':p.stat().st_size}
    assert not any(Path(p).suffix.lower() in ('.gif','.mp4','.avi','.webm') for p in data)
    save('SHA256_ENTREGAS.json', {'arquivos':data,'quantidade':len(data),
                               'exclusao_autorreferencial':'SHA256_ENTREGAS.json'})
    print({'arquivos_entregues':len(data)}, flush=True)

def check_stage():
    def git(*args, **kwargs):
        return subprocess.check_output(['git',*args],cwd=ROOT,**kwargs)
    assert git('branch','--show-current').decode().strip() == 'feature/integracao-p40'
    assert git('rev-parse','HEAD').decode().strip() == '2c167757afd6ed2ec91079b24887998df26355dd'
    assert git('rev-parse','main').decode().strip() == 'ef24b5561cacb823d1f719370c29d82522cb5b58'
    assert not git('diff','--name-only'), 'Tracked working-tree changes outside stage'
    statuses=git('diff','--cached','--name-status','-z').decode().strip('\0').split('\0')
    assert all(s == 'A' for s in statuses[::2]), 'Only new files may be staged'
    names=statuses[1::2]
    assert all(any(n == p or n.startswith(p+'/') for p in ALLOWED + ('arte_fonte/forma_humana_v1/referencia_corrida_48b5',)) for n in names)
    manifest=json.loads((OUT/'SHA256_ENTREGAS.json').read_text(encoding='utf-8'))['arquivos']
    assert set(names) == set(manifest) | {'codex/evidencias_forma_humana_48b6/SHA256_ENTREGAS.json'}
    blobs=git('cat-file','--batch',input=''.join(':'+n+'\n' for n in names).encode())
    offset=0
    for n in names:
        end=blobs.index(b'\n',offset)
        header=blobs[offset:end].split();assert header[1] == b'blob'
        size=int(header[2]);blob=blobs[end+1:end+1+size];offset=end+2+size
        assert blob == (ROOT/n).read_bytes(), 'Staged bytes differ from audited source: '+n
        if n in manifest:
            assert len(blob) == manifest[n]['bytes']
            assert hashlib.sha256(blob).hexdigest() == manifest[n]['sha256']
    assert offset == len(blobs)
    whitespace = subprocess.run(['git','diff','--cached','--check'],cwd=ROOT,capture_output=True,text=True)
    # The already-approved, SHA-protected prompt has a final blank line. Keep
    # those bytes exactly; accept only this specific preexisting source warning.
    accepted = 'arte_fonte/forma_humana_v1/referencia_corrida_48b5/PROMPT.txt:32: new blank line at EOF.\n'
    assert whitespace.returncode == 0 or (whitespace.returncode == 2 and whitespace.stdout == accepted), whitespace.stdout + whitespace.stderr
    assert not whitespace.stderr
    print({'stage_aprovado':True,'somente_arquivos_novos':len(names),
           'sha256_conferido':len(manifest),'diretor_e_kit_incluidos':False,
           'aviso_fonte_preservada':whitespace.stdout.strip()},flush=True)

if __name__ == '__main__':
    action = sys.argv[1]
    if action.startswith('preserve-'):
        preservation('antes' if action.endswith('before') else 'depois')
    elif action in ('before', 'after'):
        tests('antes' if action == 'before' else 'depois')
    elif action == 'audit-art':
        audit_art()
    elif action == 'deliveries':
        deliveries()
    elif action == 'check-stage':
        check_stage()
    else:
        raise ValueError(action)
