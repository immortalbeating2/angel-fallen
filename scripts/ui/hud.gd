extends CanvasLayer

@onready var _health_value: Label = $MarginContainer/PanelContainer/VBoxContainer/HealthValue
@onready var _stamina_value: Label = $MarginContainer/PanelContainer/VBoxContainer/StaminaValue
@onready var _level_value: Label = $MarginContainer/PanelContainer/VBoxContainer/LevelValue
@onready var _xp_value: Label = $MarginContainer/PanelContainer/VBoxContainer/XPValue
@onready var _gold_value: Label = $MarginContainer/PanelContainer/VBoxContainer/GoldValue
@onready var _ore_value: Label = $MarginContainer/PanelContainer/VBoxContainer/OreValue
@onready var _accessory_value: Label = $MarginContainer/PanelContainer/VBoxContainer/AccessoryValue
@onready var _room_type_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RoomTypeValue
@onready var _alignment_value: Label = $MarginContainer/PanelContainer/VBoxContainer/AlignmentValue
@onready var _hazard_value: Label = $MarginContainer/PanelContainer/VBoxContainer/HazardValue
@onready var _frostbite_value: Label = $MarginContainer/PanelContainer/VBoxContainer/FrostbiteValue
@onready var _void_value: Label = $MarginContainer/PanelContainer/VBoxContainer/VoidCorruptionValue
@onready var _state_value: Label = $MarginContainer/PanelContainer/VBoxContainer/StateValue
@onready var _room_kill_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RoomKillValue
@onready var _room_status_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue

var _player: CharacterBody2D
var _health_component: Node
var _stats_component: Node
var _progression_component: Node
var _game_world: Node


func _process(_delta: float) -> void:
    if _player == null:
        _player = get_tree().get_first_node_in_group("player") as CharacterBody2D
        if _player != null:
            _health_component = _player.get_node_or_null("HealthComponent")
            _stats_component = _player.get_node_or_null("StatsComponent")
            _progression_component = _player.get_node_or_null("ProgressionComponent")

    if _game_world == null:
        _game_world = get_tree().get_first_node_in_group("game_world")

    if _health_component != null:
        _health_value.text = "%.0f / %.0f" % [_health_component.current_hp, _health_component.max_hp]

    if _stats_component != null:
        _stamina_value.text = "%.0f / %.0f" % [_stats_component.current_stamina, _stats_component.stamina_max]

    if _progression_component != null:
        _level_value.text = str(_progression_component.current_level)
        _xp_value.text = "%d / %d" % [_progression_component.current_xp, _progression_component.xp_to_next]

    if _game_world != null and _game_world.has_method("get_room_progress_text"):
        _room_kill_value.text = _game_world.get_room_progress_text()
    if _game_world != null and _game_world.has_method("get_room_status_text"):
        _room_status_value.text = _game_world.get_room_status_text()
    if _game_world != null and _game_world.has_method("get_gold_amount"):
        _gold_value.text = str(_game_world.get_gold_amount())
    if _game_world != null and _game_world.has_method("get_ore_amount"):
        _ore_value.text = str(_game_world.get_ore_amount())
    if _game_world != null and _game_world.has_method("get_accessories_text"):
        _accessory_value.text = _game_world.get_accessories_text()
    if _game_world != null and _game_world.has_method("get_room_type_text"):
        _room_type_value.text = str(_game_world.get_room_type_text()).to_upper()
    if _game_world != null and _game_world.has_method("get_alignment_value"):
        _alignment_value.text = "%.0f" % _game_world.get_alignment_value()
    if _game_world != null and _game_world.has_method("get_active_hazards_text"):
        _hazard_value.text = _game_world.get_active_hazards_text()
    if _game_world != null and _game_world.has_method("get_frostbite_value"):
        _frostbite_value.text = "%.0f%%" % _game_world.get_frostbite_value()
    if _game_world != null and _game_world.has_method("get_void_corruption_value"):
        _void_value.text = "%.0f%%" % _game_world.get_void_corruption_value()

    _state_value.text = _get_state_name(GameManager.current_state)


func _get_state_name(state_value: int) -> String:
    match state_value:
        GameManager.GameState.MENU:
            return "MENU"
        GameManager.GameState.PLAYING:
            return "PLAYING"
        GameManager.GameState.PAUSED:
            return "PAUSED"
        GameManager.GameState.GAME_OVER:
            return "GAME_OVER"
        _:
            return "UNKNOWN"
