"""4.8b8: regression in isolated evidence and a complete immutable-source audit."""
from pathlib import Path
import hashlib, importlib.util, json, subprocess, sys
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('f7', ROOT/'codex/verificar_peregrino_corrompido.py')
f7 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(f7)
OUT = ROOT/'codex/evidencias_forma_humana_48b8'
OUT.mkdir(parents=True, exist_ok=True)
f7.EVIDENCE = f7.f6.EVIDENCE = f7.f6.previous.EVIDENCE = f7.f6.api.EVIDENCE = OUT
f7.f6.api.RUNTIME = ROOT/'.godot/forma_humana_48b8'
ALLOWED = ('arte_fonte/forma_humana_v1/rig_corrida_48b8_capa',
           'arte_fonte/ferramentas/animar_capa_forma_humana_48b8.py',
           'codex/evidencias_forma_humana_48b8',
           'codex/verificar_forma_humana_48b8.py',
           'codex/RELATORIO_FORMA_HUMANA_48B8.md')

# External Director collection observed with the user's reference complement.
# Fixed expected hashes accept only these known changes, never arbitrary drift.
AUTHORIZED_EXTERNAL = {'codex/diretor/DIARIO_DIRETOR.md': 'c253a37137e984882a2a12a38bba5bc9732d8bfd8f0fada5b730fe6ca9e010a2', 'codex/diretor/REFERENCIA_PRINCIPAL.md': '42b922126c4e6acfabc4a36495201fd1a85bef84baeaf458c465274d0f43164d', 'codex/diretor/referencias/skul/INVENTARIO.json': '88d777b228f6997dc8924fbdacc724f423755ae0c0093fb2207ebe2b29bd1d3e', 'codex/diretor/referencias/skul/folhas/148009.png': 'fa0834c6f56c30baa8f3b537fdc16ec7c25e63225c888449cbe4f19cf7e159ba', 'codex/diretor/referencias/skul/folhas/148013.png': 'a65aa6f43acb458cd77feebfb7dc50c2eb207d2591bf6f830ac958934bf88798', 'codex/diretor/referencias/skul/folhas/148019.png': '900e3bc058a75faf343a617d05436ebff2a26fa860a003dcff02810c60ae0d26', 'codex/diretor/referencias/skul/folhas/148045.png': '2de0f85d49c9bebf10476e8295ea684b0b82e14bacc2c8d3e86338a44331f323', 'codex/diretor/referencias/skul/folhas/148051.png': 'a3696684295fc10dea2486b1c3b3628d9388b2f480c25e93e38806dc89862d39', 'codex/diretor/referencias/skul/folhas/148058.png': '40e65e2d665d05e3aac6fd68361ada2d36063a16b0b7345db62b3d32bab1a813', 'codex/diretor/referencias/skul/folhas/148063.png': '695a1e2c67c63379c3fda9d4879bbb00ff5c55afe371cbf5acf380a52c10bb90', 'codex/diretor/referencias/skul/folhas/148099.png': 'e4f114d74742fb1982029fd4375cc440cc6bd2ce396747e96c494551898f922f', 'codex/diretor/referencias/skul/folhas/148103.png': '27b32bd82e0cc9334951b685db7f2fae992efbdd90ed60424fb918156c00da2b', 'codex/diretor/referencias/skul/folhas/148105.png': '6bbde6e1ba81308729d50936291e2f801db21bc349be6043b5afc43b8aa57212', 'codex/diretor/referencias/skul/folhas/148140.png': '7821265f8914d8d8fc0554a2e256a9b8985b8af609a1369dd8464e63d1c8875b'}

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
    data['base_run_f0'] = f7.sha(ROOT/'arte_fonte/forma_humana_v1/pose_corrida_48b6/run_f0_x1.png')
    assert data['base_run_f0'] == '28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852'
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
    meta = {k: data[k] == old[k] for k in ('branch', 'main', 'original_head', 'original_status', 'conceito_original', 'mestre_aprovado', 'base_run_f0')}
    external = [x for x in changes['integracao_protegida']
                if AUTHORIZED_EXTERNAL.get(x['arquivo']) == x['depois'] and x['arquivo'] in AUTHORIZED_EXTERNAL]
    excluded = {x['arquivo'] for x in external}
    unexpected = {n:[x for x in rows if not (n == 'integracao_protegida' and x['arquivo'] in excluded)]
                  for n,rows in changes.items()}
    result = {'preservado': not any(unexpected.values()) and all(meta.values()),
              'preservacao_integral_sem_excecoes':not any(changes.values()) and all(meta.values()),
              'metadados':meta,'alteracoes_todas':changes,
              'alteracoes_externas_diretor':external,'alteracoes_nao_autorizadas':unexpected,
              'arquivos':{n:len(v) for n,v in data['sha256'].items()},'conceito_original':data['conceito_original']}
    save('ALTERACOES_EXTERNAS_REFERENCIAS.json',{
        'origem':'coleta do Diretor, externa a esta tarefa, anunciada pelo complemento de referências do usuário',
        'motivo':'11 novas folhas; inventário, referência principal e registro correspondente no diário',
        'gravadas_por_esta_tarefa':False,'incluidas_no_commit':False,'alteracoes':external,
        'outras_diferencas':unexpected})
    save('PRESERVACAO_resultado.json', result)
    print(json.dumps({'preservado_pelo_agente':result['preservado'],
        'alteracoes_externas_autorizadas':len(external),'outras_diferencas':sum(map(len,unexpected.values())),
        'arquivos':result['arquivos']},ensure_ascii=False),flush=True)
    assert result['preservado'], 'Protected files changed; all differences are reported in the audit.'


def one(path, label):
    text = (ROOT/path).read_text(encoding='utf-8')
    for prefix in ['evidencias_integracao_p40_f%d'%i for i in (3,4,5,6)] + ['evidencias_peregrino_corrompido', 'evidencias_peregrino_47b', 'evidencias_peregrino_47c', 'evidencias_forma_humana_48a']:
        text = text.replace('res://codex/'+prefix+'/', 'res://codex/evidencias_forma_humana_48b8/'+label+'/')
    for prefix in ('p40_runtime_f5', 'p40_runtime_f6', 'peregrino_corrompido_47', 'peregrino_47b', 'peregrino_47c', 'forma_humana_48a'):
        text = text.replace('res://.godot/'+prefix+'/', 'res://.godot/forma_humana_48b8/'+label+'/')
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
    for relative in ALLOWED:
        root = ROOT/relative
        paths = root.rglob('*') if root.is_dir() else [root]
        for p in sorted(paths):
            if p.is_file() and p != OUT/'SHA256_ENTREGAS.json':
                data[p.relative_to(ROOT).as_posix()] = {'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
                                                      'bytes':p.stat().st_size}
    save('SHA256_ENTREGAS.json', {'arquivos':data,'quantidade':len(data),
                               'exclusao_autorreferencial':'SHA256_ENTREGAS.json'})
    print({'arquivos_entregues':len(data)}, flush=True)

def check_stage():
    def git(*args, **kwargs):
        return subprocess.check_output(['git',*args],cwd=ROOT,**kwargs)
    assert git('branch','--show-current').decode().strip() == 'feature/integracao-p40'
    assert git('rev-parse','HEAD').decode().strip() == 'c9adc51f1b100e7532552ccbdd27010d3487a6df'
    assert git('rev-parse','main').decode().strip() == 'ef24b5561cacb823d1f719370c29d82522cb5b58'
    assert not git('diff','--name-only'), 'Tracked working-tree changes outside stage'
    statuses=git('diff','--cached','--name-status','-z').decode().strip('\0').split('\0')
    assert all(s == 'A' for s in statuses[::2]), 'Only new files may be staged'
    names=statuses[1::2]
    assert all(any(n == p or n.startswith(p+'/') for p in ALLOWED) for n in names)
    manifest=json.loads((OUT/'SHA256_ENTREGAS.json').read_text(encoding='utf-8'))['arquivos']
    assert set(names) == set(manifest) | {'codex/evidencias_forma_humana_48b8/SHA256_ENTREGAS.json'}
    blobs=git('cat-file','--batch',input=''.join(':'+n+'\n' for n in names).encode())
    offset=0
    lfs=[]
    for n in names:
        end=blobs.index(b'\n',offset)
        header=blobs[offset:end].split();assert header[1] == b'blob'
        size=int(header[2]);blob=blobs[end+1:end+1+size];offset=end+2+size
        raw=(ROOT/n).read_bytes()
        pointer=blob.startswith(b'version https://git-lfs.github.com/spec/v1\n')
        if pointer:
            # The repository stores MP4 in LFS: audit the pointer's object
            # hash/size against the actual delivered video, never bypass LFS.
            assert git('check-attr','--cached','filter','--',n).decode().strip().endswith(': lfs')
            lines=blob.decode().splitlines()
            assert lines == ['version https://git-lfs.github.com/spec/v1',
                             'oid sha256:'+hashlib.sha256(raw).hexdigest(), 'size '+str(len(raw))]
            lfs.append(n)
        else:
            assert blob == raw, 'Staged bytes differ from audited source: '+n
        if n in manifest:
            assert len(raw) == manifest[n]['bytes']
            assert hashlib.sha256(raw).hexdigest() == manifest[n]['sha256']
    assert offset == len(blobs)
    git('diff','--cached','--check')
    print({'stage_aprovado':True,'somente_arquivos_novos':len(names),
           'sha256_conferido':len(manifest),'lfs_sha256_conferido':lfs,
           'diretor_e_kit_incluidos':False},flush=True)

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
