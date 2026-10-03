extends SceneTree

## Real production shapes, controller, enemy attack components and projectile travel.
## --baseline records phase 1 measurements without asserting the new profile.
const CARRASCO: MaskData = preload("res://data/masks/carrasco_base.tres")
const UNIT := 32.0 / 0.9
const STEP := 1.0 / 60.0
const GRAVITY := 2.0 * 2.2 * UNIT / (0.325 * 0.325)
const IMPULSE := -2.0 * 2.2 * UNIT / 0.325
var baseline := false
var failures := 0
var checks := 0
var measurements: Dictionary = {"physics_hz": 60, "jump": [], "contacts": [], "spawn": []}
var fixture: Node2D
var player: CharacterBody2D
var loco: PlayerLocomotion
var masks: MaskController
var health: HealthComponent
var enemies: Dictionary = {}

func _initialize() -> void:
    baseline = OS.get_cmdline_user_args().has("--baseline")
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if ok:
        print("PASS: ", label)
    else:
        failures += 1
        printerr("FAIL: ", label)

func near(a: float, b: float, tolerance := 0.002) -> bool:
    return absf(a - b) <= tolerance

func frames(count := 1) -> void:
    for _i in range(count):
        await physics_frame

func solid(label: String, at: Vector2, size: Vector2) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.name = label
    body.position = at
    body.collision_layer = 1
    body.collision_mask = 0
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    fixture.add_child(body)
    return body

func reset(carrasco := true, position := Vector2(0, -13.05)) -> void:
    player.get_node("Combat").abort_attack()
    player.clear_action_buffers()
    health.reset_health()
    player.get_node("Posture").reset_posture()
    var defense: PlayerDefense = player.get_node("Defense")
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    masks.activate_slot_for_setup(0 if carrasco else 1)
    masks.swap_cooldown_remaining = 0.0
    player.position = position
    player.velocity = Vector2.ZERO
    loco.reset_assists()
    for _i in range(3):
        await frames()
        loco.move(player, 0.0, false, STEP)
    player.velocity = Vector2.ZERO

func penetrations(body: CharacterBody2D) -> Array[Dictionary]:
    var collision: CollisionShape2D = body.get_node("CollisionShape2D")
    var query := PhysicsShapeQueryParameters2D.new()
    # Exact tangency also appears in intersect_shape. A 0.01-unit inset
    # distinguishes floor contact from measurable penetration (> 0.01 units).
    var inset := collision.shape.duplicate() as CapsuleShape2D
    inset.radius -= 0.01
    inset.height -= 0.02
    query.shape = inset
    query.transform = collision.global_transform
    query.collision_mask = body.collision_mask
    query.exclude = [body.get_rid()]
    query.collide_with_areas = false
    return body.get_world_2d().direct_space_state.intersect_shape(query)

func scene_checks() -> void:
    for path in [String(ProjectSettings.get_setting("application/run/main_scene")), "res://scenes/biomes/forest/forest_vertical_slice.tscn", "res://scenes/biomes/forest/bosque_trecho_01_playable.tscn"]:
        var scene: Node = load(path).instantiate()
        root.add_child(scene)
        var p: CharacterBody2D = scene.get_node("Player")
        p.get_node("Camera2D").enabled = false
        p.set_physics_process(false)
        await frames(2)
        var overlaps := penetrations(p)
        var labels: Array[String] = []
        for item in overlaps:
            labels.append(String(item.collider.name))
        measurements.spawn.append({"scene": path, "position": [p.position.x, p.position.y], "overlaps": labels})
        check(overlaps.is_empty(), "%s: spawn sem interpenetração física" % path.get_file())
        if not baseline:
            var movement: PlayerLocomotion = p.get_node("Locomotion")
            check(near(movement.gravity, GRAVITY) and near(movement.jump_velocity, IMPULSE), "%s herda o pulo P40 sem override -380" % path.get_file())
        scene.queue_free()
        await frames(2)

func build() -> void:
    fixture = Node2D.new()
    root.add_child(fixture)
    solid("Floor", Vector2(0, 32), Vector2(20000, 64))
    player = load("res://scenes/player/player.tscn").instantiate()
    player.position = Vector2(0, -13.05)
    fixture.add_child(player)
    player.set_physics_process(false)
    player.get_node("Camera2D").enabled = false
    loco = player.get_node("Locomotion")
    masks = player.get_node("MaskController")
    health = player.get_node("Health")
    masks.equip(0, CARRASCO)
    masks.equip(1, null)
    for kind in ["peregrino", "corvo", "raiz_faminta"]:
        var enemy: CharacterBody2D = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
        enemy.position = Vector2(5000, -200)
        fixture.add_child(enemy)
        enemy.set_physics_process(false)
        enemies[kind] = enemy
    await frames(4)

func profiles() -> void:
    for carrasco in [false, true]:
        await reset(carrasco)
        var collision: CollisionShape2D = player.get_node("CollisionShape2D")
        var hurt: CollisionShape2D = player.get_node("Hurtbox/CollisionShape2D")
        var capsule := collision.shape as CapsuleShape2D
        var hit_capsule := hurt.shape as CapsuleShape2D
        var expected_height := 46.0 / 0.9 if carrasco and not baseline else 64.0
        var expected_radius := 7.0 # F3 decision: same world radius as human.
        check(near(capsule.height, expected_height) and near(capsule.radius, expected_radius), "corpo %s: raio/altura corretos" % ("Carrasco" if carrasco else "humano"))
        check(near(hit_capsule.height, expected_height) and near(hit_capsule.radius, expected_radius), "hurtbox acompanha a cápsula %s" % carrasco)
        check(near(collision.position.y + capsule.height / 2.0, 13.0) and collision.position == hurt.position, "troca de corpo preserva os pés Y=13")
        check(near(player.get_node("AttackPivot").position.y, 13.0 - 0.84 * UNIT if carrasco and not baseline else -2.0), "pivô %s usa a altura esperada" % carrasco)
        check(penetrations(player).is_empty(), "corpo %s apoiado não penetra no chão" % carrasco)
    var previous_position := player.position
    for _i in range(12):
        masks.swap_cooldown_remaining = 0.0
        check(masks.swap(), "troca de forma em espaço livre")
        check(player.position == previous_position, "troca não desloca os pés")
    var second: CharacterBody2D = load("res://scenes/player/player.tscn").instantiate()
    second.position = Vector2(-1000, -13.05)
    fixture.add_child(second)
    second.set_physics_process(false)
    check(near(second.get_node("CollisionShape2D").shape.height, 64.0), "outra instância humana mantém a cápsula original")
    if not baseline:
        check(second.get_node("CollisionShape2D").shape != player.get_node("CollisionShape2D").shape, "instâncias não compartilham a cápsula mutável")
    second.queue_free()
    await frames(2)

func jumps() -> void:
    check(Engine.physics_ticks_per_second == 60, "medição feita a 60 Hz")
    check(near(loco.coyote_seconds, 0.10) and near(loco.jump_buffer_seconds, 0.12), "coyote 100 ms e buffer 120 ms preservados")
    for carrasco in [false, true]:
        await reset(carrasco)
        var start := player.position.y
        var minimum := start
        var apex_tick := 0
        var landing_tick := 0
        var trace: Array[Dictionary] = []
        for tick in range(1, 121):
            await frames()
            loco.move(player, 0.0, tick == 1, STEP)
            trace.append({"tick": tick, "y": player.position.y, "vy": player.velocity.y})
            if player.position.y < minimum:
                minimum = player.position.y
                apex_tick = tick
            if tick > 1 and player.is_on_floor():
                landing_tick = tick
                break
        var height := start - minimum
        var record := {"form": "Carrasco" if carrasco else "human", "gravity": loco.gravity, "impulse": loco.jump_velocity, "height_world": height, "height_px": height * 0.9, "height_m": height / UNIT, "apex_tick": apex_tick, "apex_s": apex_tick * STEP, "landing_tick": landing_tick, "flight_s": landing_tick * STEP, "trace": trace}
        measurements.jump.append(record)
        print("MEASURE: jump ", JSON.stringify(record))
        check(landing_tick > apex_tick and apex_tick > 0, "pulo sobe e retorna ao piso")
        if not baseline:
            check(near(height / UNIT, 2.316051865, 0.003), "altura jogada ~2,32 m em %s" % record.form)
            check(apex_tick == 20, "ápice em 20 ticks / 333,333 ms")
        # Releasing jump never used a cut in this controller; retaining input assists.
        await reset(carrasco)
        player.position.x = 10050.0
        await frames()
        loco.move(player, 0.0, false, STEP)
        for _i in range(4):
            await frames()
            loco.move(player, 0.0, false, STEP)
        await frames()
        loco.move(player, 0.0, true, STEP)
        check(player.velocity.y < 0.0, "coyote permite pulo após 83 ms fora do piso")
        await reset(carrasco)
        player.position.x = 10050.0
        for _i in range(9):
            await frames()
            loco.move(player, 0.0, false, STEP)
        await frames()
        loco.move(player, 0.0, true, STEP)
        check(player.velocity.y > 0.0, "coyote expira depois de 100 ms")
        await reset(carrasco)
        player.position.y = -19.0
        player.velocity.y = 100.0
        for tick in range(8):
            await frames()
            loco.move(player, 0.0, tick == 0, STEP, false, false, tick > 0)
        check(player.velocity.y < 0.0 and not player.is_on_floor(), "buffer transforma entrada anterior ao pouso em pulo")

func passage() -> void:
    if baseline:
        return
    var ceiling := solid("LowCeiling55", Vector2(300, -65), Vector2(240, 20))
    await frames(2)
    await reset(true, Vector2(100, -13.05))
    for _i in range(70):
        await frames()
        loco.move(player, 1.0, false, STEP)
    check(player.position.x > 250 and penetrations(player).is_empty(), "Carrasco passa sob teto de 55 unidades / 1,546875 m")
    var clear := true
    var standing_y := player.position.y
    var lowest_y := standing_y
    for tick in range(10):
        await frames()
        loco.move(player, 0.0, tick == 0, STEP)
        lowest_y = minf(lowest_y, player.position.y)
        clear = clear and penetrations(player).is_empty()
    check(clear and standing_y - lowest_y < 4.0, "pulo sob teto colide sem penetrar e limita subida à folga real")
    var before := player.position
    check(not masks.swap(), "troca para humano é recusada quando a cápsula maior não cabe")
    check(player.position == before and masks.active_data() == CARRASCO and near(masks.swap_cooldown_remaining, 0.0), "recusa preserva pés, máscara e cooldown")
    for _i in range(65):
        await frames()
        loco.move(player, 1.0, false, STEP)
    masks.swap_cooldown_remaining = 0.0
    check(masks.swap(), "troca para humano permitida após sair da passagem")
    await reset(false, Vector2(100, -13.05))
    for _i in range(100):
        await frames()
        loco.move(player, 1.0, false, STEP)
    check(player.position.x < 180.0 and penetrations(player).is_empty(), "humano conserva altura e é barrado pelo mesmo teto")
    ceiling.queue_free()
    await frames(2)
    # F3 decision: equal world radius, so every human-width slot also fits Carrasco.
    var left := solid("SlotLeft", Vector2(-317.5, -50), Vector2(20, 100))
    var right := solid("SlotRight", Vector2(-282.5, -50), Vector2(20, 100))
    await reset(false, Vector2(-300, -13.05))
    check(penetrations(player).is_empty(), "humano de 14 unidades cabe no vão de 15 / 0,421875 m")
    check(masks.swap(), "Carrasco de 14 unidades também cabe no vão de 15")
    check(masks.active_data() == CARRASCO and near(player.position.x, -300) and penetrations(player).is_empty(), "troca no vão mantém pés e não penetra nas paredes")
    measurements["passages"] = {"low_ceiling_world": 55, "low_ceiling_m": 55 / UNIT, "slot_width_world": 15, "slot_width_m": 15 / UNIT, "human_diameter_world": 14, "Carrasco_diameter_world": 14}
    left.queue_free()
    right.queue_free()
    await frames(2)

func attack_trial(kind: String, action: String, carrasco: bool, distance: float, raised: float) -> Dictionary:
    await reset(carrasco)
    var enemy: CharacterBody2D = enemies[kind]
    var attack: Node = enemy.get_node("Attack")
    attack.abort()
    enemy.set_facing(-1)
    var foot_offset := 15.5 if kind == "peregrino" else (9.0 if kind == "raiz_faminta" else 0.0)
    enemy.position = Vector2(distance, -foot_offset - raised)
    var hp := health.current_health
    if kind == "peregrino":
        var data: AttackData = attack.get(action)
        attack.start(data)
        attack.tick(data.windup_seconds + STEP, player, 5.0)
        for _i in range(ceili(data.active_seconds / STEP)):
            await frames()
            attack.tick(STEP, player, 5.0)
            root.get_node("HitStop")._restore()
    elif kind == "raiz_faminta":
        if action == "mordida":
            attack.begin_bite()
        else:
            attack.begin_emerge()
        var data: AttackData = attack.current_attack
        attack.tick(data.windup_seconds + STEP, player)
        for _i in range(ceili(data.active_seconds / STEP)):
            await frames()
            attack.tick(STEP, player)
            root.get_node("HitStop")._restore()
    else:
        attack.begin_dive()
        attack.tick(attack.rasante.windup_seconds + STEP, player)
        for _i in range(ceili(attack.rasante.active_seconds / STEP)):
            await frames()
            attack.tick(STEP, player)
            root.get_node("HitStop")._restore()
    var loss := hp - health.current_health
    attack.abort()
    enemy.position = Vector2(5000, -200)
    root.get_node("HitStop")._restore()
    return {"enemy": kind, "attack": action, "form": "Carrasco" if carrasco else "human", "dx_world": distance, "dx_m": distance / UNIT, "raised_world": raised, "raised_m": raised / UNIT, "damage": loss, "hit": loss > 0}

func contacts() -> void:
    # Hold origins still to isolate collision geometry; actual ACTIVE attack components
    # arm, rotate, overlap and damage. This does not modify AI tuning or source files.
    for kind in ["peregrino", "raiz_faminta", "corvo"]:
        var actions: Array = ["corte", "estocada"] if kind == "peregrino" else (["garra_subterranea", "mordida"] if kind == "raiz_faminta" else ["rasante"])
        for action in actions:
            for carrasco in [false, true]:
                var native_hits := 0
                for raised in [0.0, 28.0, 44.0]:
                    for distance in [10.0, 25.0, 40.0, 55.0]:
                        var record := await attack_trial(kind, action, carrasco, distance, raised)
                        measurements.contacts.append(record)
                        if near(raised, 0.0) and record.hit:
                            native_hits += 1
                check(native_hits > 0, "%s/%s acerta %s em altura normal" % [kind, action, "Carrasco" if carrasco else "humano"])
    var bird: CharacterBody2D = enemies.corvo
    for carrasco in [false, true]:
        for height in [4.0, 20.0, 40.0, 58.0, 70.0]:
            await reset(carrasco)
            var projectile: CorvoProjectile = load("res://scenes/enemies/corvo_projectile.tscn").instantiate()
            fixture.add_child(projectile)
            var hp := health.current_health
            projectile.launch(bird, Vector2(40, -height), Vector2(-40, -height), 125.0, 0.8)
            for _i in range(50):
                await frames()
                root.get_node("HitStop")._restore()
                if not is_instance_valid(projectile):
                    break
            if is_instance_valid(projectile):
                projectile.expire()
            var hit := health.current_health < hp
            measurements.contacts.append({"enemy": "corvo", "attack": "projectile", "form": "Carrasco" if carrasco else "human", "dx_world": 40, "height_world": height, "height_m": height / UNIT, "hit": hit, "damage": hp - health.current_health})
            check(hit == (height <= (51.111111 if carrasco and not baseline else 64.0)), "projétil horizontal a %.1f unidades dos pés: %s" % [height, "acerta" if hit else "passa acima"])

func run() -> void:
    Engine.physics_ticks_per_second = 60
    await scene_checks()
    await build()
    await profiles()
    await jumps()
    await passage()
    await contacts()
    measurements["baseline"] = baseline
    measurements["checks"] = checks
    measurements["failures"] = failures
    var path := "res://codex/evidencias_integracao_p40_f3/REGRESSAO_F2_MEDIDAS_%s.json" % ("antes" if baseline else "depois")
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(measurements, "  ") + "\n")
    file.close()
    fixture.queue_free()
    await frames(2)
    print("PHASE2: ", checks, " checks / ", failures, " failures")
    quit(1 if failures > 0 else 0)
