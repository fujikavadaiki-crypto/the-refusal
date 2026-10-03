extends Node

## Central real-time pause. A low time scale preserves input/physics ticks during brief impacts.

var active := false
var end_tick_usec := 0
var previous_time_scale := 1.0
var request_count := 0
var last_requested_ms := 0
var active_priority := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func request_ms(duration_ms: int, priority := 1) -> void:
    var feel := get_node_or_null("/root/Sensacao")
    if feel != null and not feel.enabled("impacto"): return
    if duration_ms <= 0:
        return
    if active and priority < active_priority:
        return
    request_count += 1
    last_requested_ms = duration_ms
    active_priority = priority
    end_tick_usec = maxi(end_tick_usec, Time.get_ticks_usec() + duration_ms * 1000)
    if not active:
        previous_time_scale = Engine.time_scale
        Engine.time_scale = feel.value("impacto", "escala_tempo_hitstop") if feel != null else 1.0
        active = true


func _process(_delta: float) -> void:
    if active and not get_node("/root/Sensacao").enabled("impacto"): _restore()
    if active and Time.get_ticks_usec() >= end_tick_usec:
        _restore()


func _exit_tree() -> void:
    if active:
        _restore()


func _restore() -> void:
    Engine.time_scale = previous_time_scale
    active = false
    end_tick_usec = 0
    active_priority = 0

func request_hit(context: HitContext) -> void:
    var feel := get_node("/root/Sensacao")
    request_ms(int(feel.value("impacto", "hitstop_pesado_ms" if context.tags.has("heavy") else "hitstop_leve_ms")), 2 if context.tags.has("heavy") else 1)
