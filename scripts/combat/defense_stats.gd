class_name DefenseStats
extends Node

## Additive defense within its own attribute; type resistance and vulnerability are separate.
@export_range(0.0, 1.0) var defense := 0.0
@export_range(0.0, 1.0) var temporary_defense := 0.0
@export_range(0.0, 1.0) var physical_resistance := 0.0
@export_range(0.0, 1.0) var magical_resistance := 0.0
@export_range(0.0, 1.0) var posture_resistance := 0.0
@export var vulnerability_bonus := 0.0
@export var magical_vulnerability_bonus := 0.0
@export var ground_heavy_posture_taken_multiplier := 1.0


func effective_defense() -> float:
    return minf(minf(defense, 0.70) + temporary_defense, 0.85)


func resistance_for(damage_type: StringName) -> float:
    match damage_type:
        &"physical":
            return physical_resistance
        &"magical":
            return magical_resistance
        _:
            return 0.0
