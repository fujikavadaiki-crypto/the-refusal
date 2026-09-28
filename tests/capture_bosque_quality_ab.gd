extends SceneTree

const ROOM := preload("res://scenes/biomes/forest/bosque_room_aprovada.tscn")


func _initialize() -> void:
    call_deferred("capture")


func capture() -> void:
    var room := ROOM.instantiate()
    root.add_child(room)
    if OS.get_environment("BOSQUE_QUALITY_PLAYER_X") != "":
        (room.get_node("Player") as CharacterBody2D).global_position = Vector2(OS.get_environment("BOSQUE_QUALITY_PLAYER_X").to_float(), 230.0)
    var mode := OS.get_environment("BOSQUE_QUALITY_MODE")
    var art := room.get_node("BACKGROUND/ApprovedComposition") as Sprite2D
    var copies: Array[Node] = [
        room.get_node("BACKGROUND/DistantParallax/FarForestAndArch"),
        room.get_node("MIDGROUND/PaintedElements/CentralTreeTrunk"),
        room.get_node("MIDGROUND/PaintedElements/RuinedShrine"),
        room.get_node("FOREGROUND/PaintedElements/MossedPillar"),
        room.get_node("FOREGROUND/PaintedElements/WaterfallCliffLip"),
    ]
    if mode == "linear" or mode == "supersample":
        art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        for copy in copies:
            (copy as CanvasItem).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if mode == "supersample":
        root.content_scale_size = Vector2i(960, 540)
        DisplayServer.window_set_size(Vector2i(1920, 1080))
        (room.get_node("Player/Camera2D") as Camera2D).zoom = Vector2(2.0, 2.0)
    (room.get_node("Player/Camera2D") as Camera2D).offset.x = OS.get_environment("BOSQUE_QUALITY_PAN").to_float()
    for _i in range(8):
        await process_frame
    var path := OS.get_environment("BOSQUE_QUALITY_OUTPUT")
    var image := root.get_texture().get_image()
    image.save_png(path)
    print("QUALITY_CAPTURE mode=%s size=%s path=%s" % [mode, str(image.get_size()), path])
    quit()
