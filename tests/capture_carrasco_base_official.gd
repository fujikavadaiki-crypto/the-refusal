extends SceneTree

## Reproducible gameplay captures of the official base in the approved room.
const ROOM := preload("res://scenes/biomes/forest/bosque_room_aprovada.tscn")


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty():
        push_error("Expected an output directory")
        quit(1)
        return
    var output: String = args[0]
    DirAccess.make_dir_recursive_absolute(output)
    var room := ROOM.instantiate() as Node2D
    root.add_child(room)
    var player := room.get_node("Player") as CharacterBody2D
    var form := player.get_node("VisualRoot/CarrascoModular") as Node2D
    if form == null or form.get_script().resource_path != "res://scripts/player/visuals/carrasco_base_official.gd":
        push_error("Official Carrasco base is not mounted")
        quit(1)
        return
    for _i in range(60):
        await physics_frame
    await _shot(output, "idle", player, form)
    Input.action_press(&"move_right")
    for frame in range(215):
        await physics_frame
        if frame in [190, 197, 204, 211]:
            await _shot(output, "run_%03d" % frame, player, form)
    Input.action_release(&"move_right")
    for _i in range(60):
        await physics_frame
    await _shot(output, "idle_on_path", player, form)
    Input.action_press(&"attack_heavy")
    await physics_frame
    Input.action_release(&"attack_heavy")
    var phases := {}
    var active_ticks := 0
    for frame in range(65):
        await physics_frame
        var phase: int = player.get_node("Combat").phase
        if not phases.has(phase):
            phases[phase] = true
            await _shot(output, "heavy_phase_%d" % phase, player, form)
        if phase == PlayerCombat.Phase.ACTIVE:
            active_ticks += 1
            if active_ticks == 4:
                await _shot(output, "heavy_swing", player, form)
    print("CARRASCO_HEAVY_PHASES=", phases.keys())
    for _i in range(60):
        await physics_frame
    Input.action_press(&"jump")
    await physics_frame
    Input.action_release(&"jump")
    for _i in range(10):
        await physics_frame
    await _shot(output, "jump", player, form)
    Input.action_press(&"dodge")
    await physics_frame
    Input.action_release(&"dodge")
    for _i in range(8):
        await physics_frame
    await _shot(output, "dash", player, form)
    for _i in range(60):
        await physics_frame
    quit(0 if phases.has(PlayerCombat.Phase.WINDUP) and phases.has(PlayerCombat.Phase.ACTIVE) and phases.has(PlayerCombat.Phase.RECOVERY) else 1)


func _shot(output: String, label: String, player: CharacterBody2D, form: Node2D) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path := output.path_join(label + ".png")
    var result := image.save_png(path)
    print("CARRASCO_SHOT label=%s x=%.1f y=%.1f pose=%s phase=%d save=%d" % [label, player.global_position.x, player.global_position.y, form.get("pose"), player.get_node("Combat").phase, result])
