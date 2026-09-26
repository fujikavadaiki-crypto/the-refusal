extends Node2D

const LAYER_ROOT := "res://assets/biomes/forest/approved/layers/"
const PANEL_SCALE := Vector2(0.684211, 0.684044)


func _ready() -> void:
    _create_plane("DistantForest", "far", -14, 0.88, 0.08)
    _create_plane("MiddleRuins", "middle", -9, 0.985, 0.01)
    _create_plane("GroundsideArchitecture", "near", -4, 1.0, 0.0)
    _create_plane("CanopyInFront", "canopy", 4, 0.995, 0.0)
    var floor_plane := Node2D.new()
    floor_plane.name = "PlayableStoneAndRoots"
    floor_plane.z_index = 1
    add_child(floor_plane)
    for i in range(3):
        _sprite(floor_plane, ["a", "b", "c"][i] + "_ground.png", i * 1300)
    _add_stone_pier("A", 578.0, 170.0, 44.0)
    _add_stone_pier("B", 1870.0, 171.0, 44.0)
    var atmosphere := Node2D.new()
    atmosphere.name = "LivingMistLeavesAndWater"
    atmosphere.set_script(load("res://scripts/biomes/forest/forest_living_atmosphere.gd"))
    add_child(atmosphere)


func _create_plane(plane_name: String, suffix: String, layer_z: int, speed: float, vertical: float) -> void:
    var plane := Node2D.new()
    plane.name = plane_name
    plane.z_index = layer_z
    plane.set_script(load("res://scripts/biomes/forest/forest_depth_plane.gd"))
    plane.set("depth_speed", speed)
    plane.set("vertical_speed", vertical)
    add_child(plane)
    for i in range(3):
        _sprite(plane, ["a", "b", "c"][i] + "_" + suffix + ".png", i * 1300)


func _sprite(parent: Node2D, filename: String, world_x: int) -> void:
    var sprite := Sprite2D.new()
    sprite.name = filename.get_basename()
    sprite.texture = load(LAYER_ROOT + filename) as Texture2D
    sprite.position = Vector2(world_x, -45)
    sprite.scale = PANEL_SCALE
    sprite.centered = false
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    parent.add_child(sprite)


func _add_stone_pier(letter: String, top_x: float, top_y: float, width: float) -> void:
    var pier := StaticBody2D.new()
    pier.name = "PlayablePaintedPier" + letter
    pier.collision_layer = 1
    pier.collision_mask = 0
    pier.position = Vector2(top_x, top_y)
    add_child(pier)
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(width, 4)
    var shape := CollisionShape2D.new()
    shape.shape = rectangle
    shape.one_way_collision = true
    pier.add_child(shape)
