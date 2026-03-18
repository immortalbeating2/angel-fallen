extends Node

@export var input_enabled: bool = true

var _body: CharacterBody2D
var _stats: Node
var _external_velocity: Vector2 = Vector2.ZERO
var _environment_speed_multiplier: float = 1.0


func _ready() -> void:
    _body = owner as CharacterBody2D
    if _body != null:
        _stats = _body.get_node_or_null("StatsComponent")


func physics_process_move(delta: float) -> void:
    if _body == null:
        return

    var input_vector: Vector2 = Vector2.ZERO
    if input_enabled:
        input_vector = Vector2(
            Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
            Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
        ).normalized()

    var speed: float = 180.0
    var is_sprinting: bool = false
    if _stats != null and _stats.has_method("tick_stamina"):
        var wants_sprint: bool = Input.is_action_pressed("sprint") and input_vector != Vector2.ZERO
        is_sprinting = _stats.tick_stamina(delta, wants_sprint)

        if _stats.get("base_move_speed") != null:
            speed = _stats.base_move_speed
        if is_sprinting and _stats.get("sprint_multiplier") != null:
            speed *= _stats.sprint_multiplier

    speed *= _environment_speed_multiplier

    _body.velocity = input_vector * speed + _external_velocity
    _external_velocity = _external_velocity.move_toward(Vector2.ZERO, 980.0 * delta)
    _body.move_and_slide()


func add_external_velocity(force: Vector2) -> void:
    _external_velocity += force


func set_environment_speed_multiplier(multiplier: float) -> void:
    _environment_speed_multiplier = clampf(multiplier, 0.35, 1.5)
