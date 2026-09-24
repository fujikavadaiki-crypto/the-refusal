extends Node2D

## Interchangeable Base presentation. Gameplay timings and hitboxes live elsewhere.
const MARK := preload("res://scripts/player/visuals/condemnation_mark.gd")
const FRAME_IDLE := preload("res://assets/characters/carrasco_base/idle.png")
const FRAME_RUN := preload("res://assets/characters/carrasco_base/run.png")
const FRAME_LIGHT_1 := preload("res://assets/characters/carrasco_base/light_1.png")
const FRAME_HEAVY := preload("res://assets/characters/carrasco_base/heavy.png")
const CLOTH_LIGHT := Color("46413c")
const ARMOR := Color("584b40")
const BONE := Color("b9a992")
const JUDGMENT := Color("a4553e")

@onready var sprite: Sprite2D = $Sprite

var runtime: CarrascoRuntimeState
var marks: Dictionary = {}
var pose: StringName = &"idle"
var attack_phase := PlayerCombat.Phase.IDLE
var attack_progress := 0.0
var charged_ready := false
var tribunal := false
var clock := 0.0


func _ready() -> void:
    _sync_sprite()


func bind_runtime(state: MaskRuntimeState) -> void:
    runtime = state as CarrascoRuntimeState


func set_pose(next_pose: StringName, phase: int, progress: float, ready: bool, ultimate: bool) -> void:
    if pose != next_pose or attack_phase != phase or charged_ready != ready or tribunal != ultimate:
        pose = next_pose
        attack_phase = phase
        charged_ready = ready
        tribunal = ultimate
    attack_progress = progress
    queue_redraw()


func _process(delta: float) -> void:
    clock += delta
    _sync_sprite()
    _sync_marks()
    queue_redraw()


func _exit_tree() -> void:
    for mark in marks.values():
        if is_instance_valid(mark):
            mark.queue_free()
    marks.clear()


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
    _draw_sprite_effects()


func _sync_sprite() -> void:
    var frame: Texture2D = FRAME_IDLE
    var source_anchor := Vector2(555.0, 1250.0)
    var image_scale := 0.027
    var rotation := 0.0
    var offset := Vector2(0, 13)
    if pose in [&"run", &"ground_dash", &"air_dash", &"jump", &"fall"]:
        frame = FRAME_RUN
        source_anchor = Vector2(1070.0, 930.0)
        image_scale = 0.040
        if pose == &"run":
            offset.y += int(clock * 11.0) % 2
        elif pose in [&"ground_dash", &"air_dash"]:
            rotation = -5.0
            offset.x += 2
        elif pose == &"jump":
            rotation = -12.0
            offset.y -= 1
        elif pose == &"fall":
            rotation = 6.0
    elif pose == &"execution":
        frame = FRAME_HEAVY
        source_anchor = Vector2(660.0, 930.0)
        image_scale = 0.038
    elif pose.begins_with("carrasco_") and attack_phase == PlayerCombat.Phase.ACTIVE:
        if pose in [&"carrasco_light_1", &"carrasco_light_2", &"carrasco_post_dodge", &"carrasco_air_light", &"carrasco_marca"]:
            frame = FRAME_LIGHT_1
            source_anchor = Vector2(530.0, 930.0)
            image_scale = 0.036
            if pose == &"carrasco_light_2":
                rotation = -26.0
                offset.y -= 6
            elif pose == &"carrasco_air_light":
                rotation = -6.0
            else:
                offset.x += 2
        else:
            frame = FRAME_HEAVY
            source_anchor = Vector2(660.0, 930.0)
            image_scale = 0.038
            if pose == &"carrasco_air_heavy":
                rotation = -9.0
            elif pose == &"carrasco_light_3":
                image_scale = 0.035
                rotation = 9.0
                offset.y -= 3
            elif pose == &"carrasco_charged_heavy":
                offset.x += 2
    elif pose.begins_with("carrasco_") and attack_phase == PlayerCombat.Phase.WINDUP:
        rotation = -5.0 if pose.contains("heavy") or pose.contains("quebra") else -2.0
        offset.y += 1
    elif pose == &"charge":
        rotation = -5.0
        offset.y += 1
    elif pose == &"hit" or pose == &"ruptured":
        rotation = 9.0
    elif pose == &"death":
        rotation = -90.0
    sprite.texture = frame
    sprite.offset = -source_anchor
    sprite.scale = Vector2(image_scale, image_scale)
    sprite.position = offset
    sprite.rotation_degrees = rotation
    sprite.modulate = Color.WHITE
    if pose == &"hit" or pose == &"ruptured":
        sprite.modulate = Color("e9a989")
    elif (pose == &"charge" and charged_ready) or pose == &"carrasco_charged_heavy":
        sprite.modulate = Color("ffe1b5")
    elif tribunal:
        sprite.modulate = Color(1.2, 1.0, 0.85)


func _draw_sprite_effects() -> void:
    var pulse := int(clock * 10.0) % 4
    if pose in [&"ground_dash", &"air_dash"]:
        _rect(-21, -4, 7, 1, CLOTH_LIGHT)
        _rect(-25, 2, 5, 1, ARMOR)
    if pose == &"charge":
        var charge_color := BONE if charged_ready else JUDGMENT
        _rect(12, -12, 2, 2, charge_color)
        _rect(17, -19, 2, 2, charge_color)
        if charged_ready:
            _rect(23, -8, 2, 2, charge_color)
            _rect(-10, -21, 2, 2, charge_color)
    if tribunal:
        _rect(-19, -19 + pulse, 2, 8, JUDGMENT)
        _rect(-16, -23 + pulse, 5, 1, BONE)
        _rect(17, -23 + pulse, 2, 9, JUDGMENT)
        _rect(12, -25 + pulse, 5, 1, BONE)
        _rect(-16, 4 - pulse, 4, 1, JUDGMENT)
        _rect(13, 3 - pulse, 4, 1, JUDGMENT)
        _rect(-4, -28, 8, 1, JUDGMENT)
        _rect(-1, -30, 2, 2, BONE)
    if attack_phase != PlayerCombat.Phase.ACTIVE:
        return
    match pose:
        &"carrasco_light_1", &"carrasco_post_dodge":
            _rect(38, -10, 2, 2, JUDGMENT)
        &"carrasco_light_2":
            _rect(31, -24, 2, 2, BONE)
        &"carrasco_light_3":
            _rect(30, -6, 3, 2, JUDGMENT)
        &"carrasco_charged_heavy":
            _rect(34, -8, 3, 2, BONE)
        &"carrasco_quebra_selos":
            _rect(32, -7, 3, 3, JUDGMENT)
        &"carrasco_marca":
            _rect(38, -13, 3, 3, JUDGMENT)


func _rect(x: int, y: int, w: int, h: int, color: Color) -> void:
    draw_rect(Rect2(x, y, w, h), color)
