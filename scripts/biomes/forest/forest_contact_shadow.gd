extends Node2D

@onready var player: CharacterBody2D = get_parent().get_node("Player")


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
    modulate.a = clampf(0.68 - height / 130.0, 0.11, 0.68)
    queue_redraw()


func _draw() -> void:
    var points := PackedVector2Array()
    for i in range(17):
        var angle := TAU * float(i) / 16.0
        points.append(Vector2(cos(angle) * 18.0, sin(angle) * 2.6))
    draw_colored_polygon(points, Color(0.04, 0.06, 0.055, 0.22))
