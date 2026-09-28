extends Node2D
## Fixed-camera, ten-second ambient loop for the approved 1900 x 633 painting.
## No gameplay node, collision or camera is part of this scene.

const LOOP_SECONDS := 10.0
const ART_SIZE := Vector2(1900.0, 633.0)
const TAU_VALUE := PI * 2.0

@onready var approved_art: Sprite2D = $BACKGROUND/ApprovedComposition
@onready var ambient: Node2D = $AMBIENT

var elapsed := 0.0


func _ready() -> void:
	assert(approved_art.texture.get_size() == ART_SIZE)
	approved_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ambient.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_loop_time(0.0)


func _process(delta: float) -> void:
	set_loop_time(elapsed + delta)


func set_loop_time(seconds: float) -> void:
	elapsed = fposmod(seconds, LOOP_SECONDS)
	var phase := elapsed / LOOP_SECONDS
	(approved_art.material as ShaderMaterial).set_shader_parameter("loop_phase", phase)
	ambient.call("set_loop_phase", phase)
