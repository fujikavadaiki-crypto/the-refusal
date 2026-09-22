class_name Hurtbox2D
extends Area2D

@export var receiver_path: NodePath
@onready var receiver: HealthComponent = get_node_or_null(receiver_path) as HealthComponent


func receive_hit(context: HitContext) -> bool:
    if receiver == null or context.attacker == receiver.get_parent():
        return false
    return receiver.receive_hit(context)
