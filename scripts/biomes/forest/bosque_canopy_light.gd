extends Node2D

## Slow, local light and canopy shadows over the intact Bosque B painting.
const SHADOW_PATCHES := [
    Vector4(195, 201, 93, 27),
    Vector4(530, 218, 116, 29),
    Vector4(875, 242, 106, 31),
]
const LIGHT_GAPS := [
    Vector4(296, 45, 359, 228),
    Vector4(785, 35, 837, 248),
]

var clock := 0.0
var wind: Node


func _ready() -> void:
    wind = get_tree().get_first_node_in_group("bosque_wind")


func _process(delta: float) -> void:
    clock += delta
    queue_redraw()


func _draw() -> void:
    _draw_moving_shadows()
    _draw_light_gaps()


func _draw_moving_shadows() -> void:
    for i in range(SHADOW_PATCHES.size()):
        var patch: Vector4 = SHADOW_PATCHES[i]
        var gust := float(wind.call("gust", 0.85 + i * 0.17)) if wind != null else 0.0
        var motion := sin(clock * 0.12 + i * 1.7) * 5.0 + sin(clock * 0.29 + i * 2.3) * 2.0 + gust * (3.0 + i)
        var center := Vector2(patch.x + motion, patch.y + sin(clock * 0.14 + i) * 1.2)
        var density := 0.84 + 0.16 * sin(clock * 0.19 + i * 1.21) + gust * 0.08
        for ring in range(8, 0, -1):
            var points := PackedVector2Array()
            for step in range(25):
                var angle := TAU * float(step) / 24.0
                var edge := 1.0 + 0.07 * sin(angle * 3.0 + i * 1.8 + clock * 0.08)
                points.append(center + Vector2(cos(angle) * patch.z * float(ring) / 8.0 * edge, sin(angle) * patch.w * float(ring) / 8.0))
            draw_colored_polygon(points, Color(0.065, 0.085, 0.075, 0.0044 * density))


func _draw_light_gaps() -> void:
    for i in range(LIGHT_GAPS.size()):
        var gap: Vector4 = LIGHT_GAPS[i]
        var gust := float(wind.call("gust", 1.1 + i * 0.23)) if wind != null else 0.0
        var drift := sin(clock * 0.14 + i * 1.91) * 2.7 + gust * 2.5
        var breathe := 0.76 + 0.16 * sin(clock * 0.22 + i * 2.13) + 0.08 * sin(clock * 0.49 + i)
        for band in range(5, 0, -1):
            var top_width := float(band) * 2.2
            var bottom_width := float(band) * 5.4
            var top := Vector2(gap.x + drift, gap.y)
            var bottom := Vector2(gap.z + drift * 0.6, gap.w)
            draw_colored_polygon(PackedVector2Array([
                top + Vector2(-top_width, 0),
                top + Vector2(top_width, 0),
                bottom + Vector2(bottom_width, 0),
                bottom + Vector2(-bottom_width, 0),
            ]), Color(0.72, 0.76, 0.64, 0.0025 * breathe))
