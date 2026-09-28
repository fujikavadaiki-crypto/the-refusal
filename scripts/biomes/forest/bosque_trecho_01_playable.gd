extends Node2D

const CARRASCO := preload("res://data/masks/carrasco_base.tres")

# The PixelLab background is visual only. These authored rectangles and bridge
# placements define the surfaces the player can touch.
const START := Vector2(109, 451)
const FLOOR_RECTS := [
    Rect2(0, 464, 592, 160),
    Rect2(752, 464, 480, 160),
    Rect2(1392, 464, 528, 160),
]
const PLATFORM_RECTS := [
    Rect2(304, 368, 160, 32),
    Rect2(880, 368, 96, 32),
    Rect2(1584, 368, 96, 32),
]
const BRIDGE_RECTS := [
    Rect2(608, 462, 128, 8),
    Rect2(1248, 462, 128, 8),
]

const TILES := "res://assets/biomes/forest/pixellab_tiles/"
const PATH_FOREST := TILES + "narrow_ruined_forest_passage_with_compact_earth_c.png"
const PATH_WOOD := TILES + "weathered_wooden_walkway_path_with_old_planks_dam.png"
const PATH_STONE := TILES + "ruined_bridge_path_with_stone_supports_and_broken.png"
const BUILDING_WOOD := TILES + "rotting_dark_wooden_supports_with_damp_age_moss_b.png"
const BUILDING_STONE := TILES + "weathered_sacred_stone_wall_with_gothic_carvings_.png"
const FENCE := TILES + "old_broken_fence_section_made_of_dark_wood_and_rus.png"

@onready var map: Node2D = $PixelLabMap
@onready var player: CharacterBody2D = $Player
@onready var details: Node2D = $ModularDetails
@onready var geometry: Node2D = $GameplayGeometry

var safe_position := START
var fall_count := 0
var reached_exit := false


func _ready() -> void:
    var export_camera := map.get_node_or_null("Camera2D") as Camera2D
    if export_camera != null:
        export_camera.enabled = false
    var background := map.get_node_or_null("Background") as CanvasItem
    if background != null:
        background.modulate = Color(0.76, 0.79, 0.82, 1.0)

    _build_geometry()
    _place_modular_art()

    player.global_position = START
    player.velocity = Vector2.ZERO
    player.z_index = 5
    player.get_node("MaskController").equip(0, CARRASCO)
    player.get_node("VisualRoot").position.y = 13.0
    var camera := player.get_node("Camera2D") as Camera2D
    camera.limit_left = 0
    camera.limit_right = 1920
    camera.limit_top = 0
    camera.limit_bottom = 640
    camera.position.y = -65
    camera.zoom = Vector2.ONE
    camera.make_current()
    var debug_label := player.get_node_or_null("DebugLabel") as CanvasItem
    if debug_label != null:
        debug_label.visible = false


func _physics_process(_delta: float) -> void:
    if player.is_on_floor() and player.global_position.x > 40 and player.global_position.x < 1850:
        safe_position = player.global_position
    if player.global_position.y > 680:
        fall_count += 1
        player.global_position = safe_position
        player.velocity = Vector2.ZERO
    if not reached_exit and player.global_position.x >= 1814:
        reached_exit = true
        print("BOSQUE_TRECHO_01_EXIT_REACHED falls=%d" % fall_count)


func _build_geometry() -> void:
    for i in range(FLOOR_RECTS.size()):
        _solid_rect("Ground%d" % i, FLOOR_RECTS[i], false)
    for i in range(PLATFORM_RECTS.size()):
        _solid_rect("Platform%d" % i, PLATFORM_RECTS[i], true)
    for i in range(BRIDGE_RECTS.size()):
        _solid_rect("Bridge%d" % i, BRIDGE_RECTS[i], true)


func _solid_rect(label: String, rect: Rect2, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.name = label
    body.collision_layer = 1
    body.collision_mask = 0
    body.position = rect.get_center()
    geometry.add_child(body)
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = rect.size
    shape.shape = rectangle
    shape.one_way_collision = one_way
    body.add_child(shape)


func _place_modular_art() -> void:
    # PATHS: selected side-view cells from the user's original PixelLab sheets.
    for segment in [Vector2i(32, 544), Vector2i(768, 1184), Vector2i(1408, 1856)]:
        var cell := 0
        for x in range(segment.x, segment.y, 64):
            _atlas_piece("ForestPath", PATH_FOREST, cell % 4, 0, Vector2(x + 32, 466), 1)
            cell += 1
    _atlas_piece("WoodBridgePathA", PATH_WOOD, 1, 0, Vector2(640, 466), 2)
    _atlas_piece("WoodBridgePathB", PATH_WOOD, 2, 0, Vector2(704, 466), 2)
    _atlas_piece("StoneBridgePathA", PATH_STONE, 1, 0, Vector2(1280, 466), 2)
    _atlas_piece("StoneBridgePathB", PATH_STONE, 2, 0, Vector2(1344, 466), 2)
    for x in [336, 400, 912, 1616]:
        _atlas_piece("RaisedStonePath", PATH_STONE, 0, 0, Vector2(x, 370), 2)

    # BUILDINGS are visible supports and ruin details, with no collision of
    # their own. The authored path/bridge bodies above control gameplay.
    _atlas_piece("WoodSupportA", BUILDING_WOOD, 1, 0, Vector2(640, 516), 0)
    _atlas_piece("WoodSupportB", BUILDING_WOOD, 2, 0, Vector2(704, 516), 0)
    _atlas_piece("StoneBridgeSupport", BUILDING_STONE, 1, 0, Vector2(1312, 516), 0)
    _atlas_piece("StoneSupportA", BUILDING_STONE, 1, 0, Vector2(368, 415), 0)
    _atlas_piece("StoneSupportB", BUILDING_STONE, 2, 0, Vector2(944, 415), 0)
    _atlas_piece("BrokenFenceA", FENCE, 1, 1, Vector2(224, 450), 3)
    _atlas_piece("BrokenFenceB", FENCE, 2, 1, Vector2(1120, 450), 3)
    _atlas_piece("BrokenFenceC", FENCE, 3, 1, Vector2(1728, 450), 3)


func _atlas_piece(label: String, image_path: String, column: int, row: int, at: Vector2, depth: int) -> void:
    var image := load(image_path) as Texture2D
    if image == null:
        push_error("PixelLab tile is missing: %s" % image_path)
        return
    var region := AtlasTexture.new()
    region.atlas = image
    region.region = Rect2(column * 65, row * 65, 64, 64)
    region.filter_clip = true
    var piece := Sprite2D.new()
    piece.name = label
    piece.texture = region
    piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    piece.position = at
    piece.z_index = depth
    details.add_child(piece)
