extends Node2D

const START_POSITION := Vector2(120, 215)
const WORLD_LENGTH := 8200.0
const END_X := 8050.0
const FALL_Y := 355.0

@onready var player: CharacterBody2D = $Player
@onready var feedback: Label = $CanvasLayer/Feedback

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
    for child in $Encounters.get_children():
        if child is ForestEncounter:
            encounters.append(child)
            for enemy in child.enemies:
                enemy.get_node("StatusLabel").visible = false
    player.get_node("Camera2D").limit_right = int(WORLD_LENGTH)
    player.get_node("Health").depleted.connect(_on_player_death)
    player.global_position = START_POSITION
    player.velocity = Vector2.ZERO
    feedback.visible = false


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        for encounter in encounters:
            for enemy in encounter.enemies:
                var label: Label = enemy.get_node("StatusLabel")
                label.visible = not label.visible


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("reset_dummy"):
        reset_slice()
        return
    elapsed_seconds += delta
    if death_reset_seconds >= 0.0:
        death_reset_seconds -= delta
        if death_reset_seconds <= 0.0:
            reset_slice()
        return
    if player.global_position.y > FALL_Y or player.global_position.x < -25.0 or player.global_position.x > WORLD_LENGTH + 25.0:
        recover_from_fall()
    safe_sample_seconds += delta
    if safe_sample_seconds >= 0.15:
        safe_sample_seconds = 0.0
        _record_safe_position()
    if not finished and player.global_position.x >= END_X:
        finished = true
        feedback.text = "FIM DA FATIA — MILESTONE 7\nTempo: %.0f s" % elapsed_seconds
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
    player.global_position = START_POSITION
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1.0
    player.get_node("VisualRoot").modulate = Color.WHITE
    combat.set_facing(1)
    defense.set_facing(1)
    for encounter in encounters:
        encounter.reset_encounter()
    safe_position = START_POSITION
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
    if pos.x < 35.0 or pos.x > WORLD_LENGTH - 35.0:
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
