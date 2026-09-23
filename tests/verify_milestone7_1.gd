extends SceneTree

var failed := false


func _initialize() -> void:
    call_deferred("run_checks")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func tap(action: StringName) -> void:
    Input.action_press(action)
    await frames(2)
    Input.action_release(action)


func run_checks() -> void:
    var slice: Node2D = load("res://scenes/biomes/forest/forest_slice_01.tscn").instantiate()
    root.add_child(slice)
    await frames(5)
    var player: CharacterBody2D = slice.get_node("Player")
    var defense: PlayerDefense = player.get_node("Defense")
    var camera: Camera2D = player.get_node("Camera2D")
    var health: HealthComponent = player.get_node("Health")
    var pairs: Array[ForestEncounter] = [slice.encounters[3], slice.encounters[4]]

    slice.reset_slice()
    player.global_position = Vector2(5250, 215)
    await frames(70)
    var crow: CharacterBody2D = pairs[0].enemies[1]
    var pilgrim: CharacterBody2D = pairs[0].enemies[0]
    check(pairs[0].is_active and crow.get_node("Brain").state not in [CorvoBrain.State.HOVER, CorvoBrain.State.PATROL_AIR], "Corvo inicia o par ao aproximar pelo oeste")
    check(pilgrim.get_node("Brain").state in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL], "Peregrino ainda não cobre a entrada do Corvo")
    player.global_position = Vector2(5470, 215)
    await frames(80)
    check(pilgrim.get_node("Brain").state not in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL], "Peregrino entra depois, sem ocultar o Corvo")

    slice.reset_slice()
    player.global_position = Vector2(6865, 215)
    await frames(70)
    var root_enemy: CharacterBody2D = pairs[1].enemies[1]
    pilgrim = pairs[1].enemies[0]
    check(pairs[1].is_active and root_enemy.get_node("Brain").state != RaizFamintaBrain.State.HIDDEN, "Raiz sinaliza sua entrada antes do Peregrino")
    check(pilgrim.get_node("Brain").state in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL], "entrada do par Raiz não é bloqueada pelo Peregrino")
    player.global_position = Vector2(7010, 215)
    await frames(80)
    check(pilgrim.get_node("Brain").state not in [PeregrinoBrain.State.IDLE, PeregrinoBrain.State.PATROL], "Peregrino entra no segundo par")

    slice.reset_slice()
    var solo_crow: CharacterBody2D = slice.encounters[2].enemies[0]
    var hit := HitContext.new()
    hit.attacker = player
    hit.target = solo_crow
    hit.attack_id = &"m7_1_fixture"
    hit.action_uid = HitContext.allocate_action_id()
    hit.base_damage = 100
    hit.damage_type = &"physical"
    player.global_position = Vector2(4190, 215)
    await frames(5)
    solo_crow.get_node("Health").receive_hit(hit)
    await frames(60)
    check(solo_crow.get_node("Health").current_health == 0 and solo_crow.get_collision_exceptions().has(player) and player.get_collision_exceptions().has(solo_crow), "Corvo morto conserva colisão com o solo, mas libera o Player")
    player.global_position = Vector2(solo_crow.global_position.x - 35.0, 215)
    Input.action_press("move_right")
    await frames(45)
    Input.action_release("move_right")
    check(player.global_position.x > solo_crow.global_position.x + 25.0, "Player atravessa a posição do Corvo morto")
    slice.reset_slice()
    check(not solo_crow.get_collision_exceptions().has(player) and solo_crow.get_node("Health").current_health == 65, "reinício restaura colisão com o Player e vida do Corvo")

    slice.reset_slice()
    player.global_position = Vector2(1840, 215)
    await frames(15)
    var safe_before: Vector2 = slice.safe_position
    defense.air_dash_available = false
    var hp_before: int = health.current_health
    player.global_position = Vector2(1930, 356)
    slice.recover_from_fall()
    check(not defense.air_dash_available, "recuperação não devolve Air Dash antes da aterrissagem")
    check(health.current_health == hp_before and player.global_position.distance_to(safe_before) < 2.0, "recuperação retorna ao solo seguro sem dano")
    await frames(4)
    check(player.is_on_floor() and defense.air_dash_available, "aterrissagem válida recarrega um Air Dash")
    check(slice.reset_count == 5 and not pairs[0].is_active and not pairs[1].is_active, "queda não reinicia nem duplica os encontros")

    slice.reset_slice()
    player.global_position = Vector2(8040, 215)
    await frames(5)
    await tap(&"jump")
    await frames(4)
    await tap(&"dodge")
    await frames(30)
    check(player.global_position.x <= 8200.0 and camera.get_screen_center_position().x <= 7961.0, "Air Dash não ultrapassa o limite direito ou a câmera")
    check(player.global_position.y >= 0.0 and camera.get_screen_center_position().y >= 0.0, "Air Dash não sai pela parte superior da fase")

    slice.reset_slice()
    player.global_position = Vector2(40, 215)
    await frames(5)
    Input.action_press("move_left")
    await frames(3)
    await tap(&"jump")
    await frames(4)
    await tap(&"dodge")
    await frames(30)
    Input.action_release("move_left")
    check(player.global_position.x >= 0.0 and camera.get_screen_center_position().x >= 239.0, "Air Dash não ultrapassa o limite esquerdo ou a câmera")

    slice.reset_slice()
    player.global_position = Vector2(3540, 125)
    await frames(30)
    check(player.is_on_floor() and player.global_position.y < 155.0, "plataforma alta recebe o Player sem atravessar o chão")
    Input.action_press("move_right")
    await tap(&"jump")
    await frames(4)
    await tap(&"dodge")
    await frames(30)
    Input.action_release("move_right")
    check(player.global_position.y >= 0.0 and player.global_position.x < slice.WORLD_LENGTH and camera.get_screen_center_position().y <= 270.0, "Air Dash da plataforma alta permanece na fase e no enquadramento")

    print("MILESTONE 7.1: ", "FAIL" if failed else "PASS")
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    slice.queue_free()
    await process_frame
    quit(1 if failed else 0)
