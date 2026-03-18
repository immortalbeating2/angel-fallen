extends Node2D

signal picked(pickup_type: String, amount: int, pickup_id: String)

@export var pickup_id: String = "xp_gem_small"
@export var pickup_type: String = "xp"
@export var amount: int = 1
@export var magnet_range: float = 160.0
@export var collect_range: float = 16.0
@export var move_speed: float = 260.0

@onready var _visual: Polygon2D = $Polygon2D

var _player: CharacterBody2D
var _active: bool = true


func _ready() -> void:
    add_to_group("pickup")
    _apply_visual_style()


func _process(delta: float) -> void:
    if not _active:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as CharacterBody2D
    if _player == null:
        return

    var distance: float = global_position.distance_to(_player.global_position)
    if distance <= collect_range:
        picked.emit(pickup_type, amount, pickup_id)
        EventBus.pickup_collected.emit(pickup_type, amount)
        _recycle()
        return

    if distance <= magnet_range:
        var direction: Vector2 = (_player.global_position - global_position).normalized()
        global_position += direction * move_speed * delta


func _apply_visual_style() -> void:
    if _visual == null:
        return

    match pickup_type:
        "xp":
            _visual.color = Color(0.36, 0.73, 1.0, 1.0)
        "gold":
            _visual.color = Color(1.0, 0.83, 0.24, 1.0)
        "ore":
            _visual.color = Color(0.7, 0.55, 0.85, 1.0)
        "hp":
            _visual.color = Color(0.4, 1.0, 0.45, 1.0)
        "accessory":
            _visual.color = Color(0.94, 0.58, 0.94, 1.0)
        _:
            _visual.color = Color(1.0, 1.0, 1.0, 1.0)


func configure(new_type: String, new_amount: int, new_id: String) -> void:
    pickup_type = new_type
    amount = max(1, new_amount)
    pickup_id = new_id
    _apply_visual_style()


func on_pool_acquired() -> void:
    _active = true
    _player = null
    _apply_visual_style()


func on_pool_released() -> void:
    _active = false
    _player = null


func _recycle() -> void:
    _active = false
    if ObjectPool != null:
        ObjectPool.release("pickup_basic", self)
        return
    queue_free()
