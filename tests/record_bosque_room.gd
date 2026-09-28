extends SceneTree

## Records real rendered gameplay at 12 fps. No collision debug is enabled.
func _initialize() -> void:
    call_deferred("record")


func record() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        quit(1)
        return
    var directory := args[0]
    DirAccess.make_dir_recursive_absolute(directory)
    var room: Node2D = load("res://scenes/biomes/forest/bosque_room_aprovada.tscn").instantiate()
    root.add_child(room)
    var player := room.get_node("Player") as CharacterBody2D
    for _frame in range(8):
        await process_frame
    Input.action_press(&"move_right")
    var jumps := [false, false, false]
    var dashed := false
    var release_jump := false
    var release_dash := false
    var saved := 0
    for tick in range(900):
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
        if not jumps[1] and x >= 948:
            Input.action_press(&"jump")
            release_jump = true
            jumps[1] = true
        if not jumps[2] and x >= 1040:
            Input.action_press(&"jump")
            release_jump = true
            jumps[2] = true
        if not dashed and x >= 1090:
            Input.action_press(&"dodge")
            release_dash = true
            dashed = true
        await physics_frame
        if tick % 5 == 0:
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            image.save_png(directory.path_join("frame_%04d.png" % saved))
            saved += 1
        if room.reached_exit:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    print("BOSQUE_ROOM_RECORD frames=%d exit=%s falls=%d" % [saved, str(room.reached_exit), room.fall_count])
    quit(0 if room.reached_exit and room.fall_count == 0 else 1)
