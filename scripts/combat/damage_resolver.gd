class_name DamageResolver
extends RefCounted

## Pure calculations. The HealthComponent applies HP/Posture together, then decides death or rupture.
static func health_amount(context: HitContext, stats: DefenseStats, posture: PostureComponent) -> int:
    if context.direct_life_loss:
        return maxi(0, context.base_damage)
    var vulnerability := 1.0 + (stats.vulnerability_bonus if stats != null else 0.0)
    if stats != null and context.damage_type == &"magical":
        vulnerability += stats.magical_vulnerability_bonus
    if posture != null and posture.is_ruptured():
        vulnerability += posture.rupture_vulnerability_bonus
    var raw := maxf(0.0, float(context.base_damage) * vulnerability)
    var defense_factor := 1.0 if context.bypass_defense or stats == null else 1.0 - stats.effective_defense()
    var resistance := stats.resistance_for(context.damage_type) if stats != null else 0.0
    var reduced := raw * defense_factor * (1.0 - clampf(resistance, 0.0, 1.0))
    # Ordinary mitigation cannot exceed the reference 85% effective safety ceiling.
    return maxi(0, roundi(maxf(reduced, raw * 0.15)))


static func posture_amount(context: HitContext, stats: DefenseStats) -> int:
    var pressure := maxf(0.0, float(context.posture_damage) * context.posture_damage_multiplier)
    if stats != null and context.tags.has("heavy") and not context.tags.has("air"):
        pressure *= stats.ground_heavy_posture_taken_multiplier
    var resistance := stats.posture_resistance if stats != null else 0.0
    return maxi(0, roundi(pressure * (1.0 - clampf(resistance, 0.0, 1.0))))


static func parry_return_amount(offensive_posture: float, multiplier: float, attacker_stats: DefenseStats) -> int:
    var resistance := attacker_stats.posture_resistance if attacker_stats != null else 0.0
    return maxi(0, roundi(offensive_posture * multiplier * (1.0 - clampf(resistance, 0.0, 1.0))))
