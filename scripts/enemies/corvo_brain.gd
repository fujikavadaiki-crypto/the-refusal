class_name CorvoBrain
extends Node

enum State { HOVER, PATROL_AIR, ALERT, POSITIONING, DIVE_WINDUP, DIVE_ACTIVE, DIVE_RECOVERY, PROJECTILE_WINDUP, PROJECTILE_ATTACK, PROJECTILE_RECOVERY, HURT, RUPTURE, TAKEOFF, DEATH }

@export var tuning: CorvoTuning
@export var player_path: NodePath = NodePath("../../TestRoom/Player")

@onready var bird: CharacterBody2D = get_parent() as CharacterBody2D
@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var flight: CorvoFlight = $"../Flight"
@onready var attack: CorvoAttack = $"../Attack"

var state := State.HOVER
var elapsed := 0.0
var home := Vector2.ZERO
var patrol_direction := -1
var cooldown := 0.0
var last_move := CorvoAttack.Mode.NONE
var attack_count := 0
var planned_move := CorvoAttack.Mode.NONE
var choice_rng := RandomNumberGenerator.new()


func _ready() -> void:
    home = bird.global_position
    choice_rng.seed = int(home.x * 101.0 + home.y * 17.0)
    attack.state_requested.connect(_set_state)
    attack.finished.connect(_on_attack_finished)


func tick(delta: float) -> void:
    elapsed += delta
    cooldown = maxf(0.0, cooldown - delta)
    match state:
        State.HOVER:
            flight.seek(home + Vector2(0, sin(elapsed * tuning.hover_frequency) * tuning.hover_amplitude))
            if _can_detect():
                _set_state(State.ALERT)
            elif elapsed >= tuning.idle_seconds:
                _set_state(State.PATROL_AIR)
        State.PATROL_AIR:
            if _can_detect():
                _set_state(State.ALERT)
            else:
                if absf(bird.global_position.x - home.x) >= tuning.patrol_half_width:
                    patrol_direction = -1 if bird.global_position.x > home.x else 1
                flight.seek(Vector2(home.x + patrol_direction * tuning.patrol_half_width, home.y + sin(elapsed * tuning.patrol_bob_frequency) * tuning.patrol_bob_amplitude), tuning.patrol_speed)
        State.ALERT:
            _face_player()
            flight.seek(bird.global_position)
            if elapsed >= tuning.alert_seconds:
                _set_state(State.POSITIONING if _target_valid() else State.PATROL_AIR)
        State.POSITIONING:
            if not _target_valid() or absf(player.global_position.x - home.x) > tuning.disengage_range:
                _set_state(State.PATROL_AIR)
            else:
                _face_player()
                var dx := player.global_position.x - bird.global_position.x
                var distance := absf(dx)
                var side := -1.0 if dx < 0.0 else 1.0
                if planned_move == CorvoAttack.Mode.NONE:
                    planned_move = _choose_move(distance)
                var choose_dive := planned_move == CorvoAttack.Mode.DIVE
                var ideal_distance := tuning.preferred_dive_distance if choose_dive else tuning.preferred_projectile_distance
                var ideal_height := tuning.prepare_height_above_player if choose_dive else tuning.safe_height_above_player
                var destination := Vector2(player.global_position.x - side * ideal_distance, player.global_position.y - ideal_height)
                flight.seek(destination)
                if cooldown <= 0.0 and elapsed >= tuning.reposition_seconds and distance >= tuning.dive_min_distance and absf(distance - ideal_distance) <= tuning.position_tolerance and absf(bird.global_position.y - destination.y) <= tuning.vertical_position_tolerance:
                    if choose_dive:
                        attack.begin_dive()
                    elif distance >= tuning.projectile_min_distance:
                        attack.begin_projectile()
        State.HURT:
            flight.seek(bird.global_position)
            if elapsed >= tuning.hurt_seconds:
                _set_state(State.POSITIONING if _target_valid() else State.PATROL_AIR)
        State.TAKEOFF:
            var target := Vector2(bird.global_position.x, clampf(home.y, tuning.min_flight_y, tuning.max_flight_y))
            flight.seek(target)
            if absf(bird.global_position.y - target.y) <= 8.0:
                _set_state(State.POSITIONING if _target_valid() else State.PATROL_AIR)
        State.DIVE_WINDUP, State.DIVE_ACTIVE, State.DIVE_RECOVERY, State.PROJECTILE_WINDUP, State.PROJECTILE_ATTACK, State.PROJECTILE_RECOVERY, State.RUPTURE, State.DEATH:
            pass


func on_damage(context: HitContext) -> void:
    if context.outcome == HitContext.Outcome.DEAD or state == State.DEATH or state == State.RUPTURE:
        return
    if state in [State.HOVER, State.PATROL_AIR, State.ALERT, State.POSITIONING]:
        _set_state(State.HURT)


func on_rupture() -> void:
    if state != State.DEATH:
        attack.abort()
        flight.fall()
        _set_state(State.RUPTURE)


func on_recovered() -> void:
    if state == State.RUPTURE:
        _set_state(State.TAKEOFF)


func on_death() -> void:
    attack.abort()
    flight.fall()
    _set_state(State.DEATH)


func reset_brain() -> void:
    attack.abort()
    home = bird.global_position
    patrol_direction = -1
    cooldown = 0.0
    last_move = CorvoAttack.Mode.NONE
    attack_count = 0
    planned_move = CorvoAttack.Mode.NONE
    choice_rng.seed = int(home.x * 101.0 + home.y * 17.0)
    _set_state(State.HOVER)


func _target_valid() -> bool:
    return is_instance_valid(player) and player.get_node("Health").current_health > 0


func _can_detect() -> bool:
    if not _target_valid() or bird.global_position.distance_to(player.global_position) > tuning.perception_range:
        return false
    var query := PhysicsRayQueryParameters2D.create(bird.global_position, player.global_position + Vector2(0, -5), 1)
    query.exclude = [bird.get_rid()]
    return bird.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _face_player() -> void:
    if _target_valid():
        var dx := player.global_position.x - bird.global_position.x
        if absf(dx) > tuning.facing_deadzone:
            bird.set_facing(-1 if dx < 0.0 else 1)


func _on_attack_finished() -> void:
    if state == State.DEATH or state == State.RUPTURE:
        return
    last_move = CorvoAttack.Mode.DIVE if state == State.DIVE_RECOVERY else CorvoAttack.Mode.PROJECTILE
    attack_count += 1
    cooldown = tuning.attack_cooldown_seconds + (tuning.third_action_extra_cooldown if attack_count % 3 == 0 else 0.0)
    _set_state(State.POSITIONING if _target_valid() else State.PATROL_AIR)


func _choose_move(distance: float) -> int:
    if distance < tuning.projectile_min_distance:
        return CorvoAttack.Mode.DIVE
    if distance > tuning.dive_max_distance:
        return CorvoAttack.Mode.PROJECTILE
    # Position and range select viable moves; bounded randomness only breaks ties.
    var dive_probability := tuning.dive_after_projectile_probability if last_move == CorvoAttack.Mode.PROJECTILE else tuning.dive_otherwise_probability
    return CorvoAttack.Mode.DIVE if choice_rng.randf() < dive_probability else CorvoAttack.Mode.PROJECTILE


func _set_state(next: int) -> void:
    if state != next:
        state = next
        elapsed = 0.0
        if next == State.POSITIONING:
            planned_move = CorvoAttack.Mode.NONE
