extends Node2D

## Screen-space rectangles: no filtering, scaling or fractional pixel output.
var particles: Array[Dictionary] = []
var previous: Dictionary = {}
var rng := RandomNumberGenerator.new()
var emissions := {"sangue": 0, "poeira": 0}

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    process_priority = 80
    rng.seed = int(get_node("/root/Sensacao").config.pixels.semente)
    get_node("/root/Sensacao").group_changed.connect(_on_group)

func _on_group(group: String, state: bool) -> void:
    if not state:
        particles = particles.filter(func(p: Dictionary) -> bool: return p.group != group)
        if group == "movimento":
            previous.clear()
            for player in get_tree().get_nodes_in_group("feel_players"): player.set_meta("landing_offset_px", 0)

func emit_pixels(world: Vector2, kind: String, facing: float) -> void:
    var feel := get_node("/root/Sensacao")
    var group := "impacto" if kind == "sangue" else "movimento"
    if not feel.enabled(group): return
    emissions[kind] += 1
    var cfg: Dictionary = feel.config[group]
    var velocity := float(cfg[kind + "_vel_px_s"])
    var factors: Dictionary = feel.config.pixels
    for i in range(int(cfg[kind + "_quantidade"])):
        if particles.size() >= int(feel.config.pixels.limite_particulas): particles.pop_front()
        particles.append({"at": world, "velocity": Vector2(rng.randf_range(factors.vel_x_fatores[0], factors.vel_x_fatores[1]) * velocity * (facing if kind == "sangue" else (-1 if i % 2 == 0 else 1)), -rng.randf_range(factors.vel_y_fatores[0], factors.vel_y_fatores[1]) * velocity) / .9, "life": float(cfg[kind + "_ms"]) / 1000.0, "gravity": float(cfg[kind + "_gravidade_px_s2"]) / .9, "color": Color(cfg[kind + "_paleta"][i % cfg[kind + "_paleta"].size()]), "group": group})

func _physics_process(delta: float) -> void:
    var feel := get_node("/root/Sensacao")
    for player: CharacterBody2D in get_tree().get_nodes_in_group("feel_players"):
        var old: Dictionary = previous.get(player, {"ground": player.is_on_floor(), "moving": false, "landing": 0.0})
        var moving: bool = absf(player.velocity.x) > feel.value("movimento", "limiar_vel_m_s") * (32.0 / .9)
        var ground := player.is_on_floor()
        old.landing = maxf(0.0, float(old.landing) - delta)
        if feel.enabled("movimento"):
            if ground and ((not old.ground) or (moving != bool(old.moving))):
                emit_pixels(player.global_position + Vector2(0, 13), "poeira", float(player.facing_direction))
                if not old.ground: old.landing = feel.value("movimento", "pouso_ms") / 1000.0
        player.set_meta("landing_offset_px", int(feel.value("movimento", "pouso_desloc_px")) if feel.enabled("movimento") and old.landing > 0 else 0)
        previous[player] = {"ground": ground, "moving": moving, "landing": old.landing}
    for actor in previous.keys():
        if not is_instance_valid(actor): previous.erase(actor)

func _process(delta: float) -> void:
    for particle in particles:
        particle.life -= delta
        particle.velocity.y += particle.gravity * delta
        particle.at += particle.velocity * delta
    particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0)
    queue_redraw()

func _draw() -> void:
    var size_px := int(get_node("/root/Sensacao").config.pixels.tamanho_px)
    var canvas := get_viewport().get_canvas_transform()
    for p in particles: draw_rect(Rect2((canvas * p.at).round(), Vector2(size_px, size_px)), p.color)
