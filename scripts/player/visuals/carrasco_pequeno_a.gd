extends Node2D

const PACKAGE := preload("res://scripts/player/visuals/carrasco_p42b_package.gd")

## Production adapter for Pequeno A v34A, based on the read-only P40 presenter.
## World CanvasItem (foreground occlusion preserved); inverse canvas transform
## keeps native pixels ×1 even in rooms with a different zoom. Only flip_h faces.
## Apresentador único do Pequeno A. Desenha em pixels de tela, ×1,
## NEAREST, âncora arredondada nos pés, espelhamento pela âncora e sombra no chão.
## O quadro de corrida vem da DISTÂNCIA percorrida (nunca de um relógio):
##   quadro = floor(distância_px / px_por_quadro) mod n
## Os golpes com arte seguem o tempo do ataque (windup/ativo/recuperação), e o
## quadro exibido em cada tick é o mesmo que fornece a área de dano.

const FEET_LOCAL := Vector2(0, 13)
const ZOOM := 0.9
const HURT_SECONDS := 0.18
const LAND_SECONDS := 0.12
const SUPPORT_HOLD_TICKS := 2
# P41: fluidez (pequeno A v3.2).
const TURN_SECONDS := 0.05
const EXIT_SECONDS := 0.066
const STOP_SECONDS := 0.066   # freio da corrida (run_stop), contado depois do quadro de apoio
const SPARK_SECONDS := 0.16
const GHOST_INTERVAL := 0.04
const GHOST_LIFE := 0.15   # padrão (v3.2A); pacotes novos trazem `rastro_dash` no manifesto
const GHOST_LIFE_SHORT := 0.10
const GHOST_ALPHA := 0.5
const GHOST_MAX := 4
const GHOST_MAX_SHORT := 2
const GHOST_COLOR := Color8(116, 3, 6)   # índice 22 da paleta C5.1
const POST_DASH_TRAIL_SECONDS := 0.13
const CHARGED_WINDUP_FRAME := 3
const AIR_HEAVY_HOLD_FRAME := 5
const SPARK_OFFSET := Vector2(25, -25)

var player: CharacterBody2D
var characters: Array[Dictionary] = []
var character: Dictionary = {}
var character_index := 0

var body := Sprite2D.new()
var shadow := Sprite2D.new()
var effect_nodes: Array[Sprite2D] = []
var ghost_nodes: Array[Sprite2D] = []
var spark := Sprite2D.new()

# P41: rastro do dash, faísca do parry e transições.
var ghosts: Array = []
var ghost_timer := 0.0
var ghost_cache := {}
var spark_remaining := 0.0
var ground_time := 0.0
var run_start_px := 999.0
var turn_remaining := 0.0
var exit_remaining := 0.0
var stop_remaining := 0.0
var prev_facing := 1
var prev_candidate := "idle"
var prev_attack := ""
var charge_peak := 0.0

var visual_state := "idle"
var anim_id := "idle"
var frame_index := 0
var frame_spec: Dictionary = {}
var last_anchor := Vector2.ZERO
var damage_remaining := 0.0

# Corrida por distância.
var run_distance_px := 0.0
var previous_x := 0.0
var was_moving := false
var support_hold_ticks := 0
var support_frame := -1
var last_step_px := 0.0

# Voo/pouso.
var air_time := 0.0
var fall_time := 0.0
var land_remaining := 0.0
var was_grounded := true
var idle_time := 0.0

# Sombra.
var shadow_hit := false
var shadow_height_m := 0.0
var shadow_factor := 1.0
var shadow_ground_screen := Vector2.ZERO
var package_ready := false
var external_state: StringName = &"idle"


func bind_player(body_node: CharacterBody2D) -> void:
    var loaded: Array[Dictionary] = [PACKAGE.character()]
    top_level = true
    player = body_node
    package_ready = not loaded[0].is_empty()
    if not package_ready:
        return
    characters = loaded
    process_physics_priority = 20
    for node: Sprite2D in [shadow, body, spark]:
        node.centered = false
        node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    shadow.name = "SombraNoChao"
    body.name = "CorpoC52"
    # Ordem de baixo para cima: sombra, efeitos (atrás do corpo), corpo.
    add_child(shadow)
    for i in range(GHOST_MAX):
        var ghost := Sprite2D.new()
        ghost.name = "Fantasma%d" % i
        ghost.centered = false
        ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        ghost.visible = false
        add_child(ghost)
        ghost_nodes.append(ghost)
    var fx_count := 0
    for anim: Dictionary in loaded[0].anims.values():
        for frame: Dictionary in anim.frames:
            fx_count = maxi(fx_count, frame.efeitos.size())
    for i in range(fx_count):
        var fx := Sprite2D.new()
        fx.name = "Efeito%d" % i
        fx.centered = false
        fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(fx)
        effect_nodes.append(fx)
    add_child(body)
    spark.name = "FaiscaParry"
    spark.centered = false
    spark.visible = false
    add_child(spark)
    (player.get_node("Defense") as PlayerDefense).parry_succeeded.connect(func(_context): spark_remaining = SPARK_SECONDS)
    player.get_node("Health").damage_taken.connect(func(_hit): damage_remaining = HURT_SECONDS)
    previous_x = player.global_position.x
    set_character(0)


func bind_runtime(_runtime: MaskRuntimeState) -> void:
    pass


func set_pose(state: StringName, _phase: int, _progress: float, _charged: bool, _tribunal: bool) -> void:
    external_state = state
    sync(0.0)


func profiles_attack(attack_id: String) -> bool:
    return package_ready and character.ataque_anim.has(attack_id) and bool(character.anims[character.ataque_anim[attack_id]].has_damage)


func reset_tracking() -> void:
    if package_ready:
        set_character(0)


func _exit_tree() -> void:
    if is_instance_valid(player) and player.get_node("Combat").frame_provider == self:
        player.get_node("Combat").frame_provider = null
        player.set_meta("small_carrasco_presenter_active", false)


func set_character(index: int) -> void:
    character_index = posmod(index, characters.size())
    character = characters[character_index]
    run_distance_px = 0.0
    support_hold_ticks = 0
    support_frame = -1
    was_moving = false
    air_time = 0.0
    fall_time = 0.0
    land_remaining = 0.0
    damage_remaining = 0.0
    was_grounded = player.is_on_floor()
    idle_time = 0.0
    previous_x = player.global_position.x
    visual_state = "idle"
    reset_transients()
    # Faísca nova (arte) substitui o polígono antigo do parry.
    var legacy_spark := player.get_node_or_null("ParrySpark") as CanvasItem
    if legacy_spark != null:
        legacy_spark.modulate = Color(1, 1, 1, 0.0 if character.anims.has("parry_spark") else 1.0)
    sync(0.0)


func reset_transients() -> void:
    ghosts.clear()
    ghost_timer = 0.0
    spark_remaining = 0.0
    ground_time = 0.0
    run_start_px = 999.0
    turn_remaining = 0.0
    exit_remaining = 0.0
    stop_remaining = 0.0
    prev_candidate = "idle"
    prev_attack = ""
    charge_peak = 0.0
    prev_facing = int(player.get("facing_direction"))


# ---------------------------------------------------------------- estado

func _candidate_state() -> String:
    var defense: PlayerDefense = player.get_node("Defense")
    var combat: PlayerCombat = player.get_node("Combat")
    if defense.mode == PlayerDefense.Mode.DEAD:
        return "death"
    if defense.mode == PlayerDefense.Mode.STAGGERED:
        return "ruptured"
    if damage_remaining > 0.0:
        return "hit"
    if combat.is_charging():
        return "charge"
    if combat.current_attack != null:
        return String(combat.current_attack.attack_id)
    if defense.mode == PlayerDefense.Mode.AIR_DASH:
        return "air_dash"
    if defense.mode == PlayerDefense.Mode.DODGING:
        return "ground_dash"
    if defense.mode == PlayerDefense.Mode.PARRYING:
        return "parry"
    if not player.is_on_floor():
        return "jump" if player.velocity.y < 0.0 else "fall"
    if absf(player.velocity.x) < 0.001:
        if land_remaining > 0.0 and character.estado_anim.has("land"):
            return "land"
        return "idle"
    return "walk" if Input.is_action_pressed("walk") else "run"


func _has_state(state: String) -> bool:
    return character.estado_anim.has(state)


func _state_name() -> String:
    var candidate := _candidate_state()
    if candidate == "idle":
        if support_hold_ticks > 0:
            return "run"
        if stop_remaining > 0.0 and _has_state("run_stop"):
            return "run_stop"
        if exit_remaining > 0.0 and _has_state("attack_exit"):
            return "attack_exit"
    elif candidate == "run" or candidate == "walk":
        if turn_remaining > 0.0 and _has_state("turn"):
            return "turn"
        if support_hold_ticks == 0 and _has_state("run_start") and run_start_px < float(character.anims[character.estado_anim["run_start"]].frames.size()) * float(character.px_por_quadro):
            return "run_start"
    return candidate


func _physics_process(delta: float) -> void:
    if player == null or character.is_empty():
        return
    var x := player.global_position.x
    last_step_px = absf(x - previous_x) * ZOOM
    # Physics can never travel this far in one ordinary tick. Recovery/respawn
    # must reset the phase/trail rather than count a teleport as a stride.
    if last_step_px > 16.0:
        reset_tracking()
        last_step_px = 0.0
    previous_x = x
    var grounded := player.is_on_floor()
    if grounded and not was_grounded:
        land_remaining = LAND_SECONDS
    land_remaining = maxf(0.0, land_remaining - delta) if grounded else 0.0
    if not grounded:
        air_time += delta
        if player.velocity.y >= 0.0:
            fall_time += delta
        else:
            fall_time = 0.0
    else:
        air_time = 0.0
        fall_time = 0.0
    was_grounded = grounded
    damage_remaining = maxf(0.0, damage_remaining - delta)
    if support_hold_ticks > 0:
        support_hold_ticks -= 1
        if support_hold_ticks == 0 and support_frame >= 0:
            # Fase da corrida retomada a partir do apoio mostrado.
            run_distance_px = float(support_frame) * float(character.px_por_quadro)
            support_frame = -1
    var candidate := _candidate_state()
    _tick_transitions(delta, candidate, grounded)
    if candidate in ["run", "walk"]:
        run_distance_px += last_step_px
        was_moving = true
        support_hold_ticks = 0
        support_frame = -1
    else:
        if candidate == "idle" and was_moving:
            support_frame = nearest_support_frame()
            support_hold_ticks = SUPPORT_HOLD_TICKS
            was_moving = false
        elif candidate != "idle":
            was_moving = false
    if candidate == "idle" and not was_moving and support_hold_ticks == 0:
        idle_time += delta
    else:
        idle_time = 0.0


## P41: partida da corrida, virada, saída do ataque, rastro do dash e faísca.
func _tick_transitions(delta: float, candidate: String, grounded: bool) -> void:
    var combat: PlayerCombat = player.get_node("Combat")
    var running := candidate == "run" or candidate == "walk"
    var was_running := prev_candidate == "run" or prev_candidate == "walk"
    ground_time = ground_time + delta if grounded else 0.0
    spark_remaining = maxf(0.0, spark_remaining - delta)
    # Carga: guarda o maior tempo segurado (heavy solto depois mostra a pose carregada).
    if combat.is_charging():
        charge_peak = combat.charge_elapsed
    elif combat.current_attack == null:
        charge_peak = 0.0
    # Partida da corrida: só a partir do idle/pouso parado.
    if running and not was_running:
        run_start_px = 0.0 if (prev_candidate == "idle" or prev_candidate == "land") else 999.0
    if running:
        run_start_px += last_step_px
    # Virada de direção correndo.
    var facing := int(player.get("facing_direction"))
    turn_remaining = maxf(0.0, turn_remaining - delta)
    if running and was_running and grounded and facing != prev_facing:
        turn_remaining = TURN_SECONDS
    if not running:
        turn_remaining = 0.0
    prev_facing = facing
    # Freio da corrida: 1 quadro derrapando depois do quadro de apoio (só no chão).
    if candidate == "idle" and was_running and grounded:
        stop_remaining = STOP_SECONDS
    elif candidate == "idle":
        if support_hold_ticks == 0:
            stop_remaining = maxf(0.0, stop_remaining - delta)
    else:
        stop_remaining = 0.0
    # Saída do ataque (no chão, parado) -> 1 quadro de transição.
    var attack_id := String(combat.current_attack.attack_id) if combat.current_attack != null else ""
    if exit_remaining > 0.0:
        exit_remaining = maxf(0.0, exit_remaining - delta) if candidate == "idle" else 0.0
    if prev_attack != "" and attack_id == "" and candidate == "idle" and not prev_attack.contains("air"):
        exit_remaining = EXIT_SECONDS
    prev_attack = attack_id
    prev_candidate = candidate
    _tick_ghosts(delta, candidate, combat)


func _tick_ghosts(delta: float, candidate: String, combat: PlayerCombat) -> void:
    for ghost in ghosts:
        ghost.age = float(ghost.age) + delta
    ghosts = ghosts.filter(func(g): return float(g.age) < float(g.life))
    var dash := candidate == "ground_dash" or candidate == "air_dash"
    var post_dash := candidate == "carrasco_post_dodge" and combat.elapsed < POST_DASH_TRAIL_SECONDS
    if not (dash or post_dash) or not character.get("v32", false):
        ghost_timer = 0.0
        return
    ghost_timer -= delta
    if ghost_timer > 0.0:
        return
    ghost_timer = GHOST_INTERVAL
    var pose := pose_for(_state_name())
    var spec: Dictionary = character.anims[String(pose.anim)].frames[int(pose.frame)]
    ghosts.append({
        "tex": _silhouette(spec.tex),
        "ancora": spec.ancora,
        "flipped": int(player.get("facing_direction")) < 0,
        "world": player.global_position + FEET_LOCAL,
        "age": 0.0,
        "life": ghost_life(post_dash),
    })
    var limit := ghost_limit(post_dash)
    while ghosts.size() > limit:
        ghosts.remove_at(0)


## Parâmetros do rastro: vêm do manifesto do pacote (`rastro_dash`) ou, na falta, dos padrões da v3.2A.
func ghost_life(short: bool) -> float:
    var trail: Dictionary = character.get("rastro", {})
    return float(trail.get("vida_curta_s", GHOST_LIFE_SHORT)) if short else float(trail.get("vida_s", GHOST_LIFE))


func ghost_limit(short: bool) -> int:
    var trail: Dictionary = character.get("rastro", {})
    return int(trail.get("maximo_curto", GHOST_MAX_SHORT)) if short else int(trail.get("maximo", GHOST_MAX))


## Silhueta de uma cor só (pixels inteiros, sem borrão) do quadro do corpo.
func _silhouette(texture: Texture2D) -> Texture2D:
    var key := texture.get_instance_id()
    if ghost_cache.has(key):
        return ghost_cache[key]
    var source := texture.get_image()
    var image := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
    for y in range(source.get_height()):
        for x in range(source.get_width()):
            if source.get_pixel(x, y).a > 0.5:
                image.set_pixel(x, y, GHOST_COLOR)
    var result := ImageTexture.create_from_image(image)
    ghost_cache[key] = result
    return result


func ghost_alpha(ghost: Dictionary) -> float:
    return GHOST_ALPHA * clampf(1.0 - float(ghost.age) / float(ghost.life), 0.0, 1.0)


func run_frames() -> int:
    return character.anims[character.estado_anim["run"]].frames.size()


## quadro = floor(distância / px_por_quadro) mod n
func run_frame() -> int:
    return int(floor(run_distance_px / float(character.px_por_quadro))) % run_frames()


func nearest_support_frame() -> int:
    var count := run_frames()
    var natural := run_frame()
    var best: int = character.apoios[0]
    var best_distance := 9999
    for support: int in character.apoios:
        var raw := absi(natural - support)
        var circular := mini(raw, count - raw)
        if circular < best_distance:
            best_distance = circular
            best = support
    return best


# ---------------------------------------------------------------- quadros

static func frame_at_ms(frames: Array, milliseconds: float, loop: bool) -> int:
    var total := 0.0
    for frame: Dictionary in frames:
        total += float(frame.ms)
    if frames.size() <= 1 or total <= 0.0:
        return 0
    var t := fposmod(milliseconds, total) if loop else clampf(milliseconds, 0.0, total - 0.0001)
    var cumulative := 0.0
    for i in range(frames.size()):
        cumulative += float(frames[i].ms)
        if t < cumulative - 0.00001:
            return i
    return frames.size() - 1


## Animação e quadro para um estado. Fonte única para a arte e para o dano.
func pose_for(state: String) -> Dictionary:
    var anims: Dictionary = character.anims
    var mapping: Dictionary = character.estado_anim
    var combat: PlayerCombat = player.get_node("Combat")
    var defense: PlayerDefense = player.get_node("Defense")
    if character.ataque_anim.has(state):
        var attack_anim: String = character.ataque_anim[state]
        var attack_frames: Array = anims[attack_anim].frames
        var attack_index := frame_at_ms(attack_frames, combat.elapsed * 1000.0, false)
        if state == "carrasco_air_heavy" and attack_index >= AIR_HEAVY_HOLD_FRAME:
            attack_index = _air_heavy_frame(attack_index, attack_frames)
        elif state == "carrasco_heavy" and charge_peak > 0.14 and character.get("v32", false) and combat.phase == PlayerCombat.Phase.WINDUP:
            attack_index = maxi(attack_index, CHARGED_WINDUP_FRAME)
        return {"anim": attack_anim, "frame": attack_index}
    if not mapping.has(state):
        var fallback: String = character.padrao
        return {"anim": fallback, "frame": 0 if fallback == "mestre" else frame_at_ms(anims[fallback].frames, idle_time * 1000.0, true)}
    var anim: String = mapping[state]
    match state:
        "idle":
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, idle_time * 1000.0, true)}
        "run", "walk":
            if support_hold_ticks > 0 and support_frame >= 0:
                return {"anim": anim, "frame": support_frame}
            return {"anim": anim, "frame": run_frame()}
        "jump":
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, air_time * 1000.0, false)}
        "fall":
            if anims.has("fall_start") and anims.has("fall_loop"):
                var start_ms := 0.0
                for frame: Dictionary in anims.fall_start.frames:
                    start_ms += float(frame.ms)
                var ms := fall_time * 1000.0
                if ms < start_ms:
                    return {"anim": "fall_start", "frame": frame_at_ms(anims.fall_start.frames, ms, false)}
                return {"anim": "fall_loop", "frame": frame_at_ms(anims.fall_loop.frames, ms - start_ms, true)}
            return {"anim": anim, "frame": 0}
        "turn", "attack_exit", "run_stop":
            return {"anim": anim, "frame": 0}
        "run_start":
            return {"anim": anim, "frame": mini(anims[anim].frames.size() - 1, int(run_start_px / float(character.px_por_quadro)))}
        "parry":
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, defense.elapsed * 1000.0, false)}
        "charge":
            return _charge_pose(combat)
        "ground_dash", "air_dash":
            var total := defense.air_dash_total_seconds if state == "air_dash" else defense.dodge_total_seconds
            var span := 0.0
            for frame: Dictionary in anims[anim].frames:
                span += float(frame.ms)
            var fraction := clampf(defense.elapsed / maxf(0.0001, total), 0.0, 0.9999)
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, fraction * span, false)}
        "hit", "ruptured", "death":
            var elapsed_hurt := HURT_SECONDS - damage_remaining
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, elapsed_hurt * 1000.0, false)}
        "land":
            return {"anim": anim, "frame": frame_at_ms(anims[anim].frames, (LAND_SECONDS - land_remaining) * 1000.0, false)}
    return {"anim": anim, "frame": 0}


## Aéreo pesado: no ar segura o quadro de mergulho; no chão toca o impacto
## (quadros após o de mergulho) contando do pouso, nunca antes do tempo do .tres.
func _air_heavy_frame(time_index: int, frames: Array) -> int:
    if not player.is_on_floor():
        return AIR_HEAVY_HOLD_FRAME
    var landing: Array = frames.slice(AIR_HEAVY_HOLD_FRAME + 1)
    var landing_index := AIR_HEAVY_HOLD_FRAME + 1 + frame_at_ms(landing, ground_time * 1000.0, false)
    return maxi(time_index, landing_index)


func _charge_pose(combat: PlayerCombat) -> Dictionary:
    var anims: Dictionary = character.anims
    var t := combat.charge_elapsed
    var start_frames: Array = anims.charge_start.frames
    var start_ms := 0.0
    for frame: Dictionary in start_frames:
        start_ms += float(frame.ms)
    if t * 1000.0 < start_ms:
        return {"anim": "charge_start", "frame": frame_at_ms(start_frames, t * 1000.0, false)}
    var threshold := combat.charge_source.charge_threshold_seconds if combat.charge_source != null else 1.0
    if combat.charge_ready():
        return {"anim": "charge_full", "frame": frame_at_ms(anims.charge_full.frames, (t - threshold) * 1000.0, true)}
    return {"anim": "charge_loop", "frame": frame_at_ms(anims.charge_loop.frames, t * 1000.0 - start_ms, true)}


## Chamado pelo PlayerCombat a cada tick ACTIVE: formas do quadro exibido.
func attack_hitbox(attack_id: String, elapsed: float) -> Dictionary:
    if character.is_empty() or not profiles_attack(attack_id):
        return {}
    var anim: String = character.ataque_anim[attack_id]
    var frames: Array = character.anims[anim].frames
    var index := frame_at_ms(frames, elapsed * 1000.0, false)
    var spec: Dictionary = frames[index]
    # O dano segue o quadro DESENHADO: se a pose de dano/queda cobre o golpe
    # (jogador atingido no meio do ataque), o quadro exibido não tem hitbox.
    if _candidate_state() != attack_id:
        return {"anim": anim, "quadro": index, "quadro_sem_dano": true, "coberto_por": _candidate_state()}
    if spec.hitbox == null or not spec.hitbox.valida or String(spec.hitbox.fase).to_upper() not in ["ACTIVE", "ATIVO"]:
        return {"anim": anim, "quadro": index, "quadro_sem_dano": true}
    return {"tem_hitbox": true, "anim": anim, "quadro": index, "partes": spec.hitbox.partes, "fase": spec.hitbox.fase}


# ---------------------------------------------------------------- desenho

func _process(delta: float) -> void:
    sync(delta)


func sync(_delta: float) -> void:
    if player == null or character.is_empty():
        return
    visual_state = _state_name()
    var pose := pose_for(visual_state)
    anim_id = String(pose.anim)
    frame_index = int(pose.frame)
    var anim: Dictionary = character.anims[anim_id]
    frame_spec = anim.frames[frame_index]
    last_anchor = frame_spec.ancora
    var feet_world := player.global_position + FEET_LOCAL
    var canvas := player.get_viewport().get_canvas_transform()
    var feet_screen := (canvas * feet_world).round()
    global_transform = canvas.affine_inverse() * Transform2D(0.0, feet_screen)
    var flipped: bool = int(player.get("facing_direction")) < 0
    body.texture = frame_spec.tex
    body.flip_h = flipped
    body.offset = _offset(frame_spec.tex, last_anchor, flipped)
    _sync_effects(flipped)
    _sync_shadow(feet_world, flipped)
    _sync_ghosts()
    _sync_spark(flipped)


func _offset(texture: Texture2D, anchor: Vector2, flipped: bool) -> Vector2:
    # Espelha o retângulo [0,w] preservando a linha da âncora nos pés.
    return Vector2(-(texture.get_width() - anchor.x) if flipped else -anchor.x, -anchor.y)


func _sync_effects(flipped: bool) -> void:
    var combat: PlayerCombat = player.get_node("Combat")
    var effects: Array = frame_spec.efeitos
    for i in range(effect_nodes.size()):
        var fx := effect_nodes[i]
        fx.visible = i < effects.size()
        if not fx.visible:
            continue
        var spec: Dictionary = effects[i]
        fx.texture = spec.tex
        fx.flip_h = flipped
        fx.offset = _offset(spec.tex, spec.ancora, flipped)
        fx.visible = spec.fase in ["TODAS", "ALL"] or (spec.fase in ["ACTIVE", "ATIVO"] and combat.phase == PlayerCombat.Phase.ACTIVE) or (spec.fase in ["WINDUP", "PREP"] and combat.phase == PlayerCombat.Phase.WINDUP) or (spec.fase in ["RECOVERY", "RECUP"] and combat.phase == PlayerCombat.Phase.RECOVERY)


func _sync_ghosts() -> void:
    var transform := player.get_viewport().get_canvas_transform()
    for i in range(ghost_nodes.size()):
        var node := ghost_nodes[i]
        node.visible = i < ghosts.size()
        if not node.visible:
            continue
        var ghost: Dictionary = ghosts[i]
        node.texture = ghost.tex
        node.flip_h = bool(ghost.flipped)
        node.offset = _offset(ghost.tex, ghost.ancora, bool(ghost.flipped))
        node.position = (transform * Vector2(ghost.world)).round() - (transform * global_position).round()
        node.modulate = Color(1, 1, 1, ghost_alpha(ghost))


func _sync_spark(flipped: bool) -> void:
    spark.visible = spark_remaining > 0.0 and character.anims.has("parry_spark")
    if not spark.visible:
        return
    var frames: Array = character.anims.parry_spark.frames
    var spec: Dictionary = frames[frame_at_ms(frames, (SPARK_SECONDS - spark_remaining) * 1000.0, false)]
    spark.texture = spec.tex
    spark.flip_h = flipped
    spark.offset = _offset(spec.tex, spec.ancora, flipped)
    spark.position = Vector2(-SPARK_OFFSET.x if flipped else SPARK_OFFSET.x, SPARK_OFFSET.y)


func _sync_shadow(feet_world: Vector2, flipped: bool) -> void:
    var query := PhysicsRayQueryParameters2D.create(feet_world - Vector2(0, 2.0 / ZOOM), feet_world + Vector2(0, 1200.0 / ZOOM), 1, [player.get_rid()])
    query.collide_with_areas = false
    var space := player.get_world_2d().direct_space_state
    var hit := space.intersect_ray(query)
    var excluded: Array[RID] = [player.get_rid()]
    for _attempt in range(32):
        if hit.is_empty() or not hit.collider is CharacterBody2D:
            break
        excluded.append(hit.collider.get_rid())
        query.exclude = excluded
        hit = space.intersect_ray(query)
    shadow_hit = not hit.is_empty() and not frame_spec.sombra.is_empty()
    shadow.visible = shadow_hit
    if not shadow_hit:
        return
    var ground: Vector2 = hit.position
    shadow_ground_screen = (player.get_viewport().get_canvas_transform() * ground).round()
    shadow_height_m = maxf(0.0, (ground.y - feet_world.y) * ZOOM / 32.0)
    shadow_factor = 1.0 - 0.5 * clampf(shadow_height_m / 2.2, 0.0, 1.0)
    var spec: Dictionary = frame_spec.sombra
    var bbox: Rect2i = spec.bbox
    var anchor: Vector2 = spec.ancora
    # Corpo ×1; sombra rasterizada em pixels inteiros no chão.
    var width := maxi(1, roundi(bbox.size.x * shadow_factor))
    var height := maxi(1, roundi(bbox.size.y * shadow_factor))
    var x := roundf((bbox.position.x - anchor.x) * shadow_factor)
    var y := roundf((bbox.position.y - anchor.y) * shadow_factor)
    shadow.texture = spec.texture
    shadow.flip_h = flipped
    shadow.scale = Vector2(float(width) / bbox.size.x, float(height) / bbox.size.y)
    shadow.offset = Vector2.ZERO
    shadow.position = shadow_ground_screen - (player.get_viewport().get_canvas_transform() * global_position).round() + Vector2(-x - width if flipped else x, y)
    shadow.modulate = Color(1, 1, 1, shadow_factor)
