extends Node2D

## Older rooms retain the GIF/atlas presentation; the playable Bosque uses the
## explicitly approved Carrasco board for every visible pose.
const MARK := preload("res://scripts/player/visuals/condemnation_mark.gd")
const ATLAS := preload("res://assets/characters/carrasco_base_gameplay/atlas.png")
const MANIFEST_PATH := "res://assets/characters/carrasco_base_gameplay/frames.json"
const GIF_ROOT := "res://assets/characters/carrasco_gif_test"
const GIF_MANIFEST_PATH := GIF_ROOT + "/frames.json"
const APPROVED_SHEET := preload("res://assets/characters/carrasco_approved_board/sheet.png")
const APPROVED_MANIFEST := "res://assets/characters/carrasco_approved_board/frames.json"
const JUDGMENT := Color("#a4553e")
const BONE := Color("#c7b9a0")

@onready var sprite: Sprite2D = $Sprite
@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

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
var gif_frame_textures: Dictionary = {}
var gif_fps: Dictionary = {}
var gif_foot_y: Dictionary = {}
var atlas_offset := Vector2.ZERO
var approved_board_mode := false
var approved_frame_textures: Dictionary = {}
var approved_offset := Vector2.ZERO


func _ready() -> void:
    if approved_board_mode:
        _load_approved_frames()
    else:
        _load_frames()
        _load_gif_frames()
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
    atlas_offset = Vector2(-int(parsed["pivot_x"]), -int(parsed["pivot_y"]))
    sprite.offset = atlas_offset
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


func _load_gif_frames() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GIF_MANIFEST_PATH))
    if not parsed is Dictionary or not parsed.has("animations"):
        push_error("Carrasco GIF frame manifest is missing or invalid")
        return
    for animation in parsed["animations"]:
        var data: Dictionary = parsed["animations"][animation]
        var textures: Array[Texture2D] = []
        for index in range(int(data["frames"])):
            var path := "%s/%s/frame_%02d.png" % [GIF_ROOT, animation, index]
            var texture := load(path) as Texture2D
            if texture == null:
                push_error("Carrasco GIF frame missing: " + path)
                return
            textures.append(texture)
        gif_frame_textures[animation] = textures
        gif_fps[animation] = float(data["fps"])
        gif_foot_y[animation] = data["foot_y_by_frame"]


func _sync_sprite() -> void:
    var animation := String(pose)
    if pose == &"charge" and charged_ready:
        animation = "charge_ready"
    if approved_board_mode:
        _sync_approved_sprite(animation)
        return
    if _sync_gif_sprite(animation):
        return
    if not frame_textures.has(animation):
        animation = "idle"
    if not frame_textures.has(animation):
        return
    var textures: Array = frame_textures[animation]
    var frame := _frame_index(animation, textures.size())
    sprite.scale.x = 1.0
    sprite.offset = atlas_offset
    sprite.texture = textures[frame]


func _load_approved_frames() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPROVED_MANIFEST))
    if not parsed is Dictionary or not parsed.has("animations"):
        push_error("Approved Carrasco board manifest is missing or invalid")
        return
    var cell_width: int = parsed["cell_width"]
    var cell_height: int = parsed["cell_height"]
    var columns: int = parsed["columns"]
    approved_offset = Vector2(-int(parsed["pivot_x"]), -int(parsed["pivot_y"]))
    for animation in parsed["animations"]:
        var textures: Array[AtlasTexture] = []
        for raw_index in parsed["animations"][animation]:
            var index: int = raw_index
            var texture := AtlasTexture.new()
            texture.atlas = APPROVED_SHEET
            texture.region = Rect2((index % columns) * cell_width, (index / columns) * cell_height, cell_width, cell_height)
            textures.append(texture)
        approved_frame_textures[animation] = textures


func _sync_approved_sprite(animation: String) -> void:
    var clip := animation
    match animation:
        "walk":
            clip = "run"
        "hit":
            clip = "hurt"
        "carrasco_light_1", "carrasco_marca":
            clip = "light_1"
        "carrasco_light_2":
            clip = "light_2"
        "carrasco_light_3", "carrasco_quebra_selos":
            clip = "light_3"
        "carrasco_heavy", "charge", "charge_ready":
            clip = "heavy"
        "carrasco_charged_heavy":
            clip = "charged_heavy"
        "carrasco_post_dodge", "carrasco_dash_light":
            clip = "post_dodge"
        "carrasco_air_light":
            clip = "air_light"
        "carrasco_air_heavy":
            clip = "air_heavy"
        "tribunal_activate", "execution", "execution_strike":
            clip = "charged_heavy"
    if not approved_frame_textures.has(clip):
        clip = "idle"
    var textures: Array = approved_frame_textures.get(clip, [])
    if textures.is_empty():
        return
    var frame := 0
    if animation.begins_with("carrasco_"):
        var count := textures.size()
        var windup := maxi(1, count / 3)
        var active := maxi(1, count / 3)
        var start := 0
        var span := windup
        if attack_phase == PlayerCombat.Phase.ACTIVE:
            start = windup
            span = active
        elif attack_phase == PlayerCombat.Phase.RECOVERY:
            start = windup + active
            span = maxi(1, count - start)
        frame = clampi(start + mini(int(attack_progress * span), span - 1), 0, count - 1)
    elif clip == "idle":
        frame = int(pose_clock * 4.0) % textures.size()
    elif clip == "run":
        frame = int(pose_clock * 12.0) % textures.size()
    elif clip == "death" or clip == "hurt" or clip == "ruptured":
        frame = mini(int(pose_clock * 9.0), textures.size() - 1)
    else:
        frame = int(pose_clock * 12.0) % textures.size()
    sprite.texture = textures[frame]
    sprite.offset = approved_offset
    sprite.scale.x = 1.0


func _sync_gif_sprite(animation: String) -> bool:
    var clip := animation
    match animation:
        "run":
            clip = "run_west" if player.facing_direction < 0 else "run_east"
        "walk":
            clip = "walk_east"
        "jump", "fall":
            clip = "jump_east"
    if not gif_frame_textures.has(clip):
        return false
    var textures: Array = gif_frame_textures[clip]
    var rate: float = gif_fps[clip]
    var frame := int(pose_clock * rate) % textures.size()
    if animation == "jump":
        frame = mini(int(pose_clock * rate), 4)
    elif animation == "fall":
        frame = 5 + mini(int(pose_clock * rate), textures.size() - 6)
    sprite.texture = textures[frame]
    sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -float(gif_foot_y[clip][frame]))
    sprite.scale.x = -1.0 if clip == "run_west" else 1.0
    return true


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
