extends Node2D

## Room-specific soft floor shadow. It follows the existing collision geometry.
@onready var player: CharacterBody2D = get_parent().get_node("Player")

var spread := 0.0


func _physics_process(_delta: float) -> void:
    var from := player.global_position + Vector2(0, 10)
    var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 95), 1)
    query.exclude = [player.get_rid()]
    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    visible = not hit.is_empty()
    if not visible:
        return
    global_position = hit.position + Vector2(0, -1)
    var height := maxf(0.0, hit.position.y - from.y)
    spread = clampf(height / 90.0, 0.0, 1.0)
    modulate.a = clampf(0.75 - height / 125.0, 0.09, 0.75)
    queue_redraw()


func _draw() -> void:
    _draw_oval(24.0 + spread * 7.0, 4.2 + spread, 0.055)
    _draw_oval(18.0 + spread * 5.0, 3.0 + spread * 0.6, 0.085)
    _draw_oval(10.5 + spread * 3.0, 1.9 + spread * 0.4, 0.13)


func _draw_oval(radius_x: float, radius_y: float, alpha: float) -> void:
    var points := PackedVector2Array()
    for i in range(25):
        var angle := TAU * float(i) / 24.0
        points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
    draw_colored_polygon(points, Color(0.035, 0.055, 0.045, alpha))
