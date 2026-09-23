class_name ForestEncounter
extends Node2D

signal activated
signal completed

@export var activation_half_width := 345.0 # Provisional stage layout distance.
@export var player_path: NodePath = NodePath("../../Player")

@onready var player: CharacterBody2D = get_node_or_null(player_path) as CharacterBody2D

var enemies: Array[CharacterBody2D] = []
var is_active := false
var is_completed := false


func _enter_tree() -> void:
    # Set before each Brain resolves its onready player reference.
    for child in get_children():
        if child is CharacterBody2D and child.has_node("Brain"):
            child.get_node("Brain").player_path = NodePath("../../../../Player")


func _ready() -> void:
    for child in get_children():
        if child is CharacterBody2D and child.has_method("reset_enemy"):
            enemies.append(child)
            child.process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    if not is_active and absf(player.global_position.x - global_position.x) <= activation_half_width:
        is_active = true
        for enemy in enemies:
            enemy.process_mode = Node.PROCESS_MODE_INHERIT
        activated.emit()
    if is_active and not is_completed:
        var all_dead := true
        for enemy in enemies:
            if enemy.get_node("Health").current_health > 0:
                all_dead = false
                break
        if all_dead:
            is_completed = true
            completed.emit()


func reset_encounter() -> void:
    is_active = false
    is_completed = false
    for enemy in enemies:
        enemy.process_mode = Node.PROCESS_MODE_INHERIT
        enemy.reset_enemy()
        enemy.process_mode = Node.PROCESS_MODE_DISABLED


func living_count() -> int:
    var total := 0
    for enemy in enemies:
        if enemy.get_node("Health").current_health > 0:
            total += 1
    return total
