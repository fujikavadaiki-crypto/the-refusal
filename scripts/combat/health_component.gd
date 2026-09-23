class_name HealthComponent
extends Node

signal damage_taken(context: HitContext)
signal contact_avoided(context: HitContext)
signal depleted
signal reset_done

@export var max_health := 500
@export var posture_path: NodePath
@export var stats_path: NodePath
@export var guard_path: NodePath
@onready var posture: PostureComponent = get_node_or_null(posture_path) as PostureComponent
@onready var stats: DefenseStats = get_node_or_null(stats_path) as DefenseStats
@onready var guard: Node = get_node_or_null(guard_path)
var current_health: int


func _ready() -> void:
    current_health = max_health


func receive_hit(context: HitContext) -> bool:
    if current_health <= 0 or (context.base_damage <= 0 and context.posture_damage <= 0):
        return false
    if guard != null and guard.has_method("try_defend") and guard.try_defend(context):
        contact_avoided.emit(context)
        return true
    var resolved_health := DamageResolver.health_amount(context, stats, posture)
    var resolved_posture := DamageResolver.posture_amount(context, stats)
    context.actual_damage = mini(resolved_health, current_health)
    current_health -= context.actual_damage
    var lethal := current_health <= 0
    if posture != null:
        context.actual_posture_damage = posture.receive_damage(resolved_posture, not lethal)
    context.outcome = HitContext.Outcome.DEAD if lethal else HitContext.Outcome.DAMAGED
    damage_taken.emit(context)
    if lethal:
        depleted.emit()
    return true


func reset_health() -> void:
    current_health = max_health
    reset_done.emit()
