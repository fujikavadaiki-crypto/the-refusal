extends SceneTree

## Phase 1 acceptance checks: production player and an unobstructed physical fixture.
## Run with --headless --path <project> --script res://codex/testes/verify_integracao_p40_f1.gd.
## Tolerances below account for one fixed physics step, never for altered tuning.
const CARRASCO: MaskData = preload("res://data/masks/carrasco_base.tres")
const HUMAN_RUN := 160.0 / 0.92
const CARRASCO_RUN := 160.0
const RATE_SCALE := 160.0 / 110.4
const WALK_RATIO := 0.55
const DASH_SPEED := 320.0 / 0.9
const DASH_SECONDS := 0.35
const IFRAME_START := 0.06125
const IFRAME_END := 0.21875
const CANCEL_START := 0.08
const COOLDOWN := 0.28
const EPSILON := 0.000001

var failed := false
var checks := 0
var measurements: Array[Dictionary] = []
var fixture: Node2D
var player: CharacterBody2D
var locomotion: PlayerLocomotion
var defense: PlayerDefense
var combat: PlayerCombat
var masks: MaskController
var health: HealthComponent
var posture: PostureComponent
var walls: Array[StaticBody2D] = []
var physics_step := 1.0 / 60.0


func _initialize() -> void:
    call_deferred("run_checks")


func check(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func near(actual: float, expected: float, tolerance := 0.001) -> bool:
    return absf(actual - expected) <= tolerance


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func release_inputs() -> void:
    for action in [&"move_left", &"move_right", &"walk", &"jump", &"dodge", &"parry", &"attack_light", &"attack_heavy", &"mask_swap"]:
        Input.action_release(action)


func solid(label: String, at: Vector2, size: Vector2) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.name = label
    body.position = at
    body.collision_layer = 1
    body.collision_mask = 0
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = size
    shape.shape = rectangle
    body.add_child(shape)
    fixture.add_child(body)
    return body


func build_fixture() -> void:
    fixture = Node2D.new()
    fixture.name = "P40Phase1PhysicalFixture"
    root.add_child(fixture)
    solid("Floor", Vector2(0, 32), Vector2(20000, 64))
    walls.append(solid("LeftWall", Vector2(-9000, -250), Vector2(16, 1000)))
    walls.append(solid("RightWall", Vector2(9000, -250), Vector2(16, 1000)))
    player = load("res://scenes/player/player.tscn").instantiate() as CharacterBody2D
    player.position = Vector2(0, -13.05)
    fixture.add_child(player)
    locomotion = player.get_node("Locomotion")
    defense = player.get_node("Defense")
    combat = player.get_node("Combat")
    masks = player.get_node("MaskController")
    health = player.get_node("Health")
    posture = player.get_node("Posture")
    player.get_node("Camera2D").enabled = false
    masks.equip(0, CARRASCO)
    masks.equip(1, null)
    masks.activate_slot_for_setup(1)
    await wait_frames(5)
    check(player.is_on_floor(), "fixture física encontra o piso real")


func reset_player(carrasco := false, airborne := false, x := 0.0) -> void:
    release_inputs()
    combat.abort_attack()
    player.clear_action_buffers()
    health.reset_health()
    posture.reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    defense.air_dash_available = true
    masks.swap_cooldown_remaining = 0.0
    masks.activate_slot_for_setup(0 if carrasco else 1)
    locomotion.reset_assists()
    player.global_position = Vector2(x, -300.0 if airborne else -13.05)
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    player.get_node("VisualRoot").modulate = Color.WHITE
    combat.set_facing(1)
    defense.set_facing(1)
    await wait_frames(4)
    check(player.is_on_floor() != airborne, "reset estabelece %s / %s" % ["Carrasco" if carrasco else "humano", "ar" if airborne else "solo"])


func check_scene_contracts() -> void:
    var main_path := String(ProjectSettings.get_setting("application/run/main_scene"))
    var main_scene := load(main_path) as PackedScene
    check(main_scene != null, "cena principal configurada continua carregável")
    if main_scene == null:
        return
    var level := main_scene.instantiate()
    root.add_child(level)
    await wait_frames(2)
    var main_player := level.get_node_or_null("Player") as CharacterBody2D
    check(main_player != null, "cena principal conserva o jogador de produção")
    if main_player != null:
        var main_locomotion := main_player.get_node("Locomotion") as PlayerLocomotion
        var main_masks := main_player.get_node("MaskController") as MaskController
        check(main_masks.active_data() == CARRASCO and near(main_locomotion.run_speed, CARRASCO_RUN), "cena principal aplica Carrasco a 160 world units/s")
        check(near(main_masks.base_speed, HUMAN_RUN), "cena principal captura a base humana antes da máscara")
        check(near(main_locomotion.gravity, 800.0) and near(main_locomotion.jump_velocity, -260.0), "cena principal preserva gravidade e pulo atuais")
        main_player.get_node("ParryAudio").stop()
        main_player.get_node("ParryAudio").stream = null
    level.queue_free()
    await wait_frames(2)

    # Instantiate without adding the vertical slice to the tree: inspect the
    # authored override without starting encounters, AI or level reset logic.
    var vertical: Node = load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate()
    var vertical_locomotion := vertical.get_node("Player/Locomotion") as PlayerLocomotion
    check(near(vertical_locomotion.jump_velocity, -380.0) and near(vertical_locomotion.gravity, 800.0), "override vertical -380 permanece intacto com gravidade 800")
    vertical.free()


func check_configuration() -> void:
    check(near(masks.base_speed, HUMAN_RUN) and near(locomotion.run_speed, HUMAN_RUN), "base humana é 160 / 0,92")
    check(near(CARRASCO.move_speed_multiplier, 0.92), "máscara Carrasco conserva multiplicador 0,92")
    check(near(locomotion.walk_speed_ratio, WALK_RATIO), "caminhada conserva proporção 0,55")
    check(near(locomotion.ground_acceleration, 900.0 * RATE_SCALE), "aceleração de solo usa a mesma proporção da corrida")
    check(near(locomotion.ground_deceleration, 1100.0 * RATE_SCALE), "desaceleração de solo usa a mesma proporção da corrida")
    check(near(locomotion.air_acceleration, 650.0 * RATE_SCALE), "aceleração aérea usa a mesma proporção da corrida")
    check(near(locomotion.gravity, 800.0) and near(locomotion.jump_velocity, -260.0), "fixture de produção conserva gravidade 800 e pulo -260")
    var configured_dash: Variant = defense.get("dash_speed")
    check(configured_dash != null and near(float(configured_dash), DASH_SPEED), "dash absoluto é 320 / 0,9 world units/s")
    check(near(defense.dodge_total_seconds, DASH_SECONDS) and near(defense.air_dash_total_seconds, DASH_SECONDS), "dash solo/ar dura 350 ms")
    check(near(defense.iframe_start_seconds, IFRAME_START) and near(defense.iframe_end_seconds, IFRAME_END), "i-frame configurado de 61,25 a 218,75 ms")
    check(near(defense.dash_attack_cancel_start_seconds, CANCEL_START) and near(defense.dodge_repeat_delay_seconds, COOLDOWN), "cancel em 80 ms e cooldown de 280 ms")


func check_mask_swaps() -> void:
    await reset_player()
    var correct := true
    for _i in range(12):
        masks.swap_cooldown_remaining = 0.0
        correct = masks.swap() and correct
        var expected := CARRASCO_RUN if masks.active_data() != null else HUMAN_RUN
        correct = correct and near(locomotion.run_speed, expected) and near(masks.base_speed, HUMAN_RUN)
    check(correct, "12 trocas reais alternam 160/base humana sem acumular multiplicador")
    check(near(locomotion.ground_acceleration, 900.0 * RATE_SCALE) and near(locomotion.ground_deceleration, 1100.0 * RATE_SCALE) and near(locomotion.air_acceleration, 650.0 * RATE_SCALE), "trocas preservam as três taxas de resposta")


func check_running_and_walking() -> void:
    for carrasco in [false, true]:
        for walk in [false, true]:
            await reset_player(carrasco)
            var expected := (CARRASCO_RUN if carrasco else HUMAN_RUN) * (WALK_RATIO if walk else 1.0)
            var legacy_speed := (110.4 if carrasco else 120.0) * (WALK_RATIO if walk else 1.0)
            Input.action_press("move_right")
            if walk:
                Input.action_press("walk")
            var acceleration_frames := 0
            while player.velocity.x < expected - 0.01 and acceleration_frames < 30:
                await wait_frames(1)
                acceleration_frames += 1
            var label := "%s %s" % ["Carrasco" if carrasco else "humano", "walk" if walk else "run"]
            check(near(player.velocity.x, expected), "%s alcança velocidade física %.6f" % [label, expected])
            check(absf(acceleration_frames * physics_step - legacy_speed / 900.0) <= physics_step + 0.0001, "%s preserva tempo de aceleração anterior" % label)
            var start_x := player.global_position.x
            await wait_frames(6)
            var measured_speed := (player.global_position.x - start_x) / (6.0 * physics_step)
            var acceleration_seconds := acceleration_frames * physics_step
            check(near(measured_speed, expected, 0.02), "%s mede %.6f world units/s pelo deslocamento" % [label, expected])
            Input.action_release("move_right")
            var stop_frames := 0
            while absf(player.velocity.x) > 0.01 and stop_frames < 30:
                await wait_frames(1)
                stop_frames += 1
            measurements.append({"kind": "locomotion", "form": "Carrasco" if carrasco else "human", "walk": walk, "nominal_speed": expected, "measured_speed": measured_speed, "acceleration_seconds": acceleration_seconds, "legacy_acceleration_seconds": legacy_speed / 900.0, "stop_seconds": stop_frames * physics_step, "legacy_stop_seconds": legacy_speed / 1100.0})
            check(near(player.velocity.x, 0.0) and absf(stop_frames * physics_step - legacy_speed / 1100.0) <= physics_step + 0.0001, "%s preserva tempo de parada anterior" % label)
            var stopped_at := player.global_position.x
            await wait_frames(3)
            check(near(player.global_position.x, stopped_at, 0.001), "%s permanece parado sem drift" % label)

    # Air acceleration must preserve the original response time as well.
    for carrasco in [false, true]:
        await reset_player(carrasco, true)
        var expected := CARRASCO_RUN if carrasco else HUMAN_RUN
        var legacy_speed := 110.4 if carrasco else 120.0
        Input.action_press("move_right")
        var acceleration_frames := 0
        while player.velocity.x < expected - 0.01 and acceleration_frames < 30:
            await wait_frames(1)
            acceleration_frames += 1
        check(not player.is_on_floor() and near(player.velocity.x, expected) and absf(acceleration_frames * physics_step - legacy_speed / 650.0) <= physics_step + 0.0001, "%s preserva velocidade e tempo de aceleração aérea" % ("Carrasco" if carrasco else "humano"))
        measurements.append({"kind": "air_acceleration", "form": "Carrasco" if carrasco else "human", "nominal_speed": expected, "measured_speed": player.velocity.x, "acceleration_seconds": acceleration_frames * physics_step, "legacy_acceleration_seconds": legacy_speed / 650.0})
        release_inputs()


func check_dash_matrix() -> void:
    var nominal_distance := DASH_SPEED * DASH_SECONDS
    var distance_tolerance := DASH_SPEED * physics_step + locomotion.ground_deceleration * physics_step * physics_step + 0.05
    for carrasco in [false, true]:
        for airborne in [false, true]:
            for direction in [-1, 1]:
                for walk in [false, true]:
                    await reset_player(carrasco, airborne)
                    Input.action_press("move_left" if direction < 0 else "move_right")
                    if walk:
                        Input.action_press("walk")
                    # Opposing facing proves that a nonzero axis chooses direction.
                    defense.accept_inputs(true, false, float(direction), -direction, false)
                    var start := player.global_position
                    var correct_speed := near(player.velocity.x, DASH_SPEED * direction)
                    var air_frozen := true
                    var dash_frames := 0
                    while defense.is_dashing() and dash_frames < 30:
                        var previous_x := player.global_position.x
                        await wait_frames(1)
                        dash_frames += 1
                        if defense.is_dashing():
                            correct_speed = correct_speed and near(player.velocity.x, DASH_SPEED * direction)
                            correct_speed = correct_speed and near((player.global_position.x - previous_x) / physics_step, DASH_SPEED * direction, 0.025)
                            if airborne:
                                air_frozen = air_frozen and near(player.velocity.y, 0.0) and near(player.global_position.y, start.y)
                    var label := "%s %s %s Shift=%s" % ["Carrasco" if carrasco else "humano", "ar" if airborne else "solo", "esquerda" if direction < 0 else "direita", walk]
                    measurements.append({"kind": "dash", "form": "Carrasco" if carrasco else "human", "airborne": airborne, "direction": direction, "walk": walk, "nominal_speed": DASH_SPEED, "nominal_seconds": DASH_SECONDS, "measured_seconds": dash_frames * physics_step, "nominal_distance": nominal_distance, "measured_distance": absf(player.global_position.x - start.x), "distance_tolerance": distance_tolerance, "speed_samples_passed": correct_speed})
                    check(correct_speed and defense.dodge_direction == direction, "dash %s mede velocidade absoluta 355,555556" % label)
                    check(not defense.is_dashing() and absf(dash_frames * physics_step - DASH_SECONDS) <= physics_step + 0.0001, "dash %s encerra em 350 ms com tolerância de um frame" % label)
                    check(near(absf(player.global_position.x - start.x), nominal_distance, distance_tolerance), "dash %s integra distância nominal %.6f ± %.6f" % [label, nominal_distance, distance_tolerance])
                    check(near(defense.dodge_cooldown, COOLDOWN) and (air_frozen if airborne else player.is_on_floor()), "dash %s conserva cooldown e contato/altura" % label)
                    if airborne:
                        check(not defense.air_dash_available, "dash %s consome uma carga aérea" % label)
                    release_inputs()

    # A neutral axis uses facing rather than an arbitrary fixed direction.
    for direction in [-1, 1]:
        await reset_player()
        defense.accept_inputs(true, false, 0.0, direction, false)
        check(defense.dodge_direction == direction and near(player.velocity.x, direction * DASH_SPEED), "dash sem eixo respeita facing %d" % direction)


func check_iframe_boundaries() -> void:
    await reset_player()
    var times := [IFRAME_START - EPSILON, IFRAME_START, (IFRAME_START + IFRAME_END) / 2.0, IFRAME_END - EPSILON, IFRAME_END]
    var should_dodge := [false, true, true, true, false]
    for dash_mode in [PlayerDefense.Mode.DODGING, PlayerDefense.Mode.AIR_DASH]:
        for index in range(times.size()):
            health.reset_health()
            posture.reset_posture()
            defense.mode = dash_mode
            defense.elapsed = times[index]
            var hit := HitContext.new()
            hit.target = player
            hit.attack_id = &"p40_iframe_boundary"
            hit.action_uid = HitContext.allocate_action_id()
            hit.base_damage = 10
            hit.posture_damage = 4
            hit.damage_type = &"physical"
            hit.parry_class = &"non_parryable"
            health.receive_hit(hit)
            var dodged: bool = should_dodge[index]
            var expected_outcome := HitContext.Outcome.DODGED if dodged else HitContext.Outcome.DAMAGED
            check(hit.outcome == expected_outcome and health.current_health == (100 if dodged else 90) and near(posture.current_posture, 100.0 if dodged else 96.0), "i-frame %s t=%.6f resolve contato HP/Postura: %s" % ["ar" if dash_mode == PlayerDefense.Mode.AIR_DASH else "solo", times[index], "miss" if dodged else "dano"])
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = IFRAME_START
    check(not defense.is_iframe_active(), "fim/cancel do dash não deixa invulnerabilidade residual")


func check_dash_with_changed_run_speed() -> void:
    for airborne in [false, true]:
        for run_speed in [0.0, 80.0, 500.0]:
            await reset_player(true, airborne)
            locomotion.run_speed = run_speed
            Input.action_press("walk")
            defense.accept_inputs(true, false, -1.0, 1, false)
            var start_x := player.global_position.x
            await wait_frames(3)
            var measured := (player.global_position.x - start_x) / (3.0 * physics_step)
            measurements.append({"kind": "dash_changed_base", "airborne": airborne, "base_speed": run_speed, "walk": true, "nominal_speed": -DASH_SPEED, "measured_speed": measured})
            check(defense.is_dashing() and near(player.velocity.x, -DASH_SPEED) and near(measured, -DASH_SPEED, 0.025), "dash %s mantém velocidade absoluta com run_speed=%.1f e Shift" % ["ar" if airborne else "solo", run_speed])
            release_inputs()


func check_cancel_and_momentum() -> void:
    for carrasco in [false, true]:
        for airborne in [false, true]:
            for heavy in [false, true]:
                await reset_player(carrasco, airborne)
                defense.accept_inputs(true, false, -1.0, 1, false)
                var original_mode := defense.mode
                defense.elapsed = CANCEL_START - EPSILON
                defense.cancel_dash_for_attack(heavy)
                check(defense.mode == original_mode and near(player.velocity.x, -DASH_SPEED) and not defense.can_cancel_dash_for_attack(), "cancel antes de 80 ms é bloqueado (%s/%s/%s)" % [carrasco, airborne, heavy])
                defense.elapsed = CANCEL_START
                var expected_attack: AttackData
                if airborne:
                    expected_attack = CARRASCO.air_heavy if carrasco and heavy else (CARRASCO.air_light if carrasco else (combat.air_heavy if heavy else combat.air_light))
                else:
                    expected_attack = CARRASCO.heavy if carrasco and heavy else (CARRASCO.post_dodge if carrasco else (combat.heavy if heavy else combat.dash_light))
                var accepted := combat.accept_inputs(not heavy, heavy, defense.mode)
                defense.cancel_dash_for_attack(heavy)
                var fraction := (defense.air_heavy_momentum_fraction if heavy else defense.air_light_momentum_fraction) if airborne else defense.ground_dash_attack_momentum_fraction
                var expected_fraction := (0.40 if heavy else 0.65) if airborne else 0.45
                check(accepted and combat.current_attack == expected_attack and defense.mode == PlayerDefense.Mode.READY, "cancel em 80 ms aceita ataque correto (%s/%s/%s)" % [carrasco, airborne, heavy])
                check(near(fraction, expected_fraction) and near(player.velocity.x, -DASH_SPEED * expected_fraction), "cancel preserva momentum %.2f e direção (%s/%s/%s)" % [expected_fraction, carrasco, airborne, heavy])
                check(not defense.is_iframe_active() and (not defense.air_dash_available if airborne else near(defense.dodge_cooldown, COOLDOWN)), "cancel encerra iframe e preserva carga/cooldown (%s/%s/%s)" % [carrasco, airborne, heavy])

    # Exercise the production input router: an early press is discarded and
    # cannot survive in the attack buffer until the approved cancel window.
    for airborne in [false, true]:
        await reset_player(true, airborne)
        Input.action_press("dodge")
        Input.action_press("attack_light")
        await wait_frames(2)
        Input.action_release("dodge")
        Input.action_release("attack_light")
        await wait_frames(5)
        check(defense.is_dashing() and defense.can_cancel_dash_for_attack() and not combat.is_busy() and near(player.light_buffer_remaining, 0.0), "input Light precoce não cancela nem fica enfileirado (%s)" % ("ar" if airborne else "solo"))
        Input.action_press("attack_light")
        await wait_frames(2)
        Input.action_release("attack_light")
        check(not defense.is_dashing() and combat.current_attack == (CARRASCO.air_light if airborne else CARRASCO.post_dodge), "input Light após 80 ms cancela pelo roteamento real (%s)" % ("ar" if airborne else "solo"))


func check_cooldown_and_air_charge() -> void:
    await reset_player()
    defense.accept_inputs(true, false, 1.0, 1, false)
    defense.tick(DASH_SECONDS)
    defense.accept_inputs(true, false, 1.0, 1, false)
    check(defense.mode == PlayerDefense.Mode.READY and near(defense.dodge_cooldown, COOLDOWN), "cooldown bloqueia repetição terrestre imediata")
    defense.tick(COOLDOWN - EPSILON)
    defense.accept_inputs(true, false, 1.0, 1, false)
    check(defense.mode == PlayerDefense.Mode.READY, "cooldown ainda bloqueia um microssegundo antes de 280 ms")
    defense.tick(2.0 * EPSILON)
    defense.accept_inputs(true, false, 1.0, 1, false)
    check(defense.mode == PlayerDefense.Mode.DODGING, "dash terrestre volta após os 280 ms completos")

    await reset_player(true, true)
    defense.accept_inputs(true, false, 1.0, 1, false)
    defense.tick(DASH_SECONDS)
    defense.sync_grounding()
    defense.accept_inputs(true, false, 1.0, 1, false)
    check(defense.mode == PlayerDefense.Mode.READY and not defense.air_dash_available, "dash aéreo completo não recarrega nem repete antes de pousar")
    player.global_position = Vector2(0, -13.05)
    player.velocity = Vector2.ZERO
    await wait_frames(4)
    check(player.is_on_floor() and defense.air_dash_available, "colisão real com piso recarrega dash aéreo")
    Input.action_press("jump")
    await wait_frames(2)
    Input.action_release("jump")
    check(not player.is_on_floor(), "pulo original continua retirando o corpo do piso")
    defense.accept_inputs(true, false, 1.0, 1, false)
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not defense.air_dash_available, "nova decolagem disponibiliza exatamente uma carga aérea")


func check_walls() -> void:
    walls[0].position.x = -180.0
    walls[1].position.x = 180.0
    await wait_frames(2)
    for airborne in [false, true]:
        for direction in [-1, 1]:
            await reset_player(true, airborne, float(direction) * 120.0)
            defense.accept_inputs(true, false, float(direction), direction, false)
            var contacted := false
            var stayed_inside := true
            for _i in range(24):
                await wait_frames(1)
                contacted = contacted or player.is_on_wall()
                stayed_inside = stayed_inside and absf(player.global_position.x) <= 165.1
            check(contacted and stayed_inside and not defense.is_dashing(), "dash %s/%s colide com parede sem atravessar ou travar ação" % ["ar" if airborne else "solo", "esquerda" if direction < 0 else "direita"])
    walls[0].position.x = -9000.0
    walls[1].position.x = 9000.0


func run_checks() -> void:
    release_inputs()
    physics_step = 1.0 / float(Engine.physics_ticks_per_second)
    await check_scene_contracts()
    await build_fixture()
    check_configuration()
    await check_mask_swaps()
    await check_running_and_walking()
    await check_dash_matrix()
    await check_dash_with_changed_run_speed()
    await check_iframe_boundaries()
    await check_cancel_and_momentum()
    await check_cooldown_and_air_charge()
    await check_walls()
    release_inputs()
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    fixture.queue_free()
    await wait_frames(2)
    print("INTEGRACAO P40 F1: ", "FAIL" if failed else "PASS", " (", checks, " checks)")
    print("P40_MEASUREMENTS_JSON: ", JSON.stringify(measurements))
    quit(1 if failed else 0)
