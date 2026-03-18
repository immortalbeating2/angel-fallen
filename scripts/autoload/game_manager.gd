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
    "camp_forge_damage": [KEY_F],
    "camp_forge_speed": [KEY_G],
    "camp_route_holy": [KEY_Q],
    "camp_route_void": [KEY_V],
    "narrative_choice_1": [KEY_1, KEY_KP_1],
    "narrative_choice_2": [KEY_2, KEY_KP_2]
}

var current_state: GameState = GameState.MENU


func _ready() -> void:
    _setup_default_input_map()
    ConfigManager.reload_all_configs()


func set_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    current_state = new_state
    EventBus.game_state_changed.emit(current_state)


func _setup_default_input_map() -> void:
    for action_name: String in DEFAULT_ACTIONS.keys():
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
        for keycode: int in DEFAULT_ACTIONS[action_name]:
            _add_key_if_missing(action_name, keycode)


func _add_key_if_missing(action_name: String, keycode: int) -> void:
    for existing: InputEvent in InputMap.action_get_events(action_name):
        if existing is InputEventKey:
            var key_event: InputEventKey = existing
            if key_event.physical_keycode == keycode:
                return

    var event: InputEventKey = InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)
