class_name PeregrinoBrain
extends Node

enum State { IDLE, PATROL, ALERT, CHASE, ATTACK_WINDUP, ATTACK_ACTIVE, ATTACK_RECOVERY, HURT, RUPTURE, DEATH }

@export var tuning: PeregrinoTuning
@export var player_path: NodePath = NodePath("../../TestRoom/Player")

@onready var enemy: CharacterBody2D = get_parent() as CharacterBody2D
@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D
@onready var attack: PeregrinoAttack = $"../Attack"
@onready var health: HealthComponent = $"../Health"
@onready var edge_probe: RayCast2D = $"../EdgeProbe"

var state := State.IDLE
var elapsed := 0.0
var home_x := 0.0
var patrol_direction := 1
var cooldown := 0.0
var move_axis := 0.0
var attack_index := 0


func _ready() -> void:
    home_x = enemy.global_position.x
    attack.phase_changed.connect(_on_attack_phase)
    attack.attack_finished.connect(_on_attack_finished)


func tick(delta: float) -> void:
    elapsed += delta
    cooldown = maxf(0.0, cooldown - delta)
    move_axis = 0.0
    match state:
        State.IDLE:
            if _can_perceive():
                _set_state(State.ALERT)
            elif elapsed >= tuning.idle_seconds:
                _set_state(State.PATROL)
        State.PATROL:
            if _can_perceive():
                _set_state(State.ALERT)
            else:
                if absf(enemy.global_position.x - home_x) >= tuning.patrol_half_width:
                    patrol_direction = -1 if enemy.global_position.x > home_x else 1
                enemy.set_facing(patrol_direction)
                move_axis = patrol_direction * tuning.patrol_speed
        State.ALERT:
            _face_player()
            if elapsed >= tuning.alert_seconds:
                _set_state(State.CHASE if _target_valid() else State.PATROL)
        State.CHASE:
            if not _target_valid() or absf(player.global_position.x - home_x) > tuning.disengage_range:
                _set_state(State.PATROL)
            else:
                var dx := player.global_position.x - enemy.global_position.x
                _face_player()
                if absf(dx) <= tuning.attack_distance + tuning.attack_tolerance and absf(player.global_position.y - enemy.global_position.y) <= tuning.perception_height:
                    if cooldown <= 0.0:
                        _begin_attack()
                elif absf(dx) > tuning.attack_distance + tuning.attack_tolerance:
                    move_axis = (-1.0 if dx < 0.0 else 1.0) * tuning.chase_speed * _aggression()
        State.ATTACK_ACTIVE:
            if attack.current_attack != null and attack.current_attack.attack_id == &"peregrino_investida":
                move_axis = enemy.facing_direction * tuning.investida_speed
        State.HURT:
            if elapsed >= tuning.hurt_seconds:
                _set_state(State.CHASE if _target_valid() else State.PATROL)
        State.ATTACK_WINDUP, State.ATTACK_RECOVERY, State.RUPTURE, State.DEATH:
            pass
    if not is_zero_approx(move_axis) and not _ground_ahead(-1 if move_axis < 0.0 else 1):
        move_axis = 0.0


func on_damage(context: HitContext) -> void:
    if context.outcome == HitContext.Outcome.DEAD or state == State.DEATH or state == State.RUPTURE:
        return
    if state in [State.IDLE, State.PATROL, State.ALERT, State.CHASE]:
        _set_state(State.HURT)


func on_rupture() -> void:
    if state != State.DEATH:
        attack.abort()
        _set_state(State.RUPTURE)


func on_recovered() -> void:
    if state == State.RUPTURE:
        _set_state(State.CHASE if _target_valid() else State.PATROL)


func on_death() -> void:
    attack.abort()
    _set_state(State.DEATH)


func reset_brain() -> void:
    attack.abort()
    home_x = enemy.global_position.x
    patrol_direction = 1
    cooldown = 0.0
    move_axis = 0.0
    attack_index = 0
    _set_state(State.IDLE)


func _can_perceive() -> bool:
    if not _target_valid():
        return false
    var offset := player.global_position - enemy.global_position
    if absf(offset.x) > tuning.perception_range or absf(offset.y) > tuning.perception_height:
        return false
    var query := PhysicsRayQueryParameters2D.create(enemy.global_position + Vector2(0, -7), player.global_position + Vector2(0, -7), 1)
    query.exclude = [enemy.get_rid()]
    return enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _target_valid() -> bool:
    return is_instance_valid(player) and player.get_node("Health").current_health > 0


func _face_player() -> void:
    if _target_valid():
        var dx := player.global_position.x - enemy.global_position.x
        if absf(dx) > tuning.facing_deadzone:
            enemy.set_facing(-1 if dx < 0.0 else 1)


func _ground_ahead(direction: int) -> bool:
    edge_probe.target_position = Vector2(tuning.edge_probe_forward * direction, tuning.edge_probe_down)
    edge_probe.force_raycast_update()
    return edge_probe.is_colliding()


func _aggression() -> float:
    return 1.15 if health.current_health < health.max_health * 0.30 else 1.0


func _begin_attack() -> void:
    var choices: Array[AttackData] = [attack.corte, attack.estocada, attack.corte_duplo_1, attack.investida, attack.penitencia]
    var selected := choices[attack_index % choices.size()]
    attack_index += 1
    var second: AttackData = attack.corte_duplo_2 if selected == attack.corte_duplo_1 else null
    attack.start(selected, second)


func _on_attack_phase(phase: int) -> void:
    if state == State.DEATH or state == State.RUPTURE:
        return
    match phase:
        PeregrinoAttack.Phase.WINDUP:
            _set_state(State.ATTACK_WINDUP)
        PeregrinoAttack.Phase.ACTIVE:
            _set_state(State.ATTACK_ACTIVE)
        PeregrinoAttack.Phase.RECOVERY:
            _set_state(State.ATTACK_RECOVERY)


func _on_attack_finished() -> void:
    if state == State.DEATH or state == State.RUPTURE:
        return
    cooldown = tuning.attack_cooldown_seconds / _aggression()
    _set_state(State.CHASE if _target_valid() else State.PATROL)


func _set_state(next: State) -> void:
    if state != next:
        state = next
        elapsed = 0.0
