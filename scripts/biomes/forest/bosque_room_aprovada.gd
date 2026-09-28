extends Node2D

## One approved painted room. The artwork is untouched; only thin invisible
## CollisionPolygon2D surfaces define where the Carrasco can stand.
const CARRASCO := preload("res://data/masks/carrasco_base.tres")

@onready var player: CharacterBody2D = $Player
@onready var start: Marker2D = $Start
@onready var exit_marker: Marker2D = $Exit

var safe_position: Vector2
var fall_count := 0
var reached_exit := false
var carrasco_visual: Node2D


func _ready() -> void:
    player.global_position = start.global_position
    player.velocity = Vector2.ZERO
    player.get_node("MaskController").equip(0, CARRASCO)
    player.get_node("VisualRoot").position.y = 13.0
    player.get_node("DebugLabel").visible = false
    carrasco_visual = player.get_node_or_null("VisualRoot/CarrascoModular") as Node2D
    if carrasco_visual != null:
        carrasco_visual.scale = Vector2(0.34, 0.34)
        carrasco_visual.modulate = Color(0.79, 0.93, 0.89, 1.0)
    var camera := player.get_node("Camera2D") as Camera2D
    camera.position.y = 35
    camera.zoom = Vector2(0.9, 0.9)
    camera.limit_left = 0
    camera.limit_right = 1300
    camera.limit_top = -125
    camera.limit_bottom = 606
    camera.make_current()
    safe_position = start.global_position


func _process(_delta: float) -> void:
    if carrasco_visual != null:
        var open_light := clampf((player.global_position.x - 700.0) / 480.0, 0.0, 1.0)
        carrasco_visual.modulate = Color(0.79 + 0.04 * open_light, 0.93 + 0.03 * open_light, 0.89 + 0.03 * open_light, 1.0)


func _physics_process(_delta: float) -> void:
    if player.is_on_floor() and player.global_position.x < 1040:
        safe_position = player.global_position
    if player.global_position.y > 410:
        fall_count += 1
        player.global_position = safe_position
        player.velocity = Vector2.ZERO
    if not reached_exit and player.global_position.x >= exit_marker.global_position.x and player.is_on_floor():
        reached_exit = true
        print("BOSQUE_APPROVED_ROOM_EXIT falls=%d" % fall_count)
