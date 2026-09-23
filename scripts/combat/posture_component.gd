class_name PostureComponent
extends Node

signal posture_changed(current: float, maximum: float)
signal ruptured
signal recovered

@export var max_posture := 100.0
@export var regen_delay_seconds := 1.5
@export var regen_per_second := 25.0
@export var rupture_duration_seconds := 0.8
@export var restore_fraction := 0.5
@export var break_protection_seconds := 0.35
@export var rupture_vulnerability_bonus := 0.0

var current_posture := 0.0
var regen_delay_remaining := 0.0
var rupture_remaining := 0.0
var protection_remaining := 0.0
var broken := false


func _ready() -> void:
    reset_posture()


func _physics_process(delta: float) -> void:
    if broken:
        rupture_remaining = maxf(0.0, rupture_remaining - delta)
        if is_zero_approx(rupture_remaining):
            _end_rupture()
        return
    protection_remaining = maxf(0.0, protection_remaining - delta)
    regen_delay_remaining = maxf(0.0, regen_delay_remaining - delta)
    if regen_delay_remaining <= 0.0 and current_posture < max_posture:
        current_posture = minf(max_posture, current_posture + regen_per_second * delta)
        posture_changed.emit(current_posture, max_posture)


func receive_damage(amount: int, allow_rupture := true) -> int:
    if amount <= 0 or broken:
        return 0
    regen_delay_remaining = regen_delay_seconds
    var before := current_posture
    current_posture = maxf(0.0, current_posture - float(amount))
    if current_posture <= 0.0 and protection_remaining > 0.0 and allow_rupture:
        current_posture = 1.0
    posture_changed.emit(current_posture, max_posture)
    if current_posture <= 0.0 and allow_rupture:
        broken = true
        rupture_remaining = rupture_duration_seconds
        ruptured.emit()
    return roundi(before - current_posture)


func is_ruptured() -> bool:
    return broken


func reset_posture() -> void:
    broken = false
    current_posture = max_posture
    regen_delay_remaining = 0.0
    rupture_remaining = 0.0
    protection_remaining = 0.0
    posture_changed.emit(current_posture, max_posture)


func set_max_preserving_ratio(value: float) -> void:
    var fraction := current_posture / maxf(1.0, max_posture)
    max_posture = maxf(1.0, value)
    current_posture = clampf(fraction * max_posture, 0.0, max_posture)
    posture_changed.emit(current_posture, max_posture)


func _end_rupture() -> void:
    broken = false
    current_posture = max_posture * restore_fraction
    protection_remaining = break_protection_seconds
    regen_delay_remaining = 0.0
    posture_changed.emit(current_posture, max_posture)
    recovered.emit()
