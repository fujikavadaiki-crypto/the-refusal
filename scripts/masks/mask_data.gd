class_name MaskData
extends Resource

## Immutable equipped configuration. Each slot creates its own runtime state.
@export var mask_id: StringName
@export var display_name: String
@export var runtime_script: Script
@export var visual_scene: PackedScene
@export var physical_bonus := 0.0
@export var posture_bonus := 0.0
@export var move_speed_multiplier := 1.0
@export var max_health_multiplier := 1.0
@export var max_posture_multiplier := 1.0
@export var parry_posture_multiplier := 1.0
@export var light_1: AttackData
@export var light_2: AttackData
@export var light_3: AttackData
@export var heavy: AttackData
@export var post_dodge: AttackData
@export var air_light: AttackData
@export var air_heavy: AttackData
@export var skill_1: AttackData
@export var skill_2: AttackData
@export var skill_1_cooldown := 0.0
@export var skill_2_cooldown := 0.0
@export var ultimate_duration := 0.0
@export var ultimate_cooldown := 0.0
@export var ultimate_physical_bonus := 0.0
@export var ultimate_posture_bonus := 0.0
