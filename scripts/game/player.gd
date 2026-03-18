extends CharacterBody2D

@onready var _movement_component: Node = $MovementComponent
@onready var _health_component: Node = $HealthComponent
@onready var _progression_component: Node = $ProgressionComponent


func _ready() -> void:
    add_to_group("player")


func _physics_process(delta: float) -> void:
    if _movement_component != null and _movement_component.has_method("physics_process_move"):
        _movement_component.physics_process_move(delta)


func apply_damage(amount: float) -> void:
    if _health_component != null and _health_component.has_method("take_damage"):
        _health_component.take_damage(amount)


func gain_xp(amount: int) -> void:
    if _progression_component != null and _progression_component.has_method("add_xp"):
        _progression_component.add_xp(amount)


func apply_knockback(force: Vector2) -> void:
    if _movement_component != null and _movement_component.has_method("add_external_velocity"):
        _movement_component.add_external_velocity(force)
