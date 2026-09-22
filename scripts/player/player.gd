extends CharacterBody2D

## Human protagonist: input routing and ownership of movement, combat, facing and camera.
@onready var locomotion: PlayerLocomotion = $Locomotion
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var combat: PlayerCombat = $Combat
@onready var visual_root: Node2D = $VisualRoot
@onready var follow_camera: PlayerCamera = $Camera2D

var facing_direction := 1


func _physics_process(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")
    if not is_zero_approx(direction) and not combat.is_busy():
        facing_direction = -1 if direction < 0.0 else 1
        visual_root.scale.x = facing_direction
        combat.set_facing(facing_direction)

    combat.accept_inputs(Input.is_action_just_pressed("attack_light"), Input.is_action_just_pressed("attack_heavy"))
    combat.tick(delta)
    locomotion.move(self, direction * combat.movement_multiplier(), jump_pressed and not combat.is_busy(), delta)
    state_machine.sync_with_body(self)
    state_machine.sync_action(combat.is_busy())
    follow_camera.update_look_ahead(facing_direction, delta)
