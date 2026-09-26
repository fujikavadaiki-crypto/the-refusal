extends SceneTree

var failed := false


func _initialize() -> void:
    call_deferred("run_checks")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(value: bool, description: String) -> void:
    if value:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func tap(action: StringName) -> void:
    Input.action_press(action)
    await frames(2)
    Input.action_release(action)


func run_checks() -> void:
    var slice := load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate() as Node2D
    root.add_child(slice)
    await frames(5)
    var player := slice.get_node("Player") as CharacterBody2D
    var second: ForestEncounter = slice.encounters[1]
    player.global_position = Vector2(2940, 175)
    await frames(20)
    var crow := second.enemies[1]
    var pilgrim := second.enemies[0]
    check(second.is_active and crow.get_node("Brain").player == player and pilgrim.get_node("Brain").player == player, "segundo encontro ativa os dois comportamentos")
    # Stage the moving target for deterministic hitbox checks after confirming
    # that the live encounter activated its AI.
    crow.set_physics_process(false)
    crow.global_position = Vector2(2965, 113)
    crow.velocity = Vector2.ZERO
    player.global_position = Vector2(2940, 175)
    await frames(20)
    var crow_hp: int = crow.get_node("Health").current_health
    await tap(&"jump")
    await frames(15)
    await tap(&"attack_light")
    await frames(25)
    print("CROW: pos=", crow.global_position, " hp=", crow.get_node("Health").current_health, " player=", player.global_position)
    check(player.get_node("Combat").confirmed_hit_count > 0 or crow.get_node("Health").current_health < crow_hp, "ataque aéreo pode alcançar o Corvo")
    await frames(22)
    Input.action_press(&"move_right")
    for _i in range(20):
        if player.global_position.x >= crow.global_position.x - 26.0:
            break
        await physics_frame
    Input.action_release(&"move_right")
    await tap(&"jump")
    await frames(15)
    await tap(&"attack_heavy")
    await frames(35)
    print("CROW FINISH: hp=", crow.get_node("Health").current_health)
    check(crow.get_node("Health").current_health == 0, "Corvo pode morrer para ataques reais do Carrasco")
    crow.set_physics_process(true)
    slice.reset_slice()
    player.global_position = Vector2(2940, 175)
    await frames(20)
    await tap(&"jump")
    await frames(3)
    await tap(&"dodge")
    check(player.get_node("Defense").mode == PlayerDefense.Mode.AIR_DASH, "air dash disponível no segundo encontro")
    await frames(5)
    await tap(&"attack_light")
    check(player.get_node("Combat").current_attack != null, "ataque após air dash responde")
    slice.reset_slice()
    await frames(8)
    await tap(&"attack_light")
    await frames(21)
    await tap(&"attack_heavy")
    await frames(7)
    var buffered: AttackData = player.get_node("Combat").current_attack
    check(buffered != null and buffered.attack_id == &"carrasco_heavy", "Heavy apertado no fim da recuperação entra pelo buffer")
    slice.reset_slice()
    player.global_position = Vector2(3050, 175)
    await frames(210)
    check(player.get_node("Health").current_health < 100, "Peregrino do segundo encontro consegue ferir o jogador")
    print("SECOND ENCOUNTER: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
