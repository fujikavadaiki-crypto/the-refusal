class_name ExecutionResolver
extends RefCounted

## Single resolver for normal Rupture and Tribunal's extra opportunity.
enum Result { INELIGIBLE, COMMON_KILL, STRIKE }
const INTERACTION_DISTANCE := 52.0 # Provisional close-range playtest value.


static func is_eligible(state: CarrascoRuntimeState, target: Node) -> bool:
    return state != null and state.meets_execution_conditions(target) and state.has_execution_opportunity(target)


static func can_reach(player: Node2D, target: Node) -> bool:
    if player == null or target == null or not is_instance_valid(target) or not target is Node2D:
        return false
    if player.global_position.distance_to((target as Node2D).global_position) > INTERACTION_DISTANCE:
        return false
    var excluded: Array[RID] = []
    if player is CollisionObject2D:
        excluded.append((player as CollisionObject2D).get_rid())
    if target is CollisionObject2D:
        excluded.append((target as CollisionObject2D).get_rid())
    var query := PhysicsRayQueryParameters2D.create(player.global_position, (target as Node2D).global_position, 1, excluded)
    return player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


static func execute(state: CarrascoRuntimeState, player: Node2D, target: Node) -> Result:
    if not is_eligible(state, target) or not can_reach(player, target):
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
    if state.execution_tier_for(target) == &"common":
        context.base_damage = health.current_health
        context.direct_life_loss = true
        context.bypass_defense = true
        if health.receive_hit(context) and context.outcome == HitContext.Outcome.DEAD:
            state.clear_target(target)
            return Result.COMMON_KILL
        return Result.INELIGIBLE
    # Elite and boss use an ordinary heavy-strength hit through the existing resolver.
    context.base_damage = state.data.heavy.base_damage
    context.posture_damage = state.data.heavy.posture_damage
    state.prepare_hit(context)
    if not health.receive_hit(context) or context.outcome not in [HitContext.Outcome.DAMAGED, HitContext.Outcome.DEAD]:
        return Result.INELIGIBLE
    state.consume_stacks(target, 3)
    if health.current_health <= 0:
        state.clear_target(target)
    return Result.STRIKE
