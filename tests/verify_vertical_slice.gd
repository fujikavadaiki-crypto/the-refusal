extends SceneTree

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


func tap(action: StringName, count := 2) -> void:
    Input.action_press(action)
    await frames(count)
    Input.action_release(action)


func snapshot(name: String) -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        return
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(args[0])
    var result := root.get_texture().get_image().save_png(args[0].path_join(name + ".png"))
    check(result == OK, "captura renderizada: " + name)


func run_checks() -> void:
    var slice := load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate() as Node2D
    root.add_child(slice)
    await frames(6)
    var player := slice.get_node("Player") as CharacterBody2D
    var locomotion := player.get_node("Locomotion") as PlayerLocomotion
    var defense := player.get_node("Defense") as PlayerDefense
    var combat := player.get_node("Combat") as PlayerCombat
    var camera := player.get_node("Camera2D") as PlayerCamera
    var encounters := slice.encounters as Array[ForestEncounter]
    var form: Node2D = player.get_node("VisualRoot").form
    check(player.is_on_floor() and player.get_node("MaskController").active_data().mask_id == &"carrasco_base" and form.get("package_ready"), "Carrasco pequeno nasce no piso com pacote validado")
    check(encounters.size() == 2 and encounters[0].enemies.size() + encounters[1].enemies.size() == 3, "dois encontros, três inimigos")
    check(camera.limit_right == 3900 and camera.impact_shake_enabled, "câmera da vertical slice configurada")
    await snapshot("01_inicio")

    Input.action_press(&"move_right")
    await frames(15)
    check(player.velocity.x > 95.0, "corrida acelera prontamente")
    Input.action_release(&"move_right")
    Input.action_press(&"move_left")
    await frames(15)
    check(player.velocity.x < -80.0 and player.facing_direction == -1, "inversão responde sem deslizamento longo")
    Input.action_release(&"move_left")

    slice.reset_slice()
    Input.action_press(&"walk")
    Input.action_press(&"move_right")
    await tap(&"dodge")
    await frames(4)
    check(defense.mode == PlayerDefense.Mode.DODGING and player.velocity.x > locomotion.run_speed * 1.5, "dash não é reduzido pelo botão de andar")
    Input.action_release(&"walk")
    Input.action_release(&"move_right")

    slice.reset_slice()
    player.global_position = Vector2(1168, 224)
    player.velocity = Vector2(120, 0)
    Input.action_press(&"move_right")
    await frames(5)
    check(not player.is_on_floor() and player.global_position.x > 1177.0, "jogador deixa a borda do penhasco pintado")
    await tap(&"jump")
    check(player.velocity.y < -150.0, "coyote time aceita salto logo após a borda")
    Input.action_release(&"move_right")

    slice.reset_slice()
    player.global_position = Vector2(500, 204)
    player.velocity = Vector2(0, 100)
    await frames(2)
    await tap(&"jump")
    await frames(8)
    check(player.velocity.y < -100.0, "jump buffer executa salto no pouso")

    slice.reset_slice()
    for encounter in encounters:
        encounter.process_mode = Node.PROCESS_MODE_DISABLED
    var jumps := [false, false, false]
    var dashes := [false, false, false]
    var jump_release := false
    var jump_release_at := -1
    var dash_release := false
    var jump_points := [1135.0, 2368.0, 3645.0]
    var dash_points := [1180.0, 2405.0, 3700.0]
    # Dash near the discrete P40 apex. The former third input at 500 ms
    # froze an already descending jump (new apex ~333 ms), below the far ledge.
    # Only the input route changes; terrain and movement values stay untouched.
    var apex_ticks := ceili(-locomotion.jump_velocity / locomotion.gravity * Engine.physics_ticks_per_second)
    var apex_seconds := float(apex_ticks) / Engine.physics_ticks_per_second
    for index in range(3):
        dash_points[index] = jump_points[index] + locomotion.run_speed * apex_seconds
    Input.action_press(&"move_right")
    for _i in range(3600):
        if jump_release and _i >= jump_release_at:
            Input.action_release(&"jump")
            jump_release = false
        if dash_release:
            Input.action_release(&"dodge")
            dash_release = false
        for index in range(3):
            if not jumps[index] and player.global_position.x >= jump_points[index]:
                Input.action_press(&"jump")
                jump_release = true
                jump_release_at = _i + 25
                jumps[index] = true
                break
            if jumps[index] and not dashes[index] and player.global_position.x >= dash_points[index]:
                Input.action_press(&"dodge")
                dash_release = true
                dashes[index] = true
                break
        await physics_frame
        if slice.finished:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    print("NAV: x=%.1f finished=%s falls=%d elapsed=%.1f" % [player.global_position.x, str(slice.finished), slice.fall_recovery_count, slice.elapsed_seconds])
    check(jumps.all(func(value): return value) and dashes.all(func(value): return value) and slice.finished and slice.fall_recovery_count == 0, "três travessias com salto e air dash sobre vãos visíveis")
    await snapshot("02_saida")

    for encounter in encounters:
        encounter.process_mode = Node.PROCESS_MODE_INHERIT
    slice.reset_slice()
    player.global_position = Vector2(1455, 145)
    await frames(20)
    var pilgrim := encounters[0].enemies[0]
    var starting_hp: int = pilgrim.get_node("Health").current_health
    await tap(&"attack_light")
    await frames(23)
    await tap(&"attack_light")
    await frames(23)
    await tap(&"attack_light")
    await frames(36)
    check(pilgrim.get_node("Health").current_health < starting_hp and combat.confirmed_hit_count > 0, "combo real acerta a hurtbox do Peregrino")
    print("COMBAT: enemy_hp=%d player_hp=%d hits=%d" % [pilgrim.get_node("Health").current_health, player.get_node("Health").current_health, combat.confirmed_hit_count])
    await snapshot("03_combate")
    await tap(&"attack_heavy")
    await frames(60)
    check(combat.current_attack == null, "Heavy conclui startup, active e recovery")

    var hit := HitContext.new()
    hit.attacker = pilgrim
    hit.target = player
    hit.attack_id = &"slice_test"
    hit.action_uid = HitContext.allocate_action_id()
    hit.base_damage = 999
    hit.damage_type = &"physical"
    player.get_node("Health").receive_hit(hit)
    await frames(65)
    check(slice.reset_count > 0 and player.get_node("Health").current_health > 0 and player.global_position.x < 200.0, "morte reinicia a fase e os encontros")
    print("VERTICAL SLICE: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
