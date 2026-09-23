extends StaticBody2D

## Temporary combat target. R resets its health and visible damage counter.
@onready var health: HealthComponent = $Health
@onready var posture: PostureComponent = $Posture
@onready var health_label: Label = $HealthLabel
@onready var posture_label: Label = $PostureLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var flash: Polygon2D = $Flash
@onready var body: Polygon2D = $Body

var hit_count := 0
var last_context: HitContext
var flash_remaining := 0.0


func _ready() -> void:
    health.damage_taken.connect(_on_damage_taken)
    health.reset_done.connect(_on_reset)
    posture.ruptured.connect(_on_ruptured)
    posture.recovered.connect(_on_recovered)
    _update_labels()


func _process(delta: float) -> void:
    if Input.is_action_just_pressed("reset_dummy"):
        reset_dummy()
    if flash_remaining > 0.0:
        flash_remaining -= delta
        flash.visible = flash_remaining > 0.0


func reset_dummy() -> void:
    hit_count = 0
    last_context = null
    health.reset_health()
    posture.reset_posture()
    body.modulate = Color.WHITE
    feedback_label.text = "RESET"


func _on_damage_taken(context: HitContext) -> void:
    hit_count += 1
    last_context = context
    flash_remaining = 0.12
    flash.visible = true
    feedback_label.text = "-%d HP / -%d POST" % [context.actual_damage, context.actual_posture_damage]
    _update_labels()


func _on_reset() -> void:
    flash.visible = false
    flash_remaining = 0.0
    _update_labels()


func _on_ruptured() -> void:
    body.modulate = Color(0.83, 0.58, 0.89)
    feedback_label.text = "RUPTURA +20%"
    _update_labels()


func _on_recovered() -> void:
    body.modulate = Color.WHITE
    feedback_label.text = "RECOVERED"
    _update_labels()


func _update_labels() -> void:
    health_label.text = "DUMMY %d/%d  HITS %d" % [health.current_health, health.max_health, hit_count]
    posture_label.text = "POST %d/%d  %s" % [roundi(posture.current_posture), roundi(posture.max_posture), "RUPTURA" if posture.is_ruptured() else "NORMAL"]
