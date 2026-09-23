class_name RaizFamintaBrain
extends Node

signal state_changed(state: int)

enum State { HIDDEN, DETECT, BURROW_MOVE, EMERGE_WINDUP, EMERGE_ATTACK, EMERGE_RECOVERY, GROUND_CHASE, BITE_WINDUP, BITE_ACTIVE, BITE_RECOVERY, HURT, RUPTURE, DEATH }

@export var tuning: RaizFamintaTuning
@export var player_path: NodePath = NodePath("../../TestRoom/Player")

@onready var enemy: CharacterBody2D = get_parent() as CharacterBody2D
@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var attack: RaizFamintaAttack = $"../Attack"

var state := State.HIDDEN
var elapsed := 0.0
var burrow_origin_x := 0.0
var locked_emerge_x := 0.0
var move_axis := 0.0
var bite_cooldown := 0.0
var out_of_range_seconds := 0.0


func _ready() -> void:
    burrow_origin_x = enemy.global_position.x
    attack.state_requested.connect(_set_state)
    attack.finished.connect(_on_attack_finished)


func tick(delta: float) -> void:
    elapsed += delta
    bite_cooldown = maxf(0.0, bite_cooldown - delta)
    move_axis = 0.0
    match state:
        State.HIDDEN:
            if _can_detect():
                _set_state(State.DETECT)
        State.DETECT:
            if elapsed >= tuning.detect_seconds:
                burrow_origin_x = enemy.global_position.x
                _set_state(State.BURROW_MOVE)
        State.BURROW_MOVE:
            _move_buried(delta)
        State.GROUND_CHASE:
            if not _target_valid() or absf(player.global_position.x - enemy.global_position.x) > tuning.disengage_range:
                out_of_range_seconds += delta
                if out_of_range_seconds >= tuning.reburrow_seconds:
                    _set_state(State.HIDDEN)
            else:
                out_of_range_seconds = 0.0
                var dx := player.global_position.x - enemy.global_position.x
                if absf(dx) > tuning.facing_deadzone:
                    enemy.set_facing(-1 if dx < 0.0 else 1)
                if absf(dx) > tuning.bite_distance:
                    move_axis = (-1.0 if dx < 0.0 else 1.0) * tuning.ground_chase_speed
                elif bite_cooldown <= 0.0 and absf(player.global_position.y - enemy.global_position.y) <= tuning.bite_height_tolerance:
                    attack.begin_bite()
        State.HURT:
            if elapsed >= tuning.hurt_seconds:
                _set_state(State.GROUND_CHASE)
        State.EMERGE_WINDUP, State.EMERGE_ATTACK, State.EMERGE_RECOVERY, State.BITE_WINDUP, State.BITE_ACTIVE, State.BITE_RECOVERY, State.RUPTURE, State.DEATH:
            pass


func on_damage(context: HitContext) -> void:
    if context.outcome == HitContext.Outcome.DEAD or state in [State.DEATH, State.RUPTURE]:
        return
    if state in [State.HIDDEN, State.DETECT, State.BURROW_MOVE]:
        attack.begin_emerge()
    elif state == State.GROUND_CHASE:
        _set_state(State.HURT)


func on_rupture() -> void:
    if state != State.DEATH:
        attack.abort()
        _set_state(State.RUPTURE)


func on_recovered() -> void:
    if state == State.RUPTURE:
        _set_state(State.GROUND_CHASE)


func on_death() -> void:
    attack.abort()
    move_axis = 0.0
    _set_state(State.DEATH)


func reset_brain() -> void:
    attack.abort()
    move_axis = 0.0
    elapsed = 0.0
    bite_cooldown = 0.0
    out_of_range_seconds = 0.0
    burrow_origin_x = enemy.global_position.x
    locked_emerge_x = enemy.global_position.x
    state = State.HIDDEN
    state_changed.emit(state)


func _target_valid() -> bool:
    return is_instance_valid(player) and player.get_node("Health").current_health > 0


func _can_detect() -> bool:
    if not _target_valid():
        return false
    var offset := player.global_position - enemy.global_position
    if absf(offset.x) > tuning.perception_range or absf(offset.y) > tuning.perception_height:
        return false
    var query := PhysicsRayQueryParameters2D.create(enemy.global_position + Vector2(0, -6), player.global_position + Vector2(0, -6), 1)
    query.exclude = [enemy.get_rid()]
    return enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _move_buried(delta: float) -> void:
    if not _target_valid():
        attack.begin_emerge()
        return
    var side := -1.0 if enemy.global_position.x < player.global_position.x else 1.0
    var target_x := player.global_position.x + side * tuning.burrow_target_offset
    var min_x := burrow_origin_x - tuning.burrow_max_distance
    var max_x := burrow_origin_x + tuning.burrow_max_distance
    target_x = clampf(target_x, min_x, max_x)
    var step := move_toward(enemy.global_position.x, target_x, tuning.burrow_speed * delta)
    var query := PhysicsRayQueryParameters2D.create(enemy.global_position + Vector2(0, -5), Vector2(step, enemy.global_position.y - 5), 1)
    query.exclude = [enemy.get_rid()]
    if enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
        enemy.global_position.x = step
    var reached := absf(enemy.global_position.x - target_x) <= tuning.burrow_stop_distance
    var capped := absf(enemy.global_position.x - burrow_origin_x) >= tuning.burrow_max_distance - 1.0
    if elapsed >= tuning.burrow_min_seconds and (reached or capped or elapsed >= tuning.burrow_max_seconds):
        locked_emerge_x = enemy.global_position.x
        attack.begin_emerge()


func _on_attack_finished(completed: int) -> void:
    if state in [State.DEATH, State.RUPTURE]:
        return
    if completed == RaizFamintaAttack.Mode.BITE:
        bite_cooldown = tuning.bite_cooldown_seconds
    _set_state(State.GROUND_CHASE)


func _set_state(next: int) -> void:
    if state != next:
        state = next
        elapsed = 0.0
        state_changed.emit(state)
