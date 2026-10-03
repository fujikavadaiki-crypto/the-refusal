extends SceneTree

var failed := false
var scene: Node2D
var player: CharacterBody2D
var combat: PlayerCombat
var dummy: StaticBody2D
var health: HealthComponent
var hit_stop: Node
var started: Array[StringName] = []
var hits: Array[HitContext] = []


func _initialize() -> void:
    call_deferred("run_checks")


func wait_frames(count: int) -> void:
    for _i in range(count):
        await physics_frame


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failed = true
        printerr("FAIL: ", description)


func press(action: StringName) -> void:
    Input.action_press(action)
    await wait_frames(2)
    Input.action_release(action)


func wait_idle() -> void:
    for _i in range(120):
        if not combat.is_busy():
            return
        await physics_frame
    check(false, "attack eventually returns to idle")


func reset_at(x: float, facing: int = 1) -> void:
    await wait_idle()
    await wait_frames(30)
    dummy.call("reset_dummy")
    started.clear()
    hits.clear()
    player.global_position = Vector2(x, 215)
    player.velocity = Vector2.ZERO
    player.set("facing_direction", facing)
    player.get_node("VisualRoot").scale.x = facing
    combat.set_facing(facing)
    await wait_frames(5)


func run_checks() -> void:
    scene = load("res://scenes/test_room.tscn").instantiate()
    root.add_child(scene)
    player = scene.get_node("Player")
    combat = player.get_node("Combat")
    dummy = scene.get_node("Dummy")
    health = dummy.get_node("Health")
    hit_stop = root.get_node("HitStop")
    combat.attack_started.connect(func(attack: AttackData, _uid: int): started.append(attack.attack_id))
    combat.hit_confirmed.connect(func(context: HitContext): hits.append(context))

    check(Engine.get_version_info().get("major") == 4 and Engine.get_version_info().get("minor") == 7, "Godot 4.7 runtime")
    check(InputMap.action_get_events("attack_light").size() == 2 and InputMap.action_get_events("attack_heavy").size() == 2, "keyboard and controller attack inputs")
    check(combat.light_1.base_damage == 20 and combat.light_2.base_damage == 22 and combat.light_3.base_damage == 28 and combat.heavy.base_damage == 35, "canonical HP damage")
    check(combat.light_1.posture_damage == 8 and combat.light_2.posture_damage == 9 and combat.light_3.posture_damage == 14 and combat.heavy.posture_damage == 25, "canonical future posture data")
    check(combat.heavy.recovery_seconds > combat.light_3.recovery_seconds and combat.light_3.recovery_seconds > combat.light_1.recovery_seconds, "attack commitment timing")

    await reset_at(374)
    var stop_before: int = hit_stop.get("request_count")
    await press(&"attack_light")
    await wait_frames(60)
    check(started == [&"light_1"], "Light 1 starts alone")
    check(health.current_health == 480 and int(dummy.get("hit_count")) == 1, "Light 1 deals 20 damage once")
    check(hits.size() == 1 and hits[0].attack_id == &"light_1" and hits[0].tags.has("light"), "Light hit context and tags")
    check(int(hit_stop.get("request_count")) == stop_before + 1 and int(hit_stop.get("last_requested_ms")) == 60, "valid Light impact requests 60 ms hit stop")
    check(not bool(hit_stop.get("active")) and is_equal_approx(Engine.time_scale, 1.0), "hit stop restores time scale")

    await reset_at(374)
    await press(&"attack_light")
    await press(&"attack_light")
    await wait_idle()
    check(started == [&"light_1"], "early repeated press cannot skip Light commitment")

    await reset_at(374)
    await press(&"attack_light")
    while combat.is_busy() and combat.elapsed < combat.current_attack.combo_queue_start_seconds:
        await physics_frame
    await press(&"attack_light")
    await wait_idle()
    await wait_frames(4)
    check(started == [&"light_1", &"light_2"], "timed re-press advances to Light 2")
    check(health.current_health == 458 and int(dummy.get("hit_count")) == 2, "Light 1→2 deals 20+22 once each")

    await reset_at(374)
    await press(&"attack_light")
    while combat.is_busy() and combat.elapsed < combat.current_attack.combo_queue_start_seconds:
        await physics_frame
    await press(&"attack_light")
    for _i in range(90):
        if combat.current_light_stage == 2 and combat.elapsed >= combat.light_2.combo_queue_start_seconds:
            break
        await physics_frame
    check(combat.current_light_stage == 2, "Light 2 reaches its queue window")
    await press(&"attack_light")
    await wait_idle()
    await wait_frames(4)
    check(started == [&"light_1", &"light_2", &"light_3"], "timed re-press advances to Light 3")
    check(health.current_health == 430 and int(dummy.get("hit_count")) == 3, "full combo deals 20+22+28 once each")
    if hits.size() == 3:
        check(hits[0].action_uid != hits[1].action_uid and hits[1].action_uid != hits[2].action_uid and hits[0].hit_uid != hits[1].hit_uid, "unique action and hit IDs")
    else:
        check(false, "three distinct hit contexts")

    await reset_at(374)
    await press(&"attack_light")
    await wait_frames(70)
    await press(&"attack_light")
    await wait_idle()
    check(started == [&"light_1", &"light_1"], "expired chain restarts at Light 1")
    check(health.current_health == 460, "expired chain has two 20-damage hits")

    await reset_at(374)
    stop_before = hit_stop.get("request_count")
    await press(&"attack_heavy")
    await wait_idle()
    check(started == [&"heavy"] and health.current_health == 465 and int(dummy.get("hit_count")) == 1, "Heavy deals 35 damage once")
    check(int(hit_stop.get("request_count")) == stop_before + 1 and int(hit_stop.get("last_requested_ms")) == 90, "valid Heavy impact requests 90 ms hit stop")

    await reset_at(426, -1)
    await press(&"attack_light")
    await wait_idle()
    check(health.current_health == 480 and int(dummy.get("hit_count")) == 1, "left facing mirrors sword and hitbox")

    await reset_at(374, 1)
    await press(&"attack_light")
    await wait_idle()
    check(health.current_health == 480, "right facing sword and hitbox")

    await reset_at(374)
    var second_hurtbox := Hurtbox2D.new()
    second_hurtbox.name = "SecondHurtbox"
    second_hurtbox.receiver_path = NodePath("../Health")
    second_hurtbox.collision_layer = 4
    second_hurtbox.collision_mask = 0
    var second_shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(18, 30)
    second_shape.shape = rectangle
    second_hurtbox.add_child(second_shape)
    dummy.add_child(second_hurtbox)
    await wait_frames(5)
    await press(&"attack_light")
    await wait_idle()
    check(health.current_health == 480 and int(dummy.get("hit_count")) == 1, "one action hits target once across multiple hurtboxes")
    second_hurtbox.queue_free()
    await wait_frames(3)

    await reset_at(1000)
    stop_before = hit_stop.get("request_count")
    await press(&"attack_light")
    await wait_idle()
    check(int(hit_stop.get("request_count")) == stop_before, "whiff does not trigger hit stop")

    await reset_at(2350)
    Input.action_press("move_right")
    await press(&"attack_heavy")
    await wait_frames(90)
    Input.action_release("move_right")
    check(player.global_position.x <= 2394.5 and not combat.is_busy(), "attack near wall keeps body collision")

    await reset_at(1000)
    Input.action_press("move_right")
    await press(&"attack_light")
    var light_start := player.global_position.x
    await wait_frames(12)
    var light_distance := player.global_position.x - light_start
    Input.action_release("move_right")
    await wait_idle()
    await reset_at(1000)
    Input.action_press("move_right")
    await press(&"attack_heavy")
    var heavy_start := player.global_position.x
    await wait_frames(12)
    var heavy_distance := player.global_position.x - heavy_start
    Input.action_release("move_right")
    await wait_idle()
    check(light_distance > heavy_distance and heavy_distance > 0.0, "movement continues with greater Heavy commitment")

    await reset_at(80)
    check(player.is_on_floor() and player.get_node("StateMachine").current_state == PlayerStateMachine.State.GROUNDED, "gravity and grounded state retained")
    Input.action_press("move_right")
    await wait_frames(70)
    Input.action_release("move_right")
    check(player.global_position.x > 170 and player.get_node("Camera2D").get_screen_center_position().x > 200, "movement and camera retained")
    await press(&"jump")
    check(not player.is_on_floor() and player.velocity.y < 0, "jump retained")
    await wait_frames(45)
    check(player.is_on_floor(), "jump lands without regression")

    dummy.call("reset_dummy")
    check(health.current_health == 500 and int(dummy.get("hit_count")) == 0, "dummy reset restores HP and count")
    check(combat.light_1.damage_type == &"physical" and combat.heavy.tags.has("heavy"), "damage type and Heavy tag")
    print("FINAL: ", "FAILED" if failed else "PASSED")
    quit(1 if failed else 0)
