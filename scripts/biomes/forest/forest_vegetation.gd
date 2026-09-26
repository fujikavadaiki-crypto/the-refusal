extends Node2D

## Low, sparse foreground placeholders. Kept behind actors and telegraphs.
@export var world_length := 8200.0
@export var raised_start := 3300.0
@export var raised_end := 3800.0
@export var raised_ground_y := 214.0
@export var gap_start := 1892.0
@export var gap_end := 1970.0


func _draw() -> void:
    for i in range(98):
        var x := 72.0 + float(i) * 82.0 + float(i % 4) * 13.0
        if x > world_length:
            break
        var ground_y := raised_ground_y if x >= raised_start and x <= raised_end else 228.0
        if x > gap_start and x < gap_end:
            continue
        var height := 5.0 + float(i % 3) * 2.0
        draw_line(Vector2(x, ground_y), Vector2(x - 3, ground_y - height), Color(0.28, 0.40, 0.27), 2.0)
        draw_line(Vector2(x, ground_y), Vector2(x + 3, ground_y - height * 0.8), Color(0.23, 0.35, 0.23), 2.0)
