extends Node2D

var time := 0.0
var leaves: Array[Vector2] = []
var phase: Array[float] = []
var fog: Array[Sprite2D] = []


func _ready() -> void:
    z_index = -2
    var rng := RandomNumberGenerator.new()
    rng.seed = 82619
    for i in range(95):
        leaves.append(Vector2(rng.randf_range(15.0, 3880.0), rng.randf_range(-10.0, 218.0)))
        phase.append(rng.randf_range(0.0, TAU))
    var fog_texture := load("res://assets/biomes/forest/approved/layers/fog_puff.png") as Texture2D
    for i in range(7):
        var ribbon := Sprite2D.new()
        ribbon.name = "DriftingMist%02d" % i
        ribbon.texture = fog_texture
        ribbon.centered = false
        ribbon.position = Vector2(i * 620 + 68, 176 + (i % 3) * 21)
        ribbon.modulate = Color(0.72, 0.81, 0.78, 0.50)
        ribbon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        add_child(ribbon)
        fog.append(ribbon)


func _process(delta: float) -> void:
    time += delta
    for i in range(fog.size()):
        fog[i].position.x = i * 620 + 68 + sin(time * 0.19 + i * 1.3) * 17.0
        fog[i].modulate.a = 0.42 + 0.08 * sin(time * 0.61 + i)
    queue_redraw()


func _draw() -> void:
    var camera: Camera2D = get_parent().get_parent().get_node("Player/Camera2D")
    var camera_x := camera.get_screen_center_position().x
    for shaft_x in [420.0, 1510.0, 2820.0, 3450.0]:
        if absf(shaft_x - camera_x) < 400.0:
            var alpha := 0.013 + 0.005 * sin(time * 0.37 + shaft_x)
            draw_colored_polygon(PackedVector2Array([
                Vector2(shaft_x - 12, -45), Vector2(shaft_x + 4, -45),
                Vector2(shaft_x + 88, 190), Vector2(shaft_x + 42, 190),
            ]), Color(0.82, 0.82, 0.66, alpha))
    for i in range(leaves.size()):
        var p := leaves[i]
        if absf(p.x - camera_x) > 340.0:
            continue
        var x := p.x + sin(time * 0.72 + phase[i]) * 10.0
        var y := fposmod(p.y + time * (4.0 + float(i % 4) * 1.4), 255.0) - 20.0
        var color := Color(0.65, 0.62, 0.41, 0.25 + float(i % 3) * 0.055)
        draw_line(Vector2(x-2.0,y), Vector2(x+1.0,y+1.0), color, 1.0)
        if i % 4 == 0:
            var dust_y := 175.0 + float(i % 8) * 9.0 + sin(time * 0.8 + phase[i]) * 3.0
            draw_circle(Vector2(p.x + sin(time * 0.23 + phase[i]) * 5.0, dust_y),
                0.7, Color(0.72, 0.71, 0.58, 0.12))
    # A faint glint is confined to the visible approved water in each open gap.
    for water_x in [1185.0, 2445.0, 3735.0]:
        if absf(water_x - camera_x) < 300.0:
            for j in range(4):
                var wave := sin(time * 1.3 + j * 1.6)
                draw_line(Vector2(water_x - 16 + j * 9 + wave * 3, 273 + j % 2 * 4),
                    Vector2(water_x - 9 + j * 9 + wave * 3, 273 + j % 2 * 4),
                    Color(0.66, 0.75, 0.71, 0.11 + 0.07 * sin(time + j)), 1.0)
