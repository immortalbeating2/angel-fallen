extends CharacterBody2D

@export var enemy_id: String = "enemy_shadowling"
@export var move_speed: float = 72.0
@export var touch_damage: float = 8.0
@export var attack_interval: float = 0.7
@export var boss_dash_cooldown: float = 4.8
@export var boss_pulse_cooldown: float = 5.5
@export var boss_frost_shard_cooldown: float = 3.9
@export var boss_void_grasp_cooldown: float = 4.3

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
var _frost_shard_cooldown_timer: float = 0.0
var _void_grasp_cooldown_timer: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_time: float = 0.0
var _base_attack_interval: float = 0.7
var _base_scale: Vector2 = Vector2.ONE
var _tier: String = "normal"
var _archetype: String = "normal"
var _is_ranged: bool = false
var _preferred_range: float = 170.0
var _ranged_attack_range: float = 255.0
var _ranged_attack_interval: float = 1.2
var _ranged_damage_mult: float = 0.82
var _ranged_cooldown: float = 0.0
var _base_color: Color = Color(0.83, 0.37, 0.37, 1.0)
var _pool_active: bool = true
var _template_enemy_id: String = "enemy_shadowling"
var _template_move_speed: float = 72.0
var _template_touch_damage: float = 8.0
var _template_attack_interval: float = 0.7
var _template_max_hp: float = 32.0
var _template_scale: Vector2 = Vector2.ONE


func _ready() -> void:
    _capture_template_state()
    _set_pool_active(true)
    _reset_for_spawn()

    if _health_component != null and _health_component.has_signal("died"):
        var callback: Callable = Callable(self, "_on_health_died")
        if not _health_component.died.is_connected(callback):
            _health_component.died.connect(callback)


func _physics_process(delta: float) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING:
        velocity = Vector2.ZERO
        return

    if _touch_cooldown > 0.0:
        _touch_cooldown = maxf(0.0, _touch_cooldown - delta)
    if _ranged_cooldown > 0.0:
        _ranged_cooldown = maxf(0.0, _ranged_cooldown - delta)

    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as CharacterBody2D

    if _player == null:
        velocity = Vector2.ZERO
        return

    var to_player: Vector2 = _player.global_position - global_position
    var distance_to_player: float = to_player.length()
    var direction: Vector2 = to_player.normalized()
    if _is_boss:
        _update_phase_by_hp()
        _process_boss_skills(delta, direction)
    elif _is_ranged:
        direction = _get_ranged_direction(direction, distance_to_player)
        _process_ranged_attack(distance_to_player)

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
    if ObjectPool != null:
        ObjectPool.release("enemy_basic", self)
    else:
        queue_free()


func on_pool_acquired() -> void:
    _set_pool_active(true)
    _reset_for_spawn()


func on_pool_released() -> void:
    _set_pool_active(false)
    _reset_for_pool()


func is_pool_active() -> bool:
    return _pool_active


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
    tween.tween_property(_visual, "color", _base_color, 0.12)
    tween.parallel().tween_property(self, "scale", _base_scale, 0.12)


func set_visual_scale_base(new_scale: Vector2) -> void:
    _base_scale = new_scale


func apply_spawn_profile(profile: Dictionary) -> void:
    var new_tier: String = str(profile.get("tier", "normal"))
    var new_archetype: String = str(profile.get("archetype", "normal"))
    var new_enemy_id: String = str(profile.get("enemy_id", enemy_id))

    if new_enemy_id != "":
        enemy_id = new_enemy_id

    _tier = new_tier
    _archetype = new_archetype
    _is_boss = _tier == "boss" or enemy_id.begins_with("boss_")
    _is_ranged = bool(profile.get("ranged", _archetype == "ranged"))
    _preferred_range = maxf(80.0, float(profile.get("preferred_range", 170.0)))
    _ranged_attack_range = maxf(_preferred_range + 20.0, float(profile.get("ranged_attack_range", 255.0)))
    _ranged_attack_interval = clampf(float(profile.get("ranged_attack_interval", 1.2)), 0.35, 4.0)
    _ranged_damage_mult = clampf(float(profile.get("ranged_damage_mult", 0.82)), 0.2, 3.0)
    _ranged_cooldown = randf_range(0.1, _ranged_attack_interval)

    var base_color_var: Variant = profile.get("base_color", _resolve_default_color())
    if base_color_var is Color:
        _base_color = base_color_var
    else:
        _base_color = _resolve_default_color()

    var scale_var: Variant = profile.get("scale", _base_scale)
    if scale_var is Vector2:
        _base_scale = scale_var

    scale = _base_scale
    _base_attack_interval = attack_interval
    _apply_visual_defaults()

    if _is_boss:
        _load_boss_phase_thresholds()
        _phase_index = 0
        _apply_phase_stats()


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

    var previous_phase: int = _phase_index
    _phase_index = new_phase
    _apply_phase_stats()
    _apply_phase_transition_pressure(previous_phase, _phase_index)


func _apply_phase_stats() -> void:
    _phase_speed_mult = 1.0 + 0.12 * _phase_index
    _phase_damage_mult = 1.0 + 0.22 * _phase_index
    attack_interval = maxf(0.24, _base_attack_interval * (1.0 - 0.12 * _phase_index))


func _apply_phase_transition_pressure(previous_phase: int, new_phase: int) -> void:
    if not _is_boss:
        return
    if new_phase <= previous_phase:
        return

    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as CharacterBody2D
    if _player == null:
        return

    var radius: float = 156.0 + 30.0 * new_phase
    var distance: float = global_position.distance_to(_player.global_position)
    if distance > radius:
        return

    var burst_damage: float = touch_damage * (0.42 + 0.18 * new_phase)
    var impulse: Vector2 = (_player.global_position - global_position).normalized()
    if impulse == Vector2.ZERO:
        impulse = Vector2.RIGHT
    var burst_color: Color = Color(1.0, 0.78, 0.34, 1.0)

    if _is_frost_king():
        burst_damage *= 1.08
        burst_color = Color(0.76, 0.95, 1.0, 1.0)
    elif _is_void_lord():
        burst_damage *= 1.18
        impulse = -impulse
        burst_color = Color(0.82, 0.58, 1.0, 1.0)

    if _player.has_method("apply_damage"):
        _player.apply_damage(burst_damage)
    if _player.has_method("apply_knockback"):
        _player.apply_knockback(impulse * (126.0 + 22.0 * new_phase))

    if _visual != null:
        var phase_tween: Tween = create_tween()
        phase_tween.tween_property(_visual, "color", burst_color, 0.08)
        phase_tween.tween_property(_visual, "color", _base_color, 0.15)

    if AudioManager != null and AudioManager.has_method("play_boss_phase_cue"):
        AudioManager.play_boss_phase_cue(enemy_id, new_phase, 2 + new_phase, 0.115)


func _process_boss_skills(delta: float, direction: Vector2) -> void:
    _dash_cooldown_timer -= delta
    _pulse_cooldown_timer -= delta

    if _is_frost_king():
        _frost_shard_cooldown_timer -= delta
    if _is_void_lord():
        _void_grasp_cooldown_timer -= delta

    if _dash_cooldown_timer <= 0.0:
        _dash_cooldown_timer = maxf(1.5, boss_dash_cooldown - 0.55 * _phase_index)
        _dash_time = 0.42
        _dash_velocity = direction * (300.0 + 80.0 * _phase_index)

    if _pulse_cooldown_timer <= 0.0:
        _pulse_cooldown_timer = maxf(2.0, boss_pulse_cooldown - 0.45 * _phase_index)
        _cast_phase_pulse()

    if _is_frost_king() and _frost_shard_cooldown_timer <= 0.0:
        _frost_shard_cooldown_timer = _get_frost_shard_cooldown_for_phase()
        _cast_frost_king_shardburst()

    if _is_void_lord() and _void_grasp_cooldown_timer <= 0.0:
        _void_grasp_cooldown_timer = _get_void_grasp_cooldown_for_phase()
        _cast_void_lord_gravity_well()


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
        var pulse_color: Color = Color(1.0, 0.78, 0.34, 1.0)
        if _is_frost_king():
            pulse_color = Color(0.72, 0.92, 1.0, 1.0)
        elif _is_void_lord():
            pulse_color = Color(0.78, 0.56, 0.98, 1.0)
        pulse_tween.tween_property(_visual, "color", pulse_color, 0.08)
        pulse_tween.tween_property(_visual, "color", _base_color, 0.12)


func _cast_frost_king_shardburst() -> void:
    if _player == null:
        return

    var radius: float = 170.0 + 34.0 * _phase_index
    var distance: float = global_position.distance_to(_player.global_position)
    if distance > radius:
        return

    var shard_damage: float = touch_damage * (0.56 + 0.2 * _phase_index)
    if _player.has_method("apply_damage"):
        _player.apply_damage(shard_damage)
        if _phase_index >= 1:
            _player.apply_damage(shard_damage * 0.33)

    if _player.has_method("apply_knockback"):
        var push: Vector2 = (_player.global_position - global_position).normalized()
        if push == Vector2.ZERO:
            push = Vector2.RIGHT
        _player.apply_knockback(push * (145.0 + 26.0 * _phase_index))

    if _visual != null:
        var tween: Tween = create_tween()
        tween.tween_property(_visual, "color", Color(0.72, 0.92, 1.0, 1.0), 0.08)
        tween.tween_property(_visual, "color", _base_color, 0.12)


func _cast_void_lord_gravity_well() -> void:
    if _player == null:
        return

    var radius: float = 190.0 + 32.0 * _phase_index
    var distance: float = global_position.distance_to(_player.global_position)
    if distance > radius:
        return

    var well_damage: float = touch_damage * (0.5 + 0.24 * _phase_index)
    if _player.has_method("apply_damage"):
        _player.apply_damage(well_damage)
        if _phase_index >= 2:
            _player.apply_damage(well_damage * 0.4)

    if _player.has_method("apply_knockback"):
        var pull: Vector2 = (global_position - _player.global_position).normalized()
        if pull == Vector2.ZERO:
            pull = Vector2.LEFT
        _player.apply_knockback(pull * (84.0 + 24.0 * _phase_index))

    if _visual != null:
        var tween: Tween = create_tween()
        tween.tween_property(_visual, "color", Color(0.78, 0.56, 0.98, 1.0), 0.08)
        tween.tween_property(_visual, "color", _base_color, 0.12)


func _is_frost_king() -> bool:
    return enemy_id.find("frost_king") >= 0


func _is_void_lord() -> bool:
    return enemy_id.find("void_lord") >= 0


func _get_frost_shard_cooldown_for_phase() -> float:
    return maxf(1.5, boss_frost_shard_cooldown - 0.42 * _phase_index)


func _get_void_grasp_cooldown_for_phase() -> float:
    return maxf(1.7, boss_void_grasp_cooldown - 0.36 * _phase_index)


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


func get_phase_index() -> int:
    return _phase_index


func play_boss_support_stage_cue(phase_index: int, includes_miniboss: bool = false) -> void:
    if not _is_boss:
        return
    if _visual == null:
        return

    var cue_color: Color = Color(1.0, 0.82, 0.36, 1.0)
    if _is_frost_king():
        cue_color = Color(0.74, 0.94, 1.0, 1.0)
    elif _is_void_lord():
        cue_color = Color(0.82, 0.62, 1.0, 1.0)
    if includes_miniboss:
        cue_color = cue_color.lightened(0.12)

    var pulse_scale: float = 1.04 + 0.03 * clampf(float(phase_index), 0.0, 4.0)
    if includes_miniboss:
        pulse_scale += 0.05

    var tween: Tween = create_tween()
    tween.tween_property(_visual, "color", cue_color, 0.08)
    tween.parallel().tween_property(self, "scale", _base_scale * pulse_scale, 0.08)
    tween.tween_property(_visual, "color", _base_color, 0.14)
    tween.parallel().tween_property(self, "scale", _base_scale, 0.14)


func _get_ranged_direction(direction_to_player: Vector2, distance_to_player: float) -> Vector2:
    if distance_to_player > _preferred_range + 28.0:
        return direction_to_player
    if distance_to_player < _preferred_range - 24.0:
        return -direction_to_player

    var strafe: Vector2 = Vector2(-direction_to_player.y, direction_to_player.x)
    if strafe == Vector2.ZERO:
        strafe = Vector2.RIGHT
    var sign_value: float = 1.0
    if int(Time.get_ticks_msec() / 550) % 2 == 0:
        sign_value = -1.0
    return strafe * sign_value


func _process_ranged_attack(distance_to_player: float) -> void:
    if _player == null:
        return
    if distance_to_player > _ranged_attack_range:
        return
    if _ranged_cooldown > 0.0:
        return

    _ranged_cooldown = _ranged_attack_interval
    var damage: float = touch_damage * _phase_damage_mult * _ranged_damage_mult
    if _player.has_method("apply_damage"):
        _player.apply_damage(damage)
    if _player.has_method("apply_knockback"):
        var push: Vector2 = (_player.global_position - global_position).normalized()
        if push == Vector2.ZERO:
            push = Vector2.RIGHT
        _player.apply_knockback(push * 38.0)

    if _visual != null:
        var pulse_tween: Tween = create_tween()
        pulse_tween.tween_property(_visual, "color", Color(1.0, 0.9, 0.4, 1.0), 0.06)
        pulse_tween.tween_property(_visual, "color", _base_color, 0.1)


func _resolve_default_color() -> Color:
    if enemy_id.begins_with("boss_"):
        return Color(0.95, 0.45, 0.2, 1.0)
    if enemy_id.begins_with("elite_"):
        return Color(0.98, 0.84, 0.3, 1.0)
    if enemy_id.find("stalker") >= 0:
        return Color(0.78, 0.52, 0.96, 1.0)
    if enemy_id.find("brute") >= 0:
        return Color(0.55, 0.78, 0.72, 1.0)
    if enemy_id.find("hexcaster") >= 0:
        return Color(0.92, 0.62, 0.38, 1.0)
    return Color(0.83, 0.37, 0.37, 1.0)


func _apply_visual_defaults() -> void:
    if _visual != null:
        _visual.color = _base_color
        if _tier == "elite":
            _visual.color = _base_color.lightened(0.12)


func _capture_template_state() -> void:
    _template_enemy_id = enemy_id
    _template_move_speed = move_speed
    _template_touch_damage = touch_damage
    _template_attack_interval = attack_interval
    _template_scale = scale
    if _health_component != null and _health_component.get("max_hp") != null:
        _template_max_hp = float(_health_component.max_hp)


func _reset_for_spawn() -> void:
    enemy_id = _template_enemy_id
    _player = null
    velocity = Vector2.ZERO
    move_speed = _template_move_speed
    touch_damage = _template_touch_damage
    attack_interval = _template_attack_interval

    _touch_cooldown = 0.0
    _knockback_velocity = Vector2.ZERO
    _dash_velocity = Vector2.ZERO
    _dash_time = 0.0
    _dash_cooldown_timer = 0.0
    _pulse_cooldown_timer = 0.0
    _frost_shard_cooldown_timer = 0.0
    _void_grasp_cooldown_timer = 0.0
    _ranged_cooldown = 0.0

    _tier = "normal"
    _archetype = "normal"
    _is_ranged = false
    _preferred_range = 170.0
    _ranged_attack_range = 255.0
    _ranged_attack_interval = 1.2
    _ranged_damage_mult = 0.82

    _is_boss = false
    _phase_index = 0
    _phase_speed_mult = 1.0
    _phase_damage_mult = 1.0
    _phase_thresholds = [1.0, 0.6, 0.3]

    _base_attack_interval = attack_interval
    _base_scale = _template_scale
    scale = _base_scale
    _base_color = _resolve_default_color()
    _apply_visual_defaults()

    if _health_component != null and _health_component.get("max_hp") != null:
        _health_component.max_hp = _template_max_hp
        _health_component.current_hp = _template_max_hp


func _reset_for_pool() -> void:
    velocity = Vector2.ZERO
    _touch_cooldown = 0.0
    _knockback_velocity = Vector2.ZERO
    _dash_velocity = Vector2.ZERO
    _dash_time = 0.0
    _ranged_cooldown = 0.0


func _set_pool_active(active: bool) -> void:
    _pool_active = active
    if active:
        if not is_in_group("enemy"):
            add_to_group("enemy")
    else:
        if is_in_group("enemy"):
            remove_from_group("enemy")
