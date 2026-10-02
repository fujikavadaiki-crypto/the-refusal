"""Evidence runner: isolated runtime, offline LFS, preserved sources, before/after tests."""
import argparse, concurrent.futures, hashlib, json, os, pathlib, re, shutil, subprocess, time, threading

ROOT = pathlib.Path(__file__).resolve().parent.parent
PRIMARY = ROOT.parent / 'the-refusal'
REFERENCE = pathlib.Path(r'C:\Users\daiki\Documents\Codex\carrasco_25d_test\jogavel\prototipo_40')
ENGINE = pathlib.Path(r'C:\Users\daiki\Documents\Codex\2026-09-22\projeto-the-refusal-godot-4-7-4\work\godot\Godot_v4.7.2-stable_win64_console.exe')
EVIDENCE = ROOT / 'codex/evidencias_integracao_p40_f1'
RUNTIME = ROOT / '.godot/p40_runtime'

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()

def git(*args, cwd=ROOT):
    return subprocess.check_output(['git', '-C', str(cwd), *args], text=True).strip()

def save(name, data):
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / name).write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def preservation(label):
    data = {'main': git('rev-parse', 'main'), 'primary_head': git('rev-parse', 'HEAD', cwd=PRIMARY),
            'primary_status': git('status', '--porcelain=v1', '-uall', cwd=PRIMARY), 'sha256': {}}
    for name, folder in [('reference_p40', REFERENCE), ('primary_checkout', PRIMARY)]:
        files = {}
        for path in folder.rglob('*'):
            relative = path.relative_to(folder)
            if path.is_file() and not any(part in ('.git', '.godot') for part in relative.parts):
                files[relative.as_posix()] = digest(path)
        data['sha256'][name] = files
    save('PRESERVACAO_' + label + '.json', data)
    if label == 'depois':
        before = json.loads((EVIDENCE / 'PRESERVACAO_antes.json').read_text(encoding='utf-8'))
        changes = {}
        for name, old in before['sha256'].items():
            new = data['sha256'][name]
            changes[name] = [key for key in sorted(old.keys() | new.keys()) if old.get(key) != new.get(key)]
        old_reference, new_reference = before['sha256']['reference_p40'], data['sha256']['reference_p40']
        save('PRESERVACAO_resultado.json', {'main_preservado': before['main'] == data['main'],
             'checkout_head_preservado': before['primary_head'] == data['primary_head'],
             'checkout_status_preservado': before['primary_status'] == data['primary_status'],
             'arquivos_alterados': changes, 'arquivos_verificados': {name: len(files) for name, files in data['sha256'].items()},
             'referencia_identica': old_reference == new_reference,
             'pacote_inicial_v32A_preservado': all(new_reference.get(key) == value for key, value in old_reference.items() if key.startswith('pacotes/pequeno_v32A/')),
             'mudanca_externa_referencia': {
                 'modificados': sorted(key for key in old_reference.keys() & new_reference.keys() if old_reference[key] != new_reference[key]),
                 'adicionados': len(new_reference.keys() - old_reference.keys()),
                 'removidos': sorted(old_reference.keys() - new_reference.keys()),
                 'nota': 'Referencia recebeu P42/v33A durante a tarefa. Nenhum comando desta integracao escreveu nessa pasta.'}})
        print({'changed_counts': {name: len(items) for name, items in changes.items()}, 'main_preserved': before['main'] == data['main']})
    else: print({name: len(files) for name, files in data['sha256'].items()})

def offline_lfs():
    copied, missing = [], []
    objects = PRIMARY / '.git/lfs/objects'
    for name in git('ls-files').splitlines():
        path = ROOT / name
        if not path.is_file() or path.stat().st_size > 512: continue
        content = path.read_bytes()
        if not content.startswith(b'version https://git-lfs.github.com/spec/v1'): continue
        oid = re.search(rb'oid sha256:([a-f0-9]{64})', content).group(1).decode()
        cached = objects / oid[:2] / oid[2:4] / oid
        candidates = [cached, PRIMARY / name]
        source = next((candidate for candidate in candidates if candidate.is_file() and digest(candidate) == oid), None)
        if source:
            shutil.copyfile(source, path); copied.append(name)
        else: missing.append(name)
    save('LFS_local.json', {'materializados_sem_rede': copied, 'indisponiveis': missing})
    print({'materializados': len(copied), 'indisponiveis': missing})

def engine_env(name):
    folder = RUNTIME / name
    folder.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP'): env[key] = str(folder)
    return env

def run_engine(args, name, timeout=600):
    start = time.monotonic()
    proc = subprocess.Popen([str(ENGINE), '--headless', '--path', str(ROOT), *args], cwd=ROOT,
          env=engine_env(name), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines, fatal = [], []
    def read_output():
        for raw in iter(proc.stdout.readline, b''):
            line = raw.decode('utf-8', errors='replace'); lines.append(line)
            if 'SCRIPT ERROR' in line or 'Parse Error' in line: fatal.append(time.monotonic())
    reader = threading.Thread(target=read_output, daemon=True); reader.start()
    forced = None
    while proc.poll() is None:
        if fatal and time.monotonic() - fatal[0] > 3:
            forced = -2; lines.append('ABORT_SCRIPT_ERROR: fatal script error; suite cannot complete.\n'); proc.terminate(); break
        if time.monotonic() - start > timeout:
            forced = -1; lines.append('TIMEOUT\n'); proc.terminate(); break
        time.sleep(.1)
    proc.wait(); reader.join(timeout=5)
    output = '\n'.join(line.rstrip() for line in ''.join(lines).splitlines()).rstrip() + '\n'
    code = forced if forced is not None else proc.returncode
    return code, output, round(time.monotonic() - start, 2)

def suites(label, reuse_completed=False, only=None):
    if label == 'antes' and git('diff', '--name-only', '--', 'scripts', 'scenes', 'data', 'project.godot'):
        raise RuntimeError('Baseline must run before production changes.')
    names = only or sorted(path.name for path in (ROOT / 'tests').glob('verify_*.gd'))
    target = EVIDENCE / label
    target.mkdir(parents=True, exist_ok=True)
    def one(name):
        previous = EVIDENCE / 'antes' / (name + '.txt')
        if reuse_completed and label == 'antes' and previous.exists() and not any(word in previous.read_text(encoding='utf-8') for word in ('TIMEOUT', 'SCRIPT ERROR', 'FAIL')):
            output, code, seconds = previous.read_text(encoding='utf-8'), 0, None
        else:
            code, output, seconds = run_engine(['--script', 'res://tests/' + name], label + '_' + name, 600)
        (target / (name + '.txt')).write_text(output, encoding='utf-8')
        failures = [line.strip() for line in output.splitlines() if 'FAIL' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line or 'TIMEOUT' in line]
        result = {'teste': name, 'exit': code, 'pass': len(re.findall(r'^PASS:', output, re.M)),
                  'fail': len(re.findall(r'^FAIL:', output, re.M)), 'falhas': failures, 'segundos': seconds,
                  'aprovado': code == 0 and not failures}
        print(json.dumps(result, ensure_ascii=False), flush=True)
        return result
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(one, names))
    save('TESTES_' + label + '.json', results)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['preserve-before', 'preserve-after', 'lfs', 'import', 'before', 'after'])
    parser.add_argument('--reuse-completed', action='store_true', help='Only reuse successful, unchanged-main baseline logs.')
    arguments = parser.parse_args()
    action = arguments.action
    if action.startswith('preserve-'): preservation('antes' if action.endswith('before') else 'depois')
    elif action == 'lfs': offline_lfs()
    elif action == 'import':
        code, output, seconds = run_engine(['--editor', '--import'], 'import', 180)
        EVIDENCE.mkdir(parents=True, exist_ok=True)
        (EVIDENCE / 'IMPORTACAO.txt').write_text(output, encoding='utf-8')
        print({'exit': code, 'seconds': seconds, 'errors': [line for line in output.splitlines() if 'ERROR' in line]})
    else: suites('antes' if action == 'before' else 'depois', arguments.reuse_completed)
