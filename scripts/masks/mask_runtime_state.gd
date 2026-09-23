class_name MaskRuntimeState
extends RefCounted

var data: MaskData
var skill_1_remaining := 0.0
var skill_2_remaining := 0.0
var ultimate_cooldown_remaining := 0.0
var ultimate_remaining := 0.0


func tick(delta: float) -> void:
    skill_1_remaining = maxf(0.0, skill_1_remaining - delta)
    skill_2_remaining = maxf(0.0, skill_2_remaining - delta)
    ultimate_cooldown_remaining = maxf(0.0, ultimate_cooldown_remaining - delta)
    ultimate_remaining = maxf(0.0, ultimate_remaining - delta)


func end_ultimate() -> void:
    ultimate_remaining = 0.0


func dispose() -> void:
    pass


func prepare_hit(context: HitContext) -> void:
    context.physical_attack_bonus += data.physical_bonus
    context.posture_attack_bonus += data.posture_bonus
    if ultimate_remaining > 0.0:
        context.physical_attack_bonus += data.ultimate_physical_bonus
        context.posture_attack_bonus += data.ultimate_posture_bonus


func on_hit(_context: HitContext) -> void:
    pass


func on_parry(_context: HitContext) -> void:
    pass
