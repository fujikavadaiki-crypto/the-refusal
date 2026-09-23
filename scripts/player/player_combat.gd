class_name PlayerCombat
extends Node

signal attack_started(attack: AttackData, action_uid: int)
signal attack_finished(attack: AttackData)
signal hit_confirmed(context: HitContext)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

@export var light_1: AttackData
@export var light_2: AttackData
@export var light_3: AttackData
@export var heavy: AttackData
@export var dash_light: AttackData
@export var air_light: AttackData
@export var air_heavy: AttackData

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var attacker_posture: PostureComponent = $"../Posture"
@onready var attacker_stats: DefenseStats = $"../DefenseStats"
@onready var pivot: Node2D = $"../AttackPivot"
@onready var hitbox: Hitbox2D = $"../AttackPivot/Hitbox"
@onready var blade: Polygon2D = $"../AttackPivot/SwordBlade"
@onready var active_marker: Polygon2D = $"../AttackPivot/ActiveMarker"
@onready var masks: MaskController = $"../MaskController"

var phase := Phase.IDLE
var current_attack: AttackData
var current_light_stage := 0
var action_uid := 0
var elapsed := 0.0
var queued_next := false
var combo_next_stage := 1
var combo_wait_remaining := 0.0
var confirmed_hit_count := 0
var facing_direction := 1


func _ready() -> void:
    pivot.rotation_degrees = 55.0
    active_marker.visible = false
    hitbox.hit_confirmed.connect(_on_hit_confirmed)
    hitbox.before_hit.connect(masks.prepare_hit)


func set_facing(direction: int) -> void:
    facing_direction = direction
    pivot.scale.x = direction
    pivot.position.x = 5.0 * direction
    if not is_busy():
        pivot.rotation_degrees = 55.0 * direction


func is_busy() -> bool:
    return phase != Phase.IDLE


func movement_multiplier() -> float:
    return current_attack.movement_multiplier if is_busy() else 1.0


func abort_attack() -> void:
    if is_busy():
        hitbox.disarm()
        active_marker.visible = false
        pivot.rotation_degrees = 55.0 * facing_direction
    phase = Phase.IDLE
    current_attack = null
    current_light_stage = 0
    queued_next = false
    combo_next_stage = 1
    combo_wait_remaining = 0.0


func accept_inputs(light_pressed: bool, heavy_pressed: bool, dash_mode := -1) -> bool:
    if is_busy():
        if light_pressed and current_light_stage > 0 and current_light_stage < 3:
            if elapsed >= current_attack.combo_queue_start_seconds and elapsed <= current_attack.total_seconds():
                queued_next = true
        return false
    var mask := masks.active_data()
    if dash_mode == PlayerDefense.Mode.DODGING:
        if heavy_pressed:
            _begin(mask.heavy if mask != null else heavy, 0)
        elif light_pressed:
            _begin(mask.post_dodge if mask != null else dash_light, 0)
        else:
            return false
    elif dash_mode == PlayerDefense.Mode.AIR_DASH or not player.is_on_floor():
        if heavy_pressed:
            _begin(mask.air_heavy if mask != null else air_heavy, 0)
        elif light_pressed:
            _begin(mask.air_light if mask != null else air_light, 0)
        else:
            return false
    elif heavy_pressed:
        _begin(mask.heavy if mask != null else heavy, 0)
    elif light_pressed:
        var stage := combo_next_stage if combo_wait_remaining > 0.0 else 1
        _begin(_light_data(stage), stage)
    else:
        return false
    return true


func start_special(attack: AttackData) -> bool:
    if is_busy() or attack == null:
        return false
    _begin(attack, 0)
    return true


func reset_combo() -> void:
    combo_next_stage = 1
    combo_wait_remaining = 0.0
    queued_next = false


func tick(delta: float) -> void:
    if not is_busy():
        combo_wait_remaining = maxf(0.0, combo_wait_remaining - delta)
        if is_zero_approx(combo_wait_remaining):
            combo_next_stage = 1
        return

    elapsed += delta
    var active_start := current_attack.windup_seconds
    var active_end := active_start + current_attack.active_seconds
    var total := current_attack.total_seconds()
    if elapsed < active_start:
        phase = Phase.WINDUP
        pivot.rotation_degrees = lerpf(55.0, current_attack.start_angle_degrees, elapsed / active_start) * facing_direction
    elif elapsed < active_end:
        if phase != Phase.ACTIVE:
            phase = Phase.ACTIVE
            _arm_hitbox()
        var progress := (elapsed - active_start) / current_attack.active_seconds
        pivot.rotation_degrees = lerpf(current_attack.start_angle_degrees, current_attack.end_angle_degrees, progress) * facing_direction
        hitbox.scan_overlaps()
    elif elapsed < total:
        if phase == Phase.ACTIVE:
            hitbox.disarm()
            active_marker.visible = false
        phase = Phase.RECOVERY
        var progress := (elapsed - active_end) / current_attack.recovery_seconds
        pivot.rotation_degrees = lerpf(current_attack.end_angle_degrees, 55.0, progress) * facing_direction
    else:
        _finish()


func _light_data(stage: int) -> AttackData:
    var mask := masks.active_data()
    match stage:
        2:
            return mask.light_2 if mask != null else light_2
        3:
            return mask.light_3 if mask != null else light_3
        _:
            return mask.light_1 if mask != null else light_1


func _begin(attack: AttackData, stage: int) -> void:
    current_attack = attack
    current_light_stage = stage
    action_uid = HitContext.allocate_action_id()
    elapsed = 0.0
    queued_next = false
    combo_wait_remaining = 0.0
    phase = Phase.WINDUP
    pivot.rotation_degrees = 55.0 * facing_direction
    match attack.attack_id:
        &"air_light":
            blade.color = Color(0.58, 0.84, 0.85, 1)
        &"air_heavy":
            blade.color = Color(0.91, 0.75, 0.49, 1)
        &"dash_light":
            blade.color = Color(0.65, 0.79, 0.93, 1)
        _:
            blade.color = Color(0.8, 0.79, 0.72, 1) if stage == 0 else Color(0.62, 0.66, 0.64, 1)
    attack_started.emit(attack, action_uid)


func _arm_hitbox() -> void:
    var context := HitContext.new()
    context.attacker = player
    context.attacker_posture = attacker_posture
    context.attacker_stats = attacker_stats
    context.attack_id = current_attack.attack_id
    context.action_uid = action_uid
    context.base_damage = current_attack.base_damage
    context.posture_damage = current_attack.posture_damage
    context.parry_class = current_attack.parry_class
    context.damage_type = current_attack.damage_type
    context.tags = current_attack.tags.duplicate()
    hitbox.arm(context, current_attack)
    active_marker.visible = true
    if current_attack == dash_light or current_attack == air_light or current_attack == air_heavy:
        active_marker.color = Color(blade.color.r, blade.color.g, blade.color.b, 0.55)
    else:
        active_marker.color = Color(0.85, 0.77, 0.55, 0.55) if current_light_stage == 0 else Color(0.64, 0.75, 0.7, 0.45)


func _finish() -> void:
    hitbox.disarm()
    active_marker.visible = false
    pivot.rotation_degrees = 55.0 * facing_direction
    var finished_attack := current_attack
    var finished_stage := current_light_stage
    var play_next := queued_next and finished_stage > 0 and finished_stage < 3
    current_attack = null
    current_light_stage = 0
    phase = Phase.IDLE
    attack_finished.emit(finished_attack)
    if play_next:
        _begin(_light_data(finished_stage + 1), finished_stage + 1)
    elif finished_stage > 0 and finished_stage < 3:
        combo_next_stage = finished_stage + 1
        combo_wait_remaining = finished_attack.combo_wait_seconds
    else:
        combo_next_stage = 1
        combo_wait_remaining = 0.0


func _on_hit_confirmed(context: HitContext) -> void:
    if context.outcome != HitContext.Outcome.DAMAGED and context.outcome != HitContext.Outcome.DEAD and context.outcome != HitContext.Outcome.CONTACT:
        return
    confirmed_hit_count += 1
    masks.on_hit(context)
    hit_confirmed.emit(context)
    if context.outcome != HitContext.Outcome.CONTACT:
        get_node("/root/HitStop").request_ms(current_attack.hit_stop_ms)
