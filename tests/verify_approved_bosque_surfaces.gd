extends SceneTree

const SAMPLES := [120.0, 450.0, 650.0, 830.0, 1090.0, 1250.0,
                  1450.0, 1900.0, 2310.0, 2560.0, 3000.0, 3450.0, 3850.0]

var failed := false


func _initialize() -> void:
    call_deferred("run_checks")


func run_checks() -> void:
    var scene := load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate() as Node2D
    root.add_child(scene)
    var player := scene.get_node("Player") as CharacterBody2D
    for encounter in scene.encounters:
        encounter.process_mode = Node.PROCESS_MODE_DISABLED
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        DirAccess.make_dir_recursive_absolute(args[0])
    for sample in SAMPLES:
        player.global_position = Vector2(sample, 25)
        player.velocity = Vector2.ZERO
        for _i in range(80):
            await physics_frame
            if _i >= 12 and player.is_on_floor():
                break
        if not player.is_on_floor() or player.global_position.y < 80.0:
            failed = true
            printerr("FAIL: no painted ground at x=", sample)
        else:
            print("GROUND: x=%.0f foot_y=%.1f" % [sample, player.global_position.y + 13.0])
        if not args.is_empty():
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(args[0].path_join("surface_%04d.png" % int(sample)))
    for gap in [1185.0, 2445.0, 3735.0]:
        var query := PhysicsRayQueryParameters2D.create(Vector2(gap, 0), Vector2(gap, 350), 1)
        query.exclude = [player.get_rid()]
        if not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
            failed = true
            printerr("FAIL: invisible floor over painted gap at x=", gap)
        else:
            print("OPEN GAP: x=", gap)
    print("APPROVED BOSQUE SURFACES: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
