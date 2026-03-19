extends CharacterBody2D

@onready var _movement_component: Node = $MovementComponent
@onready var _health_component: Node = $HealthComponent
@onready var _progression_component: Node = $ProgressionComponent
@onready var _camera: Camera2D = $Camera2D

var _shake_strength: float = 1.0
var _shake_trauma: float = 0.0


func _ready() -> void:
    add_to_group("player")
    _apply_settings()
    if EventBus != null and EventBus.has_signal("settings_changed") and not EventBus.settings_changed.is_connected(_on_settings_changed):
        EventBus.settings_changed.connect(_on_settings_changed)


func _physics_process(delta: float) -> void:
    if _movement_component != null and _movement_component.has_method("physics_process_move"):
        _movement_component.physics_process_move(delta)


func _process(delta: float) -> void:
    _update_camera_shake(delta)


func apply_damage(amount: float) -> void:
    if _health_component != null and _health_component.has_method("take_damage"):
        _health_component.take_damage(amount)
    _add_camera_trauma(0.28)


func gain_xp(amount: int) -> void:
    if _progression_component != null and _progression_component.has_method("add_xp"):
        _progression_component.add_xp(amount)


func apply_knockback(force: Vector2) -> void:
    if _movement_component != null and _movement_component.has_method("add_external_velocity"):
        _movement_component.add_external_velocity(force)
    _add_camera_trauma(clampf(force.length() / 220.0, 0.05, 0.18))


func _add_camera_trauma(amount: float) -> void:
    if _shake_strength <= 0.01:
        return
    _shake_trauma = clampf(_shake_trauma + amount * _shake_strength, 0.0, 1.0)


func _update_camera_shake(delta: float) -> void:
    if _camera == null:
        return

    if _shake_trauma <= 0.001 or _shake_strength <= 0.01:
        _shake_trauma = 0.0
        _camera.offset = _camera.offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))
        return

    _shake_trauma = maxf(0.0, _shake_trauma - delta * 1.7)
    var amp: float = _shake_trauma * _shake_trauma * 15.0 * _shake_strength
    _camera.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))


func _on_settings_changed(settings: Dictionary) -> void:
    _apply_settings(settings)


func _apply_settings(settings: Dictionary = {}) -> void:
    var source: Dictionary = settings
    if source.is_empty() and SaveManager != null and SaveManager.has_method("get_runtime_settings"):
        source = SaveManager.get_runtime_settings()
    _shake_strength = clampf(float(source.get("screen_shake", 1.0)), 0.0, 1.0)
