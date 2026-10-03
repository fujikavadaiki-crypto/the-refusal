extends SceneTree

## Diagnostic copy of the navigation segment of verify_vertical_slice.gd.
## No scene, terrain, jump, rendering or production source is changed.
var trace: Array[Dictionary] = []


func _initialize() -> void:
    call_deferred("run_diagnostic")


func frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func record(kind: String, player: CharacterBody2D, slice: Node2D, index := -1) -> void:
    var defense: PlayerDefense = player.get_node("Defense")
    var collision_names: Array[String] = []
    for collision_index in range(player.get_slide_collision_count()):
        var collider := player.get_slide_collision(collision_index).get_collider() as Node
        if collider != null:
            collision_names.append(String(collider.name))
    trace.append({"kind": kind, "route": index + 1 if index >= 0 else 0, "t": slice.elapsed_seconds, "x": player.global_position.x, "y": player.global_position.y, "feet_y": player.global_position.y + 13.0, "vx": player.velocity.x, "vy": player.velocity.y, "on_floor": player.is_on_floor(), "on_wall": player.is_on_wall(), "mode": PlayerDefense.Mode.keys()[defense.mode], "dash_elapsed": defense.elapsed, "colliders": collision_names, "falls": slice.fall_recovery_count})


func run_diagnostic() -> void:
    var variant := "old"
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        variant = args[0]
    var slice := load("res://scenes/biomes/forest/forest_vertical_slice.tscn").instantiate() as Node2D
    root.add_child(slice)
    await frames(6)
    var player := slice.get_node("Player") as CharacterBody2D
    var defense := player.get_node("Defense") as PlayerDefense
    slice.reset_slice()
    for encounter in slice.encounters:
        encounter.process_mode = Node.PROCESS_MODE_DISABLED
    var jumps := [false, false, false]
    var dashes := [false, false, false]
    var jump_release := false
    var dash_release := false
    var jump_points := [1135.0, 2368.0, 3645.0]
    var dash_points := [1180.0, 2405.0, 3700.0]
    if variant in ["retimed", "p40"]:
        # Preserve the previous running delay between jump and dash inputs.
        # The positions are an input script, not geometry or movement tuning.
        for index in range(3):
            dash_points[index] = jump_points[index] + (dash_points[index] - jump_points[index]) * 160.0 / 110.4
    if variant == "p40_apex":
        var movement: PlayerLocomotion = player.get_node("Locomotion")
        var apex_ticks := ceili(-movement.jump_velocity / movement.gravity * Engine.physics_ticks_per_second)
        var apex_seconds := float(apex_ticks) / Engine.physics_ticks_per_second
        for index in range(3):
            dash_points[index] = jump_points[index] + movement.run_speed * apex_seconds
    Input.action_press(&"move_right")
    var previous_mode := defense.mode
    var previous_floor := player.is_on_floor()
    var previous_wall := false
    var last_falls: int = slice.fall_recovery_count
    for _i in range(3600):
        if jump_release:
            Input.action_release(&"jump")
            jump_release = false
        if dash_release:
            Input.action_release(&"dodge")
            dash_release = false
        for index in range(3):
            if not jumps[index] and player.global_position.x >= jump_points[index]:
                record("jump_input", player, slice, index)
                Input.action_press(&"jump")
                jump_release = true
                jumps[index] = true
                break
            if jumps[index] and not dashes[index] and player.global_position.x >= dash_points[index]:
                record("dash_input", player, slice, index)
                Input.action_press(&"dodge")
                dash_release = true
                dashes[index] = true
                break
        await physics_frame
        if (player.global_position.x >= 1100.0 and player.global_position.x <= 1300.0) or (player.global_position.x >= 2320.0 and player.global_position.x <= 2550.0) or player.global_position.x >= 3600.0:
            record("frame", player, slice)
        if defense.mode != previous_mode or player.is_on_floor() != previous_floor or player.is_on_wall() != previous_wall:
            record("transition", player, slice)
        previous_mode = defense.mode
        previous_floor = player.is_on_floor()
        previous_wall = player.is_on_wall()
        if slice.fall_recovery_count != last_falls:
            record("fall_recovery", player, slice)
            last_falls = slice.fall_recovery_count
            if variant in ["old", "p40"]:
                # One fall already diagnoses the original route's added failure.
                break
        if slice.finished:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    var passed: bool = jumps.all(func(value): return value) and dashes.all(func(value): return value) and slice.finished and slice.fall_recovery_count == 0
    var summary := {"variant": variant, "passed_three_crossings": passed, "jumps": jumps, "dashes": dashes, "jump_points": jump_points, "dash_points": dash_points, "x": player.global_position.x, "y": player.global_position.y, "finished": slice.finished, "falls": slice.fall_recovery_count, "elapsed_seconds": slice.elapsed_seconds, "run_speed": player.get_node("Locomotion").run_speed, "dash_speed": defense.dash_speed, "jump_velocity": player.get_node("Locomotion").jump_velocity, "gravity": player.get_node("Locomotion").gravity}
    print("NAV_DIAGNOSTIC_SUMMARY: ", JSON.stringify(summary))
    print("NAV_DIAGNOSTIC_TRACE: ", JSON.stringify(trace))
    print("PASS: " if passed else "FAIL: ", "três travessias completas sem quedas; variant=", variant)
    player.get_node("ParryAudio").stop()
    player.get_node("ParryAudio").stream = null
    slice.queue_free()
    await frames(2)
    quit(0 if passed else 1)
