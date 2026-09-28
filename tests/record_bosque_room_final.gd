extends SceneTree

## Reproducible runtime tour with observation pauses for the approved room.
const ROOM := preload("res://scenes/biomes/forest/bosque_room_aprovada.tscn")


func _initialize() -> void:
    call_deferred("record")


func record() -> void:
    var room: Node2D = ROOM.instantiate()
    root.add_child(room)
    var player := room.get_node("Player") as CharacterBody2D
    await _hold(9.0)
    Input.action_press(&"move_right")
    var pause_markers := [
        {"x": 102.0, "seconds": 4.0, "floor": true},  # upper lip of the L
        {"x": 202.0, "seconds": 5.0, "floor": true},  # lower lip after the drop
        {"x": 360.0, "seconds": 5.0, "floor": true},
        {"x": 680.0, "seconds": 5.0, "floor": true},
        {"x": 870.0, "seconds": 5.0, "floor": true},
        {"x": 995.0, "seconds": 6.0, "floor": true},
        {"x": 1220.0, "seconds": 10.0, "floor": true},
    ]
    var pause_index := 0
    var jumps := [false, false, false]
    var dashed := false
    var release_jump := false
    var release_dash := false
    var ticks := 0
    for tick in range(4800):
        ticks = tick
        if release_jump:
            Input.action_release(&"jump")
            release_jump = false
        if release_dash:
            Input.action_release(&"dodge")
            release_dash = false
        var x := player.global_position.x
        if pause_index < pause_markers.size():
            var stop: Dictionary = pause_markers[pause_index]
            if x >= float(stop.x) and (not bool(stop.floor) or player.is_on_floor()):
                Input.action_release(&"move_right")
                await _hold(float(stop.seconds))
                Input.action_press(&"move_right")
                pause_index += 1
                continue
        if not jumps[0] and x >= 603.0:
            Input.action_press(&"jump")
            release_jump = true
            jumps[0] = true
        if not jumps[1] and x >= 948.0:
            Input.action_press(&"jump")
            release_jump = true
            jumps[1] = true
        if not jumps[2] and x >= 1040.0:
            Input.action_press(&"jump")
            release_jump = true
            jumps[2] = true
        if not dashed and x >= 1090.0:
            Input.action_press(&"dodge")
            release_dash = true
            dashed = true
        await physics_frame
        if room.reached_exit:
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    Input.action_release(&"dodge")
    await _hold(6.0)
    print("BOSQUE_FINAL_RECORD ticks=%d pauses=%d exit=%s falls=%d" % [ticks, pause_index, str(room.reached_exit), room.fall_count])
    quit(0 if room.reached_exit and room.fall_count == 0 and pause_index == pause_markers.size() else 1)


func _hold(seconds: float) -> void:
    for _tick in range(roundi(seconds * 60.0)):
        await physics_frame
