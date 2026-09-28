extends Node2D

## Only tiny distal leaf clusters and hanging strand tips move. Attachment points
## stay fixed on the complete approved painting beneath them.
@export var foreground_pass := true

const MANIFEST := "res://assets/biomes/forest/approved/layers/vegetation_cutouts/regions.json"
const TEXTURE_ROOT := "res://assets/biomes/forest/approved/layers/vegetation_cutouts/"

var clock := 0.0
var wind: Node
var patches: Array[Dictionary] = []


func _ready() -> void:
    wind = get_tree().get_first_node_in_group("bosque_wind")
    var file := FileAccess.open(MANIFEST, FileAccess.READ)
    if file == null:
        push_error("Missing Bosque B vegetation cutout manifest")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Array:
        push_error("Invalid Bosque B vegetation cutout manifest")
        return
    for data in parsed:
        var group: String = data["group"]
        if foreground_pass != (group == "vine" or group == "moss" or group == "near"):
            continue
        var pivot_data: Array = data["pivot"]
        var box_data: Array = data["box"]
        var pivot := Vector2(float(pivot_data[0]), float(pivot_data[1]))
        var anchor := Node2D.new()
        anchor.name = String(data["name"]).to_pascal_case()
        anchor.position = pivot
        add_child(anchor)
        var art := Sprite2D.new()
        art.name = "ApprovedArtCutout"
        art.texture = load(TEXTURE_ROOT + String(data["name"]) + ".png") as Texture2D
        art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        art.centered = false
        art.position = Vector2(float(box_data[0]), float(box_data[1])) - pivot
        anchor.add_child(art)
        patches.append({"node":anchor, "pivot":pivot, "group":group, "index":patches.size()})


func _process(delta: float) -> void:
    clock += delta
    for patch in patches:
        var index: int = patch["index"]
        var group: String = patch["group"]
        var node: Node2D = patch["node"]
        var pivot: Vector2 = patch["pivot"]
        var delay := float(index % 5) * 0.27 + (0.24 if group == "moss" else 0.0)
        var phase := float(index) * 1.37
        var gust := float(wind.call("gust", delay)) if wind != null else 0.0
        var wave := sin(clock * (0.67 + float(index % 4) * 0.09) + phase)
        var secondary := sin(clock * 1.19 + phase * 1.23) * 0.22
        var degrees := 2.6 if group == "canopy" else 4.0 if group == "vine" else 3.5 if group == "moss" else 1.7
        node.position = pivot
        node.rotation = deg_to_rad((wave + secondary) * degrees * (0.35 + gust * 1.25))
        node.scale = Vector2.ONE
