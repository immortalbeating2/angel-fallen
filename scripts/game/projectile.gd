extends Area2D

@export var speed: float = 680.0
@export var max_lifetime: float = 1.2
@export var hit_radius: float = 12.0

@onready var _shape: Polygon2D = $Polygon2D

var _direction: Vector2 = Vector2.RIGHT
var _source: Node
var _weapon_damage: float = 10.0
var _damage_type: int = 0
var _bonus_pct: float = 0.0
var _penetration: float = 0.0
var _crit_multiplier: float = 1.0
var _is_crit: bool = false
var _knockback_force: float = 90.0
var _remaining_hits: int = 1
var _hit_enemy_ids: Dictionary = {}
var _style_id: String = "default"
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
    knockback_force: float,
    max_hits: int = 1,
    style_id: String = "default"
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
    _remaining_hits = max(1, max_hits)
    _style_id = style_id
    _hit_enemy_ids.clear()
    _life_remaining = max_lifetime
    _apply_visual_style(_style_id, _is_crit)


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

    # 命中时才实时结算最终伤害，确保暴击、穿透和来源属性都按发射瞬间快照参与计算。
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

    _hit_enemy_ids[enemy.get_instance_id()] = true
    _remaining_hits -= 1
    if _remaining_hits <= 0:
        _recycle()


func _find_colliding_enemy() -> Node2D:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if not (node is Node2D):
            continue

        var enemy: Node2D = node
        if _hit_enemy_ids.has(enemy.get_instance_id()):
            continue
        # 这里用轻量距离检测替代物理碰撞回调，方便对象池投射物在无额外碰撞配置时也能稳定工作。
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
    _remaining_hits = 1
    _hit_enemy_ids.clear()
    _style_id = "default"
    _life_remaining = max_lifetime


func on_pool_released() -> void:
    _active = false
    _remaining_hits = 1
    _hit_enemy_ids.clear()
    _style_id = "default"
    _source = null


func _apply_visual_style(style_id: String, is_crit: bool) -> void:
    if _shape == null:
        return

    # 投射物外观直接由武器风格 id 决定，暴击只额外做一次高亮混色，不改底层几何模板。
    var color: Color = Color(1.0, 0.93, 0.44, 1.0)
    var polygon: PackedVector2Array = PackedVector2Array([-6, -3, 8, 0, -6, 3])

    match style_id.to_lower():
        "knight_lance":
            color = Color(0.70, 0.88, 1.0, 1.0)
            polygon = PackedVector2Array([-8, -2, 11, 0, -8, 2])
        "mage_orb":
            color = Color(0.64, 0.56, 1.0, 1.0)
            polygon = PackedVector2Array([-4, -4, 0, -7, 4, -4, 7, 0, 4, 4, 0, 7, -4, 4, -7, 0])
        "rogue_dart":
            color = Color(0.55, 1.0, 0.78, 1.0)
            polygon = PackedVector2Array([-7, -1.5, 10, 0, -7, 1.5])

    if is_crit:
        color = color.lerp(Color(1.0, 0.95, 0.55, 1.0), 0.45)

    _shape.color = color
    _shape.polygon = polygon
