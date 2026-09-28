extends SceneTree
## Capture-only tour of the real playable room, with debug drawing disabled.

const ROOM := preload("res://scenes/biomes/forest/bosque_room_aprovada.tscn")


func _initialize() -> void:
	call_deferred("record")


func record() -> void:
	var room := ROOM.instantiate()
	root.add_child(room)
	var player := room.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	player.visible = false
	# The existing player camera is used without changing any camera property.
	player.global_position = Vector2(1220, 230)
	for _frame in 300:
		await process_frame
	player.global_position = Vector2(355, 180)
	for _frame in 300:
		await process_frame
	print("BOSQUE_ENVIRONMENT_LAYERS_CAPTURE_COMPLETE")
	quit()
