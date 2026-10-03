"""Render the frozen cemetery room and encode its real viewport at 960x540/30 fps."""
import argparse, importlib.util, json, pathlib, subprocess
ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('runner', ROOT / 'codex/verificar_fase4.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
api = runner.api
EVIDENCE = ROOT / 'codex/evidencias_integracao_p40_f4'
FFMPEG = pathlib.Path(r'C:\Users\daiki\Documents\Codex\carrasco_25d_test\codex\prototipo_escala_36_corrida\ferramentas\ffmpeg.exe')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['dry', 'capture', 'encode'])
    action = parser.parse_args().action
    if action == 'encode':
        frames = ROOT / '.godot/p40_runtime_f4/capture_frames'
        sequence = sorted(frames.glob('*.png'))
        assert len(sequence) == 900, len(sequence)
        subprocess.run([str(FFMPEG), '-hide_banner', '-y', '-framerate', '30', '-i', str(frames / '%05d.png'), '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(EVIDENCE / 'CLIPE_CEMITERIO_PEQUENO_A_30s.mp4')], check=True, cwd=ROOT)
    else:
        args = ['--fixed-fps', '60', '--disable-vsync', '--script', 'res://codex/testes/capturar_cemiterio_f4.gd']
        if action == 'dry':
            code, output, seconds = api.run_engine(args + ['--', '--dry-run'], 'dry_capture', 120)
        else:
            result = subprocess.run([str(api.ENGINE), '--path', str(ROOT), *args], cwd=ROOT, env=api.engine_env('render_capture'), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
            code, output = result.returncode, result.stdout.decode('utf-8', errors='replace')
        (EVIDENCE / ('CAPTURA_SECA.txt' if action == 'dry' else 'CAPTURA.txt')).write_text(output, encoding='utf-8', newline='\n')
        print({'exit': code, 'tail': output.splitlines()[-8:]})
        raise SystemExit(code)
