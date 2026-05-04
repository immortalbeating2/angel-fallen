extends Area2D

@export var speed: float = 330.0
@export var max_lifetime: float = 1.6
@export var hit_radius: float = 14.0

@onready var _trail: Line2D = $Trail
@onready var _shape: Polygon2D = $Polygon2D

var _direction: Vector2 = Vector2.RIGHT
var _damage: float = 6.0
var _knockback_force: float = 42.0
var _life_remaining: float = 0.0
var _active: bool = false


func setup(direction: Vector2, damage: float, knockback_force: float = 42.0, style_id: String = "ranged") -> void:
    _direction = direction.normalized()
    if _direction == Vector2.ZERO:
        _direction = Vector2.RIGHT
    _damage = maxf(0.0, damage)
    _knockback_force = maxf(0.0, knockback_force)
    _life_remaining = max_lifetime
    _active = true
    rotation = _direction.angle()
    _apply_style(style_id)


func _process(delta: float) -> void:
    if not _active:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    global_position += _direction * speed * delta
    rotation = _direction.angle()

    _life_remaining -= delta
    if _life_remaining <= 0.0:
        queue_free()
        return

    var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
    if player == null:
        return
    if global_position.distance_to(player.global_position) > hit_radius:
        return

    if player.has_method("apply_damage"):
        player.apply_damage(_damage)
    if player.has_method("apply_knockback"):
        player.apply_knockback(_direction * _knockback_force)
    queue_free()


func _apply_style(style_id: String) -> void:
    var color: Color = Color(1.0, 0.58, 0.32, 1.0)
    var polygon: PackedVector2Array = PackedVector2Array([-7, -4, 8, 0, -7, 4])
    match style_id.to_lower():
        "hex":
            color = Color(1.0, 0.74, 0.36, 1.0)
            polygon = PackedVector2Array([-6, -5, 4, -5, 10, 0, 4, 5, -6, 5, -10, 0])
        "void":
            color = Color(0.86, 0.52, 1.0, 1.0)
        "frost":
            color = Color(0.62, 0.92, 1.0, 1.0)

    if _shape != null:
        _shape.color = color
        _shape.polygon = polygon
    if _trail != null:
        _trail.default_color = Color(color.r, color.g, color.b, 0.42)
