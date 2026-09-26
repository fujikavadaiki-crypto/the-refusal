extends Node2D

@export_range(0.0, 1.0) var depth_speed := 1.0
@export var vertical_speed := 0.0

@onready var camera: Camera2D = get_parent().get_parent().get_node("Player/Camera2D")


func _process(_delta: float) -> void:
    var center := camera.get_screen_center_position()
    var sway := sin(Time.get_ticks_msec() * 0.00045) * 1.2 if name == "CanopyInFront" else 0.0
    position = Vector2(
        roundf((center.x - 240.0) * (1.0 - depth_speed) + sway),
        roundf((center.y - 135.0) * vertical_speed)
    )
