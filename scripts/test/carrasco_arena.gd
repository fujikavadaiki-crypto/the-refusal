extends Node2D

const CARRASCO := preload("res://data/masks/carrasco_base.tres")
@onready var player: CharacterBody2D = $TestRoom/Player
@onready var dummy: Node2D = $TestRoom/Dummy
@onready var elite_dummy: Node2D = $EliteDummy
@onready var pilgrim: Node2D = $Peregrino
@onready var readout: Label = $TechnicalHUD/Panel/Readout
var cues: Dictionary = {}


func _ready() -> void:
    player.global_position = Vector2(320, 215)
    player.velocity = Vector2.ZERO
    player.masks.equip(0, CARRASCO)
    elite_dummy.set_meta("execution_tier", &"elite")
    for target in [dummy, elite_dummy, pilgrim]:
        var cue := Label.new()
        cue.position = Vector2(-36, -76)
        cue.add_theme_font_size_override("font_size", 9)
        cue.add_theme_color_override("font_color", Color(1.0, 0.58, 0.32))
        target.add_child(cue)
        cues[target] = cue


func _process(_delta: float) -> void:
    var state := player.masks.active_state() as CarrascoRuntimeState
    var saved := player.masks.slots[0] as CarrascoRuntimeState
    if Input.is_action_just_pressed("reset_dummy") and saved != null:
        for candidate in cues.keys():
            saved.clear_target(candidate)
    for candidate in cues.keys():
        var eligible_candidate := state != null and ExecutionResolver.is_eligible(state, candidate)
        var extended := eligible_candidate and not (candidate.get_node("Posture") as PostureComponent).is_ruptured()
        (cues[candidate] as Label).text = "EXECUTABLE +1s" if extended else ("EXECUTABLE" if eligible_candidate else "")
    var target := _nearest_target()
    var stack_count := saved.stacks_for(target) if saved != null else 0
    var selectable: Node2D = player.masks.targeting.best_target(state, player)
    var name_text: String = player.masks.active_data().display_name if player.masks.active_data() != null else "Human"
    var reserve: MaskRuntimeState = player.masks.slots[1]
    var reserve_text: String = reserve.data.display_name if reserve != null else "Empty"
    var combat := player.get_node("Combat") as PlayerCombat
    var charge_text := "CHARGED READY" if combat.charge_ready() else ("CHARGING %.1f" % combat.charge_elapsed if combat.is_charging() else "-")
    readout.text = "MASK %s | B: %s | SWAP %.1f\nSKILL 1 %.1f  SKILL 2 %.1f  ULT %.1f / %.1f\n%s COND %d/5 | %s | %s\nK=Heavy tap/hold; U/O/P/Tab; H=execute; R=reset" % [name_text, reserve_text, player.masks.swap_cooldown_remaining, saved.skill_1_remaining if saved != null else 0.0, saved.skill_2_remaining if saved != null else 0.0, saved.ultimate_cooldown_remaining if saved != null else 0.0, saved.ultimate_remaining if saved != null else 0.0, target.name if target != null else "No target", stack_count, selectable.name if selectable != null else "No execution", charge_text]


func _nearest_target() -> Node2D:
    var candidates: Array[Node2D] = [dummy, elite_dummy, pilgrim]
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
