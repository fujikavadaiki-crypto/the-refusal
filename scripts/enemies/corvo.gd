extends CharacterBody2D

@onready var brain: CorvoBrain = $Brain
@onready var flight: CorvoFlight = $Flight
@onready var attack: CorvoAttack = $Attack
@onready var health: HealthComponent = $Health
@onready var posture: PostureComponent = $Posture
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var visual: Node2D = $VisualRoot
@onready var status: Label = $StatusLabel

var spawn_position := Vector2.ZERO
var facing_direction := -1
var flash_remaining := 0.0


func _ready() -> void:
    spawn_position = global_position
    health.damage_taken.connect(_on_damage)
    health.depleted.connect(_on_death)
    posture.ruptured.connect(brain.on_rupture)
    posture.recovered.connect(brain.on_recovered)
    set_facing(-1)


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("reset_dummy"):
        reset_enemy()
    if brain.state != CorvoBrain.State.DEATH and brain.state != CorvoBrain.State.RUPTURE:
        attack.tick(delta, brain.player)
    brain.tick(delta)
    flight.tick(delta)
    flash_remaining = maxf(0.0, flash_remaining - delta)
    if brain.state == CorvoBrain.State.DEATH:
        visual.modulate = Color(0.38, 0.39, 0.38)
        visual.rotation_degrees = move_toward(visual.rotation_degrees, 85.0 * facing_direction, 180.0 * delta)
    elif brain.state == CorvoBrain.State.RUPTURE:
        visual.modulate = Color(0.94, 0.75, 0.49)
    else:
        visual.modulate = Color(1.0, 0.76, 0.68) if flash_remaining > 0.0 else Color.WHITE
    status.text = "CORVO %d/%d  POST %d/%d\n%s" % [health.current_health, health.max_health, roundi(posture.current_posture), roundi(posture.max_posture), CorvoBrain.State.keys()[brain.state]]


func set_facing(direction: int) -> void:
    if direction == 0:
        return
    facing_direction = direction
    visual.scale.x = -direction
    $BeakTelegraph.scale.x = -direction


func reset_enemy() -> void:
    attack.abort()
    attack.clear_projectiles()
    global_position = spawn_position
    velocity = Vector2.ZERO
    health.reset_health()
    posture.reset_posture()
    hurt_shape.set_deferred("disabled", false)
    visual.rotation_degrees = 0.0
    visual.modulate = Color.WHITE
    flash_remaining = 0.0
    set_facing(-1)
    flight.reset_flight()
    brain.reset_brain()


func _on_damage(context: HitContext) -> void:
    flash_remaining = 0.1
    brain.on_damage(context)


func _on_death() -> void:
    brain.on_death()
    hurt_shape.set_deferred("disabled", true)
