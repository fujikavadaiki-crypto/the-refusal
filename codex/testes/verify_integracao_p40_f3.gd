extends SceneTree

## Production presenter, physics space and damage components; no mocked contacts.
const PACKAGE := preload("res://scripts/player/visuals/carrasco_p42b_package.gd")
const CARRASCO := preload("res://data/masks/carrasco_base.tres")
const STEP := 1.0 / 60.0
var failures := 0
var checks := 0
var fixture: Node2D
var player: CharacterBody2D
var presenter: Node2D
var combat: PlayerCombat
var masks: MaskController
var targets: Array[Node2D] = []
var metrics := {"physics_hz": 60, "attacks": [], "shadow": {}, "running": {}}

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if ok:
        print("PASS: ", label)
    else:
        failures += 1
        printerr("FAIL: ", label)

func frames(count := 1) -> void:
    for _i in range(count):
        await physics_frame

func near(a: float, b: float, tolerance := 0.002) -> bool:
    return absf(a - b) <= tolerance

func solid(at: Vector2, size: Vector2) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = at
    body.collision_layer = 1
    var shape := RectangleShape2D.new()
    shape.size = size
    var collision := CollisionShape2D.new()
    collision.shape = shape
    body.add_child(collision)
    fixture.add_child(body)
    return body

func freeze_presenter() -> void:
    presenter = player.get_node("VisualRoot").form
    presenter.set_process(false)
    presenter.set_physics_process(false)
    player.get_node("VisualRoot").set_process(false)

func target(at: Vector2) -> Node2D:
    var node := Node2D.new()
    node.position = at
    var stats := DefenseStats.new()
    stats.name = "Stats"
    var posture := PostureComponent.new()
    posture.name = "Posture"
    posture.max_posture = 1000.0
    var hp := HealthComponent.new()
    hp.name = "Health"
    hp.max_health = 1000
    hp.stats_path = NodePath("../Stats")
    hp.posture_path = NodePath("../Posture")
    node.add_child(stats)
    node.add_child(posture)
    node.add_child(hp)
    var hurt := Hurtbox2D.new()
    hurt.name = "Hurtbox"
    hurt.receiver_path = NodePath("../Health")
    hurt.collision_layer = 4
    hurt.collision_mask = 0
    var collision := CollisionShape2D.new()
    collision.name = "CollisionShape2D"
    var shape := CircleShape2D.new()
    shape.radius = 1.0
    collision.shape = shape
    hurt.add_child(collision)
    node.add_child(hurt)
    fixture.add_child(node)
    targets.append(node)
    return node

func reset() -> void:
    root.get_node("HitStop")._restore()
    combat.abort_attack()
    player.position = Vector2(0, -13.05)
    player.velocity = Vector2.ZERO
    player.get_node("Health").reset_health()
    player.get_node("Posture").reset_posture()
    player.get_node("Defense").mode = PlayerDefense.Mode.READY
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    combat.set_facing(1)
    presenter.reset_tracking()
    for node in targets:
        node.position = Vector2(5000, -200)
        node.get_node("Health").reset_health()
        node.get_node("Posture").reset_posture()
    await frames(2)
    player.get_node("Locomotion").move(player, 0.0, false, STEP)

func package_checks() -> void:
    var package := PACKAGE.load_package()
    check(package.valid, "v34A carrega sem erros: %s" % [package.errors])
    check(package.anims.size() == 26, "26 animações do manifesto disponíveis")
    check(package.manifest_sha256 == "0a61e24f68a2d5ed2ebbdfc666c504d2851fa8f66316cae5d9c8f33c114d9a64", "manifesto copiado conserva SHA256 da fonte")
    check(package.hash_modes.size() == 190, "190 PNGs referenciados validados por SHA256/raw ou caBX")
    for anim_id: String in package.anims:
        var anim: Dictionary = package.anims[anim_id]
        check(not anim.frames.is_empty() and anim.ms > 0, "%s: quadros e tempos carregados" % anim_id)
        for frame: Dictionary in anim.frames:
            check(frame.tex != null and frame.ancora == frame.ancora.round(), "%s: textura e âncora inteira" % anim_id)
            for part: PackedVector2Array in frame.hitbox.get("parts", []):
                var front := true
                for point in part:
                    front = front and point.x >= 0
                check(front and part.size() >= 3, "%s: peça convexa somente à frente" % anim_id)
    check(PACKAGE.safe_path("poses/idle.png") and not PACKAGE.safe_path("../fora.png") and not PACKAGE.safe_path("C:/fora.png"), "leitor recusa caminho fora do pacote")
    check(PACKAGE.sha256_without_cabx(PackedByteArray([1, 2, 3])) == "", "PNG truncado não passa na normalização")
    var errors: Array[String] = []
    var rectangle := PACKAGE.decode_hitbox({"retangulos": [[-8, -20, 24, 10]]}, errors)
    check(errors.is_empty() and rectangle.parts.size() == 1, "retângulo opcional também é aceito")
    check(rectangle.parts[0][0].x >= 0, "retângulo cruzando os pés é recortado na frente")
    PACKAGE.decode_hitbox({"retangulos": "invalido"}, errors)
    check(not errors.is_empty(), "lista de retângulos inválida é rejeitada")

func build() -> void:
    fixture = Node2D.new()
    root.add_child(fixture)
    solid(Vector2(0, 32), Vector2(4000, 64))
    player = load("res://scenes/player/player.tscn").instantiate()
    player.position = Vector2(0, -13.05)
    fixture.add_child(player)
    player.set_physics_process(false)
    player.get_node("Camera2D").enabled = false
    combat = player.get_node("Combat")
    masks = player.get_node("MaskController")
    masks.equip(0, CARRASCO)
    masks.equip(1, null)
    freeze_presenter()
    await frames(3)
    root.canvas_transform = Transform2D(Vector2(0.9, 0), Vector2(0, 0.9), Vector2(10.25, 12.4))
    target(Vector2(5000, -200))
    target(Vector2(5000, -200))
    await reset()

func anchors_and_effects() -> void:
    check(presenter.package_ready and combat.frame_provider == presenter, "modo pequeno é o apresentador e provedor de dano ativos")
    for direction in [1, -1]:
        player.facing_direction = direction
        player.get_node("VisualRoot").scale.x = direction
        presenter.sync(0.0)
        var canvas: Transform2D = root.canvas_transform
        var transform: Transform2D = canvas * presenter.global_transform
        check(transform.x.is_equal_approx(Vector2.RIGHT) and transform.y.is_equal_approx(Vector2.DOWN), "arte ×1 mesmo com zoom .9 e facing %d" % direction)
        check(transform.origin == (canvas * (player.global_position + Vector2(0, 13))).round(), "âncora coincide com pés arredondados, facing %d" % direction)
        check(presenter.body.flip_h == (direction < 0) and presenter.body.scale == Vector2.ONE, "um espelhamento horizontal; corpo nunca escalado")
        check(presenter.body.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "amostragem NEAREST")
    for id: String in presenter.character.anims:
        for frame: Dictionary in presenter.character.anims[id].frames:
            for flipped in [false, true]:
                var offset: Vector2 = presenter._offset(frame.tex, frame.ancora, flipped)
                var anchor: Vector2 = Vector2(frame.tex.get_width() - frame.ancora.x if flipped else frame.ancora.x, frame.ancora.y)
                check((offset + anchor).is_zero_approx(), "%s: quadro espelhado conserva a âncora" % id)
    for phase in [PlayerCombat.Phase.WINDUP, PlayerCombat.Phase.ACTIVE, PlayerCombat.Phase.RECOVERY]:
        combat.phase = phase
        presenter.frame_spec = presenter.character.anims.heavy.frames[4]
        presenter._sync_effects(false)
        var visible := 0
        for effect in presenter.effect_nodes:
            visible += int(effect.visible)
        check(visible > 0 if phase == PlayerCombat.Phase.ACTIVE else visible == 0, "heavy FX respeita fase %d" % phase)
    combat.abort_attack()
    presenter.sync(0.0)
    check(near(presenter.ghost_life(false), .11) and presenter.ghost_limit(false) == 3 and near(presenter.ghost_life(true), .08) and presenter.ghost_limit(true) == 2, "rastro e névoa conservam tempos/limites do P42b")

func shadow_checks() -> void:
    await reset()
    var legacy := preload("res://scripts/biomes/forest/bosque_contact_shadow.gd").new()
    fixture.add_child(legacy)
    legacy.set_physics_process(false)
    legacy._physics_process(STEP)
    presenter.sync(0.0)
    check(not legacy.visible and presenter.shadow.visible, "uma sombra: antiga desligada somente no modo novo")
    var ground: Vector2 = presenter.shadow_ground_screen
    player.position.y -= 2.2 * 32 / .9
    presenter.sync(0.0)
    check(presenter.shadow_ground_screen == ground and near(presenter.shadow_factor, .5), "no pulo, sombra permanece no piso e reduz a 50%")
    check(near(presenter.shadow.modulate.a, .5) and presenter.body.scale == Vector2.ONE, "sombra clareia; corpo mantém ×1")
    metrics.shadow = {"ground_screen": [ground.x, ground.y], "apex_factor": presenter.shadow_factor}
    var underneath: CharacterBody2D = load("res://scenes/enemies/peregrino.tscn").instantiate()
    underneath.position = Vector2(0, -15.55)
    fixture.add_child(underneath)
    underneath.set_physics_process(false)
    await frames(2)
    presenter.sync(0.0)
    check(presenter.shadow_ground_screen == ground and near(presenter.shadow_factor, .5), "inimigo sob o jogador não vira chão para a sombra")
    underneath.queue_free()
    await frames(2)
    player.position.x = 5000
    presenter.sync(0.0)
    check(not presenter.shadow.visible, "sem chão embaixo não desenha sombra")
    await reset()
    masks.activate_slot_for_setup(1)
    await frames(2)
    legacy._physics_process(STEP)
    check(legacy.visible and combat.frame_provider == null and not player.get_meta("small_carrasco_presenter_active"), "humano restaura sombra e contato legados")
    check(player.get_node("VisualRoot/Body").visible, "arte humana preservada")
    masks.activate_slot_for_setup(0)
    freeze_presenter()
    legacy.queue_free()
    await frames(2)

func distance_checks() -> void:
    await reset()
    var loco: PlayerLocomotion = player.get_node("Locomotion")
    var start_x := player.position.x
    for _i in range(30):
        loco.move(player, 1.0, false, STEP)
        presenter._physics_process(STEP)
        presenter.sync(0.0)
        await frames()
    check(near(presenter.run_distance_px, absf(player.position.x - start_x) * .9), "corrida conta distância resolvida pelo corpo")
    check(presenter.frame_index == int(floor(presenter.run_distance_px / 6.0)) % 8, "corrida escolhe floor(distância/6) mod 8")
    var release_x := player.position.x
    var stop_ticks := 0
    while absf(player.velocity.x) > .001 and stop_ticks < 20:
        loco.move(player, 0.0, false, STEP)
        presenter._physics_process(STEP)
        presenter.sync(0.0)
        stop_ticks += 1
        await frames()
    check(stop_ticks <= 7 and absf(player.position.x - release_x) < 9, "soltar direção para com desaceleração normal, sem andar até apoio")
    check(presenter.nearest_support_frame() in [1, 5], "parada escolhe somente apoio visual 1/5")
    metrics.running = {"stop_ticks": stop_ticks, "stop_seconds": stop_ticks / 60.0, "braking_world": player.position.x - release_x, "px_per_frame": 6}
    for _i in range(12):
        presenter._physics_process(STEP)
        presenter.sync(0.0)
    check(presenter.anim_id == "idle", "apoio/freio visual retornam ao idle sem deslocamento")
    var distance: float = presenter.run_distance_px
    root.canvas_transform.origin += Vector2(30.3, 10.1)
    presenter.sync(0.0)
    check(near(distance, presenter.run_distance_px), "movimento da câmera não avança corrida")
    var wall := solid(Vector2(240, -50), Vector2(10, 100))
    await frames(2)
    for _i in range(90):
        loco.move(player, 1.0, false, STEP)
        presenter._physics_process(STEP)
        await frames()
    distance = presenter.run_distance_px
    for _i in range(5):
        loco.move(player, 1.0, false, STEP)
        presenter._physics_process(STEP)
        await frames()
    check(near(distance, presenter.run_distance_px), "parede impede avanço da animação por distância")
    player.position.x += 200
    presenter._physics_process(STEP)
    check(near(presenter.run_distance_px, 0) and presenter.ghosts.is_empty(), "teleporte reinicia fase e rastro")
    wall.queue_free()
    await frames(2)

func attack_checks() -> void:
    for attack_id: String in PACKAGE.ATTACKS:
        var data: AttackData = load("res://data/attacks/%s.tres" % attack_id)
        var anim: Dictionary = PACKAGE.load_package().anims[PACKAGE.ATTACKS[attack_id]]
        check(near(data.total_seconds() * 1000, anim.ms, .02), "%s mantém duração .tres e manifesto" % attack_id)
        var time := 0.0
        for index in range(anim.frames.size()):
            var spec: Dictionary = anim.frames[index]
            var midpoint: float = (time + float(spec.ms) / 2) / 1000
            time += float(spec.ms)
            if spec.hitbox.is_empty():
                continue
            for direction in [1, -1]:
                await reset()
                if attack_id.contains("air_"):
                    player.position.y -= 120
                player.facing_direction = direction
                combat.set_facing(direction)
                var part: PackedVector2Array = spec.hitbox.parts[0]
                var center := Vector2.ZERO
                for point in part:
                    center += point
                center /= part.size()
                targets[0].position = player.position + Vector2(0, 13) + Vector2(center.x * direction, center.y) / .9
                targets[1].position = player.position + Vector2(-15 * direction, -20)
                await frames(2)
                combat.start_special(data)
                combat.elapsed = midpoint - STEP
                combat.tick(STEP)
                combat.resolve_frame_contact()
                presenter.sync(0.0)
                var hp: int = targets[0].get_node("Health").current_health
                check(combat.phase == PlayerCombat.Phase.ACTIVE and combat.hitbox.frame_override_active, "%s/%d: geometria só no ACTIVE" % [attack_id, index])
                check(combat.frame_hitbox_frame == presenter.frame_index and combat.frame_hitbox_anim == presenter.anim_id, "%s/%d: arte e dano selecionam mesmo quadro" % [attack_id, index])
                check(hp < 1000 and targets[1].get_node("Health").current_health == 1000, "%s/%d: contato à frente, nunca atrás (%d)" % [attack_id, index, direction])
                combat.resolve_frame_contact()
                combat.hitbox.scan_overlaps()
                check(targets[0].get_node("Health").current_health == hp, "%s: peças/scans deduplicam contato por ação" % attack_id)
                combat.elapsed = data.windup_seconds + data.active_seconds + .01 - STEP
                combat.tick(STEP)
                combat.resolve_frame_contact()
                check(not combat.hitbox.active and not combat.hitbox.frame_override_active, "%s: recuperação não produz dano" % attack_id)
                metrics.attacks.append({"attack": attack_id, "frame": index, "facing": direction, "damage": 1000 - hp})
    # Moving feet are applied before the first ACTIVE scan; interrupted attacks stop it.
    await reset()
    combat.start_special(CARRASCO.heavy)
    combat.elapsed = .34 - STEP
    combat.tick(STEP)
    player.position.x += 7
    combat.resolve_frame_contact()
    check(combat.hitbox.frame_feet_world == player.position + Vector2(0, 13), "primeiro ACTIVE usa pés após movimento do tick")
    var previous_canvas: Transform2D = root.canvas_transform
    root.canvas_transform = Transform2D.IDENTITY
    presenter.sync(0.0)
    var native_transform: Transform2D = root.canvas_transform * presenter.global_transform
    check(native_transform.x.is_equal_approx(Vector2.RIGHT) and native_transform.y.is_equal_approx(Vector2.DOWN), "arte mantém ×1 também na sala com zoom 1")
    var px: Vector2 = combat.hitbox.frame_parts[0][0]
    var projected: Vector2 = combat.hitbox.current_world_parts()[0][0] - combat.hitbox.frame_feet_world
    metrics["zoom"] = {"art_native_scale": native_transform.x.length(), "damage_reference_zoom": .9, "damage_projection_ratio_at_zoom_1": projected.length() / px.length(), "review": "Passo 12: uniformizar zoom das salas; área física continua independente da câmera."}
    check(near(projected.length() / px.length(), 1.0 / .9), "área física conserva escala fixa; diferença de projeção em zoom 1 medida")
    root.canvas_transform = previous_canvas
    presenter.damage_remaining = .18
    combat.resolve_frame_contact()
    check(combat.hitbox.frame_parts.is_empty(), "pose hurt cobrindo ataque suprime dano")
    combat.abort_attack()
    combat.resolve_frame_contact()
    check(not combat.hitbox.active, "interrupção elimina dano imediatamente")
    await reset()
    combat.start_special(CARRASCO.skill_1)
    combat.elapsed = CARRASCO.skill_1.windup_seconds
    combat.tick(STEP)
    combat.resolve_frame_contact()
    check(not combat.uses_frame_profile() and not combat.hitbox.frame_override_active and combat.hitbox.active, "habilidade sem dados conserva pivô/fallback")
    # Actual Peregrino capsule: meaningful close/tip contacts, not a point target.
    var enemy_capsule := CapsuleShape2D.new()
    enemy_capsule.radius = 7
    enemy_capsule.height = 31
    targets[0].get_node("Hurtbox/CollisionShape2D").shape = enemy_capsule
    for dx in [12.0, 57.0, -20.0, 95.0]:
        await reset()
        targets[0].position = player.position + Vector2(dx / .9, -15.5 + 13)
        await frames(2)
        combat.start_special(CARRASCO.heavy)
        for _i in range(35):
            combat.tick(STEP)
            combat.resolve_frame_contact()
        var damaged: bool = targets[0].get_node("Health").current_health < 1000
        check(damaged == (dx in [12.0, 57.0]), "heavy real: colado/ponta/atrás/fora, dx %.1f px" % dx)
    await reset()
    targets[0].position = player.position + Vector2(42, -15)
    var wall := solid(Vector2(20, -35), Vector2(5, 70))
    await frames(2)
    combat.start_special(CARRASCO.heavy)
    for _i in range(35):
        combat.tick(STEP)
        combat.resolve_frame_contact()
    check(targets[0].get_node("Health").current_health == 1000, "dano por quadro não atravessa parede sólida")
    wall.queue_free()

func bosque_checks() -> void:
    fixture.queue_free()
    await frames(3)
    var scene: Node2D = load("res://scenes/biomes/forest/bosque_integracao_p40.tscn").instantiate()
    root.add_child(scene)
    await frames(12)
    check(scene.enemies_ready and scene.enemies.size() == 3, "Bosque jogável instancia Peregrino, Corvo e Raiz")
    for enemy in scene.enemies:
        check(enemy.get_node("Brain").player == scene.player, "%s usa alvo real com IA original" % enemy.name)
    check(scene.player.get_node("VisualRoot").form.package_ready, "Bosque usa Pequeno A v34A")
    scene.player.get_node("Health").current_health = 0
    scene.restart_encounter()
    await frames(3)
    check(scene.player.get_node("Health").current_health == scene.player.get_node("Health").max_health and scene.player.get_node("Defense").mode == PlayerDefense.Mode.READY, "R restaura vida/estado e reinicia encontro")
    scene.queue_free()
    await frames(3)

func run() -> void:
    package_checks()
    await build()
    anchors_and_effects()
    await shadow_checks()
    await distance_checks()
    await attack_checks()
    await bosque_checks()
    metrics["checks"] = checks
    metrics["failures"] = failures
    var file := FileAccess.open("res://codex/evidencias_integracao_p40_f3/MEDIDAS_F3.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(metrics, "  ") + "\n")
    print("F3_RESULT checks=%d failures=%d" % [checks, failures])
    quit(0 if failures == 0 else 1)
