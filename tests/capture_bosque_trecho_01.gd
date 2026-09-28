extends SceneTree

func _initialize() -> void:
    call_deferred("capture")


func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        quit(1)
        return
    var level: Node = load("res://scenes/biomes/forest/bosque_trecho_01_playable.tscn").instantiate()
    root.add_child(level)
    for _i in range(8):
        await process_frame
    var image := root.get_texture().get_image()
    print("BOSQUE_CAPTURE size=%s" % str(image.get_size()))
    print("BOSQUE_CAPTURE saved=%s" % str(image.save_png(args[0])))
    quit()
