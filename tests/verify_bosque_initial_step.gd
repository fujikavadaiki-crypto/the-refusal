extends SceneTree

const ROOM := preload("res://scenes/biomes/forest/bosque_room_aprovada.tscn")


func _initialize() -> void:
    call_deferred("verify")


func verify() -> void:
    var room := ROOM.instantiate()
    root.add_child(room)
    var player := room.get_node("Player") as CharacterBody2D
    var points: PackedVector2Array = room.get_node("GAMEPLAY/EntranceTrail/CollisionPolygon2D").polygon
    var has_l := points[3] == Vector2(166, 322) and points[4] == Vector2(166, 390) and points[5] == Vector2(340, 390)
    if not has_l:
        push_error("Entrance polygon is not the approved L step")
        quit(1)
        return
    for _tick in range(8):
        await physics_frame

    # Walk off the ledge and fall onto the lower, level surface.
    Input.action_press(&"move_right")
    var drop_landed := false
    for _tick in range(180):
        await physics_frame
        if player.global_position.x > 185.0 and player.is_on_floor() and player.global_position.y > 205.0:
            drop_landed = true
            break
    Input.action_release(&"move_right")
    print("INITIAL_STEP_DROP landed=%s x=%.1f y=%.1f falls=%d" % [str(drop_landed), player.global_position.x, player.global_position.y, room.fall_count])
    if not drop_landed or room.fall_count != 0:
        quit(1)
        return

    # Return to the start and jump across the same step.
    player.global_position = room.get_node("Start").global_position
    player.velocity = Vector2.ZERO
    for _tick in range(8):
        await physics_frame
    Input.action_press(&"move_right")
    var jumped := false
    var release_jump := false
    var was_airborne := false
    var jump_landed := false
    for _tick in range(220):
        if release_jump:
            Input.action_release(&"jump")
            release_jump = false
        if not jumped and player.global_position.x >= 98.0:
            Input.action_press(&"jump")
            release_jump = true
            jumped = true
        await physics_frame
        was_airborne = was_airborne or player.velocity.y < -15.0
        if jumped and player.global_position.x > 205.0 and player.is_on_floor() and player.global_position.y > 205.0:
            jump_landed = true
            break
    Input.action_release(&"move_right")
    Input.action_release(&"jump")
    print("INITIAL_STEP_JUMP airborne=%s landed=%s x=%.1f y=%.1f falls=%d" % [str(was_airborne), str(jump_landed), player.global_position.x, player.global_position.y, room.fall_count])
    quit(0 if jumped and was_airborne and jump_landed and room.fall_count == 0 else 1)
