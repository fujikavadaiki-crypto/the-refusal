extends Node2D

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
@onready var player: CharacterBody2D = $TestRoom/Player
@onready var dummy: Node2D = $TestRoom/Dummy
@onready var pilgrim: Node2D = $Peregrino
@onready var readout: Label = $TechnicalHUD/Panel/Readout


func _ready() -> void:
    player.global_position = Vector2(320, 215)
    player.velocity = Vector2.ZERO
    player.masks.equip(0, CARRASCO)


func _process(_delta: float) -> void:
    var state := player.masks.active_state() as CarrascoRuntimeState
    var saved := player.masks.slots[0] as CarrascoRuntimeState
    if Input.is_action_just_pressed("reset_dummy") and saved != null:
        saved.clear_target(dummy)
    var target := _nearest_target()
    var stack_count := saved.stacks_for(target) if saved != null else 0
    var eligible := state != null and ExecutionResolver.is_eligible(state, target)
    var name_text: String = player.masks.active_data().display_name if player.masks.active_data() != null else "Human"
    readout.text = "MASK %s | B: Empty | SWAP %.1f\nSKILL 1 %.1f  SKILL 2 %.1f  ULT %.1f / %.1f\n%s CONDEMNATION %d/5 %s\nU/O/P/Tab; H=execute test; R=reset dummy" % [name_text, player.masks.swap_cooldown_remaining, saved.skill_1_remaining if saved != null else 0.0, saved.skill_2_remaining if saved != null else 0.0, saved.ultimate_cooldown_remaining if saved != null else 0.0, saved.ultimate_remaining if saved != null else 0.0, target.name if target != null else "No target", stack_count, "EXECUTABLE" if eligible else ""]
    if Input.is_action_just_pressed("test_execution") and eligible and target != null and player.global_position.distance_to(target.global_position) < 58.0:
        ExecutionResolver.execute(state, player, target)


func _nearest_target() -> Node2D:
    var candidates: Array[Node2D] = [dummy, pilgrim]
    var chosen: Node2D
    var distance := INF
    for candidate in candidates:
        if candidate == null or not is_instance_valid(candidate):
            continue
        var health := candidate.get_node_or_null("Health") as HealthComponent
        if health == null or health.current_health <= 0:
            continue
        var candidate_distance := player.global_position.distance_to(candidate.global_position)
        if candidate_distance < distance:
            chosen = candidate
            distance = candidate_distance
    return chosen
