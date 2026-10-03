extends Node

## One recipient-side feedback component for players and enemies. Never requests hitstop.
const UNITS := 32.0 / 0.9
var actor: CharacterBody2D
var flash_frames := 0
var recoil := 0.0
var recoil_origin := 0.0
var saved_materials: Dictionary = {}
var white: ShaderMaterial
var hit_count := 0

func _ready() -> void:
    actor = get_parent()
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 100
    var shader := Shader.new()
    shader.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE,UV)*COLOR; COLOR=vec4(vec3(1.0),c.a); }"
    white = ShaderMaterial.new()
    white.shader = shader
    actor.get_node("Health").damage_taken.connect(_on_damage)
    actor.get_node("Health").reset_done.connect(reset)
    get_node("/root/Sensacao").group_changed.connect(_on_group)

func _on_group(group: String, state: bool) -> void:
    if group == "impacto" and not state: reset()

func reset() -> void:
    flash_frames = 0
    recoil = 0.0
    _restore_materials()

func _restore_materials() -> void:
    for item in saved_materials:
        if is_instance_valid(item): item.material = saved_materials[item]
    saved_materials.clear()

func _whiten(item: Node) -> void:
    if item is Sprite2D or item is Polygon2D:
        if not saved_materials.has(item): saved_materials[item] = item.material
        item.material = white
    for child in item.get_children(): _whiten(child)

func _process(_delta: float) -> void:
    if flash_frames <= 0:
        if not saved_materials.is_empty(): _restore_materials()
        return
    var presenter := actor.get_node_or_null("ApresentadorPacote")
    if presenter != null and presenter.active:
        _whiten(presenter.body)
    elif actor.get_meta("small_carrasco_presenter_active", false):
        _whiten(actor.get_node("VisualRoot").form.body)
    else:
        _whiten(actor.get_node("VisualRoot"))
    flash_frames -= 1

func _on_damage(context: HitContext) -> void:
    var feel := get_node("/root/Sensacao")
    if not feel.enabled("impacto"): return
    hit_count += 1
    flash_frames = int(feel.value("impacto", "flash_quadros"))
    var heavy := context.tags.has("heavy")
    var away := signf(actor.global_position.x - context.attacker.global_position.x) if is_instance_valid(context.attacker) else -float(actor.get("facing_direction"))
    if is_zero_approx(away): away = -float(actor.get("facing_direction"))
    recoil_origin = actor.global_position.x
    recoil = away * feel.value("impacto", "recuo_pesado_m_s" if heavy else "recuo_leve_m_s") * UNITS
    # Death preserves the AI's original fall and corpse behavior.
    if actor.get_node("Health").current_health <= 0: recoil = 0.0
    var target_shape := actor.get_node_or_null("Hurtbox/CollisionShape2D") as Node2D
    feel.pixels.emit_pixels(target_shape.global_position if target_shape != null else actor.global_position, "sangue", away)
    if heavy:
        var camera := actor.get_viewport().get_camera_2d()
        if camera != null and camera.has_method("add_heavy_impact"): camera.add_heavy_impact()

func apply_recoil(delta: float) -> void:
    if is_zero_approx(recoil): return
    var feel := get_node("/root/Sensacao")
    if not feel.enabled("impacto") or absf(actor.global_position.x - recoil_origin) >= feel.value("impacto", "recuo_limite_m") * UNITS:
        recoil = 0.0
        return
    actor.velocity.x = recoil
    recoil = move_toward(recoil, 0.0, feel.value("impacto", "recuo_atrito_m_s2") * UNITS * delta)

func _exit_tree() -> void:
    _restore_materials()
