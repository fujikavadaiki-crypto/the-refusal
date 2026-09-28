extends Node2D
## Sparse local motion layered over the unchanged approved composition.

const TAU_VALUE := PI * 2.0
const FOG: Texture2D = preload("res://assets/biomes/forest/approved/layers/fog_puff.png")
const CUTOUT_DIR := "res://assets/biomes/forest/approved/layers/vegetation_cutouts/"

var loop_phase := 0.0
var swaying_pivots: Array[Node2D] = []


func _ready() -> void:
	# Only small leaf or vine tips are duplicated. The underlying trunks,
	# arches, platforms and approved painting never move.
	var entries := [
		["arch_vine_center_tail", Vector2(148, 190), Vector2(139, 184)],
		["arch_vine_right_tail", Vector2(165, 176), Vector2(157, 170)],
		["trunk_vine_tail", Vector2(781, 169), Vector2(772, 163)],
		["floating_moss_left_tip", Vector2(732, 333), Vector2(723, 328)],
		["floating_moss_right_tip", Vector2(807, 333), Vector2(798, 327)],
		["waterfall_moss_tip", Vector2(1509, 419), Vector2(1500, 414)],
		["right_ledge_moss_tip", Vector2(1807, 295), Vector2(1797, 290)],
	]
	for entry in entries:
		var pivot := Node2D.new()
		pivot.name = str(entry[0])
		pivot.position = entry[1]
		add_child(pivot)
		var leaf := Sprite2D.new()
		leaf.texture = load(CUTOUT_DIR + str(entry[0]) + ".png")
		leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		leaf.centered = false
		leaf.position = entry[2] - entry[1]
		leaf.modulate.a = 0.68
		pivot.add_child(leaf)
		swaying_pivots.append(pivot)
	set_loop_phase(0.0)


func set_loop_phase(value: float) -> void:
	loop_phase = fposmod(value, 1.0)
	for i in swaying_pivots.size():
		var harmonic := 1.0 if i % 3 != 0 else 2.0
		var offset := float(i) * 0.71
		swaying_pivots[i].rotation = deg_to_rad(0.65) * sin(TAU_VALUE * harmonic * loop_phase + offset)
	queue_redraw()


func _draw() -> void:
	_draw_light()
	_draw_canopy_shadow()
	_draw_fog()
	_draw_air_particles()
	_draw_leaves()


func _draw_light() -> void:
	# Localized shafts shift a few pixels sideways; their intensity is fixed.
	var wind := sin(TAU_VALUE * loop_phase)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1390 + wind * 2.0, 35), Vector2(1414 + wind * 2.0, 35),
		Vector2(1338 + wind * 3.0, 330), Vector2(1310 + wind * 3.0, 330)
	]), Color(0.76, 0.81, 0.73, 0.011))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1532 - wind * 1.5, 44), Vector2(1547 - wind * 1.5, 44),
		Vector2(1481 - wind * 2.0, 325), Vector2(1465 - wind * 2.0, 325)
	]), Color(0.72, 0.79, 0.73, 0.009))


func _draw_canopy_shadow() -> void:
	# Small soft shade shifts over foliage, without tinting the whole frame.
	var wind := sin(TAU_VALUE * loop_phase)
	draw_texture_rect(FOG, Rect2(Vector2(293 + wind * 3.0, 188), Vector2(150, 54)), false, Color(0.10, 0.15, 0.12, 0.25))
	draw_texture_rect(FOG, Rect2(Vector2(1668 - wind * 2.0, 149), Vector2(128, 45)), false, Color(0.10, 0.15, 0.12, 0.19))


func _draw_fog() -> void:
	# The texture has a soft organic alpha shape and stays below ~4% opacity.
	var breath := sin(TAU_VALUE * loop_phase)
	draw_texture_rect(FOG, Rect2(Vector2(1539 + breath * 5.0, 556), Vector2(180, 62)), false, Color(0.77, 0.84, 0.84, 0.80))
	draw_texture_rect(FOG, Rect2(Vector2(1595 - breath * 4.0, 450), Vector2(144, 48)), false, Color(0.76, 0.83, 0.83, 0.46))
	draw_texture_rect(FOG, Rect2(Vector2(925 + breath * 3.0, 540), Vector2(220, 64)), false, Color(0.73, 0.81, 0.80, 0.40))


func _draw_air_particles() -> void:
	for i in 34:
		var index := float(i)
		var x := 66.0 + fposmod(index * 307.0, 1768.0)
		var y := 86.0 + fposmod(index * 137.0, 435.0)
		var drift := Vector2(
			3.0 * sin(TAU_VALUE * loop_phase + index * 1.37),
			2.0 * sin(TAU_VALUE * (1.0 if i % 2 == 0 else 2.0) * loop_phase + index)
		)
		draw_circle(Vector2(x, y) + drift, 0.55 if i % 4 else 0.85, Color(0.66, 0.74, 0.68, 0.18))
	# A few droplets remain close to the actual cascade.
	for i in 12:
		var travel := fposmod(loop_phase * 4.0 + float(i) * 0.27, 1.0)
		var alpha := sin(PI * travel) * 0.19
		var point := Vector2(1608 + float(i % 6) * 14.0, 484 + travel * 113.0)
		draw_circle(point, 0.7, Color(0.75, 0.86, 0.86, alpha))


func _draw_leaves() -> void:
	# Each path begins and ends invisibly. Wrapping cannot pop at the seam.
	for i in 15:
		var index := float(i)
		var travel := fposmod(loop_phase + index * 0.173, 1.0)
		var alpha := pow(sin(PI * travel), 2.0) * (0.17 if i % 4 else 0.23)
		var base := Vector2(90.0 + fposmod(index * 311.0, 1720.0), 105.0 + fposmod(index * 91.0, 353.0))
		var point := base + Vector2(85.0 * travel, 17.0 * travel + sin(TAU_VALUE * travel) * 3.0)
		var turn := sin(TAU_VALUE * loop_phase + index * 0.83) * 1.4
		var leaf := PackedVector2Array([
			point + Vector2(-2.1, 0.0), point + Vector2(0.0, -1.0 + turn * 0.2),
			point + Vector2(2.0, 0.0), point + Vector2(0.0, 1.0 + turn * 0.2)
		])
		draw_colored_polygon(leaf, Color(0.43, 0.54, 0.38, alpha))
