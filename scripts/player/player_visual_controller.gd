class_name PlayerVisualController
extends Node2D

## Presentation adapter. Reads gameplay state; never drives movement or hitboxes.
signal audio_cue_requested(cue: StringName)

const IMPACT := preload("res://scenes/player/visuals/carrasco_impact.tscn")
const MODULAR_CARRASCO := preload("res://scenes/player/visuals/carrasco_modular.tscn")
const OFFICIAL_CARRASCO := preload("res://scenes/player/visuals/carrasco_base_official.tscn")
const SMALL_CARRASCO := preload("res://scripts/player/visuals/carrasco_pequeno_a.gd")
@export var small_carrasco_enabled := true
@export var slice_feedback_enabled := false
@export var approved_board_mode := false
@export var modular_carrasco_enabled := true
@export var official_base_enabled := true

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
var slash_remaining := 0.0
var slash_heavy := false
var dash_remaining := 0.0
var landing_remaining := 0.0
var previous_attack_phase := PlayerCombat.Phase.IDLE
var was_airborne := false
func _ready() -> void:
    masks.mask_changed.connect(_on_mask_changed)
    masks.execution_resolved.connect(_on_execution)
    combat.attack_started.connect(_on_attack_started)
    combat.hit_confirmed.connect(_on_hit_confirmed)
    health.damage_taken.connect(_on_damage_taken)
    defense.dodge_started.connect(_on_dash_started)
    defense.air_dash_started.connect(_on_dash_started)
    _on_mask_changed(masks.active_data())


func _process(delta: float) -> void:
    damage_remaining = maxf(0.0, damage_remaining - delta)
    execution_remaining = maxf(0.0, execution_remaining - delta)
    tribunal_activation_remaining = maxf(0.0, tribunal_activation_remaining - delta)
    if slice_feedback_enabled:
        if combat.phase == PlayerCombat.Phase.ACTIVE and previous_attack_phase != PlayerCombat.Phase.ACTIVE:
            slash_remaining = 0.12
            slash_heavy = combat.current_attack != null and combat.current_attack.tags.has("heavy")
        previous_attack_phase = combat.phase
        slash_remaining = maxf(0.0, slash_remaining - delta)
        dash_remaining = maxf(0.0, dash_remaining - delta)
        landing_remaining = maxf(0.0, landing_remaining - delta)
        if was_airborne and player.is_on_floor():
            landing_remaining = 0.12
        was_airborne = not player.is_on_floor()
        if slash_remaining > 0.0 or dash_remaining > 0.0 or landing_remaining > 0.0:
            queue_redraw()
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
        combat.frame_provider = null
        player.set_meta("small_carrasco_presenter_active", false)
        player.get_node("ParrySpark").modulate.a = 1.0
        return
    combat.frame_provider = null
    player.set_meta("small_carrasco_presenter_active", false)
    if data.mask_id == &"carrasco_base" and small_carrasco_enabled:
        var small := SMALL_CARRASCO.new()
        if small.PACKAGE.load_package().valid:
            form = small
            form.name = "CarrascoPequenoA"
            add_child(form)
            form.bind_player(player)
            combat.frame_provider = form
            player.set_meta("small_carrasco_presenter_active", true)
            active_marker.modulate.a = 0.0
            charge_marker.modulate.a = 0.0
            return
        small.free()
        push_error("Pequeno A package rejected; preserving legacy Carrasco presentation.")
    var visual_scene: PackedScene = data.visual_scene
    if data.mask_id == &"carrasco_base" and modular_carrasco_enabled:
        visual_scene = OFFICIAL_CARRASCO if official_base_enabled else MODULAR_CARRASCO
    form = visual_scene.instantiate() as Node2D
    if approved_board_mode and visual_scene == data.visual_scene:
        form.set("approved_board_mode", true)
    add_child(form)
    active_marker.modulate.a = 0.0
    charge_marker.modulate.a = 0.0
    if form.has_method("bind_runtime"):
        form.call("bind_runtime", masks.active_state())


func _on_attack_started(attack: AttackData, _action_uid: int) -> void:
    if form != null:
        audio_cue_requested.emit(attack.attack_id)


func _on_dash_started(_direction: int) -> void:
    if slice_feedback_enabled:
        dash_remaining = 0.22


func _draw() -> void:
    if get_node("/root/Sensacao").enabled("movimento") or not slice_feedback_enabled or form == null or player.get_meta("small_carrasco_presenter_active", false):
        return
    if slash_remaining > 0.0:
        var alpha := slash_remaining / 0.12
        var radius := 34.0 if slash_heavy else 27.0
        var points := PackedVector2Array()
        for i in range(7):
            var angle := -1.15 + float(i) * 0.36
            points.append(Vector2(9.0 + cos(angle) * radius, -11.0 + sin(angle) * radius * 0.7))
        draw_polyline(points, Color(0.95, 0.66, 0.40, alpha) if slash_heavy else Color(0.78, 0.83, 0.77, alpha), 2.0, false)
    if dash_remaining > 0.0:
        var alpha := dash_remaining / 0.22
        for i in range(3):
            draw_rect(Rect2(-16.0 - i * 7.0, -16.0 + i * 4.0, 6.0, 2.0), Color(0.56, 0.72, 0.70, alpha * (0.65 - i * 0.15)))
    if landing_remaining > 0.0:
        var alpha := landing_remaining / 0.12
        draw_rect(Rect2(-13, 11, 4, 2), Color(0.48, 0.52, 0.45, alpha))
        draw_rect(Rect2(10, 12, 3, 2), Color(0.48, 0.52, 0.45, alpha))


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
    if kind not in [&"slash", &"heavy", &"charged"]:
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
