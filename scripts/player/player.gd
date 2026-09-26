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
    var dodge_pressed := Input.is_action_just_pressed("dodge")
    if dodge_pressed:
        combat.cancel_charge()
    defense.accept_inputs(dodge_pressed, Input.is_action_just_pressed("parry"), direction, facing_direction, combat.is_busy())
    defense.tick(delta)
    if defense.can_cancel_dash_for_attack() and (light_pressed or heavy_pressed):
        if combat.accept_inputs(light_pressed, heavy_pressed, defense.mode):
            defense.cancel_dash_for_attack(heavy_pressed)
    elif not defense.is_locked():
        if Input.is_action_just_pressed("mask_skill_1"):
            masks.use_skill(1)
        elif Input.is_action_just_pressed("mask_skill_2"):
            masks.use_skill(2)
        else:
            combat.accept_inputs(light_pressed, heavy_pressed)
    combat.tick(delta)
    var movement := defense.movement_axis(direction) * combat.movement_multiplier()
    locomotion.move(self, movement, jump_pressed and not combat.is_busy() and not defense.is_locked(), delta, defense.suspends_gravity(), Input.is_action_pressed("walk"))
    defense.sync_grounding()
    state_machine.sync_with_body(self)
    state_machine.sync_action(combat.is_busy(), defense.mode)
    follow_camera.update_look_ahead(facing_direction, delta)
