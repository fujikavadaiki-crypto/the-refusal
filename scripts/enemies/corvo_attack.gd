class_name CorvoAttack
extends Node

signal state_requested(state: int)
signal finished
signal hit_confirmed(context: HitContext)
signal projectile_fired(projectile: CorvoProjectile)

@export var rasante: AttackData
@export var cuspe: AttackData
@export var projectile_scene: PackedScene

@onready var bird: CharacterBody2D = get_parent() as CharacterBody2D
@onready var flight: CorvoFlight = $"../Flight"
@onready var tuning: CorvoTuning = $"../Brain".tuning
@onready var hitbox: Hitbox2D = $"../DiveHitbox"
@onready var telegraph: Polygon2D = $"../DiveTelegraph"
@onready var beak: Polygon2D = $"../BeakTelegraph"

enum Mode { NONE, DIVE, PROJECTILE }
var mode := Mode.NONE
var frame_provider: Node
var elapsed := 0.0
var target_locked := Vector2.ZERO
var aim_locked := Vector2.ZERO
var target_is_locked := false
var aim_is_locked := false
var dive_velocity := Vector2.ZERO
var fired := false
var windup_anchor := Vector2.ZERO
var active_projectiles: Array[CorvoProjectile] = []


func _ready() -> void:
    telegraph.visible = false
    beak.visible = false
    hitbox.hit_confirmed.connect(func(context: HitContext) -> void: _report_contact(context, rasante))


func begin_dive() -> bool:
    if mode != Mode.NONE:
        return false
    mode = Mode.DIVE
    elapsed = 0.0
    fired = false
    target_locked = Vector2.ZERO
    target_is_locked = false
    windup_anchor = bird.global_position + Vector2(0, -tuning.dive_windup_rise)
    telegraph.visible = true
    state_requested.emit(CorvoBrain.State.DIVE_WINDUP)
    return true


func begin_projectile() -> bool:
    if mode != Mode.NONE:
        return false
    mode = Mode.PROJECTILE
    elapsed = 0.0
    fired = false
    aim_is_locked = false
    beak.visible = true
    state_requested.emit(CorvoBrain.State.PROJECTILE_WINDUP)
    return true


func tick(delta: float, player: Node2D) -> void:
    if mode == Mode.NONE:
        return
    elapsed += delta
    if mode == Mode.DIVE:
        _tick_dive(player)
    else:
        _tick_projectile(player)


func _tick_dive(player: Node2D) -> void:
    if elapsed < rasante.windup_seconds:
        if not target_is_locked and elapsed >= rasante.windup_seconds * 0.5:
            target_locked = _target_point(player)
            target_is_locked = true
        flight.seek(windup_anchor)
        return
    if dive_velocity == Vector2.ZERO:
        if not target_is_locked:
            target_locked = _target_point(player)
            target_is_locked = true
        dive_velocity = (target_locked - bird.global_position).normalized() * tuning.dive_speed
        if dive_velocity.y < tuning.dive_min_vertical_speed:
            dive_velocity = Vector2(dive_velocity.x, tuning.dive_min_vertical_speed)
        var context := _context(rasante)
        context.parry_posture_return_override = 20
        hitbox.arm(context, rasante)
        if frame_provider != null: frame_provider.apply_damage(hitbox, rasante, elapsed)
        telegraph.visible = false
        state_requested.emit(CorvoBrain.State.DIVE_ACTIVE)
    if elapsed < rasante.windup_seconds + rasante.active_seconds and not bird.is_on_floor():
        flight.commit(dive_velocity)
        # Profiled geometry is queried after Flight resolves the moving bird.
        if frame_provider == null or not frame_provider.apply_damage(hitbox, rasante, elapsed): hitbox.scan_overlaps()
        return
    if hitbox.active:
        hitbox.disarm()
        flight.seek(Vector2(bird.global_position.x - bird.facing_direction * tuning.dive_recovery_backstep, bird.global_position.y - tuning.dive_recovery_rise))
        state_requested.emit(CorvoBrain.State.DIVE_RECOVERY)
    if elapsed >= rasante.total_seconds():
        _finish()


func _tick_projectile(player: Node2D) -> void:
    if elapsed < cuspe.windup_seconds:
        if elapsed >= cuspe.windup_seconds * 0.5 and not aim_is_locked:
            aim_locked = _target_point(player)
            aim_is_locked = true
        flight.seek(bird.global_position)
        return
    if not fired:
        fired = true
        if not aim_is_locked:
            aim_locked = _target_point(player)
            aim_is_locked = true
        var projectile := projectile_scene.instantiate() as CorvoProjectile
        bird.get_parent().add_child(projectile)
        projectile.frame_provider = frame_provider
        projectile.launch(bird, bird.global_position + Vector2(7 * bird.facing_direction, 3), aim_locked, tuning.projectile_speed, tuning.projectile_lifetime)
        projectile.expired.connect(_on_projectile_expired)
        projectile.contact.connect(func(context: HitContext) -> void: _report_contact(context, cuspe))
        active_projectiles.append(projectile)
        projectile_fired.emit(projectile)
        beak.visible = false
        state_requested.emit(CorvoBrain.State.PROJECTILE_ATTACK)
    if elapsed >= cuspe.windup_seconds + cuspe.active_seconds and elapsed < cuspe.total_seconds():
        state_requested.emit(CorvoBrain.State.PROJECTILE_RECOVERY)
    if elapsed >= cuspe.total_seconds():
        _finish()


func _target_point(player: Node2D) -> Vector2:
    return player.global_position + Vector2(0, -3) if is_instance_valid(player) else bird.global_position + Vector2(40 * bird.facing_direction, 40)

func resolve_frame_contact() -> void:
    if mode == Mode.DIVE and hitbox.active and frame_provider != null:
        if frame_provider.apply_damage(hitbox, rasante, elapsed): hitbox.scan_overlaps()


func _context(data: AttackData) -> HitContext:
    var context := HitContext.new()
    context.attacker = bird
    context.attacker_posture = bird.get_node("Posture") as PostureComponent
    context.attacker_stats = bird.get_node("DefenseStats") as DefenseStats
    context.attack_id = data.attack_id
    context.action_uid = HitContext.allocate_action_id()
    context.base_damage = data.base_damage
    context.posture_damage = data.posture_damage
    context.damage_type = data.damage_type
    context.parry_class = data.parry_class
    context.tags = data.tags.duplicate()
    return context


func abort() -> void:
    mode = Mode.NONE
    elapsed = 0.0
    target_locked = Vector2.ZERO
    aim_locked = Vector2.ZERO
    target_is_locked = false
    aim_is_locked = false
    dive_velocity = Vector2.ZERO
    fired = false
    hitbox.disarm()
    telegraph.visible = false
    beak.visible = false


func clear_projectiles() -> void:
    var projectiles := active_projectiles.duplicate()
    active_projectiles.clear()
    for projectile in projectiles:
        if is_instance_valid(projectile):
            projectile.expire()


func _finish() -> void:
    abort()
    finished.emit()


func _on_projectile_expired(projectile: CorvoProjectile) -> void:
    active_projectiles.erase(projectile)


func _report_contact(context: HitContext, data: AttackData) -> void:
    hit_confirmed.emit(context)
    if context.outcome in [HitContext.Outcome.DAMAGED, HitContext.Outcome.DEAD]:
        get_node("/root/HitStop").request_hit(context)
