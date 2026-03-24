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
@onready var _chapter_effects_value: Label = $MarginContainer/PanelContainer/VBoxContainer/ChapterEffectsValue
@onready var _route_style_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RouteStyleValue
@onready var _minimap_value: Label = $MarginContainer/PanelContainer/VBoxContainer/MinimapValue
@onready var _state_value: Label = $MarginContainer/PanelContainer/VBoxContainer/StateValue
@onready var _room_kill_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RoomKillValue
@onready var _room_status_value: Label = $MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue
@onready var _toast_panel: PanelContainer = $ToastLayer/ToastPanel
@onready var _toast_label: Label = $ToastLayer/ToastPanel/MarginContainer/ToastLabel

var _player: CharacterBody2D
var _health_component: Node
var _stats_component: Node
var _progression_component: Node
var _game_world: Node
var _toast_queue: Array[Dictionary] = []
var _toast_timer: float = 0.0

const TOAST_DURATION: float = 2.6


func _ready() -> void:
    if EventBus != null:
        if EventBus.has_signal("achievement_unlocked"):
            EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
        if EventBus.has_signal("ending_unlocked"):
            EventBus.ending_unlocked.connect(_on_ending_unlocked)
        if EventBus.has_signal("memory_fragment_found"):
            EventBus.memory_fragment_found.connect(_on_memory_fragment_found)
        if EventBus.has_signal("accessory_acquired"):
            EventBus.accessory_acquired.connect(_on_accessory_acquired)
        if EventBus.has_signal("codex_unlocked"):
            EventBus.codex_unlocked.connect(_on_codex_unlocked)
        if EventBus.has_signal("difficulty_unlocked"):
            EventBus.difficulty_unlocked.connect(_on_difficulty_unlocked)
        if EventBus.has_signal("meta_return_unlocked"):
            EventBus.meta_return_unlocked.connect(_on_meta_return_unlocked)

    if _toast_panel != null:
        _toast_panel.visible = false


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
    if _game_world != null and _game_world.has_method("get_chapter_effects_hud_text"):
        _chapter_effects_value.text = _game_world.get_chapter_effects_hud_text()
    if _game_world != null and _game_world.has_method("get_route_style_hud_text"):
        _route_style_value.text = _game_world.get_route_style_hud_text()
    if _game_world != null and _game_world.has_method("get_minimap_text"):
        _minimap_value.text = _game_world.get_minimap_text()

    _state_value.text = _get_state_name(GameManager.current_state)
    _process_toast(_delta)


func _process_toast(delta: float) -> void:
    if _toast_panel == null or _toast_label == null:
        return

    if _toast_timer > 0.0:
        _toast_timer = maxf(0.0, _toast_timer - delta)
        if _toast_timer <= 0.0:
            _toast_panel.visible = false

    if _toast_timer <= 0.0 and not _toast_queue.is_empty():
        var row: Dictionary = _toast_queue.pop_front()
        _toast_label.text = str(row.get("text", "Notice"))
        _toast_label.modulate = row.get("color", Color(1, 1, 1, 1))
        _toast_panel.visible = true
        _toast_timer = TOAST_DURATION


func _enqueue_toast(text: String, color: Color) -> void:
    _toast_queue.append({
        "text": text,
        "color": color
    })


func _on_achievement_unlocked(_achievement_id: String, title: String) -> void:
    _enqueue_toast("Achievement Unlocked: %s" % title, Color(1.0, 0.87, 0.25, 1.0))


func _on_ending_unlocked(ending_id: String) -> void:
    _enqueue_toast("Ending Unlocked: %s" % _get_ending_title(ending_id), Color(0.8, 0.92, 1.0, 1.0))


func _on_memory_fragment_found(fragment_id: String) -> void:
    var title: String = _get_fragment_title(fragment_id)
    _enqueue_toast("Memory Fragment: %s" % title, Color(0.84, 1.0, 0.84, 1.0))


func _on_accessory_acquired(accessory_id: String) -> void:
    _enqueue_toast("Accessory Acquired: %s" % _get_accessory_title(accessory_id), Color(1.0, 0.84, 0.76, 1.0))


func _on_codex_unlocked(category: String, entry_id: String) -> void:
    var category_name: String = _get_codex_category_name(category)
    var entry_name: String = _get_codex_entry_title(category, entry_id)
    _enqueue_toast("Codex Updated: [%s] %s" % [category_name, entry_name], Color(0.86, 0.84, 1.0, 1.0))


func _on_difficulty_unlocked(_tier: int, label: String) -> void:
    _enqueue_toast("Difficulty Unlocked: %s" % label, Color(1.0, 0.78, 0.38, 1.0))


func _on_meta_return_unlocked(_milestone_id: String, label: String, bonus_text: String) -> void:
    var text: String = "Meta Return Unlocked: %s" % label
    if bonus_text.strip_edges() != "":
        text += " (%s)" % bonus_text
    _enqueue_toast(text, Color(0.72, 1.0, 0.84, 1.0))


func _get_fragment_title(fragment_id: String) -> String:
    var content: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = content.get("memory_fragments", {})
    if rows_var is Dictionary:
        var row_var: Variant = (rows_var as Dictionary).get(fragment_id, {})
        if row_var is Dictionary:
            return str((row_var as Dictionary).get("title", fragment_id))
    return fragment_id


func _get_ending_title(ending_id: String) -> String:
    var content: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = content.get("endings", {})
    if rows_var is Dictionary:
        var row_var: Variant = (rows_var as Dictionary).get(ending_id, {})
        if row_var is Dictionary:
            return str((row_var as Dictionary).get("title", ending_id))
    return ending_id


func _get_accessory_title(accessory_id: String) -> String:
    match accessory_id:
        "acc_heart_of_mine":
            return "Heart of Mine"
        "acc_flame_core":
            return "Flame Core"
        "acc_zero_mark":
            return "Zero Mark"
        "acc_void_eye":
            return "Void Eye"
        _:
            return accessory_id


func _get_codex_category_name(category: String) -> String:
    match category.strip_edges().to_lower():
        "archives":
            return "Archives"
        _:
            return category.capitalize()


func _get_codex_entry_title(category: String, entry_id: String) -> String:
    match category.strip_edges().to_lower():
        "archives":
            return _get_archive_codex_title(entry_id)
        "accessories":
            return _get_accessory_title(entry_id)
        "enemies":
            return _get_boss_echo_title(entry_id)
        _:
            return _prettify_id(entry_id)


func _get_archive_codex_title(entry_id: String) -> String:
    match entry_id.strip_edges():
        "fs1_echo_archive":
            return "Time Rift Archive"
        "fs1_echo_mastery":
            return "Time Rift Mastery"
        "fs2_trial_archive":
            return "Genesis Forge Archive"
        "fs2_trial_mastery":
            return "Genesis Forge Mastery"
        "hard_clear_archive":
            return "Hard Archive"
        "nightmare_clear_archive":
            return "Nightmare Archive"
        "nightmare_hidden_archive":
            return "Nightmare Hidden Archive"
        _:
            return _prettify_id(entry_id)


func _get_boss_echo_title(boss_id: String) -> String:
    match boss_id.strip_edges():
        "boss_rock_colossus":
            return "Rock Colossus"
        "boss_flame_lord":
            return "Flame Lord"
        "boss_frost_king":
            return "Frost King"
        "boss_void_lord":
            return "Void Lord"
        _:
            return _prettify_id(boss_id)


func _prettify_id(raw_id: String) -> String:
    var text: String = raw_id
    if text.begins_with("char_") or text.begins_with("wpn_") or text.begins_with("acc_") or text.begins_with("enemy_"):
        var parts: PackedStringArray = text.split("_", false, 1)
        if parts.size() == 2:
            text = parts[1]
    return text.replace("_", " ").capitalize()


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
