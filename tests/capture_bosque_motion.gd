extends SceneTree

func _initialize() -> void:
    call_deferred("capture")


func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        quit(1)
        return
    var directory := args[0]
    DirAccess.make_dir_recursive_absolute(directory)
    var level: Node2D = load("res://scenes/biomes/forest/bosque_trecho_01_playable.tscn").instantiate()
    root.add_child(level)
    for _i in range(8):
        await process_frame
    Input.action_press(&"move_right")
    for frame in range(96):
        await process_frame
        if frame % 4 == 0:
            var image := root.get_texture().get_image()
            image.save_png(directory.path_join("run_%03d.png" % (frame / 4)))
    Input.action_release(&"move_right")
    print("BOSQUE_MOTION frames=24")
    quit()
