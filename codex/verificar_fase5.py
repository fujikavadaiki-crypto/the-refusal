"""Feel/package integration: full regression, immutable sources, isolated evidence."""
import argparse, concurrent.futures, importlib.util, json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('phase2', ROOT / 'codex/verificar_fase2.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
api = previous.api
EVIDENCE = ROOT / 'codex/evidencias_integracao_p40_f5'
previous.EVIDENCE = api.EVIDENCE = EVIDENCE
api.RUNTIME = ROOT / '.godot/p40_runtime_f5'
PROVA = api.REFERENCE.parent.parent / 'prova'

def snapshot(folder):
    return {p.relative_to(folder).as_posix(): api.digest(p) for p in folder.rglob('*')
            if p.is_file() and not any(s in ('.git', '.godot', '__pycache__') for s in p.relative_to(folder).parts)}

def preservation(label):
    data = {'main': api.git('rev-parse', 'main'),
            'primary_head': api.git('rev-parse', 'HEAD', cwd=api.PRIMARY),
            'primary_status': api.git('status', '--porcelain=v1', '-uall', cwd=api.PRIMARY),
            'sha256': {name: snapshot(folder) for name, folder in [
                ('reference_p40', api.REFERENCE), ('prova', PROVA), ('primary_checkout', api.PRIMARY),
                ('bosque_scenes', ROOT/'scenes/biomes/forest'), ('bosque_scripts', ROOT/'scripts/biomes/forest'),
                ('enemy_scenes', ROOT/'scenes/enemies'), ('enemy_brains', ROOT/'scripts/enemies'),
                ('enemy_tuning', ROOT/'data/enemies'), ('attacks', ROOT/'data/attacks'),
                ('pequeno_v34A', ROOT/'assets/characters/pequeno_v34A')]}}
    data['sha256']['enemy_brains'] = {k:v for k,v in data['sha256']['enemy_brains'].items() if '_brain.gd' in k or '_tuning.gd' in k}
    previous.save('PRESERVACAO_' + label + '.json', data)
    if label == 'depois':
        before = json.loads((EVIDENCE/'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
        changes = {name: [k for k in sorted(old.keys() | data['sha256'][name].keys())
                         if old.get(k) != data['sha256'][name].get(k)] for name, old in before['sha256'].items()}
        result = {'main_preservado': before['main'] == data['main'],
                  'checkout_head_preservado': before['primary_head'] == data['primary_head'],
                  'checkout_status_preservado': before['primary_status'] == data['primary_status'],
                  'alteracoes': changes, 'arquivos': {n: len(v) for n,v in data['sha256'].items()}}
        allowed_maps = {'corvo_mapa.json', 'peregrino_mapa.json', 'raiz_faminta_mapa.json'}
        new_maps = [k for k in changes['enemy_tuning'] if k in allowed_maps and k not in before['sha256']['enemy_tuning']]
        result['novos_mapeamentos_autorizados'] = new_maps
        result['tuning_existente_preservado'] = all(data['sha256']['enemy_tuning'].get(k) == v for k,v in before['sha256']['enemy_tuning'].items())
        result['alteracoes_nao_autorizadas'] = {name: [k for k in keys if name != 'enemy_tuning' or k not in new_maps] for name, keys in changes.items()}
        previous.save('PRESERVACAO_resultado.json', result)
        print(json.dumps(result, ensure_ascii=False))
    else:
        print({n: len(v) for n,v in data['sha256'].items()})

def run_one(path, label, timeout=600):
    # Older suites write measurements to phase-3 paths. Execute an identical
    # temporary copy with only that output directory redirected; old evidence
    # and the committed fixtures remain byte-for-byte untouched.
    text = (ROOT/path).read_text(encoding='utf-8')
    actual = path
    if any('res://codex/evidencias_integracao_p40_f%d/' % n in text for n in (3,4)):
        (EVIDENCE/label).mkdir(parents=True, exist_ok=True)
        for n in (3,4):
            text = text.replace('res://codex/evidencias_integracao_p40_f%d/' % n, 'res://codex/evidencias_integracao_p40_f5/'+label+'/')
        target = api.RUNTIME/'fixtures'/pathlib.Path(path).name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding='utf-8', newline='\n')
        actual = target.relative_to(ROOT).as_posix()
    result = previous.run_one(actual, label, timeout)
    result['teste'] = path
    return result

def suites(label):
    if label == 'antes' and api.git('diff', '--name-only', '--', 'scripts', 'scenes', 'data', 'project.godot'):
        raise RuntimeError('Baseline must precede production edits.')
    paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'tests').glob('verify_*.gd'))
    paths += ['codex/testes/verify_integracao_p40_f%d.gd' % n for n in (1,2,3,4)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(lambda p: run_one(p,label), paths))
    previous.save('TESTES_' + label + '.json', results)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['preserve-before','preserve-after','before','after','new'])
    action = parser.parse_args().action
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    if action.startswith('preserve-'): preservation('antes' if action.endswith('before') else 'depois')
    elif action == 'new': previous.save('TESTES_novos.json',run_one('codex/testes/verify_integracao_p40_f5.gd','novos'))
    else: suites('antes' if action == 'before' else 'depois')
