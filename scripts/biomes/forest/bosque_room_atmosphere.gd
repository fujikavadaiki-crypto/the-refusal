extends Node2D

## Restrained overlays over the intact Bosque B painting. No opaque fog cards.
@export var foreground := false
@export var distant := false

const FOG := preload("res://assets/biomes/forest/approved/layers/fog_puff.png")

var clock := 0.0
var fog_sprites: Array[Sprite2D] = []
var fog_origins: Array[Vector2] = []
var particles: Array[Vector2] = []
var phases: Array[float] = []
var camera: Camera2D
var wind: Node


func _ready() -> void:
    camera = get_parent().get_parent().get_node("Player/Camera2D") as Camera2D
    wind = get_tree().get_first_node_in_group("bosque_wind")
    var rng := RandomNumberGenerator.new()
    rng.seed = 0xB05B
    var count := 22 if foreground else 12 if distant else 31
    for i in range(count):
        particles.append(Vector2(rng.randf_range(25.0, 1280.0), rng.randf_range(85.0, 300.0)))
        phases.append(rng.randf_range(0.0, TAU))
    if foreground:
        return
    var puff_count := 4 if distant else 8
    for i in range(puff_count):
        var cluster := int(i / 2)
        var strand := i % 2
        var puff := Sprite2D.new()
        puff.name = ("FarMist%02d" if distant else "OrganicMist%02d") % i
        puff.texture = FOG
        puff.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        if distant:
            puff.scale = Vector2(1.15, 0.82)
            puff.position = [Vector2(238, 150), Vector2(524, 162), Vector2(817, 159), Vector2(1080, 180)][i]
            puff.modulate = Color(0.63, 0.70, 0.69, 0.18)
        else:
            puff.scale = Vector2(1.55, 1.25)
            puff.position = Vector2(130 + cluster * 310 + strand * 28, 246 + (cluster % 2) * 18 + strand * 3)
            puff.modulate = Color(0.72, 0.79, 0.73, 0.74)
        fog_origins.append(puff.position)
        add_child(puff)
        fog_sprites.append(puff)


func _process(delta: float) -> void:
    clock += delta
    for i in range(fog_sprites.size()):
        var puff := fog_sprites[i]
        var origin := fog_origins[i]
        puff.position.x = origin.x + sin(clock * (0.13 if distant else 0.18) + i * 0.8) * (4.0 if distant else 7.0)
        puff.position.y = origin.y + sin(clock * 0.27 + i) * (1.5 if distant else 2.0)
        puff.modulate.a = (0.17 + 0.035 * sin(clock * 0.32 + i)) if distant else (0.68 + 0.07 * sin(clock * 0.39 + i))
    queue_redraw()


func _draw() -> void:
    if camera == null:
        return
    var camera_x := camera.get_screen_center_position().x
    if distant:
        _draw_haze_banks(camera_x, true)
        return
    if foreground:
        _draw_near_leaves(camera_x)
    else:
        _draw_haze_banks(camera_x, false)
        _draw_dust_and_light(camera_x)


func _draw_haze_banks(camera_x: float, far_layer: bool) -> void:
    var centers := [Vector2(240, 169), Vector2(775, 177), Vector2(1080, 187)] if far_layer else [Vector2(230, 248), Vector2(602, 252), Vector2(985, 267)]
    for i in range(centers.size()):
        var center: Vector2 = centers[i]
        if absf(center.x - camera_x) > 420.0:
            continue
        center.x += sin(clock * (0.11 if far_layer else 0.17) + i * 1.7) * (6.0 if far_layer else 9.0)
        center.y += sin(clock * 0.23 + i) * 1.4
        var radius := Vector2(150, 26) if far_layer else Vector2(112, 21)
        var rings := 10 if far_layer else 12
        var breathe := 0.91 + 0.09 * sin(clock * 0.29 + i)
        for ring in range(rings, 0, -1):
            var points := PackedVector2Array()
            for step in range(25):
                var angle := TAU * float(step) / 24.0
                var edge := 1.0 + 0.045 * sin(angle * 4.0 + i * 1.9)
                points.append(center + Vector2(cos(angle) * radius.x * float(ring) / float(rings) * edge, sin(angle) * radius.y * float(ring) / float(rings)))
            var alpha := (0.0025 if far_layer else 0.0052) * breathe
            draw_colored_polygon(points, Color(0.57, 0.66, 0.65, alpha))


func _draw_dust_and_light(camera_x: float) -> void:
    var gust := float(wind.call("gust", 0.35)) if wind != null else 0.0
    for i in range(particles.size()):
        var base := particles[i]
        if absf(base.x - camera_x) > 300.0:
            continue
        var wind := sin(clock * 0.18 + phases[i]) + sin(clock * 0.07 + phases[i] * 1.7) * 0.45
        var x := base.x + clock * (0.55 + gust * 0.55) + wind * (4.0 + gust * 3.0)
        var y := base.y + sin(clock * 0.36 + phases[i] * 1.3) * 6.0
        if i % 5 == 0:
            var twinkle := 0.11 + 0.06 * sin(clock * 1.1 + phases[i])
            draw_circle(Vector2(x, y), 1.0, Color(0.86, 0.81, 0.63, twinkle))
        else:
            draw_circle(Vector2(x, y), 0.65, Color(0.66, 0.68, 0.60, 0.11))
    var pulse := 0.87 + 0.07 * sin(clock * 0.24) + 0.04 * sin(clock * 0.53 + 1.4)
    for center in [Vector2(235, 95), Vector2(994, 125), Vector2(1100, 172)]:
        if absf(center.x - camera_x) > 330.0:
            continue
        for ring in range(16, 0, -1):
            var tint := Color(0.68, 0.78, 0.76) if center.x > 1050.0 else Color(0.84, 0.78, 0.58)
            tint.a = (0.0018 if center.x > 1050.0 else 0.0024) * pulse
            draw_circle(center, ring * 7.5, tint)


func _draw_near_leaves(camera_x: float) -> void:
    var gust := float(wind.call("gust", 0.55)) if wind != null else 0.0
    for i in range(particles.size()):
        var base := particles[i]
        if absf(base.x - camera_x) > 295.0:
            continue
        var wind := sin(clock * 0.21 + phases[i]) + sin(clock * 0.075 + phases[i] * 1.6) * 0.6
        var x := fposmod(base.x + clock * (3.1 + float(i % 3) * 1.4 + gust * 2.2) + wind * (6.0 + gust * 5.0), 1300.0)
        var y := fposmod(base.y + clock * (2.7 + float(i % 3) * 1.1), 320.0) - 16.0
        var tint := Color(0.47, 0.50, 0.34, 0.24 + float(i % 3) * 0.035)
        draw_line(Vector2(x - 1.5, y), Vector2(x + 1.0, y + 0.8), tint, 1.0)
    var rooted_tips := [
        Vector2(255, 218), Vector2(440, 225), Vector2(685, 239),
        Vector2(824, 252), Vector2(955, 261), Vector2(1035, 260),
    ]
    for i in range(rooted_tips.size()):
        var tip: Vector2 = rooted_tips[i]
        if absf(tip.x - camera_x) > 295.0:
            continue
        var sway := sin(clock * 0.8 + i * 1.4) * 1.1
        draw_line(tip + Vector2(0, 1), tip + Vector2(sway, -3), Color(0.38, 0.48, 0.30, 0.24), 1.0)
