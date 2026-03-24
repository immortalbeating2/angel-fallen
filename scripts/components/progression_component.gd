extends Node

signal xp_changed(current_xp: int, next_xp: int, level: int)
signal leveled_up(new_level: int)

@export var max_level: int = 40

var current_level: int = 1
var current_xp: int = 0
var xp_to_next: int = 10


func _ready() -> void:
    xp_to_next = _calc_xp_for_level(current_level)
    _emit_xp()


func add_xp(amount: int) -> void:
    if amount <= 0:
        return

    current_xp += amount
    EventBus.xp_gained.emit(amount)

    # 使用 while 支持一次拾取连跳多级，避免大额经验被卡在单次升级上限里。
    while current_level < max_level and current_xp >= xp_to_next:
        current_xp -= xp_to_next
        current_level += 1
        xp_to_next = _calc_xp_for_level(current_level)
        leveled_up.emit(current_level)
        EventBus.player_leveled_up.emit(current_level)

    _emit_xp()


func _calc_xp_for_level(level: int) -> int:
    var config: Dictionary = ConfigManager.get_config("xp_curve", {})
    var base_xp: int = int(config.get("base_xp", 10))
    var exponent: float = float(config.get("curve_exponent", 1.3))
    return maxi(1, int(round(base_xp * pow(float(level), exponent))))


func _emit_xp() -> void:
    xp_changed.emit(current_xp, xp_to_next, current_level)
