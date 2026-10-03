extends SceneTree

## Independent reference coordinates, real physics rays and production jumps.
const ROOM := "res://scenes/biomes/cemiterio/sala_cemiterio.tscn"
const BOSQUE := "res://scenes/biomes/forest/bosque_integracao_p40.tscn"
const STEP := 1.0 / 60.0
const REFERENCE_GROUND := [
    [[0,320],[80,321],[160,322],[166,322],[166,390],[340,390]],
    [[340,390],[410,401],[500,410],[610,414],[720,417],[850,420]],
    [[850,420],[940,423],[1050,425],[1150,433],[1250,445],[1340,447]],
    [[1340,447],[1430,444],[1500,442],[1568,445]]]
const REFERENCE_PLATFORMS := [[718,820,316],[945,1070,378],[1245,1300,318],[1352,1435,345]]
var failures := 0
var checks := 0
var scene: Node2D
var p: CharacterBody2D
var metrics := {"physics_hz": 60, "routes": [], "spawns": [], "ground_rays": []}

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if ok: print("PASS: ", label)
    else:
        failures += 1
        printerr("FAIL: ", label)

func frames(n := 1) -> void:
    for _i in range(n): await physics_frame

func point(x: float, y: float) -> Vector2:
    return Vector2(x * .6154, (y + 86) * .6156)

func penetration(body: CharacterBody2D) -> Array:
    var source: CollisionShape2D = body.get_node("CollisionShape2D")
    var shape: Shape2D = source.shape.duplicate()
    if shape is CapsuleShape2D:
        shape.radius -= .01
        shape.height -= .02
    elif shape is CircleShape2D: shape.radius -= .01
    elif shape is RectangleShape2D: shape.size -= Vector2(.02,.02)
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = shape
    query.transform = source.global_transform
    query.collision_mask = 1
    query.exclude = [body.get_rid()]
    query.collide_with_areas = false
    return body.get_world_2d().direct_space_state.intersect_shape(query)

func geometry() -> void:
    check(scene.collisions.size() == 8, "quatro trechos GROUND_TOPS e quatro plataformas")
    for i in range(4):
        var collision: CollisionPolygon2D = scene.collisions[i]
        var expected: Array = REFERENCE_GROUND[i]
        check(not collision.one_way_collision and collision.polygon.size() == expected.size()+2, "chão %d sólido e fechado até y=620" % i)
        for j in range(expected.size()):
            var ref := point(expected[j][0],expected[j][1])
            check(collision.polygon[j].distance_to(ref/.9)<.001, "chão %d vértice %d igual ao P40" % [i,j])
            var screen: Vector2 = scene.get_viewport().get_canvas_transform() * collision.to_global(collision.polygon[j])
            check(screen.distance_to(ref)<.01,"chão %d/%d projetado na mesma posição do fundo ×1" % [i,j])
    for i in range(4):
        var spec: Array = REFERENCE_PLATFORMS[i]
        var a := point(spec[0],spec[2])
        var b := point(spec[1],spec[2])
        var expected := PackedVector2Array([a/.9,b/.9,(b+Vector2(0,2))/.9,(a+Vector2(0,2))/.9])
        var actual: CollisionPolygon2D = scene.collisions[i+4]
        check(actual.one_way_collision and is_equal_approx(actual.one_way_collision_margin,1/.9), "plataforma %d unidirecional, margem P40" % i)
        for j in range(4):
            check(actual.polygon[j].distance_to(expected[j])<.001, "plataforma %d/%d igual ao P40" % [i,j])
    for spec in [[30,320.375],[120,321.5],[270,390],[580,412.909090909],[1100,429],[1465,443]]:
        var expected := scene.to_global(point(spec[0],spec[1])/.9)
        var actual: Vector2 = scene.ground_at(expected.x)
        check(actual.distance_to(expected)<.01,"raio físico encontra chão de referência em x=%d" % spec[0])
        metrics.ground_rays.append({"art_x":spec[0],"world":[actual.x,actual.y]})

func jump_route(label: String, start_screen: Vector2, target: int) -> void:
    var loco: PlayerLocomotion = p.get_node("Locomotion")
    var target_spec: Array = REFERENCE_PLATFORMS[target]
    var target_screen := point((target_spec[0]+target_spec[1])*.5,target_spec[2])
    p.global_position = scene.to_global(start_screen/.9) - Vector2(0,13.05)
    p.velocity = Vector2.ZERO
    loco.reset_assists()
    await frames(2)
    for _i in range(5): loco.move(p,0,false,STEP)
    check(p.is_on_floor(), label+": partida sobre colisor real")
    if label.begins_with("chão"):
        var ground_contact := false
        for i in range(p.get_slide_collision_count()):
            ground_contact = ground_contact or String(p.get_slide_collision(i).get_collider().name).begins_with("Chao_")
        check(ground_contact,label+": partida no chão, não sobre o alvo")
    var initial_y := p.global_position.y
    var minimum_y := initial_y
    var landed := false
    var landing_tick := 0
    var positions := []
    for tick in range(90):
        var dx: float = scene.to_global(target_screen/.9).x - p.global_position.x
        var direction := signf(dx) if absf(dx)>10 else 0.0
        loco.move(p,direction,tick==0,STEP)
        minimum_y = minf(minimum_y,p.global_position.y)
        positions.append([p.global_position.x,p.global_position.y])
        if tick>3 and p.is_on_floor():
            for contact in range(p.get_slide_collision_count()):
                if p.get_slide_collision(contact).get_collider() == scene.collisions[target+4].get_parent():
                    landed=true
                    landing_tick=tick+1
            if landed: break
        await frames()
    metrics.routes.append({"route":label,"target":target,"landed":landed,"landing_ticks":landing_tick,
        "rise_screen_px":(initial_y-minimum_y)*.9,"rise_m":(initial_y-minimum_y)*.9/32,"trace":positions})
    check(landed,label+": alcança a plataforma com pulo normal, sem dash")
    check((initial_y-minimum_y)*.9>=73.9 and (initial_y-minimum_y)*.9<=75.1,label+": ápice do pulo integrado, tolerância de 1 px para contato em rampa")

func run() -> void:
    for id in InputMap.get_actions():
        InputMap.action_erase_events(id)
        Input.action_release(id)
    scene=load(ROOM).instantiate()
    root.add_child(scene)
    current_scene=scene
    p=scene.player
    p.set_physics_process(false)
    while not scene.enemies_ready: await frames()
    for enemy in scene.enemies: enemy.set_physics_process(false)
    await frames(2)
    scene.camera.force_update_scroll()
    check(ProjectSettings.get_setting("application/run/main_scene")==ROOM,"cemitério é a cena inicial deste branch")
    check(scene.camera.zoom==Vector2(.9,.9) and not scene.camera.position_smoothing_enabled,"câmera fixa 0,9 sem suavizar o fundo")
    check(not p.get_node("Camera2D").enabled,"câmera móvel do jogador desativada nesta sala")
    var image: TextureRect = scene.background
    check(image.texture.get_size()==Vector2(960,540) and image.size==Vector2(960,540) and image.scale==Vector2.ONE,"fundo nativo 960×540 em ×1")
    check(image.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"fundo usa NEAREST")
    check(scene.background_patch.position==Vector2(162,224) and scene.background_patch.size==Vector2(39,69),"mesma cobertura local do Carrasco embutido do P40, PNG intacto")
    geometry()
    check(p.get_node("MaskController").active_data().mask_id==&"carrasco_base","Carrasco inicia equipado")
    check(penetration(p).is_empty(),"jogador nasce sem interpenetração")
    for _i in range(5): p.get_node("Locomotion").move(p,0,false,STEP)
    check(p.is_on_floor(),"jogador encontra apoio no spawn")
    check(is_equal_approx(p.get_node("Locomotion").run_speed,160),"corrida preservada em 4,5 m/s")
    check(is_equal_approx(p.get_node("Defense").dodge_total_seconds,.35),"dash preservado em 350 ms")
    var form: Node=p.get_node("VisualRoot").form
    check(form.package_ready and form.character.anims.size()==26,"apresentador Pequeno A completo")
    for enemy in scene.enemies:
        var foot: float=8 if enemy.name=="Corvo" else (15.5 if enemy.name=="Peregrino" else 9)
        var ground: Vector2=scene.ground_at(enemy.global_position.x,enemy.global_position.y+foot-1)
        var gap: float=ground.y-enemy.global_position.y-foot
        metrics.spawns.append({"name":String(enemy.name),"world":[enemy.global_position.x,enemy.global_position.y],"floor_gap_world":gap,"overlaps":penetration(enemy).size()})
        check(penetration(enemy).is_empty(),"%s nasce sem atravessar chão/plataforma" % enemy.name)
        if enemy.name=="Corvo":
            check(enemy.global_position.y>=92 and enemy.global_position.y<=186 and gap>20,"Corvo nasce no alto dentro da faixa original 92–186")
        else:
            check(gap>=-.5 and gap<=.6,"%s nasce apoiado no chão" % enemy.name)
        check(enemy.get_node("Brain").player==p,"%s usa o jogador da sala, sem trocar IA" % enemy.name)
    var stone:=point(769,316)
    var ruin:=point(1007.5,378)
    var pillar:=point(1393.5,345)
    await jump_route("chão → pedra",scene.to_local(scene.ground_at(stone.x/.9,scene.to_global(stone/.9).y+5))*.9,0)
    await jump_route("chão → ruína",scene.to_local(scene.ground_at(ruin.x/.9,scene.to_global(ruin/.9).y+5))*.9,1)
    await jump_route("chão → pilar",scene.to_local(scene.ground_at(pillar.x/.9,scene.to_global(pillar/.9).y+5))*.9,3)
    await jump_route("pilar → coluna",point(1370,345),2)
    scene.restart_encounter()
    await frames(3)
    check(p.global_position.distance_to(scene.start.global_position)<.01,"R restaura o spawn da sala")
    for enemy in scene.enemies:
        check(enemy.get_node("Health").current_health==enemy.get_node("Health").max_health,"R restaura vida de %s" % enemy.name)
    p.get_node("Health").current_health=0
    scene.restart_encounter()
    check(p.get_node("Health").current_health==100 and p.get_node("Defense").mode==PlayerDefense.Mode.READY,"R renasce depois da morte com defesa pronta")
    var router: Node=root.get_node("IntegrationRooms")
    var event:=InputEventKey.new()
    event.keycode=KEY_F9
    event.pressed=true
    router._unhandled_key_input(event)
    await frames(8)
    check(current_scene.scene_file_path==BOSQUE,"F9 abre Bosque B preservado")
    check(current_scene.has_node("Player") and current_scene.enemies_ready,"Bosque continua jogável com seus três inimigos")
    router._unhandled_key_input(event)
    await frames(8)
    check(current_scene.scene_file_path==ROOM,"F9 retorna à sala nova")
    var file:=FileAccess.open("res://codex/evidencias_integracao_p40_f4/MEDIDAS_SALA.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(metrics,"  ")+"\n")
    print("ROOM_F4_RESULT checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
