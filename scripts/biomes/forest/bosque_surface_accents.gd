extends Node2D

## Sparse moss/stone glints on already-painted walkable lips.
## Visual only; the approved collision polygons remain the sole geometry.
const LIPS := [
    Vector4(720, 317, 819, 316),
    Vector4(930, 382, 1068, 378),
    Vector4(1245, 322, 1293, 321),
    Vector4(1350, 346, 1435, 346),
    Vector4(1450, 412, 1555, 411),
    Vector4(1504, 443, 1565, 445),
    Vector4(1735, 474, 1890, 470),
    Vector4(1750, 287, 1890, 286),
]


func _draw() -> void:
    for lip_index in range(LIPS.size()):
        var lip: Vector4 = LIPS[lip_index]
        var from := Vector2(lip.x, lip.y)
        var to := Vector2(lip.z, lip.w)
        var count := maxi(2, roundi(from.distance_to(to) / 15.0))
        for i in range(count):
            var t := (float(i) + 0.28) / float(count)
            var point := from.lerp(to, t) + Vector2(0, float((i * 3 + lip_index) % 3) * 0.3)
            var width := 3.0 + float((i * 7 + lip_index) % 4)
            var highlight := Color(0.60, 0.66, 0.45, 0.18 + float(i % 3) * 0.035)
            draw_line(point, point + Vector2(width, -0.2), highlight, 1.15)
            if i % 3 == 0:
                draw_line(point + Vector2(width * 0.5, 1.2), point + Vector2(width * 0.5 + 1.0, 2.6), Color(0.17, 0.23, 0.17, 0.22), 1.0)
