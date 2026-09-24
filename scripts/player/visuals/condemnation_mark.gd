extends Node2D

## Five small ritual segments indicate the actual runtime stack count.
var stacks := 0


func set_stacks(value: int) -> void:
    if stacks == value:
        return
    stacks = clampi(value, 0, 5)
    queue_redraw()


func _draw() -> void:
    var dull := Color("5f4138")
    var lit := Color("c8875c")
    draw_rect(Rect2(-4, -4, 8, 1), dull)
    draw_rect(Rect2(-1, -7, 2, 10), dull)
    for index in range(5):
        var x := -6 + index * 3
        draw_rect(Rect2(x, 4, 2, 2), lit if index < stacks else dull)
    if stacks >= 3:
        draw_rect(Rect2(-2, -3, 4, 1), lit)
    if stacks == 5:
        draw_rect(Rect2(-6, -5, 2, 2), lit)
        draw_rect(Rect2(4, -5, 2, 2), lit)
