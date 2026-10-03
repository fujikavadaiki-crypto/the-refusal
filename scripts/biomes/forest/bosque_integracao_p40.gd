extends "res://scripts/biomes/forest/bosque_room_aprovada.gd"

## Isolated playable encounter: approved Bosque geometry/art and original enemy AI.
const ENEMIES := {
    "Peregrino": preload("res://scenes/enemies/peregrino.tscn"),
    "Corvo": preload("res://scenes/enemies/corvo.tscn"),
    "Raiz": preload("res://scenes/enemies/raiz_faminta.tscn"),
}
var enemies: Array[CharacterBody2D] = []
var hud: Label
var debug_geometry := false
var enemies_ready := false

func _ready() -> void:
    super._ready()
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(16, 12)
    hud.add_theme_font_size_override("font_size", 15)
    hud.add_theme_color_override("font_shadow_color", Color.BLACK)
    hud.add_theme_constant_override("shadow_offset_x", 1)
    hud.add_theme_constant_override("shadow_offset_y", 1)
    layer.add_child(hud)
    _populate.call_deferred()

func ground_at(x: float) -> Vector2:
    var ray := PhysicsRayQueryParameters2D.create(Vector2(x, -120), Vector2(x, 600), 1)
    ray.collide_with_areas = false
    ray.exclude = [player.get_rid()]
    for enemy in enemies:
        if is_instance_valid(enemy):
            ray.exclude.append(enemy.get_rid())
    var hit := get_world_2d().direct_space_state.intersect_ray(ray)
    return hit.get("position", Vector2(x, 280))

func _populate() -> void:
    await get_tree().physics_frame
    for spec in [["Peregrino", 330.0, 15.5], ["Corvo", 650.0, 86.0], ["Raiz", 800.0, 9.0]]:
        var enemy: CharacterBody2D = ENEMIES[spec[0]].instantiate()
        enemy.name = spec[0]
        enemy.position = ground_at(spec[1]) - Vector2(0, spec[2] + 0.05)
        enemy.z_index = 4
        enemy.get_node("Brain").player_path = NodePath("../../Player")
        add_child(enemy)
        enemies.append(enemy)
    enemies_ready = true

func restart_encounter() -> void:
    player.get_node("Combat").abort_attack()
    player.clear_action_buffers()
    player.get_node("Health").reset_health()
    player.get_node("Posture").reset_posture()
    var defense: PlayerDefense = player.get_node("Defense")
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    defense.air_dash_available = true
    player.position = start.position
    player.velocity = Vector2.ZERO
    player.get_node("Locomotion").reset_assists()
    safe_position = start.position
    fall_count = 0
    reached_exit = false
    var form: Node = player.get_node("VisualRoot").form
    if form != null and form.has_method("reset_tracking"):
        form.reset_tracking()
    for enemy in enemies:
        enemy.reset_enemy()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            restart_encounter()
        elif event.keycode == KEY_F3:
            debug_geometry = not debug_geometry
            get_tree().debug_collisions_hint = debug_geometry
            queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if hud != null:
        var hp: HealthComponent = player.get_node("Health")
        var posture: PostureComponent = player.get_node("Posture")
        hud.text = "BOSQUE · PEQUENO A\nVida %d/%d · Postura %d/%d\nA/D mover · Shift andar · Espaço pular · J leve · K pesado/carga\nL dash · I parry · Tab máscara · R reiniciar · F3 áreas" % [hp.current_health, hp.max_health, roundi(posture.current_posture), roundi(posture.max_posture)]
    if debug_geometry:
        queue_redraw()

func _draw() -> void:
    if not debug_geometry:
        return
    var hitbox: Hitbox2D = player.get_node("AttackPivot/Hitbox")
    for part: PackedVector2Array in hitbox.current_world_parts():
        var local := PackedVector2Array()
        for point in part:
            local.append(to_local(point))
        draw_colored_polygon(local, Color(1, 0.28, 0.1, 0.3))
        local.append(local[0])
        draw_polyline(local, Color(1, 0.5, 0.1), 1.0)
    draw_circle(to_local(player.global_position + Vector2(0, 13)), 1.5, Color.YELLOW)
