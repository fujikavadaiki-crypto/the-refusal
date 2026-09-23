class_name RaizFamintaAttack
extends Node

signal state_requested(state: int)
signal finished(mode: int)
signal hit_confirmed(context: HitContext)

enum Mode { NONE, EMERGE, BITE }

@export var garra_subterranea: AttackData
@export var mordida: AttackData

@onready var enemy: CharacterBody2D = get_parent() as CharacterBody2D
@onready var pivot: Node2D = $"../AttackPivot"
@onready var hitbox: Hitbox2D = $"../AttackPivot/Hitbox"
@onready var emerge_telegraph: Polygon2D = $"../EmergeTelegraph"
@onready var bite_telegraph: Polygon2D = $"../AttackPivot/BiteTelegraph"

var mode := Mode.NONE
var current_attack: AttackData
var elapsed := 0.0
var locked_position := Vector2.ZERO
var facing_locked := false


func _ready() -> void:
    emerge_telegraph.visible = false
    bite_telegraph.visible = false
    hitbox.hit_confirmed.connect(_on_hit_confirmed)


func begin_emerge() -> bool:
    if mode != Mode.NONE:
        return false
    mode = Mode.EMERGE
    current_attack = garra_subterranea
    elapsed = 0.0
    locked_position = enemy.global_position
    facing_locked = true
    emerge_telegraph.visible = true
    state_requested.emit(RaizFamintaBrain.State.EMERGE_WINDUP)
    return true


func begin_bite() -> bool:
    if mode != Mode.NONE:
        return false
    mode = Mode.BITE
    current_attack = mordida
    elapsed = 0.0
    facing_locked = false
    bite_telegraph.visible = true
    state_requested.emit(RaizFamintaBrain.State.BITE_WINDUP)
    return true


func tick(delta: float, player: Node2D) -> void:
    if mode == Mode.NONE:
        return
    elapsed += delta
    if mode == Mode.EMERGE:
        enemy.global_position.x = locked_position.x
    elif not facing_locked and elapsed < current_attack.windup_seconds * 0.5 and is_instance_valid(player):
        var dx := player.global_position.x - enemy.global_position.x
        if absf(dx) > 5.0:
            enemy.set_facing(-1 if dx < 0.0 else 1)
    else:
        facing_locked = true
    if elapsed < current_attack.windup_seconds:
        return
    if not hitbox.active and elapsed < current_attack.windup_seconds + current_attack.active_seconds:
        var context := _context(current_attack)
        hitbox.position.y = -11.0 if mode == Mode.EMERGE else -5.0
        hitbox.arm(context, current_attack)
        emerge_telegraph.visible = false
        bite_telegraph.visible = false
        state_requested.emit(RaizFamintaBrain.State.EMERGE_ATTACK if mode == Mode.EMERGE else RaizFamintaBrain.State.BITE_ACTIVE)
    if hitbox.active:
        hitbox.scan_overlaps()
    if elapsed >= current_attack.windup_seconds + current_attack.active_seconds and hitbox.active:
        hitbox.disarm()
        state_requested.emit(RaizFamintaBrain.State.EMERGE_RECOVERY if mode == Mode.EMERGE else RaizFamintaBrain.State.BITE_RECOVERY)
    if elapsed >= current_attack.total_seconds():
        var completed := mode
        abort()
        finished.emit(completed)


func abort() -> void:
    hitbox.disarm()
    emerge_telegraph.visible = false
    bite_telegraph.visible = false
    mode = Mode.NONE
    current_attack = null
    elapsed = 0.0
    facing_locked = false


func _context(data: AttackData) -> HitContext:
    var context := HitContext.new()
    context.attacker = enemy
    context.attacker_posture = enemy.get_node("Posture") as PostureComponent
    context.attacker_stats = enemy.get_node("DefenseStats") as DefenseStats
    context.attack_id = data.attack_id
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = data.base_damage
    context.posture_damage = data.posture_damage
    context.damage_type = data.damage_type
    context.parry_class = data.parry_class
    context.tags = data.tags.duplicate()
    return context


func _on_hit_confirmed(context: HitContext) -> void:
    hit_confirmed.emit(context)
    if current_attack != null and context.outcome in [HitContext.Outcome.DAMAGED, HitContext.Outcome.DEAD]:
        get_node("/root/HitStop").request_ms(current_attack.hit_stop_ms)
