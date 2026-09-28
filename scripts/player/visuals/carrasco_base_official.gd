extends Node2D

## Visual-only Carrasco base. The Player controller, physics and hitboxes own gameplay.
const PART_ROOT := "res://assets/characters/carrasco_base_official/parts/"
const MARK := preload("res://scripts/player/visuals/condemnation_mark.gd")
const PARTS := {
    "cape_center": ["CapeCenter", Vector2(137, 180), -6],
    "cape_left": ["CapeLeft", Vector2(97, 100), -5],
    "cape_right": ["CapeRight", Vector2(190, 108), -5],
    "thigh_left": ["ThighLeft", Vector2(109, 230), -2],
    "shin_left": ["ShinLeft", Vector2(105, 275), -2],
    "boot_left": ["BootLeft", Vector2(93, 327), -2],
    "thigh_right": ["ThighRight", Vector2(171, 230), -1],
    "shin_right": ["ShinRight", Vector2(172, 280), -1],
    "boot_right": ["BootRight", Vector2(184, 329), -1],
    "torso": ["Torso", Vector2(137, 91), 0],
    "upper_arm_left": ["ArmLeft", Vector2(90, 82), 2],
    "forearm_left": ["ForearmLeft", Vector2(76, 126), 3],
    "hand_left": ["HandLeft", Vector2(73, 176), 4],
    "upper_arm_right": ["ArmRight", Vector2(190, 91), 2],
    "forearm_right": ["ForearmRight", Vector2(193, 139), 3],
    "hand_right": ["HandRight", Vector2(206, 185), 4],
    "head": ["Head", Vector2(145, 55), 5],
    "front_cloth": ["FrontCloth", Vector2(154, 161), 5],
    "chain_left": ["ChainLeft", Vector2(137, 153), 6],
    "chain_right": ["ChainRight", Vector2(179, 160), 6],
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
    "CapeCenter": "Skeleton2D/Pelvis/Torso/CapeCenter",
    "ChainLeft": "Skeleton2D/Pelvis/Torso/ChainLeft",
    "ChainRight": "Skeleton2D/Pelvis/Torso/ChainRight",
    "FrontCloth": "Skeleton2D/Pelvis/FrontCloth",
    "ThighLeft": "Skeleton2D/Pelvis/ThighLeft",
    "ShinLeft": "Skeleton2D/Pelvis/ThighLeft/ShinLeft",
    "BootLeft": "Skeleton2D/Pelvis/ThighLeft/ShinLeft/BootLeft",
    "ThighRight": "Skeleton2D/Pelvis/ThighRight",
    "ShinRight": "Skeleton2D/Pelvis/ThighRight/ShinRight",
    "BootRight": "Skeleton2D/Pelvis/ThighRight/ShinRight/BootRight",
    "Weapon": "Skeleton2D/Pelvis/Torso/Weapon",
}

var bones: Dictionary = {}
var marks: Dictionary = {}
var runtime: CarrascoRuntimeState
var player: CharacterBody2D
var pose: StringName = &"idle"
var attack_phase := PlayerCombat.Phase.IDLE
var attack_progress := 0.0
var charged_ready := false
var tribunal := false
var clock := 0.0
var gait_phase := 0.0
var weapon_sprite: Sprite2D


func _enter_tree() -> void:
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
        var sprite := Sprite2D.new()
        sprite.name = String(part_name).to_pascal_case()
        sprite.texture = load(PART_ROOT + part_name + ".png") as Texture2D
        sprite.centered = false
        sprite.position = -Vector2(spec[1])
        sprite.z_as_relative = true
        sprite.z_index = int(spec[2])
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        if not String(part_name).begins_with("cape") and part_name != "front_cloth":
            sprite.modulate = Color(1.10, 1.10, 1.10, 1.0)
        (bones[spec[0]] as Bone2D).add_child(sprite)
    weapon_sprite = Sprite2D.new()
    weapon_sprite.name = "BloodiedWeapon"
    weapon_sprite.texture = load(PART_ROOT + "weapon.png") as Texture2D
    weapon_sprite.centered = false
    weapon_sprite.position = Vector2(-60, -34)
    weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    weapon_sprite.z_as_relative = true
    weapon_sprite.z_index = 7
    (bones["Weapon"] as Bone2D).add_child(weapon_sprite)


func _add_joint_backing() -> void:
    # Functional underpainting stays behind the approved-design pixels.
    for spec in [
        ["ArmLeft", Vector2(-14, 44), 29.0],
        ["ForearmLeft", Vector2(-3, 50), 21.0],
        ["ArmRight", Vector2(3, 48), 24.0],
        ["ForearmRight", Vector2(13, 46), 19.0],
        ["ThighLeft", Vector2(-4, 45), 39.0],
        ["ShinLeft", Vector2(-12, 52), 30.0],
        ["ThighRight", Vector2(1, 50), 33.0],
        ["ShinRight", Vector2(12, 49), 27.0],
    ]:
        var line := Line2D.new()
        line.name = "JointBacking"
        line.points = PackedVector2Array([Vector2.ZERO, spec[1]])
        line.width = float(spec[2])
        line.default_color = Color("#23181d")
        line.begin_cap_mode = Line2D.LINE_CAP_ROUND
        line.end_cap_mode = Line2D.LINE_CAP_ROUND
        line.z_index = -9
        line.antialiased = false
        (bones[spec[0]] as Bone2D).add_child(line)


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


func _animate(delta: float) -> void:
    var targets: Dictionary = {}
    var bob := 0.0
    var weapon_position := Vector2(68, 96)
    var weapon_angle := 0.83
    var moving := pose == &"run" or pose == &"walk"
    var dashing := pose == &"ground_dash" or pose == &"air_dash"
    var attacking := String(pose).begins_with("carrasco_") or pose == &"charge" or pose == &"charge_ready"
    # The broad blade is behind the cloak while the weapon is stowed; its
    # pommel and wrapped grip remain visible at the waist at unchanged scale.
    weapon_sprite.region_enabled = moving or dashing or pose == &"jump" or pose == &"fall"
    weapon_sprite.region_rect = Rect2(0, 0, 123, 107)
    if moving:
        var speed_factor := 1.0
        if player != null:
            speed_factor = clampf(absf(player.velocity.x) / 125.0, 0.45, 1.0)
        gait_phase = wrapf(gait_phase + delta * TAU * (1.5 + 0.65 * speed_factor), 0.0, TAU)
        var stride := sin(gait_phase)
        var left_lift := maxf(0.0, sin(gait_phase + 0.35))
        var right_lift := maxf(0.0, -sin(gait_phase + 0.35))
        var amplitude := 0.54 * speed_factor * (0.65 if pose == &"walk" else 1.0)
        bob = -4.0 - 3.3 * cos(gait_phase * 2.0)
        targets = {
            "Pelvis": 0.035 * stride, "Torso": 0.12 + 0.04 * sin(gait_phase + 0.4),
            "Head": -0.09, "ThighLeft": -amplitude * stride,
            "ShinLeft": 0.15 + 0.7 * left_lift, "BootLeft": -0.16 - 0.18 * left_lift,
            "ThighRight": amplitude * stride, "ShinRight": 0.15 + 0.7 * right_lift,
            "BootRight": -0.16 - 0.18 * right_lift,
            "ArmLeft": 0.42 * stride, "ForearmLeft": -0.18 - 0.13 * right_lift,
            "ArmRight": -0.42 * stride, "ForearmRight": 0.13 + 0.13 * left_lift,
            "CapeLeft": -0.10 + 0.09 * sin(gait_phase - 0.8),
            "CapeRight": -0.09 + 0.08 * sin(gait_phase - 1.1),
            "CapeCenter": -0.08 + 0.06 * sin(gait_phase - 0.9),
            "FrontCloth": -0.07 * sin(gait_phase - 0.35),
            "ChainLeft": 0.09 * sin(gait_phase - 0.8),
            "ChainRight": 0.09 * sin(gait_phase - 1.0),
        }
        weapon_position = Vector2(83, 169)
        weapon_angle = -2.7 + 0.025 * sin(gait_phase - 0.7)
        weapon_sprite.z_index = -7
    elif dashing:
        bob = 3.0
        targets = {
            "Torso": 0.31, "Head": -0.17,
            "ThighLeft": 0.6, "ShinLeft": -0.4, "ThighRight": -0.55,
            "ShinRight": 0.65, "ArmLeft": 0.56, "ArmRight": -0.47,
            "CapeLeft": -0.29, "CapeRight": -0.26,
            "CapeCenter": -0.24, "FrontCloth": -0.19,
        }
        weapon_position = Vector2(83, 169)
        weapon_angle = -2.7
        weapon_sprite.z_index = -7
    elif pose == &"jump" or pose == &"fall":
        var rising := pose == &"jump"
        bob = -2.0 if rising else 2.0
        targets = {
            "Torso": 0.10 if rising else -0.03, "Head": -0.06,
            "ThighLeft": -0.41, "ShinLeft": 0.71,
            "ThighRight": 0.30, "ShinRight": 0.59,
            "ArmLeft": -0.23, "ArmRight": 0.19,
            "CapeLeft": -0.14, "CapeRight": -0.11,
            "CapeCenter": -0.09, "FrontCloth": 0.06,
        }
        weapon_position = Vector2(83, 169)
        weapon_angle = -2.7
        weapon_sprite.z_index = -7
    elif attacking:
        var heavy := pose == &"carrasco_heavy" or pose == &"carrasco_charged_heavy" or pose == &"carrasco_air_heavy"
        weapon_sprite.z_index = 8
        weapon_position = Vector2(60, 52)
        if attack_phase == PlayerCombat.Phase.WINDUP or pose == &"charge" or pose == &"charge_ready":
            targets = {
                "Torso": -0.14, "Head": 0.08, "ArmLeft": -0.35,
                "ForearmLeft": -0.25, "ArmRight": -0.78 if heavy else -0.45,
                "ForearmRight": -0.34, "CapeLeft": 0.07, "CapeRight": 0.06,
                "FrontCloth": 0.04,
            }
            weapon_angle = -1.70 if heavy else -1.28
        elif attack_phase == PlayerCombat.Phase.ACTIVE:
            var swing := smoothstep(0.0, 1.0, attack_progress)
            targets = {
                "Torso": lerpf(-0.06, 0.25, swing), "Head": -0.10,
                "ArmLeft": lerpf(-0.25, 0.42, swing),
                "ArmRight": lerpf(-0.65, 0.59, swing),
                "ForearmRight": 0.30, "CapeLeft": -0.18,
                "CapeRight": -0.14, "CapeCenter": -0.13,
                "FrontCloth": -0.11,
            }
            weapon_angle = lerpf(-1.65, 0.94, swing) if heavy else lerpf(-1.25, 0.55, swing)
        else:
            targets = {
                "Torso": 0.16, "Head": -0.07, "ArmLeft": 0.18,
                "ArmRight": 0.38, "ForearmRight": 0.21,
                "CapeLeft": -0.13, "CapeRight": -0.10,
                "FrontCloth": -0.08,
            }
            weapon_angle = 0.95
    else:
        var breath := sin(clock * 2.2)
        bob = -0.6 * breath
        targets = {
            "Torso": 0.009 * breath, "Head": -0.008 * breath,
            "ArmLeft": -0.011 * breath, "ArmRight": 0.009 * breath,
            "CapeLeft": 0.012 * sin(clock * 1.7),
            "CapeRight": 0.011 * sin(clock * 1.8 - 0.4),
            "CapeCenter": 0.009 * sin(clock * 1.6),
            "FrontCloth": 0.013 * sin(clock * 1.6 - 0.5),
            "ChainLeft": 0.015 * sin(clock * 1.4),
            "ChainRight": 0.015 * sin(clock * 1.5 - 0.3),
        }
        weapon_sprite.z_index = 8
        if pose == &"death" or pose == &"ruptured":
            targets["Torso"] = -0.25
            targets["Head"] = 0.18
    var blend := 1.0 - exp(-delta * (35.0 if attacking else 16.0))
    for name in bones:
        var bone: Bone2D = bones[name]
        if name == "Weapon":
            continue
        bone.rotation = lerp_angle(bone.rotation, float(targets.get(name, 0.0)), blend)
    var pelvis: Bone2D = bones["Pelvis"]
    pelvis.position = pelvis.position.lerp(Vector2(137, 160 + bob), blend)
    var weapon_bone: Bone2D = bones["Weapon"]
    if not weapon_sprite.region_enabled:
        var torso: Bone2D = bones["Torso"]
        var hand: Bone2D = bones["HandRight"]
        weapon_bone.position = torso.to_local(hand.global_position)
    else:
        weapon_bone.position = weapon_bone.position.lerp(weapon_position, blend)
    weapon_bone.rotation = lerp_angle(weapon_bone.rotation, weapon_angle, blend * 0.85)


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
