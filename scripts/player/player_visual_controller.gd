class_name PlayerVisualController
extends Node2D

## Presentation adapter. Reads gameplay state; never drives movement or hitboxes.
signal audio_cue_requested(cue: StringName)

const IMPACT := preload("res://scenes/player/visuals/carrasco_impact.tscn")

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var combat: PlayerCombat = $"../Combat"
@onready var defense: PlayerDefense = $"../Defense"
@onready var masks: MaskController = $"../MaskController"
@onready var health: HealthComponent = $"../Health"
@onready var blade: Polygon2D = $"../AttackPivot/SwordBlade"
@onready var handle: Polygon2D = $"../AttackPivot/SwordHandle"
@onready var active_marker: Polygon2D = $"../AttackPivot/ActiveMarker"
@onready var charge_marker: Polygon2D = $"../AttackPivot/ChargeMarker"

var form: Node2D
var damage_remaining := 0.0
var execution_remaining := 0.0
var tribunal_activation_remaining := 0.0
var execution_pose: StringName = &"execution"
var tribunal_was_active := false
func _ready() -> void:
    masks.mask_changed.connect(_on_mask_changed)
    masks.execution_resolved.connect(_on_execution)
    combat.attack_started.connect(_on_attack_started)
    combat.hit_confirmed.connect(_on_hit_confirmed)
    health.damage_taken.connect(_on_damage_taken)
    _on_mask_changed(masks.active_data())


func _process(delta: float) -> void:
    damage_remaining = maxf(0.0, damage_remaining - delta)
    execution_remaining = maxf(0.0, execution_remaining - delta)
    tribunal_activation_remaining = maxf(0.0, tribunal_activation_remaining - delta)
    if form == null:
        return
    var runtime := masks.active_state()
    var tribunal := runtime != null and runtime.ultimate_remaining > 0.0
    if tribunal and not tribunal_was_active:
        tribunal_activation_remaining = 0.24
        audio_cue_requested.emit(&"tribunal")
    elif not tribunal:
        tribunal_activation_remaining = 0.0
    tribunal_was_active = tribunal
    var visual_state := _state_name()
    var progress := 0.0
    if combat.current_attack != null:
        var attack := combat.current_attack
        match combat.phase:
            PlayerCombat.Phase.WINDUP:
                progress = combat.elapsed / maxf(attack.windup_seconds, 0.001)
            PlayerCombat.Phase.ACTIVE:
                progress = (combat.elapsed - attack.windup_seconds) / maxf(attack.active_seconds, 0.001)
            PlayerCombat.Phase.RECOVERY:
                progress = (combat.elapsed - attack.windup_seconds - attack.active_seconds) / maxf(attack.recovery_seconds, 0.001)
    form.call("set_pose", visual_state, combat.phase, progress, combat.charge_ready(), tribunal)


func _state_name() -> StringName:
    if defense.mode == PlayerDefense.Mode.DEAD:
        return &"death"
    if defense.mode == PlayerDefense.Mode.STAGGERED:
        return &"ruptured"
    if execution_remaining > 0.0:
        return execution_pose
    if damage_remaining > 0.0:
        return &"hit"
    if combat.is_charging():
        return &"charge"
    if combat.current_attack != null:
        return combat.current_attack.attack_id
    if tribunal_activation_remaining > 0.0:
        return &"tribunal_activate"
    if defense.mode == PlayerDefense.Mode.AIR_DASH:
        return &"air_dash"
    if defense.mode == PlayerDefense.Mode.DODGING:
        return &"ground_dash"
    if defense.mode == PlayerDefense.Mode.PARRYING:
        return &"parry"
    if not player.is_on_floor():
        return &"jump" if player.velocity.y < 0.0 else &"fall"
    if absf(player.velocity.x) <= 5.0:
        return &"idle"
    return &"walk" if Input.is_action_pressed("walk") else &"run"


func _on_mask_changed(data: MaskData) -> void:
    var retiring_form := form
    if form != null:
        form.visible = false
        form.queue_free()
        form = null
    var masked := data != null and data.visual_scene != null
    for child in get_children():
        if child != retiring_form:
            child.visible = not masked and child.name != "MaskBadge"
    blade.modulate.a = 0.0 if masked else 1.0
    handle.modulate.a = 0.0 if masked else 1.0
    active_marker.modulate.a = 1.0
    charge_marker.modulate.a = 1.0
    tribunal_was_active = false
    if not masked:
        return
    form = data.visual_scene.instantiate() as Node2D
    add_child(form)
    active_marker.modulate.a = 0.0
    charge_marker.modulate.a = 0.0
    if form.has_method("bind_runtime"):
        form.call("bind_runtime", masks.active_state())


func _on_attack_started(attack: AttackData, _action_uid: int) -> void:
    if form != null:
        audio_cue_requested.emit(attack.attack_id)


func _on_hit_confirmed(context: HitContext) -> void:
    if form == null or context.target == null or context.outcome == HitContext.Outcome.CONTACT:
        return
    var kind: StringName = &"slash"
    if context.attack_id == &"carrasco_quebra_selos":
        kind = &"seal_break"
    elif context.attack_id == &"carrasco_charged_heavy":
        kind = &"charged"
    elif context.tags.has("heavy"):
        kind = &"heavy"
    elif context.tags.has("mark"):
        kind = &"mark"
    _spawn_impact(context.target.global_position + Vector2(0, -12), kind)
    if context.caused_rupture or context.actual_posture_damage >= 40:
        _spawn_impact(context.target.global_position + Vector2(0, -18), &"posture")


func _on_damage_taken(_context: HitContext) -> void:
    damage_remaining = 0.18


func _on_execution(target: Node2D, result: int) -> void:
    if form == null:
        return
    execution_remaining = 0.28
    execution_pose = &"execution" if result == ExecutionResolver.Result.COMMON_KILL else &"execution_strike"
    _spawn_impact(target.global_position + Vector2(0, -14), &"execution" if result == ExecutionResolver.Result.COMMON_KILL else &"sentence")
    audio_cue_requested.emit(&"execution")


func _spawn_impact(world_position: Vector2, kind: StringName) -> void:
    var effect := IMPACT.instantiate() as Node2D
    player.get_parent().add_child(effect)
    effect.global_position = world_position
    effect.call("start", kind, player.facing_direction)
