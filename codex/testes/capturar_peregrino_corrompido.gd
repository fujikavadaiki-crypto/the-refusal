extends SceneTree

## Reproducible 20 s capture: original AI, real Input and resolved damage.
## One Peregrino encounter; only the player is positioned at the start.
const OUT := "res://codex/evidencias_peregrino_corrompido/"
var scene: Node2D
var frame := 0
var captured := 0
var recording := false
var dry := false
var photos := false
var stage := -1
var photo_queue := ""
var held := {}
var release_at := {}
var events: Array = []
var trace: Array = []
var shots := {}
var stats := {"hits": {}, "incoming_damage": 0, "enemy_deaths": [], "animations": {}, "max_ghosts": 0}
var retreating := false
var move_started := -1000
var move_index := 0
var next_attack := 0
var hitstop_count := 0
var hitstop_until := 0

func _initialize() -> void:
    dry = OS.get_cmdline_user_args().has("--dry-run")
    photos = OS.get_cmdline_user_args().has("--photos")
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
    root.get_node("Sensacao").set_all(true)
    root.get_node("Sensacao").set_process_input(false)
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
    scene.player.get_node("Defense").parry_succeeded.connect(func(c): events.append({"frame":frame,"event":"parry","attack":String(c.attack_id)}))
    scene.player.get_node("Health").damage_taken.connect(func(c): stats.incoming_damage += c.actual_damage)
    for enemy in scene.enemies:
        enemy.get_node("Health").depleted.connect(func(): stats.enemy_deaths.append(String(enemy.name)))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "capturas"))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/peregrino_corrompido_47/capture_frames"))
    if not dry:
        RenderingServer.frame_post_draw.connect(capture)
    if photos:
        for e in scene.enemies: freeze(e)
        freeze(scene.player)
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
    var p: CharacterBody2D = scene.player
    var enemy: CharacterBody2D = scene.enemies[0]
    var combat: PlayerCombat = p.get_node("Combat")
    var defense: PlayerDefense = p.get_node("Defense")
    if photos:
        photo_timeline()
    else:
        if frame == 0: segment(0)
        # Observe the real five-attack AI cycle, defending with timed parries.
        # Then close out with a real combo/heavy; no direct damage or HP edits.
        var dx := enemy.global_position.x - p.global_position.x
        var facing := -1 if dx < 0 else 1
        var distance := absf(dx)*.9
        var alive: bool = enemy.health.current_health > 0 and p.get_node("Health").current_health > 0
        var ready := not combat.is_busy() and defense.mode == PlayerDefense.Mode.READY
        if distance < 22: retreating = true
        if distance >= 31: retreating = false
        var walking: bool = alive and ready and (retreating or distance > 32 or p.facing_direction != facing)
        var move_facing := -facing if retreating else facing
        action("move_right",walking and move_facing > 0)
        action("move_left",walking and move_facing < 0)
        if frame == 40: pulse("jump",25)
        if frame == 60: pulse("dodge")
        var data: AttackData = enemy.attack.current_attack
        if alive and ready and data != null and enemy.attack.phase == PeregrinoAttack.Phase.WINDUP and enemy.attack.elapsed >= data.windup_seconds-.055:
            if data.parry_class == &"parryable": pulse("parry")
            else: pulse("dodge")
        if alive and ready and distance < 32 and frame > 800 and frame >= next_attack:
            pulse("attack_heavy" if move_index % 2 else "attack_light")
            move_index += 1
            next_attack = frame + 70
    var presenter: Node = p.get_node("VisualRoot").form
    stats.animations[presenter.anim_id] = int(stats.animations.get(presenter.anim_id, 0)) + 1
    stats.max_ghosts = maxi(stats.max_ghosts, presenter.ghosts.size())
    scene.debug_geometry = photos and stage < 6
    root.get_node("Sensacao").debug_controls = scene.debug_geometry
    scene.queue_redraw()
    frame += 1
    if dry and frame % 2 == 0:
        collect_trace()
        captured += 1
    if dry and frame >= (810 if photos else 1200):
        finish()
    return false

func collect_trace() -> void:
    var p: CharacterBody2D = scene.player
    var form: Node = p.get_node("VisualRoot").form
    var enemies := []
    for enemy in scene.enemies:
        enemies.append({"name": String(enemy.name), "health": enemy.get_node("Health").current_health, "state": enemy.get_node("Brain").state, "position":[enemy.position.x,enemy.position.y]})
    trace.append({"png": captured, "video_s": captured / 30.0, "position": [p.position.x, p.position.y], "animation": form.anim_id, "frame": form.frame_index, "shadow": form.shadow.visible, "legacy_shadow": scene.get_node("ContactShadow").visible, "ghosts": form.ghosts.size(), "hp": p.get_node("Health").current_health, "particles": root.get_node("Sensacao").pixels.particles.size(), "camera_px": [scene.camera.offset.x*.9, scene.camera.offset.y*.9], "landing_px": p.get_meta("landing_offset_px", 0), "flashes": scene.enemies.map(func(e): return e.get_node("SensacaoAlvo").flash_frames), "enemies": enemies, "peregrino_anim":scene.enemies[0].get_node("ApresentadorPacote").current_anim,"peregrino_frame":scene.enemies[0].get_node("ApresentadorPacote").frame_index})

func capture() -> void:
    if not recording or frame % 2 != 0 or captured >= 600:
        return
    var image := root.get_texture().get_image()
    if image.is_empty():
        quit(2)
        return
    if photos:
        if not photo_queue.is_empty():
            image.save_png(ProjectSettings.globalize_path(OUT + "capturas/" + photo_queue + ".png"))
            shots[photo_queue] = {"frame":frame,"anim":scene.enemies[0].get_node("ApresentadorPacote").current_anim,"sprite_frame":scene.enemies[0].get_node("ApresentadorPacote").frame_index}
            photo_queue = ""
        if frame >= 810: finish()
        return
    image.save_png(ProjectSettings.globalize_path("res://.godot/peregrino_corrompido_47/capture_frames/%05d.png" % captured))
    collect_trace()
    var view: Node = scene.enemies[0].get_node("ApresentadorPacote")
    for id in ["idle","ruptura","morte"]:
        if view.current_anim == id and (id != "morte" or view.frame_index == 7) and not shots.has(id):
            image.save_png(ProjectSettings.globalize_path(OUT + "capturas/combate_%s.png" % id))
            shots[id] = true
    captured += 1
    if captured >= 600: finish()

func freeze(n: Node) -> void:
    n.set_physics_process(false)
    for child in n.get_children(): freeze(child)

func photo_timeline() -> void:
    var next_stage := mini(8,frame/90)
    var e: CharacterBody2D = scene.enemies[0]
    var v: Node = e.get_node("ApresentadorPacote")
    var p: CharacterBody2D = scene.player
    if next_stage != stage:
        stage = next_stage
        e.reset_enemy()
        p.get_node("Health").reset_health()
        p.get_node("Posture").reset_posture()
        p.get_node("SensacaoAlvo").reset()
        e.global_position = scene.ground_at(scene.to_global(Vector2(340/.9,0)).x)-Vector2(0,15.55)
        p.global_position = e.global_position+Vector2(-70/.9,2.5)
        e.set_facing(-1)
        p.facing_direction=1
        p.get_node("Combat").set_facing(1)
        p.get_node("VisualRoot").scale.x=1
        var form: Node = p.get_node("VisualRoot").form
        form.reset_tracking()
        var choices := ["corte","estocada","corte_duplo_1","corte_duplo_2","investida","penitencia"]
        if stage < 6:
            e.attack.start(e.attack.get(choices[stage]))
            events.append({"event":"photo_attack","attack":choices[stage],"frame":frame})
        elif stage < 8:
            var c := HitContext.new()
            c.attacker=p
            c.base_damage=1 if stage == 6 else 1000
            c.posture_damage=40 if stage == 6 else 0
            e.health.receive_hit(c)
            events.append({"event":"photo_state_callback","state":"ruptura" if stage == 6 else "morte","frame":frame})
    if stage < 6:
        var data: AttackData = e.attack.current_attack
        if data != null:
            e.attack.tick(1.0/60, p,5)
            e.attack.resolve_frame_contact()
            var suffix: String = ["corte","estocada","corte_duplo_1","corte_duplo_2","investida","penitencia"][stage]
            if e.attack.phase == PeregrinoAttack.Phase.WINDUP and e.attack.elapsed >= data.windup_seconds*.7 and not shots.has("aviso_"+suffix): photo_queue="aviso_"+suffix
            if e.attack.phase == PeregrinoAttack.Phase.ACTIVE and e.attack.elapsed >= data.windup_seconds+data.active_seconds*.55 and not shots.has("F3_"+suffix): photo_queue="F3_"+suffix
    elif frame%90 == 75:
        photo_queue="ruptura_x1" if stage==6 else ("morte_x1" if stage==7 else "escala_x1")

func finish() -> void:
    recording = false
    for id in held.keys():
        Input.action_release(id)
    root.get_node("HitStop")._restore()
    var verified: bool = shots.size() == 15 if photos else stats.hits.has("Peregrino")
    var metadata := {"duration_s": captured / 30.0, "photos":photos, "shots":shots, "fps": 30, "frames": captured, "viewport": [960, 540], "dry_run": dry, "real_combat_verified": verified and not photos, "photos_verified":verified and photos, "stats": stats, "feel_groups": root.get_node("Sensacao").groups, "pixel_emissions": root.get_node("Sensacao").pixels.emissions, "method": "Clipe: entradas programadas, IA e dano reais, encontro Peregrino; jogador posicionado ao início. Fotos: inimigo imóvel, ataques originais, morte/ruptura acionadas pelos callbacks de dano para revisão visual. Hitstop virtual 60 Hz só na exportação."}
    for pair in [["CLIPE_TRACE.json", trace], ["CLIPE_INPUTS.json", events], ["CLIPE_METADADOS.json", metadata]]:
        var name_: String = ("FOTOS_" if photos else ("SECO_" if dry else "")) + pair[0]
        var file := FileAccess.open(OUT + name_, FileAccess.WRITE)
        file.store_string(JSON.stringify(pair[1]) + "\n")
    print("CAPTURE_RESULT ", JSON.stringify(metadata))
    quit(0 if verified else 2)
