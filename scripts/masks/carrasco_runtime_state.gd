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
            _forget_key(key)
            continue
        entry.buff = maxf(0.0, entry.buff - delta)
        entry.extension = maxf(0.0, entry.extension - delta)
        var posture := target.get_node_or_null("Posture") as PostureComponent
        if posture == null or not posture.is_ruptured():
            entry.time = maxf(0.0, entry.time - delta)
        if entry.time <= 0.0:
            entry.stacks = 0
        if entry.stacks == 0 and entry.buff <= 0.0 and entry.extension <= 0.0:
            _forget_key(key)
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
    if not targets.has(key):
        _observe_target(target)
    var entry: Dictionary = targets[key]
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
        _forget_key(target.get_instance_id())


func dispose() -> void:
    for key in targets.keys():
        _forget_key(key)


func extension_for(target: Node) -> float:
    return float(targets[target.get_instance_id()].extension) if target != null and targets.has(target.get_instance_id()) else 0.0


func has_execution_opportunity(target: Node) -> bool:
    if target == null or not is_instance_valid(target):
        return false
    var posture := target.get_node_or_null("Posture") as PostureComponent
    return posture != null and (posture.is_ruptured() or extension_for(target) > 0.0)


func meets_execution_conditions(target: Node) -> bool:
    if target == null or not is_instance_valid(target) or stacks_for(target) < 3:
        return false
    var health := target.get_node_or_null("Health") as HealthComponent
    if health == null or health.current_health <= 0:
        return false
    return execution_tier_for(target) != &"common" or float(health.current_health) / float(health.max_health) < 0.15


func execution_tier_for(target: Node) -> StringName:
    var value: StringName = target.get_meta("execution_tier", &"common")
    return value if value in [&"elite", &"miniboss", &"boss"] else &"common"


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
    if context.target == null:
        return
    if context.outcome == HitContext.Outcome.DEAD:
        clear_target(context.target)
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
        _arm_extension_after_hit(context.target)


func on_parry(context: HitContext) -> void:
    if context.attacker == null:
        return
    add_stacks(context.attacker, 1)
    if context.caused_rupture:
        add_stacks(context.attacker, 2)
        _arm_extension_after_hit(context.attacker)


func _observe_target(target: Node) -> void:
    var target_ref: WeakRef = weakref(target)
    var entry: Dictionary = {"ref": target_ref, "stacks": 0, "time": 0.0, "buff": 0.0, "extension": 0.0, "armed": false}
    var target_posture := target.get_node_or_null("Posture") as PostureComponent
    if target_posture != null:
        entry.broken_callback = Callable(self, "_on_target_ruptured").bind(target_ref)
        entry.recovered_callback = Callable(self, "_on_target_recovered").bind(target_ref)
        target_posture.ruptured.connect(entry.broken_callback)
        target_posture.recovered.connect(entry.recovered_callback)
    targets[target.get_instance_id()] = entry


func _forget_key(key: int) -> void:
    if not targets.has(key):
        return
    var entry: Dictionary = targets[key]
    var target: Node = entry.ref.get_ref()
    if target != null and is_instance_valid(target):
        var target_posture := target.get_node_or_null("Posture") as PostureComponent
        if target_posture != null and entry.has("broken_callback"):
            if target_posture.ruptured.is_connected(entry.broken_callback):
                target_posture.ruptured.disconnect(entry.broken_callback)
            if target_posture.recovered.is_connected(entry.recovered_callback):
                target_posture.recovered.disconnect(entry.recovered_callback)
    targets.erase(key)


func _on_target_ruptured(target_ref: WeakRef) -> void:
    var target: Node = target_ref.get_ref()
    if target == null or not targets.has(target.get_instance_id()):
        return
    var key := target.get_instance_id()
    var entry: Dictionary = targets[key]
    entry.extension = 0.0
    entry.armed = ultimate_remaining > 0.0 and meets_execution_conditions(target)
    targets[key] = entry


func _on_target_recovered(target_ref: WeakRef) -> void:
    var target: Node = target_ref.get_ref()
    if target == null or not targets.has(target.get_instance_id()):
        return
    var key := target.get_instance_id()
    var entry: Dictionary = targets[key]
    entry.extension = 1.0 if entry.armed else 0.0
    entry.armed = false
    targets[key] = entry


func _arm_extension_after_hit(target: Node) -> void:
    if target == null or not targets.has(target.get_instance_id()) or ultimate_remaining <= 0.0 or not meets_execution_conditions(target):
        return
    var posture := target.get_node_or_null("Posture") as PostureComponent
    if posture == null or not posture.is_ruptured():
        return
    var key := target.get_instance_id()
    var entry: Dictionary = targets[key]
    entry.armed = true
    targets[key] = entry


func _is_dead(target: Node) -> bool:
    var health := target.get_node_or_null("Health") as HealthComponent
    return health != null and health.current_health <= 0
