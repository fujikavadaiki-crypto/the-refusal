extends SceneTree

var failed := false
var arena: Node2D
var player: CharacterBody2D
var enemy: CharacterBody2D
var brain: PeregrinoBrain
var attack: PeregrinoAttack
var health: HealthComponent
var posture: PostureComponent
var player_health: HealthComponent
var player_posture: PostureComponent
var defense: PlayerDefense
var combat: PlayerCombat
var contacts: Array[HitContext] = []
var states_seen: Dictionary = {}


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame
        if brain != null:
            states_seen[brain.state] = true


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func _on_contact(context: HitContext) -> void:
    contacts.append(context)


func reset_pair(player_x := 1270.0) -> void:
    enemy.reset_enemy()
    combat.abort_attack()
    player_health.reset_health()
    player_posture.reset_posture()
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0.0
    defense.dodge_cooldown = 0.0
    player.get_node("Locomotion").run_speed = 120.0
    player.global_position = Vector2(player_x, 215)
    player.velocity = Vector2.ZERO
    player.facing_direction = 1
    player.get_node("VisualRoot").scale.x = 1
    combat.set_facing(1)
    defense.set_facing(1)
    contacts.clear()
    await wait_frames(5)


func run_checks() -> void:
    arena = load("res://scenes/test/peregrino_arena.tscn").instantiate()
    root.add_child(arena)
    player = arena.get_node("TestRoom/Player")
    enemy = arena.get_node("Peregrino")
    brain = enemy.get_node("Brain")
    attack = enemy.get_node("Attack")
    health = enemy.get_node("Health")
    posture = enemy.get_node("Posture")
    player_health = player.get_node("Health")
    player_posture = player.get_node("Posture")
    defense = player.get_node("Defense")
    combat = player.get_node("Combat")
    attack.hit_confirmed.connect(_on_contact)

    await wait_frames(65)
    check(health.max_health == 100 and health.current_health == 100, "Peregrino: 100 HP canônicos")
    check(posture.max_posture == 40.0 and posture.current_posture == 40.0, "Peregrino: 40 Postura canônica")
    check(brain.state == PeregrinoBrain.State.PATROL and attack.phase == PeregrinoAttack.Phase.IDLE, "fora da percepção, patrulha sem atacar")
    check(player_health.current_health == 100, "fora de alcance, jogador intacto")

    player.global_position = Vector2(1180, 215)
    await wait_frames(2)
    check(brain.state == PeregrinoBrain.State.ALERT, "entrada em alcance gera ALERT")
    await wait_frames(30)
    check(brain.state == PeregrinoBrain.State.CHASE, "ALERT progride para CHASE")
    await wait_frames(110)
    for _i in range(45):
        if states_seen.has(PeregrinoBrain.State.ATTACK_RECOVERY):
            break
        await wait_frames(1)
    check(states_seen.has(PeregrinoBrain.State.ATTACK_WINDUP), "ataque entra em WINDUP")
    check(states_seen.has(PeregrinoBrain.State.ATTACK_ACTIVE), "ataque entra em ACTIVE")
    check(states_seen.has(PeregrinoBrain.State.ATTACK_RECOVERY), "ataque entra em RECOVERY")
    check(player_health.current_health == 88 and roundi(player_posture.current_posture) == 92, "Corte causa 12 HP / 8 Postura")
    check(contacts.size() == 1, "um contato por janela ofensiva")

    await reset_pair()
    check(health.current_health == 100 and posture.current_posture == 40.0 and brain.state in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.ALERT], "reset restaura HP, Postura e IA")
    check(not enemy.get_node("AttackPivot/Hitbox").active, "reset desativa Hitbox")

    attack.start(attack.corte)
    await wait_frames(8)
    player.global_position = Vector2(1080, 215)
    await wait_frames(45)
    check(player_health.current_health == 100, "afastar-se durante WINDUP evita golpe comprometido")

    await reset_pair()
    attack.start(attack.corte)
    await wait_frames(16)
    defense.accept_inputs(false, true, 0.0, 1, false)
    await wait_frames(13)
    check(player_health.current_health == 100 and player_posture.current_posture == 100.0, "Parry evita HP e Postura")
    check(posture.current_posture == 32.0 and contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.PARRIED, "Parry retorna 8 Postura ao Peregrino")

    await reset_pair()
    player.get_node("Locomotion").run_speed = 0.0
    attack.start(attack.corte)
    await wait_frames(16)
    defense.accept_inputs(true, false, 0.0, -1, false)
    await wait_frames(13)
    check(player_health.current_health == 100 and player_posture.current_posture == 100.0, "Dodge em i-frame evita ambos os danos")
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DODGED, "Dodge resolvido pelo sistema genérico")

    await reset_pair()
    attack.start(attack.corte)
    await wait_frames(29)
    check(player_health.current_health == 88 and roundi(player_posture.current_posture) == 92, "sem i-frame/Parry, ataque causa dano normal")
    check(contacts.size() == 1, "scan repetido não duplica hit")

    await reset_pair()
    brain.state = PeregrinoBrain.State.RUPTURE # Freeze decisions only for player-hit fixture.
    combat.accept_inputs(true, false)
    await wait_frames(20)
    check(health.current_health == 80 and posture.current_posture == 32.0, "Light 1 aplica 20 HP / 8 Postura via Hitbox")
    await reset_pair()
    brain.state = PeregrinoBrain.State.RUPTURE
    combat.accept_inputs(false, true)
    await wait_frames(28)
    check(health.current_health == 65 and posture.current_posture == 15.0, "Heavy aplica 35 HP / 25 Postura via Hitbox")

    await reset_pair()
    brain.state = PeregrinoBrain.State.RUPTURE
    combat.accept_inputs(true, false)
    for _i in range(90):
        await physics_frame
        if combat.current_light_stage == 1 and combat.elapsed >= combat.light_1.combo_queue_start_seconds:
            break
    combat.accept_inputs(true, false)
    for _i in range(90):
        await physics_frame
        if combat.current_light_stage == 2 and combat.elapsed >= combat.light_2.combo_queue_start_seconds:
            break
    combat.accept_inputs(true, false)
    await wait_frames(55)
    check(health.current_health == 30 and roundi(posture.current_posture) == 9, "Peregrino recebe Light 1/2/3: 20+22+28 HP e 8+9+14 Postura")

    await reset_pair()
    var strike := HitContext.new()
    strike.attacker = player
    strike.attacker_posture = player_posture
    strike.attacker_stats = player.get_node("DefenseStats")
    strike.attack_id = &"heavy"
    strike.action_uid = HitContext.allocate_action_id()
    strike.base_damage = 35
    strike.posture_damage = 25
    strike.damage_type = &"physical"
    health.receive_hit(strike)
    strike = strike.for_target(enemy, 1)
    health.receive_hit(strike)
    check(posture.is_ruptured() and brain.state == PeregrinoBrain.State.RUPTURE, "Postura zero inicia RUPTURE")
    check(not enemy.get_node("AttackPivot/Hitbox").active, "Ruptura cancela Hitbox")
    var vulnerable := strike.for_target(enemy, 2)
    vulnerable.base_damage = 20
    vulnerable.posture_damage = 0
    health.receive_hit(vulnerable)
    check(vulnerable.actual_damage == 24, "Ruptura aplica vulnerabilidade canônica +20%")
    await wait_frames(135)
    check(not posture.is_ruptured() and roundi(posture.current_posture) >= 20 and brain.state != PeregrinoBrain.State.RUPTURE, "recupera aproximadamente 50% da Postura")

    await reset_pair()
    var lethal := strike.for_target(enemy, 3)
    lethal.base_damage = 100
    lethal.posture_damage = 40
    health.receive_hit(lethal)
    await wait_frames(2)
    check(health.current_health == 0 and brain.state == PeregrinoBrain.State.DEATH and not posture.is_ruptured(), "morte prevalece sobre Ruptura simultânea")
    check(not enemy.get_node("AttackPivot/Hitbox").active, "morte neutraliza ataque")
    Input.action_press("reset_dummy")
    await wait_frames(2)
    Input.action_release("reset_dummy")
    check(health.current_health == 100 and brain.state != PeregrinoBrain.State.DEATH, "tecla R restaura o Peregrino após morte")
    await reset_pair()
    check(health.current_health == 100 and brain.state != PeregrinoBrain.State.DEATH, "reset ressuscita Peregrino")

    # Canonical move definitions, including both windows of Corte Duplo.
    var expected := [
        [attack.corte, 12, 8, &"parryable"],
        [attack.estocada, 14, 10, &"parryable"],
        [attack.investida, 18, 14, &"parryable"],
        [attack.corte_duplo_1, 10, 6, &"parryable"],
        [attack.corte_duplo_2, 12, 8, &"parryable"],
        [attack.penitencia, 25, 22, &"non_parryable"]
    ]
    for row in expected:
        check(row[0].base_damage == row[1] and row[0].posture_damage == row[2] and row[0].parry_class == row[3], "dados canônicos: %s" % row[0].attack_id)

    await reset_pair()
    attack.start(attack.corte_duplo_1, attack.corte_duplo_2)
    await wait_frames(90)
    check(player_health.current_health == 78 and roundi(player_posture.current_posture) == 86, "Corte Duplo aplica 10+12 HP e 6+8 Postura")
    check(contacts.size() == 2 and contacts[0].action_uid != contacts[1].action_uid, "Corte Duplo registra uma vez por golpe")

    await reset_pair()
    attack.start(attack.penitencia)
    await wait_frames(36)
    defense.accept_inputs(false, true, 0.0, 1, false)
    await wait_frames(15)
    check(player_health.current_health == 75 and roundi(player_posture.current_posture) == 78, "Golpe da Penitência atravessa Parry, 25 HP / 22 Postura")
    check(contacts.size() == 1 and contacts[0].outcome == HitContext.Outcome.DAMAGED, "Golpe da Penitência não é parryable")

    # Long unattended encounter; increase only the test fixture's player HP.
    await reset_pair(1180.0)
    player_health.max_health = 100000
    player_health.reset_health()
    var impossible := false
    var moves_seen: Dictionary = {}
    for i in range(7200):
        await physics_frame
        if attack.current_attack != null:
            moves_seen[attack.current_attack.attack_id] = true
        if brain.state == PeregrinoBrain.State.DEATH or is_nan(enemy.global_position.x) or absf(enemy.global_position.x) > 2400.0:
            impossible = true
            break
        if i % 600 == 0:
            print("SOAK frame=", i, " state=", PeregrinoBrain.State.keys()[brain.state], " x=", enemy.global_position.x)
    check(not impossible and player_health.current_health < 100000, "2 minutos simulados: IA combate sem estado impossível")
    check(moves_seen.size() == 6, "IA percorre os cinco golpes canônicos, incluindo as duas janelas do Corte Duplo")

    print("MILESTONE 4: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
