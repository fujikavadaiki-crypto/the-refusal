extends "res://tests/verify_milestone5.gd"

## Reproduce only the two unchanged M5 jump/attack fixtures, record contact geometry.
## Old values are instance-only controls, never edits to production or enemy AI.
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
    player_combat.hit_confirmed.connect(func(context: HitContext) -> void: player_hits.append(context))
    var loco: PlayerLocomotion = player.get_node("Locomotion")
    var current_g := loco.gravity
    var current_v := loco.jump_velocity
    var records: Array[Dictionary] = []
    for old in [true, false]:
        loco.gravity = 800.0 if old else current_g
        loco.jump_velocity = -260.0 if old else current_v
        for action in [&"attack_light", &"attack_heavy"]:
            await fixture(Vector2(1100, 175), Vector2(1070, 215))
            await press(&"jump")
            Input.action_press(action)
            var samples: Array[Dictionary] = []
            for tick in range(40):
                await wait_frames(1)
                if tick == 1:
                    Input.action_release(action)
                if player_combat.hitbox.active:
                    var center := player_combat.hitbox.global_position
                    samples.append({"tick": tick, "elapsed_s": player_combat.elapsed, "player_feet_y": player.position.y + 13.0, "player_origin_y": player.position.y, "bird_y": bird.position.y, "dx_world": bird.position.x - player.position.x, "hit_center_x": center.x, "hit_center_y": center.y, "hit_center_dy_world": center.y - bird.position.y, "angle_degrees": player_combat.pivot.rotation_degrees})
            root.get_node("HitStop")._restore()
            var record := {"profile": "before_g800_v260" if old else "P40", "form": "human", "action": action, "gravity": loco.gravity, "impulse": loco.jump_velocity, "initial_dx_world": 30, "initial_bird_y": 175, "damage": 65 - health.current_health, "contacts": player_hits.size(), "active_samples": samples}
            records.append(record)
            print("MEASURE: ", JSON.stringify(record))
    var file := FileAccess.open("res://codex/evidencias_integracao_p40_f2/DIAGNOSTICO_CORVO.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    arena.queue_free()
    await wait_frames(2)
    quit(0)
