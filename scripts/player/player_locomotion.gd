class_name PlayerLocomotion
extends Node

## P40 phase 1: Carrasco runs at 160 world units/s with its existing 0.92 mask.
const P40_MOVEMENT_SCALE := (160.0 / 0.92) / 120.0
@export var run_speed := 160.0 / 0.92
@export_range(0.1, 1.0, 0.05) var walk_speed_ratio := 0.55
@export var ground_acceleration := 900.0 * P40_MOVEMENT_SCALE
@export var ground_deceleration := 1100.0 * P40_MOVEMENT_SCALE
@export var air_acceleration := 650.0 * P40_MOVEMENT_SCALE
@export var gravity := 800.0
@export var jump_velocity := -260.0
@export var coyote_seconds := 0.10
@export var jump_buffer_seconds := 0.12

var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0


func reset_assists() -> void:
    coyote_remaining = 0.0
    jump_buffer_remaining = 0.0


func move(body: CharacterBody2D, direction: float, jump_pressed: bool, delta: float, suspend_gravity := false, walk_requested := false, jump_allowed := true, horizontal_speed_override := -1.0) -> void:
    coyote_remaining = coyote_seconds if body.is_on_floor() else maxf(0.0, coyote_remaining - delta)
    jump_buffer_remaining = jump_buffer_seconds if jump_pressed else maxf(0.0, jump_buffer_remaining - delta)
    var horizontal_rate := air_acceleration
    if suspend_gravity:
        body.velocity.y = 0.0
    elif body.is_on_floor():
        horizontal_rate = ground_acceleration if not is_zero_approx(direction) else ground_deceleration
    else:
        body.velocity.y += gravity * delta

    if jump_allowed and not suspend_gravity and jump_buffer_remaining > 0.0 and coyote_remaining > 0.0:
        body.velocity.y = jump_velocity
        jump_buffer_remaining = 0.0
        coyote_remaining = 0.0

    # Absolute dash speed must not depend on the mask, walking or a zero run speed.
    var target_speed := horizontal_speed_override if horizontal_speed_override >= 0.0 else run_speed * (walk_speed_ratio if walk_requested else 1.0)
    body.velocity.x = move_toward(body.velocity.x, direction * target_speed, horizontal_rate * delta)
    body.move_and_slide()
    if body.is_on_floor() and jump_allowed and jump_buffer_remaining > 0.0 and not suspend_gravity:
        body.velocity.y = jump_velocity
        jump_buffer_remaining = 0.0
        coyote_remaining = 0.0
