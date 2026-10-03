class_name PlayerCamera
extends Camera2D

## Shared fixed/follow camera. Render offset is always an integer screen pixel.
@export var look_ahead_pixels := 60.0 # Retains compatibility with serialized rooms.
@export var shift_speed := 240.0
@export var impact_shake_enabled := false

var shake_remaining := 0.0
var shake_strength := 0.0
var look := 0.0
var player: CharacterBody2D
var background_root: Node2D

func _ready() -> void:
    get_node("/root/Sensacao").group_changed.connect(_group_changed)

func bind_fixed(owner_player: CharacterBody2D, background_: Node2D) -> void:
    player = owner_player
    background_root = background_


func _process(delta: float) -> void:
    var feel := get_node("/root/Sensacao")
    var target := 0.0
    if feel.enabled("camera") and is_instance_valid(player) and absf(player.velocity.x) > feel.value("camera", "limiar_corrida_m_s") * (32.0 / .9):
        target = signf(player.velocity.x) * feel.value("camera", "antecipacao_px")
    look = lerpf(look, target, 1.0 - exp(-feel.value("camera", "suavizacao_s_inversa") * delta)) if feel.enabled("camera") else 0.0
    var shake := Vector2.ZERO
    if shake_remaining > 0.0 and feel.enabled("impacto"):
        shake_remaining = maxf(0, shake_remaining - delta / maxf(Engine.time_scale, .0001))
        var fade: float = shake_remaining / (feel.value("impacto", "tremor_ms") / 1000.0)
        var time := Time.get_ticks_msec() * .001
        shake = Vector2(sin(time * feel.value("impacto", "tremor_x_rad_s")), cos(time * feel.value("impacto", "tremor_y_rad_s"))) * shake_strength * fade
    var screen := (Vector2(look, 0) + shake).round()
    offset = screen / zoom
    if is_instance_valid(background_root): background_root.position = -screen


func add_impact(_strength: float) -> void:
    add_heavy_impact()

func add_heavy_impact() -> void:
    var feel := get_node("/root/Sensacao")
    if not feel.enabled("impacto"): return
    shake_strength = feel.value("impacto", "tremor_px")
    shake_remaining = feel.value("impacto", "tremor_ms") / 1000.0

func _group_changed(group: String, state: bool) -> void:
    if group == "impacto" and not state: clear_impact()
    if group == "camera" and not state: look = 0.0


func clear_impact() -> void:
    shake_remaining = 0.0
    shake_strength = 0.0
    offset = Vector2.ZERO


func update_look_ahead(_facing_direction: int, _delta: float) -> void:
    if player == null and get_parent() is CharacterBody2D: player = get_parent()
