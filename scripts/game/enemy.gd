extends CharacterBody2D

@export var enemy_id: String = "enemy_shadowling"
@export var move_speed: float = 72.0
@export var touch_damage: float = 8.0
@export var attack_interval: float = 0.7
@export var boss_dash_cooldown: float = 4.8
@export var boss_pulse_cooldown: float = 5.5

@onready var _health_component: Node = $HealthComponent
@onready var _visual: Polygon2D = $Polygon2D

var _player: CharacterBody2D
var _touch_cooldown: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _is_boss: bool = false
var _phase_thresholds: Array[float] = [1.0, 0.6, 0.3]
var _phase_index: int = 0
var _phase_speed_mult: float = 1.0
var _phase_damage_mult: float = 1.0
var _dash_cooldown_timer: float = 0.0
var _pulse_cooldown_timer: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_time: float = 0.0
var _base_attack_interval: float = 0.7
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
    add_to_group("enemy")
    _base_attack_interval = attack_interval
    _base_scale = scale
    _is_boss = enemy_id.begins_with("boss_")

    if _health_component != null and _health_component.has_signal("died"):
        _health_component.died.connect(_on_health_died)

    if _is_boss:
        _load_boss_phase_thresholds()
        _dash_cooldown_timer = randf_range(1.2, 2.2)
        _pulse_cooldown_timer = randf_range(2.2, 3.2)
        _apply_phase_stats()
        if _visual != null:
            _visual.color = Color(0.95, 0.45, 0.2, 1.0)


func _physics_process(delta: float) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING:
        velocity = Vector2.ZERO
        return

    if _touch_cooldown > 0.0:
        _touch_cooldown = maxf(0.0, _touch_cooldown - delta)

    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as CharacterBody2D

    if _player == null:
        velocity = Vector2.ZERO
        return

    var direction: Vector2 = (_player.global_position - global_position).normalized()
    if _is_boss:
        _update_phase_by_hp()
        _process_boss_skills(delta, direction)

    velocity = direction * (move_speed * _phase_speed_mult) + _knockback_velocity + _dash_velocity
    _knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 780.0 * delta)
    _dash_velocity = _dash_velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
    _dash_time = maxf(0.0, _dash_time - delta)
    move_and_slide()

    var hit_range: float = 22.0
    if _is_boss:
        hit_range = 34.0

    if _touch_cooldown <= 0.0 and global_position.distance_to(_player.global_position) <= hit_range:
        _touch_cooldown = attack_interval
        if _player.has_method("apply_damage"):
            var impact_damage: float = touch_damage * _phase_damage_mult
            if _dash_time > 0.0:
                impact_damage *= 1.35
            _player.apply_damage(impact_damage)
            if _player.has_method("apply_knockback"):
                var push: Vector2 = (_player.global_position - global_position).normalized()
                _player.apply_knockback(push * (90.0 + 24.0 * _phase_index))


func apply_damage(
    amount: float,
    _source: Node = null,
    _damage_type: int = 0,
    is_crit: bool = false,
    knockback: Vector2 = Vector2.ZERO
) -> void:
    if _health_component != null and _health_component.has_method("take_damage"):
        _health_component.take_damage(amount)
    if knockback != Vector2.ZERO:
        var knockback_scale: float = 1.0
        if _is_boss:
            knockback_scale = 0.45
        _knockback_velocity += knockback * knockback_scale
    _play_hit_feedback(is_crit)


func _on_health_died(owner_node: Node) -> void:
    if owner_node != self:
        return
    EventBus.enemy_killed.emit(enemy_id, global_position)
    queue_free()


func _play_hit_feedback(is_crit: bool) -> void:
    if _visual == null:
        return

    var flash_color: Color = Color(1.0, 0.46, 0.46, 1.0)
    var target_scale: Vector2 = _base_scale * 1.08
    if is_crit:
        flash_color = Color(1.0, 0.88, 0.36, 1.0)
        target_scale = _base_scale * 1.22

    _visual.color = flash_color
    scale = target_scale

    var tween: Tween = create_tween()
    var return_color: Color = Color(0.83, 0.37, 0.37, 1.0)
    if _is_boss:
        return_color = Color(0.95, 0.45, 0.2, 1.0)
    tween.tween_property(_visual, "color", return_color, 0.12)
    tween.parallel().tween_property(self, "scale", _base_scale, 0.12)


func set_visual_scale_base(new_scale: Vector2) -> void:
    _base_scale = new_scale


func _update_phase_by_hp() -> void:
    if _health_component == null or _health_component.get("max_hp") == null:
        return

    var max_hp_value: float = float(_health_component.max_hp)
    if max_hp_value <= 0.0:
        return

    var hp_ratio: float = clampf(float(_health_component.current_hp) / max_hp_value, 0.0, 1.0)
    var new_phase: int = 0
    for i in range(1, _phase_thresholds.size()):
        if hp_ratio <= _phase_thresholds[i]:
            new_phase = i

    if new_phase == _phase_index:
        return

    _phase_index = new_phase
    _apply_phase_stats()


func _apply_phase_stats() -> void:
    _phase_speed_mult = 1.0 + 0.12 * _phase_index
    _phase_damage_mult = 1.0 + 0.22 * _phase_index
    attack_interval = maxf(0.24, _base_attack_interval * (1.0 - 0.12 * _phase_index))


func _process_boss_skills(delta: float, direction: Vector2) -> void:
    _dash_cooldown_timer -= delta
    _pulse_cooldown_timer -= delta

    if _dash_cooldown_timer <= 0.0:
        _dash_cooldown_timer = maxf(1.5, boss_dash_cooldown - 0.55 * _phase_index)
        _dash_time = 0.42
        _dash_velocity = direction * (300.0 + 80.0 * _phase_index)

    if _pulse_cooldown_timer <= 0.0:
        _pulse_cooldown_timer = maxf(2.0, boss_pulse_cooldown - 0.45 * _phase_index)
        _cast_phase_pulse()


func _cast_phase_pulse() -> void:
    if _player == null:
        return

    var radius: float = 190.0 + 28.0 * _phase_index
    var distance: float = global_position.distance_to(_player.global_position)
    if distance > radius:
        return

    var pulse_damage: float = touch_damage * (0.7 + 0.4 * _phase_index)
    if _player.has_method("apply_damage"):
        _player.apply_damage(pulse_damage)
    if _player.has_method("apply_knockback"):
        var push: Vector2 = (_player.global_position - global_position).normalized()
        if push == Vector2.ZERO:
            push = Vector2.RIGHT
        _player.apply_knockback(push * (110.0 + 30.0 * _phase_index))

    if _visual != null:
        var pulse_tween: Tween = create_tween()
        pulse_tween.tween_property(_visual, "color", Color(1.0, 0.78, 0.34, 1.0), 0.08)
        pulse_tween.tween_property(_visual, "color", Color(0.95, 0.45, 0.2, 1.0), 0.12)


func _load_boss_phase_thresholds() -> void:
    var config: Dictionary = ConfigManager.get_config("boss_phases", {})
    var bosses_var: Variant = config.get("bosses", {})
    if not (bosses_var is Dictionary):
        return

    var bosses: Dictionary = bosses_var
    var phase_key: String = enemy_id
    if enemy_id.begins_with("boss_"):
        phase_key = "enemy_%s" % enemy_id.trim_prefix("boss_")

    var thresholds_var: Variant = bosses.get(phase_key, [])
    if not (thresholds_var is Array):
        return

    var parsed: Array[float] = []
    for value: Variant in thresholds_var:
        parsed.append(clampf(float(value), 0.0, 1.0))
    if parsed.size() >= 2:
        _phase_thresholds = parsed
