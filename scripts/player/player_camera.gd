class_name PlayerCamera
extends Camera2D

## Small reversible look-ahead; the room limits keep the visible area inside the sandbox.
@export var look_ahead_pixels := 60.0
@export var shift_speed := 240.0


func update_look_ahead(facing_direction: int, delta: float) -> void:
    var target_x := float(facing_direction) * look_ahead_pixels
    position.x = roundf(move_toward(position.x, target_x, shift_speed * delta))
