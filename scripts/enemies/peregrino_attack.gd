class_name PeregrinoAttack
extends Node

signal phase_changed(phase: Phase)
signal attack_finished
signal hit_confirmed(context: HitContext)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

@export var corte: AttackData
@export var estocada: AttackData
@export var investida: AttackData
@export var corte_duplo_1: AttackData
@export var corte_duplo_2: AttackData
@export var penitencia: AttackData

@onready var enemy: CharacterBody2D = get_parent() as CharacterBody2D
@onready var pivot: Node2D = $"../AttackPivot"
@onready var hitbox: Hitbox2D = $"../AttackPivot/Hitbox"
@onready var telegraph: Polygon2D = $"../AttackPivot/Telegraph"
@onready var posture: PostureComponent = $"../Posture"
@onready var stats: DefenseStats = $"../DefenseStats"

var phase := Phase.IDLE
var current_attack: AttackData
var followup: AttackData
var elapsed := 0.0
var action_uid := 0
var facing_locked := false


func _ready() -> void:
    telegraph.visible = false
    hitbox.hit_confirmed.connect(_on_hit_confirmed)


func start(attack: AttackData, second: AttackData = null) -> bool:
    if phase != Phase.IDLE or attack == null:
        return false
    followup = second
    _begin(attack)
    return true


func _begin(attack: AttackData) -> void:
    current_attack = attack
    action_uid = HitContext.allocate_action_id()
    elapsed = 0.0
    facing_locked = false
    phase = Phase.WINDUP
    telegraph.visible = true
    telegraph.color = Color(0.91, 0.27, 0.19, 0.9) if attack.parry_class != &"parryable" else Color(0.8, 0.88, 0.61, 0.82)
    phase_changed.emit(phase)


func tick(delta: float, player: Node2D, facing_deadzone: float) -> void:
    if phase == Phase.IDLE:
        return
    elapsed += delta
    if phase == Phase.WINDUP:
        if not facing_locked and elapsed < current_attack.windup_seconds * 0.5 and is_instance_valid(player):
            var offset := player.global_position.x - enemy.global_position.x
            if absf(offset) > facing_deadzone:
                enemy.set_facing(-1 if offset < 0.0 else 1)
        else:
            facing_locked = true
        pivot.rotation_degrees = current_attack.start_angle_degrees * enemy.facing_direction
        if elapsed >= current_attack.windup_seconds:
            phase = Phase.ACTIVE
            _arm()
            phase_changed.emit(phase)
    if phase == Phase.ACTIVE:
        var progress := clampf((elapsed - current_attack.windup_seconds) / current_attack.active_seconds, 0.0, 1.0)
        pivot.rotation_degrees = lerpf(current_attack.start_angle_degrees, current_attack.end_angle_degrees, progress) * enemy.facing_direction
        hitbox.scan_overlaps()
        if phase == Phase.ACTIVE and elapsed >= current_attack.windup_seconds + current_attack.active_seconds:
            hitbox.disarm()
            telegraph.visible = false
            phase = Phase.RECOVERY
            phase_changed.emit(phase)
    if phase == Phase.RECOVERY and elapsed >= current_attack.total_seconds():
        if followup != null:
            var next := followup
            followup = null
            _begin(next)
        else:
            abort()
            attack_finished.emit()


func abort() -> void:
    hitbox.disarm()
    telegraph.visible = false
    phase = Phase.IDLE
    current_attack = null
    followup = null
    elapsed = 0.0
    facing_locked = false
    pivot.rotation_degrees = 0.0


func _arm() -> void:
    var context := HitContext.new()
    context.attacker = enemy
    context.attacker_posture = posture
    context.attacker_stats = stats
    context.attack_id = current_attack.attack_id
    context.action_uid = action_uid
    context.base_damage = current_attack.base_damage
    context.posture_damage = current_attack.posture_damage
    context.damage_type = current_attack.damage_type
    context.parry_class = current_attack.parry_class
    context.tags = current_attack.tags.duplicate()
    hitbox.arm(context, current_attack)


func _on_hit_confirmed(context: HitContext) -> void:
    hit_confirmed.emit(context)
    if (context.outcome == HitContext.Outcome.DAMAGED or context.outcome == HitContext.Outcome.DEAD) and current_attack != null:
        get_node("/root/HitStop").request_ms(current_attack.hit_stop_ms)
