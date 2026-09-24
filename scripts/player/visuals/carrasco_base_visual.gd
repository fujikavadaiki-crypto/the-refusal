extends Node2D

## Native 64x48 tiles with a 31 px body. Animation only reads gameplay state.
const MARK := preload("res://scripts/player/visuals/condemnation_mark.gd")
const ATLAS := preload("res://assets/characters/carrasco_base_gameplay/atlas.png")
const MANIFEST_PATH := "res://assets/characters/carrasco_base_gameplay/frames.json"
const JUDGMENT := Color("#a4553e")
const BONE := Color("#c7b9a0")

@onready var sprite: Sprite2D = $Sprite

var runtime: CarrascoRuntimeState
var marks: Dictionary = {}
var pose: StringName = &"idle"
var attack_phase := PlayerCombat.Phase.IDLE
var attack_progress := 0.0
var charged_ready := false
var tribunal := false
var pose_clock := 0.0
var clock := 0.0
var frame_textures: Dictionary = {}


func _ready() -> void:
    _load_frames()
    _sync_sprite()


func bind_runtime(state: MaskRuntimeState) -> void:
    runtime = state as CarrascoRuntimeState


func set_pose(next_pose: StringName, phase: int, progress: float, ready: bool, ultimate: bool) -> void:
    if pose != next_pose or charged_ready != ready:
        pose_clock = 0.0
    pose = next_pose
    attack_phase = phase
    attack_progress = clampf(progress, 0.0, 1.0)
    charged_ready = ready
    tribunal = ultimate


func _process(delta: float) -> void:
    clock += delta
    pose_clock += delta
    _sync_sprite()
    _sync_marks()
    queue_redraw()


func _exit_tree() -> void:
    for mark in marks.values():
        if is_instance_valid(mark):
            mark.queue_free()
    marks.clear()


func _load_frames() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if not parsed is Dictionary or not parsed.has("animations"):
        push_error("Carrasco frame manifest is missing or invalid")
        return
    var tile_width: int = parsed["tile_width"]
    var tile_height: int = parsed["tile_height"]
    var columns: int = parsed["columns"]
    sprite.offset = Vector2(-int(parsed["pivot_x"]), -int(parsed["pivot_y"]))
    sprite.position = Vector2(0, 13)
    for animation in parsed["animations"]:
        var textures: Array[AtlasTexture] = []
        for raw_index in parsed["animations"][animation]:
            var index: int = raw_index
            var texture := AtlasTexture.new()
            texture.atlas = ATLAS
            texture.region = Rect2((index % columns) * tile_width, (index / columns) * tile_height, tile_width, tile_height)
            textures.append(texture)
        frame_textures[animation] = textures


func _sync_sprite() -> void:
    var animation := String(pose)
    if pose == &"charge" and charged_ready:
        animation = "charge_ready"
    if not frame_textures.has(animation):
        animation = "idle"
    if not frame_textures.has(animation):
        return
    var textures: Array = frame_textures[animation]
    var frame := _frame_index(animation, textures.size())
    sprite.texture = textures[frame]


func _frame_index(animation: String, count: int) -> int:
    if animation.begins_with("carrasco_"):
        var windup := 2
        var active := 1
        if animation == "carrasco_heavy":
            windup = 3
        elif animation == "carrasco_charged_heavy" or animation == "carrasco_air_heavy":
            active = 2
        var start := 0
        var span := windup
        if attack_phase == PlayerCombat.Phase.ACTIVE:
            start = windup
            span = active
        elif attack_phase == PlayerCombat.Phase.RECOVERY:
            start = windup + active
            span = count - start
        return clampi(start + mini(int(attack_progress * span), span - 1), 0, count - 1)
    if animation == "idle":
        return int(pose_clock * 4.0) % count
    if animation == "run":
        return int(pose_clock * 12.0) % count
    if animation == "charge" or animation == "charge_ready":
        return int(pose_clock * 6.0) % count
    if animation == "ruptured":
        return int(pose_clock * 5.0) % count
    var rate := 16.0
    if animation == "execution" or animation == "execution_strike":
        rate = 26.0
    elif animation == "death":
        rate = 9.0
    return mini(int(pose_clock * rate), count - 1)


func _sync_marks() -> void:
    if runtime == null:
        return
    for key in marks.keys():
        var mark: Node2D = marks[key]
        if not is_instance_valid(mark) or not runtime.targets.has(key):
            if is_instance_valid(mark):
                mark.queue_free()
            marks.erase(key)
    for key in runtime.targets.keys():
        var entry: Dictionary = runtime.targets[key]
        var target: Node = entry.ref.get_ref()
        if target == null or not is_instance_valid(target) or not target is Node2D:
            continue
        var stacks := runtime.stacks_for(target)
        if stacks <= 0:
            if marks.has(key):
                marks[key].queue_free()
                marks.erase(key)
            continue
        if not marks.has(key):
            var mark := Node2D.new()
            mark.set_script(MARK)
            target.add_child(mark)
            mark.position = Vector2(0, -29)
            marks[key] = mark
        marks[key].set_stacks(stacks)


func _draw() -> void:
    if not tribunal:
        return
    var pulse := int(clock * 10.0) % 3
    draw_rect(Rect2(-19, -8 + pulse, 2, 9), JUDGMENT)
    draw_rect(Rect2(-16, -12 + pulse, 5, 1), BONE)
    draw_rect(Rect2(18, -11 + pulse, 2, 9), JUDGMENT)
    draw_rect(Rect2(13, -13 + pulse, 5, 1), BONE)
    draw_rect(Rect2(-3, -22, 6, 1), JUDGMENT)
    draw_rect(Rect2(-1, -24, 2, 2), BONE)
