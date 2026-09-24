extends Node2D

## Short, local, hard-edge effects. No gameplay collision or damage.
var kind: StringName = &"slash"
var direction := 1
var age := 0.0
var lifetime := 0.20


func start(effect_kind: StringName, facing: int) -> void:
    kind = effect_kind
    direction = facing
    lifetime = 0.30 if kind in [&"execution", &"sentence", &"seal_break"] else 0.20
    queue_redraw()


func _process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
    else:
        queue_redraw()


func _draw() -> void:
    var t := age / lifetime
    var alpha := 1.0 - t
    var color := Color("c7b59a")
    var reach := 9
    match kind:
        &"heavy":
            color = Color("d0b685")
            reach = 13
        &"charged":
            color = Color("f0c17a")
            reach = 16
        &"posture":
            color = Color("8ea7aa")
            reach = 11
        &"seal_break":
            color = Color("b2c3bb")
            reach = 16
        &"mark":
            color = Color("b77553")
            reach = 8
        &"execution", &"sentence":
            color = Color("da9b65")
            reach = 17 if kind == &"execution" else 13
    color.a = alpha
    var r := reach + roundi(4.0 * t)
    draw_rect(Rect2(-r * direction, -2, 2 * r, 2), color)
    draw_rect(Rect2(-2, -r, 2, 2 * r), color)
    if kind in [&"posture", &"seal_break", &"charged"]:
        draw_rect(Rect2(-r / 2.0, -r / 2.0, 2, 3), color)
        draw_rect(Rect2(r / 2.0, r / 2.0, 2, 3), color)
    if kind in [&"execution", &"sentence"]:
        draw_rect(Rect2(-r / 2.0, -r / 2.0, r, 2), color)
        draw_rect(Rect2(-r / 2.0, r / 2.0, r, 2), color)
