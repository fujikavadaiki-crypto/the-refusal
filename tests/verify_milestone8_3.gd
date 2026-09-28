extends SceneTree

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
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


func run_checks() -> void:
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/carrasco_base_gameplay/frames.json"))
    var animations: Dictionary = manifest["animations"]
    var total := 0
    for ids in animations.values():
        total += ids.size()
    check(manifest["body_height"] == 31 and is_equal_approx(31.0 / 27.0, 1.1481481), "native body is 31 px versus 27 px human visual")
    check(manifest["tile_width"] == 64 and manifest["tile_height"] == 48 and total == 104, "104 native-size frames with fixed 64x48 cells")
    var expected := {
        "idle": 4, "run": 6, "jump": 2, "fall": 2, "ground_dash": 3, "air_dash": 3,
        "carrasco_light_1": 4, "carrasco_light_2": 4, "carrasco_light_3": 4,
        "carrasco_heavy": 6, "charge": 4, "charge_ready": 2, "carrasco_charged_heavy": 6,
        "carrasco_post_dodge": 4, "carrasco_air_light": 4, "carrasco_air_heavy": 5,
        "carrasco_quebra_selos": 5, "carrasco_marca": 4, "tribunal_activate": 4,
        "execution": 8, "execution_strike": 6, "hit": 3, "ruptured": 3, "death": 5, "parry": 3
    }
    for animation in expected:
        check(animations.has(animation) and animations[animation].size() == expected[animation], "frames for %s" % animation)
    var atlas_image := Image.load_from_file("res://assets/characters/carrasco_base_gameplay/atlas.png")
    for animation in ["idle", "run", "carrasco_light_1", "carrasco_light_2", "carrasco_light_3", "carrasco_heavy"]:
        var signatures := {}
        for raw_index in animations[animation]:
            var index: int = raw_index
            var cell := atlas_image.get_region(Rect2i((index % 10) * 64, (index / 10) * 48, 64, 48))
            signatures[hash(cell.get_data())] = true
        check(signatures.size() == animations[animation].size(), "%s uses distinct authored frames" % animation)

    var arena := load("res://scenes/test/carrasco_arena.tscn").instantiate() as Node2D
    root.add_child(arena)
    arena.get_node("Peregrino").process_mode = Node.PROCESS_MODE_DISABLED
    await frames(5)
    var player := arena.get_node("TestRoom/Player") as CharacterBody2D
    var visual := player.get_node("VisualRoot") as PlayerVisualController
    var combat := player.get_node("Combat") as PlayerCombat
    var masks := player.get_node("MaskController") as MaskController
    var dummy := arena.get_node("TestRoom/Dummy") as Node2D
    # Exercise the preserved legacy atlas explicitly; gameplay uses the modular rig.
    visual.modular_carrasco_enabled = false
    visual._on_mask_changed(masks.active_data())
    var sprite := visual.form.sprite as Sprite2D
    check(sprite.scale == Vector2.ONE and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and sprite.offset == Vector2(-28, -54) and sprite.position == Vector2(0, 13), "approved idle GIF uses native pixels and shares the body's ground plane")
    check(sprite.texture is Texture2D and sprite.texture.get_size() == Vector2(56, 56), "runtime displays the native 56x56 idle frame")
    check(visual.form.frame_textures.size() == expected.size(), "all authored actions are available to the interchangeable Mask visual")
    check((player.get_node("CollisionShape2D") as CollisionShape2D).shape.height == 64.0, "body collider matches the modular silhouette")
    check(not combat.hitbox.active, "hitbox starts inactive")
    Input.action_press("attack_light")
    await frames(2)
    Input.action_release("attack_light")
    var windup_texture := sprite.texture
    check(combat.phase == PlayerCombat.Phase.WINDUP and not combat.hitbox.active, "visual windup keeps hitbox inactive")
    await frames(10)
    check(combat.phase == PlayerCombat.Phase.ACTIVE and combat.hitbox.active and sprite.texture != windup_texture, "distinct active frame follows existing attack timing")
    combat.abort_attack()
    await frames(2)

    var state := masks.active_state() as CarrascoRuntimeState
    state.ultimate_remaining = 4.0
    await frames(2)
    check(visual.form.tribunal and visual._state_name() == &"tribunal_activate", "Tribunal has a short activation animation")
    await frames(18)
    check(visual.form.tribunal and visual._state_name() != &"tribunal_activate", "Tribunal returns to ordinary combat poses with aura")
    state.end_ultimate()
    await frames(2)
    visual._on_execution(dummy, ExecutionResolver.Result.STRIKE)
    await frames(2)
    check(visual._state_name() == &"execution_strike", "elite Execution Strike has a separate nonlethal visual")
    masks.activate_slot_for_setup(1)
    await frames(2)
    check(visual.form == null and visual.get_node("Head").visible, "empty slot retains human visual")
    masks.activate_slot_for_setup(0)
    await frames(2)
    check(visual.form != null and visual.form.sprite.texture is AtlasTexture, "Carrasco visual reloads after swap")

    var toggle := InputEventKey.new()
    toggle.keycode = KEY_F3
    toggle.pressed = true
    arena._unhandled_key_input(toggle)
    check(not arena.get_node("TechnicalHUD").visible, "F3 hides technical HUD")
    arena._unhandled_key_input(toggle)
    check(arena.get_node("TechnicalHUD").visible, "F3 restores technical HUD")

    var moves := [
        [CARRASCO.light_1, 30, 16], [CARRASCO.light_2, 34, 18], [CARRASCO.light_3, 44, 28],
        [CARRASCO.heavy, 58, 42], [CARRASCO.heavy.charged_variant, 78, 65],
        [CARRASCO.post_dodge, 32, 18], [CARRASCO.air_light, 34, 22],
        [CARRASCO.air_heavy, 52, 45], [CARRASCO.skill_1, 50, 70]
    ]
    for move in moves:
        check(move[0].base_damage == move[1] and move[0].posture_damage == move[2], "unchanged damage and Posture for %s" % move[0].attack_id)
    arena.queue_free()
    await frames(2)
    print("MILESTONE 8.3: ", "FAIL" if failed else "PASS")
    quit(1 if failed else 0)
