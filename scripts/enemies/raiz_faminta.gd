extends CharacterBody2D

@onready var brain: RaizFamintaBrain = $Brain
@onready var attack: RaizFamintaAttack = $Attack
@onready var health: HealthComponent = $Health
@onready var posture: PostureComponent = $Posture
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var visual: Node2D = $VisualRoot
@onready var mound: Polygon2D = $BurrowMark
@onready var status: Label = $StatusLabel

var spawn_position := Vector2.ZERO
var facing_direction := -1
var flash_remaining := 0.0
var died_buried := false


func _ready() -> void:
    spawn_position = global_position
    health.damage_taken.connect(_on_damage)
    health.depleted.connect(_on_death)
    posture.ruptured.connect(brain.on_rupture)
    posture.recovered.connect(brain.on_recovered)
    brain.state_changed.connect(_apply_state)
    set_facing(-1)
    _apply_state(brain.state)


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("reset_dummy"):
        reset_enemy()
    if brain.state not in [RaizFamintaBrain.State.RUPTURE, RaizFamintaBrain.State.DEATH]:
        attack.tick(delta, brain.player)
    brain.tick(delta)
    if brain.state in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DETECT, RaizFamintaBrain.State.BURROW_MOVE, RaizFamintaBrain.State.EMERGE_WINDUP, RaizFamintaBrain.State.EMERGE_ATTACK, RaizFamintaBrain.State.EMERGE_RECOVERY, RaizFamintaBrain.State.DEATH]:
        velocity = Vector2.ZERO
    else:
        if not is_on_floor():
            velocity.y += brain.tuning.gravity * delta
        velocity.x = move_toward(velocity.x, brain.move_axis, brain.tuning.ground_acceleration * delta)
        move_and_slide()
    flash_remaining = maxf(0.0, flash_remaining - delta)
    _update_visual()
    status.text = "RAIZ %d/%d  POST %d/%d\n%s" % [health.current_health, health.max_health, roundi(posture.current_posture), roundi(posture.max_posture), RaizFamintaBrain.State.keys()[brain.state]]


func set_facing(direction: int) -> void:
    if direction == 0:
        return
    facing_direction = direction
    visual.scale.x = direction
    $AttackPivot.scale.x = direction


func reset_enemy() -> void:
    attack.abort()
    global_position = spawn_position
    velocity = Vector2.ZERO
    health.reset_health()
    posture.reset_posture()
    hurt_shape.set_deferred("disabled", false)
    visual.rotation_degrees = 0.0
    visual.modulate = Color.WHITE
    mound.modulate = Color.WHITE
    flash_remaining = 0.0
    died_buried = false
    set_facing(-1)
    brain.reset_brain()
    _apply_state(brain.state)


func _on_damage(context: HitContext) -> void:
    flash_remaining = 0.10
    brain.on_damage(context)


func _on_death() -> void:
    died_buried = brain.state in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DETECT, RaizFamintaBrain.State.BURROW_MOVE, RaizFamintaBrain.State.EMERGE_WINDUP]
    brain.on_death()
    velocity = Vector2.ZERO
    hurt_shape.set_deferred("disabled", true)


func _apply_state(state: int) -> void:
    var buried := state in [RaizFamintaBrain.State.HIDDEN, RaizFamintaBrain.State.DETECT, RaizFamintaBrain.State.BURROW_MOVE, RaizFamintaBrain.State.EMERGE_WINDUP]
    var emerging := state in [RaizFamintaBrain.State.EMERGE_ATTACK, RaizFamintaBrain.State.EMERGE_RECOVERY]
    body_shape.set_deferred("disabled", buried or emerging or state == RaizFamintaBrain.State.DEATH)
    visual.visible = not buried or state == RaizFamintaBrain.State.EMERGE_WINDUP
    mound.visible = buried or (state == RaizFamintaBrain.State.DEATH and died_buried)
    if state in [RaizFamintaBrain.State.RUPTURE, RaizFamintaBrain.State.DEATH]:
        visual.visible = true
    if state == RaizFamintaBrain.State.DEATH:
        visual.position.y = 5.0
        visual.rotation_degrees = 15.0 * facing_direction


func _update_visual() -> void:
    match brain.state:
        RaizFamintaBrain.State.HIDDEN:
            mound.position.x = 0.0
            mound.scale.x = 1.0 + sin(brain.elapsed * 2.0) * 0.05
        RaizFamintaBrain.State.DETECT, RaizFamintaBrain.State.BURROW_MOVE:
            mound.position.x = sin(brain.elapsed * 13.0) * 0.7
            mound.scale.x = 1.12
        RaizFamintaBrain.State.EMERGE_WINDUP:
            var progress := clampf(attack.elapsed / attack.garra_subterranea.windup_seconds, 0.0, 1.0)
            visual.position.y = lerpf(brain.tuning.emerge_visual_rise, 0.0, progress)
            mound.position.x = sin(attack.elapsed * 30.0) * brain.tuning.mound_rumble_amplitude
            mound.scale.x = 1.0 + progress * 0.5
            visual.modulate = Color(1, 1, 1, 0.55 + progress * 0.45)
        RaizFamintaBrain.State.RUPTURE:
            visual.position.y = 4.0
            visual.modulate = Color(0.89, 0.75, 0.49)
        RaizFamintaBrain.State.DEATH:
            visual.modulate = Color(0.37, 0.39, 0.34)
            mound.modulate = Color(0.36, 0.38, 0.33)
        _:
            visual.position.y = 0.0
            visual.modulate = Color(1.0, 0.82, 0.68) if flash_remaining > 0.0 else Color.WHITE
            mound.position.x = 0.0
