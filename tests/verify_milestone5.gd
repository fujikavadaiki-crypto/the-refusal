extends SceneTree

var failed := false
var arena: Node2D
var bird: CharacterBody2D
var player: CharacterBody2D
var brain: CorvoBrain
var attack: CorvoAttack
var health: HealthComponent
var posture: PostureComponent
var player_health: HealthComponent
var player_posture: PostureComponent
var defense: PlayerDefense
var player_combat: PlayerCombat
var contacts: Array[HitContext] = []
var player_hits: Array[HitContext] = []
var fired_count := 0


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func press(action: StringName) -> void:
    Input.action_press(action)
    await wait_frames(2)
    Input.action_release(action)


func wait_for_descent(lead_ticks := 0) -> void:
    # Approved F2 decision: ACTIVE contact on descent, same target/AI. The
    # heavy's 250 ms preparation needs input two ticks before the apex boundary;
    # the engine consumes this input on the following tick. Light waits for descent.
    # Reavaliar após dano por quadro (this fixture still exercises the human fallback).
    for _tick in range(90):
        await physics_frame
        var lead_velocity: float = player.get_node("Locomotion").gravity * lead_ticks / 60.0
        if not player.is_on_floor() and player.velocity.y >= -lead_velocity:
            return
    check(false, "fixture chega à descida do pulo P40")


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func reset_player(position := Vector2(1070, 215)) -> void:
    player_combat.abort_attack()
    player_health.reset_health()
    player_posture.reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    defense.air_dash_available = true
    player.global_position = position
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    player.get_node("VisualRoot").modulate = Color.WHITE
    player_combat.set_facing(1)
    defense.set_facing(1)
    contacts.clear()
    player_hits.clear()
    await wait_frames(5)


func fixture(bird_position := Vector2(1100, 175), player_position := Vector2(1070, 215)) -> void:
    root.get_node("HitStop")._restore()
    bird.reset_enemy()
    await reset_player(player_position)
    bird.global_position = bird_position
    bird.velocity = Vector2.ZERO
    bird.flight.stop()
    brain.state = CorvoBrain.State.RUPTURE # Static fixture, no AI decision.
    attack.abort()
    await wait_frames(3)


func make_hit(damage: int, pressure: int) -> HitContext:
    var context := HitContext.new()
    context.attacker = player
    context.attacker_posture = player.get_node("Posture")
    context.attacker_stats = player.get_node("DefenseStats")
    context.target = bird
    context.attack_id = &"m5_contact_fixture"
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = damage
    context.posture_damage = pressure
    context.damage_type = &"physical"
    return context


func run_checks() -> void:
    arena = load("res://scenes/test/corvo_arena.tscn").instantiate()
    root.add_child(arena)
    bird = arena.get_node("Corvo")
    player = arena.get_node("TestRoom/Player")
    brain = bird.get_node("Brain")
    attack = bird.get_node("Attack")
    health = bird.get_node("Health")
    posture = bird.get_node("Posture")
    player_health = player.get_node("Health")
    player_posture = player.get_node("Posture")
    defense = player.get_node("Defense")
    player_combat = player.get_node("Combat")
    attack.hit_confirmed.connect(func(context: HitContext) -> void: contacts.append(context))
    attack.projectile_fired.connect(func(_projectile: CorvoProjectile) -> void: fired_count += 1)
    player_combat.hit_confirmed.connect(func(context: HitContext) -> void: player_hits.append(context))

    check(health.max_health == 65 and health.current_health == 65, "Corvo tem HP canônico 65")
    check(posture.max_posture == 20.0 and posture.current_posture == 20.0, "Corvo tem Postura canônica 20")
    check(attack.rasante.base_damage == 11 and attack.rasante.posture_damage == 7 and attack.rasante.parry_class == &"parryable", "Rasante canônico 11/7 e parryável")
    check(attack.cuspe.base_damage == 8 and attack.cuspe.parry_class != &"parryable" and attack.cuspe.tags.has("plague_pending_status"), "Cuspe 8 HP, sem Parry e com hook de Praga pendente")
    check(attack.cuspe.posture_damage == 5, "Postura do projétil centralizada como provisória")
    check(bird.get_node("Hurtbox") is Hurtbox2D and bird.get_node("DiveHitbox") is Hitbox2D, "componentes genéricos de contato reaproveitados")

    await reset_player(Vector2(600, 215))
    await wait_frames(100)
    check(brain.state == CorvoBrain.State.PATROL_AIR or brain.state == CorvoBrain.State.HOVER, "fora do alcance patrulha/paíra sem ler comandos")
    check(absf(bird.global_position.x - bird.spawn_position.x) <= brain.tuning.patrol_half_width + 12.0, "patrulha aérea curta")
    await reset_player(Vector2(1070, 215))
    var detected := false
    var airborne_movement := false
    for _i in range(150):
        await physics_frame
        detected = detected or brain.state in [CorvoBrain.State.ALERT, CorvoBrain.State.POSITIONING, CorvoBrain.State.PROJECTILE_WINDUP, CorvoBrain.State.DIVE_WINDUP]
        airborne_movement = airborne_movement or absf(bird.global_position.y - bird.spawn_position.y) > 3.0
    check(detected, "detecção por mundo real chega a ALERT/POSITIONING")
    check(airborne_movement and bird.global_position.y < 205.0, "voo controlado muda altura sem cair como humanoide")

    bird.reset_enemy()
    await reset_player()
    var saw_dive_windup := false
    var saw_dive_active := false
    var saw_dive_recovery := false
    var saw_projectile_windup := false
    var saw_projectile_recovery := false
    var locked_commitment := false
    var ai_bounds := true
    var max_same_state := 0
    var same_state := 0
    var previous_state := -1
    var move_sequence: Array[int] = []
    for i in range(10800): # Three simulated minutes at 60 physics frames/s.
        await physics_frame
        var state := brain.state
        if state == previous_state:
            same_state += 1
        else:
            max_same_state = maxi(max_same_state, same_state)
            same_state = 0
            previous_state = state
            if state == CorvoBrain.State.DIVE_WINDUP:
                move_sequence.append(CorvoAttack.Mode.DIVE)
            elif state == CorvoBrain.State.PROJECTILE_WINDUP:
                move_sequence.append(CorvoAttack.Mode.PROJECTILE)
        saw_dive_windup = saw_dive_windup or state == CorvoBrain.State.DIVE_WINDUP
        saw_dive_active = saw_dive_active or state == CorvoBrain.State.DIVE_ACTIVE
        saw_dive_recovery = saw_dive_recovery or state == CorvoBrain.State.DIVE_RECOVERY
        saw_projectile_windup = saw_projectile_windup or state == CorvoBrain.State.PROJECTILE_WINDUP
        saw_projectile_recovery = saw_projectile_recovery or state == CorvoBrain.State.PROJECTILE_RECOVERY
        if state == CorvoBrain.State.DIVE_ACTIVE and attack.target_locked != Vector2.ZERO:
            var before := attack.target_locked
            player.global_position.x += 6.0 if i % 120 == 0 else 0.0
            locked_commitment = locked_commitment or attack.target_locked == before
        if state in [CorvoBrain.State.HOVER, CorvoBrain.State.PATROL_AIR, CorvoBrain.State.ALERT, CorvoBrain.State.POSITIONING, CorvoBrain.State.PROJECTILE_WINDUP, CorvoBrain.State.PROJECTILE_ATTACK, CorvoBrain.State.PROJECTILE_RECOVERY]:
            ai_bounds = ai_bounds and bird.global_position.y >= brain.tuning.min_flight_y - 8.0 and bird.global_position.y <= 225.0
        if player_health.current_health <= 20:
            player_health.reset_health()
            player_posture.reset_posture()
    check(saw_dive_windup and saw_dive_active and saw_dive_recovery, "IA executa WINDUP/ACTIVE/RECOVERY do mergulho")
    check(saw_projectile_windup and saw_projectile_recovery and fired_count >= 2, "IA executa preparo/disparo/recuperação do projétil")
    check(locked_commitment, "alvo do mergulho fica travado antes do ACTIVE")
    check(ai_bounds, "altura de voo permanece na área útil da câmera")
    check(max_same_state < 500, "sem estado travado em três minutos de IA")
    check(contacts.size() > 0 and contacts.size() < 90, "cadência finita sem spam de contato")
    var repeated_choice := false
    for i in range(1, move_sequence.size()):
        repeated_choice = repeated_choice or move_sequence[i] == move_sequence[i - 1]
    check(repeated_choice and move_sequence.size() >= 5, "cadência contextual não alterna em padrão fixo")
    check(player.get_node("Camera2D").get_screen_center_position().y >= 0.0, "câmera continua seguindo o jogador, sem perseguir o Corvo")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    await press(&"jump")
    await wait_for_descent()
    await press(&"attack_light")
    await wait_frames(22)
    check(health.current_health == 47 and roundi(posture.current_posture) == 13, "Air Light real causa 18 HP/7 Postura ao Corvo")
    check(player_hits.size() == 1, "Air Light produz um contato por ação")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    await press(&"jump")
    await wait_for_descent(2)
    await press(&"attack_heavy")
    await wait_frames(35)
    check(health.current_health == 33 and posture.is_ruptured(), "Air Heavy real causa 32 HP/28 Postura e rompe o Corvo")
    check(brain.state == CorvoBrain.State.RUPTURE and bird.global_position.y > 175.0, "Ruptura aérea derruba o corpo")
    root.get_node("HitStop")._restore()
    await wait_frames(170)
    check(not posture.is_ruptured() and roundi(posture.current_posture) >= 10 and brain.state != CorvoBrain.State.RUPTURE, "Ruptura recupera ~50% e decola gradualmente")

    await fixture(Vector2(1100, 205), Vector2(1070, 215))
    await press(&"attack_light")
    await wait_frames(25)
    check(health.current_health < 65, "Light terrestre continua acertando Corvo baixo")

    await fixture(Vector2(1100, 205), Vector2(1070, 215))
    await press(&"attack_heavy")
    await wait_frames(40)
    check(health.current_health < 65, "Heavy terrestre continua acertando Corvo baixo")

    await fixture()
    var projectile := attack.projectile_scene.instantiate() as CorvoProjectile
    arena.add_child(projectile)
    projectile.launch(bird, player.global_position + Vector2(35, -4), player.global_position, brain.tuning.projectile_speed, 1.0)
    await wait_frames(30)
    check(player_health.current_health == 92 and roundi(player_posture.current_posture) == 95, "projétil real causa 8 HP/5 Postura uma vez")
    check(not is_instance_valid(projectile), "projétil some depois do contato")

    await fixture()
    projectile = attack.projectile_scene.instantiate() as CorvoProjectile
    arena.add_child(projectile)
    projectile.launch(bird, player.global_position + Vector2(80, -4), player.global_position + Vector2(80, -4), 0.0, 0.12)
    await wait_frames(12)
    check(not is_instance_valid(projectile), "projétil sem contato expira")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    attack.begin_dive()
    for _i in range(70):
        await physics_frame
        if brain.state == CorvoBrain.State.DIVE_ACTIVE:
            break
    await wait_frames(4)
    await press(&"parry")
    await wait_frames(18)
    var parried := false
    for context in contacts:
        parried = parried or context.outcome == HitContext.Outcome.PARRIED and context.parry_posture_return == 20
    check(parried and posture.is_ruptured() and player_health.current_health == 100, "Parry real do Rasante retorna 20 Postura e derruba o Corvo")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    attack.begin_dive()
    for _i in range(70):
        await physics_frame
        if brain.state == CorvoBrain.State.DIVE_ACTIVE:
            break
    await wait_frames(5)
    defense.mode = PlayerDefense.Mode.DODGING
    defense.elapsed = 0.1
    defense.dodge_direction = 1
    await wait_frames(14)
    var dodged_dive := false
    for context in contacts:
        dodged_dive = dodged_dive or context.outcome == HitContext.Outcome.DODGED
    check(dodged_dive and player_health.current_health == 100 and player_posture.current_posture == 100.0, "i-frame do Dodge evita contato real do Rasante")

    await fixture()
    await press(&"dodge")
    await wait_frames(4)
    check(defense.is_iframe_active(), "Dodge abre i-frame antes de contato de projétil")
    var avoided_contacts: Array[HitContext] = []
    projectile = attack.projectile_scene.instantiate() as CorvoProjectile
    arena.add_child(projectile)
    projectile.contact.connect(func(context: HitContext) -> void: avoided_contacts.append(context))
    projectile.launch(bird, player.global_position + Vector2(16, -4), player.global_position, brain.tuning.projectile_speed, 1.0)
    await wait_frames(10)
    check(avoided_contacts.size() == 1 and avoided_contacts[0].outcome == HitContext.Outcome.DODGED and player_health.current_health == 100 and player_posture.current_posture == 100.0, "Dodge evita HP e Postura do projétil real")

    await fixture(Vector2(1135, 175), Vector2(1070, 172))
    brain.state = CorvoBrain.State.DIVE_RECOVERY
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_light")
    await wait_frames(25)
    check(health.current_health == 47 and player_hits.size() == 1, "Air Dash → Light alcança Corvo em recuperação")

    await fixture(Vector2(1135, 175), Vector2(1070, 145))
    brain.state = CorvoBrain.State.DIVE_RECOVERY
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_heavy")
    await wait_frames(35)
    check(health.current_health == 33 and posture.is_ruptured(), "Air Dash → Heavy abre Ruptura do Corvo em recuperação")

    await fixture(Vector2(1140, 205), Vector2(1070, 215))
    await press(&"dodge")
    await wait_frames(6)
    await press(&"attack_light")
    await wait_frames(25)
    check(health.current_health < 65, "Ground Dash Light continua acertando Corvo baixo")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    attack.begin_dive()
    for _i in range(50):
        await physics_frame
        if attack.target_locked != Vector2.ZERO:
            break
    var locked_x := attack.target_locked.x
    await press(&"jump")
    Input.action_press("move_left")
    await press(&"dodge")
    Input.action_release("move_left")
    await wait_frames(35)
    check(locked_x > 0.0 and player.global_position.x < locked_x - 35.0 and player_health.current_health == 100, "pulo → Air Dash escapa da trajetória já comprometida")

    await fixture()
    defense.mode = PlayerDefense.Mode.PARRYING
    defense.elapsed = 0.0
    projectile = attack.projectile_scene.instantiate() as CorvoProjectile
    arena.add_child(projectile)
    projectile.launch(bird, player.global_position + Vector2(16, -4), player.global_position, brain.tuning.projectile_speed, 1.0)
    await wait_frames(10)
    check(player_health.current_health == 92 and player_posture.current_posture == 95.0, "Parry não bloqueia Cuspe não parryável")

    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    attack.begin_projectile()
    var outgoing: CorvoProjectile
    for _i in range(80):
        await physics_frame
        if not attack.active_projectiles.is_empty():
            outgoing = attack.active_projectiles[0]
            break
    check(is_instance_valid(outgoing), "disparo cria objeto independente")
    health.receive_hit(make_hit(100, 0))
    await wait_frames(35)
    check(brain.state == CorvoBrain.State.DEATH and player_health.current_health == 92, "projétil lançado prossegue e atinge após morte do Corvo")

    await fixture(Vector2(1200, 150), Vector2(1070, 215))
    attack.begin_projectile()
    for _i in range(80):
        await physics_frame
        if not attack.active_projectiles.is_empty():
            break
    var extra_projectile := attack.projectile_scene.instantiate() as CorvoProjectile
    arena.add_child(extra_projectile)
    extra_projectile.launch(bird, Vector2(1500, 100), Vector2(1500, 100), 0.0, 10.0)
    attack.active_projectiles.append(extra_projectile)
    check(attack.active_projectiles.size() == 2, "reset encontra dois projéteis ativos")
    bird.reset_enemy()
    await wait_frames(2)
    check(attack.active_projectiles.is_empty() and not is_instance_valid(extra_projectile), "reset remove todos os projéteis ativos")

    await fixture()
    var initial_y := bird.global_position.y
    var heavy := make_hit(32, 28)
    health.receive_hit(heavy)
    check(heavy.outcome == HitContext.Outcome.DAMAGED and posture.is_ruptured(), "dano compartilhado rompe 20 Postura sem alterar valor canônico")
    await wait_frames(25)
    check(bird.global_position.y > initial_y + 20.0 and bird.is_on_floor(), "Corvo em Ruptura cai e colide com o piso")
    var punish := make_hit(10, 0)
    health.receive_hit(punish)
    check(punish.actual_damage == 12, "alvo rompido recebe vulnerabilidade geral de +20%")
    await wait_frames(140)
    check(not posture.is_ruptured() and roundi(posture.current_posture) >= 10, "recuperação da Ruptura restaura cerca de metade")

    await fixture()
    attack.begin_projectile()
    var fired_before := fired_count
    var lethal := make_hit(100, 0)
    health.receive_hit(lethal)
    await wait_frames(50)
    check(brain.state == CorvoBrain.State.DEATH and fired_count == fired_before and attack.mode == CorvoAttack.Mode.NONE, "morte no WINDUP cancela disparo")
    check(bird.global_position.y > 175.0, "morte aérea cai em vez de flutuar")

    bird.reset_enemy()
    check(bird.global_position == bird.spawn_position and brain.state == CorvoBrain.State.HOVER and attack.active_projectiles.is_empty(), "reset restaura posição/estado/cooldowns/projéteis")
    await reset_player()
    check(health.current_health == 65 and roundi(posture.current_posture) == 20 and not posture.is_ruptured(), "reset restaura HP/Postura/Ruptura")

    var brain_source := FileAccess.get_file_as_string("res://scripts/enemies/corvo_brain.gd")
    check(not brain_source.contains("Input."), "IA não consulta comandos do jogador")
    print("MILESTONE 5: ", "FAIL" if failed else "PASS")
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    arena.queue_free()
    await process_frame
    var audio_cleanup_until := Time.get_ticks_msec() + 400
    while Time.get_ticks_msec() < audio_cleanup_until:
        await process_frame
    quit(1 if failed else 0)
