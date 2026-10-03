extends SceneTree

var failed := false


func _initialize() -> void:
    call_deferred("run_checks")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(value: bool, description: String) -> void:
    if value:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func snapshot(name: String) -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        return
    await RenderingServer.frame_post_draw
    var output_dir := args[0]
    DirAccess.make_dir_recursive_absolute(output_dir)
    var error := root.get_texture().get_image().save_png(output_dir.path_join(name + ".png"))
    check(error == OK, "rendered capture: " + name)


func hide_labels(node: Node) -> void:
    if node is Label:
        (node as Label).visible = false
    for child in node.get_children():
        hide_labels(child)


func run_checks() -> void:
    var arena := load("res://scenes/test/carrasco_arena.tscn").instantiate() as Node2D
    root.add_child(arena)
    arena.get_node("Peregrino").process_mode = Node.PROCESS_MODE_DISABLED
    await frames(8)
    if not OS.get_cmdline_user_args().is_empty():
        hide_labels(arena)
        arena.get_node("TechnicalHUD").visible = false

    var player := arena.get_node("TestRoom/Player") as CharacterBody2D
    var visual := player.get_node("VisualRoot") as PlayerVisualController
    # This suite describes the archived GIF contract, not the new package.
    visual.small_carrasco_enabled = false
    visual._on_mask_changed(player.get_node("MaskController").active_data())
    var form: Node2D = visual.form
    var sprite := form.get_node("Sprite") as Sprite2D
    var locomotion := player.get_node("Locomotion") as PlayerLocomotion

    check(InputMap.has_action("walk"), "walk action exists")
    check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "nearest filtering remains active")
    check(sprite.texture.get_size() == Vector2(56, 56) and form.pose == &"idle", "idle uses the supplied native GIF")
    await snapshot("01_idle")
    check(form.gif_frame_textures["idle"].size() == 9 and form.gif_frame_textures["walk_east"].size() == 6, "idle and walk frame counts")
    check(form.gif_frame_textures["run_east"].size() == 8 and form.gif_frame_textures["run_west"].size() == 8 and form.gif_frame_textures["jump_east"].size() == 9, "run and jump frame counts")
    var idle_frame := sprite.texture
    await frames(12)
    check(sprite.texture != idle_frame, "idle animation advances")

    Input.action_press("walk")
    Input.action_press("move_right")
    await frames(14)
    check(form.pose == &"walk" and form.gif_frame_textures["walk_east"].has(sprite.texture), "holding walk selects east walking GIF")
    check(absf(player.velocity.x - locomotion.run_speed * locomotion.walk_speed_ratio) < 2.0, "walk speed follows the existing run tuning")
    check(sprite.texture.get_size() == Vector2(80, 80) and sprite.offset.x == -40.0 and sprite.offset.y >= -66.0 and sprite.offset.y <= -65.0, "walk keeps its original canvas and stable ground pivot")
    await snapshot("02_walk")

    Input.action_release("walk")
    await frames(12)
    check(form.pose == &"run" and form.gif_frame_textures["run_east"].has(sprite.texture), "walk to run transition selects east run GIF")
    check(absf(player.velocity.x - locomotion.run_speed) < 2.0, "unchanged run speed is reached")
    await snapshot("03_run_east")
    if not OS.get_cmdline_user_args().is_empty():
        for index in range(8):
            await snapshot("run_east_%02d" % index)
            await frames(5)

    Input.action_release("move_right")
    Input.action_press("move_left")
    await frames(2)
    check(player.facing_direction == -1 and form.gif_frame_textures["run_west"].has(sprite.texture), "direction reversal selects original west frames immediately")
    check(player.visual_root.scale.x == -1.0 and sprite.scale.x == -1.0, "west GIF is displayed without double mirroring")
    await snapshot("04_run_west")
    if not OS.get_cmdline_user_args().is_empty():
        for index in range(8):
            await snapshot("run_west_%02d" % index)
            await frames(5)
    Input.action_press("walk")
    await frames(2)
    check(form.pose == &"walk" and player.visual_root.scale.x == -1.0 and sprite.scale.x == 1.0, "west walking temporarily mirrors east frames")
    Input.action_release("walk")

    Input.action_release("move_left")
    await frames(12)
    check(form.pose == &"idle", "landing locomotion returns to idle after stopping")
    Input.action_press("jump")
    await frames(2)
    Input.action_release("jump")
    check(player.velocity.y < 0.0 and form.pose == &"jump", "jump input responds and selects jump frames")
    check(player.visual_root.scale.x == -1.0 and sprite.scale.x == 1.0, "west jump temporarily mirrors east frames")
    await snapshot("05_jump")
    await frames(23)
    check(player.velocity.y >= 0.0 and form.pose == &"fall", "vertical velocity selects fall frames")
    check(form.gif_frame_textures["jump_east"].has(sprite.texture), "fall reuses the supplied jump GIF")
    await snapshot("06_fall")
    await frames(28)
    check(player.is_on_floor() and form.pose == &"idle", "landing returns immediately to idle")
    check((player.get_node("CollisionShape2D") as CollisionShape2D).shape.height == 26.0, "body collider remains unchanged")
    await snapshot("07_landed")

    Input.action_press("attack_light")
    await frames(2)
    Input.action_release("attack_light")
    check(sprite.texture is AtlasTexture, "unapproved combat poses keep the previous atlas")

    arena.queue_free()
    await frames(2)
    print("CARRASCO GIF TEST: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
