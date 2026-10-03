extends Node2D

const PACKAGE := preload("res://scripts/enemies/presentation/enemy_package.gd")
const CORE := preload("res://scripts/player/visuals/carrasco_p42b_package.gd")
const ZOOM := 0.9
var actor: CharacterBody2D
var mapping: Dictionary = {}
var package: Dictionary = {"valid": false, "anims": {}}
var active := false
var body := Sprite2D.new()
var shadow := Sprite2D.new()
var fx_root := Node2D.new()
var current_anim := ""
var frame_index := 0
var current_phase := ""
var feet_local := Vector2.ZERO
var fallback_reason := ""
var idle_ms := 0.0
var last_state := -1

func _ready() -> void:
    top_level = true
    process_priority = 90
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    body.centered = false
    shadow.centered = false
    shadow.z_index = -1
    add_child(shadow)
    add_child(body)
    add_child(fx_root)
    visible = false

func bind_actor(owner_actor: CharacterBody2D, map_path: String) -> void:
    actor = owner_actor
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(map_path)) if FileAccess.file_exists(map_path) else null
    if not parsed is Dictionary:
        fallback_reason = "mapeamento ausente/invalido"
        return
    mapping = parsed
    var raw_feet: Variant = mapping.get("pes_world", [0, 0])
    if not raw_feet is Array or raw_feet.size() != 2 or not raw_feet.all(CORE._number) or not mapping.get("estados", {}) is Dictionary or not mapping.get("ataques", {}) is Dictionary:
        package = {"valid": false, "anims": {}}
        fallback_reason = "mapa: pes/estados/ataques invalidos"
        return
    var feet: Array = raw_feet
    feet_local = Vector2(float(feet[0]), float(feet[1]))
    package = PACKAGE.load_package(String(mapping.get("pacote", "")))
    fallback_reason = "; ".join(package.get("errors", []))

func attack_sample(data: AttackData, elapsed: float) -> Dictionary:
    if not package.valid or data == null: return {}
    var id := String(mapping.get("ataques", {}).get(String(data.attack_id), ""))
    if not package.anims.has(id): return {}
    var sample := PACKAGE.attack_frame(package.anims[id], data, elapsed)
    sample.anim = id
    sample.has_damage = package.anims[id].has_damage
    return sample

func apply_damage(hitbox: Hitbox2D, data: AttackData, elapsed: float, origin := Vector2.INF, facing := 0) -> bool:
    var sample := attack_sample(data, elapsed)
    if sample.is_empty() or not sample.has_damage:
        hitbox.clear_frame_override()
        return false
    var parts: Array = []
    if sample.phase == "ACTIVE" and not sample.frame.hitbox.is_empty() and sample.frame.phase == "ACTIVE": parts = sample.frame.hitbox.parts
    var at := actor.global_position + feet_local if origin == Vector2.INF else origin
    hitbox.set_frame_parts(parts, at, int(actor.facing_direction) if facing == 0 else facing, ZOOM)
    return true

func projectile_sample(data: AttackData, age: float) -> Dictionary:
    if not package.valid or data == null: return {}
    var id := String(mapping.get("projeteis", {}).get(String(data.attack_id), ""))
    if not package.anims.has(id): return {}
    var anim: Dictionary = package.anims[id]
    var index := CORE.frame_at_ms(anim.frames, age * 1000, anim.loop)
    return {"frame": anim.frames[index], "index": index, "has_damage": anim.has_damage}

func _runtime_attack() -> Dictionary:
    var attack: Node = actor.get_node("Attack")
    var data: AttackData
    if "current_attack" in attack: data = attack.current_attack
    elif attack.mode == attack.Mode.DIVE: data = attack.rasante
    elif attack.mode == attack.Mode.PROJECTILE: data = attack.cuspe
    return attack_sample(data, float(attack.elapsed))

func _process(delta: float) -> void:
    if not is_instance_valid(actor): return
    var brain: Node = actor.get_node("Brain")
    if int(brain.state) != last_state:
        idle_ms = 0.0
        last_state = int(brain.state)
    idle_ms += delta * 1000
    var sample := _runtime_attack()
    if sample.is_empty() and package.valid:
        var names: Dictionary = brain.get_script().get_script_constant_map().get("State", {})
        var key := ""
        for name_ in names:
            if int(names[name_]) == int(brain.state): key = name_
        var id := String(mapping.get("estados", {}).get(key, mapping.get("padrao", "idle")))
        if package.anims.has(id):
            var anim: Dictionary = package.anims[id]
            var index := CORE.frame_at_ms(anim.frames, idle_ms, anim.loop)
            sample = {"anim": id, "index": index, "frame": anim.frames[index], "phase": "ALL"}
    var was_active := active
    active = not sample.is_empty()
    visible = active
    if not active:
        if was_active:
            actor.get_node("VisualRoot").visible = true
            if actor.has_method("_apply_state"): actor._apply_state(brain.state)
        return # Fallback never overrides the original hidden/death presentation.
    actor.get_node("VisualRoot").visible = false
    current_anim = sample.anim
    frame_index = sample.index
    current_phase = sample.phase
    for path in ["AttackPivot/Telegraph", "BeakTelegraph", "DiveTelegraph", "BurrowMark", "EmergeTelegraph", "AttackPivot/BiteTelegraph"]:
        var old := actor.get_node_or_null(path)
        if old != null: old.visible = false
    var canvas := get_viewport().get_canvas_transform()
    var feet := canvas * (actor.global_position + feet_local)
    global_transform = canvas.affine_inverse() * Transform2D(0.0, feet.round())
    var frame: Dictionary = sample.frame
    var left := int(actor.facing_direction) < 0
    _pose(body, frame.tex, frame.ancora, left)
    for child in fx_root.get_children(): child.free()
    for effect: Dictionary in frame.efeitos:
        if effect.fase not in ["ALL", current_phase]: continue
        var sprite := Sprite2D.new()
        sprite.centered = false
        fx_root.add_child(sprite)
        _pose(sprite, effect.tex, effect.ancora, left)
    _shadow(frame.sombra, left)

func _pose(sprite: Sprite2D, texture: Texture2D, anchor: Vector2, left: bool) -> void:
    sprite.texture = texture
    sprite.flip_h = left
    sprite.offset = Vector2(-(texture.get_width() - anchor.x) if left else -anchor.x, -anchor.y)

func _shadow(spec: Dictionary, left: bool) -> void:
    shadow.visible = false
    if spec.is_empty(): return
    var feet := actor.global_position + feet_local
    var ray := PhysicsRayQueryParameters2D.create(feet - Vector2(0, 2 / ZOOM), feet + Vector2(0, 1200 / ZOOM), 1)
    var excluded: Array[RID] = [actor.get_rid()]
    ray.exclude = excluded
    var space := actor.get_world_2d().direct_space_state
    var hit := space.intersect_ray(ray)
    for _i in range(32):
        if hit.is_empty() or not hit.collider is CharacterBody2D: break
        excluded.append(hit.collider.get_rid())
        ray.exclude = excluded
        hit = space.intersect_ray(ray)
    if hit.is_empty() or hit.collider is CharacterBody2D: return
    var ground: Vector2 = hit.position
    var factor := lerpf(1.0, .5, clampf((ground.y - feet.y) / (2.2 * 32 / ZOOM), 0, 1))
    var canvas := get_viewport().get_canvas_transform()
    shadow.visible = true
    shadow.texture = spec.texture
    shadow.flip_h = left
    var bbox: Rect2i = spec.bbox
    # Resize only the ground shadow; never resize the character or FX.
    var desired := Vector2(maxf(1, roundf(bbox.size.x * factor)), maxf(1, roundf(bbox.size.y * factor)))
    shadow.scale = desired / Vector2(bbox.size)
    var at := ((canvas * ground).round() - (canvas * feet).round())
    var anchor: Vector2 = spec.ancora
    var local_anchor := anchor - Vector2(bbox.position)
    if left: local_anchor.x = bbox.size.x - local_anchor.x
    shadow.position = (at - (local_anchor * shadow.scale).round()).round()
    shadow.offset = Vector2.ZERO
    shadow.modulate.a = factor
