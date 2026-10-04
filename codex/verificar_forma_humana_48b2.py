"""4.8b1: regression in isolated evidence and a complete immutable-source audit."""
from pathlib import Path
import importlib.util, json, sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('f7', ROOT/'codex/verificar_peregrino_corrompido.py')
f7 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(f7)
OUT = ROOT/'codex/evidencias_forma_humana_48b2'
OUT.mkdir(parents=True, exist_ok=True)
f7.EVIDENCE = f7.f6.EVIDENCE = f7.f6.previous.EVIDENCE = f7.f6.api.EVIDENCE = OUT
f7.f6.api.RUNTIME = ROOT/'.godot/forma_humana_48b2'
ALLOWED = ('arte_fonte/forma_humana_v1/poses_chave_48b2',
           'arte_fonte/ferramentas/propor_pernas_forma_humana_48b2.py',
           'codex/evidencias_forma_humana_48b2',
           'codex/verificar_forma_humana_48b2.py',
           'codex/RELATORIO_FORMA_HUMANA_48B2.md')

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
        text = text.replace('res://codex/'+prefix+'/', 'res://codex/evidencias_forma_humana_48b2/'+label+'/')
    for prefix in ('p40_runtime_f5', 'p40_runtime_f6', 'peregrino_corrompido_47', 'peregrino_47b', 'peregrino_47c', 'forma_humana_48a'):
        text = text.replace('res://.godot/'+prefix+'/', 'res://.godot/forma_humana_48b2/'+label+'/')
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
        comparison = [{'teste': a['teste'], 'aprovado_antes': a['aprovado'], 'aprovado_depois': b['aprovado'],
                       'pass_antes': a['pass'], 'pass_depois': b['pass']} for a,b in zip(old,new)]
        save('TESTES_COMPARACAO.json', comparison)
        assert all(a['teste'] == b['teste'] and a['aprovado'] == b['aprovado'] and a['pass'] == b['pass'] for a,b in zip(old,new))

if __name__ == '__main__':
    action = sys.argv[1]
    if action.startswith('preserve-'):
        preservation('antes' if action.endswith('before') else 'depois')
    elif action in ('before', 'after'):
        tests('antes' if action == 'before' else 'depois')
    else:
        raise ValueError(action)
