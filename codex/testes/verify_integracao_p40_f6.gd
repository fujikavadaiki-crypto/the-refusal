extends SceneTree
const ROOM := preload("res://scenes/biomes/cemiterio/sala_cemiterio.tscn")
const PACKAGE := preload("res://scripts/enemies/presentation/enemy_package.gd")
const OUT := "res://codex/evidencias_integracao_p40_f6/"
const DT := 1.0 / 60.0
var baseline := false
var checks := 0
var failures := 0
var room: Node2D
var p: CharacterBody2D
var enemy: CharacterBody2D
var view: Node2D
var measurements := {"contacts": [], "hurt_points": [], "attacks": []}
func _initialize() -> void:
    baseline = OS.get_cmdline_user_args().has("--baseline")
    run.call_deferred()
func frames(n := 1) -> void:
    for _i in range(n): await physics_frame
func freeze(n: Node) -> void:
    n.set_physics_process(false)
    for c in n.get_children(): freeze(c)
func check(ok: bool, message: String) -> void:
    checks += 1
    if ok: print("PASS: ", message)
    else:
        failures += 1
        printerr("FAIL: ", message)
func reset_pair(dx_px: float, raised_px := 0.0, facing := 1) -> void:
    enemy.reset_enemy()
    p.combat.abort_attack()
    p.clear_action_buffers()
    p.get_node("Health").reset_health()
    p.get_node("Posture").reset_posture()
    p.defense.mode = PlayerDefense.Mode.READY
    p.get_node("SensacaoAlvo").reset()
    enemy.get_node("SensacaoAlvo").reset()
    enemy.global_position = room.ground_at(room.to_global(Vector2(250/.9,0)).x) - Vector2(0,15.55 + raised_px/.9)
    p.global_position = enemy.global_position + Vector2(dx_px/.9*facing, 2.5 + raised_px/.9)
    p.velocity = Vector2.ZERO
    enemy.velocity = Vector2.ZERO
    enemy.set_facing(facing)
    root.get_node("HitStop")._restore()
func trial(action: String, dx_px: float, raised_px: float, facing := 1) -> Dictionary:
    reset_pair(dx_px,raised_px,facing)
    await frames(2)
    var data: AttackData = enemy.attack.get(action)
    enemy.attack.start(data)
    enemy.attack.facing_locked = true # Static geometry trial: do not turn toward the rear probe.
    for _i in range(ceili((data.windup_seconds+data.active_seconds+.02)/DT)):
        enemy.attack.tick(DT,p,5)
        enemy.attack.resolve_frame_contact()
        root.get_node("HitStop")._restore()
        await frames()
    var loss: int = p.get_node("Health").max_health - p.get_node("Health").current_health
    enemy.attack.abort()
    return {"attack":action,"distance_px":dx_px,"distance_m":dx_px/32,"raised_px":raised_px,"facing":facing,"hit":loss>0,"damage":loss}
func contacts() -> void:
    for action in ["corte","estocada","corte_duplo_1","corte_duplo_2","investida","penitencia"]:
        for raised in [0.0,24.0,48.0]:
            for dx in [8.0,18.0,30.0,40.0,50.0,65.0]:
                measurements.contacts.append(await trial(action,dx,raised))
    reset_pair(100)
    await frames(2)
    var hurt: CollisionShape2D = enemy.hurt_shape
    measurements.hurt = {"radius_world":hurt.shape.radius,"height_world":hurt.shape.height,"center_y_world":hurt.position.y,"feet_y_world":15.5,"body_height_world":enemy.body_shape.shape.height}
    for y in [-8.0,-24.0,-30.0,-36.0,-43.0,-47.0]:
        var q := PhysicsPointQueryParameters2D.new()
        q.position = enemy.global_position + Vector2(0,15.5+y/.9)
        q.collision_mask = 4
        q.collide_with_areas = true
        q.collide_with_bodies = false
        var hits := enemy.get_world_2d().direct_space_state.intersect_point(q)
        var found := false
        for h in hits: found = found or h.collider == enemy.get_node("Hurtbox")
        measurements.hurt_points.append({"y_px":y,"hit":found})
func package_checks() -> void:
    var pack := PACKAGE.load_package("res://assets/enemies/peregrino_v1/")
    check(pack.valid, "pacote aprovado carrega sem erro: " + str(pack.errors))
    if not pack.valid: return
    check(pack.anims.size() == 12, "12 animações reais do Peregrino")
    check(absf(enemy.hurt_shape.shape.radius * .9 - 7) < .001 and absf(enemy.hurt_shape.shape.height * .9 - 44) < .001, "hurtbox sugerida raio 7 / altura 44 px pela escala fixa")
    check(absf(enemy.hurt_shape.position.y + enemy.hurt_shape.shape.height*.5 - 15.5) < .001, "hurtbox conserva pés antigos")
    check(enemy.body_shape.shape.height == 31 and enemy.body_shape.shape.radius == 7, "colisor de locomoção e IA preservados")
    for state in ["IDLE","PATROL","ALERT","CHASE","HURT","RUPTURE","DEATH"]:
        enemy.brain.state = PeregrinoBrain.State[state]
        enemy.attack.abort()
        view._process(0)
        check(view.current_anim == view.mapping.estados[state], "estado " + state + " usa animação própria")
    enemy.reset_enemy()
    enemy.attack.abort()
    view._process(0)
    view.idle_ms = 1200
    enemy.brain.state = PeregrinoBrain.State.RUPTURE
    view.last_state = enemy.brain.state
    view._process(0)
    check(view.frame_index >= 3, "ruptura não repete a entrada: loop começa no quadro 3")
    enemy.brain.state = PeregrinoBrain.State.DEATH
    view.last_state = enemy.brain.state
    view.idle_ms = 2000
    view._process(0)
    check(view.frame_index == 7 and is_zero_approx(view.body.rotation) and view.body.scale == Vector2.ONE, "morte segura quadro caído sem rotação/escala legadas")
    enemy.reset_enemy()
    for action in ["corte","estocada","corte_duplo_1","corte_duplo_2","investida","penitencia"]:
        var data: AttackData = enemy.attack.get(action)
        var anim_id: String = view.mapping.ataques[String(data.attack_id)]
        var anim: Dictionary = pack.anims[anim_id]
        var authored: Dictionary = anim.attack_specs.get(String(data.attack_id), anim.attack)
        var rec := {"attack":String(data.attack_id),"anim":anim_id,"frames":[],"windup_ms":data.windup_seconds*1000,"active_ms":data.active_seconds*1000,"recovery_ms":data.recovery_seconds*1000}
        check(absf(float(authored.tres.windup_ms)-data.windup_seconds*1000)<.01 and absf(float(authored.tres.active_ms)-data.active_seconds*1000)<.01 and absf(float(authored.tres.recovery_ms)-data.recovery_seconds*1000)<.01, action + " mantém tempos do recurso original")
        for factor in [.01,.75]:
            var sample: Dictionary = view.attack_sample(data,data.windup_seconds+data.active_seconds*factor)
            rec.frames.append(sample.index)
            check(sample.phase == "ACTIVE" and not sample.frame.hitbox.is_empty(), action + " seleciona área do quadro ATIVO correspondente")
            var front := true
            for part in sample.frame.hitbox.parts:
                for point in part: front = front and point.x >= -.001 and point.y <= .001
            check(front, action + " área recortada à frente e acima do chão")
        if action.begins_with("corte_duplo"):
            check(rec.frames == ([3,4] if action.ends_with("1") else [8,9]), action + " seleciona apenas a sua parte do duplo")
        enemy.attack.start(data)
        enemy.attack.elapsed = data.windup_seconds*.7
        view._process(0)
        check(view.warning_class == ("non_parryable" if action == "penitencia" else "parryable"), action + " aviso segue classe real de parry")
        check(view.fx_root.get_children().any(func(s): return s.get_meta("warning",false)), action + " aviso do pacote visível na preparação")
        enemy.attack.elapsed = data.windup_seconds + data.active_seconds*.75
        enemy.attack._arm()
        view._process(0)
        check(enemy.attack.hitbox.frame_override_active and not enemy.get_node("AttackPivot").visible, action + " área do pacote substitui pivô e arma legada não aparece")
        check(view.fx_root.get_children().all(func(s): return not s.get_meta("warning",false)), action + " aviso desaparece em ACTIVE")
        enemy.attack.abort()
        check(not enemy.attack.hitbox.frame_override_active, action + " interrupção limpa área")
        measurements.attacks.append(rec)
        var right := await trial(action,30,0,1)
        var left := await trial(action,30,0,-1)
        check(right.hit == left.hit and right.damage == left.damage, action + " espelho conserva contato/dano")
    for action in ["corte","estocada","corte_duplo_1","corte_duplo_2","investida","penitencia"]:
        var behind := await trial(action,-30,0,1)
        check(not behind.hit, action + " não atinge jogador atrás do Peregrino")
    reset_pair(100)
    enemy.attack.abort()
    enemy.brain.state = PeregrinoBrain.State.IDLE
    view._process(0)
    var canvas: Transform2D = room.get_viewport().get_canvas_transform()
    var feet: Vector2 = canvas * (enemy.global_position + view.feet_local)
    check((canvas * view.global_position).distance_to(feet.round()) < .001, "pacote real: âncora nos pés em pixel inteiro")
    var screen_transform: Transform2D = canvas * view.global_transform
    check(screen_transform.x.is_equal_approx(Vector2.RIGHT) and screen_transform.y.is_equal_approx(Vector2.DOWN), "pacote real: apresentação ×1 NEAREST")
    enemy.set_facing(-1)
    view._process(0)
    check(view.body.flip_h and (canvas*view.global_position).distance_to(feet.round())<.001, "pacote real: espelho único sem deslocar pés")
    check(view.shadow.visible, "pacote real: uma sombra separada no chão")
    for anim: Dictionary in pack.anims.values():
        for q: Dictionary in anim.frames:
            check(q.efeitos.all(func(fx): return fx.camada in ["atras_do_corpo","frente_do_corpo"]), "FX real: camada de fundo/frente válida")
    # Real double: independent action UID, no duplicate damage within either half.
    reset_pair(30)
    await frames(2)
    enemy.attack.start(enemy.attack.corte_duplo_1,enemy.attack.corte_duplo_2)
    var ids := {}
    var losses := []
    var last_hp: int = p.get_node("Health").current_health
    for _i in range(90):
        enemy.attack.tick(DT,p,5)
        enemy.attack.resolve_frame_contact()
        if enemy.attack.current_attack != null: ids[enemy.attack.action_uid] = true
        var hp: int = p.get_node("Health").current_health
        if hp != last_hp: losses.append(last_hp-hp)
        last_hp = hp
        root.get_node("HitStop")._restore()
        await frames()
    check(ids.size() == 2 and losses.size() <= 2, "duplo conserva dois UIDs e no máximo um acerto por parte")
    measurements.double = {"uids":ids.size(),"damage_events":losses}
    enemy.attack.abort()
    enemy.reset_enemy()
    # Trigger production health/posture callbacks (no source tuning changed).
    var c := HitContext.new()
    c.attacker = p
    c.base_damage = 1
    c.posture_damage = 40
    enemy.health.receive_hit(c)
    view._process(0)
    check(enemy.brain.state == PeregrinoBrain.State.RUPTURE and view.current_anim == "ruptura", "ruptura real seleciona ajoelhado")
    c = HitContext.new()
    c.attacker = p
    c.base_damage = 1000
    enemy.health.receive_hit(c)
    await frames(2)
    view._process(0)
    check(enemy.brain.state == PeregrinoBrain.State.DEATH and view.current_anim == "morte" and enemy.hurt_shape.disabled, "morte real anima e desliga hurtbox")
    enemy.reset_enemy()
    await frames(2)
    view._process(0)
    check(not enemy.hurt_shape.disabled and view.current_anim == "idle", "R restaura vida, hurtbox e apresentação")
    view.bind_actor(enemy,"res://data/enemies/mapa_inexistente_fixture.json")
    view._process(0)
    check(not view.package.valid and not view.active and enemy.visual.visible and enemy.get_node("AttackPivot").visible, "mapeamento ausente restaura apresentação/arma antigas")
    check(enemy.hurt_shape.shape.height == 31 and enemy.hurt_shape.position == Vector2.ZERO, "fallback restaura hurtbox anterior sem deixar pacote parcialmente equipado")
    view.bind_actor(enemy,"res://data/enemies/peregrino_mapa.json")
    view._process(0)
    check(view.active and absf(enemy.hurt_shape.shape.height*.9-44)<.001, "reequipar pacote válido restaura arte e hurtbox sugerida")
    for e in room.enemies.slice(1):
        var v: Node = e.get_node("ApresentadorPacote")
        v._process(0)
        check(not v.package.valid and not v.active, String(e.name) + " mantém arte provisória; nenhum pacote humanoide usado")
    room.queue_free()
    await frames(2)
    room = load("res://scenes/biomes/forest/bosque_integracao_p40.tscn").instantiate()
    root.add_child(room)
    current_scene = room
    await frames(5)
    var equipped := 0
    var found: Array[Node] = room.find_children("Peregrino*", "CharacterBody2D", true, false)
    for e in found:
        var v: Node = e.get_node("ApresentadorPacote")
        if v.package.valid and absf(e.get_node("Hurtbox/CollisionShape2D").shape.height*.9-44)<.001: equipped += 1
    check(equipped > 0, "Bosque F9 também equipa pacote e hurtbox reais")
    measurements.bosque_peregrinos = equipped
func run() -> void:
    root.get_node("Sensacao").set_group("impacto",false)
    room = ROOM.instantiate()
    root.add_child(room)
    current_scene = room
    await frames(8)
    p = room.player
    enemy = room.enemies[0]
    view = enemy.get_node("ApresentadorPacote")
    freeze(p)
    for e in room.enemies: freeze(e)
    room.enemies[1].global_position = Vector2(10000,-10000)
    room.enemies[2].global_position = Vector2(10000,-10000)
    await contacts()
    if not baseline: await package_checks()
    measurements.checks = checks
    measurements.failures = failures
    var f := FileAccess.open(OUT + ("MEDIDAS_antes.json" if baseline else "MEDIDAS_depois.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(measurements,"  "))
    print("FINAL: ",checks," checks / ",failures," failures")
    quit(0 if failures == 0 else 1)
