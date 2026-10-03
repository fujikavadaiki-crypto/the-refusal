extends SceneTree

var jump_ticket := 0

var failed := false
var room: Node2D
var player: CharacterBody2D
var defense: PlayerDefense
var combat: PlayerCombat
var health: HealthComponent
var posture: PostureComponent
var locomotion: PlayerLocomotion
var camera: PlayerCamera
var enemy: CharacterBody2D
var enemy_contacts: Array[HitContext] = []
var player_hits: Array[HitContext] = []
var air_dash_starts := 0


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func press(action: StringName) -> void:
    Input.action_press(action)
    await wait_frames(2)
    if action == &"jump":
        release_full_jump()
    else:
        Input.action_release(action)


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func bind_player(new_player: CharacterBody2D) -> void:
    player = new_player
    defense = player.get_node("Defense")
    combat = player.get_node("Combat")
    health = player.get_node("Health")
    posture = player.get_node("Posture")
    locomotion = player.get_node("Locomotion")
    camera = player.get_node("Camera2D")
    defense.air_dash_started.connect(func(_direction: int) -> void: air_dash_starts += 1)
    combat.hit_confirmed.connect(func(context: HitContext) -> void: player_hits.append(context))


func reset_player(x := 1000.0, y := 215.0) -> void:
    jump_ticket += 1
    Input.action_release("jump")
    player.get_node("Locomotion").reset_assists()
    player.clear_action_buffers()
    combat.abort_attack()
    health.reset_health()
    posture.reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    defense.dash_speed = 320.0 / 0.9
    defense.air_dash_available = true
    locomotion.run_speed = 120.0
    player.global_position = Vector2(x, y)
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    player.get_node("VisualRoot").modulate = Color.WHITE
    combat.set_facing(1)
    defense.set_facing(1)
    player_hits.clear()
    await wait_frames(5)


func incoming_context() -> HitContext:
    var context := HitContext.new()
    context.attacker = room.get_node("TrainingDevice")
    context.attacker_posture = room.get_node("TrainingDevice/Posture")
    context.attacker_stats = room.get_node("TrainingDevice/DefenseStats")
    context.target = player
    context.attack_id = &"test_contact"
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = 12
    context.posture_damage = 8
    context.damage_type = &"physical"
    return context


func setup_enemy(x: float, y: float) -> void:
    enemy.reset_enemy()
    await reset_player(x, y)
    enemy.get_node("Brain").state = PeregrinoBrain.State.RUPTURE # Decision-free combat fixture.
    enemy_contacts.clear()


func run_checks() -> void:
    room = load("res://scenes/test_room.tscn").instantiate()
    root.add_child(room)
    bind_player(room.get_node("Player"))
    await reset_player()
    check(InputMap.has_action("dodge") and InputMap.has_action("attack_light") and InputMap.has_action("attack_heavy"), "controles existentes continuam no Input Map")
    check(combat.dash_light.base_damage == 22 and combat.dash_light.posture_damage == 10, "pós-esquiva canônico 22/10")
    check(combat.air_light.base_damage == 18 and combat.air_light.posture_damage == 7, "Air Light canônico 18/7")
    check(combat.air_heavy.base_damage == 32 and combat.air_heavy.posture_damage == 28, "Air Heavy canônico 32/28")
    check(is_equal_approx(defense.dodge_total_seconds, 0.35) and is_equal_approx(defense.air_dash_total_seconds, 0.35), "dash terrestre e aéreo P40 duram 350 ms")
    check(is_equal_approx(defense.iframe_start_seconds, 0.06125) and is_equal_approx(defense.iframe_end_seconds, 0.21875), "i-frames proporcionais entre 61,25 e 218,75 ms")

    await reset_player()
    await press(&"dodge")
    await press(&"attack_light")
    check(defense.mode == PlayerDefense.Mode.DODGING and not combat.is_busy(), "Light antes da janela mínima não cancela Ground Dodge")
    await wait_frames(3)
    check(defense.can_cancel_dash_for_attack(), "janela ofensiva abre após 80 ms")
    await press(&"attack_light")
    check(defense.mode == PlayerDefense.Mode.READY and combat.current_attack == combat.dash_light, "Ground Dodge → Dash Light próprio")
    check(player.get_node("StateMachine").current_action_state == PlayerStateMachine.ActionState.ATTACKING, "Ground Dash Light entra no estado ofensivo terrestre")
    check(not defense.is_iframe_active(), "i-frames terminam no mesmo frame do cancelamento ofensivo")
    var vulnerable := incoming_context()
    health.receive_hit(vulnerable)
    check(vulnerable.outcome == HitContext.Outcome.DAMAGED and health.current_health == 88, "ataque iniciado no dash já pode receber dano")

    await reset_player()
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_heavy")
    check(defense.mode == PlayerDefense.Mode.READY and combat.current_attack == combat.heavy, "Ground Dodge → Heavy normal 35/25")

    await reset_player()
    await press(&"jump")
    check(not player.is_on_floor() and defense.air_dash_available, "pulo deixa Air Dash disponível")
    var start_x := player.global_position.x
    var camera_before := camera.get_screen_center_position().x
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not defense.air_dash_available, "Air Dash inicia e consome a única carga")
    check(player.get_node("StateMachine").current_action_state == PlayerStateMachine.ActionState.AIR_DASH, "máquina de estados distingue Air Dash")
    await wait_frames(4)
    check(defense.is_iframe_active() and player.global_position.x > start_x, "Air Dash direito move e possui i-frames")
    var avoided := incoming_context()
    health.receive_hit(avoided)
    check(avoided.outcome == HitContext.Outcome.DODGED and health.current_health == 100 and posture.current_posture == 100.0, "i-frames do Air Dash evitam HP e Postura")
    check(absf(camera.get_screen_center_position().x - camera_before) < 100.0, "câmera acompanha sem snap brusco")

    await reset_player(1000, 80)
    await press(&"dodge")
    var starts_before := air_dash_starts
    await wait_frames(28)
    check(defense.mode == PlayerDefense.Mode.READY and not player.is_on_floor(), "Air Dash termina no ar")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.READY and not defense.air_dash_available and air_dash_starts == starts_before, "segundo Air Dash na mesma permanência no ar é recusado")
    await wait_frames(38)
    check(player.is_on_floor() and defense.air_dash_available, "aterrissagem real restaura a carga")
    await press(&"jump")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH, "novo salto após aterrissar permite novo Air Dash")

    await reset_player(1000, 80)
    Input.action_press("move_left")
    await press(&"dodge")
    Input.action_release("move_left")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and player.velocity.x < 0.0 and player.facing_direction == -1, "Air Dash esquerdo usa input e facing")
    await reset_player(1000, 80)
    Input.action_press("move_right")
    await press(&"dodge")
    Input.action_release("move_right")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and player.velocity.x > 0.0 and player.facing_direction == 1, "Air Dash direito usa input e facing")

    await reset_player(842, 164)
    check(player.is_on_floor(), "jogador apoiado na plataforma")
    Input.action_press("move_right")
    for _i in range(80):
        await physics_frame
        if not player.is_on_floor():
            break
    Input.action_release("move_right")
    check(not player.is_on_floor() and defense.air_dash_available, "cair da plataforma preserva o Air Dash")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH, "queda da plataforma permite Air Dash sem pulo")

    await reset_player(2380, 80)
    await press(&"dodge")
    await wait_frames(12)
    check(player.global_position.x <= 2394.5 and not player.is_on_floor(), "Air Dash respeita parede sólida")
    check(not defense.air_dash_available, "colisão lateral com parede não restaura carga")

    await reset_player(1000, 80)
    await press(&"dodge")
    await wait_frames(6)
    await press(&"parry")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not defense.is_parry_active(), "Parry bloqueado durante Air Dash")
    await reset_player()
    await press(&"dodge")
    await press(&"parry")
    check(defense.mode == PlayerDefense.Mode.DODGING and not defense.is_parry_active(), "Parry bloqueado durante Ground Dodge")
    await wait_frames(26)
    await press(&"parry")
    check(defense.mode == PlayerDefense.Mode.PARRYING, "Parry volta após fim do Ground Dodge")

    # Keep the whole 28-tick post-cancel observation airborne with P40 gravity.
    # At Y=80 the new gravity reaches the real floor first, correctly recharging
    # Air Dash; that would test landing rather than consumption by an air attack.
    await reset_player(1000, -80)
    await press(&"dodge")
    await wait_frames(6)
    var dash_speed := absf(player.velocity.x)
    await press(&"attack_light")
    check(combat.current_attack == combat.air_light and defense.mode == PlayerDefense.Mode.READY, "Air Dash → Air Light direto")
    check(player.get_node("StateMachine").current_action_state == PlayerStateMachine.ActionState.AIR_ATTACK, "máquina de estados distingue ataque aéreo")
    check(not defense.is_iframe_active() and not defense.air_dash_available, "cancelar Air Dash elimina i-frame e não restaura carga")
    check(absf(player.velocity.x) >= dash_speed * 0.58, "Air Light mantém aproximadamente 65% do momentum inicial")
    var air_contact := incoming_context()
    health.receive_hit(air_contact)
    check(air_contact.outcome == HitContext.Outcome.DAMAGED and not defense.air_dash_available, "receber dano no ar não restaura Air Dash")
    await wait_frames(28)
    check(not player.is_on_floor() and not defense.air_dash_available, "ataque aéreo não restaura Air Dash")
    await press(&"dodge")
    check(defense.mode == PlayerDefense.Mode.READY, "Air Dash → Light não permite segundo Dash no ar")

    await reset_player(1000, 80)
    await press(&"dodge")
    await press(&"attack_heavy")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not combat.is_busy(), "Heavy antes da janela mínima não cancela Air Dash")
    await wait_frames(3)
    await press(&"attack_heavy")
    check(combat.current_attack == combat.air_heavy and not defense.is_iframe_active(), "Heavy cancela Air Dash após a janela mínima")

    await reset_player(1000, 80)
    await press(&"dodge")
    await wait_frames(6)
    dash_speed = absf(player.velocity.x)
    await press(&"attack_heavy")
    check(combat.current_attack == combat.air_heavy and defense.mode == PlayerDefense.Mode.READY, "Air Dash → Air Heavy direto")
    check(absf(player.velocity.x) >= dash_speed * 0.33 and absf(player.velocity.x) < dash_speed * 0.55, "Air Heavy preserva menos momentum que Air Light")
    check(not defense.air_dash_available and not defense.is_iframe_active(), "Air Heavy não restaura carga nem mantém i-frame")

    await reset_player()
    await press(&"jump")
    await press(&"attack_light")
    check(combat.current_attack == combat.air_light and defense.air_dash_available, "Air Light funciona sem Dash")
    await reset_player()
    await press(&"jump")
    await press(&"attack_heavy")
    check(combat.current_attack == combat.air_heavy and defense.air_dash_available, "Air Heavy funciona sem Dash")

    room.queue_free()
    await process_frame
    var arena: Node2D = load("res://scenes/test/peregrino_arena.tscn").instantiate()
    root.add_child(arena)
    room = arena.get_node("TestRoom")
    bind_player(room.get_node("Player"))
    enemy = arena.get_node("Peregrino")
    enemy.get_node("Attack").hit_confirmed.connect(func(context: HitContext) -> void: enemy_contacts.append(context))

    await setup_enemy(1258, 200)
    await press(&"dodge")
    await wait_frames(8)
    check(player.global_position.x < 1290.0 and not player.is_on_floor(), "Air Dash colide com o corpo do Peregrino")
    check(not defense.air_dash_available, "colisão com inimigo não restaura Air Dash")

    await setup_enemy(1248, 215)
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_light")
    await wait_frames(45)
    check(enemy.get_node("Health").current_health == 78 and roundi(enemy.get_node("Posture").current_posture) == 30, "Ground Dash Light acerta Peregrino: 22 HP / 10 Postura")
    check(player_hits.size() == 1, "Dash Light usa Hitbox, um contato por ação")

    await setup_enemy(1253, 215)
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_heavy")
    await wait_frames(55)
    check(enemy.get_node("Health").current_health == 65 and roundi(enemy.get_node("Posture").current_posture) == 15, "Ground Dash Heavy acerta Peregrino: Heavy normal 35/25")

    await setup_enemy(1248, 196)
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_light")
    check(not defense.is_iframe_active() and not defense.air_dash_available, "Air Dash ofensivo perde i-frames contra Peregrino")
    for _i in range(45):
        await physics_frame
        if enemy.get_node("Health").current_health < 100:
            break
    check(enemy.get_node("Health").current_health == 82 and roundi(enemy.get_node("Posture").current_posture) == 33, "Air Dash Light acerta Peregrino: 18 HP / 7 Postura")
    check(not player.is_on_floor() and not defense.air_dash_available, "acertar Peregrino no ar não recarrega Air Dash")

    await setup_enemy(1235, 180)
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_heavy")
    await wait_frames(65)
    check(enemy.get_node("Health").current_health == 68 and roundi(enemy.get_node("Posture").current_posture) == 12, "Air Dash Heavy acerta Peregrino: 32 HP / 28 Postura")

    await setup_enemy(1270, 215)
    enemy.get_node("Brain").reset_brain()
    enemy.get_node("Attack").start(enemy.get_node("Attack").corte)
    await wait_frames(12)
    player.global_position = Vector2(1270, 200)
    player.velocity = Vector2.ZERO
    locomotion.run_speed = 0.0
    defense.dash_speed = 0.0 # Stationary enemy-contact fixture, independent of run speed.
    await wait_frames(2)
    await press(&"dodge")
    await wait_frames(15)
    check(enemy_contacts.size() >= 1 and enemy_contacts[0].outcome == HitContext.Outcome.DODGED, "Air Dash i-frame evita Corte real do Peregrino")
    check(health.current_health == 100, "Peregrino não causa HP durante i-frame aéreo")
    enemy.reset_enemy()
    await reset_player(1180, 215)
    await wait_frames(30)
    check(enemy.get_node("Brain").state == PeregrinoBrain.State.CHASE, "Peregrino conserva detecção e perseguição após reset")

    print("MILESTONE 4.1: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)


func release_full_jump() -> void:
    # This fixture requests a full jump; variable-height taps are tested in F5.
    var ticket := jump_ticket
    await wait_frames(22)
    if ticket == jump_ticket: Input.action_release("jump")
