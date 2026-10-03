extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene: Node = load("res://scenes/biomes/forest/bosque_integracao_p40.tscn").instantiate()
    root.add_child(scene)
    for _i in range(20):
        await physics_frame
    var form: Node = scene.player.get_node("VisualRoot").form
    var native: Rect2i = form.character.anims.idle.frames[0].tex.get_image().get_used_rect()
    var result := {"zoom": .9, "viewport": [960, 540], "player_idle_native_bbox": [native.position.x, native.position.y, native.size.x, native.size.y], "player_capsule_world": {"radius": 7, "height": 46 / .9}, "enemies": []}
    for enemy: CharacterBody2D in scene.enemies:
        var visual: Node2D = enemy.get_node("VisualRoot")
        var bounds := Rect2()
        var first := true
        for polygon: Polygon2D in visual.find_children("*", "Polygon2D", true, false):
            var transform := polygon.get_global_transform_with_canvas()
            for point: Vector2 in polygon.polygon:
                var screen: Vector2 = transform * point
                if first:
                    bounds = Rect2(screen, Vector2.ZERO)
                    first = false
                else:
                    bounds = bounds.expand(screen)
        var collision: Shape2D = enemy.get_node("Hurtbox/CollisionShape2D").shape
        result.enemies.append({"name": String(enemy.name), "visual_bbox_screen": [bounds.size.x, bounds.size.y], "visible_at_sample": visual.visible, "hurtbox_world": collision.get_rect().size.y, "note": "silhueta provisória original; Raiz medida na geometria de quando emerge, sem mudar sua IA"})
    var file := FileAccess.open("res://codex/evidencias_integracao_p40_f3/ESCALA_BOSQUE.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(result, "  ") + "\n")
    print("SCALE_RESULT ", JSON.stringify(result))
    quit(0)
