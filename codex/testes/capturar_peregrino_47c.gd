extends SceneTree

## Actual patrol/chase AI and actual player Input, 20 s at fixed 60 Hz.
## Player placed twice (start, start of chase take); no enemy state/tuning
## overrides during the movie. Static photos follow after the recording.
const OUT := "res://codex/evidencias_peregrino_47c/"
var scene: Node2D
var enemy: CharacterBody2D
var frame := 0
var captured := 0
var recording := false
var dry := false
var finishing := false
var held := {}
var releases := {}
var direction := 1
var dash_at := -1
var next_turn := 0
var trace: Array = []
var events: Array = []
var state_counts := {}
var phase_frames := {}
var label: Label

func _initialize() -> void:
    dry = OS.get_cmdline_user_args().has("--dry-run")
    call_deferred("start")

func start() -> void:
    for action in InputMap.get_actions():
        InputMap.action_erase_events(action)
        Input.action_release(action)
    scene = load("res://scenes/biomes/cemiterio/sala_cemiterio.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    root.size = Vector2i(960,540)
    scene.set_process_unhandled_key_input(false)
    root.get_node("IntegrationRooms").set_process_unhandled_key_input(false)
    root.get_node("Sensacao").set_process_input(false)
    root.get_node("Sensacao").debug_controls = false
    while not scene.enemies_ready: await physics_frame
    await physics_frame
    enemy = scene.enemies[0]
    place_player(scene.to_global(Vector2(115/.9,0)).x)
    var layer := CanvasLayer.new()
    layer.layer = 19
    scene.add_child(layer)
    label = Label.new()
    label.position = Vector2(12,150)
    label.add_theme_color_override("font_color",Color(1,.9,.65))
    label.add_theme_color_override("font_outline_color",Color.BLACK)
    label.add_theme_constant_override("outline_size",2)
    layer.add_child(label)
    if not dry:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/peregrino_47c/capture_frames"))
        RenderingServer.frame_post_draw.connect(capture)
    recording = true

func place_player(x: float) -> void:
    var p: CharacterBody2D = scene.player
    p.global_position = scene.ground_at(x)-Vector2(0,13.1)
    p.velocity = Vector2.ZERO
    p.get_node("Locomotion").reset_assists()
    p.get_node("VisualRoot").form.reset_tracking()
    events.append({"tick":frame,"event":"player_take_start","position":[p.global_position.x,p.global_position.y]})

func action(id: String,pressed: bool) -> void:
    if held.get(id,false)==pressed: return
    held[id]=pressed
    if pressed: Input.action_press(id)
    else: Input.action_release(id)

func pulse(id: String,ticks := 2) -> void:
    action(id,true)
    releases[id]=frame+ticks

func _process(_delta: float) -> bool:
    if not recording: return false
    for id in releases.keys():
        if frame>=releases[id]:
            action(id,false)
            releases.erase(id)
    if frame==480:
        place_player(enemy.global_position.x+120/.9)
        events.append({"tick":frame,"event":"chase_take","enemy_state_unchanged":enemy.brain.state})
    label.text = "PATRULHA" if frame<480 else "PERSEGUIÇÃO"
    if frame>=480:
        var x: float = scene.to_local(scene.player.global_position).x*.9
        if frame>=next_turn and ((direction>0 and x>=480) or (direction<0 and x<=200)):
            direction = -direction
            pulse("jump",28)
            dash_at = frame+10
            next_turn = frame+90
        action("move_right",direction>0)
        action("move_left",direction<0)
        action("walk",true)
        if frame==dash_at: pulse("dodge")
    if dry and frame%2==0:
        collect_trace()
        captured+=1
    frame+=1
    if dry and frame>=1200: finish.call_deferred()
    return false

func collect_trace() -> void:
    var v: Node = enemy.get_node("ApresentadorPacote")
    var state := String(PeregrinoBrain.State.keys()[enemy.brain.state])
    state_counts[state]=int(state_counts.get(state,0))+1
    var key: String = v.current_anim+"_"+str(v.frame_index)
    phase_frames[key]=int(phase_frames.get(key,0))+1
    var canvas := root.get_canvas_transform()
    var feet: Vector2 = canvas*(enemy.global_position+v.feet_local)
    trace.append({"tick":frame,"state":state,"anim":v.current_anim,"frame":v.frame_index,
      "facing":enemy.facing_direction,"x_world":enemy.global_position.x,"y_world":enemy.global_position.y,
      "vx":enemy.velocity.x,"on_floor":enemy.is_on_floor(),"motion_px":v.motion_px,
      "feet_viewport":[roundi(feet.x),roundi(feet.y)],"player_hp":scene.player.get_node("Health").current_health})

func capture() -> void:
    if not recording or frame%2!=0 or captured>=600: return
    var image := root.get_texture().get_image()
    image.save_png(ProjectSettings.globalize_path("res://.godot/peregrino_47c/capture_frames/%05d.png"%captured))
    collect_trace()
    captured+=1
    if captured==600: finish.call_deferred()

func freeze(n: Node) -> void:
    n.set_physics_process(false)
    for child in n.get_children(): freeze(child)

func finish() -> void:
    if finishing: return
    finishing = true
    recording = false
    for id in held: Input.action_release(id)
    var walking := int(state_counts.get("PATROL",0))>=120 and int(state_counts.get("CHASE",0))>=120
    var all_frames := true
    for anim in ["patrulha","perseguicao"]:
        for i in range(8):
            if not phase_frames.has(anim+"_"+str(i)): all_frames=false
    var feet_visible := true
    for row in trace:
        if row.anim in ["patrulha","perseguicao"] and (row.feet_viewport[0]<40 or row.feet_viewport[0]>900 or row.feet_viewport[1]<180 or row.feet_viewport[1]>470):feet_visible=false
    var metadata := {"seconds":20,"fps":30,"frames":captured,"viewport":[960,540],"dry":dry,
      "state_counts":state_counts,"all_8_frames_each_march":all_frames,"feet_in_view":feet_visible,
      "ai_and_tuning_original":true,"player_take_start_count":2,"events":events,
      "method":"Actual original AI, player Input; player placed at the start of each take (8 s patrol + 12 s chase). Photos separately pose the stationary package after the movie."}
    var f := FileAccess.open(OUT+("SECO_" if dry else "")+"CLIPE_METADADOS.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(metadata)+"\n")
    f=FileAccess.open(OUT+("SECO_" if dry else "")+"CLIPE_TRACE.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(trace)+"\n")
    print("CAPTURE_RESULT ",JSON.stringify(metadata))
    if not dry:
        # Only the static photo fixture selects a pose. Movie trace above
        # contains the untouched brain and real movement for all 600 frames.
        for actor in scene.enemies: freeze(actor)
        freeze(scene.player)
        root.get_node("HitStop")._restore()
        enemy.attack.abort()
        enemy.global_position=scene.ground_at(scene.to_global(Vector2(340/.9,0)).x)-Vector2(0,15.55)
        scene.player.global_position=enemy.global_position+Vector2(-80/.9,2.5)
        scene.player.get_node("VisualRoot").form.reset_tracking()
        enemy.set_facing(1)
        enemy.brain.state=PeregrinoBrain.State.PATROL
        var v: Node=enemy.get_node("ApresentadorPacote")
        v.motion_px=0
        v.last_actor_x=enemy.global_position.x
        label.text="MARCHA — QUADRO 0"
        for i in range(60):await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"marcha_na_sala_x1.png"))
        scene.debug_geometry=true
        root.get_node("Sensacao").debug_controls=true
        scene.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"F3_marcha.png"))
    quit(0 if walking and all_frames and feet_visible and captured==600 else 2)
