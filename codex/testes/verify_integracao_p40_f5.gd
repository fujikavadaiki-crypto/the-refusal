extends SceneTree

const ROOM := preload("res://scenes/biomes/cemiterio/sala_cemiterio.tscn")
const PACKAGE := preload("res://scripts/enemies/presentation/enemy_package.gd")
const FAKE := "res://codex/fixtures/inimigo_falso_v1/"
const MAP := FAKE + "fixture_mapa.json"
const DT := 1.0 / 60.0
var failures := 0
var checks := 0
var room: Node2D
var p: CharacterBody2D
var feel: Node
var measurements := {}

func _initialize() -> void: run.call_deferred()

func frames(n := 1) -> void:
    for _i in range(n): await physics_frame

func check(ok: bool, message: String) -> void:
    checks += 1
    if ok: print("PASS: ", message)
    else:
        failures += 1
        printerr("FAIL: ", message)

func freeze(actor: Node) -> void:
    actor.set_physics_process(false)
    for child in actor.get_children(): freeze(child)

func context(target: Node2D, heavy := false) -> HitContext:
    var c := HitContext.new()
    c.attacker = p
    c.target = target
    c.base_damage = 1
    c.posture_damage = 0
    c.attack_id = &"fixture_heavy" if heavy else &"fixture_light"
    c.tags = PackedStringArray(["heavy" if heavy else "light"])
    c.action_uid = HitContext.allocate_action_id()
    return c

func settle() -> void:
    p.global_position = room.to_global(Vector2(150, room.floor_screen(150)) / .9) - Vector2(0, 13.05)
    p.velocity = Vector2.ZERO
    p.locomotion.reset_assists()
    p.get_node("SensacaoAlvo").reset()
    for _i in range(4): p.locomotion.move(p, 0, false, DT)

func jump(release_at: int, assists: bool) -> Dictionary:
    feel.set_group("controle", assists)
    settle()
    var origin := p.global_position.y
    var minimum := origin
    var apex := 0
    var landed := 0
    for tick in range(75):
        p.locomotion.move(p, 0, tick == 0, DT, false, false, true, -1, tick < release_at)
        if p.global_position.y < minimum:
            minimum = p.global_position.y
            apex = tick + 1
        if tick > 2 and p.is_on_floor():
            landed = tick + 1
            break
    return {"height_m": (origin - minimum) / PlayerLocomotion.P40_UNITS_PER_METER, "apex_ticks": apex, "landed_ticks": landed}

func control_checks() -> void:
    check(feel.groups.values().all(func(v: Variant) -> bool: return bool(v)), "quatro grupos ligados por padrão")
    check(feel.value("controle", "buffer_pulo_ms") == 100 and feel.value("controle", "coyote_ms") == 100, "pulo/coyote 100 ms no arquivo único")
    check(feel.value("controle", "buffer_ataque_ms") == 120 and feel.value("controle", "buffer_dash_ms") == 120, "ataque/dash 120 ms no arquivo único")
    measurements.tap = jump(1, true)
    measurements.held = jump(60, true)
    measurements.off = jump(1, false)
    check(absf(measurements.tap.height_m - 1.0) < .06, "soltar cedo: mínimo ~1 m")
    check(absf(measurements.held.height_m - 2.314903) < .002 and measurements.held.apex_ticks == 20, "segurar mantém pulo P40 a 60 Hz")
    check(absf(measurements.off.height_m - measurements.held.height_m) < .001, "controle OFF desliga corte variável")
    feel.set_group("controle", true)
    settle()
    p.global_position.y -= 20
    p.locomotion.move(p, 0, false, DT)
    p.locomotion.coyote_remaining = .085
    p.locomotion.move(p, 0, true, DT)
    check(p.velocity.y < -400, "coyote aceita pulo após saída do chão")
    settle()
    p.global_position.y -= 20
    p.locomotion.move(p, 0, false, DT)
    p.locomotion.coyote_remaining = 0
    p.locomotion.move(p, 0, true, DT, false, false, false)
    check(p.locomotion.jump_buffer_remaining > .09, "buffer de pulo conserva pedido enquanto bloqueado")
    for _i in range(7): p.locomotion.move(p, 0, false, DT, false, false, false)
    check(p.locomotion.jump_buffer_remaining == 0, "buffer expira após 100 ms")
    settle()
    p.light_buffer_remaining = .1
    p.dash_buffer_remaining = .1
    feel.set_group("controle", false)
    check(p.light_buffer_remaining == 0 and p.dash_buffer_remaining == 0, "desligar controle descarta pedidos pendentes")
    feel.set_group("controle", true)
    # Exercise production input router, not a duplicate cancellation implementation.
    settle()
    p.combat.start_special(p.masks.active_data().light_1)
    p.combat.current_light_stage = 1
    p.combat.elapsed = p.combat.current_attack.windup_seconds + p.combat.current_attack.active_seconds + .01
    p.combat.phase = PlayerCombat.Phase.RECOVERY
    p.defense.mode = PlayerDefense.Mode.READY
    p.defense.dodge_cooldown = 0
    Input.action_press("dodge")
    p.set_physics_process(true)
    await frames(2)
    p.set_physics_process(false)
    Input.action_release("dodge")
    check(p.defense.is_dashing() and not p.combat.is_busy(), "dash cancela somente recuperação leve")
    p.defense.mode = PlayerDefense.Mode.READY
    p.defense.dodge_cooldown = 0
    await frames(2)
    p.combat.start_special(p.masks.active_data().heavy)
    p.combat.phase = PlayerCombat.Phase.RECOVERY
    p.combat.elapsed = p.combat.current_attack.windup_seconds + p.combat.current_attack.active_seconds + .01
    Input.action_press("dodge")
    p.set_physics_process(true)
    await frames(2)
    p.set_physics_process(false)
    Input.action_release("dodge")
    check(p.combat.is_busy() and not p.defense.is_dashing(), "dash não cancela recuperação pesada")
    p.combat.abort_attack()
    p.clear_action_buffers()
    for wait_seconds in [.08, .25]:
        settle()
        p.defense.mode = PlayerDefense.Mode.READY
        p.defense.dodge_cooldown = wait_seconds
        Input.action_press("dodge")
        p.set_physics_process(true)
        await frames(2)
        Input.action_release("dodge")
        await frames(8 if wait_seconds < .1 else 16)
        p.set_physics_process(false)
        check(p.defense.is_dashing() == (wait_seconds < .1), "buffer dash: cooldown %.0f ms %s pedido" % [wait_seconds * 1000, "aceita" if wait_seconds < .1 else "expira"])
        p.defense.mode = PlayerDefense.Mode.READY
        p.clear_action_buffers()
    for wait_seconds in [.08, .25]:
        settle()
        p.combat.start_special(p.masks.active_data().heavy)
        p.combat.phase = PlayerCombat.Phase.RECOVERY
        p.combat.elapsed = p.combat.current_attack.total_seconds() - wait_seconds
        p.defense.mode = PlayerDefense.Mode.READY
        Input.action_press("attack_light")
        p.set_physics_process(true)
        await frames(2)
        Input.action_release("attack_light")
        await frames(8 if wait_seconds < .1 else 16)
        p.set_physics_process(false)
        check((p.combat.current_light_stage == 1) == (wait_seconds < .1), "buffer ataque: bloqueio %.0f ms %s pedido" % [wait_seconds * 1000, "aceita" if wait_seconds < .1 else "expira"])
        p.combat.abort_attack()
        p.clear_action_buffers()

func impact_checks() -> void:
    var enemy: CharacterBody2D = room.enemies[0]
    var fb: Node = enemy.get_node("SensacaoAlvo")
    var stop: Node = root.get_node("HitStop")
    settle()
    enemy.global_position.x = p.global_position.x + 45
    var c := context(enemy)
    var count: int = stop.request_count
    enemy.health.receive_hit(c)
    stop.request_hit(c)
    check(stop.last_requested_ms == 60 and stop.request_count == count + 1, "un hitstop leve único de 60 ms")
    check(room.camera.shake_remaining == 0, "leve não treme câmera")
    check(fb.flash_frames == 2 and fb.recoil > 0, "alvo: flash de dois quadros e recuo para fora")
    fb._process(0)
    check(not fb.saved_materials.is_empty() and fb.flash_frames == 1, "flash branco aplicado à arte, sem atingir sombra")
    fb._process(0)
    fb._process(0)
    check(fb.saved_materials.is_empty(), "material original restaurado após dois quadros")
    var origin := enemy.global_position.x
    for _i in range(60):
        fb.apply_recoil(DT)
        enemy.move_and_slide()
    check(enemy.global_position.x > origin and enemy.global_position.x - origin <= .5 * (32 / .9) + .1, "recuo efetivo com atrito e limite de meio metro")
    stop._restore()
    c = context(enemy, true)
    enemy.health.receive_hit(c)
    stop.request_hit(c)
    check(stop.last_requested_ms == 90 and room.camera.shake_remaining > 0, "pesado: hitstop 90 ms e tremor no responsável existente")
    check(feel.pixels.emissions.sangue >= 2 and not feel.pixels.particles.is_empty(), "sangue de paleta emitido em pixels")
    feel.set_group("impacto", false)
    stop._process(0)
    check(not stop.active and is_equal_approx(Engine.time_scale, 1), "impacto OFF libera hitstop ativo")
    check(fb.recoil == 0 and fb.flash_frames == 0 and room.camera.shake_remaining == 0, "impacto OFF remove recuo, flash e tremor")
    count = stop.request_count
    enemy.health.receive_hit(context(enemy, true))
    stop.request_hit(context(enemy, true))
    check(stop.request_count == count and fb.flash_frames == 0, "impacto OFF mantém dano sem feedback")
    feel.set_group("impacto", true)
    enemy.health.reset_health()

func presentation_checks() -> void:
    var pack := PACKAGE.load_package(FAKE)
    check(pack.valid and pack.anims.size() == 4, "pacote FALSO mínimo lê animacoes[] sem exigir animações do Carrasco")
    check(not PACKAGE.load_package("res://../escape").valid, "raiz externa rejeitada")
    check(not PACKAGE.load_package("res://assets/enemies/peregrino_v1/").valid, "pacote ausente preserva fallback")
    var root_enemy: CharacterBody2D = room.enemies[2]
    root_enemy.brain.state = RaizFamintaBrain.State.HIDDEN
    root_enemy._apply_state(root_enemy.brain.state)
    root_enemy.get_node("ApresentadorPacote")._process(0)
    check(not root_enemy.visual.visible and root_enemy.mound.visible, "fallback mantém Raiz enterrada conforme IA original")
    var enemy: CharacterBody2D = room.enemies[0]
    var presenter: Node2D = enemy.get_node("ApresentadorPacote")
    check(not presenter.active and enemy.visual.visible, "inimigo real ainda usa arte provisória")
    enemy.reset_enemy()
    presenter.bind_actor(enemy, MAP)
    enemy.attack.abort()
    presenter._process(0)
    check(presenter.active and not enemy.visual.visible and presenter.current_anim == "idle", "mapa da IA ativa arte do pacote sem mudar IA")
    var canvas: Transform2D = room.get_viewport().get_canvas_transform()
    var feet: Vector2 = canvas * (enemy.global_position + presenter.feet_local)
    var origin: Vector2 = canvas * presenter.global_position
    check(origin.distance_to(feet.round()) < .001, "âncora dos pés arredondada em tela")
    enemy.set_facing(-1)
    presenter._process(0)
    check(presenter.body.flip_h and presenter.body.offset.x == -22, "espelho único preserva âncora (10,30) em PNG de 32 px")
    check((canvas * presenter.global_position) == origin, "virada não desloca pés")
    var body_at := enemy.global_position
    presenter._process(0)
    check(presenter.shadow.visible, "sombra separada detecta chão por raycast")
    enemy.global_position.y -= 2.2 * (32 / .9)
    presenter._process(0)
    check(presenter.shadow.visible and presenter.shadow.modulate.a <= .51, "sombra no ar permanece no chão e clareia até metade")
    enemy.global_position.x = -500
    presenter._process(0)
    check(not presenter.shadow.visible, "sem chão embaixo não há sombra")
    enemy.global_position = body_at
    enemy.set_facing(1)
    enemy.attack.start(enemy.attack.corte)
    presenter._process(0)
    check(presenter.current_anim == "attack" and presenter.fx_root.get_child_count() == 0, "WINDUP: quadro correto, nenhum FX ACTIVE")
    var data: AttackData = enemy.attack.corte
    enemy.attack.elapsed = data.windup_seconds + .01
    presenter._process(0)
    check(presenter.frame_index == 1 and presenter.fx_root.get_child_count() == 1, "ACTIVE inicial: retângulo e FX do mesmo quadro")
    enemy.attack._arm()
    check(enemy.attack.hitbox.frame_override_active and enemy.attack.hitbox.frame_parts.size() == 1, "armar ataque aplica área por quadro antes do contato nativo")
    var first: Array = enemy.attack.hitbox.current_screen_parts()
    enemy.attack.elapsed = data.windup_seconds + data.active_seconds * .75
    presenter.apply_damage(enemy.attack.hitbox, data, enemy.attack.elapsed)
    presenter._process(0)
    check(presenter.frame_index == 2 and first != enemy.attack.hitbox.current_screen_parts(), "ACTIVE seguinte seleciona polígono diferente no tick")
    for part: PackedVector2Array in enemy.attack.hitbox.current_screen_parts():
        var front := true
        for point in part: front = front and point.x >= 0
        check(front, "dano do pacote só à frente")
    enemy.attack.elapsed = data.windup_seconds + data.active_seconds + .01
    presenter._process(0)
    check(presenter.fx_root.get_child_count() == 0 and presenter.frame_index == 3, "RECOVERY: sem FX ACTIVE")
    enemy.attack.abort()
    check(not enemy.attack.hitbox.active and not enemy.attack.hitbox.frame_override_active, "abortar limpa toda área por quadro")
    # Query real player hurtbox; two frames retain one action UID.
    settle()
    enemy.global_position = p.global_position + Vector2(-14, -2.5)
    await frames(2) # Publish moved Area2D transforms before the query.
    enemy.set_facing(1)
    enemy.attack.start(data)
    enemy.attack.elapsed = data.windup_seconds + .01
    enemy.attack._arm()
    p.defense.mode = PlayerDefense.Mode.READY
    p.get_node("Health").reset_health()
    var hp_before: int = p.get_node("Health").current_health
    enemy.attack.resolve_frame_contact()
    check(p.get_node("Health").current_health < hp_before, "retângulo do pacote causa dano na hurtbox real")
    var hp_after: int = p.get_node("Health").current_health
    enemy.attack.elapsed = data.windup_seconds + data.active_seconds * .75
    presenter.apply_damage(enemy.attack.hitbox, data, enemy.attack.elapsed)
    enemy.attack.hitbox.scan_overlaps()
    check(p.get_node("Health").current_health == hp_after, "quadros diferentes não duplicam dano do mesmo UID")
    enemy.attack.abort()
    root.get_node("HitStop")._restore()
    p.get_node("SensacaoAlvo").reset()
    presenter.bind_actor(enemy, "res://data/enemies/peregrino_mapa.json")
    enemy.attack.start(data)
    enemy.attack._arm()
    check(not enemy.attack.hitbox.frame_override_active, "ataque sem pacote usa retângulo/pivô existente")
    enemy.attack.abort()
    # Rendering and damage mapping support all three native enemy owners.
    for target: CharacterBody2D in room.enemies:
        var view: Node = target.get_node("ApresentadorPacote")
        view.bind_actor(target, MAP)
        var attack_data: AttackData = target.attack.rasante if target.name == "Corvo" else (target.attack.mordida if target.name == "Raiz" else target.attack.corte)
        var sample: Dictionary = view.attack_sample(attack_data, attack_data.windup_seconds + .01)
        check(not sample.is_empty() and sample.has_damage, "%s aceita área do pacote falso" % target.name)
        view.bind_actor(target, "res://data/enemies/%s_mapa.json" % ("raiz_faminta" if target.name == "Raiz" else String(target.name).to_lower()))
    var bird: CharacterBody2D = room.enemies[1]
    var bird_view: Node = bird.get_node("ApresentadorPacote")
    bird_view.bind_actor(bird, MAP)
    var projectile: CorvoProjectile = bird.attack.projectile_scene.instantiate()
    room.add_child(projectile)
    projectile.set_physics_process(false)
    projectile.frame_provider = bird_view
    projectile.launch(bird, p.global_position + Vector2(-30, -20), p.global_position, 125, 2.2)
    check(projectile.hitbox.frame_override_active and projectile.hitbox.frame_feet_world == projectile.global_position, "Corvo: área por quadro acompanha origem do projétil")
    projectile.age = .31
    projectile._sync_frame()
    check(projectile.package_body.visible and not projectile.get_node("Core").visible and projectile.hitbox.frame_parts.size() == 1, "projétil: arte/retângulo ACTIVE vêm do mesmo quadro dedicado")
    var locked: int = projectile.hitbox.frame_facing
    bird.set_facing(-locked)
    projectile.global_position.x += 10
    projectile._sync_frame()
    check(projectile.hitbox.frame_feet_world == projectile.global_position and projectile.hitbox.frame_facing == locked, "projétil mantém direção própria após virada do Corvo")
    projectile.expire()
    check(not projectile.hitbox.active, "expirar projétil limpa área do pacote")
    bird_view.bind_actor(bird, "res://data/enemies/corvo_mapa.json")

func invalid_package_checks() -> void:
    var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FAKE + "manifesto_sprites.json"))
    var destination := "res://.godot/p40_runtime_f5/pacote_invalido/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
    for file in ["idle.png", "ataque.png", "sombra.png", "fx.png"]:
        DirAccess.copy_absolute(ProjectSettings.globalize_path(FAKE + file), ProjectSettings.globalize_path(destination + file))
    for key in ["hash", "path", "time", "anchor", "phase"]:
        var changed := base.duplicate(true)
        var q: Dictionary = changed.animacoes[0].quadros[0]
        match key:
            "hash": q.sha256 = "0".repeat(64)
            "path": q.arquivo = "../idle.png"
            "time": q.ms = -1
            "anchor": q.ancora = [10.5, 30]
            "phase": q.hitbox = {"fase": "WINDUP", "retangulo": [0, -20, 5, 10]}
        var output := FileAccess.open(destination + "manifesto_sprites.json", FileAccess.WRITE)
        output.store_string(JSON.stringify(changed))
        output.close()
        check(not PACKAGE.load_package(destination).valid, "manifesto rejeita " + key + " inválido sem ativar arte/dano")

func movement_camera_checks() -> void:
    settle()
    var old_scale: Vector2 = p.visual_root.form.body.scale
    p.set_meta("landing_offset_px", 2)
    p.visual_root.form.sync(0)
    check(p.visual_root.form.body.position.y == 2 and p.visual_root.form.body.scale == old_scale, "pouso desloca 2 px sem escalar arte")
    feel.set_group("movimento", false)
    check(int(p.get_meta("landing_offset_px")) == 0, "movimento OFF cancela deslocamento do pouso")
    feel.set_group("movimento", true)
    feel.pixels.emit_pixels(p.global_position + Vector2(0, 13), "poeira", 1)
    check(feel.pixels.emissions.poeira > 0, "poeira em pixels usa paleta e orçamento comum")
    room.camera.clear_impact()
    p.velocity.x = 160
    for _i in range(60): room.camera._process(DT)
    var px: Vector2 = room.camera.offset * room.camera.zoom
    check(px == px.round() and absf(px.x - 18) <= 1, "antecipação suave termina em 18 pixels inteiros")
    check(room.background_root.position == -px, "fundo acompanha câmera sem deslizar contra colisores")
    feel.set_group("camera", false)
    room.camera._process(DT)
    check(room.camera.offset == Vector2.ZERO and room.background_root.position == Vector2.ZERO, "câmera OFF restaura composição congelada")
    feel.set_group("camera", true)
    var ev := InputEventKey.new()
    ev.keycode = KEY_F3
    ev.pressed = true
    feel._input(ev)
    check(feel.debug_controls, "F3 habilita comandos debug G/H")
    ev.keycode = KEY_G
    var selected: int = feel.selected
    feel._input(ev)
    check(feel.selected == (selected + 1) % 4, "G cicla grupo selecionado")
    ev.keycode = KEY_H
    var group: String = feel.GROUPS[feel.selected]
    feel._input(ev)
    check(not feel.enabled(group), "H alterna grupo ao vivo")
    feel.set_all(true)
    feel.debug_controls = false

func run() -> void:
    feel = root.get_node("Sensacao")
    room = ROOM.instantiate()
    root.add_child(room)
    current_scene = room
    await frames(8)
    p = room.player
    freeze(p)
    for enemy in room.enemies: freeze(enemy)
    await control_checks()
    impact_checks()
    await presentation_checks()
    invalid_package_checks()
    movement_camera_checks()
    measurements.checks = checks
    measurements.failures = failures
    var file := FileAccess.open("res://codex/evidencias_integracao_p40_f5/MEDIDAS.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(measurements, "  "))
    print("FINAL: ", "PASSED" if failures == 0 else "FAILED", " · ", checks, " checks")
    quit(0 if failures == 0 else 1)
