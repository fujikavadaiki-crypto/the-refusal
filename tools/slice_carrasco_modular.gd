extends SceneTree

## Cuts the approved transparent base into articulated regions and underpainting.
## Run with Godot 4.7.2 --headless --path . --script res://tools/slice_carrasco_modular.gd
const SOURCE := "res://assets/characters/carrasco_modular/approved_base.png"
const OUTPUT := "res://assets/characters/carrasco_modular/parts"


func _initialize() -> void:
    var source := Image.load_from_file(SOURCE)
    if source.is_empty() or source.get_size() != Vector2i(256, 256):
        push_error("Expected the approved transparent 256x256 Carrasco base")
        quit(1)
        return
    var regions := _regions()
    var images: Dictionary = {}
    for region in regions:
        var image := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
        image.fill(Color.TRANSPARENT)
        images[region.name] = image
    var core := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
    core.fill(Color.TRANSPARENT)
    images["core_underlay"] = core
    for y in range(256):
        for x in range(256):
            var color := source.get_pixel(x, y)
            if color.a < 0.01:
                continue
            var owner := ""
            var point := Vector2(x + 0.5, y + 0.5)
            for region in regions:
                var found := false
                for polygon in region.polygons:
                    if Geometry2D.is_point_in_polygon(point, polygon):
                        owner = region.name
                        found = true
                        break
                if found:
                    break
            if owner.is_empty():
                owner = _fallback_owner(x, y)
            (images[owner] as Image).set_pixel(x, y, color)
            if x >= 96 and x <= 161 and y >= 72 and y <= 165:
                core.set_pixel(x, y, color if owner != "axe" else Color(0.12, 0.085, 0.10, 0.85))
    _mirror_hidden_right_leg(images)
    _extend_joint_edges(images, source)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    for name in images:
        var result: Error = (images[name] as Image).save_png(OUTPUT + "/" + name + ".png")
        if result != OK:
            push_error("Could not save Carrasco part: " + name)
            quit(1)
            return
    print("Sliced Carrasco source into ", images.size(), " functional pieces")
    quit()


func _fallback_owner(x: int, y: int) -> String:
    if y < 70:
        return "head"
    if y < 115:
        return "cape_left" if x < 96 else ("cape_right" if x > 157 else "torso")
    if y > 204:
        return "boot_left" if x < 120 else "boot_right"
    if y > 174:
        return "shin_left" if x < 120 else ("shin_right" if x > 145 else "front_cloth")
    if x < 100:
        return "cape_left"
    if x > 156:
        return "cape_right"
    return "front_cloth"


func _mirror_hidden_right_leg(images: Dictionary) -> void:
    # The approved single pose hides most of the far thigh behind its cloth and axe.
    # Reuse its own near-leg armor pixels as underpainting for articulation.
    for pair in [["thigh_left", "thigh_right"], ["shin_left", "shin_right"], ["boot_left", "boot_right"]]:
        var near: Image = images[pair[0]]
        var far: Image = images[pair[1]]
        for y in range(125, 232):
            for x in range(65, 125):
                var destination_x := 256 - x
                if destination_x > 166 or far.get_pixel(destination_x, y).a > 0.0:
                    continue
                var color := near.get_pixel(x, y)
                if color.a > 0.0:
                    color = color.darkened(0.18)
                    far.set_pixel(destination_x, y, color)


func _extend_joint_edges(images: Dictionary, source: Image) -> void:
    # Duplicate only existing approved pixels within 5 px of a cut. At rest the
    # image is unchanged; during rotation this covers the otherwise empty seam.
    for name in images:
        if name == "axe" or name == "core_underlay":
            continue
        var part: Image = images[name]
        var expanded := part.duplicate() as Image
        for y in range(256):
            for x in range(256):
                if part.get_pixel(x, y).a <= 0.0:
                    continue
                for oy in range(-5, 6):
                    for ox in range(-5, 6):
                        if abs(ox) + abs(oy) > 6:
                            continue
                        var px := x + ox
                        var py := y + oy
                        if px < 0 or py < 0 or px >= 256 or py >= 256:
                            continue
                        if expanded.get_pixel(px, py).a <= 0.0:
                            var original := source.get_pixel(px, py)
                            if original.a > 0.0:
                                expanded.set_pixel(px, py, original)
        images[name] = expanded


func _poly(coords: Array) -> PackedVector2Array:
    var points := PackedVector2Array()
    for point in coords:
        points.append(Vector2(point[0], point[1]))
    return points


func _region(name: String, coordinates: Array) -> Dictionary:
    var polygons: Array[PackedVector2Array] = []
    for coords in coordinates:
        polygons.append(_poly(coords))
    return {"name": name, "polygons": polygons}


func _regions() -> Array[Dictionary]:
    # Front to back. Each visible source pixel belongs to one part only.
    return [
        _region("axe", [
            [[67, 106], [77, 103], [184, 181], [177, 191], [69, 114]],
            [[106, 151], [119, 147], [149, 175], [172, 185], [175, 225], [165, 228], [145, 210], [118, 187], [103, 168]],
        ]),
        _region("chain_left", [
            [[114, 117], [127, 114], [132, 165], [119, 174], [112, 160]],
        ]),
        _region("chain_right", [
            [[148, 127], [161, 127], [168, 177], [154, 186], [145, 170]],
        ]),
        _region("hand_left", [[[80, 119], [97, 119], [99, 138], [83, 142]]]),
        _region("hand_right", [[[151, 123], [169, 123], [172, 141], [154, 144]]]),
        _region("head", [[[109, 28], [150, 28], [153, 66], [137, 73], [109, 61]]]),
        _region("forearm_left", [[[79, 94], [103, 94], [102, 125], [80, 127]]]),
        _region("forearm_right", [[[147, 104], [165, 103], [170, 130], [151, 131]]]),
        _region("upper_arm_left", [[[81, 61], [117, 59], [119, 95], [104, 108], [78, 96]]]),
        _region("upper_arm_right", [[[143, 79], [163, 75], [168, 108], [148, 111]]]),
        _region("front_cloth", [[[119, 112], [146, 111], [147, 161], [141, 201], [121, 190], [115, 151]]]),
        _region("cape_right", [[[151, 82], [174, 90], [180, 171], [186, 194], [153, 191], [146, 143]]]),
        _region("cape_left", [[[72, 71], [111, 74], [110, 125], [99, 181], [65, 189], [65, 112]]]),
        _region("torso", [[[108, 57], [156, 61], [157, 120], [143, 140], [106, 129], [98, 94]]]),
        _region("thigh_left", [[[81, 126], [111, 126], [114, 175], [96, 190], [77, 174]]]),
        _region("thigh_right", [[[135, 132], [161, 131], [167, 179], [140, 189], [128, 169]]]),
        _region("shin_left", [[[76, 168], [105, 164], [106, 211], [72, 216]]]),
        _region("shin_right", [[[136, 172], [164, 168], [162, 212], [130, 212]]]),
        _region("boot_left", [[[68, 206], [106, 204], [108, 232], [65, 233]]]),
        _region("boot_right", [[[126, 204], [168, 204], [171, 233], [124, 233]]]),
    ]
