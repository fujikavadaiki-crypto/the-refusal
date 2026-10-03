extends CharacterBody2D

## Scene owner. Combat arithmetic and AI decisions stay in their components.
@onready var brain: PeregrinoBrain = $Brain
@onready var attack: PeregrinoAttack = $Attack
@onready var health: HealthComponent = $Health
@onready var posture: PostureComponent = $Posture
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var visual: Node2D = $VisualRoot
@onready var status: Label = $StatusLabel

var spawn_position := Vector2.ZERO
var facing_direction := -1
var flash_remaining := 0.0


func _ready() -> void:
    get_node("/root/Sensacao").attach_actor(self, "res://data/enemies/peregrino_mapa.json")
    spawn_position = global_position
    health.damage_taken.connect(_on_damage)
    health.depleted.connect(_on_death)
    posture.ruptured.connect(brain.on_rupture)
    posture.recovered.connect(brain.on_recovered)
    set_facing(-1)


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("reset_dummy"):
        reset_enemy()
    if brain.state != PeregrinoBrain.State.DEATH:
        attack.tick(delta, brain.player, brain.tuning.facing_deadzone)
        brain.tick(delta)
        if not is_on_floor():
            velocity.y += brain.tuning.gravity * delta
        var rate := brain.tuning.acceleration * delta
        velocity.x = move_toward(velocity.x, brain.move_axis, rate)
        $SensacaoAlvo.apply_recoil(delta)
        move_and_slide()
        attack.resolve_frame_contact()
    flash_remaining = maxf(0.0, flash_remaining - delta)
    if brain.state != PeregrinoBrain.State.DEATH and brain.state != PeregrinoBrain.State.RUPTURE:
        visual.modulate = Color(1.0, 0.75, 0.66) if flash_remaining > 0.0 else Color.WHITE
    status.text = "PEREGRINO %d/%d  POST %d/%d\n%s" % [health.current_health, health.max_health, roundi(posture.current_posture), roundi(posture.max_posture), PeregrinoBrain.State.keys()[brain.state]]


func set_facing(direction: int) -> void:
    if direction == 0:
        return
    facing_direction = direction
    visual.scale.x = direction
    $AttackPivot.scale.x = direction
    $AttackPivot.position.x = 5.0 * direction


func reset_enemy() -> void:
    attack.abort()
    global_position = spawn_position
    velocity = Vector2.ZERO
    health.reset_health()
    posture.reset_posture()
    body_shape.set_deferred("disabled", false)
    hurt_shape.set_deferred("disabled", false)
    visual.rotation_degrees = 0.0
    visual.modulate = Color.WHITE
    flash_remaining = 0.0
    set_facing(-1)
    brain.reset_brain()


func _on_damage(context: HitContext) -> void:
    flash_remaining = 0.0
    brain.on_damage(context)


func _on_death() -> void:
    brain.on_death()
    velocity = Vector2.ZERO
    body_shape.set_deferred("disabled", true)
    hurt_shape.set_deferred("disabled", true)
    visual.modulate = Color(0.38, 0.39, 0.4)
    visual.rotation_degrees = 70.0 * facing_direction
