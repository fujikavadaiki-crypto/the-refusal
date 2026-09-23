extends Node2D

## Isolated flat-lane ambush with the existing room's platforms still available.
func _ready() -> void:
    $TestRoom/Player.global_position = Vector2(1090, 215)
    $TestRoom/Player.velocity = Vector2.ZERO
