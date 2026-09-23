class_name HitContext
extends RefCounted

## A single resolved contact. Future modifiers can read these fields without changing hit detection.
enum Outcome { PENDING, DODGED, PARRIED, DAMAGED, DEAD }
static var next_action_uid := 1


static func allocate_action_id() -> int:
    var result := next_action_uid
    next_action_uid += 1
    return result

var attacker: Node2D
var target: Node2D
var attacker_posture: PostureComponent
var attacker_stats: DefenseStats
var attack_id: StringName
var action_uid: int
var hit_uid: int
var base_damage: int
var actual_damage: int
var posture_damage: int
var actual_posture_damage: int
var posture_damage_multiplier := 1.0
var parry_posture_return := 0
var parry_posture_return_override := 0
var damage_type: StringName
var parry_class: StringName = &"parryable"
var tags: PackedStringArray
var direct := true
var critical := false
var can_proc := true
var bypass_defense := false
var direct_life_loss := false
var outcome := Outcome.PENDING


func for_target(new_target: Node2D, new_hit_uid: int) -> HitContext:
    var result := HitContext.new()
    result.attacker = attacker
    result.target = new_target
    result.attacker_posture = attacker_posture
    result.attacker_stats = attacker_stats
    result.attack_id = attack_id
    result.action_uid = action_uid
    result.hit_uid = new_hit_uid
    result.base_damage = base_damage
    result.posture_damage = posture_damage
    result.posture_damage_multiplier = posture_damage_multiplier
    result.parry_posture_return_override = parry_posture_return_override
    result.damage_type = damage_type
    result.parry_class = parry_class
    result.tags = tags.duplicate()
    result.direct = direct
    result.critical = critical
    result.can_proc = can_proc
    result.bypass_defense = bypass_defense
    result.direct_life_loss = direct_life_loss
    return result
