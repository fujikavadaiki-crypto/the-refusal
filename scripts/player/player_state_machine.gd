class_name PlayerStateMachine
extends Node

## Locomotion and action tracks are orthogonal; future actions can add states here.
signal state_changed(previous: State, current: State)
signal action_state_changed(previous: ActionState, current: ActionState)

enum State { GROUNDED, AIRBORNE }
enum ActionState { FREE, ATTACKING }

var current_state := State.AIRBORNE
var current_action_state := ActionState.FREE


func sync_with_body(body: CharacterBody2D) -> void:
    var next_state := State.GROUNDED if body.is_on_floor() else State.AIRBORNE
    if next_state == current_state:
        return
    var previous := current_state
    current_state = next_state
    state_changed.emit(previous, current_state)


func sync_action(attacking: bool) -> void:
    var next_state := ActionState.ATTACKING if attacking else ActionState.FREE
    if next_state == current_action_state:
        return
    var previous := current_action_state
    current_action_state = next_state
    action_state_changed.emit(previous, current_action_state)
