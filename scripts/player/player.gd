extends CharacterBody2D

## Human protagonist: input routing and ownership of movement, combat, facing and camera.
@onready var locomotion: PlayerLocomotion = $Locomotion
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var combat: PlayerCombat = $Combat
@onready var defense: PlayerDefense = $Defense
@onready var visual_root: Node2D = $VisualRoot
@onready var follow_camera: PlayerCamera = $Camera2D
@onready var masks: MaskController = $MaskController

var facing_direction := 1
var light_buffer_remaining := 0.0
var heavy_buffer_remaining := 0.0
const ATTACK_BUFFER_SECONDS := 0.16
const SMALL_REFERENCE_ZOOM := 0.9
const SMALL_RADIUS := 7.0 / SMALL_REFERENCE_ZOOM
const SMALL_HEIGHT := 46.0 / SMALL_REFERENCE_ZOOM
const SMALL_PIVOT_HEIGHT_ABOVE_FEET := 0.84 * PlayerLocomotion.P40_UNITS_PER_METER
var human_body_shape: CapsuleShape2D
var human_hurt_shape: CapsuleShape2D
var human_body_center := Vector2.ZERO
var human_hurt_center := Vector2.ZERO
var human_pivot_y := 0.0
var feet_y := 0.0


func clear_action_buffers() -> void:
    light_buffer_remaining = 0.0
    heavy_buffer_remaining = 0.0


func _ready() -> void:
    # Keep independent originals: the shared scene and human profile stay intact.
    human_body_shape = $CollisionShape2D.shape.duplicate()
    human_hurt_shape = $Hurtbox/CollisionShape2D.shape.duplicate()
    human_body_center = $CollisionShape2D.position
    human_hurt_center = $Hurtbox/CollisionShape2D.position
    human_pivot_y = $AttackPivot.position.y
    feet_y = human_body_center.y + human_body_shape.height / 2.0
    masks.mask_changed.connect(_apply_body_profile)
    _apply_body_profile(masks.active_data())
    combat.hit_confirmed.connect(_on_hit_confirmed)
    $Health.damage_taken.connect(_on_damage_taken)


func _is_small_carrasco(data: MaskData) -> bool:
    return data != null and data.mask_id == &"carrasco_base"


func _small_capsule() -> CapsuleShape2D:
    var capsule := CapsuleShape2D.new()
    capsule.radius = SMALL_RADIUS
    capsule.height = SMALL_HEIGHT
    return capsule


func _apply_body_profile(data: MaskData) -> void:
    var small := _is_small_carrasco(data)
    $CollisionShape2D.shape = _small_capsule() if small else human_body_shape.duplicate()
    $Hurtbox/CollisionShape2D.shape = _small_capsule() if small else human_hurt_shape.duplicate()
    var small_center := Vector2(human_body_center.x, feet_y - SMALL_HEIGHT / 2.0)
    $CollisionShape2D.position = small_center if small else human_body_center
    $Hurtbox/CollisionShape2D.position = small_center if small else human_hurt_center
    $AttackPivot.position.y = feet_y - SMALL_PIVOT_HEIGHT_ABOVE_FEET if small else human_pivot_y


func can_change_body_profile(data: MaskData) -> bool:
    # A larger form cannot materialize through a low ceiling or narrow wall.
    # Keep the same feet/origin; a rejected swap consumes no cooldown or ultimate.
    var small := _is_small_carrasco(data)
    var capsule := _small_capsule() if small else human_body_shape.duplicate() as CapsuleShape2D
    capsule.radius -= 0.01
    capsule.height -= 0.02
    var center := Vector2(human_body_center.x, feet_y - SMALL_HEIGHT / 2.0) if small else human_body_center
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = capsule
    query.transform = global_transform * Transform2D(0.0, center)
    query.collision_mask = collision_mask
    query.exclude = [get_rid()]
    query.collide_with_areas = false
    return get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _physics_process(delta: float) -> void:
    masks.tick(delta)
    if Input.is_action_just_pressed("mask_swap"):
        masks.swap()
    if Input.is_action_just_pressed("mask_ultimate"):
        masks.use_ultimate()
    if Input.is_action_just_pressed("execute"):
        masks.try_execute()
    var direction := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")
    if not is_zero_approx(direction) and not combat.is_busy() and not defense.is_locked():
        facing_direction = -1 if direction < 0.0 else 1
        visual_root.scale.x = facing_direction
        combat.set_facing(facing_direction)
        defense.set_facing(facing_direction)

    var light_pressed := Input.is_action_just_pressed("attack_light")
    var heavy_pressed := Input.is_action_just_pressed("attack_heavy")
    light_buffer_remaining = ATTACK_BUFFER_SECONDS if light_pressed else maxf(0.0, light_buffer_remaining - delta)
    heavy_buffer_remaining = ATTACK_BUFFER_SECONDS if heavy_pressed else maxf(0.0, heavy_buffer_remaining - delta)
    var dodge_pressed := Input.is_action_just_pressed("dodge")
    if dodge_pressed:
        combat.cancel_charge()
    defense.accept_inputs(dodge_pressed, Input.is_action_just_pressed("parry"), direction, facing_direction, combat.is_busy())
    defense.tick(delta)
    if defense.is_dashing() and not defense.can_cancel_dash_for_attack() and (light_pressed or heavy_pressed):
        # The approved dash cancel window starts at 80 ms; an earlier press cannot pre-cancel it.
        light_buffer_remaining = 0.0
        heavy_buffer_remaining = 0.0
    var wants_light := light_buffer_remaining > 0.0
    var wants_heavy := heavy_buffer_remaining > 0.0
    if defense.can_cancel_dash_for_attack() and (wants_light or wants_heavy):
        if combat.accept_inputs(wants_light and not wants_heavy, wants_heavy, defense.mode):
            defense.cancel_dash_for_attack(wants_heavy)
            light_buffer_remaining = 0.0
            heavy_buffer_remaining = 0.0
    elif not defense.is_locked():
        if Input.is_action_just_pressed("mask_skill_1"):
            masks.use_skill(1)
        elif Input.is_action_just_pressed("mask_skill_2"):
            masks.use_skill(2)
        else:
            if combat.accept_inputs(wants_light and not wants_heavy, wants_heavy):
                light_buffer_remaining = 0.0
                heavy_buffer_remaining = 0.0
            elif light_pressed and combat.current_light_stage > 0:
                # The combat component owns the queued combo input.
                light_buffer_remaining = 0.0
    combat.tick(delta)
    var movement := defense.movement_axis(direction) * combat.movement_multiplier()
    locomotion.move(self, movement, jump_pressed, delta, defense.suspends_gravity(), Input.is_action_pressed("walk") and not defense.is_dashing(), not combat.is_busy() and not defense.is_locked(), defense.dash_speed if defense.is_dashing() else -1.0)
    defense.sync_grounding()
    state_machine.sync_with_body(self)
    state_machine.sync_action(combat.is_busy(), defense.mode)
    follow_camera.update_look_ahead(facing_direction, delta)


func _on_hit_confirmed(context: HitContext) -> void:
    if context.outcome == HitContext.Outcome.DAMAGED or context.outcome == HitContext.Outcome.DEAD:
        follow_camera.add_impact(4.0 if context.tags.has("heavy") else 1.5)


func _on_damage_taken(context: HitContext) -> void:
    if context.attacker != null:
        var away := signf(global_position.x - context.attacker.global_position.x)
        velocity.x = (away if not is_zero_approx(away) else -float(facing_direction)) * 100.0
    follow_camera.add_impact(2.0)
