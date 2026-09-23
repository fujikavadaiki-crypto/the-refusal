extends Node2D

## Low, sparse foreground placeholders. Kept behind actors and telegraphs.
@export var world_length := 8200.0


func _draw() -> void:
    for i in range(98):
        var x := 72.0 + float(i) * 82.0 + float(i % 4) * 13.0
        var ground_y := 214.0 if x >= 3300.0 and x <= 3800.0 else 228.0
        if x > 1892.0 and x < 1970.0:
            continue
        var height := 5.0 + float(i % 3) * 2.0
        draw_line(Vector2(x, ground_y), Vector2(x - 3, ground_y - height), Color(0.28, 0.40, 0.27), 2.0)
        draw_line(Vector2(x, ground_y), Vector2(x + 3, ground_y - height * 0.8), Color(0.23, 0.35, 0.23), 2.0)
