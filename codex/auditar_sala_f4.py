"""SHA256 provenance of the frozen P40 map; no writes to either source."""
import ast, hashlib, json, pathlib, re
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = pathlib.Path(r'C:\Users\daiki\Documents\Codex\carrasco_25d_test')
OUT = ROOT/'codex/evidencias_integracao_p40_f4/ORIGEM_MAPA.json'

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def pixels(path): return hashlib.sha256(Image.open(path).convert('RGB').tobytes()).hexdigest()
def constant(text, name):
    match = re.search(r'^const '+name+r'\s*:=\s*(\[.*?\])\s*(?=\nconst|\n@|\nvar)',text,re.M|re.S)
    return ast.literal_eval(match.group(1))

if __name__ == '__main__':
    images = {
        'reference_p40': SOURCE/'jogavel/prototipo_40/assets/teste/fundo_congelado.png',
        'frozen_A11': SOURCE/'prova/a1_inicio/imagens/A11_quadro_A11_960x540.png',
        'delivery_R4': SOURCE/'prova/entrega_r4/prova_R4_960x540.png',
        'integration_copy': ROOT/'assets/biomes/cemiterio/fundo_congelado_p40.png'}
    hashes = {n:{'path':str(p),'sha256':digest(p),'rgb_sha256':pixels(p),'size':list(Image.open(p).size)} for n,p in images.items()}
    assert hashes['integration_copy']['sha256'] == hashes['reference_p40']['sha256'] == hashes['frozen_A11']['sha256']
    assert hashes['delivery_R4']['rgb_sha256'] != hashes['reference_p40']['rgb_sha256']
    src = (SOURCE/'jogavel/prototipo_40/prototipo.gd').read_text(encoding='utf-8')
    dst = (ROOT/'scripts/biomes/cemiterio/sala_cemiterio.gd').read_text(encoding='utf-8')
    geometry = {name:constant(src,name) for name in ('GROUND_TOPS','PLATFORMS','PLATFORM_NAMES')}
    for name,value in geometry.items(): assert value == constant(dst,name),name
    data = {'images':hashes,'byte_identical_p40_A11_copy':True,'R4_is_different':True,
            'background_decision':'Preservado exatamente o mapa usado no P40, conforme decisão principal do pedido; identificação correta A1.1, não R4 original. Divergência foi apresentada ao usuário.',
            'geometry':geometry,'geometry_identical_p40':True,'screen_px_per_m':32,'camera_zoom':.9,
            'room_world_translation':[0,-150],'translation_reason':'Câmera e geometria juntas: conserva projeção ×1 e atende limites absolutos 92–186 do Corvo original, sem editar IA/tuning.',
            'background_atlas_patch':{'target':[162,224,39,69],'source':[203,224,39,69],'same_as_p40':True},
            'reference_source_sha256':digest(SOURCE/'jogavel/prototipo_40/prototipo.gd')}
    OUT.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print({'p40_A11_copy':True,'R4_is_different':True,'geometry_identical':True})
