extends Node2D

## Reuses the regression room; starts the player in a separate, flat combat lane.
func _ready() -> void:
    $TestRoom/Player.global_position = Vector2(1070, 215)
    $TestRoom/Player.velocity = Vector2.ZERO
