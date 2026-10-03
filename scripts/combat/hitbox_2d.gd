class_name Hitbox2D
extends Area2D

## Hitbox do jogo (base 3.4/3.5) com ÁREA DE DANO POR QUADRO (P40).
## Quando um quadro fornece formas, a hitbox nativa (pivô) fica desligada e as
## formas são consultadas no espaço físico a cada tick. Formas em pixels de tela
## relativos à âncora dos pés (x direita, y baixo); espelhadas por -x ao olhar
## para a esquerda; convertidas ao mundo dividindo pelo zoom.

signal hit_confirmed(context: HitContext)
signal before_hit(context: HitContext)
static var next_hit_uid := 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false
var template: HitContext
var struck_targets: Dictionary = {}
var frame_override_active := false
## Peças convexas em px (já decompostas). Cada item: PackedVector2Array.
var frame_parts: Array = []
var frame_feet_world := Vector2.ZERO
var frame_facing := 1
var frame_zoom := 0.9
var validation_error := ""
var armed_action_uid := -1
var last_query_count := 0


func _ready() -> void:
    collision_shape.shape = collision_shape.shape.duplicate()
    collision_shape.disabled = true
    area_entered.connect(_on_area_entered)


func arm(context: HitContext, attack: AttackData) -> void:
    template = context
    active = false
    clear_frame_override()
    if context.action_uid == 0 or armed_action_uid != context.action_uid:
        struck_targets.clear()
    armed_action_uid = context.action_uid
    position.x = attack.hitbox_center_x
    var rectangle := collision_shape.shape as RectangleShape2D
    rectangle.size = attack.hitbox_size
    active = true
    _sync_native_shape()


func disarm() -> void:
    active = false
    collision_shape.set_deferred("disabled", true)
    clear_frame_override()


## Retângulo [x, y, largura, altura] inteiros -> polígono de 4 pontos.
static func rect_to_polygon(entry: Array) -> PackedVector2Array:
    var x := float(entry[0])
    var y := float(entry[1])
    var w := float(entry[2])
    var h := float(entry[3])
    return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


static func validate_rectangles(rectangles: Variant) -> Dictionary:
    var parts: Array = []
    if not rectangles is Array:
        return {"valid": false, "partes": parts, "erro": "retangulos deve ser uma lista"}
    for index in range(rectangles.size()):
        var entry: Variant = rectangles[index]
        if not entry is Array or entry.size() != 4:
            return {"valid": false, "partes": parts, "erro": "retangulo %d deve conter x, y, largura, altura" % index}
        for component in entry:
            if typeof(component) != TYPE_INT and typeof(component) != TYPE_FLOAT:
                return {"valid": false, "partes": parts, "erro": "retangulo %d deve conter numeros" % index}
            if is_nan(float(component)) or is_inf(float(component)) or not is_equal_approx(float(component), roundf(float(component))):
                return {"valid": false, "partes": parts, "erro": "retangulo %d deve usar pixels inteiros finitos" % index}
        if float(entry[2]) <= 0.0 or float(entry[3]) <= 0.0:
            return {"valid": false, "partes": parts, "erro": "retangulo %d deve ter largura e altura positivas" % index}
        parts.append(rect_to_polygon(entry))
    return {"valid": true, "partes": parts, "erro": ""}


## Polígono (lista de [x,y]) possivelmente côncavo -> peças convexas.
static func polygon_to_parts(points: Variant) -> Dictionary:
    var parts: Array = []
    if not points is Array or points.size() < 3:
        return {"valid": false, "partes": parts, "erro": "poligono precisa de 3 ou mais pontos"}
    var polygon := PackedVector2Array()
    for point in points:
        if not point is Array or point.size() != 2:
            return {"valid": false, "partes": parts, "erro": "ponto deve ser [x, y]"}
        var px := float(point[0])
        var py := float(point[1])
        if is_nan(px) or is_inf(px) or is_nan(py) or is_inf(py):
            return {"valid": false, "partes": parts, "erro": "ponto nao finito"}
        polygon.append(Vector2(px, py))
    if Geometry2D.is_polygon_clockwise(polygon):
        polygon.reverse()
    for piece in Geometry2D.decompose_polygon_in_convex(polygon):
        parts.append(piece)
    if parts.is_empty():
        return {"valid": false, "partes": parts, "erro": "poligono nao decomponivel"}
    return {"valid": true, "partes": parts, "erro": ""}


func _sync_native_shape() -> void:
    if is_instance_valid(collision_shape):
        collision_shape.set_deferred("disabled", not active or frame_override_active)


func set_frame_parts(parts: Array, feet_world: Vector2, facing: int, zoom: float) -> void:
    if zoom <= 0.0 or is_nan(zoom) or is_inf(zoom):
        clear_frame_override()
        validation_error = "zoom deve ser positivo e finito"
        return
    frame_parts = parts.duplicate()
    frame_feet_world = feet_world
    frame_facing = -1 if facing < 0 else 1
    frame_zoom = zoom
    frame_override_active = true
    validation_error = ""
    _sync_native_shape()


func clear_frame_override() -> void:
    frame_override_active = false
    frame_parts.clear()
    validation_error = ""
    _sync_native_shape()


## Polígonos convexos em coordenadas de MUNDO (já espelhados).
func current_world_parts() -> Array:
    var result: Array = []
    if not active or not frame_override_active:
        return result
    for part: PackedVector2Array in frame_parts:
        var world := PackedVector2Array()
        for point in part:
            world.append(frame_feet_world + Vector2(point.x * frame_facing, point.y) / frame_zoom)
        result.append(world)
    return result


## Mesmas peças em px de tela relativos à âncora (para depuração/testes).
func current_screen_parts() -> Array:
    var result: Array = []
    if not frame_override_active:
        return result
    for part: PackedVector2Array in frame_parts:
        var screen := PackedVector2Array()
        for point in part:
            screen.append(Vector2(point.x * frame_facing, point.y))
        result.append(screen)
    return result


func scan_overlaps() -> void:
    if not active:
        return
    if frame_override_active:
        last_query_count = 0
        var space := get_world_2d().direct_space_state
        for world_part: PackedVector2Array in current_world_parts():
            var shape := ConvexPolygonShape2D.new()
            shape.points = world_part
            var query := PhysicsShapeQueryParameters2D.new()
            query.shape = shape
            query.transform = Transform2D.IDENTITY
            query.collision_mask = collision_mask
            query.collide_with_areas = true
            query.collide_with_bodies = false
            query.exclude = [get_rid()]
            for match_result in space.intersect_shape(query, 256):
                var area: Area2D = match_result.collider as Area2D
                last_query_count += 1
                if area != null:
                    _try_area(area, true)
        return
    for area in get_overlapping_areas():
        _try_area(area)


func _on_area_entered(area: Area2D) -> void:
    if frame_override_active:
        return
    _try_area(area)


func _try_area(area: Area2D, from_frame_query := false) -> void:
    if not active or template == null or not area is Hurtbox2D or (frame_override_active and not from_frame_query):
        return
    if area.receiver != null and area.receiver.get_parent() == template.attacker:
        return
    if from_frame_query and not _frame_contact_visible(area):
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


func _frame_contact_visible(area: Hurtbox2D) -> bool:
    # Profiled melee cannot pass through solid terrain. Actor bodies do not
    # occlude a sweep hitting multiple targets; their hurtboxes do receive it.
    var target_position := area.global_position
    var target_shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if target_shape != null:
        target_position = target_shape.global_position
    var excluded: Array[RID] = []
    if template.attacker is CollisionObject2D:
        excluded.append(template.attacker.get_rid())
    var ray := PhysicsRayQueryParameters2D.create(frame_feet_world - Vector2(0, 23.0 / frame_zoom), target_position, 1, excluded)
    var space := get_world_2d().direct_space_state
    for _i in range(32):
        var hit := space.intersect_ray(ray)
        if hit.is_empty() or hit.collider == area.get_parent():
            return true
        if not hit.collider is CharacterBody2D:
            return false
        excluded.append(hit.collider.get_rid())
        ray.exclude = excluded
    return false
