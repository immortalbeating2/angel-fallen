extends VBoxContainer

signal settings_updated(settings: Dictionary)
signal defaults_restored

@export var show_title: bool = true

@onready var _title: Label = $Title
@onready var _master_row: HBoxContainer = $MasterRow
@onready var _master_value: Label = $MasterRow/Value
@onready var _master_slider: HSlider = $MasterRow/Slider
@onready var _bgm_row: HBoxContainer = $BGMRow
@onready var _bgm_value: Label = $BGMRow/Value
@onready var _bgm_slider: HSlider = $BGMRow/Slider
@onready var _sfx_row: HBoxContainer = $SFXRow
@onready var _sfx_value: Label = $SFXRow/Value
@onready var _sfx_slider: HSlider = $SFXRow/Slider
@onready var _ambience_row: HBoxContainer = $AmbienceRow
@onready var _ambience_value: Label = $AmbienceRow/Value
@onready var _ambience_slider: HSlider = $AmbienceRow/Slider
@onready var _shake_row: HBoxContainer = $ShakeRow
@onready var _shake_value: Label = $ShakeRow/Value
@onready var _shake_slider: HSlider = $ShakeRow/Slider
@onready var _ui_scale_row: HBoxContainer = $UIScaleRow
@onready var _ui_scale_value: Label = $UIScaleRow/Value
@onready var _ui_scale_slider: HSlider = $UIScaleRow/Slider
@onready var _difficulty_row: HBoxContainer = $DifficultyRow
@onready var _difficulty_value: Label = $DifficultyRow/Value
@onready var _difficulty_slider: HSlider = $DifficultyRow/Slider
@onready var _difficulty_hint: Label = $DifficultyHint

@onready var _bus_meter_section: VBoxContainer = $BusMeterTitle
@onready var _master_meter: ProgressBar = $BusMeterTitle/MasterMeter
@onready var _bgm_meter: ProgressBar = $BusMeterTitle/BGMMeter
@onready var _sfx_meter: ProgressBar = $BusMeterTitle/SFXMeter
@onready var _ambience_meter: ProgressBar = $BusMeterTitle/AmbienceMeter
@onready var _input_bindings_section: VBoxContainer = $InputBindingsSection
@onready var _binding_hint: Label = $InputBindingsSection/Hint
@onready var _bindings_list: VBoxContainer = $InputBindingsSection/BindingsScroll/BindingsList
@onready var _actions_row: HBoxContainer = $Actions
@onready var _test_sfx_button: Button = $Actions/TestSFXButton
@onready var _reset_defaults_button: Button = $Actions/ResetDefaultsButton

const DIRTY_COLOR: Color = Color(1.0, 0.84, 0.34, 1.0)
const NORMAL_COLOR: Color = Color(0.92, 0.92, 0.92, 1.0)
const METER_REFRESH: float = 0.06
const SETTINGS_PAGE_IDS: Array[String] = ["display", "audio", "controls", "accessibility"]
const SETTINGS_PAGE_LABELS: Dictionary = {
    "display": "Display",
    "audio": "Audio",
    "controls": "Controls",
    "accessibility": "Accessibility"
}
const DISPLAY_MODE_OPTIONS: Array[Dictionary] = [
    {"id": "windowed", "label": "Windowed"},
    {"id": "borderless", "label": "Borderless"},
    {"id": "fullscreen", "label": "Fullscreen"}
]
const RESOLUTION_OPTIONS: Array[String] = ["1280x720", "1600x900", "1920x1080", "2560x1440", "3840x2160"]

const INPUT_ACTION_ROWS: Array[Dictionary] = [
    {"id": "move_up", "label": "Move Up"},
    {"id": "move_down", "label": "Move Down"},
    {"id": "move_left", "label": "Move Left"},
    {"id": "move_right", "label": "Move Right"},
    {"id": "sprint", "label": "Sprint"},
    {"id": "interact", "label": "Interact"},
    {"id": "pause", "label": "Pause"},
    {"id": "shop_restock", "label": "Shop Restock"},
    {"id": "camp_forge_damage", "label": "Forge Damage"},
    {"id": "camp_forge_speed", "label": "Forge Speed"},
    {"id": "camp_memory_altar", "label": "Memory Altar"},
    {"id": "camp_hidden_fs1", "label": "Enter FS1"},
    {"id": "camp_hidden_fs2", "label": "Enter FS2"},
    {"id": "camp_challenge_layer", "label": "Enter Challenge"},
    {"id": "camp_route_holy", "label": "Route Holy"},
    {"id": "camp_route_void", "label": "Route Void"},
    {"id": "narrative_choice_1", "label": "Choice 1"},
    {"id": "narrative_choice_2", "label": "Choice 2"}
]

const JOYPAD_BUTTON_LABELS: Dictionary = {
    JOY_BUTTON_A: "A",
    JOY_BUTTON_B: "B",
    JOY_BUTTON_X: "X",
    JOY_BUTTON_Y: "Y",
    JOY_BUTTON_START: "Start",
    JOY_BUTTON_LEFT_SHOULDER: "LB",
    JOY_BUTTON_RIGHT_SHOULDER: "RB",
    JOY_BUTTON_DPAD_UP: "DPad Up",
    JOY_BUTTON_DPAD_DOWN: "DPad Down",
    JOY_BUTTON_DPAD_LEFT: "DPad Left",
    JOY_BUTTON_DPAD_RIGHT: "DPad Right",
    JOY_BUTTON_LEFT_STICK: "LStick",
    JOY_BUTTON_RIGHT_STICK: "RStick"
}

var _syncing: bool = false
var _meter_timer: float = 0.0
var _default_settings: Dictionary = {}
var _input_bindings: Dictionary = {}
var _binding_row_nodes: Dictionary = {}
var _capture_action_id: String = ""
var _capture_target: String = ""
var _page_buttons: Dictionary = {}
var _page_nodes: Dictionary = {}
var _active_page: String = "display"
var _display_mode_option: OptionButton = null
var _resolution_option: OptionButton = null


func _ready() -> void:
    if _title != null:
        _title.visible = show_title
        _title.text = "Settings"
    _build_settings_pages()
    _build_binding_rows()
    _default_settings = _get_default_settings()
    sync_from_save()


func _build_settings_pages() -> void:
    if get_node_or_null("PageTabs") != null:
        return

    custom_minimum_size = Vector2(680, 0)
    add_theme_constant_override("separation", 10)

    var tabs: HBoxContainer = HBoxContainer.new()
    tabs.name = "PageTabs"
    tabs.alignment = BoxContainer.ALIGNMENT_CENTER
    tabs.add_theme_constant_override("separation", 8)
    add_child(tabs)
    move_child(tabs, 1 if show_title else 0)

    var stack: VBoxContainer = VBoxContainer.new()
    stack.name = "PageStack"
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 8)
    add_child(stack)
    move_child(stack, tabs.get_index() + 1)

    for page_id: String in SETTINGS_PAGE_IDS:
        var button: Button = Button.new()
        button.text = str(SETTINGS_PAGE_LABELS.get(page_id, page_id.capitalize()))
        button.toggle_mode = true
        button.custom_minimum_size = Vector2(130, 38)
        button.pressed.connect(_on_page_tab_pressed.bind(page_id))
        tabs.add_child(button)
        _page_buttons[page_id] = button

        var page: VBoxContainer = VBoxContainer.new()
        page.name = "%sPage" % page_id.capitalize()
        page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        page.add_theme_constant_override("separation", 8)
        stack.add_child(page)
        _page_nodes[page_id] = page

    _build_display_page()
    _move_control_to_page(_master_row, "audio")
    _move_control_to_page(_bgm_row, "audio")
    _move_control_to_page(_sfx_row, "audio")
    _move_control_to_page(_ambience_row, "audio")
    _move_control_to_page(_bus_meter_section, "audio")
    _move_control_to_page(_test_sfx_button, "audio")
    _move_control_to_page(_shake_row, "accessibility")
    if _difficulty_row != null:
        _difficulty_row.visible = false
    if _difficulty_hint != null:
        _difficulty_hint.visible = false
    _move_control_to_page(_input_bindings_section, "controls")
    if _actions_row != null:
        move_child(_actions_row, get_child_count() - 1)
    if _reset_defaults_button != null:
        _reset_defaults_button.custom_minimum_size = Vector2(180, 38)
    _set_active_page(_active_page)


func _build_display_page() -> void:
    var display_page: VBoxContainer = _page_nodes.get("display", null)
    if display_page == null:
        return

    var mode_row: HBoxContainer = _make_option_row("Display Mode")
    _display_mode_option = mode_row.get_node("Option") as OptionButton
    for option: Dictionary in DISPLAY_MODE_OPTIONS:
        _display_mode_option.add_item(str(option.get("label", "")))
        _display_mode_option.set_item_metadata(_display_mode_option.item_count - 1, str(option.get("id", "windowed")))
    _display_mode_option.item_selected.connect(_on_display_mode_selected)
    display_page.add_child(mode_row)

    var resolution_row: HBoxContainer = _make_option_row("Resolution")
    _resolution_option = resolution_row.get_node("Option") as OptionButton
    for resolution: String in RESOLUTION_OPTIONS:
        _resolution_option.add_item(resolution)
        _resolution_option.set_item_metadata(_resolution_option.item_count - 1, resolution)
    _resolution_option.item_selected.connect(_on_resolution_selected)
    display_page.add_child(resolution_row)

    _move_control_to_page(_ui_scale_row, "display")


func _make_option_row(label_text: String) -> HBoxContainer:
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var name_label: Label = Label.new()
    name_label.custom_minimum_size = Vector2(132, 0)
    name_label.text = label_text
    row.add_child(name_label)

    var option: OptionButton = OptionButton.new()
    option.name = "Option"
    option.custom_minimum_size = Vector2(248, 36)
    option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(option)
    return row


func _move_control_to_page(control: Control, page_id: String) -> void:
    if control == null:
        return
    var page: VBoxContainer = _page_nodes.get(page_id, null)
    if page == null:
        return
    var parent: Node = control.get_parent()
    if parent != null:
        parent.remove_child(control)
    page.add_child(control)


func _on_page_tab_pressed(page_id: String) -> void:
    _set_active_page(page_id)


func _set_active_page(page_id: String) -> void:
    if not _page_nodes.has(page_id):
        page_id = "display"
    _active_page = page_id
    for key: String in SETTINGS_PAGE_IDS:
        var page: Control = _page_nodes.get(key, null)
        if page != null:
            page.visible = key == page_id
        var button: Button = _page_buttons.get(key, null)
        if button != null:
            button.button_pressed = key == page_id
            button.disabled = key == page_id


func _process(delta: float) -> void:
    _meter_timer -= delta
    if _meter_timer > 0.0:
        return
    _meter_timer = METER_REFRESH
    _refresh_bus_meters()


func _unhandled_input(event: InputEvent) -> void:
    if _capture_action_id == "" or _capture_target == "":
        return
    if not visible:
        return

    if event is InputEventKey:
        var key_event: InputEventKey = event
        if not key_event.pressed or key_event.echo:
            return

        if key_event.physical_keycode == KEY_ESCAPE:
            _clear_binding_capture("Rebind canceled")
            get_viewport().set_input_as_handled()
            return

        if _capture_target == "keyboard":
            _assign_binding(_capture_action_id, "keyboard", int(key_event.physical_keycode))
            _clear_binding_capture("Keyboard binding updated")
            get_viewport().set_input_as_handled()
        return

    if event is InputEventJoypadButton and _capture_target == "joypad":
        var joy_event: InputEventJoypadButton = event
        if not joy_event.pressed:
            return
        _assign_binding(_capture_action_id, "joypad", int(joy_event.button_index))
        _clear_binding_capture("Gamepad binding updated")
        get_viewport().set_input_as_handled()


func is_capturing_input() -> bool:
    return _capture_action_id != "" and _capture_target != ""


func sync_from_save() -> void:
    var settings: Dictionary = _default_settings.duplicate(true)
    if SaveManager != null and SaveManager.has_method("get_runtime_settings"):
        settings = SaveManager.get_runtime_settings()
    _apply_settings_to_ui(settings)

    var bindings: Dictionary = _get_default_bindings()
    if SaveManager != null and SaveManager.has_method("get_input_bindings"):
        bindings = SaveManager.get_input_bindings()
    _apply_bindings_to_ui(bindings)


func reset_to_default() -> void:
    if SaveManager != null and SaveManager.has_method("update_runtime_settings"):
        SaveManager.update_runtime_settings(_default_settings)
    sync_from_save()
    defaults_restored.emit()


func _apply_settings_to_ui(settings: Dictionary) -> void:
    _syncing = true
    var max_unlocked_tier: int = 2
    if SaveManager != null and SaveManager.has_method("get_max_unlocked_difficulty_tier"):
        max_unlocked_tier = int(SaveManager.get_max_unlocked_difficulty_tier())
    _difficulty_slider.max_value = max_unlocked_tier
    _master_slider.value = float(settings.get("master_volume", 1.0))
    _bgm_slider.value = float(settings.get("bgm_volume", 1.0))
    _sfx_slider.value = float(settings.get("sfx_volume", 1.0))
    _ambience_slider.value = float(settings.get("ambience_volume", 1.0))
    _shake_slider.value = float(settings.get("screen_shake", 1.0))
    _ui_scale_slider.value = float(settings.get("ui_scale", 1.0))
    _difficulty_slider.value = clampi(int(settings.get("difficulty_tier", 0)), 0, max_unlocked_tier)
    _select_option_by_metadata(_display_mode_option, str(settings.get("display_mode", "windowed")))
    _select_option_by_metadata(_resolution_option, str(settings.get("resolution", "1280x720")))
    _syncing = false
    _refresh_value_labels()


func _refresh_value_labels() -> void:
    _set_value_label(_master_value, "%d%%" % int(round(_master_slider.value * 100.0)), _is_dirty("master_volume", _master_slider.value))
    _set_value_label(_bgm_value, "%d%%" % int(round(_bgm_slider.value * 100.0)), _is_dirty("bgm_volume", _bgm_slider.value))
    _set_value_label(_sfx_value, "%d%%" % int(round(_sfx_slider.value * 100.0)), _is_dirty("sfx_volume", _sfx_slider.value))
    _set_value_label(_ambience_value, "%d%%" % int(round(_ambience_slider.value * 100.0)), _is_dirty("ambience_volume", _ambience_slider.value))
    _set_value_label(_shake_value, "%d%%" % int(round(_shake_slider.value * 100.0)), _is_dirty("screen_shake", _shake_slider.value))
    _set_value_label(_ui_scale_value, "%.2fx" % _ui_scale_slider.value, _is_dirty("ui_scale", _ui_scale_slider.value))
    _set_value_label(_difficulty_value, _get_difficulty_label(int(round(_difficulty_slider.value))), _is_dirty("difficulty_tier", _difficulty_slider.value))
    if _difficulty_hint != null:
        _difficulty_hint.text = _get_difficulty_hint_text()


func _select_option_by_metadata(option: OptionButton, metadata_value: String) -> void:
    if option == null:
        return
    for i: int in range(option.item_count):
        if str(option.get_item_metadata(i)) == metadata_value:
            option.select(i)
            return
    if option.item_count > 0:
        option.select(0)


func _set_value_label(label: Label, text_value: String, dirty: bool) -> void:
    if label == null:
        return
    label.text = text_value
    label.modulate = DIRTY_COLOR if dirty else NORMAL_COLOR


func _build_binding_rows() -> void:
    if _bindings_list == null:
        return

    for child: Node in _bindings_list.get_children():
        child.queue_free()

    _binding_row_nodes.clear()
    # 动态重建按键绑定行，避免场景里手写重复控件并统一刷新逻辑。
    for row_data: Dictionary in INPUT_ACTION_ROWS:
        var action_id: String = str(row_data.get("id", "")).strip_edges()
        var label_text: String = str(row_data.get("label", action_id))
        if action_id == "":
            continue

        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)

        var name_label: Label = Label.new()
        name_label.custom_minimum_size = Vector2(132, 0)
        name_label.text = label_text
        row.add_child(name_label)

        var keyboard_button: Button = Button.new()
        keyboard_button.custom_minimum_size = Vector2(170, 0)
        keyboard_button.text = "Key: -"
        keyboard_button.pressed.connect(_on_rebind_button_pressed.bind(action_id, "keyboard"))
        row.add_child(keyboard_button)

        var joypad_button: Button = Button.new()
        joypad_button.custom_minimum_size = Vector2(170, 0)
        joypad_button.text = "Pad: -"
        joypad_button.pressed.connect(_on_rebind_button_pressed.bind(action_id, "joypad"))
        row.add_child(joypad_button)

        _bindings_list.add_child(row)
        _binding_row_nodes[action_id] = {
            "keyboard": keyboard_button,
            "joypad": joypad_button
        }


func _on_rebind_button_pressed(action_id: String, target: String) -> void:
    if action_id == "":
        return
    _capture_action_id = action_id
    _capture_target = target
    if _binding_hint != null:
        if target == "keyboard":
            _binding_hint.text = "Listening %s keyboard... press ESC to cancel" % action_id
        else:
            _binding_hint.text = "Listening %s gamepad... press ESC to cancel" % action_id


func _clear_binding_capture(message: String) -> void:
    _capture_action_id = ""
    _capture_target = ""
    if _binding_hint != null:
        _binding_hint.text = message


func _assign_binding(action_id: String, target: String, value: int) -> void:
    var row_var: Variant = _input_bindings.get(action_id, {})
    var row: Dictionary = {}
    if row_var is Dictionary:
        row = row_var

    if target == "keyboard":
        row["keys"] = [value]
    else:
        row["joypad_buttons"] = [value]

    _persist_binding_patch(action_id, row)


func _persist_binding_patch(action_id: String, row: Dictionary) -> void:
    _input_bindings[action_id] = row
    # 优先走存档层，让存档负责归一化并同步到 InputMap；缺失时再退回 GameManager 清洗。
    if SaveManager != null and SaveManager.has_method("update_input_bindings"):
        _input_bindings = SaveManager.update_input_bindings({action_id: row})
    elif GameManager != null and GameManager.has_method("sanitize_input_bindings"):
        _input_bindings = GameManager.sanitize_input_bindings(_input_bindings)
    _refresh_binding_buttons()


func _apply_bindings_to_ui(bindings: Dictionary) -> void:
    if GameManager != null and GameManager.has_method("sanitize_input_bindings"):
        _input_bindings = GameManager.sanitize_input_bindings(bindings)
    else:
        _input_bindings = bindings.duplicate(true)
    _refresh_binding_buttons()


func _refresh_binding_buttons() -> void:
    for row_data: Dictionary in INPUT_ACTION_ROWS:
        var action_id: String = str(row_data.get("id", "")).strip_edges()
        if action_id == "":
            continue

        var node_var: Variant = _binding_row_nodes.get(action_id, {})
        if not (node_var is Dictionary):
            continue
        var node_row: Dictionary = node_var

        var binding_var: Variant = _input_bindings.get(action_id, {})
        var binding: Dictionary = {}
        if binding_var is Dictionary:
            binding = binding_var

        var keys: Array[int] = _to_int_array(binding.get("keys", []), 4)
        var pads: Array[int] = _to_int_array(binding.get("joypad_buttons", []), 4)

        var keyboard_button: Button = node_row.get("keyboard", null)
        if keyboard_button != null:
            keyboard_button.text = "Key: %s" % _format_keycodes(keys)
            keyboard_button.modulate = DIRTY_COLOR if _is_binding_dirty(action_id, "keys", keys) else NORMAL_COLOR

        var joypad_button: Button = node_row.get("joypad", null)
        if joypad_button != null:
            joypad_button.text = "Pad: %s" % _format_joypad_buttons(pads)
            joypad_button.modulate = DIRTY_COLOR if _is_binding_dirty(action_id, "joypad_buttons", pads) else NORMAL_COLOR


func _is_binding_dirty(action_id: String, key: String, current_values: Array[int]) -> bool:
    var defaults: Dictionary = _get_default_bindings()
    var default_row_var: Variant = defaults.get(action_id, {})
    if not (default_row_var is Dictionary):
        return false

    var default_row: Dictionary = default_row_var
    var default_values: Array[int] = _to_int_array(default_row.get(key, []), 4)
    if default_values.size() != current_values.size():
        return true

    for i: int in range(default_values.size()):
        if int(default_values[i]) != int(current_values[i]):
            return true
    return false


func _get_default_bindings() -> Dictionary:
    if SaveManager != null and SaveManager.has_method("get_default_input_bindings"):
        return SaveManager.get_default_input_bindings()
    if GameManager != null and GameManager.has_method("get_default_input_bindings"):
        return GameManager.get_default_input_bindings()
    return {}


func _format_keycodes(keys: Array[int]) -> String:
    if keys.is_empty():
        return "-"
    var labels: Array[String] = []
    for keycode: int in keys:
        var key_label: String = OS.get_keycode_string(keycode)
        if key_label == "":
            key_label = "Key %d" % keycode
        labels.append(key_label)
    return " / ".join(PackedStringArray(labels))


func _format_joypad_buttons(buttons: Array[int]) -> String:
    if buttons.is_empty():
        return "-"
    var labels: Array[String] = []
    for button_index: int in buttons:
        if JOYPAD_BUTTON_LABELS.has(button_index):
            labels.append(str(JOYPAD_BUTTON_LABELS[button_index]))
        else:
            labels.append("Btn %d" % button_index)
    return " / ".join(PackedStringArray(labels))


func _to_int_array(value: Variant, max_items: int) -> Array[int]:
    var out: Array[int] = []
    if value is Array:
        var source: Array = value
        for item: Variant in source:
            var parsed: int = int(item)
            if parsed < 0:
                continue
            if not out.has(parsed):
                out.append(parsed)
            if out.size() >= max_items:
                break
    return out


func _is_dirty(key: String, value: float) -> bool:
    var default_value: float = float(_default_settings.get(key, value))
    return absf(default_value - value) > 0.001


func _commit_settings_patch(patch: Dictionary) -> void:
    if _syncing:
        return

    var result_settings: Dictionary = patch
    if SaveManager != null and SaveManager.has_method("update_runtime_settings"):
        result_settings = SaveManager.update_runtime_settings(patch)
    _apply_settings_to_ui(result_settings)
    settings_updated.emit(result_settings)


func _refresh_bus_meters() -> void:
    _set_meter_value(_master_meter, _get_bus_peak_ratio(&"Master"))
    _set_meter_value(_bgm_meter, _get_bus_peak_ratio(&"BGM"))
    _set_meter_value(_sfx_meter, _get_bus_peak_ratio(&"SFX"))
    _set_meter_value(_ambience_meter, _get_bus_peak_ratio(&"Ambience"))


func _set_meter_value(bar: ProgressBar, value: float) -> void:
    if bar == null:
        return
    bar.value = clampf(value, 0.0, 1.0)


func _get_bus_peak_ratio(bus_name: StringName) -> float:
    if AudioManager != null and AudioManager.has_method("get_bus_peak_ratio"):
        return float(AudioManager.get_bus_peak_ratio(bus_name))
    return 0.0


func _get_default_settings() -> Dictionary:
    if SaveManager != null and SaveManager.has_method("get_default_runtime_settings"):
        return SaveManager.get_default_runtime_settings()
    return {
        "display_mode": "windowed",
        "resolution": "1280x720",
        "master_volume": 1.0,
        "bgm_volume": 1.0,
        "sfx_volume": 1.0,
        "ambience_volume": 1.0,
        "screen_shake": 1.0,
        "ui_scale": 1.0,
        "difficulty_tier": 0
    }


func _get_difficulty_label(tier: int) -> String:
    if SaveManager != null and SaveManager.has_method("get_difficulty_label"):
        return str(SaveManager.get_difficulty_label(tier))
    match clampi(tier, 0, 2):
        1:
            return "Hard"
        2:
            return "Nightmare"
        _:
            return "Normal"


func _get_difficulty_hint_text() -> String:
    if SaveManager != null and SaveManager.has_method("get_next_difficulty_unlock_hint"):
        return str(SaveManager.get_next_difficulty_unlock_hint())
    return "All difficulty tiers unlocked"


func _on_master_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"master_volume": value})


func _on_display_mode_selected(index: int) -> void:
    if _display_mode_option == null:
        return
    _commit_settings_patch({"display_mode": str(_display_mode_option.get_item_metadata(index))})


func _on_resolution_selected(index: int) -> void:
    if _resolution_option == null:
        return
    _commit_settings_patch({"resolution": str(_resolution_option.get_item_metadata(index))})


func _on_bgm_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"bgm_volume": value})


func _on_sfx_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"sfx_volume": value})


func _on_ambience_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"ambience_volume": value})


func _on_shake_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"screen_shake": value})


func _on_ui_scale_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"ui_scale": value})


func _on_difficulty_slider_value_changed(value: float) -> void:
    _commit_settings_patch({"difficulty_tier": int(round(value))})


func _on_test_sfx_button_pressed() -> void:
    if AudioManager != null and AudioManager.has_method("play_test_tone"):
        AudioManager.play_test_tone()


func _on_reset_defaults_button_pressed() -> void:
    reset_to_default()


func _on_reset_bindings_button_pressed() -> void:
    if SaveManager != null and SaveManager.has_method("reset_input_bindings"):
        _input_bindings = SaveManager.reset_input_bindings()
    else:
        _input_bindings = _get_default_bindings()
    _refresh_binding_buttons()
    _clear_binding_capture("Input bindings reset to defaults")
