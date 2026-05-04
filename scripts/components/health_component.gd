extends Node

signal died(owner_node: Node)

@export var max_hp: float = 100.0
var current_hp: float = 100.0


func _ready() -> void:
    current_hp = max_hp
    var health_owner: Node = _get_health_owner()
    if health_owner != null and health_owner.is_in_group("player"):
        EventBus.health_changed.emit(current_hp, max_hp)


func take_damage(amount: float) -> bool:
    var clamped: float = maxf(0.0, amount)
    current_hp = clampf(current_hp - clamped, 0.0, max_hp)
    var health_owner: Node = _get_health_owner()
    if health_owner != null and health_owner.is_in_group("player"):
        EventBus.health_changed.emit(current_hp, max_hp)
    if current_hp <= 0.0:
        # 使用运行时父节点作为生命归属，避免场景 owner 指向根节点时漏发玩家死亡事件。
        died.emit(health_owner)
        if health_owner != null and health_owner.is_in_group("player"):
            EventBus.player_died.emit("hp_depleted")
        return true
    return false


func heal(amount: float) -> void:
    current_hp = clampf(current_hp + maxf(0.0, amount), 0.0, max_hp)
    var health_owner: Node = _get_health_owner()
    if health_owner != null and health_owner.is_in_group("player"):
        EventBus.health_changed.emit(current_hp, max_hp)


func _get_health_owner() -> Node:
    return get_parent()
