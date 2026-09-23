class_name CorvoProjectile
extends Node2D

signal expired(projectile: CorvoProjectile)
signal contact(context: HitContext)

@export var attack: AttackData
@onready var hitbox: Hitbox2D = $Hitbox

var source: Node2D
var source_posture: PostureComponent
var source_stats: DefenseStats
var direction := Vector2.LEFT
var speed := 125.0
var lifetime := 2.2
var age := 0.0
var launched := false


func _ready() -> void:
    hitbox.hit_confirmed.connect(_on_hit)


func launch(owner_bird: Node2D, from_position: Vector2, toward: Vector2, flight_speed: float, max_life: float) -> void:
    source = owner_bird
    source_posture = owner_bird.get_node("Posture") as PostureComponent
    source_stats = owner_bird.get_node("DefenseStats") as DefenseStats
    global_position = from_position
    direction = (toward - from_position).normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.LEFT
    speed = flight_speed
    lifetime = max_life
    age = 0.0
    var context := HitContext.new()
    context.attacker = source
    context.attacker_posture = source_posture
    context.attacker_stats = source_stats
    context.attack_id = attack.attack_id
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = attack.base_damage
    context.posture_damage = attack.posture_damage
    context.damage_type = attack.damage_type
    context.parry_class = attack.parry_class
    context.tags = attack.tags.duplicate()
    hitbox.arm(context, attack)
    launched = true


func _physics_process(delta: float) -> void:
    if not launched:
        return
    age += delta
    if age >= lifetime:
        expire()
        return
    var travel := direction * speed * delta
    var query := PhysicsRayQueryParameters2D.create(global_position, global_position + travel, 1)
    if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
        expire()
        return
    global_position += travel
    hitbox.scan_overlaps()


func _on_hit(context: HitContext) -> void:
    contact.emit(context)
    expire()


func expire() -> void:
    if not launched:
        return
    launched = false
    hitbox.disarm()
    expired.emit(self)
    queue_free()
