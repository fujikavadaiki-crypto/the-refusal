extends SceneTree

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
const DUMMY := preload("res://scenes/test/dummy.tscn")
var failed := false
var arena: Node2D
var player: CharacterBody2D
var masks: MaskController
var state: CarrascoRuntimeState
var combat: PlayerCombat
var defense: PlayerDefense
var dummy: Node2D
var dummy_health: HealthComponent
var dummy_posture: PostureComponent


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


func reset_player_at(x: float) -> void:
    Input.action_release("attack_heavy")
    combat.abort_attack()
    defense.mode = PlayerDefense.Mode.READY
    defense.dodge_cooldown = 0.0
    player.global_position = Vector2(x, 215)
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    combat.set_facing(1)
    await frames(4)


func ready_common(with_tribunal: bool) -> void:
    state.clear_target(dummy)
    dummy.reset_dummy()
    dummy_health.current_health = 74
    state.ultimate_remaining = 8.0 if with_tribunal else 0.0
    state.add_stacks(dummy, 3)
    dummy_posture.current_posture = 1.0
    dummy_posture.receive_damage(2)


func make_tier_target(tier: StringName, target: Node2D) -> void:
    state.clear_target(target)
    target.reset_dummy()
    target.set_meta("execution_tier", tier)
    state.add_stacks(target, 5)
    var posture := target.get_node("Posture") as PostureComponent
    posture.current_posture = 1.0
    posture.receive_damage(2)


func run_checks() -> void:
    arena = load("res://scenes/test/carrasco_arena.tscn").instantiate()
    root.add_child(arena)
    arena.get_node("Peregrino").process_mode = Node.PROCESS_MODE_DISABLED
    await frames(5)
    player = arena.get_node("TestRoom/Player")
    masks = player.get_node("MaskController")
    state = masks.slots[0] as CarrascoRuntimeState
    combat = player.get_node("Combat") as PlayerCombat
    defense = player.get_node("Defense") as PlayerDefense
    dummy = arena.get_node("TestRoom/Dummy")
    dummy_health = dummy.get_node("Health") as HealthComponent
    dummy_posture = dummy.get_node("Posture") as PostureComponent

    check(InputMap.has_action("execute") and InputMap.action_get_events("execute").size() > 0 and not InputMap.has_action("test_execution"), "11 Execution uses semantic InputMap action")
    check(CARRASCO.heavy.charged_variant != null and is_equal_approx(CARRASCO.heavy.charge_threshold_seconds, 1.0), "Charged Heavy configured by reusable AttackData")
    var moves := [
        [CARRASCO.light_1, 30, 16], [CARRASCO.light_2, 34, 18], [CARRASCO.light_3, 44, 28],
        [CARRASCO.heavy, 58, 42], [CARRASCO.heavy.charged_variant, 78, 65],
        [CARRASCO.post_dodge, 32, 18], [CARRASCO.air_light, 34, 22],
        [CARRASCO.air_heavy, 52, 45], [CARRASCO.skill_1, 50, 70]
    ]
    for move in moves:
        check(move[0].base_damage == move[1] and move[0].posture_damage == move[2], "Carrasco base data %s: %d/%d" % [move[0].attack_id, move[1], move[2]])

    await reset_player_at(320)
    Input.action_press("attack_heavy")
    await frames(2)
    check(combat.is_charging() and combat.movement_multiplier() < 1.0, "press Heavy begins mobile reduced-speed charge")
    Input.action_release("attack_heavy")
    await frames(2)
    check(combat.current_attack == CARRASCO.heavy, "01 tap Heavy releases normal Heavy")
    combat.abort_attack()

    await reset_player_at(320)
    Input.action_press("attack_heavy")
    await frames(30)
    check(combat.is_charging() and not combat.charge_ready(), "hold below threshold remains uncharged")
    Input.action_release("attack_heavy")
    await frames(2)
    check(combat.current_attack == CARRASCO.heavy, "02 release below threshold gives normal Heavy")
    combat.abort_attack()

    await reset_player_at(320)
    Input.action_press("attack_heavy")
    await frames(70)
    check(combat.charge_ready() and combat.charge_marker.visible, "charge reaches distinct CHARGED READY feedback")
    Input.action_release("attack_heavy")
    await frames(2)
    check(combat.current_attack == CARRASCO.heavy.charged_variant, "03 hold above threshold releases Charged Heavy")
    check(combat.current_attack.base_damage == 78, "04 Charged Heavy base HP damage 78")
    check(combat.current_attack.posture_damage == 65, "05 Charged Heavy base Posture damage 65")
    combat.abort_attack()

    await reset_player_at(365)
    dummy.reset_dummy()
    Input.action_press("attack_heavy")
    await frames(10)
    Input.action_press("dodge")
    await frames(2)
    Input.action_release("dodge")
    Input.action_release("attack_heavy")
    check(not combat.is_charging() and defense.mode == PlayerDefense.Mode.DODGING, "06 Dodge cancels charge and starts universal Dodge")
    await frames(60)
    check(dummy.hit_count == 0, "07 canceled charge never arms hitbox")
    defense.mode = PlayerDefense.Mode.READY

    await reset_player_at(365)
    dummy.reset_dummy()
    masks.swap_cooldown_remaining = 0.0
    Input.action_press("attack_heavy")
    await frames(10)
    Input.action_press("mask_swap")
    await frames(2)
    Input.action_release("mask_swap")
    Input.action_release("attack_heavy")
    check(masks.active_slot == 1 and not combat.is_charging() and combat.current_attack == null, "08 swap cancels charge without storing it")
    await frames(20)
    check(dummy.hit_count == 0, "swap-canceled charge produces no hit")
    masks.activate_slot_for_setup(0)
    masks.swap_cooldown_remaining = 0.0

    await reset_player_at(365)
    Input.action_press("attack_heavy")
    await frames(8)
    var incoming := HitContext.new()
    incoming.attacker = dummy
    incoming.target = player
    incoming.base_damage = 5
    incoming.damage_type = &"physical"
    incoming.tags = PackedStringArray(["physical"])
    (player.get_node("Health") as HealthComponent).receive_hit(incoming)
    Input.action_release("attack_heavy")
    check(not combat.is_charging() and combat.current_attack == null, "incoming damage interrupts charge")

    await reset_player_at(365)
    dummy_posture.max_posture = 500.0
    dummy.reset_dummy()
    state.clear_target(dummy)
    Input.action_press("attack_heavy")
    await frames(70)
    Input.action_release("attack_heavy")
    await frames(35)
    check(dummy.last_context != null and dummy.last_context.base_damage == 78 and dummy.last_context.posture_damage == 65, "Charged Heavy resolves 78/65 through existing hitbox")
    check(state.stacks_for(dummy) == 1, "09 valid Charged Heavy adds one Condemnation")
    combat.abort_attack()
    state.clear_target(dummy)
    dummy.reset_dummy()
    state.ultimate_remaining = 8.0
    Input.action_press("attack_heavy")
    await frames(70)
    Input.action_release("attack_heavy")
    await frames(35)
    check(state.stacks_for(dummy) == 2, "10 Tribunal Charged Heavy adds two stacks total")
    state.end_ultimate()
    combat.abort_attack()
    dummy_posture.max_posture = 40.0
    dummy.reset_dummy()

    await reset_player_at(365)
    state.clear_target(dummy)
    dummy_health.current_health = 75
    state.add_stacks(dummy, 3)
    check(not ExecutionResolver.is_eligible(state, dummy), "12 common at exactly 15 percent is not eligible")
    state.clear_target(dummy)
    dummy.reset_dummy()
    ready_common(false)
    check(ExecutionResolver.is_eligible(state, dummy), "12 common HP<15, Rupture and three stacks is eligible")
    dummy_posture.rupture_remaining = 0.001
    await frames(2)
    check(not dummy_posture.is_ruptured() and not ExecutionResolver.is_eligible(state, dummy), "13 normal window ends with Rupture")

    ready_common(true)
    var damage_probe := HitContext.new()
    damage_probe.base_damage = 100
    damage_probe.damage_type = &"physical"
    var vulnerable_damage := DamageResolver.health_amount(damage_probe, null, dummy_posture)
    dummy_posture.rupture_remaining = 0.001
    await frames(2)
    var recovered_damage := DamageResolver.health_amount(damage_probe, null, dummy_posture)
    check(ExecutionResolver.is_eligible(state, dummy) and state.extension_for(dummy) > 0.9, "14 Tribunal grants one second of extended opportunity")
    check(not dummy_posture.is_ruptured(), "15 extended window does not prolong physical Rupture")
    check(vulnerable_damage > recovered_damage and recovered_damage == 100, "16 extended window does not prolong Rupture vulnerability")
    var deaths := [0]
    var ruptures := [0]
    dummy_health.depleted.connect(func() -> void: deaths[0] += 1)
    dummy_posture.ruptured.connect(func() -> void: ruptures[0] += 1)
    var before_execution := player.global_position
    Input.action_press("execute")
    await frames(2)
    Input.action_release("execute")
    check(dummy_health.current_health == 0 and deaths[0] == 1, "17 gameplay Input executes common during Tribunal extension")
    check(player.global_position.distance_to(before_execution) < 2.0, "Execution does not teleport Player")
    check(masks.try_execute() == ExecutionResolver.Result.INELIGIBLE and deaths[0] == 1, "24 dead target cannot execute again")
    check(ruptures[0] == 0, "27 execution does not emit duplicate Rupture")
    check(state.stacks_for(dummy) == 0, "common death clears Condemnation target state")

    ready_common(true)
    dummy_posture.rupture_remaining = 0.001
    await frames(2)
    state.tick(1.01)
    check(not ExecutionResolver.is_eligible(state, dummy) and state.extension_for(dummy) == 0.0, "18 common window closes after exact extension")
    check(masks.try_execute() == ExecutionResolver.Result.INELIGIBLE and dummy_health.current_health == 74, "Execution outside window causes no damage")

    ready_common(true)
    dummy_posture.rupture_remaining = 0.001
    await frames(2)
    masks.activate_slot_for_setup(1)
    check(masks.try_execute() == ExecutionResolver.Result.INELIGIBLE and state.extension_for(dummy) > 0.0, "inactive Carrasco retains window but cannot execute")
    state.tick(0.4)
    masks.activate_slot_for_setup(0)
    check(ExecutionResolver.is_eligible(state, dummy), "returning to Carrasco can use remaining window")
    state.tick(0.7)
    check(not ExecutionResolver.is_eligible(state, dummy), "window keeps ticking while Carrasco is reserve")
    ready_common(false)
    state.ultimate_remaining = 8.0
    dummy_posture.rupture_remaining = 0.001
    await frames(2)
    check(not ExecutionResolver.is_eligible(state, dummy), "Tribunal activated after Rupture does not retroactively extend window")

    var elite: Node2D = arena.get_node("EliteDummy")
    await reset_player_at(615)
    for tier in [&"elite", &"miniboss", &"boss"]:
        make_tier_target(tier, elite)
        var elite_health := elite.get_node("Health") as HealthComponent
        var result := masks.try_execute()
        check(result == ExecutionResolver.Result.STRIKE and elite_health.current_health > 0, "%s receives strike, never forced kill" % tier)
        check(state.stacks_for(elite) == 2, "22 %s consumes exactly three stacks" % tier)
    make_tier_target(&"boss", elite)
    var elite_posture := elite.get_node("Posture") as PostureComponent
    elite_posture.rupture_remaining = 0.001
    await frames(2)
    check(not elite_posture.is_ruptured() and ExecutionResolver.is_eligible(state, elite), "elite/boss strike stays available in Tribunal extension")
    check(masks.try_execute() == ExecutionResolver.Result.STRIKE and state.stacks_for(elite) == 2, "extended boss strike consumes three stacks")

    await reset_player_at(300)
    ready_common(false)
    check(not ExecutionResolver.can_reach(player, dummy) and masks.try_execute() == ExecutionResolver.Result.INELIGIBLE and dummy_health.current_health == 74, "23 target outside 52 px cannot execute")
    await reset_player_at(365)
    var wall := StaticBody2D.new()
    wall.collision_layer = 1
    wall.collision_mask = 0
    wall.global_position = Vector2(380, 215)
    var wall_shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(8, 32)
    wall_shape.shape = rectangle
    wall.add_child(wall_shape)
    arena.add_child(wall)
    await frames(2)
    check(not ExecutionResolver.can_reach(player, dummy) and masks.try_execute() == ExecutionResolver.Result.INELIGIBLE, "wall blocks Execution without teleport")
    wall.queue_free()
    await frames(2)
    masks.activate_slot_for_setup(1)
    check(masks.try_execute() == ExecutionResolver.Result.INELIGIBLE and dummy_health.current_health == 74, "25 reserve mask cannot use Carrasco Execution")
    masks.activate_slot_for_setup(0)

    # Two valid overlapping Hurtboxes: nearest wins; equal distance favors facing.
    state.clear_target(dummy)
    dummy.reset_dummy()
    var near := DUMMY.instantiate()
    var far := DUMMY.instantiate()
    arena.add_child(near)
    arena.add_child(far)
    near.global_position = Vector2(385, 214)
    far.global_position = Vector2(402, 214)
    await reset_player_at(350)
    for candidate in [near, far]:
        candidate.get_node("Health").current_health = 74
        state.add_stacks(candidate, 3)
        var candidate_posture := candidate.get_node("Posture") as PostureComponent
        candidate_posture.current_posture = 1.0
        candidate_posture.receive_damage(2)
    await frames(2)
    check(masks.targeting.best_target(state, player) == near, "26 closest eligible target wins")
    state.clear_target(near)
    state.clear_target(far)
    near.global_position = Vector2(325, 214)
    far.global_position = Vector2(375, 214)
    near.reset_dummy()
    far.reset_dummy()
    for candidate in [near, far]:
        candidate.get_node("Health").current_health = 74
        state.add_stacks(candidate, 3)
        var candidate_posture := candidate.get_node("Posture") as PostureComponent
        candidate_posture.current_posture = 1.0
        candidate_posture.receive_damage(2)
    await frames(2)
    check(masks.targeting.best_target(state, player) == far, "26 facing breaks equal-distance tie")

    var lethal_context := HitContext.new()
    lethal_context.target = near
    lethal_context.outcome = HitContext.Outcome.DEAD
    state.on_hit(lethal_context)
    check(state.stacks_for(near) == 0 and not state.targets.has(near.get_instance_id()), "ordinary lethal hit clears target state immediately")

    var ephemeral := DUMMY.instantiate()
    arena.add_child(ephemeral)
    var ephemeral_key := ephemeral.get_instance_id()
    state.add_stacks(ephemeral, 3)
    ephemeral.queue_free()
    await frames(2)
    state.tick(0.01)
    check(not state.targets.has(ephemeral_key), "freed target leaves no Condemnation or window reference")

    arena.queue_free()
    await frames(2)
    print("MILESTONE 8.1: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
