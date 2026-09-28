extends Node2D
## Source-image coordinates. The approved painting, camera and collision stay fixed.

@export_enum("Waterfall", "LowerWater", "Vegetation", "Leaves", "Mist", "Light", "Spray") var layer_mode := 0

const FOG: Texture2D = preload("res://assets/biomes/forest/approved/layers/fog_puff.png")
const CUTOUT_ROOT := "res://assets/biomes/forest/approved/layers/vegetation_cutouts/"
const FALLS := [
	Vector4(1613, 1642, 383, 462),
	Vector4(1608, 1625, 486, 565),
	Vector4(1628, 1639, 485, 578),
	Vector4(1648, 1661, 484, 591),
	Vector4(1665, 1682, 484, 604),
	Vector4(1689, 1703, 486, 560),
]

var clock := 0.0
var wind: Node
var vegetation: Array[Node2D] = []


func _ready() -> void:
	wind = get_tree().get_first_node_in_group("bosque_wind")
	if layer_mode == 2:
		_build_vegetation()


func _process(delta: float) -> void:
	clock += delta
	if layer_mode == 0:
		var art := get_node("../../BACKGROUND/ApprovedComposition") as Sprite2D
		(art.material as ShaderMaterial).set_shader_parameter("loop_phase", fposmod(clock, 10.0) / 10.0)
	if layer_mode == 2:
		_sway_vegetation()
	queue_redraw()


func _draw() -> void:
	match layer_mode:
		0: _draw_waterfall()
		1: _draw_lower_water()
		3: _draw_leaves()
		4: _draw_mist()
		5: _draw_light()
		6: _draw_spray()


func _gust(delay: float = 0.0) -> float:
	return float(wind.call("gust", delay)) if wind != null else 0.0


func _draw_waterfall() -> void:
	# Moving highlights follow the six painted water bands. Dark rock is untouched.
	for b in FALLS.size():
		var band: Vector4 = FALLS[b]
		var height := band.w - band.z
		var count := maxi(4, roundi((band.y - band.x) / 2.8))
		for lane in count:
			var x := lerpf(band.x + 0.7, band.y - 0.7, float(lane) / float(count - 1))
			var phase := float((lane * 29 + b * 37) % 103)
			var drift := sin(clock * 0.66 + lane * 0.59 + b) * 0.55
			draw_line(Vector2(x + drift, band.z), Vector2(x + drift, band.w), Color(0.76, 0.88, 0.87, 0.095), 1.1)
			for n in 4:
				var speed := 53.0 + float((lane * 7 + b * 19) % 32)
				var length := 11.0 + float((lane * 13 + n * 5) % 22)
				var head := fposmod(clock * speed + phase + n * height * 0.39, height + length) - length
				var y0 := maxf(band.z, band.z + head)
				var y1 := minf(band.w, band.z + head + length)
				if y1 - y0 > 2.0:
					draw_line(Vector2(x + drift, y0), Vector2(x + drift + 0.7, y1), Color(0.82, 0.93, 0.92, 0.30 if n % 2 else 0.38), 1.35)
	# Painted lip foam, kept within the actual gap.
	for i in 20:
		var x := 1601.0 + float(i) * 5.1
		var drift := sin(clock * 1.3 + i * 0.78) * 1.4
		var y := 481.0 + float(i % 3) * 1.8
		draw_line(Vector2(x + drift, y), Vector2(x + drift + 2.5 + float(i % 3), y - 0.3), Color(0.83, 0.91, 0.88, 0.21), 1.1)
	# A gentle flicker of falling water beneath the distant ruined arch.
	for i in 12:
		var x := 1609.0 + float(i) * 2.7
		var travel := fposmod(clock * (41.0 + float(i % 3) * 8.0) + i * 23.0, 100.0)
		draw_line(Vector2(x, 382.0 + travel), Vector2(x + 0.4, minf(466.0, 391.0 + travel)), Color(0.82, 0.91, 0.88, 0.20), 1.1)


func _draw_lower_water() -> void:
	# Surface reflections in the water below the main path, including the
	# visible rim immediately beneath the waterfall landing.
	for bank in [Vector2(0, 730), Vector2(760, 1260), Vector2(1465, 1580), Vector2(1730, 1900)]:
		var count := roundi((bank.y - bank.x) / 23.0)
		for i in count:
			var x: float = bank.x + float(i) * 23.0 + sin(clock * 0.8 + i * 0.7) * 2.0
			var y := 604.0 + float((i * 7) % 4) * 5.5
			var travel := fposmod(clock * (13.0 + float(i % 3) * 3.0) + float(i * 17), 34.0)
			var width := 5.0 + float(i % 4) * 3.0
			draw_line(Vector2(x + travel, y), Vector2(x + travel + width, y), Color(0.72, 0.84, 0.82, 0.22), 1.15)
			if i % 3 == 0:
				draw_line(Vector2(x + travel + 4.0, y + 3.0), Vector2(x + travel + 9.0, y + 3.0), Color(0.62, 0.75, 0.74, 0.15), 1.0)
	for i in 18:
		var x := 1565.0 + float(i) * 9.0
		var y := 570.0 + float(i % 3) * 4.0
		var offset := sin(clock * 1.35 + i * 0.77) * 2.2
		draw_line(Vector2(x + offset, y), Vector2(x + offset + 3.0 + float(i % 4), y), Color(0.79, 0.90, 0.88, 0.19), 1.2)
	# Expanding, fading ripples at the base of the falls.
	for i in 7:
		var center := Vector2(1582.0 + float(i) * 22.0, 603.0 + float(i % 2) * 3.0)
		var life := fposmod(clock * (0.31 + float(i % 3) * 0.035) + float(i) * 0.21, 1.0)
		draw_arc(center, 2.5 + life * 14.0, 0.1, PI - 0.1, 12, Color(0.74, 0.87, 0.84, (1.0 - life) * 0.22), 1.0)


func _build_vegetation() -> void:
	var patches := [
		["arch_leaf_left_tip", Vector2(80, 149), Vector2(53, 121), 1.7],
		["arch_leaf_right_tip", Vector2(206, 153), Vector2(199, 125), 1.6],
		["tree_leaf_left_tip", Vector2(352, 283), Vector2(326, 252), 1.9],
		["tree_leaf_right_tip", Vector2(438, 288), Vector2(432, 260), 1.8],
		["far_tree_left_tip", Vector2(1676, 254), Vector2(1648, 221), 1.6],
		["far_tree_right_tip", Vector2(1800, 244), Vector2(1794, 213), 1.8],
		["arch_vine_center_tail", Vector2(148, 190), Vector2(139, 184), 2.1],
		["arch_vine_right_tail", Vector2(165, 176), Vector2(157, 170), 2.0],
		["trunk_vine_tail", Vector2(781, 169), Vector2(772, 163), 2.1],
		["floating_moss_left_tip", Vector2(732, 333), Vector2(723, 328), 2.2],
		["floating_moss_right_tip", Vector2(807, 333), Vector2(798, 327), 2.2],
		["waterfall_moss_tip", Vector2(1509, 419), Vector2(1500, 414), 2.3],
		["right_ledge_moss_tip", Vector2(1807, 295), Vector2(1797, 290), 2.0],
	]
	for entry in patches:
		var anchor := Node2D.new()
		anchor.name = str(entry[0]).to_pascal_case()
		anchor.position = entry[1]
		add_child(anchor)
		var sprite := Sprite2D.new()
		sprite.name = "ApprovedArtTip"
		sprite.texture = load(CUTOUT_ROOT + str(entry[0]) + ".png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.position = entry[2] - entry[1]
		anchor.add_child(sprite)
		vegetation.append(anchor)


func _sway_vegetation() -> void:
	for i in vegetation.size():
		var anchor := vegetation[i]
		var phase := float(i) * 1.37
		var gust := _gust(float(i % 4) * 0.19)
		var wave := sin(clock * (0.85 + float(i % 3) * 0.1) + phase)
		var secondary := 0.22 * sin(clock * 1.43 + phase * 1.29)
		var strength := 1.65 if i < 6 else 2.15
		anchor.rotation = deg_to_rad((wave + secondary) * strength * (0.62 + gust * 0.52))


func _draw_leaves() -> void:
	# Independent slow flights, with fade-in/out well inside the painting.
	for i in 26:
		var seed := float(i)
		var age := fposmod(clock / (6.5 + float(i % 4) * 0.9) + seed * 0.319, 1.0)
		var alpha := pow(sin(PI * age), 2.0) * (0.48 + float(i % 3) * 0.055)
		var origin := Vector2(42.0 + fposmod(seed * 257.0, 1800.0), 95.0 + fposmod(seed * 113.0, 355.0))
		var p := origin + Vector2(age * (150.0 + float(i % 4) * 34.0), age * (31.0 + float(i % 3) * 12.0) + sin(clock * 1.06 + seed) * 5.0)
		if p.x > 1894.0:
			continue
		var tilt := sin(clock * 1.7 + seed * 1.29) * 1.5
		var size := 4.0 + float(i % 4) * 0.95
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-size, 0), p + Vector2(0, -1.3 + tilt * 0.3),
			p + Vector2(size, 0.4), p + Vector2(0, 1.2 + tilt * 0.3),
		]), Color(0.53, 0.59, 0.36, alpha))
		if i % 3 == 0:
			draw_line(p, p + Vector2(1.5, 1.1), Color(0.25, 0.33, 0.23, alpha * 0.55), 0.75)


func _draw_mist() -> void:
	var drift := sin(clock * 0.22)
	for region in [
		[Vector2(172, 520), Vector2(260, 84), 0.35],
		[Vector2(835, 535), Vector2(280, 78), 0.29],
		[Vector2(1542, 550), Vector2(235, 82), 0.72],
		[Vector2(1593, 450), Vector2(158, 55), 0.47],
	]:
		var origin: Vector2 = region[0]
		var size: Vector2 = region[1]
		var alpha: float = region[2]
		draw_texture_rect(FOG, Rect2(origin + Vector2(drift * 6.0, sin(clock * 0.32) * 1.5), size), false, Color(0.72, 0.80, 0.79, alpha))
	for i in 38:
		var x := 30.0 + fposmod(float(i) * 247.0, 1840.0)
		var y := 83.0 + fposmod(float(i) * 127.0, 465.0)
		var motion := Vector2(sin(clock * 0.36 + i) * 3.0, sin(clock * 0.25 + i * 1.4) * 2.0)
		draw_circle(Vector2(x, y) + motion, 0.8 if i % 4 else 1.1, Color(0.69, 0.77, 0.74, 0.17))


func _draw_light() -> void:
	var drift := sin(clock * 0.18) * 3.0
	for shaft in [Vector4(280, 45, 351, 277), Vector4(775, 34, 836, 302), Vector4(1365, 47, 1314, 310)]:
		for band in 5:
			var wide := float(5 - band)
			draw_colored_polygon(PackedVector2Array([
				Vector2(shaft.x + drift - wide * 2.0, shaft.y),
				Vector2(shaft.x + drift + wide * 2.0, shaft.y),
				Vector2(shaft.z + drift * 0.6 + wide * 5.0, shaft.w),
				Vector2(shaft.z + drift * 0.6 - wide * 5.0, shaft.w),
			]), Color(0.68, 0.77, 0.72, 0.0065))
	# Soft local canopy shadows move in position, never global brightness.
	for shade in [Vector2(375, 235), Vector2(1708, 213)]:
		draw_texture_rect(FOG, Rect2(shade + Vector2(drift * 0.8, 0), Vector2(150, 48)), false, Color(0.10, 0.16, 0.13, 0.24))


func _draw_spray() -> void:
	for i in 38:
		var age := fposmod(clock * (0.21 + float(i % 4) * 0.04) + float(i) * 0.231, 1.0)
		var x := 1597.0 + float((i * 37) % 112) + sin(clock * 0.59 + i) * 2.0
		var y := 485.0 + age * 116.0
		var alpha := pow(sin(PI * age), 2.0) * 0.27
		draw_circle(Vector2(x, y), 0.75 if i % 3 else 1.05, Color(0.78, 0.89, 0.87, alpha))
