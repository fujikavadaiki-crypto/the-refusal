class_name ExecutionTargeting
extends Area2D

## Short-range candidates from existing Hurtboxes. No persistent lock-on target.
@onready var reach_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
    var circle := reach_shape.shape as CircleShape2D
    circle.radius = ExecutionResolver.INTERACTION_DISTANCE


func best_target(state: CarrascoRuntimeState, player: Node2D) -> Node2D:
    if state == null:
        return null
    var best: Node2D
    var best_distance := INF
    var best_in_front := false
    var facing: int = player.get("facing_direction")
    for area in get_overlapping_areas():
        if not area is Hurtbox2D:
            continue
        var receiver: HealthComponent = area.receiver
        if receiver == null:
            continue
        var candidate := receiver.get_parent() as Node2D
        if candidate == null or candidate == player or not ExecutionResolver.is_eligible(state, candidate):
            continue
        if not ExecutionResolver.can_reach(player, candidate):
            continue
        var distance := player.global_position.distance_squared_to(candidate.global_position)
        var in_front := (candidate.global_position.x - player.global_position.x) * facing >= 0.0
        if distance < best_distance - 0.01 or (absf(distance - best_distance) <= 0.01 and in_front and not best_in_front):
            best = candidate
            best_distance = distance
            best_in_front = in_front
    return best
