extends StaticBody2D

## Temporary combat target. R resets its health and visible damage counter.
@onready var health: HealthComponent = $Health
@onready var health_label: Label = $HealthLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var flash: Polygon2D = $Flash

var hit_count := 0
var last_context: HitContext
var flash_remaining := 0.0


func _ready() -> void:
    health.damage_taken.connect(_on_damage_taken)
    health.reset_done.connect(_on_reset)
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
    feedback_label.text = "RESET"


func _on_damage_taken(context: HitContext) -> void:
    hit_count += 1
    last_context = context
    flash_remaining = 0.12
    flash.visible = true
    feedback_label.text = "-%d %s" % [context.actual_damage, context.attack_id]
    _update_labels()


func _on_reset() -> void:
    flash.visible = false
    flash_remaining = 0.0
    _update_labels()


func _update_labels() -> void:
    health_label.text = "DUMMY %d/%d  HITS %d" % [health.current_health, health.max_health, hit_count]
