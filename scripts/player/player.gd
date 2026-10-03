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
var dash_buffer_remaining := 0.0
const SMALL_REFERENCE_ZOOM := 0.9
## Phase 3 decision: equal radius to human; height and feet retain P40 conversion.
const SMALL_RADIUS := 7.0
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
    dash_buffer_remaining = 0.0


func _ready() -> void:
    add_to_group("feel_players")
    get_node("/root/Sensacao").attach_actor(self)
    get_node("/root/Sensacao").group_changed.connect(_feel_group_changed)
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
    $Health.reset_done.connect(_reset_feel_state)
    $Health.depleted.connect(clear_action_buffers)


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
    if Input.is_action_just_pressed("execute") and not get_node("/root/Sensacao").debug_controls:
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
    var feel := get_node("/root/Sensacao")
    var assisted: bool = feel.enabled("controle")
    var attack_buffer: float = feel.value("controle", "buffer_ataque_ms") / 1000.0 if assisted else delta
    light_buffer_remaining = attack_buffer if light_pressed else maxf(0.0, light_buffer_remaining - delta)
    heavy_buffer_remaining = attack_buffer if heavy_pressed else maxf(0.0, heavy_buffer_remaining - delta)
    var dash_pressed := Input.is_action_just_pressed("dodge")
    dash_buffer_remaining = (feel.value("controle", "buffer_dash_ms") / 1000.0 if assisted else delta) if dash_pressed else maxf(0.0, dash_buffer_remaining - delta)
    var dodge_pressed := dash_buffer_remaining > 0.0
    if dodge_pressed:
        combat.cancel_charge()
        var can_dash := defense.mode == PlayerDefense.Mode.READY and ((is_on_floor() and defense.dodge_cooldown <= 0) or (not is_on_floor() and defense.air_dash_available))
        if can_dash and assisted and bool(feel.config.controle.dash_cancela_recuperacao_leve) and combat.phase == PlayerCombat.Phase.RECOVERY and combat.current_light_stage > 0:
            combat.abort_attack()
    defense.accept_inputs(dodge_pressed, Input.is_action_just_pressed("parry"), direction, facing_direction, combat.is_busy())
    if defense.is_dashing(): dash_buffer_remaining = 0.0
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
    locomotion.move(self, movement, jump_pressed, delta, defense.suspends_gravity(), Input.is_action_pressed("walk") and not defense.is_dashing(), not combat.is_busy() and not defense.is_locked(), defense.dash_speed if defense.is_dashing() else -1.0, Input.is_action_pressed("jump"))
    # Frame polygons follow the resolved feet, before the first damage query.
    combat.resolve_frame_contact()
    defense.sync_grounding()
    state_machine.sync_with_body(self)
    state_machine.sync_action(combat.is_busy(), defense.mode)
    follow_camera.update_look_ahead(facing_direction, delta)


func _on_hit_confirmed(context: HitContext) -> void:
    pass # Recipient feedback owns impact shake for the active room camera.


func _on_damage_taken(context: HitContext) -> void:
    pass # Shared recipient component owns flash/recoil/blood.

func _feel_group_changed(group: String, state: bool) -> void:
    if group == "controle" and not state:
        clear_action_buffers()
        locomotion.reset_assists()
        combat.queued_next = false

func _reset_feel_state() -> void:
    clear_action_buffers()
    locomotion.reset_assists()
    set_meta("landing_offset_px", 0)
    get_node("/root/Sensacao").pixels.previous.erase(self)
