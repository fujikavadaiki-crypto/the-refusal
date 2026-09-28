extends SceneTree

## Captures live gameplay poses without modifying the scene or controller.
## --script res://tests/capture_modular_motion.gd -- <absolute-output-directory>
var output_dir := ""


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        push_error("Expected an output directory")
        quit(1)
        return
    output_dir = args[0]
    DirAccess.make_dir_recursive_absolute(output_dir)
    call_deferred("_run")


func _run() -> void:
    if change_scene_to_file("res://scenes/biomes/forest/forest_vertical_slice.tscn") != OK:
        quit(1)
        return
    for i in range(25):
        await physics_frame
    var player := current_scene.get_node("Player") as CharacterBody2D
    var form := player.get_node("VisualRoot/CarrascoModular") as Node2D
    if form == null:
        push_error("Modular Carrasco was not mounted on the Player")
        quit(1)
        return
    await _capture("idle", player, form)
    Input.action_press("move_right")
    for i in range(16):
        await physics_frame
    for phase in range(6):
        for i in range(4):
            await physics_frame
        await _capture("run_%02d" % phase, player, form)
    Input.action_press("dodge")
    await physics_frame
    Input.action_release("dodge")
    for i in range(5):
        await physics_frame
    await _capture("dash", player, form)
    for i in range(35):
        await physics_frame
    Input.action_press("jump")
    await physics_frame
    Input.action_release("jump")
    for i in range(8):
        await physics_frame
    await _capture("jump", player, form)
    Input.action_release("move_right")
    quit()


func _capture(label: String, player: CharacterBody2D, form: Node2D) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path := output_dir.path_join("carrasco_" + label + ".png")
    var result := image.save_png(path)
    print(label, " pos=", player.global_position, " velocity=", player.velocity,
        " pose=", form.get("pose"), " defense=", player.get_node("Defense").mode,
        " pixels=", image.get_size(), " save=", result)
