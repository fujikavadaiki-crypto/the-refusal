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
var frame_provider: Node
var package_body: Sprite2D
var package_fx: Node2D


func _ready() -> void:
    hitbox.hit_confirmed.connect(_on_hit)
    package_body = Sprite2D.new()
    package_body.centered = false
    package_body.top_level = true
    package_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    package_body.visible = false
    add_child(package_body)
    package_fx = Node2D.new()
    package_body.add_child(package_fx)


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
    _sync_frame()
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
    _sync_frame()
    hitbox.scan_overlaps()

func _sync_frame() -> void:
    if not is_instance_valid(frame_provider): return
    # Dedicated projectile frames use their own anchor; mouth hitboxes never
    # move to the bullet. Missing dedicated data preserves the original core.
    var sample: Dictionary = frame_provider.projectile_sample(attack, age)
    package_body.visible = not sample.is_empty()
    $Core.visible = sample.is_empty()
    if sample.is_empty():
        hitbox.clear_frame_override()
        return
    var frame: Dictionary = sample.frame
    var parts: Array = []
    if not frame.hitbox.is_empty() and frame.phase == "ACTIVE": parts = frame.hitbox.parts
    if sample.has_damage: hitbox.set_frame_parts(parts, global_position, -1 if direction.x < 0 else 1, .9)
    else: hitbox.clear_frame_override()
    var canvas := get_viewport().get_canvas_transform()
    package_body.global_transform = canvas.affine_inverse() * Transform2D(0.0, (canvas * global_position).round())
    frame_provider._pose(package_body, frame.tex, frame.ancora, direction.x < 0)
    for child in package_fx.get_children(): child.free()
    for effect: Dictionary in frame.efeitos:
        if effect.fase not in ["ALL", "ACTIVE"]: continue
        var sprite := Sprite2D.new()
        sprite.centered = false
        package_fx.add_child(sprite)
        frame_provider._pose(sprite, effect.tex, effect.ancora, direction.x < 0)


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
