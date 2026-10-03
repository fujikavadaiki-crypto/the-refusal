extends StaticBody2D

## Manually triggered training prop, not an enemy. T = parryable, G = heavy.
enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

@export var parryable_attack: AttackData
@export var heavy_attack: AttackData
@export var player_path: NodePath = NodePath("../Player")

@onready var player: CharacterBody2D = get_node(player_path) as CharacterBody2D
@onready var pivot: Node2D = $AttackPivot
@onready var hitbox: Hitbox2D = $AttackPivot/Hitbox
@onready var telegraph: Polygon2D = $AttackPivot/Telegraph
@onready var body: Polygon2D = $Body
@onready var posture: PostureComponent = $Posture
@onready var stats: DefenseStats = $DefenseStats
@onready var health: HealthComponent = $Health
@onready var cue_audio: AudioStreamPlayer2D = $HeavyCueAudio
@onready var status_label: Label = $StatusLabel
@onready var feedback_label: Label = $FeedbackLabel

var phase := Phase.IDLE
var current_attack: AttackData
var elapsed := 0.0
var action_uid := 0
var facing_direction := 1
var last_context: HitContext


func _ready() -> void:
    hitbox.hit_confirmed.connect(_on_hit_confirmed)
    health.damage_taken.connect(_on_damage_taken)
    posture.ruptured.connect(_on_ruptured)
    posture.recovered.connect(_on_recovered)
    telegraph.visible = false
    _update_label()


func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("training_parryable"):
        trigger_attack(false)
    elif Input.is_action_just_pressed("training_heavy") and not get_node("/root/Sensacao").debug_controls:
        trigger_attack(true)
    if Input.is_action_just_pressed("reset_dummy"):
        reset_device()
    _tick_attack(delta)
    _update_label()


func trigger_attack(heavy := false) -> bool:
    if phase != Phase.IDLE or posture.is_ruptured() or health.current_health <= 0:
        return false
    current_attack = heavy_attack if heavy else parryable_attack
    phase = Phase.WINDUP
    elapsed = 0.0
    action_uid = HitContext.allocate_action_id()
    facing_direction = -1 if player.global_position.x < global_position.x else 1
    pivot.scale.x = facing_direction
    pivot.position.x = 5.0 * facing_direction
    pivot.rotation_degrees = current_attack.start_angle_degrees * facing_direction
    telegraph.visible = true
    telegraph.color = Color(0.8, 0.12, 0.18, 0.82) if heavy else Color(0.76, 0.91, 0.77, 0.75)
    feedback_label.text = "HEAVY!" if heavy else "PARRYABLE"
    if heavy:
        cue_audio.play()
    return true


func reset_device() -> void:
    _cancel_attack()
    health.reset_health()
    posture.reset_posture()
    body.modulate = Color.WHITE
    feedback_label.text = "RESET"


func _tick_attack(delta: float) -> void:
    if phase == Phase.IDLE:
        return
    elapsed += delta
    var active_start := current_attack.windup_seconds
    var active_end := active_start + current_attack.active_seconds
    if elapsed < active_start:
        phase = Phase.WINDUP
        pivot.rotation_degrees = current_attack.start_angle_degrees * facing_direction
    elif elapsed < active_end:
        if phase != Phase.ACTIVE:
            phase = Phase.ACTIVE
            _arm_hitbox()
        var progress := (elapsed - active_start) / current_attack.active_seconds
        pivot.rotation_degrees = lerpf(current_attack.start_angle_degrees, current_attack.end_angle_degrees, progress) * facing_direction
        hitbox.scan_overlaps()
    elif elapsed < current_attack.total_seconds():
        if phase == Phase.ACTIVE:
            hitbox.disarm()
            telegraph.visible = false
        phase = Phase.RECOVERY
    else:
        _cancel_attack()


func _arm_hitbox() -> void:
    var context := HitContext.new()
    context.attacker = self
    context.attacker_posture = posture
    context.attacker_stats = stats
    context.attack_id = current_attack.attack_id
    context.action_uid = action_uid
    context.base_damage = current_attack.base_damage
    context.posture_damage = current_attack.posture_damage
    context.damage_type = current_attack.damage_type
    context.parry_class = current_attack.parry_class
    context.tags = current_attack.tags.duplicate()
    hitbox.arm(context, current_attack)


func _cancel_attack() -> void:
    hitbox.disarm()
    telegraph.visible = false
    phase = Phase.IDLE
    current_attack = null
    elapsed = 0.0
    pivot.rotation_degrees = 0.0


func _on_hit_confirmed(context: HitContext) -> void:
    last_context = context
    match context.outcome:
        HitContext.Outcome.DODGED:
            feedback_label.text = "DODGED"
        HitContext.Outcome.PARRIED:
            feedback_label.text = "PARRIED -%d POST" % context.parry_posture_return
        _:
            feedback_label.text = "-%d HP / -%d POST" % [context.actual_damage, context.actual_posture_damage]
            get_node("/root/HitStop").request_hit(context)


func _on_damage_taken(context: HitContext) -> void:
    feedback_label.text = "-%d HP / -%d POST" % [context.actual_damage, context.actual_posture_damage]
    _update_label()


func _on_ruptured() -> void:
    _cancel_attack()
    body.modulate = Color(0.82, 0.55, 0.9)
    feedback_label.text = "RUPTURA"


func _on_recovered() -> void:
    body.modulate = Color.WHITE
    feedback_label.text = "RECOVERED"


func _update_label() -> void:
    var state := "RUPTURA" if posture.is_ruptured() else ("WINDUP" if phase == Phase.WINDUP else "READY")
    status_label.text = "TRAIN %d HP  %d/%d POST  %s" % [health.current_health, roundi(posture.current_posture), roundi(posture.max_posture), state]
