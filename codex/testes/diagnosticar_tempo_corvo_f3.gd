extends "res://tests/verify_milestone5.gd"

## Only the aerial fixture timing; same Corvo height, shapes and original AI.
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
    var contacts_data: Array = []
    player_combat.hit_confirmed.connect(func(c):
        player_hits.append(c)
        contacts_data.append({"velocity_y": player.velocity.y, "player_y": player.position.y, "elapsed": player_combat.elapsed})
    )
    var records: Array = []
    for delay in [6, 8, 10, 11, 12, 14, 16, 18, 20]:
        await fixture(Vector2(1100, 175), Vector2(1070, 215))
        contacts_data.clear()
        await press(&"jump")
        await wait_frames(delay)
        await press(&"attack_heavy")
        await wait_frames(45)
        var record := {"wait_after_jump": delay, "damage": 65 - health.current_health, "contacts": contacts_data.duplicate()}
        records.append(record)
        print("TIMING: ", JSON.stringify(record))
    await fixture(Vector2(1100, 175), Vector2(1070, 215))
    contacts_data.clear()
    await press(&"jump")
    await wait_for_descent(2)
    var input_velocity := player.velocity.y
    await press(&"attack_heavy")
    await wait_frames(35)
    var final_record := {"fixture": "M5 final", "input_velocity_y": input_velocity, "damage": 65 - health.current_health, "contacts": contacts_data.duplicate()}
    records.append(final_record)
    check(health.current_health == 33 and posture.is_ruptured(), "fixture final do pesado acerta/rompe o Corvo")
    check(not contacts_data.is_empty() and contacts_data[0].velocity_y > 0, "contato ACTIVE final acontece na descida")
    print("FINAL_TIMING: ", JSON.stringify(final_record))
    var file := FileAccess.open("res://codex/evidencias_integracao_p40_f3/TEMPO_CORVO.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(records, "  ") + "\n")
    quit(0)
