extends Node2D

## Fixed, low-cost placeholder composition for Stage 1. No gameplay collision.
@export var world_length := 8200.0

const SKY := Color(0.10, 0.15, 0.15)
const FAR_FOG := Color(0.19, 0.25, 0.22)
const FAR_TREE := Color(0.15, 0.21, 0.19)
const NEAR_TREE := Color(0.12, 0.17, 0.15)
const CANOPY := Color(0.11, 0.18, 0.15)
const STONE := Color(0.22, 0.27, 0.25)


func _draw() -> void:
    draw_rect(Rect2(0, 0, world_length, 270), SKY)
    draw_rect(Rect2(0, 86, world_length, 100), FAR_FOG)
    draw_rect(Rect2(0, 173, world_length, 55), Color(0.15, 0.21, 0.18))
    for i in range(45):
        var x := float(i) * 187.0 + float((i * 37) % 73)
        var trunk_width := 8.0 + float(i % 3) * 3.0
        draw_rect(Rect2(x, 46 + i % 4 * 9, trunk_width, 180), FAR_TREE)
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 33, 66), Vector2(x - 20, 25), Vector2(x + trunk_width * 0.5, 12),
            Vector2(x + trunk_width + 25, 28), Vector2(x + trunk_width + 42, 70)
        ]), CANOPY)
    for x in [320.0, 980.0, 1540.0, 2390.0, 3220.0, 3820.0, 4670.0, 6160.0, 7630.0]:
        _draw_near_tree(x)
    for x in [720.0, 1730.0, 3030.0, 3970.0, 4850.0, 6370.0, 7830.0]:
        _draw_ruin(x)


func _draw_near_tree(x: float) -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(x - 16, 228), Vector2(x - 10, 92), Vector2(x - 14, 18),
        Vector2(x + 12, 18), Vector2(x + 9, 104), Vector2(x + 19, 228)
    ]), NEAR_TREE)
    draw_line(Vector2(x, 88), Vector2(x - 56, 61), NEAR_TREE, 6.0)
    draw_line(Vector2(x + 2, 105), Vector2(x + 63, 73), NEAR_TREE, 5.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(x - 78, 64), Vector2(x - 57, 34), Vector2(x - 28, 19),
        Vector2(x + 25, 16), Vector2(x + 72, 37), Vector2(x + 83, 62)
    ]), CANOPY)


func _draw_ruin(x: float) -> void:
    draw_rect(Rect2(x - 39, 174, 9, 54), STONE)
    draw_rect(Rect2(x + 23, 185, 8, 43), STONE)
    draw_rect(Rect2(x - 44, 171, 19, 5), Color(0.25, 0.30, 0.26))
    draw_rect(Rect2(x + 19, 182, 17, 5), Color(0.25, 0.30, 0.26))
    draw_line(Vector2(x - 30, 177), Vector2(x + 24, 184), STONE, 4.0)
