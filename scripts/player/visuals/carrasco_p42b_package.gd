class_name CarrascoP42bPackage
extends RefCounted

## Read-only package decoder. Texture and collision data share the same frame.
const ROOT := "res://assets/characters/pequeno_v34A/"
const ATTACKS := {
    "carrasco_heavy": "heavy", "carrasco_light_1": "light1",
    "carrasco_light_2": "light2", "carrasco_light_3": "light3",
    "carrasco_post_dodge": "post_dash", "carrasco_air_light": "air_light",
    "carrasco_air_heavy": "air_heavy", "carrasco_charged_heavy": "charged_heavy",
}
static var cached: Dictionary = {}

static func load_package() -> Dictionary:
    if not cached.is_empty():
        return cached
    var errors: Array[String] = []
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifesto_sprites.json"))
    if not parsed is Dictionary or not parsed.get("animacoes") is Array:
        return {"errors": ["manifesto: animacoes[] ausente"], "valid": false}
    var textures := {}
    var hash_modes := {}
    var anims := {}
    var palette: Dictionary = parsed.get("paleta", {})
    var palette_path := String(palette.get("arquivo", ""))
    if not safe_path(palette_path) or FileAccess.get_sha256(ROOT + palette_path) != String(palette.get("sha256", "")):
        errors.append("SHA256 da paleta diverge")
    for source: Variant in parsed.animacoes:
        if not source is Dictionary or not source.get("quadros") is Array:
            errors.append("animacao sem quadros[]")
            continue
        var id := String(source.get("id", ""))
        if id.is_empty() or anims.has(id) or source.quadros.is_empty():
            errors.append("animacao vazia/duplicada: " + id)
            continue
        var frames: Array[Dictionary] = []
        var total_ms := 0.0
        var has_damage := false
        for index in range(source.quadros.size()):
            var q: Variant = source.quadros[index]
            if not q is Dictionary:
                errors.append("quadro invalido: " + id)
                continue
            var texture := _texture(String(q.get("arquivo", "")), String(q.get("sha256", "")), textures, hash_modes, errors)
            _dimensions(texture, q, errors)
            var anchor := _anchor(q.get("ancora"), errors)
            var milliseconds := float(q.get("ms", 0.0))
            if not is_finite(milliseconds) or milliseconds <= 0.0:
                errors.append("tempo de quadro invalido: " + id)
            total_ms += milliseconds
            var effects: Array[Dictionary] = []
            for fx: Variant in source.get("efeitos", []):
                if not fx is Dictionary or (fx.has("quadro") and int(fx.quadro) != index):
                    continue
                var phase := String(fx.get("fase", "")).to_upper()
                if phase not in ["TODAS", "ALL", "ACTIVE", "ATIVO", "WINDUP", "PREP", "RECOVERY", "RECUP"]:
                    errors.append("fase FX invalida: " + id)
                var fx_texture := _texture(String(fx.get("arquivo", "")), String(fx.get("sha256", "")), textures, hash_modes, errors)
                _dimensions(fx_texture, fx, errors)
                effects.append({"tex": fx_texture, "ancora": _anchor(fx.get("ancora"), errors), "fase": phase})
            var shadow_source: Variant = q.get("sombra", source.get("sombra", {}))
            var shadow := {}
            if shadow_source is Dictionary and not shadow_source.is_empty():
                var shadow_tex := _texture(String(shadow_source.get("arquivo", "")), String(shadow_source.get("sha256", "")), textures, hash_modes, errors)
                _dimensions(shadow_tex, shadow_source, errors)
                if shadow_tex != null:
                    var bbox := shadow_tex.get_image().get_used_rect()
                    if bbox.has_area():
                        var atlas := AtlasTexture.new()
                        atlas.atlas = shadow_tex
                        atlas.region = bbox
                        shadow = {"texture": atlas, "bbox": bbox, "ancora": _anchor(shadow_source.get("ancora"), errors)}
            var damage := {}
            if q.get("hitbox") is Dictionary:
                damage = decode_hitbox(q.hitbox, errors)
                has_damage = true
            frames.append({"tex": texture, "arquivo": String(q.get("arquivo", "")), "ancora": anchor, "ms": milliseconds, "sombra": shadow, "efeitos": effects, "hitbox": damage})
        anims[id] = {"frames": frames, "loop": bool(source.get("loop", false)), "ms": total_ms, "has_damage": has_damage, "attack": source.get("ataque", {}), "px_per_frame": float(source.get("px_por_quadro", 6.0)), "supports": source.get("apoios", [1, 5])}
    for id in ["idle", "run", "run_start", "run_stop", "turn", "jump_up", "fall_start", "fall_loop", "land", "dash", "dash_ar", "light1", "light2", "light3", "post_dash", "air_light", "air_heavy", "heavy", "charge_start", "charge_loop", "charge_full", "charged_heavy", "parry", "parry_spark", "hurt", "attack_exit"]:
        if not anims.has(id):
            errors.append("animacao necessaria ausente: " + id)
    cached = {"valid": errors.is_empty(), "errors": errors, "anims": anims, "attacks": ATTACKS, "trail": parsed.get("rastro_dash", {}), "hash_modes": hash_modes, "manifest_sha256": FileAccess.get_sha256(ROOT + "manifesto_sprites.json")}
    return cached

static func character() -> Dictionary:
    var package := load_package()
    if not package.valid:
        return {}
    # Adapter for the P40 presenter contract; the manifest itself is the v34A format.
    var anims: Dictionary = package.anims.duplicate(true)
    for anim: Dictionary in anims.values():
        for frame: Dictionary in anim.frames:
            if frame.hitbox.is_empty():
                frame.hitbox = null
            else:
                frame.hitbox = {"partes": frame.hitbox.parts, "fase": frame.hitbox.phase, "valida": true}
    return {"id": "pequeno_a", "nome": "Pequeno A v34A", "v32": true, "anims": anims,
        "estado_anim": {"idle": "idle", "run": "run", "walk": "run", "run_start": "run_start", "run_stop": "run_stop", "turn": "turn", "jump": "jump_up", "fall": "fall_start", "land": "land", "ground_dash": "dash", "air_dash": "dash_ar", "charge": "charge_loop", "parry": "parry", "hit": "hurt", "death": "hurt", "ruptured": "hurt", "attack_exit": "attack_exit"},
        "ataque_anim": ATTACKS, "padrao": "idle", "px_por_quadro": package.anims.run.px_per_frame,
        "apoios": package.anims.run.supports, "rastro": package.trail}

static func _anchor(value: Variant, errors: Array[String]) -> Vector2:
    if not value is Array or value.size() != 2 or not _number(value[0]) or not _number(value[1]):
        errors.append("ancora invalida")
        return Vector2.ZERO
    var result := Vector2(float(value[0]), float(value[1]))
    if result != result.round():
        errors.append("ancora deve usar pixels inteiros")
    return result

static func _number(value: Variant) -> bool:
    return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _dimensions(texture: Texture2D, spec: Dictionary, errors: Array[String]) -> void:
    if texture == null:
        return
    if spec.has("largura") and (not _number(spec.largura) or float(spec.largura) != texture.get_width()):
        errors.append("largura diverge do PNG: " + String(spec.get("arquivo", "")))
    if spec.has("altura") and (not _number(spec.altura) or float(spec.altura) != texture.get_height()):
        errors.append("altura diverge do PNG: " + String(spec.get("arquivo", "")))

static func safe_path(relative: String) -> bool:
    return not relative.is_empty() and not relative.is_absolute_path() and not relative.contains(":") and not relative.contains("\\") and not relative.split("/").has("..")

static func sha256_without_cabx(bytes: PackedByteArray) -> String:
    if bytes.size() < 20 or bytes.slice(0, 8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
        return ""
    var kept := bytes.slice(0, 8)
    var offset := 8
    var ended := false
    while offset + 12 <= bytes.size():
        var length := (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3]
        var end := offset + 12 + length
        if length < 0 or end > bytes.size():
            return ""
        var kind := bytes.slice(offset + 4, offset + 8).get_string_from_ascii()
        if kind != "caBX":
            kept.append_array(bytes.slice(offset, end))
        offset = end
        if kind == "IEND":
            ended = true
            break
    if not ended or offset != bytes.size():
        return ""
    var hash := HashingContext.new()
    hash.start(HashingContext.HASH_SHA256)
    hash.update(kept)
    return hash.finish().hex_encode()

static func _texture(relative: String, expected: String, textures: Dictionary, modes: Dictionary, errors: Array[String]) -> Texture2D:
    if not safe_path(relative):
        errors.append("caminho invalido: " + relative)
        return null
    var bytes := FileAccess.get_file_as_bytes(ROOT + relative)
    var mode := "raw" if FileAccess.get_sha256(ROOT + relative) == expected else "caBX"
    if expected.length() != 64 or (mode == "caBX" and sha256_without_cabx(bytes) != expected):
        errors.append("SHA256 diverge: " + relative)
        return null
    if textures.has(relative):
        return textures[relative]
    var image := Image.new()
    if image.load_png_from_buffer(bytes) != OK or image.is_empty():
        errors.append("PNG invalido: " + relative)
        return null
    var texture := ImageTexture.create_from_image(image)
    textures[relative] = texture
    modes[relative] = mode
    return texture

## Rectangles and possibly concave polygons, relative to the feet anchor.
## Clip at x=0 before decomposition: behind-the-player damage is never inferred.
static func decode_hitbox(spec: Dictionary, errors: Array[String]) -> Dictionary:
    var polygons: Array = []
    for key in ["arco", "lamina"]:
        if spec.get(key) is Dictionary and spec[key].get("poligono") is Array:
            polygons.append(spec[key].poligono)
    if spec.get("poligono") is Array:
        polygons.append(spec.poligono)
    var rectangles: Variant = spec.get("retangulos", [])
    if spec.get("retangulo") is Array:
        rectangles = [spec.retangulo]
    if not rectangles is Array:
        errors.append("retangulos deve ser uma lista")
        rectangles = []
    for rectangle: Variant in rectangles:
        if not rectangle is Array or rectangle.size() != 4 or not rectangle.all(_number) or float(rectangle[2]) <= 0 or float(rectangle[3]) <= 0:
            errors.append("retangulo invalido")
            continue
        var x := float(rectangle[0])
        var y := float(rectangle[1])
        var w := float(rectangle[2])
        var h := float(rectangle[3])
        polygons.append([[x, y], [x + w, y], [x + w, y + h], [x, y + h]])
    var parts: Array[PackedVector2Array] = []
    for source: Variant in polygons:
        var polygon := PackedVector2Array()
        var valid: bool = source is Array and source.size() >= 3
        if valid:
            for point: Variant in source:
                if not point is Array or point.size() != 2 or not point.all(_number):
                    valid = false
                    break
                polygon.append(Vector2(float(point[0]), float(point[1])))
        if not valid:
            errors.append("poligono invalido")
            continue
        polygon = clip_front(polygon)
        if polygon.size() < 3:
            continue
        if Geometry2D.is_polygon_clockwise(polygon):
            polygon.reverse()
        var pieces := Geometry2D.decompose_polygon_in_convex(polygon)
        if pieces.is_empty():
            errors.append("poligono nao decomponivel")
        for piece: PackedVector2Array in pieces:
            var hull := Geometry2D.convex_hull(piece)
            if hull.size() > 1 and hull[0] == hull[-1]:
                hull.remove_at(hull.size() - 1)
            hull = simplify_convex(hull)
            if hull.size() >= 3:
                parts.append(hull)
    return {"parts": parts, "phase": String(spec.get("fase", "ACTIVE")).to_upper()}

static func clip_front(polygon: PackedVector2Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for index in range(polygon.size()):
        var a := polygon[index]
        var b := polygon[(index + 1) % polygon.size()]
        if a.x >= 0.0:
            result.append(a)
        if (a.x >= 0.0) != (b.x >= 0.0):
            result.append(a.lerp(b, -a.x / (b.x - a.x)))
    return result

static func simplify_convex(points: PackedVector2Array) -> PackedVector2Array:
    var pts := points.duplicate()
    while pts.size() > 3:
        var best := -1
        var smallest := 0.25
        for i in range(pts.size()):
            var a := pts[(i - 1 + pts.size()) % pts.size()]
            var b := pts[i]
            var c := pts[(i + 1) % pts.size()]
            var length := a.distance_to(c)
            var deviation := b.distance_to(a) if length < 0.0001 else absf((c - a).cross(b - a)) / length
            if deviation < smallest:
                best = i
                smallest = deviation
        if best < 0:
            break
        pts.remove_at(best)
    return pts

static func frame_at_ms(frames: Array, milliseconds: float, loop := false) -> int:
    var total := 0.0
    for frame: Dictionary in frames:
        total += float(frame.ms)
    var t := fposmod(milliseconds, total) if loop else clampf(milliseconds, 0.0, total - 0.00001)
    var cumulative := 0.0
    for i in range(frames.size()):
        cumulative += float(frames[i].ms)
        if t < cumulative - 0.000001:
            return i
    return frames.size() - 1
