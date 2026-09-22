class_name PlayerStateMachine
extends Node

## Only the states needed by the first playable slice exist now.
signal state_changed(previous: State, current: State)

enum State { GROUNDED, AIRBORNE }

var current_state := State.AIRBORNE


func sync_with_body(body: CharacterBody2D) -> void:
    var next_state := State.GROUNDED if body.is_on_floor() else State.AIRBORNE
    if next_state == current_state:
        return
    var previous := current_state
    current_state = next_state
    state_changed.emit(previous, current_state)
