extends SceneTree

## Native viewport review, current room and real death callback.
## Actors immobilized only for the photograph; production scripts untouched.
const OUT := "res://codex/evidencias_peregrino_47b/"

func _initialize() -> void:
    call_deferred("take_photo")

func freeze(n: Node) -> void:
    n.set_physics_process(false)
    for child in n.get_children(): freeze(child)

func take_photo() -> void:
    for id in InputMap.get_actions():
        InputMap.action_erase_events(id)
        Input.action_release(id)
    var scene: Node2D = load("res://scenes/biomes/cemiterio/sala_cemiterio.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    root.size = Vector2i(960, 540)
    root.get_node("IntegrationRooms").set_process_unhandled_key_input(false)
    root.get_node("Sensacao").set_process_input(false)
    scene.set_process_unhandled_key_input(false)
    scene.debug_geometry = false
    root.get_node("Sensacao").debug_controls = false
    while not scene.enemies_ready: await physics_frame
    await physics_frame
    for e in scene.enemies: freeze(e)
    freeze(scene.player)
    var enemy: CharacterBody2D = scene.enemies[0]
    var player: CharacterBody2D = scene.player
    enemy.global_position = scene.ground_at(scene.to_global(Vector2(340/.9,0)).x)-Vector2(0,15.55)
    player.global_position = enemy.global_position+Vector2(-70/.9,2.5)
    enemy.set_facing(1)
    player.facing_direction = 1
    player.get_node("Combat").set_facing(1)
    player.get_node("VisualRoot").scale.x = 1
    player.get_node("VisualRoot").form.reset_tracking()
    var hit := HitContext.new()
    hit.attacker = player
    hit.base_damage = 1000
    enemy.health.receive_hit(hit)
    root.get_node("HitStop")._restore()
    for i in range(150): await process_frame
    var view: Node = enemy.get_node("ApresentadorPacote")
    if not view.active or view.current_anim != "morte" or view.frame_index != 7:
        printerr("Death photo did not reach the actual last package frame")
        quit(2)
        return
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var path := ProjectSettings.globalize_path(OUT+"morte_no_cemiterio_x1.png")
    var error := image.save_png(path)
    var metadata := {"scene":scene.scene_file_path,"viewport":[960,540],"zoom":.9,"art_scale":1,
        "animation":view.current_anim,"frame":view.frame_index,"enemy_hp":enemy.health.current_health,
        "feet_screen":[view.global_position.x,view.global_position.y],
        "method":"Photo only: actors stationary, death triggered through Health.receive_hit; no production edits."}
    var file := FileAccess.open(OUT+"FOTO_METADADOS.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(metadata)+"\n")
    print("FOTO_RESULT ",JSON.stringify(metadata))
    quit(0 if error == OK else 2)
