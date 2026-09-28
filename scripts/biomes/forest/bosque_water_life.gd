extends Node2D

## Small moving accents registered to the approved Bosque B painting.
## Coordinates are source-image pixels; the scene supplies the image transform.
@export var foreground_spray := false

const FOG := preload("res://assets/biomes/forest/approved/layers/fog_puff.png")
const FALLS := [
    Vector4(1613.0, 1642.0, 383.0, 462.0), # waterfall behind the ruined arch
    Vector4(1608.0, 1625.0, 486.0, 565.0),
    Vector4(1628.0, 1639.0, 485.0, 578.0),
    Vector4(1648.0, 1661.0, 484.0, 591.0),
    Vector4(1665.0, 1682.0, 484.0, 604.0),
    Vector4(1689.0, 1703.0, 486.0, 560.0),
]

var clock := 0.0
var vapor: Array[Sprite2D] = []


func _ready() -> void:
    if foreground_spray:
        return
    for i in range(3):
        var puff := Sprite2D.new()
        puff.name = "WetVapor%02d" % i
        puff.texture = FOG
        puff.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        puff.position = [Vector2(1624, 465), Vector2(1642, 576), Vector2(1690, 594)][i]
        puff.scale = [Vector2(0.40, 0.31), Vector2(0.72, 0.47), Vector2(0.80, 0.40)][i]
        puff.modulate = Color(0.72, 0.80, 0.78, 0.26)
        add_child(puff)
        vapor.append(puff)


func _process(delta: float) -> void:
    clock += delta
    for i in range(vapor.size()):
        var puff := vapor[i]
        puff.position.x = [1624.0, 1642.0, 1690.0][i] + sin(clock * 0.32 + i * 1.7) * 5.0
        puff.position.y = [465.0, 576.0, 594.0][i] + sin(clock * 0.41 + i) * 2.0
        puff.modulate.a = 0.21 + 0.055 * sin(clock * 0.54 + i)
    queue_redraw()


func _draw() -> void:
    if foreground_spray:
        _draw_spray()
        return
    _draw_falling_water()
    _draw_surface_reflections()
    _draw_water_vapor()


func _draw_falling_water() -> void:
    for band_index in range(FALLS.size()):
        var band: Vector4 = FALLS[band_index]
        var height := band.w - band.z
        var lane_count := maxi(4, roundi((band.y - band.x) / 3.2))
        for lane in range(lane_count):
            var x := lerpf(band.x + 1.0, band.y - 1.0, float(lane) / float(lane_count - 1))
            var speed := 43.0 + float((lane * 13 + band_index * 7) % 29)
            var phase := float((lane * 29 + band_index * 41) % 91)
            var length := 16.0 + float((lane * 11 + band_index * 3) % 25)
            var ribbon_sway := sin(clock * 0.62 + lane * 0.87) * 0.9 + sin(clock * 1.23 + lane * 1.7) * 0.25
            draw_line(
                Vector2(x + ribbon_sway, band.z),
                Vector2(x + ribbon_sway + 0.8, band.w),
                Color(0.70, 0.84, 0.84, 0.048 + 0.016 * sin(clock * 0.83 + lane)),
                1.25
            )
            for segment in range(4):
                var flow_time := clock * speed + sin(clock * 0.31 + lane * 0.87 + band_index) * 3.5
                var head := fposmod(flow_time + phase + segment * height * 0.38, height + length) - length
                var y0 := maxf(band.z, band.z + head)
                var y1 := minf(band.w, band.z + head + length)
                if y1 - y0 < 2.0:
                    continue
                var drift := sin(clock * 0.66 + lane * 0.81) * 0.5
                var alpha := 0.17 + 0.05 * sin(clock * 1.07 + lane * 1.3 + segment)
                draw_line(Vector2(x + drift, y0), Vector2(x + drift + 0.7, y1), Color(0.80, 0.89, 0.87, alpha), 1.45)


func _draw_surface_reflections() -> void:
    # The gap stays empty: these are water highlights, never ground or collision.
    for i in range(18):
        var x := 1576.0 + float(i) * 8.0
        var y := 469.0 + sin(clock * 1.12 + i * 1.7) * 1.4 + float(i % 3) * 1.3
        var width := 3.0 + float(i % 4) * 1.8
        draw_line(Vector2(x, y), Vector2(x + width, y), Color(0.79, 0.86, 0.83, 0.13 + 0.05 * sin(clock * 0.84 + i)), 1.2)
        if i % 3 == 0:
            draw_circle(Vector2(x + width * 0.5, y + 2.0), 0.85, Color(0.86, 0.91, 0.88, 0.12))
    for i in range(16):
        var x := 1498.0 + float(i) * 22.0 + sin(clock * 0.45 + i) * 2.0
        var y := 613.0 + float(i % 3) * 5.0
        var alpha := 0.08 + 0.045 * sin(clock * 0.77 + i * 1.2)
        draw_line(Vector2(x, y), Vector2(x + 8.0 + float(i % 3) * 4.0, y), Color(0.76, 0.84, 0.80, alpha), 1.0)
    for i in range(4):
        var ripple_center := Vector2(1584.0 + i * 37.0, 607.0 + float(i % 2) * 5.0)
        var life := fposmod(clock * (0.30 + i * 0.035) + i * 0.28, 1.0)
        var radius := 3.0 + life * 12.0
        var fade := (1.0 - life) * 0.075
        draw_arc(ripple_center, radius, 0.05, PI - 0.05, 10, Color(0.74, 0.83, 0.82, fade), 1.0)
    for i in range(7):
        var foam_x := 1603.0 + float(i) * 15.0
        var foam_y := 484.0 + float(i % 2) * 1.5
        var foam_alpha := 0.13 + 0.065 * sin(clock * (0.9 + i * 0.07) + i * 1.6)
        draw_arc(Vector2(foam_x, foam_y), 2.5 + float(i % 3), PI * 0.1, PI * 0.91, 8, Color(0.85, 0.91, 0.87, foam_alpha), 1.2)
    for i in range(6):
        var impact_x := 1602.0 + float(i) * 19.0 + sin(clock * 0.65 + i) * 2.0
        var impact_y := 606.0 + float(i % 2) * 3.0
        draw_line(Vector2(impact_x - 3.0, impact_y), Vector2(impact_x + 3.0, impact_y - 0.6), Color(0.83, 0.90, 0.87, 0.1 + 0.05 * sin(clock * 1.2 + i)), 1.0)


func _draw_water_vapor() -> void:
    var centers := [Vector2(1628, 464), Vector2(1650, 584), Vector2(1694, 595)]
    var radii := [Vector2(29, 9), Vector2(52, 15), Vector2(48, 12)]
    for i in range(centers.size()):
        var center: Vector2 = centers[i] + Vector2(sin(clock * 0.29 + i) * 5.0, sin(clock * 0.41 + i) * 1.2)
        var size: Vector2 = radii[i]
        for ring in range(9, 0, -1):
            var points := PackedVector2Array()
            for step in range(21):
                var angle := TAU * float(step) / 20.0
                var edge := 1.0 + 0.055 * sin(angle * 3.0 + clock * 0.17 + i)
                points.append(center + Vector2(cos(angle) * size.x * float(ring) / 9.0 * edge, sin(angle) * size.y * float(ring) / 9.0))
            draw_colored_polygon(points, Color(0.69, 0.78, 0.77, 0.0075))


func _draw_spray() -> void:
    for i in range(34):
        var x := 1598.0 + float((i * 31) % 119) + sin(clock * 0.78 + i * 1.4) * 5.0
        var y := 468.0 + fposmod(clock * (9.0 + float(i % 4) * 3.0) + float(i * 23), 90.0)
        var alpha := 0.13 + 0.055 * sin(clock * 0.9 + i)
        draw_circle(Vector2(x, y), 0.65 if i % 3 else 0.95, Color(0.79, 0.86, 0.83, alpha))
