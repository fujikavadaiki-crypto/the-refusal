class_name AttackData
extends Resource

## One move definition. Canonical damage is data; timing and shapes are test tuning.
@export var attack_id: StringName
@export var base_damage: int
@export var posture_damage: int
@export var parry_class: StringName = &"parryable"
@export var damage_type: StringName = &"physical"
@export var tags: PackedStringArray = PackedStringArray()
@export var windup_seconds: float
@export var active_seconds: float
@export var recovery_seconds: float
@export var combo_queue_start_seconds: float
@export var combo_wait_seconds: float
@export var movement_multiplier: float = 1.0
@export var start_angle_degrees: float
@export var end_angle_degrees: float
@export var hitbox_center_x: float = 19.0
@export var hitbox_size: Vector2 = Vector2(12, 5)
@export var hit_stop_ms: int = 30
@export var charged_variant: AttackData
@export var charge_threshold_seconds := 0.0
@export var charge_move_multiplier := 0.45


func total_seconds() -> float:
    return windup_seconds + active_seconds + recovery_seconds
