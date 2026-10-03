extends SceneTree

## Reproducible 30 s capture: original AI, real Input and resolved damage.
## Three 10 s encounters; only the player is repositioned between encounters.
const OUT := "res://codex/evidencias_integracao_p40_f4/"
var scene: Node2D
var frame := 0
var captured := 0
var recording := false
var dry := false
var held := {}
var release_at := {}
var events: Array = []
var trace: Array = []
var shots := {}
var stats := {"hits": {}, "incoming_damage": 0, "enemy_deaths": [], "animations": {}, "max_ghosts": 0}
var move_started := -1000
var move_index := 0
var next_attack := 0
var hitstop_count := 0
var hitstop_until := 0

func _initialize() -> void:
    dry = OS.get_cmdline_user_args().has("--dry-run")
    call_deferred("start")

func start() -> void:
    # The export's Input timeline is exclusive; live keyboard/gamepad events
    # must not change an automated recording while this window is open.
    for id in InputMap.get_actions():
        InputMap.action_erase_events(id)
        Input.action_release(id)
    scene = load("res://scenes/biomes/cemiterio/sala_cemiterio.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    scene.set_process_unhandled_key_input(false)
    root.get_node("IntegrationRooms").set_process_unhandled_key_input(false)
    root.size = Vector2i(960, 540)
    while not scene.enemies_ready:
        await physics_frame
    await physics_frame
    if not dry and DisplayServer.get_name() == "headless":
        printerr("Capture requires the rendered viewport.")
        quit(2)
        return
    root.get_node("HitStop").process_priority = 1000
    scene.player.get_node("Combat").hit_confirmed.connect(on_hit)
    scene.player.get_node("Health").damage_taken.connect(func(c): stats.incoming_damage += c.actual_damage)
    for enemy in scene.enemies:
        enemy.get_node("Health").depleted.connect(func(): stats.enemy_deaths.append(String(enemy.name)))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "capturas"))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/p40_runtime_f4/capture_frames"))
    if not dry:
        RenderingServer.frame_post_draw.connect(capture)
    recording = true
    events.append({"frame": 0, "event": "start", "scene": scene.scene_file_path})

func action(id: String, pressed: bool) -> void:
    if held.get(id, false) == pressed:
        return
    held[id] = pressed
    if pressed:
        Input.action_press(id)
    else:
        Input.action_release(id)
    events.append({"frame": frame, "action": id, "pressed": pressed})

func pulse(id: String, ticks := 2) -> void:
    action(id, true)
    release_at[id] = frame + ticks

func on_hit(context: HitContext) -> void:
    if context.outcome not in [HitContext.Outcome.DAMAGED, HitContext.Outcome.DEAD]:
        return
    var key := String(context.target.name)
    stats.hits[key] = int(stats.hits.get(key, 0)) + 1
    events.append({"frame": frame, "event": "hit", "target": key, "attack": String(context.attack_id), "damage": context.actual_damage, "active_frame": scene.player.get_node("Combat").frame_hitbox_frame})

func segment(index: int) -> void:
    for id in held.keys():
        action(id, false)
    release_at.clear()
    var enemy: CharacterBody2D = scene.enemies[index]
    var p: CharacterBody2D = scene.player
    p.get_node("Combat").abort_attack()
    p.clear_action_buffers()
    p.get_node("Health").reset_health()
    p.get_node("Posture").reset_posture()
    var defense: PlayerDefense = p.get_node("Defense")
    defense.mode = PlayerDefense.Mode.READY
    defense.elapsed = 0
    defense.dodge_cooldown = 0
    defense.air_dash_available = true
    var x := enemy.global_position.x - 95
    p.global_position = scene.ground_at(x) - Vector2(0, 13.1)
    p.velocity = Vector2.ZERO
    p.facing_direction = 1
    p.get_node("VisualRoot").scale.x = 1
    p.get_node("Combat").set_facing(1)
    defense.set_facing(1)
    p.get_node("Locomotion").reset_assists()
    p.get_node("VisualRoot").form.reset_tracking()
    next_attack = frame + 50
    move_started = -1000
    move_index = 0
    events.append({"frame": frame, "event": "next_encounter", "target": String(enemy.name), "player_position": [p.position.x, p.position.y]})

func virtual_hitstop() -> void:
    # Fixed export: real-time hitstop is represented by the same number of
    # 60 Hz wall-clock frames. Production HitStop code stays unmodified.
    var stop: Node = root.get_node("HitStop")
    if stop.request_count != hitstop_count:
        hitstop_count = stop.request_count
        hitstop_until = maxi(hitstop_until, frame + int(ceil(stop.last_requested_ms * .06)))
    if stop.active:
        if frame >= hitstop_until:
            stop._restore()
        else:
            stop.end_tick_usec = Time.get_ticks_usec() + 3600000000

func _process(_delta: float) -> bool:
    if not recording:
        return false
    virtual_hitstop()
    for id in release_at.keys():
        if InputMap.has_action(id) and frame >= release_at[id]:
            action(id, false)
            release_at.erase(id)
    if frame == 600:
        segment(1)
    elif frame == 1200:
        segment(2)
    var p: CharacterBody2D = scene.player
    var combat: PlayerCombat = p.get_node("Combat")
    var defense: PlayerDefense = p.get_node("Defense")
    var section := mini(2, frame / 600)
    var enemy: CharacterBody2D = scene.enemies[section]
    if frame < 230:
        action("move_right", frame >= 35 and frame < 200)
        if frame == 70:
            pulse("jump", 10)
        elif frame == 88:
            pulse("dodge")
        if frame == 205:
            pulse("parry", 2)
    elif p.get_node("Health").current_health > 0 and enemy.get_node("Health").current_health > 0:
        var dx := enemy.global_position.x - p.global_position.x
        var facing := -1 if dx < 0 else 1
        var distance := absf(dx) * .9
        var ready := not combat.is_busy() and defense.mode == PlayerDefense.Mode.READY
        if ready:
            var walking: bool = distance > 37 or p.facing_direction != facing
            action("move_right", walking and facing > 0)
            action("move_left", walking and facing < 0)
            if not walking and frame >= next_attack:
                move_started = frame
                # Normal heavy, combo, aerial, charge. No direct health edits.
                if section == 1 and move_index % 2 == 0:
                    pulse("jump", 10)
                    release_at["air_attack"] = frame + 14
                    next_attack = frame + 100
                elif move_index % 4 == 0:
                    pulse("attack_heavy")
                    next_attack = frame + 70
                elif move_index % 4 == 1:
                    pulse("attack_light")
                    release_at["combo2"] = frame + 23
                    release_at["combo3"] = frame + 48
                    next_attack = frame + 100
                elif move_index % 4 == 2:
                    pulse("attack_heavy", 70)
                    next_attack = frame + 150
                else:
                    pulse("jump", 10)
                    release_at["air_attack"] = frame + 13
                    next_attack = frame + 90
                move_index += 1
        else:
            action("move_left", false)
            action("move_right", false)
        if release_at.has("air_attack") and frame >= release_at.air_attack:
            release_at.erase("air_attack")
            pulse("attack_heavy")
        if release_at.has("combo2") and frame >= release_at.combo2:
            release_at.erase("combo2")
            pulse("attack_light")
        if release_at.has("combo3") and frame >= release_at.combo3:
            release_at.erase("combo3")
            pulse("attack_light")
    else:
        action("move_left", false)
        action("move_right", false)
    var presenter: Node = p.get_node("VisualRoot").form
    stats.animations[presenter.anim_id] = int(stats.animations.get(presenter.anim_id, 0)) + 1
    stats.max_ghosts = maxi(stats.max_ghosts, presenter.ghosts.size())
    scene.debug_geometry = frame % 600 >= 300 and frame % 600 < 375
    scene.queue_redraw()
    frame += 1
    if dry and frame % 2 == 0:
        collect_trace()
        captured += 1
    if dry and frame >= 1800:
        finish()
    return false

func collect_trace() -> void:
    var p: CharacterBody2D = scene.player
    var form: Node = p.get_node("VisualRoot").form
    var enemies := []
    for enemy in scene.enemies:
        enemies.append({"name": String(enemy.name), "health": enemy.get_node("Health").current_health, "state": enemy.get_node("Brain").state})
    trace.append({"png": captured, "video_s": captured / 30.0, "position": [p.position.x, p.position.y], "animation": form.anim_id, "frame": form.frame_index, "shadow": form.shadow.visible, "legacy_shadow": scene.get_node("ContactShadow").visible, "ghosts": form.ghosts.size(), "hp": p.get_node("Health").current_health, "enemies": enemies})

func capture() -> void:
    if not recording or frame % 2 != 0 or captured >= 900:
        return
    var image := root.get_texture().get_image()
    if image.is_empty():
        quit(2)
        return
    image.save_png(ProjectSettings.globalize_path("res://.godot/p40_runtime_f4/capture_frames/%05d.png" % captured))
    collect_trace()
    var key := "escala_%s" % scene.enemies[mini(2, (frame - 1) / 600)].name
    if frame % 600 > 50 and not shots.has(key):
        image.save_png(ProjectSettings.globalize_path(OUT + "capturas/%s.png" % key))
        shots[key] = true
    if frame % 600 >= 315 and frame % 600 < 370:
        var debug_key := "F3_%s" % scene.enemies[mini(2, (frame - 1) / 600)].name
        if not shots.has(debug_key):
            image.save_png(ProjectSettings.globalize_path(OUT + "capturas/%s.png" % debug_key))
            shots[debug_key] = true
    captured += 1
    if captured >= 900:
        finish()

func finish() -> void:
    recording = false
    for id in held.keys():
        Input.action_release(id)
    root.get_node("HitStop")._restore()
    var verified: bool = stats.hits.has("Peregrino") and stats.hits.has("Corvo") and stats.hits.has("Raiz") and stats.incoming_damage > 0
    var metadata := {"duration_s": captured / 30.0, "fps": 30, "frames": captured, "viewport": [960, 540], "dry_run": dry, "real_combat_verified": verified, "stats": stats, "method": "Inputs programados; IA e dano reais, jogador reposicionado entre 3 encontros de 10 s, sem ajuste de IA ou dano artificial; hitstop em relógio virtual 60 Hz só na exportação."}
    for pair in [["CLIPE_TRACE.json", trace], ["CLIPE_INPUTS.json", events], ["CLIPE_METADADOS.json", metadata]]:
        var name_: String = ("SECO_" if dry else "") + pair[0]
        var file := FileAccess.open(OUT + name_, FileAccess.WRITE)
        file.store_string(JSON.stringify(pair[1], "  ") + "\n")
    print("CAPTURE_RESULT ", JSON.stringify(metadata))
    quit(0 if verified else 2)
