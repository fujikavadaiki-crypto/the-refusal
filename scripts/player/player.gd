extends CharacterBody2D

## Human protagonist foundation. Input stays here; movement and state tracking live in child nodes.
@onready var locomotion: PlayerLocomotion = $Locomotion
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var visual_root: Node2D = $VisualRoot
@onready var follow_camera: PlayerCamera = $Camera2D

var facing_direction := 1


func _physics_process(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")

    if not is_zero_approx(direction):
        facing_direction = -1 if direction < 0.0 else 1
        visual_root.scale.x = facing_direction

    locomotion.move(self, direction, jump_pressed, delta)
    state_machine.sync_with_body(self)
    follow_camera.update_look_ahead(facing_direction, delta)
