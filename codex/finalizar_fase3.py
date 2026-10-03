"""Consolidate phase-3 evidence without touching the reference or original checkout."""
import collections, json, pathlib, subprocess
from verificar_fase3 import ROOT, EVIDENCE, previous

def read(name):
    return json.loads((EVIDENCE / name).read_text(encoding='utf-8'))

def save(name, value):
    (EVIDENCE / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')

def finish():
    previous.preservation('depois')
    original = previous.api.REFERENCE / 'pacotes/pequeno_v34A'
    copy = ROOT / 'assets/characters/pequeno_v34A'
    files = {p.relative_to(original).as_posix(): {'source_sha256': previous.api.digest(p), 'copy_sha256': previous.api.digest(copy / p.relative_to(original))} for p in original.rglob('*') if p.is_file()}
    divergent = [name for name, hashes in files.items() if hashes['source_sha256'] != hashes['copy_sha256']]
    save('PACOTE_SHA256.json', {'source': str(original), 'copy': str(copy), 'files': files, 'divergent': divergent, 'count': len(files)})
    assert len(files) == 215 and not divergent
    before, after, new = read('TESTES_antes.json'), read('TESTES_depois.json'), read('TESTES_novos.json')
    assert len(before) == len(after) == 21
    capture, trace, events = read('CLIPE_METADADOS.json'), read('CLIPE_TRACE.json'), read('CLIPE_INPUTS.json')
    assert capture['real_combat_verified'] and not capture['dry_run'] and capture['frames'] == 900 and len(trace) == 900
    assert all(not row['legacy_shadow'] for row in trace)
    assert all(row['video_s'] == index / 30 or abs(row['video_s'] - index / 30) < 1e-10 for index, row in enumerate(trace))
    assert capture['stats']['hits'].keys() == {'Peregrino', 'Corvo', 'Raiz'}
    frames = sorted((ROOT / '.godot/p40_runtime_f3/capture_frames').glob('*.png'))
    if frames:
        assert len(frames) == 900
        save('QUADROS_CAPTURA_SHA256.json', {p.name: previous.api.digest(p) for p in frames})
    video = EVIDENCE / 'CLIPE_BOSQUE_PEQUENO_A_30s.mp4'
    images = EVIDENCE / 'capturas'
    save('MIDIA_SHA256.json', {'mp4': {'sha256': previous.api.digest(video), 'bytes': video.stat().st_size}, 'images': {p.name: previous.api.digest(p) for p in sorted(images.glob('*.png'))}})
    preservation = read('PRESERVACAO_resultado.json')
    assert all(preservation[key] for key in ['main_preservado', 'checkout_head_preservado', 'checkout_status_preservado'])
    assert all(not value for value in preservation['alteracoes'].values())
    unchanged = previous.api.git('diff', '--name-only', '--', 'scripts/enemies', 'data/enemies', 'data/attacks', 'scenes/enemies', 'project.godot')
    assert not unchanged, unchanged
    save('COMPARACAO.json', {'suites_before': 21, 'suites_after': 21, 'passed_before': sum(x['aprovado'] for x in before), 'passed_after': sum(x['aprovado'] for x in after), 'pass_assertions_before': sum(x['pass'] for x in before), 'pass_assertions_after': sum(x['pass'] for x in after), 'failures_before': [x for x in before if not x['aprovado']], 'failures_after': [x for x in after if not x['aprovado']], 'new_suite': new, 'package_files_identical': len(files), 'preservation': preservation, 'unchanged_enemy_attack_project_sources': True, 'real_capture_verified': True, 'video_duration_s': 30, 'scope': 'Phase 3: steps 6-8 and 10 plus user-approved radius/M5 fixture decisions; local branch, no push/merge.'})
    print({'suites_after': sum(x['aprovado'] for x in after), 'new_checks': new['pass'], 'package_identical': len(files), 'preserved': preservation['arquivos'], 'video_sha256': previous.api.digest(video)})

if __name__ == '__main__':
    finish()
