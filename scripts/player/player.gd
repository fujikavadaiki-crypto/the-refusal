extends CharacterBody2D

## Human protagonist: input routing and ownership of movement, combat, facing and camera.
@onready var locomotion: PlayerLocomotion = $Locomotion
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var combat: PlayerCombat = $Combat
@onready var defense: PlayerDefense = $Defense
@onready var visual_root: Node2D = $VisualRoot
@onready var follow_camera: PlayerCamera = $Camera2D

var facing_direction := 1


func _physics_process(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")
    if not is_zero_approx(direction) and not combat.is_busy() and not defense.is_locked():
        facing_direction = -1 if direction < 0.0 else 1
        visual_root.scale.x = facing_direction
        combat.set_facing(facing_direction)
        defense.set_facing(facing_direction)

    defense.accept_inputs(Input.is_action_just_pressed("dodge"), Input.is_action_just_pressed("parry"), direction, facing_direction, combat.is_busy())
    defense.tick(delta)
    if not defense.is_locked():
        combat.accept_inputs(Input.is_action_just_pressed("attack_light"), Input.is_action_just_pressed("attack_heavy"))
    combat.tick(delta)
    var movement := defense.movement_axis(direction) * combat.movement_multiplier()
    locomotion.move(self, movement, jump_pressed and not combat.is_busy() and not defense.is_locked(), delta)
    state_machine.sync_with_body(self)
    state_machine.sync_action(combat.is_busy(), defense.mode)
    follow_camera.update_look_ahead(facing_direction, delta)
