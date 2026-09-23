class_name CarrascoRuntimeState
extends MaskRuntimeState

## Target state belongs to this equipped mask instance, not to the target or Player.
const STACK_DURATION := 10.0 # Provisional playtest duration.
const MARK_BONUS_DURATION := 5.0 # Provisional playtest duration.
const MAX_STACKS := 5
var targets: Dictionary = {}


func tick(delta: float) -> void:
    super.tick(delta)
    for key in targets.keys():
        var entry: Dictionary = targets[key]
        var target: Node = entry.ref.get_ref()
        if target == null or not is_instance_valid(target) or _is_dead(target):
            targets.erase(key)
            continue
        entry.buff = maxf(0.0, entry.buff - delta)
        var posture := target.get_node_or_null("Posture") as PostureComponent
        if posture == null or not posture.is_ruptured():
            entry.time = maxf(0.0, entry.time - delta)
        if entry.time <= 0.0:
            entry.stacks = 0
        if entry.stacks == 0 and entry.buff <= 0.0:
            targets.erase(key)
        else:
            targets[key] = entry


func stacks_for(target: Node) -> int:
    if target == null or not targets.has(target.get_instance_id()):
        return 0
    return int(targets[target.get_instance_id()].stacks)


func time_for(target: Node) -> float:
    return float(targets[target.get_instance_id()].time) if target != null and targets.has(target.get_instance_id()) else 0.0


func buff_for(target: Node) -> float:
    return float(targets[target.get_instance_id()].buff) if target != null and targets.has(target.get_instance_id()) else 0.0


func add_stacks(target: Node, amount: int) -> void:
    if target == null or not is_instance_valid(target) or _is_dead(target):
        return
    var key := target.get_instance_id()
    var entry: Dictionary = targets.get(key, {"ref": weakref(target), "stacks": 0, "time": 0.0, "buff": 0.0})
    entry.stacks = mini(MAX_STACKS, int(entry.stacks) + amount)
    entry.time = STACK_DURATION
    targets[key] = entry


func consume_stacks(target: Node, amount: int) -> void:
    if target == null or not targets.has(target.get_instance_id()):
        return
    var key := target.get_instance_id()
    var entry: Dictionary = targets[key]
    entry.stacks = maxi(0, int(entry.stacks) - amount)
    targets[key] = entry


func clear_target(target: Node) -> void:
    if target != null:
        targets.erase(target.get_instance_id())


func prepare_hit(context: HitContext) -> void:
    super.prepare_hit(context)
    if context.target == null:
        return
    context.posture_attack_bonus += 0.03 * stacks_for(context.target)
    if buff_for(context.target) > 0.0:
        context.physical_attack_bonus += 0.20
    if context.tags.has("seal_break"):
        var stats := context.target.get_node_or_null("DefenseStats") as DefenseStats
        if stats != null and stats.has_posture_protection():
            context.posture_damage_multiplier *= 1.50


func on_hit(context: HitContext) -> void:
    if context.target == null or context.outcome == HitContext.Outcome.DEAD:
        return
    if context.tags.has("mark"):
        var prior := stacks_for(context.target)
        add_stacks(context.target, 2)
        if prior >= 3:
            var key := context.target.get_instance_id()
            var entry: Dictionary = targets[key]
            entry.buff = MARK_BONUS_DURATION
            targets[key] = entry
    if context.tags.has("heavy"):
        add_stacks(context.target, 2 if ultimate_remaining > 0.0 else 1)
    if context.caused_rupture:
        add_stacks(context.target, 2)


func on_parry(context: HitContext) -> void:
    if context.attacker == null:
        return
    add_stacks(context.attacker, 1)
    if context.caused_rupture:
        add_stacks(context.attacker, 2)


func _is_dead(target: Node) -> bool:
    var health := target.get_node_or_null("Health") as HealthComponent
    return health != null and health.current_health <= 0
