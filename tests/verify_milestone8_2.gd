extends SceneTree

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
var failed := false


func _initialize() -> void:
    call_deferred("run_checks")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(value: bool, description: String) -> void:
    if value:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func run_checks() -> void:
    var arena := load("res://scenes/test/carrasco_arena.tscn").instantiate() as Node2D
    root.add_child(arena)
    arena.get_node("Peregrino").process_mode = Node.PROCESS_MODE_DISABLED
    await frames(5)
    var player := arena.get_node("TestRoom/Player") as CharacterBody2D
    var visual := player.get_node("VisualRoot") as PlayerVisualController
    var masks := player.get_node("MaskController") as MaskController
    # Preserve the legacy artwork checks; Pequeno A has its own acceptance suite.
    visual.small_carrasco_enabled = false
    visual._on_mask_changed(masks.active_data())
    var combat := player.get_node("Combat") as PlayerCombat
    var defense := player.get_node("Defense") as PlayerDefense
    var state := masks.active_state() as CarrascoRuntimeState
    var dummy := arena.get_node("TestRoom/Dummy") as Node2D

    check(CARRASCO.visual_scene != null and visual.form != null, "Carrasco loads independent visual scene")
    check(visual.form.sprite.texture != null and visual.form.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Carrasco artwork loads with nearest filtering")
    check(visual.get_node("Head").visible == false, "base human placeholder is hidden while masked")
    check(visual.blade.modulate.a == 0.0 and visual.handle.modulate.a == 0.0, "old technical sword is hidden behind authored axe")
    check(visual.active_marker.modulate.a == 0.0 and visual.charge_marker.modulate.a == 0.0, "technical active markers are visually hidden")
    check((player.get_node("CollisionShape2D") as CollisionShape2D).shape is CapsuleShape2D and (player.get_node("CollisionShape2D") as CollisionShape2D).shape.height == 26.0, "player collider remains 26 px")
    check(visual._state_name() == &"idle", "idle pose follows gameplay")
    Input.action_press("move_right")
    await frames(8)
    check(visual._state_name() == &"run", "run pose follows horizontal movement")
    Input.action_release("move_right")
    Input.action_press("jump")
    await frames(2)
    Input.action_release("jump")
    check(visual._state_name() == &"jump", "jump pose follows upward velocity")
    await frames(24)
    check(visual._state_name() == &"fall" or player.is_on_floor(), "fall pose follows descent")
    await frames(30)
    player.global_position = Vector2(320, 215)
    player.velocity = Vector2.ZERO
    await frames(3)

    Input.action_press("attack_light")
    await frames(2)
    Input.action_release("attack_light")
    check(combat.current_attack == CARRASCO.light_1 and visual._state_name() == &"carrasco_light_1", "Light 1 uses its own visual pose")
    check(not combat.hitbox.active, "hitbox stays disarmed during visual windup")
    await frames(10)
    check(combat.phase == PlayerCombat.Phase.ACTIVE and combat.hitbox.active, "visual active phase matches existing hitbox phase")
    combat.abort_attack()
    await frames(2)

    Input.action_press("attack_heavy")
    await frames(2)
    check(visual._state_name() == &"charge" and not combat.charge_ready(), "charge pose begins before threshold")
    await frames(70)
    check(combat.charge_ready() and visual.form.charged_ready, "ready pose follows one second threshold")
    Input.action_release("attack_heavy")
    await frames(2)
    check(visual._state_name() == &"carrasco_charged_heavy", "charged attack has distinct visual pose")
    combat.abort_attack()

    state.add_stacks(dummy, 5)
    await frames(2)
    check(visual.form.marks.has(dummy.get_instance_id()) and visual.form.marks[dummy.get_instance_id()].stacks == 5, "target mark shows five actual Condemnation stacks")
    state.clear_target(dummy)
    await frames(2)
    check(not visual.form.marks.has(dummy.get_instance_id()), "target mark clears with runtime state")
    state.ultimate_remaining = 4.0
    await frames(2)
    check(visual.form.tribunal, "Tribunal aura follows runtime duration")
    state.end_ultimate()
    await frames(2)
    check(not visual.form.tribunal, "Tribunal aura clears on end")

    masks.activate_slot_for_setup(1)
    await frames(2)
    check(visual.form == null and visual.get_node("Head").visible and not visual.get_node("MaskBadge").visible and visual.active_marker.modulate.a == 1.0 and visual.blade.modulate.a == 1.0 and visual.handle.modulate.a == 1.0, "empty second slot restores unmasked human and weapon")
    masks.activate_slot_for_setup(0)
    await frames(2)
    check(visual.form != null and masks.active_state() == state, "return to Carrasco restores visual and same runtime")

    defense.mode = PlayerDefense.Mode.DODGING
    await frames(2)
    check(visual._state_name() == &"ground_dash", "ground dash pose follows defense mode")
    defense.mode = PlayerDefense.Mode.AIR_DASH
    await frames(2)
    check(visual._state_name() == &"air_dash", "air dash pose follows defense mode")
    defense.mode = PlayerDefense.Mode.READY
    for attack in [CARRASCO.light_1, CARRASCO.light_2, CARRASCO.light_3, CARRASCO.heavy, CARRASCO.heavy.charged_variant, CARRASCO.post_dodge, CARRASCO.air_light, CARRASCO.air_heavy, CARRASCO.skill_1, CARRASCO.skill_2]:
        combat.abort_attack()
        check(combat.start_special(attack), "visual can begin %s" % attack.attack_id)
        await frames(2)
        check(visual._state_name() == attack.attack_id and visual.form.pose == attack.attack_id, "visual follows %s" % attack.attack_id)
    combat.abort_attack()
    Input.action_press("move_left")
    await frames(7)
    Input.action_release("move_left")
    check(visual.scale.x == -1.0 and combat.pivot.scale.x == -1.0, "left facing mirrors silhouette and weapon together")
    Input.action_press("move_right")
    await frames(7)
    Input.action_release("move_right")
    check(visual.scale.x == 1.0 and combat.pivot.scale.x == 1.0, "right facing restores silhouette and weapon together")
    check(CARRASCO.light_1.base_damage == 30 and CARRASCO.light_1.posture_damage == 16 and CARRASCO.skill_1.base_damage == 50 and CARRASCO.skill_1.posture_damage == 70, "visual pass preserves sample attack data")
    arena.queue_free()
    await frames(2)
    print("MILESTONE 8.2: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
