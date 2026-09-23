extends SceneTree

var failed := false
var arena: Node2D
var root_enemy: CharacterBody2D
var player: CharacterBody2D
var brain: RaizFamintaBrain
var attack: RaizFamintaAttack
var health: HealthComponent
var posture: PostureComponent
var player_health: HealthComponent
var player_posture: PostureComponent
var defense: PlayerDefense
var combat: PlayerCombat
var contacts: Array[HitContext] = []
var player_hits: Array[HitContext] = []


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func press(action: StringName) -> void:
    Input.action_press(action)
    await wait_frames(2)
    Input.action_release(action)


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func reset_player(position := Vector2(1070, 215)) -> void:
    combat.abort_attack()
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
    combat.set_facing(1)
    defense.set_facing(1)
    contacts.clear()
    player_hits.clear()
    await wait_frames(5)


func fixture(enemy_position := Vector2(1100, 219), player_position := Vector2(1070, 215)) -> void:
    root.get_node("HitStop")._restore()
    root_enemy.reset_enemy()
    await reset_player(player_position)
    root_enemy.global_position = enemy_position
    root_enemy.velocity = Vector2.ZERO
    brain.state = RaizFamintaBrain.State.RUPTURE # Static attack target, no AI decisions.
    attack.abort()
    root_enemy._apply_state(brain.state)
    await wait_frames(3)


func make_hit(damage: int, pressure: int, tags := PackedStringArray(), damage_type := &"physical") -> HitContext:
    var context := HitContext.new()
    context.attacker = player
    context.attacker_posture = player.get_node("Posture")
    context.attacker_stats = player.get_node("DefenseStats")
    context.target = root_enemy
    context.attack_id = &"m6_fixture"
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = damage
    context.posture_damage = pressure
    context.damage_type = damage_type
    context.tags = tags
    return context


func run_checks() -> void:
    arena = load("res://scenes/test/raiz_faminta_arena.tscn").instantiate()
    root.add_child(arena)
    root_enemy = arena.get_node("RaizFaminta")
    player = arena.get_node("TestRoom/Player")
    brain = root_enemy.get_node("Brain")
    attack = root_enemy.get_node("Attack")
    health = root_enemy.get_node("Health")
    posture = root_enemy.get_node("Posture")
    player_health = player.get_node("Health")
    player_posture = player.get_node("Posture")
    defense = player.get_node("Defense")
    combat = player.get_node("Combat")
    attack.hit_confirmed.connect(func(context: HitContext) -> void: contacts.append(context))
    player.get_node("AttackPivot/Hitbox").hit_confirmed.connect(func(context: HitContext) -> void: player_hits.append(context))
    await wait_frames(3)
    check(health.current_health == 85 and posture.current_posture == 35.0, "Raiz usa 85 HP e 35 Postura canônicos")
    check(brain.state in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DETECT] and root_enemy.get_node("BurrowMark").visible, "estado enterrado mantém sinal visível")
    check(not root_enemy.get_node("VisualRoot").visible and not attack.hitbox.active, "enterrada não ataca instantaneamente")
    check(attack.garra_subterranea.base_damage == 14 and attack.garra_subterranea.posture_damage == 10 and attack.garra_subterranea.parry_class == &"non_parryable", "Garra Subterrânea canônica 14/10 não aparável")
    check(attack.mordida.base_damage == 11 and attack.mordida.posture_damage == 8 and attack.mordida.parry_class == &"non_parryable", "Mordida 11/8 canônicos e classe não aparável provisória")

    var seen: Dictionary = {}
    var locked_x := INF
    var target_moved := false
    var commitment_stable := true
    var max_same := 0
    var same := 0
    var last := -1
    for i in range(10800): # Three simulated minutes at 60 physics frames/s.
        await physics_frame
        var state := brain.state
        seen[state] = true
        if state == last:
            same += 1
        else:
            max_same = maxi(max_same, same)
            same = 0
            last = state
        if state == RaizFamintaBrain.State.EMERGE_WINDUP and is_inf(locked_x):
            locked_x = root_enemy.global_position.x
            target_moved = true
            player.global_position.x -= 45.0
        if state == RaizFamintaBrain.State.EMERGE_WINDUP and target_moved:
            commitment_stable = commitment_stable and is_equal_approx(root_enemy.global_position.x, locked_x)
        if player_health.current_health <= 30:
            player_health.reset_health()
            player_posture.reset_posture()
            player.global_position = Vector2(1090, 215)
            player.velocity = Vector2.ZERO
    for state in [RaizFamintaBrain.State.DETECT, RaizFamintaBrain.State.BURROW_MOVE, RaizFamintaBrain.State.EMERGE_WINDUP, RaizFamintaBrain.State.EMERGE_ATTACK, RaizFamintaBrain.State.EMERGE_RECOVERY, RaizFamintaBrain.State.GROUND_CHASE, RaizFamintaBrain.State.BITE_WINDUP, RaizFamintaBrain.State.BITE_ACTIVE, RaizFamintaBrain.State.BITE_RECOVERY]:
        check(seen.has(state), "IA visita %s" % RaizFamintaBrain.State.keys()[state])
    check(target_moved and locked_x > 0.0, "emboscada anuncia posição antes do ACTIVE")
    check(commitment_stable, "ponto do surgimento não segue o jogador durante o Windup")
    check(max_same < 600, "IA não trava em estado por três minutos")
    check(contacts.size() > 1 and contacts.size() < 150, "cadência de ataques finita, sem spam de contato")
    var unique: Dictionary = {}
    for context in contacts:
        unique[context.action_uid] = true
    check(unique.size() == contacts.size(), "um contato por ação ofensiva")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_emerge()
    await wait_frames(2)
    player.global_position.x = root_enemy.global_position.x - 10.0
    await wait_frames(8)
    check(brain.state == RaizFamintaBrain.State.EMERGE_WINDUP and attack.emerge_telegraph.visible and player_health.current_health == 100, "surgimento tem windup legível sem dano antecipado")
    await wait_frames(55)
    check(contacts.size() == 1 and player_health.current_health == 86 and player_posture.current_posture == 90.0, "Garra causa 14 HP/10 Postura uma vez")
    root.get_node("HitStop")._restore()
    await wait_frames(48)
    check(brain.state not in [RaizFamintaBrain.State.EMERGE_WINDUP, RaizFamintaBrain.State.EMERGE_ATTACK, RaizFamintaBrain.State.EMERGE_RECOVERY] and attack.mode != RaizFamintaAttack.Mode.EMERGE, "surgimento termina em recuperação")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_bite()
    await wait_frames(8)
    check(brain.state == RaizFamintaBrain.State.BITE_WINDUP and attack.bite_telegraph.visible and player_health.current_health == 100, "mordida avisa antes de atingir")
    await wait_frames(16)
    await wait_frames(29)
    check(contacts.size() == 1 and player_health.current_health == 89 and player_posture.current_posture == 92.0, "Mordida curta causa 11 HP/8 Postura uma vez")
    root.get_node("HitStop")._restore()
    await wait_frames(35)
    check(brain.state in [RaizFamintaBrain.State.GROUND_CHASE, RaizFamintaBrain.State.BITE_RECOVERY], "mordida entra em recuperação")

    await fixture(Vector2(1100, 219), Vector2(1070, 215))
    await press(&"attack_heavy")
    await wait_frames(40)
    check(health.current_health == 50 and roundi(posture.current_posture) == 4 and not posture.is_ruptured(), "Heavy terrestre real causa 35 HP e ~31 Postura, sem romper sozinho")
    check(player_hits.size() == 1, "Heavy terrestre acerta uma vez")

    await fixture(Vector2(1100, 219), Vector2(1070, 215))
    await press(&"attack_light")
    for _i in range(90):
        root.get_node("HitStop")._restore()
        if combat.current_light_stage == 1 and combat.elapsed >= combat.light_1.combo_queue_start_seconds:
            break
        await physics_frame
    await press(&"attack_light")
    for _i in range(90):
        root.get_node("HitStop")._restore()
        if combat.current_light_stage == 2 and combat.elapsed >= combat.light_2.combo_queue_start_seconds:
            break
        await physics_frame
    await press(&"attack_light")
    root.get_node("HitStop")._restore()
    await wait_frames(75)
    check(health.current_health == 15 and roundi(posture.current_posture) == 4 and player_hits.size() == 3, "combo Light real acerta a silhueta baixa três vezes: 70 HP/31 Postura")

    await fixture(Vector2(1100, 219), Vector2(1070, 215))
    player.global_position.y = 190.0
    player.velocity.y = 180.0
    await press(&"attack_light")
    await wait_frames(22)
    check(health.current_health == 67 and roundi(posture.current_posture) == 28, "Air Light real causa 18 HP/7 Postura na Raiz")

    await fixture(Vector2(1100, 219), Vector2(1070, 215))
    player.global_position.y = 170.0
    player.velocity.y = 150.0
    await press(&"attack_heavy")
    await wait_frames(35)
    check(health.current_health == 53 and roundi(posture.current_posture) == 7 and not posture.is_ruptured(), "Air Heavy real causa 32 HP/28 Postura sem romper sozinho")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_emerge()
    await wait_frames(2)
    player.global_position.x = root_enemy.global_position.x - 10.0
    await wait_frames(36)
    defense.mode = PlayerDefense.Mode.DODGING
    defense.elapsed = 0.10
    defense.dodge_direction = 1
    await wait_frames(15)
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DODGED and player_health.current_health == 100, "i-frame evita Garra real")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_bite()
    await wait_frames(11)
    defense.mode = PlayerDefense.Mode.DODGING
    defense.elapsed = 0.10
    defense.dodge_direction = 1
    await wait_frames(14)
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DODGED and player_health.current_health == 100, "i-frame evita Mordida real")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_emerge()
    await wait_frames(2)
    player.global_position.x = root_enemy.global_position.x - 10.0
    await wait_frames(34)
    defense.mode = PlayerDefense.Mode.PARRYING
    defense.elapsed = 0.0
    await wait_frames(15)
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 86, "Parry não bloqueia Garra não aparável")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_bite()
    await wait_frames(11)
    defense.mode = PlayerDefense.Mode.PARRYING
    defense.elapsed = 0.0
    await wait_frames(14)
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DAMAGED and player_health.current_health == 89, "Parry não bloqueia Mordida não aparável")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_emerge()
    await wait_frames(2)
    player.global_position.x = root_enemy.global_position.x - 10.0
    var emergence_x := root_enemy.global_position.x
    await press(&"jump")
    Input.action_press("move_left")
    await press(&"dodge")
    Input.action_release("move_left")
    check(defense.mode == PlayerDefense.Mode.AIR_DASH and not defense.air_dash_available, "salto e Air Dash usam mobilidade existente")
    await wait_frames(75)
    check(player.global_position.x < emergence_x - 35.0 and player_health.current_health == 100, "Air Dash escapa da emboscada comprometida")

    await fixture(Vector2(1200, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    root_enemy._apply_state(brain.state)
    var chase_x := root_enemy.global_position.x
    await wait_frames(45)
    check(root_enemy.global_position.x < chase_x - 15.0 and absf(root_enemy.global_position.y - 219.0) < 3.0, "perseguição rasteja em direção ao jogador sem sair do chão")

    await fixture(Vector2(1300, 219), Vector2(1070, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    health.receive_hit(make_hit(5, 2))
    await wait_frames(3)
    var hurt_elapsed := brain.elapsed
    health.receive_hit(make_hit(5, 2))
    check(brain.state == RaizFamintaBrain.State.HURT and brain.elapsed >= hurt_elapsed, "Light repetido não reinicia Hurt indefinidamente")
    await wait_frames(12)
    check(brain.state != RaizFamintaBrain.State.HURT, "Hurt comum termina sem loop de stun")

    await fixture(Vector2(1100, 219), Vector2(1090, 215))
    brain.state = RaizFamintaBrain.State.GROUND_CHASE
    attack.begin_bite()
    health.receive_hit(make_hit(85, 35))
    await wait_frames(2)
    check(brain.state == RaizFamintaBrain.State.DEATH and attack.mode == RaizFamintaAttack.Mode.NONE and not attack.hitbox.active, "morte durante Windup cancela ataque e desliga hitbox")

    await fixture()
    var pressure := make_hit(0, 35)
    health.receive_hit(pressure)
    check(posture.is_ruptured() and brain.state == RaizFamintaBrain.State.RUPTURE and not attack.hitbox.active, "quebra de Postura interrompe ataque e expõe Ruptura")
    var punish := make_hit(10, 0)
    health.receive_hit(punish)
    check(punish.actual_damage == 12, "Ruptura concede +20% de dano")
    await wait_frames(190)
    check(not posture.is_ruptured() and brain.state != RaizFamintaBrain.State.RUPTURE and roundi(posture.current_posture) >= 17, "Raiz recupera da Ruptura de ~3 s")

    await fixture()
    var magic := make_hit(20, 0, PackedStringArray(), &"magical")
    health.receive_hit(magic)
    check(magic.actual_damage == 23, "vulnerabilidade mágica canônica +15% aplica via resolver compartilhado")

    root_enemy.reset_enemy()
    root_enemy.global_position = Vector2(1300, 219)
    var buried_break := make_hit(0, 35)
    health.receive_hit(buried_break)
    await wait_frames(2)
    check(brain.state == RaizFamintaBrain.State.RUPTURE and root_enemy.get_node("VisualRoot").visible and not attack.hitbox.active, "Ruptura enterrada vira colapso visível sem ataque")
    root_enemy.reset_enemy()
    root_enemy.global_position = Vector2(1300, 219)
    var lethal := make_hit(85, 35)
    health.receive_hit(lethal)
    await wait_frames(2)
    check(brain.state == RaizFamintaBrain.State.DEATH and not posture.is_ruptured() and not attack.hitbox.active, "Morte prevalece sobre Ruptura no mesmo impacto")
    check(root_enemy.get_node("VisualRoot").visible and root_enemy.died_buried and health.current_health == 0, "morte enterrada deixa corpo exposto")

    root_enemy.reset_enemy()
    check(root_enemy.global_position == root_enemy.spawn_position and brain.state == RaizFamintaBrain.State.HIDDEN and attack.mode == RaizFamintaAttack.Mode.NONE, "reset restaura posição, enterramento e ataque")
    check(health.current_health == 85 and posture.current_posture == 35.0 and not posture.is_ruptured(), "reset restaura HP e Postura")
    player.global_position = Vector2(700, 215)
    root_enemy.global_position = Vector2(1400, 219)
    health.receive_hit(make_hit(10, 0))
    await press(&"reset_dummy")
    check(health.current_health == 85 and root_enemy.global_position == root_enemy.spawn_position and brain.state == RaizFamintaBrain.State.HIDDEN, "tecla de reset restaura Raiz fora do alcance do jogador")
    check(not FileAccess.get_file_as_string("res://scripts/enemies/raiz_faminta_brain.gd").contains("Input."), "IA lê mundo, sem ler comandos")

    print("MILESTONE 6: ", "FAIL" if failed else "PASS")
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    arena.queue_free()
    await process_frame
    var cleanup_until := Time.get_ticks_msec() + 400
    while Time.get_ticks_msec() < cleanup_until:
        await process_frame
    quit(1 if failed else 0)
