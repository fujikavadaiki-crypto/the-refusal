extends Node

## Shared feel settings. Physics profiles, AI and damage remain with their owners.
signal group_changed(group: String, enabled: bool)
const CONFIG_PATH := "res://data/config/sensacao.json"
const GROUPS := ["controle", "impacto", "movimento", "camera"]
const FEEDBACK := preload("res://scripts/feel/actor_feedback.gd")
const PIXELS := preload("res://scripts/feel/pixel_feedback.gd")
const PRESENTER := preload("res://scripts/enemies/presentation/enemy_presenter.gd")
var config: Dictionary = {}
var groups: Dictionary = {}
var selected := 0
var debug_controls := false
var pixels: Node2D
var label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
    groups = config.grupos_ligados.duplicate()
    var layer := CanvasLayer.new()
    layer.layer = 16
    add_child(layer)
    pixels = PIXELS.new()
    layer.add_child(pixels)
    label = Label.new()
    label.position = Vector2(12, 112)
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 2)
    layer.add_child(label)

func enabled(group: String) -> bool:
    return bool(groups.get(group, false))

func value(group: String, key: String) -> float:
    return float(config[group][key])

func set_group(group: String, state: bool) -> void:
    if not groups.has(group) or enabled(group) == state: return
    groups[group] = state
    group_changed.emit(group, state)

func set_all(state: bool) -> void:
    for group in GROUPS: set_group(group, state)

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    if key == KEY_F3:
        debug_controls = not debug_controls
    elif debug_controls and key in [KEY_G, KEY_H]:
        Input.action_release("training_heavy")
        Input.action_release("execute")
        if key == KEY_G: selected = (selected + 1) % GROUPS.size()
        else: set_group(GROUPS[selected], not enabled(GROUPS[selected]))
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    var items := PackedStringArray()
    for group in GROUPS:
        items.append(("[" if GROUPS[selected] == group else "") + group.to_upper() + ": " + ("ON" if enabled(group) else "OFF") + ("]" if GROUPS[selected] == group else ""))
    label.text = "Sensação · " + "  ".join(items) + ("\nG escolher · H alternar" if debug_controls else " · F3: G/H")
    label.visible = get_tree().current_scene != null

func attach_actor(actor: CharacterBody2D, mapping := "") -> void:
    if not actor.has_node("SensacaoAlvo"):
        var feedback := FEEDBACK.new()
        feedback.name = "SensacaoAlvo"
        actor.add_child(feedback)
    if not mapping.is_empty() and not actor.has_node("ApresentadorPacote"):
        var presenter := PRESENTER.new()
        presenter.name = "ApresentadorPacote"
        actor.add_child(presenter)
        presenter.bind_actor(actor, mapping)
        actor.get_node("Attack").frame_provider = presenter
