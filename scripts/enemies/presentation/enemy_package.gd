extends RefCounted

## Generic v34A decoder; shares PNG, anchor and front-clipped geometry rules with Carrasco.
const CORE := preload("res://scripts/player/visuals/carrasco_p42b_package.gd")

static func phase_name(value: String) -> String:
    match value.to_upper():
        "PREPARACAO", "PREP", "WINDUP": return "WINDUP"
        "ATIVO", "ACTIVE": return "ACTIVE"
        "RECUPERACAO", "RECUP", "RECOVERY": return "RECOVERY"
        "TODAS", "ALL": return "ALL"
        _: return ""

static func load_package(root: String) -> Dictionary:
    var errors: Array[String] = []
    if not root.begins_with("res://") or root.contains("..") or root.contains("\\"):
        return {"valid": false, "errors": ["raiz de pacote invalida"], "anims": {}}
    root = root.trim_suffix("/") + "/"
    if not FileAccess.file_exists(root + "manifesto_sprites.json"):
        return {"valid": false, "errors": ["pacote ainda nao entregue"], "anims": {}}
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(root + "manifesto_sprites.json"))
    if not data is Dictionary or not data.get("animacoes") is Array:
        return {"valid": false, "errors": ["manifesto: animacoes[] ausente"], "anims": {}}
    var textures := {}
    var anims := {}
    if data.get("paleta") is Dictionary:
        var palette: Dictionary = data.paleta
        if not CORE.safe_path(String(palette.get("arquivo", ""))) or FileAccess.get_sha256(root + String(palette.get("arquivo", ""))) != String(palette.get("sha256", "")):
            errors.append("SHA256 da paleta diverge")
    for source: Variant in data.animacoes:
        if not source is Dictionary or not source.get("quadros") is Array:
            errors.append("animacao sem quadros[]")
            continue
        var id := String(source.get("id", ""))
        if id.is_empty() or anims.has(id) or source.quadros.is_empty():
            errors.append("animacao vazia/duplicada")
            continue
        var frames: Array[Dictionary] = []
        var has_damage := false
        var total_ms := 0.0
        var raw_attack: Variant = source.get("ataque", {})
        var entries: Array = raw_attack if raw_attack is Array else [raw_attack]
        var attack_specs := {}
        var attack := {}
        for entry: Variant in entries:
            if not entry is Dictionary or not entry.get("fases", {}) is Dictionary:
                errors.append("ataque/fases invalido")
                continue
            entry = entry.duplicate(true)
            for key in entry.get("fases", {}):
                var phase_spec: Variant = entry.fases[key]
                if not phase_spec is Dictionary or not phase_spec.get("quadros", []) is Array:
                    errors.append("fase/quadros invalido")
                    continue
                var indices: Array[int] = []
                for raw_index: Variant in phase_spec.get("quadros", []):
                    if not CORE._number(raw_index) or float(raw_index) != floorf(float(raw_index)) or float(raw_index) < 0 or float(raw_index) >= source.quadros.size():
                        errors.append("indice de fase invalido")
                    else: indices.append(int(raw_index))
                phase_spec.quadros = indices
            if attack.is_empty(): attack = entry
            var attack_id := String(entry.get("attack_id", ""))
            if attack_specs.has(attack_id): errors.append("attack_id duplicado")
            attack_specs[attack_id] = entry
        for i in range(source.quadros.size()):
            var q: Variant = source.quadros[i]
            if not q is Dictionary:
                errors.append("quadro invalido")
                continue
            var tex := texture(root, q, textures, errors)
            var anchor := CORE._anchor(q.get("ancora"), errors)
            var ms := float(q.get("ms", 0)) if CORE._number(q.get("ms")) else 0.0
            if ms <= 0: errors.append("tempo de quadro invalido")
            total_ms += ms
            var phase := phase_name(String(q.get("fase", "")))
            for entry: Dictionary in attack_specs.values():
                for key in entry.get("fases", {}):
                    var spec: Variant = entry.fases[key]
                    if not spec is Dictionary or not spec.get("quadros", []) is Array:
                        errors.append("fase/quadros invalido")
                    elif spec.quadros.has(i): phase = phase_name(key)
            var damage := {}
            if q.get("hitbox") != null:
                if not q.hitbox is Dictionary:
                    errors.append("hitbox deve ser objeto")
                else:
                    damage = CORE.decode_hitbox(q.hitbox, errors)
                    if phase.is_empty(): phase = phase_name(String(damage.phase))
                    if phase != "ACTIVE" or phase_name(String(damage.phase)) != "ACTIVE": errors.append("hitbox fora de ACTIVE")
                    has_damage = true
            var effects: Array[Dictionary] = []
            if not source.get("efeitos", []) is Array or not q.get("efeitos", []) is Array: errors.append("efeitos deve ser lista")
            var specs: Array = source.get("efeitos", []).duplicate() if source.get("efeitos", []) is Array else []
            if q.get("efeitos") is Array: specs.append_array(q.efeitos)
            for fx: Variant in specs:
                if not fx is Dictionary:
                    errors.append("FX invalido")
                    continue
                if fx.has("quadro") and int(fx.quadro) != i: continue
                var fx_phase := phase_name(String(fx.fase)) if fx.has("fase") else (phase if not phase.is_empty() else "ALL")
                if fx_phase.is_empty(): errors.append("fase FX invalida")
                effects.append({"tex": texture(root, fx, textures, errors), "ancora": CORE._anchor(fx.get("ancora"), errors), "fase": fx_phase, "camada": String(fx.get("camada", "frente_do_corpo")), "warning": fx.get("tipo", "") == "brilho_de_aviso"})
            var shadow := {}
            var shadow_spec: Variant = q.get("sombra", source.get("sombra", {}))
            if not shadow_spec is Dictionary: errors.append("sombra deve ser objeto")
            if shadow_spec is Dictionary and not shadow_spec.is_empty():
                var st := texture(root, shadow_spec, textures, errors)
                var sa := CORE._anchor(shadow_spec.get("ancora"), errors)
                if st != null:
                    var bbox := st.get_image().get_used_rect()
                    if bbox.has_area():
                        var atlas := AtlasTexture.new()
                        atlas.atlas = st
                        atlas.region = bbox
                        shadow = {"texture": atlas, "bbox": bbox, "ancora": sa}
            frames.append({"tex": tex, "ancora": anchor, "ms": ms, "sombra": shadow, "efeitos": effects, "hitbox": damage, "phase": phase})
        anims[id] = {"frames": frames, "loop": bool(source.get("loop", false)), "ms": total_ms, "has_damage": has_damage, "attack": attack, "attack_specs": attack_specs, "loop_start": int(source.get("loop_inicio_quadro", 0))}
    if anims.is_empty(): errors.append("pacote sem animacoes")
    var hurt: Variant = data.get("hurtbox_sugerida", {})
    if not hurt is Dictionary:
        errors.append("hurtbox_sugerida invalida")
        hurt = {}
    if not hurt.is_empty():
        if not CORE._number(hurt.get("raio_px")) or not CORE._number(hurt.get("altura_px")) or float(hurt.raio_px) <= 0 or float(hurt.altura_px) < 2*float(hurt.raio_px):
            errors.append("capsula sugerida invalida")
    for anim: Dictionary in anims.values():
        if anim.loop_start < 0 or anim.loop_start >= anim.frames.size(): errors.append("loop_inicio_quadro invalido")
    return {"valid": errors.is_empty(), "errors": errors, "anims": anims, "root": root, "hurtbox": hurt}

static func texture(root: String, spec: Dictionary, cache: Dictionary, errors: Array[String]) -> Texture2D:
    var relative := String(spec.get("arquivo", ""))
    if not CORE.safe_path(relative):
        errors.append("caminho invalido")
        return null
    var expected := String(spec.get("sha256", ""))
    var bytes := FileAccess.get_file_as_bytes(root + relative)
    if expected.length() != 64 or (FileAccess.get_sha256(root + relative) != expected and CORE.sha256_without_cabx(bytes) != expected):
        errors.append("SHA256 diverge: " + relative)
        return null
    if cache.has(relative):
        CORE._dimensions(cache[relative], spec, errors)
        return cache[relative]
    var image := Image.new()
    if image.load_png_from_buffer(bytes) != OK or image.is_empty():
        errors.append("PNG invalido: " + relative)
        return null
    var result := ImageTexture.create_from_image(image)
    CORE._dimensions(result, spec, errors)
    cache[relative] = result
    return result

## Normalize only authored frame cadence inside each phase, never AI/tres timings.
static func attack_frame(anim: Dictionary, data: AttackData, elapsed: float) -> Dictionary:
    var phase := "WINDUP" if elapsed < data.windup_seconds else ("ACTIVE" if elapsed < data.windup_seconds + data.active_seconds else "RECOVERY")
    var start := 0.0 if phase == "WINDUP" else (data.windup_seconds if phase == "ACTIVE" else data.windup_seconds + data.active_seconds)
    var duration := data.windup_seconds if phase == "WINDUP" else (data.active_seconds if phase == "ACTIVE" else data.recovery_seconds)
    var indices: Array[int] = []
    var total := 0.0
    var authored: Dictionary = anim.attack_specs.get(String(data.attack_id), anim.attack)
    var allowed: Array = []
    for key in authored.get("fases", {}):
        if phase_name(key) == phase: allowed = authored.fases[key].get("quadros", [])
    for i in range(anim.frames.size()):
        if anim.frames[i].phase == phase and (allowed.is_empty() or allowed.has(i)):
            indices.append(i)
            total += float(anim.frames[i].ms)
    var index: int
    if indices.is_empty():
        index = CORE.frame_at_ms(anim.frames, elapsed * 1000, false)
    else:
        var t := clampf((elapsed - start) / maxf(duration, .0001), 0, .999999) * total
        index = indices[-1]
        for i in indices:
            if t < float(anim.frames[i].ms):
                index = i
                break
            t -= float(anim.frames[i].ms)
    return {"index": index, "frame": anim.frames[index], "phase": phase}

## Play the entry once, then repeat only the authored loop tail (e.g. rupture).
static func state_frame(anim: Dictionary, elapsed_ms: float) -> int:
    if not anim.loop or anim.loop_start == 0: return CORE.frame_at_ms(anim.frames, elapsed_ms, anim.loop)
    var intro := 0.0
    for i in range(anim.loop_start): intro += float(anim.frames[i].ms)
    if elapsed_ms < intro: return CORE.frame_at_ms(anim.frames,elapsed_ms,false)
    var tail := float(anim.ms) - intro
    return CORE.frame_at_ms(anim.frames,intro + fposmod(elapsed_ms-intro,tail),false)
