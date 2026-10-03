class_name CorvoFlight
extends Node

@onready var bird: CharacterBody2D = get_parent() as CharacterBody2D
@onready var tuning: CorvoTuning = $"../Brain".tuning

var desired_position := Vector2.ZERO
var current_speed := 0.0
var forced_velocity := Vector2.ZERO
var controlled := true
var falling := false


func _ready() -> void:
    desired_position = bird.global_position
    current_speed = tuning.flight_speed


func seek(position: Vector2, max_speed := -1.0) -> void:
    controlled = true
    falling = false
    current_speed = tuning.flight_speed if max_speed < 0.0 else max_speed
    desired_position = Vector2(position.x, clampf(position.y, tuning.min_flight_y, tuning.max_flight_y))


func commit(velocity: Vector2) -> void:
    controlled = false
    falling = false
    forced_velocity = velocity


func fall() -> void:
    controlled = false
    falling = true
    bird.velocity.x *= 0.5
    bird.velocity.y = maxf(0.0, bird.velocity.y)


func stop() -> void:
    controlled = false
    falling = false
    forced_velocity = Vector2.ZERO
    bird.velocity = Vector2.ZERO


func tick(delta: float) -> void:
    if falling:
        bird.velocity.x = move_toward(bird.velocity.x, 0.0, tuning.flight_brake * delta)
        bird.velocity.y += tuning.fall_gravity * delta
    elif controlled:
        var offset := desired_position - bird.global_position
        var target_velocity := offset.limit_length(current_speed)
        var rate := tuning.flight_acceleration if target_velocity.length() > bird.velocity.length() else tuning.flight_brake
        bird.velocity = bird.velocity.move_toward(target_velocity, rate * delta)
    else:
        bird.velocity = forced_velocity
    bird.get_node("SensacaoAlvo").apply_recoil(delta)
    bird.move_and_slide()
    if controlled and (bird.is_on_wall() or bird.is_on_floor() or bird.is_on_ceiling()):
        bird.velocity = bird.velocity.move_toward(Vector2.ZERO, tuning.flight_brake * delta)


func reset_flight() -> void:
    bird.velocity = Vector2.ZERO
    seek(bird.global_position)
