class_name PlayerLocomotion
extends Node

## P40 phase 1: Carrasco runs at 160 world units/s with its existing 0.92 mask.
const P40_MOVEMENT_SCALE := (160.0 / 0.92) / 120.0
@export var run_speed := 160.0 / 0.92
@export_range(0.1, 1.0, 0.05) var walk_speed_ratio := 0.55
@export var ground_acceleration := 900.0 * P40_MOVEMENT_SCALE
@export var ground_deceleration := 1100.0 * P40_MOVEMENT_SCALE
@export var air_acceleration := 650.0 * P40_MOVEMENT_SCALE
## P40 played jump: nominal 2.20 m / 325 ms, measured ~2.32 m at 60 Hz.
## Fixed reference conversion; never recompute physics from a room's camera zoom.
const P40_UNITS_PER_METER := 32.0 / 0.9
const P40_JUMP_HEIGHT := 2.2 * P40_UNITS_PER_METER
const P40_APEX_SECONDS := 0.325
@export var gravity := 2.0 * P40_JUMP_HEIGHT / (P40_APEX_SECONDS * P40_APEX_SECONDS)
@export var jump_velocity := -2.0 * P40_JUMP_HEIGHT / P40_APEX_SECONDS
@export var coyote_seconds := 0.10
@export var jump_buffer_seconds := 0.10

var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var jump_origin_y := 0.0
var jump_in_progress := false
var jump_cut_applied := false


func reset_assists() -> void:
    coyote_remaining = 0.0
    jump_buffer_remaining = 0.0
    jump_in_progress = false
    jump_cut_applied = false


func move(body: CharacterBody2D, direction: float, jump_pressed: bool, delta: float, suspend_gravity := false, walk_requested := false, jump_allowed := true, horizontal_speed_override := -1.0, jump_held := true) -> void:
    var feel := get_node("/root/Sensacao")
    var assists: bool = feel.enabled("controle")
    coyote_seconds = feel.value("controle", "coyote_ms") / 1000.0
    jump_buffer_seconds = feel.value("controle", "buffer_pulo_ms") / 1000.0
    coyote_remaining = coyote_seconds if assists and body.is_on_floor() and not jump_in_progress else maxf(0.0, coyote_remaining - delta)
    jump_buffer_remaining = jump_buffer_seconds if assists and jump_pressed else maxf(0.0, jump_buffer_remaining - delta)
    if not assists:
        coyote_remaining = 0.0
        jump_buffer_remaining = 0.0
    var horizontal_rate := air_acceleration
    if suspend_gravity:
        body.velocity.y = 0.0
    elif body.is_on_floor():
        horizontal_rate = ground_acceleration if not is_zero_approx(direction) else ground_deceleration
    else:
        body.velocity.y += gravity * delta

    var assisted_jump := assists and jump_buffer_remaining > 0.0 and coyote_remaining > 0.0
    if jump_allowed and not suspend_gravity and (assisted_jump or (not assists and jump_pressed and body.is_on_floor())):
        _begin_jump(body)
    if assists and not suspend_gravity and jump_in_progress and not jump_held and not jump_cut_applied and body.velocity.y < 0:
        var remaining := maxf(0, feel.value("controle", "pulo_minimo_m") * P40_UNITS_PER_METER - maxf(0, jump_origin_y - body.global_position.y))
        var half_step := gravity * delta * .5
        var limit := sqrt(2 * gravity * remaining + half_step * half_step) - half_step
        body.velocity.y = maxf(body.velocity.y, -limit)
        jump_cut_applied = true

    # Absolute dash speed must not depend on the mask, walking or a zero run speed.
    var target_speed := horizontal_speed_override if horizontal_speed_override >= 0.0 else run_speed * (walk_speed_ratio if walk_requested else 1.0)
    body.velocity.x = move_toward(body.velocity.x, direction * target_speed, horizontal_rate * delta)
    if body.has_node("SensacaoAlvo"): body.get_node("SensacaoAlvo").apply_recoil(delta)
    body.move_and_slide()
    if body.is_on_floor(): jump_in_progress = false
    if body.is_on_floor() and jump_allowed and jump_buffer_remaining > 0.0 and not suspend_gravity:
        _begin_jump(body)

func _begin_jump(body: CharacterBody2D) -> void:
    body.velocity.y = jump_velocity
    jump_origin_y = body.global_position.y
    jump_in_progress = true
    jump_cut_applied = false
    jump_buffer_remaining = 0.0
    coyote_remaining = 0.0
