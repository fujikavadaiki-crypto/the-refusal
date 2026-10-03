"""Phase 2: isolated Godot runtime, complete suites and preservation audit."""
import argparse, concurrent.futures, importlib.util, json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('phase1_runner', ROOT / 'codex/verificar_fase1.py')
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)
EVIDENCE = ROOT / 'codex/evidencias_integracao_p40_f2'
api.EVIDENCE = EVIDENCE
api.RUNTIME = ROOT / '.godot/p40_runtime_f2'

def save(name, value):
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8', newline='\n')

def preservation(label):
    data = {'main': api.git('rev-parse', 'main'), 'primary_head': api.git('rev-parse', 'HEAD', cwd=api.PRIMARY),
            'primary_status': api.git('status', '--porcelain=v1', '-uall', cwd=api.PRIMARY), 'sha256': {}}
    for name, folder in [('reference_p42b', api.REFERENCE), ('primary_checkout', api.PRIMARY)]:
        data['sha256'][name] = {p.relative_to(folder).as_posix(): api.digest(p) for p in folder.rglob('*')
              if p.is_file() and not any(part in ('.git', '.godot') for part in p.relative_to(folder).parts)}
    save('PRESERVACAO_' + label + '.json', data)
    if label == 'depois':
        before = json.loads((EVIDENCE / 'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
        changes = {name: [key for key in sorted(old.keys() | data['sha256'][name].keys())
                     if old.get(key) != data['sha256'][name].get(key)] for name, old in before['sha256'].items()}
        save('PRESERVACAO_resultado.json', {'main_preservado': before['main'] == data['main'],
             'checkout_head_preservado': before['primary_head'] == data['primary_head'],
             'checkout_status_preservado': before['primary_status'] == data['primary_status'],
             'alteracoes': changes, 'arquivos': {name: len(files) for name, files in data['sha256'].items()}})
        print({name: len(files) for name, files in changes.items()})
    else: print({name: len(files) for name, files in data['sha256'].items()})

def run_one(path, label, timeout=600):
    code, output, seconds = api.run_engine(['--script', 'res://' + path], label + '_' + pathlib.Path(path).stem, timeout)
    folder = EVIDENCE / label
    folder.mkdir(parents=True, exist_ok=True)
    (folder / (pathlib.Path(path).name + '.txt')).write_text(output, encoding='utf-8', newline='\n')
    failures = [line.strip() for line in output.splitlines() if 'FAIL' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line or 'TIMEOUT' in line]
    result = {'teste': path, 'exit': code, 'pass': len(re.findall(r'^PASS:', output, re.M)),
              'fail': len(re.findall(r'^FAIL:', output, re.M)), 'falhas': failures, 'segundos': seconds,
              'aprovado': code == 0 and not failures}
    print(json.dumps(result, ensure_ascii=False), flush=True)
    return result

def suites(label):
    if label == 'antes' and api.git('diff', '--name-only', '--', 'scripts', 'scenes', 'data', 'project.godot'):
        raise RuntimeError('Baseline must precede production edits.')
    paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'tests').glob('verify_*.gd'))
    paths.append('codex/testes/verify_integracao_p40_f1.gd')
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(lambda path: run_one(path, label), paths))
    save('TESTES_' + label + '.json', results)

def summarize():
    before = json.loads((EVIDENCE / 'TESTES_antes.json').read_text(encoding='utf-8'))
    after = json.loads((EVIDENCE / 'TESTES_depois.json').read_text(encoding='utf-8'))
    old_metrics = json.loads((EVIDENCE / 'MEDIDAS_antes.json').read_text(encoding='utf-8'))
    new_metrics = json.loads((EVIDENCE / 'MEDIDAS_depois.json').read_text(encoding='utf-8'))
    assert len(before) == len(after) == 20
    assert len(old_metrics['contacts']) == len(new_metrics['contacts']) == 130
    changed = []
    for old, new in zip(old_metrics['contacts'], new_metrics['contacts']):
        for field in ['enemy', 'attack', 'form', 'dx_world', 'raised_world', 'height_world']:
            assert old.get(field) == new.get(field), field
        if old['hit'] != new['hit']:
            changed.append({'before': old, 'after': new})
    save('COMPARACAO.json', {
        'suites_before': len(before), 'suites_after': len(after),
        'passed_before': sum(r['aprovado'] for r in before), 'passed_after': sum(r['aprovado'] for r in after),
        'assertions_passed_before': sum(r['pass'] for r in before), 'assertions_passed_after': sum(r['pass'] for r in after),
        'failed_before': [r for r in before if not r['aprovado']], 'failed_after': [r for r in after if not r['aprovado']],
        'new_suite': json.loads((EVIDENCE / 'TESTES_novos.json').read_text(encoding='utf-8')),
        'jump': [{key: value for key, value in jump.items() if key != 'trace'} for jump in new_metrics['jump']],
        'contact_trials': 130, 'changed_contacts': changed,
        'enemy_and_attack_sources_changed': api.git('diff', '--name-only', '--', 'scripts/enemies', 'data/enemies', 'data/attacks'),
        'scope': 'Phase 2, only jump and Carrasco body/hurtbox/pivot; original checkout and reference read-only.'})
    print({'passed_before': sum(r['aprovado'] for r in before), 'passed_after': sum(r['aprovado'] for r in after), 'changed_contacts': len(changed)})

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['preserve-before', 'preserve-after', 'before', 'after', 'new', 'measure-before', 'recheck', 'apply-recheck', 'summarize'])
    action = parser.parse_args().action
    if action.startswith('preserve-'): preservation('antes' if action.endswith('before') else 'depois')
    elif action == 'summarize': summarize()
    elif action == 'new': save('TESTES_novos.json', run_one('codex/testes/verify_integracao_p40_f2.gd', 'novos', 600))
    elif action == 'measure-before':
        code, output, seconds = api.run_engine(['--script', 'res://codex/testes/verify_integracao_p40_f2.gd', '--', '--baseline'], 'medidas_antes', 600)
        (EVIDENCE / 'MEDICAO_antes.txt').write_text(output, encoding='utf-8', newline='\n')
        print({'exit': code, 'seconds': seconds, 'errors': [line for line in output.splitlines() if 'FAIL' in line or 'ERROR' in line]})
    elif action == 'recheck': save('REVISAO_FIXTURE.json', [run_one(path, 'revisados') for path in ['tests/verify_milestone4_1.gd', 'tests/verify_milestone8_3.gd', 'tests/verify_vertical_slice.gd']])
    elif action == 'apply-recheck':
        results = json.loads((EVIDENCE / 'TESTES_depois.json').read_text(encoding='utf-8'))
        if not (EVIDENCE / 'TESTES_primeira_execucao.json').exists():
            save('TESTES_primeira_execucao.json', results)
        revised = {result['teste']: result for result in json.loads((EVIDENCE / 'REVISAO_FIXTURE.json').read_text(encoding='utf-8'))}
        save('TESTES_depois.json', [revised.get(result['teste'], result) for result in results])
        print('Final summary includes the revised fixture; initial log and results retained.')
    else: suites('antes' if action == 'before' else 'depois')
