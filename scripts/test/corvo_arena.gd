extends Node2D

## Technical encounter; the existing main room and Peregrino arena are untouched.
func _ready() -> void:
    $TestRoom/Player.global_position = Vector2(1070, 215)
    $TestRoom/Player.velocity = Vector2.ZERO
