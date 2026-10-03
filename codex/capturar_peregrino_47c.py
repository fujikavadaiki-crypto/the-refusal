"""Dry run, actual viewport recording, and 600-frame/20-second encoding."""
from pathlib import Path
import importlib.util,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
s=importlib.util.spec_from_file_location('runner',ROOT/'codex/verificar_peregrino_47c.py')
r=importlib.util.module_from_spec(s);s.loader.exec_module(r)
api=r.f7.f6.api
FFMPEG=Path(r'C:\Users\daiki\Documents\Codex\carrasco_25d_test\codex\prototipo_escala_36_corrida\ferramentas\ffmpeg.exe')
if __name__=='__main__':
 action=sys.argv[1]
 if action=='encode':
  folder=api.RUNTIME/'capture_frames';assert len(list(folder.glob('*.png')))==600
  subprocess.run([str(FFMPEG),'-hide_banner','-y','-framerate','30','-i',str(folder/'%05d.png'),'-c:v','libx264','-crf','18','-preset','medium','-pix_fmt','yuv420p','-movflags','+faststart',str(r.OUT/'CLIPE_MARCHA_20s.mp4')],cwd=ROOT,check=True)
 else:
  args=['--fixed-fps','60','--disable-vsync','--script','res://codex/testes/capturar_peregrino_47c.gd']
  if action=='dry':code,output,_=api.run_engine(args+['--','--dry-run'],'capture_dry',120)
  elif action=='capture':
   proc=subprocess.run([str(api.ENGINE),'--path',str(ROOT),*args],cwd=ROOT,env=api.engine_env('capture_render'),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=600)
   code,output=proc.returncode,proc.stdout.decode('utf-8',errors='replace')
  else:raise ValueError(action)
  output='\n'.join(x.rstrip() for x in output.replace('\r','').splitlines()).rstrip()+'\n'
  (r.OUT/f'CAPTURA_{action}.txt').write_text(output,encoding='utf-8',newline='\n')
  print(output[-3500:]);raise SystemExit(code)
