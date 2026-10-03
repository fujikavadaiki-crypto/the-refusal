"""P42b integration: complete suites, isolated runtimes and SHA256 audit."""
import argparse, concurrent.futures, importlib.util, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('phase2_runner', ROOT / 'codex/verificar_fase2.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
EVIDENCE = ROOT / 'codex/evidencias_integracao_p40_f3'
previous.EVIDENCE = EVIDENCE
previous.api.EVIDENCE = EVIDENCE
previous.api.RUNTIME = ROOT / '.godot/p40_runtime_f3'

def suites(label):
    if label == 'antes' and previous.api.git('diff', '--name-only', '--', 'scripts', 'scenes', 'data', 'project.godot'):
        raise RuntimeError('Baseline must precede production edits.')
    paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 'tests').glob('verify_*.gd'))
    paths += ['codex/testes/verify_integracao_p40_f1.gd', 'codex/testes/verify_integracao_p40_f2.gd']
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(lambda path: previous.run_one(path, label), paths))
    previous.save('TESTES_' + label + '.json', results)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['preserve-before', 'preserve-after', 'before', 'after', 'new', 'import'])
    action = parser.parse_args().action
    if action.startswith('preserve-'):
        previous.preservation('antes' if action.endswith('before') else 'depois')
    elif action == 'new':
        previous.save('TESTES_novos.json', previous.run_one('codex/testes/verify_integracao_p40_f3.gd', 'novos', 600))
    elif action == 'import':
        code, output, seconds = previous.api.run_engine(['--editor', '--import', '--quit'], 'import', 240)
        EVIDENCE.mkdir(parents=True, exist_ok=True)
        (EVIDENCE / 'IMPORTACAO.txt').write_text(output, encoding='utf-8', newline='\n')
        print({'exit': code, 'seconds': seconds, 'errors': [line for line in output.splitlines() if 'ERROR' in line]})
    else:
        suites('antes' if action == 'before' else 'depois')
