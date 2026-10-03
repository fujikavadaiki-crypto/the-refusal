extends SceneTree

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
const DUMMY := preload("res://scenes/test/dummy.tscn")
var failed := false
var arena: Node2D
var player: CharacterBody2D
var masks: MaskController
var state: CarrascoRuntimeState
var target: Node2D
var other: Node2D


func _initialize() -> void:
    call_deferred("run_checks")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(ok: bool, name: String) -> void:
    if ok:
        print("PASS: ", name)
    else:
        failed = true
        printerr("FAIL: ", name)


func hit(victim: Node2D, attack: AttackData, rupture := false) -> HitContext:
    var context := HitContext.new()
    context.attacker = player
    context.target = victim
    context.attack_id = attack.attack_id
    context.base_damage = attack.base_damage
    context.posture_damage = attack.posture_damage
    context.damage_type = attack.damage_type
    context.tags = attack.tags.duplicate()
    context.outcome = HitContext.Outcome.DAMAGED
    context.caused_rupture = rupture
    return context


func run_checks() -> void:
    arena = load("res://scenes/test/carrasco_arena.tscn").instantiate()
    root.add_child(arena)
    await frames(5)
    player = arena.get_node("TestRoom/Player")
    masks = player.get_node("MaskController")
    state = masks.slots[0] as CarrascoRuntimeState
    target = arena.get_node("TestRoom/Dummy")
    other = DUMMY.instantiate()
    arena.add_child(other)
    other.global_position = Vector2(1000, 214)
    await frames(2)
    var health := player.get_node("Health") as HealthComponent
    var posture := player.get_node("Posture") as PostureComponent
    var defense := player.get_node("Defense") as PlayerDefense
    var combat := player.get_node("Combat") as PlayerCombat
    var locomotion := player.get_node("Locomotion") as PlayerLocomotion

    check(masks.slots.size() == 2 and state != null, "01 two slots")
    check(masks.slots[1] == null, "02 empty reserve")
    var hp_before := health.current_health
    health.current_health = 60
    posture.current_posture = 45.0
    defense.air_dash_available = false
    combat.combo_next_stage = 2
    combat.combo_wait_remaining = 0.2
    check(masks.swap(), "03 switch to empty slot")
    check(combat.combo_next_stage == 1 and combat.combo_wait_remaining == 0.0, "swap does not carry combo stage across movesets")
    check(not masks.swap() and masks.swap_cooldown_remaining > 0.0, "04 global swap cooldown")
    check(health.current_health == 60, "05 swap does not heal")
    check(is_equal_approx(posture.current_posture, 45.0), "06 swap preserves Posture")
    check(not defense.is_iframe_active(), "07 swap grants no i-frame")
    check(not defense.air_dash_available, "swap preserves Air Dash availability")
    masks.activate_slot_for_setup(0)
    state.skill_1_remaining = 6.0
    masks.activate_slot_for_setup(1)
    masks.tick(2.0)
    check(is_equal_approx(state.skill_1_remaining, 4.0), "08 inactive cooldown ticks")
    masks.activate_slot_for_setup(0)
    state.ultimate_remaining = 5.0
    state.ultimate_cooldown_remaining = 25.0
    masks.swap_cooldown_remaining = 0.0
    check(masks.swap() and state.ultimate_remaining == 0.0 and state.ultimate_cooldown_remaining == 25.0, "09 Ultimate ends on swap; cooldown remains")
    masks.activate_slot_for_setup(0)
    var baseline := locomotion.run_speed
    masks.activate_slot_for_setup(0)
    check(is_equal_approx(locomotion.run_speed, baseline) and is_equal_approx(float(health.current_health) / health.max_health, 0.6), "10 modifiers do not stack; HP ratio remains")
    var probe := hit(target, CARRASCO.light_1)
    state.prepare_hit(probe)
    check(DamageResolver.health_amount(probe, null, null) == 36, "11 +20 percent physical")
    check(DamageResolver.posture_amount(probe, null) == 20, "12 +25 percent Posture")
    check(is_equal_approx(locomotion.run_speed, 160.0) and is_equal_approx(locomotion.run_speed, masks.base_speed * CARRASCO.move_speed_multiplier), "13 Carrasco P40 = 160 with movement -8 percent")
    check(is_equal_approx(defense.parry_active_seconds, 0.16) and is_equal_approx(defense.parry_posture_multiplier, 1.2), "canonical Parry window and Carrasco return")
    check(health.current_health < hp_before and health.max_health == 100 and posture.max_posture == 100.0, "Carrasco does not add HP or Posture")

    state.add_stacks(target, 8)
    check(state.stacks_for(target) == 5, "14 Condemnation cap 5")
    state.consume_stacks(target, 5)
    state.on_hit(hit(target, CARRASCO.heavy))
    check(state.stacks_for(target) == 1, "15 valid Heavy +1")
    var parry := hit(target, CARRASCO.heavy)
    parry.attacker = other
    state.on_parry(parry)
    check(state.stacks_for(other) == 1 and state.stacks_for(target) == 1, "16 perfect Parry binds the correct attacker")
    state.on_hit(hit(target, CARRASCO.light_1, true))
    check(state.stacks_for(target) == 3, "17 Carrasco-caused Rupture +2")
    var mark := hit(target, CARRASCO.skill_2)
    mark.outcome = HitContext.Outcome.CONTACT
    state.on_hit(mark)
    check(state.stacks_for(target) == 5, "18 Mark +2")
    state.tick(3.0)
    state.add_stacks(target, 1)
    check(is_equal_approx(state.time_for(target), 10.0), "19 new application refreshes timer")
    var target_posture := target.get_node("Posture") as PostureComponent
    target_posture.broken = true
    state.tick(2.0)
    check(is_equal_approx(state.time_for(target), 10.0), "20 timer freezes during target Rupture")
    target_posture.broken = false
    state.tick(2.0)
    check(is_equal_approx(state.time_for(target), 8.0), "21 timer resumes after Rupture")
    masks.activate_slot_for_setup(1)
    masks.tick(2.0)
    check(is_equal_approx(state.time_for(target), 6.0), "22 timer runs while Carrasco is reserve")
    var mock := MaskData.new()
    mock.mask_id = &"test_only"
    mock.display_name = "Test only"
    mock.heavy = CARRASCO.heavy
    masks.equip(1, mock)
    var mock_hit := hit(target, CARRASCO.heavy)
    masks.prepare_hit(mock_hit)
    check(is_zero_approx(mock_hit.posture_attack_bonus), "23 mock mask receives no Condemnation bonus")
    var hp_fraction := float(health.current_health) / float(health.max_health)
    var posture_fraction := posture.current_posture / posture.max_posture
    mock.max_health_multiplier = 1.2
    mock.max_posture_multiplier = 1.5
    masks.equip(1, mock)
    check(health.max_health == 120 and posture.max_posture == 150.0 and is_equal_approx(float(health.current_health) / health.max_health, hp_fraction) and is_equal_approx(posture.current_posture / posture.max_posture, posture_fraction), "future mask max HP/Posture changes preserve percentages")
    masks.activate_slot_for_setup(0)
    check(health.max_health == 100 and posture.max_posture == 100.0, "base maxima return without stacking")
    masks.equip(1, CARRASCO)
    check(masks.slots[1] != state and masks.slots[1].data == state.data, "same configuration creates independent slot state")
    masks.equip(1, null)
    state.consume_stacks(target, 5)
    state.add_stacks(target, 3)
    probe = hit(target, CARRASCO.light_1)
    state.prepare_hit(probe)
    check(is_equal_approx(probe.posture_attack_bonus, 0.34), "24 three stacks give +9 percent on top of Carrasco +25")
    check(CARRASCO.skill_1.base_damage == 50 and CARRASCO.skill_1.posture_damage == 70 and CARRASCO.skill_1_cooldown == 8.0, "25 Seal Break 50/70, 8s")
    var unprotected := hit(other, CARRASCO.skill_1)
    state.prepare_hit(unprotected)
    (other.get_node("DefenseStats") as DefenseStats).shield_protection = true
    var protected := hit(other, CARRASCO.skill_1)
    state.prepare_hit(protected)
    check(is_equal_approx(protected.posture_damage_multiplier / unprotected.posture_damage_multiplier, 1.5), "Seal Break bonus only on explicit protection")
    var prior := state.stacks_for(other)
    state.skill_2_remaining = 0.0
    combat.abort_attack()
    check(masks.use_skill(2) and state.stacks_for(other) == prior, "26 Mark only applies on hit")
    combat.abort_attack()
    state.add_stacks(target, 3)
    state.on_hit(mark)
    var buffed := hit(target, CARRASCO.light_1)
    state.prepare_hit(buffed)
    var unbuffed := hit(other, CARRASCO.light_1)
    state.prepare_hit(unbuffed)
    check(state.buff_for(target) > 0.0 and is_equal_approx(buffed.physical_attack_bonus - unbuffed.physical_attack_bonus, 0.2), "27 Mark +20 percent is target-specific")
    state.ultimate_cooldown_remaining = 0.0
    check(masks.use_ultimate() and is_equal_approx(state.ultimate_remaining, 8.0), "28 Tribunal 8s")
    probe = hit(other, CARRASCO.light_1)
    state.prepare_hit(probe)
    check(is_equal_approx(probe.physical_attack_bonus, 0.5), "29 Tribunal +30 percent physical")
    check(is_equal_approx(probe.posture_attack_bonus, 0.65 + 0.03 * state.stacks_for(other)), "30 Tribunal +40 percent Posture")
    state.consume_stacks(other, 5)
    state.on_hit(hit(other, CARRASCO.heavy))
    check(state.stacks_for(other) == 2, "31 Tribunal Heavy +2")
    state.end_ultimate()

    var victim := DUMMY.instantiate()
    arena.add_child(victim)
    victim.global_position = Vector2(1100, 214)
    await frames(2)
    var victim_health := victim.get_node("Health") as HealthComponent
    var victim_posture := victim.get_node("Posture") as PostureComponent
    state.add_stacks(victim, 3)
    victim_posture.broken = true
    victim_posture.rupture_remaining = 2.0
    victim_health.current_health = 75
    check(not ExecutionResolver.is_eligible(state, victim), "32 common requires HP strictly below 15 percent")
    victim_health.current_health = 74
    check(ExecutionResolver.is_eligible(state, victim), "32 common eligible with HP<15, Rupture, 3 stacks")
    player.global_position = Vector2(1060, 215)
    player.velocity = Vector2.ZERO
    await frames(2)
    check(ExecutionResolver.execute(state, player, victim) == ExecutionResolver.Result.COMMON_KILL and victim_health.current_health == 0, "33 technical common execution kills")
    victim.reset_dummy()
    victim.set_meta("execution_tier", &"elite")
    state.add_stacks(victim, 5)
    victim_posture.broken = true
    victim_posture.rupture_remaining = 2.0
    var elite_before := victim_health.current_health
    check(ExecutionResolver.execute(state, player, victim) == ExecutionResolver.Result.STRIKE and victim_health.current_health > 0 and victim_health.current_health < elite_before, "34 elite receives strike, no forced kill")
    check(state.stacks_for(victim) == 2, "35 elite consumes three stacks")
    victim.reset_dummy()
    var ruptures := [0]
    victim_posture.ruptured.connect(func() -> void: ruptures[0] += 1)
    victim_posture.current_posture = 1.0
    var lethal := hit(victim, CARRASCO.heavy)
    lethal.base_damage = victim_health.current_health
    victim_health.receive_hit(lethal)
    check(victim_health.current_health == 0 and ruptures[0] == 0 and not lethal.caused_rupture, "36 lethal damage suppresses Rupture")
    check(player.collision_mask == 1 and not player.get_collision_exceptions().has(arena.get_node("Peregrino")), "37 Carrasco has no Phase Dash collision exception")

    # Input/scene integration: controls route through the current Player and AttackData.
    combat.abort_attack()
    masks.activate_slot_for_setup(0)
    state.skill_1_remaining = 0.0
    Input.action_press("mask_skill_1")
    await frames(2)
    Input.action_release("mask_skill_1")
    check(combat.current_attack == CARRASCO.skill_1 and state.skill_1_remaining > 0.0, "InputMap Skill 1 routes into PlayerCombat")
    combat.abort_attack()
    state.skill_2_remaining = 0.0
    Input.action_press("mask_skill_2")
    await frames(2)
    Input.action_release("mask_skill_2")
    check(combat.current_attack == CARRASCO.skill_2 and state.skill_2_remaining > 0.0, "InputMap Skill 2 routes into PlayerCombat")
    combat.abort_attack()
    combat.combo_next_stage = 2
    combat.combo_wait_remaining = 0.2
    combat.accept_inputs(true, false)
    check(combat.current_attack == CARRASCO.light_2, "Carrasco Light 2 routes through existing combo")
    combat.abort_attack()
    combat.combo_next_stage = 3
    combat.combo_wait_remaining = 0.2
    combat.accept_inputs(true, false)
    check(combat.current_attack == CARRASCO.light_3, "Carrasco Light 3 routes through existing combo")
    combat.abort_attack()
    combat.accept_inputs(false, true)
    check(combat.current_attack == CARRASCO.heavy, "Carrasco Heavy replaces human Heavy")
    combat.abort_attack()
    combat.accept_inputs(true, false, PlayerDefense.Mode.DODGING)
    check(combat.current_attack == CARRASCO.post_dodge, "Carrasco Post-Dodge uses universal Dash attack path")
    combat.abort_attack()
    combat.accept_inputs(true, false, PlayerDefense.Mode.AIR_DASH)
    check(combat.current_attack == CARRASCO.air_light, "Carrasco Air Light uses universal air path")
    combat.abort_attack()
    combat.accept_inputs(false, true, PlayerDefense.Mode.AIR_DASH)
    check(combat.current_attack == CARRASCO.air_heavy, "Carrasco Air Heavy uses universal air path")
    combat.abort_attack()
    masks.equip(1, null)
    masks.activate_slot_for_setup(0)
    masks.swap_cooldown_remaining = 0.0
    Input.action_press("mask_swap")
    await frames(2)
    Input.action_release("mask_swap")
    check(masks.active_slot == 1, "InputMap swap routes into two-slot controller")

    # A real AttackPivot/Hitbox/Hurtbox cycle, including a contact-only Mark.
    masks.activate_slot_for_setup(0)
    masks.swap_cooldown_remaining = 0.0
    state.consume_stacks(target, 5)
    (target.get_node("Health") as HealthComponent).reset_health()
    target_posture.reset_posture()
    player.global_position = Vector2(365, 215)
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    combat.set_facing(1)
    await frames(5)
    var dummy_health_before := (target.get_node("Health") as HealthComponent).current_health
    check(combat.accept_inputs(true, false), "real Carrasco Light starts")
    await frames(35)
    check((target.get_node("Health") as HealthComponent).current_health < dummy_health_before, "Carrasco Light resolves through existing hitbox")
    combat.abort_attack()
    state.skill_2_remaining = 0.0
    var stacks_before_real_mark := state.stacks_for(target)
    var health_before_mark := (target.get_node("Health") as HealthComponent).current_health
    check(masks.use_skill(2), "real Mark starts")
    await frames(40)
    check(state.stacks_for(target) == mini(5, stacks_before_real_mark + 2) and (target.get_node("Health") as HealthComponent).current_health == health_before_mark, "real Mark contact applies stacks without invented damage")
    combat.abort_attack()
    target.reset_dummy()
    state.clear_target(target)
    target_posture.current_posture = 35.0
    check(combat.accept_inputs(false, true), "real Carrasco Heavy starts")
    await frames(55)
    check(target_posture.is_ruptured() and state.stacks_for(target) == 3, "real Heavy causing Rupture adds 1+2 exactly once")

    # The same physical collision used by enemy bodies remains active during Dash.
    combat.abort_attack()
    player.global_position = Vector2(965, 215)
    player.velocity = Vector2.ZERO
    await frames(5)
    defense.mode = PlayerDefense.Mode.READY
    defense.dodge_cooldown = 0.0
    defense.accept_inputs(true, false, 1.0, 1, false)
    await frames(20)
    check(defense.mode == PlayerDefense.Mode.DODGING and player.global_position.x < other.global_position.x - 10.0, "37 real Dash remains blocked by solid opponent body")
    defense.mode = PlayerDefense.Mode.READY

    # The existing successful Parry signal must reach the correct mask state.
    combat.abort_attack()
    defense.mode = PlayerDefense.Mode.PARRYING
    defense.elapsed = 0.0
    defense.parry_consumed = false
    var parry_before := state.stacks_for(other)
    var incoming := hit(player, CARRASCO.light_1)
    incoming.attacker = other
    incoming.attacker_posture = other.get_node("Posture") as PostureComponent
    check(defense.try_defend(incoming) and state.stacks_for(other) == mini(5, parry_before + 1), "successful PlayerDefense Parry adds stack to actual attacker")
    defense.mode = PlayerDefense.Mode.READY
    state.ultimate_cooldown_remaining = 0.0
    Input.action_press("mask_ultimate")
    await frames(2)
    Input.action_release("mask_ultimate")
    check(state.ultimate_remaining > 0.0 and state.ultimate_cooldown_remaining > 0.0, "InputMap Ultimate routes into mask runtime")

    # Movement and camera still use the original controller with the active mask.
    state.end_ultimate()
    player.global_position = Vector2(320, 215)
    player.velocity = Vector2.ZERO
    await frames(5)
    Input.action_press("move_right")
    await frames(15)
    Input.action_release("move_right")
    check(player.global_position.x > 320.0 and (player.get_node("Camera2D") as PlayerCamera).offset.x > 0.0, "Carrasco moves and camera tracks through original Player")
    var ground_y := player.global_position.y
    Input.action_press("jump")
    await frames(2)
    Input.action_release("jump")
    await frames(8)
    check(player.global_position.y < ground_y, "Carrasco retains universal jump")

    arena.queue_free()
    await frames(2)
    print("MILESTONE 8: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
