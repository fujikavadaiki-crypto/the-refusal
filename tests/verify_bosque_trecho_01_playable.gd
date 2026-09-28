extends SceneTree

func _initialize() -> void:
    call_deferred("verify")


func verify() -> void:
    var level: Node2D = load("res://scenes/biomes/forest/bosque_trecho_01_playable.tscn").instantiate()
    root.add_child(level)
    var player := level.get_node("Player") as CharacterBody2D
    var checks := [false, false, false, false]
    var jumps := [false, false]
    var dashes := [false, false]
    var release_jump := false
    var release_dash := false
    Input.action_press(&"move_right")
    for _tick in range(1400):
        if release_jump:
            Input.action_release(&"jump")
            release_jump = false
        if release_dash:
            Input.action_release(&"dodge")
            release_dash = false
        var x := player.global_position.x
        if not jumps[0] and x >= 550:
            Input.action_press(&"jump")
            release_jump = true
            jumps[0] = true
        elif jumps[0] and not dashes[0] and x >= 586:
            Input.action_press(&"dodge")
            release_dash = true
            dashes[0] = true
        if not jumps[1] and x >= 1190:
            Input.action_press(&"jump")
            release_jump = true
            jumps[1] = true
        elif jumps[1] and not dashes[1] and x >= 1226:
            Input.action_press(&"dodge")
            release_dash = true
            dashes[1] = true
        await physics_frame
        x = player.global_position.x
        checks[0] = checks[0] or (x >= 500 and player.is_on_floor())
        checks[1] = checks[1] or (x >= 800 and player.is_on_floor())
        checks[2] = checks[2] or (x >= 1450 and player.is_on_floor())
        checks[3] = checks[3] or level.reached_exit
        if level.reached_exit:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    print("BOSQUE_PLAYTEST checks=%s falls=%d x=%.1f exit=%s" % [str(checks), level.fall_count, player.global_position.x, str(level.reached_exit)])
    quit(0 if checks.all(func(value): return value) and level.fall_count == 0 else 1)
