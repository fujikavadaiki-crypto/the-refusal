extends Node

## Integration copy only: route F9 without modifying either Bosque scene/script.
const CEMITERIO := "res://scenes/biomes/cemiterio/sala_cemiterio.tscn"
const BOSQUE := "res://scenes/biomes/forest/bosque_integracao_p40.tscn"
var switching := false

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo or event.keycode!=KEY_F9 or switching:
        return
    var current: Node=get_tree().current_scene
    if current==null: return
    switching=true
    var target:=BOSQUE if current.scene_file_path==CEMITERIO else CEMITERIO
    _switch.call_deferred(target)
    get_viewport().set_input_as_handled()

func _switch(target: String) -> void:
    get_node("/root/HitStop")._restore()
    for action in InputMap.get_actions(): Input.action_release(action)
    get_tree().debug_collisions_hint=false
    get_node("/root/Sensacao").debug_controls=false
    var error:=get_tree().change_scene_to_file(target)
    if error!=OK: push_error("Não foi possível abrir a sala: %s" % target)
    await get_tree().process_frame
    switching=false
