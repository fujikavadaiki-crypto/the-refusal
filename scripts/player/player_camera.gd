class_name PlayerCamera
extends Camera2D

## Small reversible look-ahead; the room limits keep the visible area inside the sandbox.
@export var look_ahead_pixels := 60.0
@export var shift_speed := 240.0
@export var impact_shake_enabled := false

var shake_remaining := 0.0
var shake_strength := 0.0


func _process(delta: float) -> void:
    if not impact_shake_enabled or shake_remaining <= 0.0:
        offset = Vector2.ZERO
        return
    shake_remaining = maxf(0.0, shake_remaining - delta)
    var fade := shake_remaining / 0.14
    var time := Time.get_ticks_msec() * 0.001
    offset = Vector2(roundf(sin(time * 73.0) * shake_strength * fade), roundf(cos(time * 91.0) * shake_strength * fade))


func add_impact(strength: float) -> void:
    if impact_shake_enabled:
        shake_strength = maxf(shake_strength, strength)
        shake_remaining = 0.14


func clear_impact() -> void:
    shake_remaining = 0.0
    shake_strength = 0.0
    offset = Vector2.ZERO


func update_look_ahead(facing_direction: int, delta: float) -> void:
    var target_x := float(facing_direction) * look_ahead_pixels
    position.x = roundf(move_toward(position.x, target_x, shift_speed * delta))
