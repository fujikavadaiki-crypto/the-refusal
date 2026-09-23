class_name ExecutionResolver
extends RefCounted

## Technical API only. A final execution input/window has not been defined.
enum Result { INELIGIBLE, COMMON_KILL, STRIKE }


static func is_eligible(state: CarrascoRuntimeState, target: Node) -> bool:
    if state == null or target == null or not is_instance_valid(target):
        return false
    var health := target.get_node_or_null("Health") as HealthComponent
    var posture := target.get_node_or_null("Posture") as PostureComponent
    if health == null or posture == null or health.current_health <= 0:
        return false
    if not posture.is_ruptured() or state.stacks_for(target) < 3:
        return false
    return _tier(target) != &"common" or float(health.current_health) / float(health.max_health) < 0.15


static func execute(state: CarrascoRuntimeState, player: Node2D, target: Node) -> Result:
    if not is_eligible(state, target):
        return Result.INELIGIBLE
    var health := target.get_node("Health") as HealthComponent
    var context := HitContext.new()
    context.attacker = player
    context.target = target as Node2D
    context.attack_id = &"carrasco_execution"
    context.action_uid = HitContext.allocate_action_id()
    context.hit_uid = context.action_uid
    context.damage_type = &"physical"
    context.tags = PackedStringArray(["physical", "melee", "execution"])
    context.parry_class = &"unparryable"
    if _tier(target) == &"common":
        context.base_damage = health.current_health
        context.direct_life_loss = true
        context.bypass_defense = true
        return Result.COMMON_KILL if health.receive_hit(context) and context.outcome == HitContext.Outcome.DEAD else Result.INELIGIBLE
    # Elite and boss use an ordinary heavy-strength hit through the existing resolver.
    context.base_damage = state.data.heavy.base_damage
    context.posture_damage = state.data.heavy.posture_damage
    state.prepare_hit(context)
    if not health.receive_hit(context) or context.outcome not in [HitContext.Outcome.DAMAGED, HitContext.Outcome.DEAD]:
        return Result.INELIGIBLE
    state.consume_stacks(target, 3)
    return Result.STRIKE


static func _tier(target: Node) -> StringName:
    var value: StringName = target.get_meta("execution_tier", &"common")
    return value if value in [&"elite", &"miniboss", &"boss"] else &"common"
