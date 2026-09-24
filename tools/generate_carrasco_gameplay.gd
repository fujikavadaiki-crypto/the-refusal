extends SceneTree

## Reproducible native-pixel artwork for the approved Base design.
## Run in Godot 4.7.2: --headless --path . --script res://tools/generate_carrasco_gameplay.gd
const TILE := Vector2i(64, 48)
const PIVOT := Vector2i(17, 42)
const COLUMNS := 10
const OUTPUT := "res://assets/characters/carrasco_base_gameplay"

const INK := Color("#151217")
const VOID := Color("#09090c")
const CAPE := Color("#252126")
const CAPE_LIT := Color("#443536")
const CAPE_RED := Color("#73392f")
const SHADOW := Color("#302b2d")
const ARMOR := Color("#5e4c3e")
const ARMOR_LIT := Color("#997454")
const BRONZE := Color("#c19360")
const WOOD := Color("#4b3028")
const WRAP := Color("#82614a")
const STEEL := Color("#aaa39a")
const STEEL_LIT := Color("#e1d1b6")
const BLOOD := Color("#a34435")

var animations: Dictionary = {}


func _initialize() -> void:
    _define_animations()
    var count := 0
    for frames in animations.values():
        count += frames.size()
    var rows := ceili(float(count) / COLUMNS)
    var atlas := Image.create_empty(TILE.x * COLUMNS, TILE.y * rows, false, Image.FORMAT_RGBA8)
    atlas.fill(Color.TRANSPARENT)
    var manifest := {"tile_width": TILE.x, "tile_height": TILE.y, "pivot_x": PIVOT.x, "pivot_y": PIVOT.y, "body_height": 31, "columns": COLUMNS, "animations": {}}
    var index := 0
    for animation in animations.keys():
        var ids: Array[int] = []
        for spec in animations[animation]:
            var frame := Image.create_empty(TILE.x, TILE.y, false, Image.FORMAT_RGBA8)
            frame.fill(Color.TRANSPARENT)
            _render(frame, spec)
            atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, TILE), Vector2i((index % COLUMNS) * TILE.x, (index / COLUMNS) * TILE.y))
            ids.append(index)
            index += 1
        manifest["animations"][animation] = ids
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    var result := atlas.save_png(OUTPUT + "/atlas.png")
    var file := FileAccess.open(OUTPUT + "/frames.json", FileAccess.WRITE)
    if file == null:
        printerr("Could not write Carrasco frame manifest")
        quit(1)
        return
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    print("Carrasco native atlas: ", count, " frames, ", atlas.get_width(), "x", atlas.get_height(), ", result ", result)
    quit(0 if result == OK else 1)


func _f(mode: String, rear_x: int, rear_y: int, tip_x: int, tip_y: int, cape_phase: int = 0, effect: String = "") -> Array:
    return [mode, Vector2i(rear_x, rear_y), Vector2i(tip_x, tip_y), cape_phase, effect]


func _define_animations() -> void:
    animations["idle"] = [
        _f("idle0", 8, 31, 43, 38, 0), _f("idle1", 8, 31, 43, 39, 1),
        _f("idle2", 8, 31, 43, 38, 2), _f("idle1", 8, 31, 43, 39, 3)]
    animations["run"] = [
        _f("run0", 7, 31, 42, 37, 0), _f("run1", 7, 30, 42, 37, 1),
        _f("run2", 6, 31, 41, 38, 2), _f("run3", 7, 31, 42, 37, 3),
        _f("run4", 7, 30, 42, 37, 0), _f("run5", 6, 31, 41, 38, 2)]
    animations["jump"] = [_f("air0", 8, 29, 42, 34, 2), _f("air1", 8, 28, 42, 33, 3)]
    animations["fall"] = [_f("air2", 8, 31, 42, 36, 2), _f("air3", 8, 32, 42, 37, 1)]
    animations["ground_dash"] = [
        _f("dash0", 5, 33, 42, 34, 3), _f("dash1", 4, 33, 43, 34, 2),
        _f("dash2", 5, 32, 42, 35, 1)]
    animations["air_dash"] = [
        _f("airdash0", 5, 29, 42, 30, 3), _f("airdash1", 4, 29, 43, 30, 2),
        _f("airdash2", 5, 30, 42, 31, 1)]
    animations["parry"] = [
        _f("guard", 11, 33, 33, 17, 0), _f("guard", 11, 33, 31, 15, 1),
        _f("guard", 11, 33, 33, 17, 2)]
    animations["carrasco_light_1"] = [
        _f("wind", 8, 31, 34, 19, 0), _f("wind", 8, 31, 39, 24, 1),
        _f("lunge", 11, 29, 45, 26, 3, "slash"), _f("recover", 8, 31, 43, 37, 2)]
    animations["carrasco_light_2"] = [
        _f("wind", 7, 35, 35, 36, 1), _f("crouch", 7, 36, 38, 31, 2),
        _f("lunge", 10, 36, 39, 15, 3, "slash"), _f("recover", 8, 31, 42, 29, 1)]
    animations["carrasco_light_3"] = [
        _f("wind", 16, 26, 34, 9, 0), _f("overhead", 18, 21, 36, 7, 1),
        _f("impact", 13, 26, 45, 38, 3, "finish"), _f("recover", 9, 31, 43, 40, 2)]
    animations["carrasco_heavy"] = [
        _f("wind", 8, 31, 33, 21, 0), _f("overhead", 17, 23, 36, 8, 1),
        _f("overhead", 18, 20, 38, 8, 2), _f("impact", 14, 24, 45, 39, 3, "heavy"),
        _f("crouch", 11, 27, 44, 41, 2), _f("recover", 8, 31, 43, 38, 1)]
    animations["charge"] = [
        _f("crouch", 8, 34, 35, 21, 0, "charge"),
        _f("crouch", 8, 34, 35, 21, 1, "charge"),
        _f("crouch", 8, 34, 36, 20, 2, "charge"),
        _f("crouch", 8, 34, 36, 20, 3, "charge")]
    animations["charge_ready"] = [
        _f("crouch", 8, 34, 36, 18, 0, "ready"),
        _f("crouch", 8, 34, 36, 18, 2, "ready")]
    animations["carrasco_charged_heavy"] = [
        _f("overhead", 17, 23, 36, 7, 0, "ready"),
        _f("overhead", 18, 20, 38, 6, 1, "ready"),
        _f("impact", 13, 24, 46, 38, 3, "charged"),
        _f("impact", 13, 25, 46, 40, 2, "charged"),
        _f("crouch", 10, 27, 44, 41, 1), _f("recover", 8, 31, 43, 38, 0)]
    animations["carrasco_post_dodge"] = [
        _f("dash0", 5, 32, 40, 32, 3), _f("dash1", 7, 31, 42, 31, 2),
        _f("lunge", 11, 30, 46, 27, 3, "slash"), _f("recover", 8, 31, 43, 37, 1)]
    animations["carrasco_air_light"] = [
        _f("air0", 8, 27, 37, 18, 2), _f("air1", 8, 28, 42, 24, 3),
        _f("air2", 10, 28, 45, 26, 2, "slash"), _f("air3", 8, 30, 42, 34, 1)]
    animations["carrasco_air_heavy"] = [
        _f("air0", 14, 22, 35, 8, 2), _f("air1", 16, 21, 38, 7, 3),
        _f("air2", 14, 22, 43, 29, 2), _f("air3", 12, 25, 44, 39, 1, "heavy"),
        _f("air3", 9, 29, 42, 39, 0)]
    animations["carrasco_quebra_selos"] = [
        _f("wind", 14, 24, 34, 10, 0), _f("overhead", 17, 21, 37, 8, 1),
        _f("impact", 13, 25, 45, 39, 3, "seal"), _f("crouch", 11, 27, 44, 41, 2, "seal"),
        _f("recover", 8, 31, 42, 38, 1)]
    animations["carrasco_marca"] = [
        _f("ritual", 9, 33, 36, 19, 0), _f("ritual", 9, 32, 38, 17, 1, "mark"),
        _f("ritual", 10, 31, 42, 18, 2, "mark"), _f("recover", 8, 31, 42, 37, 0)]
    animations["tribunal_activate"] = [
        _f("ritual", 10, 34, 35, 18, 0, "tribunal"),
        _f("ritual", 10, 33, 35, 12, 1, "tribunal"),
        _f("overhead", 16, 22, 35, 7, 2, "tribunal"),
        _f("overhead", 16, 22, 35, 7, 3, "tribunal")]
    animations["execution"] = [
        _f("wind", 8, 31, 34, 20, 0), _f("overhead", 16, 22, 35, 8, 1),
        _f("overhead", 18, 21, 37, 7, 2), _f("lunge", 13, 24, 43, 26, 3),
        _f("impact", 14, 25, 46, 39, 3, "execution"),
        _f("impact", 14, 26, 46, 40, 2, "execution"),
        _f("crouch", 10, 28, 44, 41, 1), _f("recover", 8, 31, 43, 38, 0)]
    animations["execution_strike"] = [
        _f("wind", 9, 31, 34, 20, 0), _f("overhead", 16, 22, 36, 8, 1),
        _f("lunge", 12, 25, 43, 29, 3), _f("impact", 13, 26, 45, 38, 2, "strike"),
        _f("crouch", 10, 28, 44, 40, 1), _f("recover", 8, 31, 43, 38, 0)]
    animations["hit"] = [
        _f("hurt", 7, 32, 41, 40, 0), _f("hurt", 7, 33, 42, 41, 1),
        _f("recover", 8, 31, 43, 38, 2)]
    animations["ruptured"] = [
        _f("broken", 8, 34, 40, 42, 0), _f("broken", 8, 35, 39, 42, 1),
        _f("broken", 8, 34, 40, 42, 2)]
    animations["death"] = [
        _f("hurt", 7, 33, 42, 41, 0), _f("broken", 8, 35, 40, 42, 1),
        _f("dead", 9, 40, 44, 42, 2), _f("dead", 9, 40, 44, 42, 2),
        _f("dead", 9, 40, 44, 42, 2)]


func _render(image: Image, spec: Array) -> void:
    var mode: String = spec[0]
    var rear: Vector2i = spec[1]
    var tip: Vector2i = spec[2]
    tip.x = mini(tip.x, 43)
    var cape_phase: int = spec[3]
    var effect: String = spec[4]
    if mode == "dead":
        _draw_dead(image, rear, tip)
        return
    var lean := 0
    var crouch := 0
    var stride := 0
    var bob := 0
    match mode:
        "idle1": bob = 1
        "idle2": bob = 0
        "run0": stride = 5; lean = 3
        "run1": stride = 2; lean = 4; bob = 1
        "run2": stride = -2; lean = 4
        "run3": stride = -5; lean = 3
        "run4": stride = -2; lean = 4; bob = 1
        "run5": stride = 2; lean = 4
        "air0": stride = 2; crouch = 2
        "air1": stride = 0; crouch = 3
        "air2": stride = -1; crouch = 2
        "air3": stride = 1; crouch = 1
        "dash0", "dash1", "dash2", "airdash0", "airdash1", "airdash2":
            lean = 5; crouch = 4; stride = -3
        "wind": lean = -2; crouch = 1
        "overhead": lean = -1; crouch = 1; stride = 2
        "lunge": lean = 4; crouch = 2; stride = 4
        "impact": lean = 4; crouch = 4; stride = 4
        "crouch": lean = 1; crouch = 4; stride = 2
        "recover": lean = 1; crouch = 2; stride = -1
        "ritual": lean = 0; crouch = 1
        "guard": lean = -1; crouch = 1
        "hurt": lean = -3; crouch = 2; stride = -2
        "broken": lean = -2; crouch = 5; stride = -2
    var air := mode.begins_with("air")
    var y_shift := -2 if air else 0
    _draw_cape(image, lean, crouch, cape_phase, y_shift)
    _draw_legs(image, stride, crouch, air)
    _draw_torso(image, lean, crouch, bob + y_shift)
    _draw_hood(image, lean, crouch, bob + y_shift)
    _draw_weapon_and_arms(image, rear, tip, lean, crouch, bob + y_shift)
    _draw_effect(image, effect, tip)


func _draw_cape(image: Image, lean: int, crouch: int, phase: int, y_shift: int) -> void:
    var wind: int = [0, -2, -4, -1][phase]
    var shoulder := Vector2i(12 + lean, 19 + crouch + y_shift)
    _poly(image, [shoulder, Vector2i(8 + lean, 22 + crouch + y_shift),
        Vector2i(2 + wind, 30 + y_shift), Vector2i(5 + wind, 36 + y_shift),
        Vector2i(1 + wind, 41 + y_shift), Vector2i(8 + wind, 39 + y_shift),
        Vector2i(11, 43 + y_shift), Vector2i(17, 36 + y_shift),
        Vector2i(20 + lean, 24 + crouch + y_shift)], INK)
    _poly(image, [Vector2i(11 + lean, 21 + crouch + y_shift),
        Vector2i(5 + wind, 29 + y_shift), Vector2i(7 + wind, 35 + y_shift),
        Vector2i(5 + wind, 39 + y_shift), Vector2i(11, 36 + y_shift),
        Vector2i(13, 40 + y_shift), Vector2i(18, 34 + y_shift),
        Vector2i(19 + lean, 25 + crouch + y_shift)], CAPE)
    _line(image, Vector2i(10 + lean, 23 + crouch + y_shift), Vector2i(5 + wind, 35 + y_shift), CAPE_LIT, 1)
    _rect(image, Rect2i(3 + wind, 39 + y_shift, 3, 1), CAPE_RED)
    _rect(image, Rect2i(12, 39 + y_shift, 2, 2), CAPE_RED)
    _line(image, Vector2i(8 + wind, 31 + y_shift), Vector2i(4 + wind, 40 + y_shift), CAPE_RED, 1)
    _rect(image, Rect2i(8 + wind, 28 + y_shift, 1, 3), ARMOR_LIT)


func _draw_legs(image: Image, stride: int, crouch: int, air: bool) -> void:
    var sole := 40 if air else 42
    var hip_y := 30 + crouch
    var left_foot := 11 - stride
    var right_foot := 24 + stride
    if air:
        left_foot = 12 - stride
        right_foot = 22 + stride
    _line(image, Vector2i(15, hip_y), Vector2i(left_foot + 2, sole - 3), INK, 6)
    _line(image, Vector2i(22, hip_y), Vector2i(right_foot, sole - 3), INK, 6)
    _line(image, Vector2i(15, hip_y), Vector2i(left_foot + 2, sole - 3), ARMOR, 4)
    _line(image, Vector2i(22, hip_y), Vector2i(right_foot, sole - 3), ARMOR, 4)
    _line(image, Vector2i(14, hip_y + 2), Vector2i(left_foot + 1, sole - 5), ARMOR_LIT, 1)
    _line(image, Vector2i(21, hip_y + 2), Vector2i(right_foot - 1, sole - 5), ARMOR_LIT, 1)
    _rect(image, Rect2i(left_foot, sole - 7, 4, 1), BRONZE)
    _rect(image, Rect2i(right_foot - 1, sole - 8, 4, 1), ARMOR_LIT)
    _rect(image, Rect2i(left_foot - 2, sole - 2, 7, 2), INK)
    _rect(image, Rect2i(right_foot - 2, sole - 2, 7, 2), INK)
    _rect(image, Rect2i(left_foot - 1, sole - 2, 5, 1), ARMOR_LIT)
    _rect(image, Rect2i(right_foot - 1, sole - 2, 5, 1), ARMOR_LIT)


func _draw_torso(image: Image, lean: int, crouch: int, bob: int) -> void:
    var shift := Vector2i(lean, crouch + bob)
    _poly(image, [_v(11, 18) + shift, _v(24, 18) + shift, _v(27, 30) + shift,
        _v(11, 32) + shift, _v(9, 25) + shift], INK)
    _poly(image, [_v(12, 19) + shift, _v(23, 19) + shift, _v(25, 29) + shift,
        _v(13, 30) + shift, _v(11, 24) + shift], ARMOR)
    _poly(image, [_v(12, 21) + shift, _v(17, 18) + shift, _v(20, 20) + shift,
        _v(17, 27) + shift, _v(13, 28) + shift], SHADOW)
    _line(image, _v(12, 22) + shift, _v(15, 26) + shift, ARMOR_LIT, 1)
    _line(image, _v(22, 20) + shift, _v(25, 28) + shift, ARMOR_LIT, 1)
    _line(image, _v(16, 23) + shift, _v(23, 24) + shift, SHADOW, 1)
    _line(image, _v(15, 26) + shift, _v(23, 27) + shift, ARMOR_LIT, 1)
    _rect(image, Rect2i(17 + lean, 22 + crouch + bob, 1, 1), BRONZE)
    _rect(image, Rect2i(21 + lean, 25 + crouch + bob, 1, 1), BRONZE)
    _rect(image, Rect2i(12 + lean, 28 + crouch + bob, 14, 2), INK)
    _rect(image, Rect2i(14 + lean, 28 + crouch + bob, 11, 1), BRONZE)
    _rect(image, Rect2i(18 + lean, 28 + crouch + bob, 3, 3), INK)
    _rect(image, Rect2i(19 + lean, 29 + crouch + bob, 1, 1), BRONZE)
    # Two small iron links survive the final gameplay scale.
    _rect(image, Rect2i(20 + lean, 32 + crouch + bob, 2, 2), BRONZE)
    _rect(image, Rect2i(21 + lean, 35 + crouch + bob, 2, 2), BRONZE)
    _rect(image, Rect2i(20 + lean, 33 + crouch + bob, 1, 1), VOID)
    _poly(image, [_v(9, 18) + shift, _v(14, 18) + shift, _v(16, 22) + shift,
        _v(14, 26) + shift, _v(8, 24) + shift], INK)
    _poly(image, [_v(10, 19) + shift, _v(14, 19) + shift, _v(15, 22) + shift,
        _v(13, 24) + shift, _v(9, 23) + shift], ARMOR_LIT)
    _rect(image, Rect2i(10 + lean, 20 + crouch + bob, 4, 1), BRONZE)
    _rect(image, Rect2i(10 + lean, 22 + crouch + bob, 3, 1), ARMOR)
    _poly(image, [_v(22, 18) + shift, _v(27, 19) + shift, _v(29, 24) + shift,
        _v(25, 26) + shift, _v(22, 22) + shift], INK)
    _poly(image, [_v(23, 19) + shift, _v(26, 20) + shift, _v(28, 23) + shift,
        _v(25, 24) + shift, _v(23, 22) + shift], ARMOR)
    _rect(image, Rect2i(24 + lean, 20 + crouch + bob, 3, 1), BRONZE)
    _rect(image, Rect2i(25 + lean, 22 + crouch + bob, 2, 1), ARMOR_LIT)


func _draw_hood(image: Image, lean: int, crouch: int, bob: int) -> void:
    var s := _v(lean, crouch + bob)
    _poly(image, [_v(12, 18) + s, _v(13, 13) + s, _v(16, 11) + s,
        _v(21, 11) + s, _v(25, 15) + s, _v(25, 21) + s,
        _v(20, 23) + s, _v(14, 22) + s], INK)
    _poly(image, [_v(14, 15) + s, _v(17, 12) + s, _v(21, 12) + s,
        _v(24, 16) + s, _v(22, 21) + s, _v(15, 20) + s], CAPE_LIT)
    _rect(image, Rect2i(17 + lean, 14 + crouch + bob, 6, 7), VOID)
    _rect(image, Rect2i(17 + lean, 14 + crouch + bob, 6, 1), BRONZE)
    _rect(image, Rect2i(18 + lean, 15 + crouch + bob, 1, 5), BRONZE)
    _rect(image, Rect2i(20 + lean, 15 + crouch + bob, 1, 5), BRONZE)
    _rect(image, Rect2i(22 + lean, 15 + crouch + bob, 1, 5), BRONZE)
    _rect(image, Rect2i(17 + lean, 20 + crouch + bob, 6, 1), ARMOR_LIT)
    _rect(image, Rect2i(15 + lean, 12 + crouch + bob, 4, 1), ARMOR_LIT)
    _rect(image, Rect2i(23 + lean, 17 + crouch + bob, 1, 3), SHADOW)
    _line(image, _v(12, 19) + s, _v(16, 23) + s, SHADOW, 2)


func _draw_weapon_and_arms(image: Image, rear: Vector2i, tip: Vector2i, lean: int, crouch: int, bob: int) -> void:
    var direction := Vector2(tip - rear).normalized()
    # Every authored pose keeps the same 33 px haft and blade profile.
    rear = Vector2i((Vector2(tip) - direction * 33.0).round())
    var grip_back := Vector2i(Vector2(rear).lerp(Vector2(tip), 0.36).round())
    var grip_front := Vector2i(Vector2(rear).lerp(Vector2(tip), 0.60).round())
    var shoulder_back := _v(12 + lean, 23 + crouch + bob)
    var shoulder_front := _v(26 + lean, 23 + crouch + bob)
    _line(image, shoulder_back, grip_back, INK, 5)
    _line(image, shoulder_front, grip_front, INK, 5)
    _line(image, shoulder_back, grip_back, ARMOR, 3)
    _line(image, shoulder_front, grip_front, ARMOR_LIT, 3)
    _line(image, rear, tip, INK, 4)
    _line(image, rear, tip, WOOD, 2)
    for t in [0.18, 0.48, 0.78]:
        var wrap_at := Vector2i(Vector2(rear).lerp(Vector2(tip), t).round())
        _rect(image, Rect2i(wrap_at.x, wrap_at.y, 2, 2), WRAP)
    _line(image, grip_back, grip_back + Vector2i(1, 1), INK, 4)
    _line(image, grip_front, grip_front + Vector2i(1, 1), INK, 4)
    _rect(image, Rect2i(grip_back.x, grip_back.y, 2, 2), ARMOR_LIT)
    _rect(image, Rect2i(grip_front.x, grip_front.y, 2, 2), ARMOR_LIT)
    _draw_axe_head(image, tip, direction)


func _draw_axe_head(image: Image, tip: Vector2i, direction: Vector2) -> void:
    var normal := Vector2(-direction.y, direction.x)
    # One fixed single-edge axe profile, rotated with the weapon axis.
    var local := [
        Vector2(-3, -3), Vector2(1, -4), Vector2(5, -6),
        Vector2(8, -5), Vector2(6, -2), Vector2(6, 2),
        Vector2(8, 5), Vector2(5, 6), Vector2(1, 4),
        Vector2(-3, 3), Vector2(-1, 0)]
    var blade: Array[Vector2i] = []
    for point in local:
        blade.append(Vector2i((Vector2(tip) + direction * point.x + normal * point.y).round()))
    _poly(image, blade, INK)
    var inner: Array[Vector2i] = []
    for point in [Vector2(-2, -2), Vector2(2, -3), Vector2(5, -5),
        Vector2(7, -4), Vector2(5, -2), Vector2(5, 2),
        Vector2(7, 4), Vector2(5, 5), Vector2(2, 3),
        Vector2(-2, 2), Vector2(0, 0)]:
        inner.append(Vector2i((Vector2(tip) + direction * point.x + normal * point.y).round()))
    _poly(image, inner, STEEL)
    var edge_a := Vector2i((Vector2(tip) + direction * 7 + normal * -5).round())
    var edge_b := Vector2i((Vector2(tip) + direction * 7 + normal * 5).round())
    _line(image, edge_a, edge_b, STEEL_LIT, 1)
    _rect(image, Rect2i(tip.x, tip.y, 2, 2), ARMOR_LIT)
    var blood_at := Vector2i((Vector2(tip) + direction * 4 + normal * 4).round())
    _rect(image, Rect2i(blood_at.x, blood_at.y, 2, 1), BLOOD)


func _draw_effect(image: Image, kind: String, tip: Vector2i) -> void:
    match kind:
        "charge", "ready":
            _rect(image, Rect2i(tip.x + 5, tip.y - 6, 2, 2), BRONZE)
            if kind == "ready":
                _rect(image, Rect2i(tip.x + 8, tip.y - 3, 2, 2), STEEL_LIT)
                _rect(image, Rect2i(9, 13, 2, 2), BRONZE)
        "slash", "finish", "heavy":
            _rect(image, Rect2i(tip.x + 6, tip.y - 4, 2, 1), BLOOD)
            if kind != "slash":
                _rect(image, Rect2i(tip.x + 7, tip.y - 7, 2, 2), BRONZE)
        "charged", "seal":
            _rect(image, Rect2i(tip.x + 7, tip.y - 6, 3, 2), STEEL_LIT)
            _rect(image, Rect2i(tip.x + 9, tip.y - 2, 2, 2), BLOOD)
        "mark":
            _rect(image, Rect2i(tip.x + 7, tip.y - 7, 1, 7), BRONZE)
            _rect(image, Rect2i(tip.x + 4, tip.y - 4, 7, 1), BRONZE)
        "tribunal":
            _rect(image, Rect2i(7, 14, 1, 7), BLOOD)
            _rect(image, Rect2i(30, 11, 1, 7), BRONZE)
            _rect(image, Rect2i(20, 7, 4, 1), STEEL_LIT)
        "execution":
            _rect(image, Rect2i(tip.x + 6, tip.y - 6, 3, 3), BLOOD)
            _rect(image, Rect2i(tip.x + 9, tip.y - 2, 2, 2), BLOOD)
        "strike":
            _rect(image, Rect2i(tip.x + 6, tip.y - 5, 3, 2), BRONZE)


func _draw_dead(image: Image, rear: Vector2i, tip: Vector2i) -> void:
    _poly(image, [_v(5, 37), _v(12, 34), _v(31, 35), _v(39, 40), _v(38, 43), _v(7, 43)], INK)
    _poly(image, [_v(8, 38), _v(18, 36), _v(31, 37), _v(34, 41), _v(9, 41)], CAPE)
    _rect(image, Rect2i(24, 36, 9, 5), ARMOR)
    _rect(image, Rect2i(34, 37, 5, 4), INK)
    _rect(image, Rect2i(35, 38, 3, 2), VOID)
    _rect(image, Rect2i(36, 38, 1, 2), BRONZE)
    var direction := Vector2(tip - rear).normalized()
    rear = Vector2i((Vector2(tip) - direction * 33.0).round())
    _line(image, rear, tip, INK, 4)
    _line(image, rear, tip, WOOD, 2)
    _draw_axe_head(image, tip, direction)


func _v(x: int, y: int) -> Vector2i:
    return Vector2i(x, y)


func _rect(image: Image, area: Rect2i, color: Color) -> void:
    var clipped := area.intersection(Rect2i(Vector2i.ZERO, TILE))
    if clipped.has_area():
        image.fill_rect(clipped, color)


func _line(image: Image, start: Vector2i, finish: Vector2i, color: Color, width: int) -> void:
    var delta := finish - start
    var steps := maxi(absi(delta.x), absi(delta.y))
    if steps == 0:
        _rect(image, Rect2i(start.x - width / 2, start.y - width / 2, width, width), color)
        return
    for step in range(steps + 1):
        var point := Vector2i((Vector2(start).lerp(Vector2(finish), float(step) / steps)).round())
        _rect(image, Rect2i(point.x - width / 2, point.y - width / 2, width, width), color)


func _poly(image: Image, vertices: Array, color: Color) -> void:
    if vertices.size() < 3:
        return
    var min_y := TILE.y
    var max_y := 0
    for vertex in vertices:
        min_y = mini(min_y, vertex.y)
        max_y = maxi(max_y, vertex.y)
    for y in range(maxi(0, min_y), mini(TILE.y - 1, max_y) + 1):
        var crossings: Array[float] = []
        for i in range(vertices.size()):
            var a: Vector2i = vertices[i]
            var b: Vector2i = vertices[(i + 1) % vertices.size()]
            if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
                crossings.append(a.x + float(y - a.y) * (b.x - a.x) / (b.y - a.y))
        crossings.sort()
        for i in range(0, crossings.size() - 1, 2):
            var left := maxi(0, ceili(crossings[i]))
            var right := mini(TILE.x - 1, floori(crossings[i + 1]))
            if right >= left:
                _rect(image, Rect2i(left, y, right - left + 1, 1), color)
