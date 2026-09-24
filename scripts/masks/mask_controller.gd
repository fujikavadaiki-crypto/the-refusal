class_name MaskController
extends Node

signal mask_changed(active: MaskData)
signal execution_resolved(target: Node2D, result: int)

@export var swap_cooldown_seconds := 10.0
@onready var player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var locomotion: PlayerLocomotion = $"../Locomotion"
@onready var combat: PlayerCombat = $"../Combat"
@onready var defense: PlayerDefense = $"../Defense"
@onready var health: HealthComponent = $"../Health"
@onready var posture: PostureComponent = $"../Posture"
@onready var badge: Polygon2D = $"../VisualRoot/MaskBadge"
@onready var targeting: ExecutionTargeting = $"../ExecutionRange"

var slots: Array[MaskRuntimeState] = [null, null]
var active_slot := 0
var swap_cooldown_remaining := 0.0
var base_speed := 0.0
var base_health := 0
var base_posture := 0.0
var base_parry_multiplier := 1.0


func _ready() -> void:
    base_speed = locomotion.run_speed
    base_health = health.max_health
    base_posture = posture.max_posture
    base_parry_multiplier = defense.parry_posture_multiplier
    defense.parry_succeeded.connect(_on_parry)
    badge.visible = false


func tick(delta: float) -> void:
    swap_cooldown_remaining = maxf(0.0, swap_cooldown_remaining - delta)
    for state in slots:
        if state != null:
            state.tick(delta)


func equip(slot: int, data: MaskData) -> void:
    assert(slot >= 0 and slot < 2)
    if slots[slot] != null:
        slots[slot].dispose()
    var state: MaskRuntimeState = null
    if data != null:
        state = data.runtime_script.new() as MaskRuntimeState if data.runtime_script != null else MaskRuntimeState.new()
        state.data = data
    slots[slot] = state
    if slot == active_slot:
        _apply_active()


func _exit_tree() -> void:
    for state in slots:
        if state != null:
            state.dispose()


func active_state() -> MaskRuntimeState:
    return slots[active_slot]


func active_data() -> MaskData:
    var state := active_state()
    return state.data if state != null else null


func swap() -> bool:
    if swap_cooldown_remaining > 0.0 or defense.is_locked():
        return false
    combat.cancel_charge()
    if combat.is_busy():
        return false
    var state := active_state()
    if state != null:
        state.end_ultimate()
    active_slot = 1 - active_slot
    combat.reset_combo()
    swap_cooldown_remaining = swap_cooldown_seconds
    _apply_active()
    return true


func activate_slot_for_setup(slot: int) -> void:
    assert(slot >= 0 and slot < 2)
    active_slot = slot
    _apply_active()


func use_skill(index: int) -> bool:
    var state := active_state()
    if state == null or defense.is_locked():
        return false
    var attack := state.data.skill_1 if index == 1 else state.data.skill_2
    var remaining := state.skill_1_remaining if index == 1 else state.skill_2_remaining
    if attack == null or remaining > 0.0 or not combat.start_special(attack):
        return false
    if index == 1:
        state.skill_1_remaining = state.data.skill_1_cooldown
    else:
        state.skill_2_remaining = state.data.skill_2_cooldown
    return true


func use_ultimate() -> bool:
    var state := active_state()
    if state == null or defense.is_locked() or state.data.ultimate_duration <= 0.0 or state.ultimate_cooldown_remaining > 0.0:
        return false
    state.ultimate_remaining = state.data.ultimate_duration
    state.ultimate_cooldown_remaining = state.data.ultimate_cooldown
    return true


func try_execute() -> int:
    var state := active_state() as CarrascoRuntimeState
    if state == null or defense.is_locked():
        return ExecutionResolver.Result.INELIGIBLE
    var target := targeting.best_target(state, player)
    if target == null:
        return ExecutionResolver.Result.INELIGIBLE
    combat.abort_attack()
    var result := ExecutionResolver.execute(state, player, target)
    if result != ExecutionResolver.Result.INELIGIBLE:
        execution_resolved.emit(target, result)
    return result


func prepare_hit(context: HitContext) -> void:
    var state := active_state()
    if state != null:
        state.prepare_hit(context)


func on_hit(context: HitContext) -> void:
    var state := active_state()
    if state != null:
        state.on_hit(context)


func _on_parry(context: HitContext) -> void:
    var state := active_state()
    if state != null:
        state.on_parry(context)


func _apply_active() -> void:
    var data := active_data()
    locomotion.run_speed = base_speed * (data.move_speed_multiplier if data != null else 1.0)
    health.set_max_preserving_ratio(roundi(base_health * (data.max_health_multiplier if data != null else 1.0)))
    posture.set_max_preserving_ratio(base_posture * (data.max_posture_multiplier if data != null else 1.0))
    defense.parry_posture_multiplier = base_parry_multiplier * (data.parry_posture_multiplier if data != null else 1.0)
    badge.visible = data != null
    mask_changed.emit(data)
