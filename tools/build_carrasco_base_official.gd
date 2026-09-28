extends SceneTree

## Deterministic anatomical partition of the approved-design gameplay cutout.
## The original concept sheet and cutout remain untouched.
const ROOT := "res://assets/characters/carrasco_base_official/"
const SIZE := Vector2i(256, 384)


func _initialize() -> void:
    var source := Image.load_from_file(ROOT + "cutout_source.png")
    var weapon := Image.load_from_file(ROOT + "weapon_source.png")
    if source.is_empty() or weapon.is_empty():
        push_error("Carrasco concept cutouts are missing")
        quit(1)
        return
    source.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
    weapon.resize(320, 107, Image.INTERPOLATE_LANCZOS)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "parts"))
    source.save_png(ROOT + "gameplay_base.png")
    weapon.save_png(ROOT + "parts/weapon.png")
    var regions := _regions()
    var images := {}
    for region in regions:
        var blank := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
        blank.fill(Color.TRANSPARENT)
        images[region.name] = blank
    for y in range(SIZE.y):
        for x in range(SIZE.x):
            var color := source.get_pixel(x, y)
            if color.a <= 0.015:
                continue
            var owner := ""
            var p := Vector2(x + 0.5, y + 0.5)
            for region in regions:
                if Geometry2D.is_point_in_polygon(p, region.poly):
                    owner = region.name
                    break
            if owner.is_empty():
                owner = _fallback(x, y)
            (images[owner] as Image).set_pixel(x, y, color)
    # Three source pixels of seam overlap let neighboring bones rotate without
    # opening a transparent hairline. At the rest pose the original is unchanged.
    for name in images:
        var part: Image = images[name]
        var expanded := part.duplicate() as Image
        for y in range(SIZE.y):
            for x in range(SIZE.x):
                if part.get_pixel(x, y).a <= 0.015:
                    continue
                for oy in range(-3, 4):
                    for ox in range(-3, 4):
                        if absi(ox) + absi(oy) > 3:
                            continue
                        var px := x + ox
                        var py := y + oy
                        if px < 0 or py < 0 or px >= SIZE.x or py >= SIZE.y:
                            continue
                        if expanded.get_pixel(px, py).a <= 0.015:
                            expanded.set_pixel(px, py, source.get_pixel(px, py))
        var path: String = ROOT + "parts/" + String(name) + ".png"
        if expanded.save_png(path) != OK:
            push_error("Could not save Carrasco region: " + path)
            quit(1)
            return
    print("CARRASCO_BASE_PARTS=", images.size(), " source=", SIZE)
    quit()


func _poly(points: Array) -> PackedVector2Array:
    var polygon := PackedVector2Array()
    for point in points:
        polygon.append(Vector2(point[0], point[1]))
    return polygon


func _region(name: String, points: Array) -> Dictionary:
    return {"name": name, "poly": _poly(points)}


func _regions() -> Array[Dictionary]:
    # Front-most to rear-most. Coordinates refer to the 256 x 384 cutout.
    return [
        _region("hand_left", [[58, 168], [87, 163], [94, 197], [83, 207], [56, 202]]),
        _region("hand_right", [[190, 174], [220, 167], [225, 203], [202, 213], [189, 201]]),
        _region("head", [[108, 0], [190, 0], [188, 73], [166, 83], [123, 70], [107, 51]]),
        _region("forearm_left", [[58, 125], [88, 121], [91, 181], [56, 183]]),
        _region("forearm_right", [[183, 128], [212, 124], [223, 182], [189, 188]]),
        _region("upper_arm_left", [[64, 58], [115, 58], [128, 95], [92, 143], [60, 133]]),
        _region("upper_arm_right", [[174, 71], [199, 78], [209, 139], [183, 145], [169, 104]]),
        _region("chain_left", [[125, 145], [151, 143], [153, 237], [124, 246]]),
        _region("chain_right", [[170, 156], [194, 154], [195, 240], [169, 239]]),
        _region("front_cloth", [[137, 152], [177, 150], [182, 256], [176, 291], [135, 290], [129, 243]]),
        _region("cape_left", [[46, 86], [98, 89], [117, 176], [108, 215], [79, 275], [42, 300], [38, 202]]),
        _region("cape_right", [[181, 95], [209, 105], [233, 249], [226, 310], [182, 267], [171, 172]]),
        _region("cape_center", [[100, 175], [137, 179], [156, 212], [156, 321], [119, 323], [108, 262]]),
        _region("torso", [[114, 62], [188, 61], [191, 163], [169, 180], [112, 173], [93, 118]]),
        _region("boot_left", [[59, 316], [121, 311], [121, 381], [57, 381]]),
        _region("boot_right", [[151, 318], [220, 314], [227, 365], [148, 370]]),
        _region("shin_left", [[78, 263], [128, 262], [128, 329], [70, 333]]),
        _region("shin_right", [[150, 266], [196, 264], [197, 333], [148, 333]]),
        _region("thigh_left", [[96, 198], [141, 202], [147, 268], [92, 276], [77, 253]]),
        _region("thigh_right", [[142, 204], [188, 202], [194, 277], [148, 284]]),
    ]


func _fallback(x: int, y: int) -> String:
    if y < 70:
        return "head"
    if y > 317:
        return "boot_left" if x < 140 else "boot_right"
    if y > 265:
        return "shin_left" if x < 140 else "shin_right"
    if x < 95:
        return "cape_left" if y > 185 else "upper_arm_left"
    if x > 195:
        return "cape_right" if y > 205 else "upper_arm_right"
    if y > 194:
        return "cape_center" if x < 145 else "front_cloth"
    return "torso"
