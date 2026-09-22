extends Node

## Central real-time pause. A low time scale preserves input/physics ticks during brief impacts.
const IMPACT_TIME_SCALE := 0.08

var active := false
var end_tick_usec := 0
var previous_time_scale := 1.0
var request_count := 0
var last_requested_ms := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func request_ms(duration_ms: int) -> void:
    if duration_ms <= 0:
        return
    request_count += 1
    last_requested_ms = duration_ms
    end_tick_usec = maxi(end_tick_usec, Time.get_ticks_usec() + duration_ms * 1000)
    if not active:
        previous_time_scale = Engine.time_scale
        Engine.time_scale = IMPACT_TIME_SCALE
        active = true


func _process(_delta: float) -> void:
    if active and Time.get_ticks_usec() >= end_tick_usec:
        _restore()


func _exit_tree() -> void:
    if active:
        _restore()


func _restore() -> void:
    Engine.time_scale = previous_time_scale
    active = false
    end_tick_usec = 0
