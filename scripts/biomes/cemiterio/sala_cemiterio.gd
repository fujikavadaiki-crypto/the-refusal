extends Node2D

## Frozen P40 screen geometry. Room translation only places the original Corvo
## within its absolute flight bounds; camera and local geometry translate together.
const ZOOM := 0.9
const ART_X := 0.6154
const ART_Y := 0.6156
const CARRASCO := preload("res://data/masks/carrasco_base.tres")
const BACKGROUND_PATH := "res://assets/biomes/cemiterio/fundo_congelado_p40.png"
const GROUND_TOPS := [
    [[0,320],[80,321],[160,322],[166,322],[166,390],[340,390]],
    [[340,390],[410,401],[500,410],[610,414],[720,417],[850,420]],
    [[850,420],[940,423],[1050,425],[1150,433],[1250,445],[1340,447]],
    [[1340,447],[1430,444],[1500,442],[1568,445]]]
const PLATFORMS := [[718,820,316],[945,1070,378],[1245,1300,318],[1352,1435,345]]
const PLATFORM_NAMES := ["pedra flutuante","bloco da ruína","coluna","pilar"]
const ENEMIES := {
    "Peregrino": preload("res://scenes/enemies/peregrino.tscn"),
    "Corvo": preload("res://scenes/enemies/corvo.tscn"),
    "Raiz": preload("res://scenes/enemies/raiz_faminta.tscn"),
}
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $CameraFixa
@onready var start: Marker2D = $Start
var collisions: Array[CollisionPolygon2D] = []
var enemies: Array[CharacterBody2D] = []
var enemies_ready := false
var background_root: Node2D
var background: TextureRect
var background_patch: TextureRect
var hud: Label
var enemy_hud: Label
var debug_geometry := false

func art_to_screen(point: Vector2) -> Vector2:
    return Vector2(point.x * ART_X, (point.y+86) * ART_Y)

func floor_screen(x: float) -> float:
    for section in GROUND_TOPS:
        for i in range(section.size()-1):
            var a := art_to_screen(Vector2(section[i][0],section[i][1]))
            var b := art_to_screen(Vector2(section[i+1][0],section[i+1][1]))
            if b.x>a.x and x>=a.x and x<=b.x:
                return lerpf(a.y,b.y,(x-a.x)/(b.x-a.x))
    return 530.0

func _ready() -> void:
    process_priority=50
    _make_background()
    camera.bind_fixed(player,background_root)
    _make_collisions()
    start.position=Vector2(150,floor_screen(150))/ZOOM-Vector2(0,13.1)
    player.position=start.position
    player.velocity=Vector2.ZERO
    player.get_node("MaskController").equip(0,CARRASCO)
    player.get_node("DebugLabel").visible=false
    player.get_node("Camera2D").enabled=false
    camera.make_current()
    camera.force_update_scroll()
    _make_hud()
    _populate.call_deferred()

func _make_background() -> void:
    var layer:=CanvasLayer.new()
    layer.name="PrintCongelado"
    layer.layer=-20
    add_child(layer)
    background=TextureRect.new()
    background.name="Fundo960x540"
    # Decode once, as for the P42b sprites: native PNG, no editor dependency.
    background.texture=ImageTexture.create_from_image(Image.load_from_file(BACKGROUND_PATH))
    background.size=Vector2(960,540)
    background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    background.mouse_filter=Control.MOUSE_FILTER_IGNORE
    background_root=Node2D.new()
    background_root.name="FundoComCamera"
    layer.add_child(background_root)
    background_root.add_child(background)
    # Identical P40 atlas coverage, hiding the old figure baked in the frozen PNG.
    background_patch=TextureRect.new()
    background_patch.name="RemendoCarrascoAntigo"
    var atlas:=AtlasTexture.new()
    atlas.atlas=background.texture
    atlas.region=Rect2(203,224,39,69)
    background_patch.texture=atlas
    background_patch.position=Vector2(162,224)
    background_patch.size=Vector2(39,69)
    background_patch.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    background_patch.mouse_filter=Control.MOUSE_FILTER_IGNORE
    background_root.add_child(background_patch)
    _background_edges()

func _make_collisions() -> void:
    for i in range(GROUND_TOPS.size()):
        var points:=PackedVector2Array()
        for p in GROUND_TOPS[i]: points.append(art_to_screen(Vector2(p[0],p[1]))/ZOOM)
        points.append(Vector2(points[-1].x,620/ZOOM))
        points.append(Vector2(points[0].x,620/ZOOM))
        _solid("Chao_%d" % i,points,false)
    for i in range(PLATFORMS.size()):
        var p: Array=PLATFORMS[i]
        var a:=art_to_screen(Vector2(p[0],p[2]))
        var b:=art_to_screen(Vector2(p[1],p[2]))
        _solid("Plataforma_%d" % i,PackedVector2Array([a/ZOOM,b/ZOOM,(b+Vector2(0,2))/ZOOM,(a+Vector2(0,2))/ZOOM]),true)

func _solid(id: String,points: PackedVector2Array,one_way: bool) -> void:
    var body:=StaticBody2D.new()
    body.name=id
    body.collision_layer=1
    body.collision_mask=0
    add_child(body)
    var poly:=CollisionPolygon2D.new()
    poly.polygon=points
    poly.one_way_collision=one_way
    poly.one_way_collision_margin=1/ZOOM
    body.add_child(poly)
    collisions.append(poly)

func ground_at(x: float,from_y := -INF) -> Vector2:
    var ray:=PhysicsRayQueryParameters2D.create(Vector2(x,global_position.y-100 if is_inf(from_y) else from_y),Vector2(x,global_position.y+620/ZOOM),1)
    ray.collide_with_areas=false
    var excluded: Array[RID]=[player.get_rid()]
    for enemy in enemies:
        if is_instance_valid(enemy): excluded.append(enemy.get_rid())
    ray.exclude=excluded
    var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
    return hit.get("position",Vector2(x,global_position.y+530/ZOOM))

func _populate() -> void:
    await get_tree().physics_frame
    # Screen x: patrol on ground, bird above the far ruins, root by the low ruin.
    for spec in [["Peregrino",340.0,15.5],["Corvo",745.0,75.0],["Raiz",620.0,9.0]]:
        var enemy: CharacterBody2D=ENEMIES[spec[0]].instantiate()
        enemy.name=spec[0]
        var foot:=to_local(ground_at(float(spec[1])/ZOOM))
        # Root and Peregrino rest on solid ground, never on the one-way ledges.
        if spec[0]!="Corvo": foot=Vector2(float(spec[1]),floor_screen(float(spec[1])))/ZOOM
        if spec[0]=="Raiz":
            # Its rectangular body must clear the higher corner of a slope.
            foot.y=minf(floor_screen(float(spec[1])-14.5*ZOOM),floor_screen(float(spec[1])+14.5*ZOOM))/ZOOM
        enemy.position=foot-Vector2(0,float(spec[2])+.05)
        enemy.z_index=4
        enemy.get_node("Brain").player_path=NodePath("../../Player")
        enemy.get_node("StatusLabel").visible=false
        add_child(enemy)
        enemies.append(enemy)
    enemies_ready=true

func _make_hud() -> void:
    var layer:=CanvasLayer.new()
    layer.name="HUD"
    layer.layer=15
    add_child(layer)
    hud=_label(Vector2(12,8),14,layer)
    enemy_hud=_label(Vector2(12,502),13,layer)

func _label(at: Vector2,size_: int,parent: Node) -> Label:
    var label:=Label.new()
    label.position=at
    label.add_theme_font_size_override("font_size",size_)
    label.add_theme_color_override("font_shadow_color",Color.BLACK)
    label.add_theme_constant_override("shadow_offset_x",1)
    label.add_theme_constant_override("shadow_offset_y",1)
    label.add_theme_color_override("font_outline_color",Color(0,0,0,.9))
    label.add_theme_constant_override("outline_size",2)
    parent.add_child(label)
    return label

func restart_encounter() -> void:
    get_node("/root/HitStop")._restore()
    player.get_node("Combat").abort_attack()
    player.get_node("Combat").cancel_charge()
    player.clear_action_buffers()
    player.get_node("Health").reset_health()
    player.get_node("Posture").reset_posture()
    var defense: PlayerDefense=player.get_node("Defense")
    defense.mode=PlayerDefense.Mode.READY
    defense.elapsed=0
    defense.dodge_cooldown=0
    defense.air_dash_available=true
    player.position=start.position
    player.velocity=Vector2.ZERO
    player.get_node("Locomotion").reset_assists()
    var form: Node=player.get_node("VisualRoot").form
    if form!=null and form.has_method("reset_tracking"): form.reset_tracking()
    for enemy in enemies: enemy.reset_enemy()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_R: restart_encounter()
        elif event.keycode==KEY_F3:
            debug_geometry=not debug_geometry
            queue_redraw()

func _physics_process(_delta: float) -> void:
    if player.position.y>620/ZOOM or player.position.x<0 or player.position.x>960/ZOOM:
        player.position=start.position
        player.velocity=Vector2.ZERO
        player.get_node("Locomotion").reset_assists()
        var form: Node=player.get_node("VisualRoot").form
        if form!=null and form.has_method("reset_tracking"): form.reset_tracking()

func _process(_delta: float) -> void:
    var hp: HealthComponent=player.get_node("Health")
    var posture: PostureComponent=player.get_node("Posture")
    var dead: String=" · MORREU — R para renascer" if hp.current_health<=0 else ""
    hud.text="CEMITÉRIO · PEQUENO A%s\nVida %d/%d · Postura %d/%d\nA/D mover · Shift andar · Espaço pular · J leve · K pesado/carga\nL dash · I parry · Tab máscara · R reiniciar · F3 áreas · F9 Bosque" % [dead,hp.current_health,hp.max_health,roundi(posture.current_posture),roundi(posture.max_posture)]
    var lines:=PackedStringArray()
    for enemy in enemies:
        var ehp: HealthComponent=enemy.get_node("Health")
        var epost: PostureComponent=enemy.get_node("Posture")
        lines.append("%s: vida %d/%d · postura %d/%d" % [enemy.name,ehp.current_health,ehp.max_health,roundi(epost.current_posture),roundi(epost.max_posture)])
    enemy_hud.text="  |  ".join(lines)
    if debug_geometry: queue_redraw()

func _draw() -> void:
    if not debug_geometry: return
    for collision in collisions:
        var points:=collision.polygon.duplicate()
        points.append(points[0])
        draw_polyline(points,Color(.2,.85,1,.9),1/ZOOM)
    for body in [player]+enemies:
        var shape_node: CollisionShape2D=body.get_node("CollisionShape2D")
        var shape: Shape2D=shape_node.shape
        var at:=to_local(shape_node.global_position)
        var color_:=Color(1,.9,.15,.95) if body==player else Color(1,.3,.7,.95)
        if shape is CapsuleShape2D:
            var r: float=shape.radius
            var half: float=shape.height*.5-r
            draw_arc(at-Vector2(0,half),r,PI,TAU,16,color_,1/ZOOM)
            draw_arc(at+Vector2(0,half),r,0,PI,16,color_,1/ZOOM)
            draw_line(at+Vector2(-r,-half),at+Vector2(-r,half),color_,1/ZOOM)
            draw_line(at+Vector2(r,-half),at+Vector2(r,half),color_,1/ZOOM)
        elif shape is CircleShape2D: draw_arc(at,shape.radius,0,TAU,24,color_,1/ZOOM)
        elif shape is RectangleShape2D: draw_rect(Rect2(at-shape.size*.5,shape.size),color_,false,1/ZOOM)
    var hitbox: Hitbox2D=player.get_node("AttackPivot/Hitbox")
    for part: PackedVector2Array in hitbox.current_world_parts():
        var local:=PackedVector2Array()
        for point in part: local.append(to_local(point))
        draw_colored_polygon(local,Color(1,.28,.1,.3))
        local.append(local[0])
        draw_polyline(local,Color(1,.5,.1),1/ZOOM)
    draw_circle(to_local(player.global_position+Vector2(0,13)),1.5/ZOOM,Color.YELLOW)
    for enemy in enemies:
        var attack_box: Hitbox2D=enemy.get_node("Attack").hitbox
        for part: PackedVector2Array in attack_box.current_world_parts():
            var local:=PackedVector2Array()
            for point_ in part: local.append(to_local(point_))
            draw_colored_polygon(local,Color(.6,.2,1,.25))
            local.append(local[0])
            draw_polyline(local,Color(.8,.5,1),1/ZOOM)

func _background_edges() -> void:
    var feel:=get_node("/root/Sensacao")
    var mx:=ceili(feel.value("camera","antecipacao_px")+feel.value("impacto","tremor_px"))
    var my:=ceili(feel.value("impacto","tremor_px"))
    var edges: Array=[
        [Rect2(0,0,mx,540),Vector2(-mx,0),true,false],
        [Rect2(960-mx,0,mx,540),Vector2(960,0),true,false],
        [Rect2(0,0,960,my),Vector2(0,-my),false,true],
        [Rect2(0,540-my,960,my),Vector2(0,540),false,true]]
    for x in [0,1]:
        for y in [0,1]:
            edges.append([Rect2(0 if x==0 else 960-mx,0 if y==0 else 540-my,mx,my),Vector2(-mx if x==0 else 960,-my if y==0 else 540),true,true])
    for spec in edges:
        var edge:=TextureRect.new()
        var atlas:=AtlasTexture.new()
        atlas.atlas=background.texture
        atlas.region=spec[0]
        edge.texture=atlas
        edge.position=spec[1]
        edge.size=spec[0].size
        edge.flip_h=spec[2]
        edge.flip_v=spec[3]
        edge.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        edge.mouse_filter=Control.MOUSE_FILTER_IGNORE
        background_root.add_child(edge)
