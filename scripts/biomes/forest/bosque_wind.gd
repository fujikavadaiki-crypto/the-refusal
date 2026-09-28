extends Node

## One slow wind field shared by painted vegetation, particles and canopy light.
const CYCLE_SECONDS := 21.0
const GUST_START := 3.0
const GUST_PEAK := 5.5
const GUST_RELEASE := 8.0
const GUST_END := 12.0

var clock := 0.0


func _ready() -> void:
    add_to_group("bosque_wind")


func _process(delta: float) -> void:
    clock += delta


func gust(delay: float = 0.0) -> float:
    var cycle_time := fposmod(maxf(0.0, clock - delay), CYCLE_SECONDS)
    var enter := smoothstep(GUST_START, GUST_PEAK, cycle_time)
    var leave := 1.0 - smoothstep(GUST_RELEASE, GUST_END, cycle_time)
    return enter * leave


func sample(delay: float = 0.0, phase: float = 0.0) -> float:
    var t := maxf(0.0, clock - delay)
    var normal := 0.25 + 0.08 * sin(t * 0.59 + phase)
    var wave := sin(t * 1.04 + phase) * 0.23 + sin(t * 0.41 + phase * 1.71) * 0.12
    return normal + (0.25 + 0.75 * gust(delay)) * wave + 0.85 * gust(delay)
