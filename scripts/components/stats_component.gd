extends Node

signal stamina_updated(current: float, max_value: float)

@export var base_move_speed: float = 180.0
@export var sprint_multiplier: float = 1.6
@export var stamina_max: float = 100.0
@export var stamina_drain_per_sec: float = 30.0
@export var stamina_recover_per_sec: float = 20.0
@export var stamina_recover_delay: float = 0.5
@export var min_stamina_to_sprint: float = 20.0
@export var armor: float = 0.0
@export var damage_bonus_pct: float = 0.0
@export var crit_chance: float = 0.08
@export var crit_multiplier: float = 1.6
@export var knockback_power: float = 95.0
@export var frostbite_resistance: float = 0.0
@export var void_resistance: float = 0.0

var current_stamina: float = 100.0
var _recover_cooldown: float = 0.0


func _ready() -> void:
    current_stamina = stamina_max
    _emit_stamina()


func tick_stamina(delta: float, wants_sprint: bool) -> bool:
    var was_sprinting: bool = false
    var previous: float = current_stamina

    # 体力用“消耗 -> 冷却 -> 回复”三段式，防止冲刺键快速点按时获得非预期的高机动性。
    if wants_sprint and current_stamina >= min_stamina_to_sprint:
        current_stamina = maxf(0.0, current_stamina - stamina_drain_per_sec * delta)
        _recover_cooldown = stamina_recover_delay
        was_sprinting = true
    elif _recover_cooldown > 0.0:
        _recover_cooldown = maxf(0.0, _recover_cooldown - delta)
    else:
        current_stamina = minf(stamina_max, current_stamina + stamina_recover_per_sec * delta)

    if not is_equal_approx(previous, current_stamina):
        _emit_stamina()

    return was_sprinting


func get_armor_capped() -> float:
    return clampf(armor, 0.0, 0.75)


func _emit_stamina() -> void:
    stamina_updated.emit(current_stamina, stamina_max)
    EventBus.stamina_changed.emit(current_stamina, stamina_max)
