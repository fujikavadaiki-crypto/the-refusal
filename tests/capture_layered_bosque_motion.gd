extends SceneTree

const SEGMENTS := [Vector2(220, 560), Vector2(1290, 1640), Vector2(2630, 2980), Vector2(3560, 3880)]


func _initialize() -> void:
    call_deferred("capture")


func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        printerr("Pass an output directory after --")
        quit(1)
        return
    var output := args[0]
    DirAccess.make_dir_recursive_absolute(output)
    var slice := load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate() as Node2D
    root.add_child(slice)
    for encounter in slice.encounters:
        encounter.process_mode = Node.PROCESS_MODE_DISABLED
        encounter.visible = false
    var player := slice.get_node("Player") as CharacterBody2D
    var far: Node2D = slice.get_node("LayeredBosque/DistantForest")
    var middle: Node2D = slice.get_node("LayeredBosque/MiddleRuins")
    var ground: Node2D = slice.get_node("LayeredBosque/PlayableStoneAndRoots")
    var jumps := [false, false, false]
    var dashes := [false, false, false]
    var counts := [0, 0, 0, 0]
    var jump_release := false
    var dash_release := false
    var jump_points := [1135.0, 2368.0, 3645.0]
    var dash_points := [1180.0, 2405.0, 3700.0]
    Input.action_press(&"move_right")
    for tick in range(3600):
        if jump_release:
            Input.action_release(&"jump")
            jump_release = false
        if dash_release:
            Input.action_release(&"dodge")
            dash_release = false
        for i in range(3):
            if not jumps[i] and player.global_position.x >= jump_points[i]:
                Input.action_press(&"jump")
                jump_release = true
                jumps[i] = true
                break
            if jumps[i] and not dashes[i] and player.global_position.x >= dash_points[i]:
                Input.action_press(&"dodge")
                dash_release = true
                dashes[i] = true
                break
        await physics_frame
        if tick % 5 == 0:
            for section in range(4):
                var interval: Vector2 = SEGMENTS[section]
                if player.global_position.x >= interval.x and player.global_position.x <= interval.y and counts[section] < 34:
                    await RenderingServer.frame_post_draw
                    var file := output.path_join("section_%d_%03d.png" % [section + 1, counts[section]])
                    root.get_texture().get_image().save_png(file)
                    counts[section] += 1
        if slice.finished:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    print("MOTION: finished=%s falls=%d captures=%s far=%.1f middle=%.1f ground=%.1f" % [
        str(slice.finished), slice.fall_recovery_count, str(counts), far.position.x, middle.position.x, ground.position.x
    ])
    var valid: bool = slice.finished and slice.fall_recovery_count == 0 and counts.min() >= 8
    valid = valid and far.position.x > middle.position.x and middle.position.x > ground.position.x
    quit(0 if valid else 1)
