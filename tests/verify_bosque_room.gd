extends SceneTree

func _initialize() -> void:
    call_deferred("verify")


func verify() -> void:
    var room: Node2D = load("res://scenes/biomes/forest/bosque_room_aprovada.tscn").instantiate()
    root.add_child(room)
    var player := room.get_node("Player") as CharacterBody2D
    var checks := {"main_path": false, "height_change": false, "raised_platform": false, "gap_empty": false, "gap_crossed": false, "exit": false}
    await physics_frame
    var ray := PhysicsRayQueryParameters2D.new()
    ray.from = Vector2(1128, 160)
    ray.to = Vector2(1128, 380)
    ray.collision_mask = 1
    checks.gap_empty = room.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
    var jumps := [false, false, false]
    var dashed := false
    var release_jump := false
    var release_dash := false
    Input.action_press(&"move_right")
    for tick in range(1600):
        if release_jump:
            Input.action_release(&"jump")
            release_jump = false
        if release_dash:
            Input.action_release(&"dodge")
            release_dash = false
        var x := player.global_position.x
        if not jumps[0] and x >= 603:
            Input.action_press(&"jump")
            release_jump = true
            jumps[0] = true
            print("ROOM_JUMP_RUIN x=%.1f y=%.1f" % [x, player.global_position.y])
        if not jumps[1] and x >= 948:
            Input.action_press(&"jump")
            release_jump = true
            jumps[1] = true
            print("ROOM_JUMP_STONE x=%.1f y=%.1f" % [x, player.global_position.y])
        if not jumps[2] and x >= 1040:
            Input.action_press(&"jump")
            release_jump = true
            jumps[2] = true
            print("ROOM_JUMP_GAP x=%.1f y=%.1f floor=%s" % [x, player.global_position.y, str(player.is_on_floor())])
        if not dashed and x >= 1090:
            Input.action_press(&"dodge")
            release_dash = true
            dashed = true
            print("ROOM_DASH_GAP x=%.1f y=%.1f" % [x, player.global_position.y])
        await physics_frame
        x = player.global_position.x
        if tick % 60 == 0:
            print("ROOM_STEP tick=%d x=%.1f y=%.1f floor=%s falls=%d" % [tick, x, player.global_position.y, str(player.is_on_floor()), room.fall_count])
        checks.main_path = checks.main_path or (x >= 500 and player.is_on_floor())
        checks.height_change = checks.height_change or (x >= 350 and player.is_on_floor() and player.global_position.y > 208)
        checks.raised_platform = checks.raised_platform or (x >= 640 and x <= 735 and player.is_on_floor() and player.global_position.y < 205)
        checks.gap_crossed = checks.gap_crossed or (x > 1190 and player.is_on_floor())
        checks.exit = room.reached_exit
        if room.reached_exit:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    print("ROOM_RESULT checks=%s falls=%d x=%.1f y=%.1f" % [str(checks), room.fall_count, player.global_position.x, player.global_position.y])
    quit(0 if checks.values().all(func(value): return value) and room.fall_count == 0 else 1)
