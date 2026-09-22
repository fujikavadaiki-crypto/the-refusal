class_name HealthComponent
extends Node

signal damage_taken(context: HitContext)
signal depleted
signal reset_done

@export var max_health := 500
var current_health: int


func _ready() -> void:
    current_health = max_health


func receive_hit(context: HitContext) -> bool:
    if current_health <= 0 or context.base_damage <= 0:
        return false
    context.actual_damage = mini(context.base_damage, current_health)
    current_health -= context.actual_damage
    damage_taken.emit(context)
    if current_health == 0:
        depleted.emit()
    return true


func reset_health() -> void:
    current_health = max_health
    reset_done.emit()
