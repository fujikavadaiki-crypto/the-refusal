extends Node2D

const START_POSITION := Vector2(120, 215)
const WORLD_LENGTH := 8200.0
const END_X := 8050.0
const FALL_Y := 355.0

@export var slice_start := START_POSITION
@export var slice_length := WORLD_LENGTH
@export var slice_end_x := END_X
@export var slice_fall_y := FALL_Y
@export var starting_mask: MaskData
@export var playtest_presentation := false

@onready var player: CharacterBody2D = $Player
@onready var feedback: Label = $CanvasLayer/Feedback
@onready var health_label: Label = get_node_or_null("CanvasLayer/HealthLabel") as Label

var encounters: Array[ForestEncounter] = []
var safe_position := START_POSITION
var elapsed_seconds := 0.0
var finished := false
var fall_recovery_count := 0
var reset_count := 0
var death_reset_seconds := -1.0
var feedback_seconds := 0.0
var safe_sample_seconds := 0.0


func _ready() -> void:
    if playtest_presentation:
        _build_approved_bosque_collision()
    for child in $Encounters.get_children():
        if child is ForestEncounter:
            encounters.append(child)
            for enemy in child.enemies:
                enemy.get_node("StatusLabel").visible = false
    player.get_node("Camera2D").limit_right = int(slice_length)
    if playtest_presentation:
        player.get_node("Camera2D").limit_bottom = 390
    player.get_node("Health").depleted.connect(_on_player_death)
    player.global_position = slice_start
    player.velocity = Vector2.ZERO
    safe_position = slice_start
    if playtest_presentation:
        player.get_node("VisualRoot").approved_board_mode = true
    if starting_mask != null:
        player.get_node("MaskController").equip(0, starting_mask)
    if playtest_presentation:
        player.get_node("DebugLabel").visible = false
        player.get_node("Camera2D").impact_shake_enabled = true
        player.get_node("VisualRoot").slice_feedback_enabled = true
    feedback.visible = false


func _build_approved_bosque_collision() -> void:
    # The three painted Bosque paths are the source of the playable topology.
    # Existing technical collision pieces remain in the scene for older tests,
    # but are inactive here so the player stands on the painted ledges.
    for child in get_children():
        if child is StaticBody2D and child.name != "LeftBoundary" and child.name != "RightBoundary":
            child.collision_layer = 0
    var paths := [
        PackedVector2Array([
            Vector2(0, 180), Vector2(130, 183), Vector2(200, 196),
            Vector2(270, 215), Vector2(360, 225), Vector2(500, 230),
            Vector2(580, 235), Vector2(615, 225), Vector2(660, 205),
            Vector2(730, 203), Vector2(800, 211), Vector2(860, 226),
            Vector2(940, 238), Vector2(1040, 242), Vector2(1120, 240),
            Vector2(1170, 237),
        ]),
        PackedVector2Array([
            Vector2(1200, 162), Vector2(1250, 163), Vector2(1300, 165),
            Vector2(1430, 168), Vector2(1470, 170), Vector2(1510, 195),
            Vector2(1580, 216),
            Vector2(1690, 226), Vector2(1820, 231), Vector2(1960, 233),
            Vector2(2110, 242), Vector2(2290, 249), Vector2(2390, 247),
        ]),
        PackedVector2Array([
            Vector2(2500, 164), Vector2(2600, 165), Vector2(2730, 192),
            Vector2(2870, 209), Vector2(3000, 218), Vector2(3140, 226),
            Vector2(3300, 222), Vector2(3450, 222), Vector2(3540, 231),
            Vector2(3600, 242), Vector2(3675, 242),
        ]),
        PackedVector2Array([
            Vector2(3800, 160), Vector2(3850, 158), Vector2(3900, 158),
        ]),
    ]
    for i in range(paths.size()):
        var surface: PackedVector2Array = paths[i]
        var polygon := PackedVector2Array(surface)
        polygon.append(Vector2(surface[surface.size() - 1].x, 430))
        polygon.append(Vector2(surface[0].x, 430))
        var ground := StaticBody2D.new()
        ground.name = "ApprovedBosqueGround%d" % i
        ground.collision_layer = 1
        ground.collision_mask = 0
        add_child(ground)
        var shape := CollisionPolygon2D.new()
        shape.polygon = polygon
        ground.add_child(shape)


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        for encounter in encounters:
            for enemy in encounter.enemies:
                var label: Label = enemy.get_node("StatusLabel")
                label.visible = not label.visible


func _physics_process(delta: float) -> void:
    if health_label != null:
        health_label.text = "VIDA %d/%d" % [player.get_node("Health").current_health, player.get_node("Health").max_health]
    if Input.is_action_just_pressed("reset_dummy"):
        reset_slice()
        return
    elapsed_seconds += delta
    if death_reset_seconds >= 0.0:
        death_reset_seconds -= delta
        if death_reset_seconds <= 0.0:
            reset_slice()
        return
    if player.global_position.y > slice_fall_y or player.global_position.x < -25.0 or player.global_position.x > slice_length + 25.0:
        recover_from_fall()
    safe_sample_seconds += delta
    if safe_sample_seconds >= 0.15:
        safe_sample_seconds = 0.0
        _record_safe_position()
    if not finished and player.global_position.x >= slice_end_x and player.is_on_floor():
        finished = true
        feedback.text = ("FIM DO TRECHO — BOSQUE DOS ESQUECIDOS\nTempo: %.0f s  |  R para reiniciar" if playtest_presentation else "FIM DA FATIA — MILESTONE 7\nTempo: %.0f s") % elapsed_seconds
        feedback.visible = true
        feedback_seconds = -1.0
    if feedback_seconds > 0.0:
        feedback_seconds -= delta
        if feedback_seconds <= 0.0:
            feedback.visible = false


func reset_slice() -> void:
    get_node("/root/HitStop")._restore()
    var combat: PlayerCombat = player.get_node("Combat")
    var defense: PlayerDefense = player.get_node("Defense")
    combat.abort_attack()
    player.clear_action_buffers()
    player.get_node("Locomotion").reset_assists()
    player.get_node("Camera2D").clear_impact()
    player.get_node("Health").reset_health()
    player.get_node("Posture").reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    defense.parry_consumed = false
    defense.spark_remaining = 0.0
    defense.air_dash_available = true
    player.get_node("ParrySpark").visible = false
    player.get_node("ParryAudio").stop()
    player.global_position = slice_start
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1.0
    player.get_node("VisualRoot").modulate = Color.WHITE
    combat.set_facing(1)
    defense.set_facing(1)
    for encounter in encounters:
        encounter.reset_encounter()
    safe_position = slice_start
    safe_sample_seconds = 0.0
    elapsed_seconds = 0.0
    finished = false
    death_reset_seconds = -1.0
    feedback_seconds = 0.0
    feedback.visible = false
    reset_count += 1


func recover_from_fall() -> void:
    var defense: PlayerDefense = player.get_node("Defense")
    player.get_node("Combat").abort_attack()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    # The safe point is on solid ground, but the charge returns only after
    # CharacterBody2D confirms a real landing on the next movement step.
    defense.air_dash_available = false
    player.global_position = safe_position
    player.velocity = Vector2.ZERO
    fall_recovery_count += 1
    feedback.text = "RECUPERAÇÃO DE NAVEGAÇÃO — SEM DANO"
    feedback.visible = true
    feedback_seconds = 1.1


func _on_player_death() -> void:
    death_reset_seconds = 0.9
    feedback.text = "MORTE — RESET TÉCNICO PROVISÓRIO"
    feedback.visible = true
    feedback_seconds = -1.0


func _record_safe_position() -> void:
    if not player.is_on_floor() or player.get_node("Health").current_health <= 0:
        return
    var pos := player.global_position
    if pos.x < 35.0 or pos.x > slice_length - 35.0:
        return
    for encounter in encounters:
        for enemy in encounter.enemies:
            if enemy.get_node("Health").current_health > 0 and absf(enemy.global_position.x - pos.x) < 36.0 and absf(enemy.global_position.y - pos.y) < 38.0:
                return
    if _stable_ground_at(pos + Vector2(-12, 0)) and _stable_ground_at(pos + Vector2(12, 0)):
        safe_position = pos


func _stable_ground_at(point: Vector2) -> bool:
    var query := PhysicsRayQueryParameters2D.create(point, point + Vector2(0, 26), 1)
    query.exclude = [player.get_rid()]
    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.collider is StaticBody2D
