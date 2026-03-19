extends Node

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    GAME_OVER
}

const DEFAULT_ACTIONS: Dictionary = {
    "move_up": [KEY_W, KEY_UP],
    "move_down": [KEY_S, KEY_DOWN],
    "move_left": [KEY_A, KEY_LEFT],
    "move_right": [KEY_D, KEY_RIGHT],
    "sprint": [KEY_SHIFT],
    "interact": [KEY_E],
    "pause": [KEY_ESCAPE],
    "shop_buy_1": [KEY_1, KEY_KP_1],
    "shop_buy_2": [KEY_2, KEY_KP_2],
    "shop_buy_3": [KEY_3, KEY_KP_3],
    "shop_buy_4": [KEY_4, KEY_KP_4],
    "shop_restock": [KEY_R],
    "shop_exchange_ore": [KEY_T],
    "camp_forge_damage": [KEY_F],
    "camp_forge_speed": [KEY_G],
    "camp_memory_altar": [KEY_T],
    "camp_route_holy": [KEY_Q],
    "camp_route_void": [KEY_V],
    "narrative_choice_1": [KEY_1, KEY_KP_1],
    "narrative_choice_2": [KEY_2, KEY_KP_2]
}

const DEFAULT_JOYPAD_ACTIONS: Dictionary = {
    "move_up": [JOY_BUTTON_DPAD_UP],
    "move_down": [JOY_BUTTON_DPAD_DOWN],
    "move_left": [JOY_BUTTON_DPAD_LEFT],
    "move_right": [JOY_BUTTON_DPAD_RIGHT],
    "sprint": [JOY_BUTTON_RIGHT_SHOULDER],
    "interact": [JOY_BUTTON_A],
    "pause": [JOY_BUTTON_START],
    "shop_buy_1": [JOY_BUTTON_DPAD_UP],
    "shop_buy_2": [JOY_BUTTON_DPAD_RIGHT],
    "shop_buy_3": [JOY_BUTTON_DPAD_DOWN],
    "shop_buy_4": [JOY_BUTTON_DPAD_LEFT],
    "shop_restock": [JOY_BUTTON_Y],
    "shop_exchange_ore": [JOY_BUTTON_B],
    "camp_forge_damage": [JOY_BUTTON_X],
    "camp_forge_speed": [JOY_BUTTON_Y],
    "camp_memory_altar": [JOY_BUTTON_LEFT_STICK],
    "camp_route_holy": [JOY_BUTTON_RIGHT_SHOULDER],
    "camp_route_void": [JOY_BUTTON_LEFT_SHOULDER],
    "narrative_choice_1": [JOY_BUTTON_X],
    "narrative_choice_2": [JOY_BUTTON_Y]
}

var current_state: GameState = GameState.MENU
var selected_character_id: String = "char_knight"
var current_room_index: int = 0
var current_room_type: String = ""
var current_chapter_id: String = "global"


func _ready() -> void:
    _setup_default_input_map()
    ConfigManager.reload_all_configs()
    reset_run_context()


func set_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    current_state = new_state
    if current_state == GameState.MENU:
        reset_run_context()
    EventBus.game_state_changed.emit(current_state)


func set_run_context(room_index: int, room_type: String, chapter_id: String) -> void:
    current_room_index = max(0, room_index)
    current_room_type = room_type.strip_edges().to_lower()
    var normalized_chapter: String = chapter_id.strip_edges().to_lower()
    if normalized_chapter == "":
        normalized_chapter = "global"
    current_chapter_id = normalized_chapter


func reset_run_context() -> void:
    current_room_index = 0
    current_room_type = ""
    current_chapter_id = "global"


func _setup_default_input_map() -> void:
    apply_input_bindings(get_default_input_bindings())


func get_default_input_bindings() -> Dictionary:
    var out: Dictionary = {}
    for action_name: String in DEFAULT_ACTIONS.keys():
        var key_codes: Array[int] = _sanitize_int_array(DEFAULT_ACTIONS[action_name], 4)
        var joypad_buttons: Array[int] = _sanitize_int_array(DEFAULT_JOYPAD_ACTIONS.get(action_name, []), 4)
        out[action_name] = {
            "keys": key_codes,
            "joypad_buttons": joypad_buttons
        }
    return out


func sanitize_input_bindings(bindings: Dictionary) -> Dictionary:
    var defaults: Dictionary = get_default_input_bindings()
    var source: Dictionary = bindings
    var out: Dictionary = {}

    for action_name: String in DEFAULT_ACTIONS.keys():
        var row: Dictionary = {}
        var row_var: Variant = source.get(action_name, {})
        if row_var is Dictionary:
            row = row_var

        var default_row: Dictionary = defaults.get(action_name, {})
        var keys: Array[int] = _sanitize_int_array(row.get("keys", default_row.get("keys", [])), 4)
        if keys.is_empty():
            keys = _sanitize_int_array(default_row.get("keys", []), 4)

        var joypad_buttons: Array[int] = _sanitize_int_array(row.get("joypad_buttons", default_row.get("joypad_buttons", [])), 4)
        out[action_name] = {
            "keys": keys,
            "joypad_buttons": joypad_buttons
        }

    return out


func apply_input_bindings(bindings: Dictionary) -> Dictionary:
    var sanitized: Dictionary = sanitize_input_bindings(bindings)
    for action_name: String in DEFAULT_ACTIONS.keys():
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
        InputMap.action_erase_events(action_name)

        var row_var: Variant = sanitized.get(action_name, {})
        if not (row_var is Dictionary):
            continue

        var row: Dictionary = row_var
        for keycode: int in _sanitize_int_array(row.get("keys", []), 4):
            _add_key_event(action_name, keycode)
        for button_index: int in _sanitize_int_array(row.get("joypad_buttons", []), 4):
            _add_joypad_button_event(action_name, button_index)

    return get_current_input_bindings()


func get_current_input_bindings() -> Dictionary:
    var defaults: Dictionary = get_default_input_bindings()
    var out: Dictionary = {}

    for action_name: String in DEFAULT_ACTIONS.keys():
        var keys: Array[int] = []
        var joypad_buttons: Array[int] = []

        for existing: InputEvent in InputMap.action_get_events(action_name):
            if existing is InputEventKey:
                var key_event: InputEventKey = existing
                var keycode: int = int(key_event.physical_keycode)
                if keycode > 0 and not keys.has(keycode):
                    keys.append(keycode)
            elif existing is InputEventJoypadButton:
                var joy_event: InputEventJoypadButton = existing
                var button_index: int = int(joy_event.button_index)
                if button_index >= 0 and not joypad_buttons.has(button_index):
                    joypad_buttons.append(button_index)

        if keys.is_empty():
            var default_row: Dictionary = defaults.get(action_name, {})
            keys = _sanitize_int_array(default_row.get("keys", []), 4)

        out[action_name] = {
            "keys": keys,
            "joypad_buttons": joypad_buttons
        }

    return out


func _add_key_event(action_name: String, keycode: int) -> void:
    if keycode <= 0:
        return
    var event: InputEventKey = InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)


func _add_joypad_button_event(action_name: String, button_index: int) -> void:
    if button_index < 0:
        return
    var event: InputEventJoypadButton = InputEventJoypadButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action_name, event)


func _sanitize_int_array(value: Variant, max_items: int) -> Array[int]:
    var out: Array[int] = []
    if value is Array:
        var source: Array = value
        for item: Variant in source:
            var parsed: int = int(item)
            if parsed <= 0 and parsed != 0:
                continue
            if not out.has(parsed):
                out.append(parsed)
            if out.size() >= max_items:
                break
    return out
