extends SceneTree

var failed := false
var scene: Node2D
var player: CharacterBody2D
var combat: PlayerCombat
var defense: PlayerDefense
var player_health: HealthComponent
var player_posture: PostureComponent
var player_stats: DefenseStats
var dummy: StaticBody2D
var dummy_health: HealthComponent
var dummy_posture: PostureComponent
var training: StaticBody2D
var training_health: HealthComponent
var training_posture: PostureComponent


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func press(action: StringName) -> void:
    Input.action_press(action)
    await wait_frames(2)
    Input.action_release(action)


func reset_player(x := 374.0) -> void:
    combat.abort_attack()
    player_health.reset_health()
    player_posture.reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    player.get_node("VisualRoot").modulate = Color.WHITE
    player.global_position = Vector2(x, 215)
    player.velocity = Vector2.ZERO
    player.set("facing_direction", 1)
    combat.set_facing(1)
    defense.set_facing(1)
    await wait_frames(5)


func training_context(attack: AttackData) -> HitContext:
    var context := HitContext.new()
    context.attacker = training
    context.attacker_posture = training_posture
    context.attacker_stats = training.get_node("DefenseStats")
    context.target = player
    context.attack_id = attack.attack_id
    context.action_uid = HitContext.allocate_action_id()
    context.hit_uid = context.action_uid
    context.base_damage = attack.base_damage
    context.posture_damage = attack.posture_damage
    context.parry_class = attack.parry_class
    context.damage_type = attack.damage_type
    context.tags = attack.tags.duplicate()
    return context


func run_checks() -> void:
    scene = load("res://scenes/test_room.tscn").instantiate()
    root.add_child(scene)
    player = scene.get_node("Player")
    combat = player.get_node("Combat")
    defense = player.get_node("Defense")
    player_health = player.get_node("Health")
    player_posture = player.get_node("Posture")
    player_stats = player.get_node("DefenseStats")
    dummy = scene.get_node("Dummy")
    dummy_health = dummy.get_node("Health")
    dummy_posture = dummy.get_node("Posture")
    training = scene.get_node("TrainingDevice")
    training_health = training.get_node("Health")
    training_posture = training.get_node("Posture")

    check(InputMap.action_get_events("dodge").size() == 2 and InputMap.action_get_events("parry").size() == 2, "Dodge and Parry keyboard/controller mappings")
    check(player_health.max_health == 100 and player_posture.max_posture == 100.0, "canonical player HP and Posture")
    check(is_equal_approx(player_posture.regen_delay_seconds, 1.5) and is_equal_approx(player_posture.regen_per_second, 25.0), "configured player Posture recovery")
    check(is_equal_approx(defense.dodge_total_seconds, .4) and is_equal_approx(defense.iframe_end_seconds - defense.iframe_start_seconds, .18), "Dodge and i-frame durations")
    check(is_equal_approx(defense.parry_active_seconds, .16) and is_equal_approx(defense.parry_total_seconds, .38), "Parry window and recovery")

    var stats := DefenseStats.new()
    stats.defense = .30
    stats.magical_resistance = .20
    stats.posture_resistance = .20
    var math_hit := HitContext.new()
    math_hit.base_damage = 100
    math_hit.posture_damage = 25
    math_hit.damage_type = &"magical"
    check(DamageResolver.health_amount(math_hit, stats, null) == 56, "100 magical with 30% Defense and 20% Resistance = 56")
    math_hit.damage_type = &"physical"
    stats.physical_resistance = .20
    check(DamageResolver.health_amount(math_hit, stats, null) == 56, "physical Resistance also follows Defense multiplicatively")
    math_hit.damage_type = &"magical"
    check(DamageResolver.posture_amount(math_hit, stats) == 20, "25 Posture with 20% Posture Resistance = 20")
    stats.physical_resistance = .45
    stats.defense = .70
    check(DamageResolver.posture_amount(math_hit, stats) == 20, "Defense and physical resistance do not reduce Posture")
    stats.defense = .15 + .10
    check(is_equal_approx(stats.effective_defense(), .25), "Defense bonuses add within their attribute")
    stats.defense = .95
    check(is_equal_approx(stats.effective_defense(), .70), "normal Defense cap is 70%")
    stats.temporary_defense = .20
    check(is_equal_approx(stats.effective_defense(), .85), "temporary Defense respects 85% safety ceiling")
    stats.temporary_defense = 0.0
    stats.posture_resistance = 0.0
    math_hit.posture_damage_multiplier = 1.4
    check(DamageResolver.posture_amount(math_hit, stats) == 35, "+40% Posture damage scales 25 to 35")
    math_hit.bypass_defense = true
    check(DamageResolver.health_amount(math_hit, stats, null) == 80, "Defense bypass can retain compatible magical Resistance")
    stats.vulnerability_bonus = .4
    math_hit.direct_life_loss = true
    check(DamageResolver.health_amount(math_hit, stats, null) == 100, "direct life loss stays distinct from mitigated damage")
    stats.free()

    await reset_player()
    player_posture.receive_damage(30)
    check(is_equal_approx(player_posture.current_posture, 70), "player loses Posture independently of HP")
    await wait_frames(75)
    check(is_equal_approx(player_posture.current_posture, 70), "no regeneration before 1.5 seconds")
    player_posture.receive_damage(10)
    await wait_frames(75)
    check(is_equal_approx(player_posture.current_posture, 60), "new Posture hit resets delay")
    await wait_frames(25)
    check(player_posture.current_posture > 60 and player_posture.current_posture < 66, "Posture regenerates near 25 per second after delay")

    await reset_player()
    player_posture.receive_damage(100)
    check(player_posture.is_ruptured() and defense.mode == PlayerDefense.Mode.STAGGERED, "player Rupture enters stagger")
    await press(&"attack_light")
    await press(&"dodge")
    await press(&"parry")
    check(not combat.is_busy() and defense.mode == PlayerDefense.Mode.STAGGERED, "stagger blocks attack, Dodge and Parry")
    await wait_frames(52)
    check(not player_posture.is_ruptured() and defense.mode == PlayerDefense.Mode.READY and player_posture.current_posture >= 50, "stagger ends and restores about half Posture")
    player_posture.receive_damage(100)
    check(not player_posture.is_ruptured() and player_posture.current_posture >= 1, "brief post-rupture protection stops immediate re-break")
    await wait_frames(24)
    player_posture.receive_damage(10)
    check(player_posture.is_ruptured(), "new Rupture is possible after protection ends")

    await reset_player()
    await press(&"attack_heavy")
    check(combat.is_busy(), "Heavy starts before interruption")
    await press(&"dodge")
    await press(&"parry")
    check(combat.is_busy() and defense.mode == PlayerDefense.Mode.READY, "Dodge and Parry cannot cancel committed attack")
    player_posture.receive_damage(100)
    check(not combat.is_busy() and defense.mode == PlayerDefense.Mode.STAGGERED, "Rupture interrupts active player attack")
    var stagger_hit := training_context(training.get("parryable_attack"))
    stagger_hit.base_damage = 50
    player_health.receive_hit(stagger_hit)
    check(stagger_hit.actual_damage == 50 and player_health.current_health == 50, "player Rupture grants no automatic 20% vulnerability")

    await reset_player(1000)
    Input.action_press("move_left")
    await press(&"dodge")
    Input.action_release("move_left")
    check(defense.mode == PlayerDefense.Mode.DODGING and defense.dodge_direction == -1 and player.velocity.x < 0, "Dodge starts in left input direction")
    check(not defense.is_iframe_active(), "Dodge startup is hittable")
    var dodge_start := player.global_position.x
    var camera_start: float = player.get_node("Camera2D").get_screen_center_position().x
    await wait_frames(6)
    check(defense.is_iframe_active() and player.global_position.x < dodge_start, "i-frame starts and Dodge moves left")
    check(player.get_node("Camera2D").get_screen_center_position().x < camera_start, "camera keeps tracking during Dodge")
    var dodged := training_context(training.get("parryable_attack"))
    check(player_health.receive_hit(dodged) and dodged.outcome == HitContext.Outcome.DODGED and player_health.current_health == 100 and player_posture.current_posture == 100, "eligible attack during i-frame is a true miss")
    await wait_frames(12)
    check(not defense.is_iframe_active() and defense.mode == PlayerDefense.Mode.DODGING, "Dodge tail is outside i-frames")
    var tail_hit := training_context(training.get("parryable_attack"))
    player_health.receive_hit(tail_hit)
    check(tail_hit.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 82 and player_posture.current_posture == 88, "Dodge tail receives HP and Posture damage")
    await wait_frames(8)
    check(defense.mode == PlayerDefense.Mode.READY and defense.dodge_cooldown > 0, "Dodge ends with repeat delay")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.READY, "repeat delay blocks immediate Dodge")
    await wait_frames(20)
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.DODGING, "Dodge becomes available after repeat delay")

    await reset_player(1000)
    await press(&"jump")
    check(not player.is_on_floor(), "player is airborne before Air Dash check")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not defense.air_dash_available, "airborne Dodge now starts the one-use Air Dash")

    await reset_player()
    training.call("reset_device")
    await press(&"parry")
    check(defense.is_parry_active(), "Parry opens within its active window")
    var parried := training_context(training.get("parryable_attack"))
    player_health.receive_hit(parried)
    check(parried.outcome == HitContext.Outcome.PARRIED and player_health.current_health == 100 and player_posture.current_posture == 100, "valid Parry negates both HP and Posture")
    check(parried.parry_posture_return == 12 and training_posture.current_posture == 28, "Parry returns attack Posture pressure to attacker")
    check(root.get_node("HitStop").last_requested_ms == 80, "Parry uses dominant 80 ms hit stop")
    root.get_node("HitStop").request_ms(30, 1)
    check(root.get_node("HitStop").last_requested_ms == 80, "weaker simultaneous hit stop cannot replace Parry feedback")
    var followup := training_context(training.get("parryable_attack"))
    player_health.receive_hit(followup)
    check(followup.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 82, "Parry resolves one hit, not a whole multi-hit sequence")

    await reset_player()
    training.call("reset_device")
    training.get_node("DefenseStats").posture_resistance = .20
    await press(&"parry")
    var resisted_parry := training_context(training.get("parryable_attack"))
    player_health.receive_hit(resisted_parry)
    check(resisted_parry.parry_posture_return == 10 and training_posture.current_posture == 30, "attacker Posture Resistance mitigates Parry return")
    training.get_node("DefenseStats").posture_resistance = 0.0

    await reset_player()
    await press(&"parry")
    await wait_frames(11)
    check(not defense.is_parry_active() and defense.mode == PlayerDefense.Mode.PARRYING, "early Parry enters recovery")
    var early := training_context(training.get("parryable_attack"))
    player_health.receive_hit(early)
    check(early.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 82, "attack in Parry recovery hits normally")
    await press(&"parry")
    check(defense.mode == PlayerDefense.Mode.PARRYING and defense.elapsed > defense.parry_active_seconds, "Parry cannot spam during recovery")
    await wait_frames(20)
    check(defense.mode == PlayerDefense.Mode.READY, "Parry recovery ends")

    await reset_player()
    training.call("reset_device")
    await press(&"parry")
    var unparable := training_context(training.get("heavy_attack"))
    player_health.receive_hit(unparable)
    check(unparable.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 70 and player_posture.current_posture == 75, "non-parryable Heavy bypasses Parry without extra penalty")
    check(is_zero_approx(training_posture.current_posture - 40.0), "failed Heavy Parry does not damage attacker Posture")

    await reset_player()
    var late := training_context(training.get("parryable_attack"))
    player_health.receive_hit(late)
    await press(&"parry")
    check(late.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 82, "late Parry cannot retroactively cancel impact")

    await reset_player()
    dummy.call("reset_dummy")
    dummy_posture.receive_damage(40)
    check(dummy_posture.is_ruptured(), "dummy enters Rupture at zero Posture")
    var vulnerable := HitContext.new()
    vulnerable.attacker = player
    vulnerable.base_damage = 100
    vulnerable.damage_type = &"physical"
    vulnerable.posture_damage = 0
    dummy_health.receive_hit(vulnerable)
    check(vulnerable.actual_damage == 120 and dummy_health.current_health == 380 and is_zero_approx(dummy.get_node("DefenseStats").defense), "Rupture adds 20% vulnerability without changing Defense")
    await wait_frames(125)
    check(not dummy_posture.is_ruptured() and dummy_posture.current_posture >= 20, "dummy Rupture lasts about two seconds and restores half Posture")

    await reset_player()
    dummy.call("reset_dummy")
    dummy_health.current_health = 10
    dummy_posture.current_posture = 5
    var lethal := HitContext.new()
    lethal.attacker = player
    lethal.base_damage = 20
    lethal.posture_damage = 10
    lethal.damage_type = &"physical"
    dummy_health.receive_hit(lethal)
    check(lethal.outcome == HitContext.Outcome.DEAD and dummy_health.current_health == 0 and not dummy_posture.is_ruptured(), "simultaneous HP/Posture zero resolves as death")

    await reset_player()
    player_health.current_health = 10
    player_posture.current_posture = 5
    var player_lethal := training_context(training.get("parryable_attack"))
    player_health.receive_hit(player_lethal)
    check(player_lethal.outcome == HitContext.Outcome.DEAD and defense.mode == PlayerDefense.Mode.DEAD and not player_posture.is_ruptured(), "player death also precedes Rupture")

    await reset_player()
    dummy.call("reset_dummy")
    training.call("reset_device")
    dummy.global_position.x = 1000
    training.global_position.x = 400
    await wait_frames(5)
    check(training.call("trigger_attack", false), "training device starts parryable attack")
    check(training.get_node("AttackPivot/Telegraph").visible, "parryable telegraph is localized")
    for _i in range(80):
        if training.get("elapsed") >= .35:
            break
        await physics_frame
    await press(&"parry")
    await wait_frames(25)
    var actual: HitContext = training.get("last_context")
    check(actual != null and actual.outcome == HitContext.Outcome.PARRIED and player_health.current_health == 100, "real hitbox/hurtbox Parry integration")

    await reset_player()
    training.call("reset_device")
    await wait_frames(5)
    check(training.call("trigger_attack", true), "training device starts heavy non-parryable attack")
    check(training.get_node("AttackPivot/Telegraph").color.r > .7 and training.get_node("HeavyCueAudio").playing, "heavy telegraph and low cue stay local")
    for _i in range(100):
        if training.get("elapsed") >= .60:
            break
        await physics_frame
    await press(&"parry")
    await wait_frames(30)
    actual = training.get("last_context")
    check(actual != null and actual.outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 70 and player_posture.current_posture <= 75, "real non-parryable hitbox defeats Parry")

    await reset_player()
    training.call("reset_device")
    await wait_frames(5)
    training.call("trigger_attack", false)
    for _i in range(80):
        if training.get("elapsed") >= .34:
            break
        await physics_frame
    await press(&"dodge")
    await wait_frames(25)
    actual = training.get("last_context")
    check(actual != null and actual.outcome == HitContext.Outcome.DODGED and player_health.current_health == 100 and player_posture.current_posture == 100, "real hitbox misses during Dodge i-frame")

    await reset_player()
    training.call("reset_device")
    await wait_frames(5)
    await press(&"attack_light")
    await wait_frames(40)
    check(training_health.current_health == 180 and is_equal_approx(training_posture.current_posture, 32), "player sword applies separate HP and Posture to training target")

    await reset_player()
    training.global_position.x = 1000
    dummy.global_position.x = 400
    dummy.call("reset_dummy")
    await wait_frames(5)
    await press(&"attack_heavy")
    await wait_frames(55)
    check(dummy_health.current_health == 465 and dummy_posture.current_posture <= 15 and dummy_posture.current_posture > 14, "existing Heavy deals 35 HP and 25 Posture to dummy")

    print("FINAL: ", "FAILED" if failed else "PASSED")
    quit(1 if failed else 0)
