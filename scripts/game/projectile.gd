extends Area2D

@export var speed: float = 680.0
@export var max_lifetime: float = 1.2
@export var hit_radius: float = 12.0

var _direction: Vector2 = Vector2.RIGHT
var _source: Node
var _weapon_damage: float = 10.0
var _damage_type: int = 0
var _bonus_pct: float = 0.0
var _penetration: float = 0.0
var _crit_multiplier: float = 1.0
var _is_crit: bool = false
var _knockback_force: float = 90.0
var _life_remaining: float = 0.0
var _active: bool = false


func setup(
    source: Node,
    direction: Vector2,
    weapon_damage: float,
    damage_type: int,
    bonus_pct: float,
    penetration: float,
    crit_multiplier: float,
    is_crit: bool,
    knockback_force: float
) -> void:
    _active = true
    _source = source
    _direction = direction.normalized()
    _weapon_damage = weapon_damage
    _damage_type = damage_type
    _bonus_pct = bonus_pct
    _penetration = penetration
    _crit_multiplier = maxf(1.0, crit_multiplier)
    _is_crit = is_crit
    _knockback_force = maxf(0.0, knockback_force)
    _life_remaining = max_lifetime


func _process(delta: float) -> void:
    if not _active:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    global_position += _direction * speed * delta
    rotation = _direction.angle()

    _life_remaining -= delta
    if _life_remaining <= 0.0:
        _recycle()
        return

    var enemy: Node2D = _find_colliding_enemy()
    if enemy == null:
        return

    var damage_value: float = DamageSystem.calculate_damage(
        _source,
        enemy,
        _weapon_damage,
        _damage_type,
        _bonus_pct,
        _penetration,
        _crit_multiplier if _is_crit else 1.0,
        1.0
    )

    if enemy.has_method("apply_damage"):
        enemy.apply_damage(
            damage_value,
            _source,
            _damage_type,
            _is_crit,
            _direction * _knockback_force
        )

    _recycle()


func _find_colliding_enemy() -> Node2D:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if not (node is Node2D):
            continue

        var enemy: Node2D = node
        if global_position.distance_to(enemy.global_position) <= hit_radius:
            return enemy

    return null


func _recycle() -> void:
    _active = false
    if ObjectPool != null:
        ObjectPool.release("projectile_basic", self)
        return
    queue_free()


func on_pool_acquired() -> void:
    _active = false
    _life_remaining = max_lifetime


func on_pool_released() -> void:
    _active = false
    _source = null
