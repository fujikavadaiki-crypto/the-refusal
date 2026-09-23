class_name Hitbox2D
extends Area2D

signal hit_confirmed(context: HitContext)
signal before_hit(context: HitContext)
static var next_hit_uid := 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false
var template: HitContext
var struck_targets: Dictionary = {}


func _ready() -> void:
    collision_shape.shape = collision_shape.shape.duplicate()
    collision_shape.disabled = true
    area_entered.connect(_on_area_entered)


func arm(context: HitContext, attack: AttackData) -> void:
    template = context
    struck_targets.clear()
    position.x = attack.hitbox_center_x
    var rectangle := collision_shape.shape as RectangleShape2D
    rectangle.size = attack.hitbox_size
    active = true
    collision_shape.set_deferred("disabled", false)


func disarm() -> void:
    active = false
    collision_shape.set_deferred("disabled", true)


func scan_overlaps() -> void:
    if not active:
        return
    for area in get_overlapping_areas():
        _try_area(area)


func _on_area_entered(area: Area2D) -> void:
    _try_area(area)


func _try_area(area: Area2D) -> void:
    if not active or not area is Hurtbox2D:
        return
    var target_key: int = area.get_parent().get_instance_id()
    if area.receiver != null:
        target_key = area.receiver.get_instance_id()
    if struck_targets.has(target_key):
        return
    struck_targets[target_key] = true
    var context := template.for_target(area.get_parent() as Node2D, next_hit_uid)
    next_hit_uid += 1
    before_hit.emit(context)
    if area.receive_hit(context):
        hit_confirmed.emit(context)
    else:
        struck_targets.erase(target_key)
