extends SceneTree

var jump_ticket := 0

var failed := false
var slice: Node2D
var player: CharacterBody2D
var encounters: Array[ForestEncounter] = []
var health: HealthComponent
var posture: PostureComponent
var defense: PlayerDefense


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


func make_hit(target: CharacterBody2D, damage: int) -> HitContext:
    var hit := HitContext.new()
    hit.attacker = player if target != player else encounters[0].enemies[0]
    hit.target = target
    hit.attack_id = &"m7_fixture"
    hit.action_uid = HitContext.allocate_action_id()
    hit.base_damage = damage
    hit.damage_type = &"physical"
    return hit


func move_player(position: Vector2) -> void:
    jump_ticket += 1
    Input.action_release("jump")
    player.get_node("Locomotion").reset_assists()
    player.clear_action_buffers()
    player.global_position = position
    player.velocity = Vector2.ZERO
    await wait_frames(4)


func run_checks() -> void:
    slice = load("res://scenes/biomes/forest/forest_slice_01.tscn").instantiate()
    root.add_child(slice)
    player = slice.get_node("Player")
    health = player.get_node("Health")
    posture = player.get_node("Posture")
    defense = player.get_node("Defense")
    for child in slice.get_node("Encounters").get_children():
        encounters.append(child)
    await wait_frames(4)
    check(player.global_position.distance_to(Vector2(120, 215)) < 2.0 and player.is_on_floor(), "Player começa seguro e no chão")
    check(encounters.size() == 5 and slice.WORLD_LENGTH == 8200.0, "fatia artesanal longa com cinco encontros")
    var types: Array[String] = []
    for encounter in encounters:
        var label := ""
        for enemy in encounter.enemies:
            label += enemy.name + "+"
            check(enemy.get_node("Brain").player == player, "IA de %s aponta para o Player da fatia" % enemy.name)
        types.append(label)
    check(types == ["Peregrino+", "RaizFaminta+", "Corvo+", "Peregrino+Corvo+", "Peregrino+RaizFaminta+"], "ordem: Peregrino, Raiz, Corvo, duas combinações")
    await wait_frames(240)
    var all_sleeping := true
    for encounter in encounters:
        all_sleeping = all_sleeping and not encounter.is_active
    check(all_sleeping and health.current_health == 100, "entrada segura; inimigos distantes não agroam")

    await move_player(Vector2(1080, 215))
    await wait_frames(30)
    check(encounters[0].is_active and not encounters[1].is_active and not encounters[2].is_active, "primeiro encontro ativa isoladamente")
    check(encounters[0].enemies[0].get_node("Brain").state != PeregrinoBrain.State.IDLE, "Peregrino percebe e reage no cenário")
    var safe_outside: Vector2 = slice.safe_position
    await move_player(Vector2(1185, 215))
    await wait_frames(12)
    check(slice.safe_position.distance_to(safe_outside) < 2.0, "safe position não atualiza dentro do espaço de inimigo vivo")

    slice.reset_slice()
    await move_player(Vector2(2690, 215))
    await wait_frames(35)
    check(encounters[1].is_active and encounters[1].enemies[0].get_node("Brain").state not in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DEATH], "Raiz detecta com marca visível no cenário")
    check(encounters[1].enemies[0].get_node("BurrowMark").visible, "aviso subterrâneo continua legível")

    slice.reset_slice()
    await move_player(Vector2(4130, 215))
    await wait_frames(40)
    check(encounters[2].is_active and encounters[2].enemies[0].get_node("Brain").state not in [CorvoBrain.State.HOVER, CorvoBrain.State.PATROL_AIR], "Corvo detecta no espaço vertical")
    var camera: Camera2D = player.get_node("Camera2D")
    check(camera.get_screen_center_position().y >= 0.0 and camera.get_screen_center_position().y <= 270.0, "câmera permanece na faixa vertical estável")
    check(absf(camera.get_screen_center_position().x - player.global_position.x) < 100.0, "câmera segue Player, não Corvo")

    slice.reset_slice()
    await move_player(Vector2(5390, 215))
    await wait_frames(100)
    check(encounters[3].is_active and encounters[3].enemies.size() == 2, "Peregrino e Corvo ativam no mesmo encontro")
    check(encounters[3].enemies[0].get_node("Brain").state not in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL] and encounters[3].enemies[1].get_node("Brain").state not in [CorvoBrain.State.HOVER, CorvoBrain.State.PATROL_AIR], "duas IAs independentes reagem ao jogador")

    slice.reset_slice()
    await move_player(Vector2(7010, 215))
    await wait_frames(100)
    check(encounters[4].is_active and encounters[4].enemies.size() == 2, "Peregrino e Raiz ativam no último encontro")
    check(encounters[4].enemies[0].get_node("Brain").state not in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL] and encounters[4].enemies[1].get_node("Brain").state not in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DEATH], "ameaças humana e subterrânea coexistem")

    slice.reset_slice()
    await move_player(Vector2(1640, 215))
    Input.action_press("move_right")
    await press(&"jump")
    await wait_frames(20)
    Input.action_release("move_right")
    await wait_frames(28)
    check(player.is_on_floor() and player.global_position.y < 205.0, "primeira plataforma alcançável por pulo normal")

    slice.reset_slice()
    await move_player(Vector2(1840, 215))
    await wait_frames(15)
    var safe_before: Vector2 = slice.safe_position
    var hp_before := health.current_health
    await move_player(Vector2(1893, 215))
    await wait_frames(12)
    check(slice.safe_position.distance_to(safe_before) < 2.0, "safe position não atualiza na borda insegura")
    await move_player(Vector2(1845, 180))
    await wait_frames(10)
    check(slice.safe_position.distance_to(safe_before) < 2.0, "safe position não atualiza no ar")
    player.global_position = Vector2(1930, 231)
    player.velocity = Vector2.ZERO
    await wait_frames(65)
    check(slice.fall_recovery_count == 1 and player.global_position.distance_to(safe_before) < 20.0, "queda no vão retorna à posição segura recente")
    check(health.current_health == hp_before, "recuperação de queda não retira HP")

    slice.reset_slice()
    await move_player(Vector2(1845, 215))
    Input.action_press("move_right")
    await press(&"jump")
    await wait_frames(5)
    await press(&"dodge")
    await wait_frames(45)
    Input.action_release("move_right")
    check(player.global_position.x > 1980.0 and slice.fall_recovery_count == 1, "Air Dash cruza o vão sem quebrar limites da fase")

    slice.reset_slice()
    await move_player(Vector2(1845, 215))
    Input.action_press("move_right")
    await press(&"jump")
    await wait_frames(55)
    Input.action_release("move_right")
    check(player.global_position.x > 1950.0 and slice.fall_recovery_count == 1, "pulo normal oferece rota pelo vão")

    slice.reset_slice()
    await move_player(Vector2(8040, 215))
    Input.action_press("move_right")
    await wait_frames(10)
    Input.action_release("move_right")
    check(slice.finished and slice.get_node("CanvasLayer/Feedback").text.contains("FIM DA FATIA"), "marcador final mostra feedback sem mudar de cena")
    check(root.get_child(root.get_child_count() - 1) == slice, "saída não carrega outro bioma")

    slice.reset_slice()
    await move_player(Vector2(5390, 215))
    var crow: CharacterBody2D = encounters[3].enemies[1]
    crow.get_node("Attack").abort()
    crow.get_node("Attack").begin_projectile()
    await wait_frames(55)
    check(crow.get_node("Attack").active_projectiles.size() >= 1, "Corvo combinado pode lançar projétil")
    encounters[3].enemies[0].get_node("Health").receive_hit(make_hit(encounters[3].enemies[0], 100))
    await press(&"reset_dummy")
    check(slice.reset_count >= 1 and player.global_position.distance_to(Vector2(120, 215)) < 2.0 and health.current_health == 100 and posture.current_posture == 100.0, "R reinicia Player, HP e Postura")
    var reset_ok := true
    for encounter in encounters:
        reset_ok = reset_ok and not encounter.is_active and not encounter.is_completed
        for enemy in encounter.enemies:
            reset_ok = reset_ok and enemy.get_node("Health").current_health == enemy.get_node("Health").max_health and not enemy.get_node("Posture").is_ruptured()
    check(reset_ok and crow.get_node("Attack").active_projectiles.is_empty() and defense.air_dash_available, "R restaura encontros, ambush, projéteis e Air Dash")

    await move_player(Vector2(1080, 215))
    encounters[0].enemies[0].get_node("Health").receive_hit(make_hit(encounters[0].enemies[0], 100))
    await wait_frames(3)
    check(encounters[0].is_completed, "encontro conclui quando todos os seus inimigos morrem")
    slice.reset_slice()

    health.receive_hit(make_hit(player, 100))
    await wait_frames(75)
    check(health.current_health == 100 and slice.reset_count >= 2, "morte do Player usa reset técnico provisório")

    await long_soak()
    await geometry_traversal()
    check(slice.get_node_or_null("Loot") == null and slice.get_node_or_null("Relics") == null, "fatia não cria loot ou sistemas futuros")
    print("MILESTONE 7: ", "FAIL" if failed else "PASS")
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    slice.queue_free()
    await process_frame
    var cleanup_until := Time.get_ticks_msec() + 400
    while Time.get_ticks_msec() < cleanup_until:
        await process_frame
    quit(1 if failed else 0)


func long_soak() -> void:
    slice.reset_slice()
    await move_player(Vector2(5390, 215))
    var peregrino: CharacterBody2D = encounters[3].enemies[0]
    var crow: CharacterBody2D = encounters[3].enemies[1]
    var saw_ground := false
    var saw_air := false
    var max_projectiles := 0
    var bounded := true
    for i in range(10800): # Three simulated minutes.
        await physics_frame
        root.get_node("HitStop")._restore()
        var ground_state: int = peregrino.get_node("Brain").state
        var air_state: int = crow.get_node("Brain").state
        saw_ground = saw_ground or ground_state in [PeregrinoBrain.State.ATTACK_WINDUP, PeregrinoBrain.State.ATTACK_ACTIVE]
        saw_air = saw_air or air_state in [CorvoBrain.State.DIVE_WINDUP, CorvoBrain.State.PROJECTILE_WINDUP]
        max_projectiles = maxi(max_projectiles, crow.get_node("Attack").active_projectiles.size())
        bounded = bounded and absf(peregrino.global_position.x - peregrino.spawn_position.x) < 330.0 and absf(crow.global_position.x - crow.spawn_position.x) < 360.0
        if health.current_health <= 30:
            health.reset_health()
            posture.reset_posture()
            defense.mode = PlayerDefense.Mode.READY
        if i % 300 == 0:
            player.global_position = Vector2(5390, 215)
            player.velocity = Vector2.ZERO
    check(saw_ground and saw_air and bounded and max_projectiles < 10, "três minutos de Peregrino+Corvo: dois ataques, limites e projéteis finitos")
    slice.reset_slice()
    check(crow.get_node("Attack").active_projectiles.is_empty(), "reset após simulação remove projéteis")

    await move_player(Vector2(7010, 215))
    var root_enemy: CharacterBody2D = encounters[4].enemies[1]
    var saw_emerge := false
    var saw_bite := false
    var root_grounded := true
    for i in range(3600): # One simulated minute for the second combined encounter.
        await physics_frame
        root.get_node("HitStop")._restore()
        var state: int = root_enemy.get_node("Brain").state
        saw_emerge = saw_emerge or state in [RaizFamintaBrain.State.EMERGE_WINDUP, RaizFamintaBrain.State.EMERGE_ATTACK]
        saw_bite = saw_bite or state in [RaizFamintaBrain.State.BITE_WINDUP, RaizFamintaBrain.State.BITE_ACTIVE]
        root_grounded = root_grounded and absf(root_enemy.global_position.y - 219.0) < 4.0
        if health.current_health <= 30:
            health.reset_health()
            posture.reset_posture()
            defense.mode = PlayerDefense.Mode.READY
        if i % 300 == 0:
            player.global_position = Vector2(7010, 215)
            player.velocity = Vector2.ZERO
    check(saw_emerge and saw_bite and root_grounded, "um minuto de Peregrino+Raiz: emboscada, mordida e chão estáveis")


func geometry_traversal() -> void:
    slice.reset_slice()
    for encounter in encounters:
        encounter.set_physics_process(false) # Isolate terrain and camera from combat in this route check.
    Input.action_press("move_right")
    var jumped_gap := false
    var jumped_step := false
    var camera_bounded := true
    for _i in range(6000):
        if not jumped_gap and player.global_position.x >= 1842.0 and player.is_on_floor():
            jumped_gap = true
            await press(&"jump")
        if not jumped_step and player.global_position.x >= 3250.0 and player.is_on_floor():
            jumped_step = true
            await press(&"jump")
        await physics_frame
        var camera_x: float = player.get_node("Camera2D").get_screen_center_position().x
        camera_bounded = camera_bounded and camera_x >= 239.0 and camera_x <= 7961.0
        if slice.finished:
            break
    Input.action_release("move_right")
    check(jumped_gap and jumped_step and slice.finished and slice.fall_recovery_count == 1, "travessia contínua alcança saída com pulo e pequeno desnível")
    check(camera_bounded, "câmera respeita limites durante o corredor longo")
    print("TRAVESSIA SEM COMBATE: %.1f s" % slice.elapsed_seconds)


func release_full_jump() -> void:
    # This fixture requests a full jump; variable-height taps are tested in F5.
    var ticket := jump_ticket
    await wait_frames(22)
    if ticket == jump_ticket: Input.action_release("jump")
