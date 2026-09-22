class_name PlayerLocomotion
extends Node

## Reversible sandbox tuning; no canonical movement values are specified yet.
@export var run_speed := 120.0
@export var ground_acceleration := 900.0
@export var ground_deceleration := 1100.0
@export var air_acceleration := 650.0
@export var gravity := 800.0
@export var jump_velocity := -260.0


func move(body: CharacterBody2D, direction: float, jump_pressed: bool, delta: float) -> void:
    var horizontal_rate := air_acceleration
    if body.is_on_floor():
        horizontal_rate = ground_acceleration if not is_zero_approx(direction) else ground_deceleration
        if jump_pressed:
            body.velocity.y = jump_velocity
    else:
        body.velocity.y += gravity * delta

    body.velocity.x = move_toward(body.velocity.x, direction * run_speed, horizontal_rate * delta)
    body.move_and_slide()
