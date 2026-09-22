class_name HitContext
extends RefCounted

## A single resolved contact. Future modifiers can read these fields without changing hit detection.
var attacker: Node2D
var target: Node2D
var attack_id: StringName
var action_uid: int
var hit_uid: int
var base_damage: int
var actual_damage: int
var posture_damage: int
var damage_type: StringName
var tags: PackedStringArray
var direct := true
var critical := false
var can_proc := true


func for_target(new_target: Node2D, new_hit_uid: int) -> HitContext:
    var result := HitContext.new()
    result.attacker = attacker
    result.target = new_target
    result.attack_id = attack_id
    result.action_uid = action_uid
    result.hit_uid = new_hit_uid
    result.base_damage = base_damage
    result.posture_damage = posture_damage
    result.damage_type = damage_type
    result.tags = tags.duplicate()
    result.direct = direct
    result.critical = critical
    result.can_proc = can_proc
    return result
