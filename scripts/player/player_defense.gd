class_name PlayerDefense
extends Node

signal dodge_started(direction: int)
signal parry_started
signal parry_succeeded(context: HitContext)
signal stagger_started

enum Mode { READY, DODGING, PARRYING, STAGGERED, DEAD }

@export var dodge_total_seconds := 0.40
@export var iframe_start_seconds := 0.07
@export var iframe_end_seconds := 0.25
@export var dodge_repeat_delay_seconds := 0.28
@export var dodge_speed_multiplier := 2.0
@export var parry_active_seconds := 0.16
@export var parry_total_seconds := 0.38
@export var parry_posture_multiplier := 1.0
@export var parry_hit_stop_ms := 80

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var locomotion: PlayerLocomotion = $"../Locomotion"
@onready var posture: PostureComponent = $"../Posture"
@onready var health: HealthComponent = $"../Health"
@onready var visual_root: Node2D = $"../VisualRoot"
@onready var spark: Polygon2D = $"../ParrySpark"
@onready var parry_audio: AudioStreamPlayer2D = $"../ParryAudio"
@onready var debug_label: Label = $"../DebugLabel"

var mode := Mode.READY
var elapsed := 0.0
var dodge_direction := 1
var dodge_cooldown := 0.0
var parry_consumed := false
var spark_remaining := 0.0


func _ready() -> void:
    posture.ruptured.connect(_on_ruptured)
    posture.recovered.connect(_on_recovered)
    health.depleted.connect(_on_depleted)
    spark.visible = false


func set_facing(direction: int) -> void:
    spark.position.x = 12.0 * direction
    spark.scale.x = direction


func _process(delta: float) -> void:
    if spark_remaining > 0.0:
        spark_remaining = maxf(0.0, spark_remaining - delta)
        spark.visible = spark_remaining > 0.0
    var iframe_text := "I-FRAME" if is_iframe_active() else "-"
    var parry_text := "ACTIVE" if is_parry_active() else ("RECOVERY" if mode == Mode.PARRYING else "-")
    var regen_text := "BROKEN" if posture.is_ruptured() else ("WAIT %.1f" % posture.regen_delay_remaining if posture.regen_delay_remaining > 0.0 else "REGEN")
    debug_label.text = "HP %d/%d  POST %d/%d\n%s  I:%s  P:%s" % [health.current_health, health.max_health, roundi(posture.current_posture), roundi(posture.max_posture), regen_text, iframe_text, parry_text]


func accept_inputs(dodge_pressed: bool, parry_pressed: bool, axis: float, facing: int, combat_busy: bool) -> void:
    if mode != Mode.READY or combat_busy or not player.is_on_floor():
        return
    if dodge_pressed and dodge_cooldown <= 0.0:
        dodge_direction = facing if is_zero_approx(axis) else (-1 if axis < 0.0 else 1)
        mode = Mode.DODGING
        elapsed = 0.0
        player.velocity.x = locomotion.run_speed * dodge_speed_multiplier * dodge_direction
        visual_root.modulate = Color(0.55, 0.8, 1.0)
        dodge_started.emit(dodge_direction)
    elif parry_pressed:
        mode = Mode.PARRYING
        elapsed = 0.0
        parry_consumed = false
        visual_root.modulate = Color(0.7, 1.0, 0.75)
        parry_started.emit()


func tick(delta: float) -> void:
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    if mode != Mode.DODGING and mode != Mode.PARRYING:
        return
    elapsed += delta
    if mode == Mode.DODGING and elapsed >= dodge_total_seconds:
        mode = Mode.READY
        dodge_cooldown = dodge_repeat_delay_seconds
        visual_root.modulate = Color.WHITE
    elif mode == Mode.PARRYING and elapsed >= parry_total_seconds:
        mode = Mode.READY
        visual_root.modulate = Color.WHITE


func is_locked() -> bool:
    return mode != Mode.READY


func is_iframe_active() -> bool:
    return mode == Mode.DODGING and elapsed >= iframe_start_seconds and elapsed < iframe_end_seconds


func is_parry_active() -> bool:
    return mode == Mode.PARRYING and elapsed < parry_active_seconds and not parry_consumed


func movement_axis(input_axis: float) -> float:
    match mode:
        Mode.DODGING:
            return dodge_direction * dodge_speed_multiplier
        Mode.PARRYING:
            return input_axis * 0.25
        Mode.STAGGERED, Mode.DEAD:
            return 0.0
        _:
            return input_axis


func try_defend(context: HitContext) -> bool:
    if is_iframe_active():
        context.outcome = HitContext.Outcome.DODGED
        return true
    if not is_parry_active() or context.parry_class != &"parryable":
        return false
    parry_consumed = true
    context.outcome = HitContext.Outcome.PARRIED
    if context.attacker_posture != null:
        var pressure := float(context.posture_damage) * context.posture_damage_multiplier
        var returned := roundi(pressure * parry_posture_multiplier)
        if context.attacker_stats != null:
            returned = DamageResolver.parry_return_amount(pressure, parry_posture_multiplier, context.attacker_stats)
        context.parry_posture_return = context.attacker_posture.receive_damage(returned)
    spark_remaining = 0.16
    spark.visible = true
    parry_audio.play()
    get_node("/root/HitStop").request_ms(parry_hit_stop_ms, 2)
    parry_succeeded.emit(context)
    return true


func _on_ruptured() -> void:
    if mode == Mode.DEAD:
        return
    mode = Mode.STAGGERED
    elapsed = 0.0
    player.velocity.x = 0.0
    visual_root.modulate = Color(1.0, 0.68, 0.5)
    player.get_node("Combat").abort_attack()
    stagger_started.emit()


func _on_recovered() -> void:
    if mode == Mode.STAGGERED:
        mode = Mode.READY
        visual_root.modulate = Color.WHITE


func _on_depleted() -> void:
    mode = Mode.DEAD
    visual_root.modulate = Color(0.45, 0.45, 0.45)
    player.get_node("Combat").abort_attack()
