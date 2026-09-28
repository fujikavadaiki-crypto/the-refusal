extends Node2D

## The same approved pixels are articulated by Bone2D nodes. Presentation only.
const PART_ROOT := "res://assets/characters/carrasco_modular/parts/"
const MARK := preload("res://scripts/player/visuals/condemnation_mark.gd")
const PARTS := {
    "core_underlay": ["Pelvis", Vector2(128, 128), -8],
    "torso": ["Torso", Vector2(129, 94), 0],
    "head": ["Head", Vector2(132, 59), 4],
    "upper_arm_left": ["ArmLeft", Vector2(101, 76), 2],
    "forearm_left": ["ForearmLeft", Vector2(91, 102), 3],
    "hand_left": ["HandLeft", Vector2(88, 124), 5],
    "upper_arm_right": ["ArmRight", Vector2(154, 91), 1],
    "forearm_right": ["ForearmRight", Vector2(158, 111), 2],
    "hand_right": ["HandRight", Vector2(160, 129), 3],
    "cape_left": ["CapeLeft", Vector2(97, 98), -5],
    "cape_right": ["CapeRight", Vector2(154, 103), -4],
    "chain_left": ["ChainLeft", Vector2(117, 117), 6],
    "chain_right": ["ChainRight", Vector2(146, 121), 6],
    "front_cloth": ["FrontCloth", Vector2(130, 115), 4],
    "thigh_left": ["ThighLeft", Vector2(111, 132), -2],
    "shin_left": ["ShinLeft", Vector2(104, 174), -2],
    "boot_left": ["BootLeft", Vector2(90, 209), -2],
    "thigh_right": ["ThighRight", Vector2(145, 135), -1],
    "shin_right": ["ShinRight", Vector2(150, 176), -1],
    "boot_right": ["BootRight", Vector2(149, 210), -1],
    "axe": ["AxeBack", Vector2(88, 120), 7],
}
const BONE_PATHS := {
    "Pelvis": "Skeleton2D/Pelvis",
    "Torso": "Skeleton2D/Pelvis/Torso",
    "Head": "Skeleton2D/Pelvis/Torso/Head",
    "ArmLeft": "Skeleton2D/Pelvis/Torso/ArmLeft",
    "ForearmLeft": "Skeleton2D/Pelvis/Torso/ArmLeft/ForearmLeft",
    "HandLeft": "Skeleton2D/Pelvis/Torso/ArmLeft/ForearmLeft/HandLeft",
    "ArmRight": "Skeleton2D/Pelvis/Torso/ArmRight",
    "ForearmRight": "Skeleton2D/Pelvis/Torso/ArmRight/ForearmRight",
    "HandRight": "Skeleton2D/Pelvis/Torso/ArmRight/ForearmRight/HandRight",
    "CapeLeft": "Skeleton2D/Pelvis/Torso/CapeLeft",
    "CapeRight": "Skeleton2D/Pelvis/Torso/CapeRight",
    "ChainLeft": "Skeleton2D/Pelvis/Torso/ChainLeft",
    "ChainRight": "Skeleton2D/Pelvis/Torso/ChainRight",
    "AxeBack": "Skeleton2D/Pelvis/Torso/AxeBack",
    "FrontCloth": "Skeleton2D/Pelvis/FrontCloth",
    "ThighLeft": "Skeleton2D/Pelvis/ThighLeft",
    "ShinLeft": "Skeleton2D/Pelvis/ThighLeft/ShinLeft",
    "BootLeft": "Skeleton2D/Pelvis/ThighLeft/ShinLeft/BootLeft",
    "ThighRight": "Skeleton2D/Pelvis/ThighRight",
    "ShinRight": "Skeleton2D/Pelvis/ThighRight/ShinRight",
    "BootRight": "Skeleton2D/Pelvis/ThighRight/ShinRight/BootRight",
}

var bones: Dictionary = {}
var marks: Dictionary = {}
var runtime: CarrascoRuntimeState
var player: CharacterBody2D
var approved_board_mode := true
var pose: StringName = &"idle"
var attack_phase := PlayerCombat.Phase.IDLE
var attack_progress := 0.0
var charged_ready := false
var tribunal := false
var clock := 0.0
var gait_phase := 0.0
var axe_sprite: Sprite2D
var cloth_sprite: Sprite2D


func _enter_tree() -> void:
    # Skeleton2D needs invertible rest transforms before its children enter.
    for key in BONE_PATHS:
        var bone := get_node(BONE_PATHS[key]) as Bone2D
        bone.set_autocalculate_length_and_angle(false)
        bone.set_length(20.0)
        bone.rest = bone.transform


func _ready() -> void:
    player = get_parent().get_parent() as CharacterBody2D
    for key in BONE_PATHS:
        bones[key] = get_node(BONE_PATHS[key]) as Bone2D
    _add_joint_backing()
    for part_name in PARTS:
        var spec: Array = PARTS[part_name]
        var bone: Bone2D = bones[spec[0]]
        var sprite := Sprite2D.new()
        sprite.name = String(part_name).to_pascal_case()
        sprite.texture = load(PART_ROOT + part_name + ".png") as Texture2D
        sprite.centered = false
        sprite.position = -Vector2(spec[1])
        sprite.z_as_relative = true
        sprite.z_index = int(spec[2])
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        bone.add_child(sprite)
        if part_name == "axe":
            axe_sprite = sprite
        elif part_name == "front_cloth":
            cloth_sprite = sprite


func _add_joint_backing() -> void:
    # The approved art is one flattened pose, so its hidden sides have no
    # pixels. These small armor-colored bridges keep the joints covered when
    # their visible fragments rotate apart. They stay behind the source art.
    var skirt_backing := Polygon2D.new()
    skirt_backing.name = "HiddenSkirtBacking"
    skirt_backing.polygon = PackedVector2Array([
        Vector2(-30, -10), Vector2(28, -10), Vector2(31, 27),
        Vector2(20, 70), Vector2(10, 76), Vector2(0, 88),
        Vector2(-16, 75), Vector2(-38, 86), Vector2(-61, 66),
        Vector2(-48, 37),
    ])
    skirt_backing.color = Color("#24171c")
    skirt_backing.z_as_relative = true
    skirt_backing.z_index = -6
    skirt_backing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    (bones["Pelvis"] as Bone2D).add_child(skirt_backing)
    var links := [
        ["ArmLeft", Vector2(-10, 26), 19.0, Color("#32252a")],
        ["ForearmLeft", Vector2(-3, 22), 16.0, Color("#3e2b2d")],
        ["ArmRight", Vector2(4, 20), 18.0, Color("#32252a")],
        ["ForearmRight", Vector2(2, 18), 15.0, Color("#3e2b2d")],
        ["ThighLeft", Vector2(-7, 42), 23.0, Color("#302126")],
        ["ShinLeft", Vector2(-14, 35), 18.0, Color("#3c2b2a")],
        ["ThighRight", Vector2(5, 41), 22.0, Color("#302126")],
        ["ShinRight", Vector2(-1, 34), 18.0, Color("#3c2b2a")],
    ]
    for link in links:
        var line := Line2D.new()
        line.name = "JointBacking"
        line.points = PackedVector2Array([Vector2.ZERO, link[1]])
        line.width = float(link[2])
        line.default_color = link[3]
        line.begin_cap_mode = Line2D.LINE_CAP_ROUND
        line.end_cap_mode = Line2D.LINE_CAP_ROUND
        line.antialiased = false
        line.z_as_relative = true
        line.z_index = -7
        line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        (bones[link[0]] as Bone2D).add_child(line)


func bind_runtime(state: MaskRuntimeState) -> void:
    runtime = state as CarrascoRuntimeState


func set_pose(next_pose: StringName, phase: int, progress: float, ready: bool, ultimate: bool) -> void:
    pose = next_pose
    attack_phase = phase
    attack_progress = clampf(progress, 0.0, 1.0)
    charged_ready = ready
    tribunal = ultimate


func _process(delta: float) -> void:
    clock += delta
    _animate(delta)
    _sync_marks()
    if tribunal:
        queue_redraw()


func _animate(delta: float) -> void:
    var targets: Dictionary = {}
    var bob := 0.0
    var axe_position := Vector2(-41, 26)
    var axe_angle := 0.0
    var locomotion := pose == &"run" or pose == &"walk"
    var dashing := pose == &"ground_dash" or pose == &"air_dash"
    if locomotion:
        var speed_factor := 1.0
        if player != null:
            speed_factor = clampf(absf(player.velocity.x) / 120.0, 0.45, 1.0)
        var amplitude := 0.75 * speed_factor * (0.65 if pose == &"walk" else 1.0)
        gait_phase = wrapf(gait_phase + delta * TAU * (1.55 + 0.8 * speed_factor), 0.0, TAU)
        var stride := sin(gait_phase)
        var lift_left := maxf(0.0, sin(gait_phase + 0.3))
        var lift_right := maxf(0.0, -sin(gait_phase + 0.3))
        bob = -3.0 - 2.5 * cos(gait_phase * 2.0)
        targets = {
            "Pelvis": 0.045 * stride,
            "Torso": 0.12 + 0.045 * sin(gait_phase + 0.6),
            "Head": -0.09 - 0.025 * stride,
            "ThighLeft": -amplitude * stride,
            "ShinLeft": 0.18 + 0.72 * lift_left,
            "BootLeft": -0.22 - 0.25 * lift_left,
            "ThighRight": amplitude * stride,
            "ShinRight": 0.18 + 0.72 * lift_right,
            "BootRight": -0.22 - 0.25 * lift_right,
            "ArmLeft": 0.50 * stride - 0.08,
            "ForearmLeft": -0.22 - 0.20 * lift_right,
            "ArmRight": -0.50 * stride + 0.06,
            "ForearmRight": 0.16 + 0.18 * lift_left,
            "CapeLeft": -0.11 + 0.11 * sin(gait_phase - 0.65),
            "CapeRight": -0.08 + 0.10 * sin(gait_phase - 1.05),
            "FrontCloth": -0.10 * sin(gait_phase - 0.4),
            "ChainLeft": 0.13 * sin(gait_phase - 0.9),
            "ChainRight": 0.12 * sin(gait_phase - 1.2),
        }
        # During locomotion the weapon is carried behind the waist.
        axe_position = Vector2(-40, 10)
        axe_angle = -1.0 + 0.045 * sin(gait_phase - 0.8)
        axe_sprite.z_index = -4
        cloth_sprite.z_index = -3
    elif dashing:
        bob = 2.0
        targets = {
            "Pelvis": -0.05, "Torso": 0.32, "Head": -0.17,
            "ThighLeft": 0.75, "ShinLeft": -0.55, "BootLeft": 0.20,
            "ThighRight": -0.62, "ShinRight": 0.75, "BootRight": -0.18,
            "ArmLeft": 0.63, "ForearmLeft": -0.36,
            "ArmRight": -0.47, "ForearmRight": 0.30,
            "CapeLeft": -0.38, "CapeRight": -0.32,
            "FrontCloth": -0.24, "ChainLeft": -0.25, "ChainRight": -0.22,
        }
        axe_position = Vector2(-40, 10)
        axe_angle = -1.05
        axe_sprite.z_index = -4
        cloth_sprite.z_index = -3
    elif pose == &"jump" or pose == &"fall":
        var rising := pose == &"jump"
        bob = -2.0 if rising else 1.0
        targets = {
            "Pelvis": 0.02, "Torso": 0.10 if rising else -0.04,
            "Head": -0.06, "ThighLeft": -0.54, "ShinLeft": 0.86,
            "BootLeft": -0.20, "ThighRight": 0.30, "ShinRight": 0.68,
            "BootRight": -0.12, "ArmLeft": -0.28, "ForearmLeft": -0.30,
            "ArmRight": 0.23, "ForearmRight": 0.24,
            "CapeLeft": -0.15, "CapeRight": -0.12,
            "FrontCloth": 0.09, "ChainLeft": 0.12, "ChainRight": 0.10,
        }
        axe_position = Vector2(-40, 10)
        axe_angle = -1.0
        axe_sprite.z_index = -4
        cloth_sprite.z_index = -3
    else:
        var breath := sin(clock * 2.6)
        bob = -0.6 * breath
        targets = {
            "Pelvis": 0.0, "Torso": 0.012 * breath,
            "Head": -0.010 * breath,
            "ArmLeft": -0.018 * breath, "ArmRight": 0.015 * breath,
            "CapeLeft": 0.015 * sin(clock * 1.9),
            "CapeRight": 0.015 * sin(clock * 2.1 - 0.4),
            "FrontCloth": 0.017 * sin(clock * 2.0 - 0.6),
            "ChainLeft": 0.02 * sin(clock * 1.8 - 0.5),
            "ChainRight": 0.02 * sin(clock * 1.7 - 1.0),
        }
        axe_sprite.z_index = 7
        cloth_sprite.z_index = 4
        if String(pose).begins_with("carrasco_") or pose == &"charge" or pose == &"charge_ready":
            targets["Torso"] = 0.16 if attack_phase == PlayerCombat.Phase.ACTIVE else -0.08
            targets["ArmLeft"] = -0.25 if attack_phase == PlayerCombat.Phase.WINDUP else 0.28
            targets["ArmRight"] = 0.23 if attack_phase == PlayerCombat.Phase.WINDUP else -0.22
            axe_angle = -0.55 if attack_phase == PlayerCombat.Phase.WINDUP else 0.24
        elif pose == &"death" or pose == &"ruptured":
            targets["Torso"] = -0.27
            targets["Head"] = 0.22
    var blend := 1.0 - exp(-delta * 15.0)
    for name in bones:
        var bone: Bone2D = bones[name]
        bone.rotation = lerp_angle(bone.rotation, float(targets.get(name, 0.0)), blend)
    var pelvis: Bone2D = bones["Pelvis"]
    pelvis.position = pelvis.position.lerp(Vector2(128, 128 + bob), blend)
    var axe_bone: Bone2D = bones["AxeBack"]
    axe_bone.position = axe_bone.position.lerp(axe_position, blend)
    axe_bone.rotation = lerp_angle(axe_bone.rotation, axe_angle, blend * 0.65)


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


func _exit_tree() -> void:
    for mark in marks.values():
        if is_instance_valid(mark):
            mark.queue_free()
    marks.clear()


func _draw() -> void:
    if not tribunal:
        return
    draw_rect(Rect2(-8, -57, 4, 1), Color(0.8, 0.31, 0.19, 0.7))
    draw_rect(Rect2(5, -53, 3, 1), Color(0.8, 0.31, 0.19, 0.7))
