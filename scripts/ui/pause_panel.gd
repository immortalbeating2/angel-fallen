extends Control

signal resume_requested
signal retreat_requested
signal quit_to_menu_requested

@onready var _summary_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Summary
@onready var _hint_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Hint
@onready var _menu_actions: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuActions
@onready var _settings_page: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPage
@onready var _runtime_settings_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsPage/RuntimeSettingsPanel

var _settings_page_open: bool = false


func _ready() -> void:
    visible = false
    _set_settings_page(false)


func open_panel(room_index: int, room_type: String, alignment: float) -> void:
    visible = true
    _set_settings_page(false)
    _summary_label.text = "Room %d | Type: %s | Alignment: %.0f" % [
        room_index,
        room_type.to_upper(),
        alignment
    ]
    _hint_label.text = "[1] Resume  [2] Retreat  [3] Main Menu  [4] Settings"
    if _runtime_settings_panel != null and _runtime_settings_panel.has_method("sync_from_save"):
        _runtime_settings_panel.sync_from_save()


func close_panel() -> void:
    visible = false
    _set_settings_page(false)


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return

    var capturing_binding: bool = _is_runtime_settings_capturing()

    if event.is_action_pressed("pause") and not capturing_binding:
        resume_requested.emit()
        return

    if _settings_page_open and event.is_action_pressed("interact") and not capturing_binding:
        _set_settings_page(false)
        return

    if not _settings_page_open and event.is_action_pressed("interact"):
        resume_requested.emit()
        return

    if event is InputEventKey:
        var key_event: InputEventKey = event
        if not key_event.pressed or key_event.echo:
            return

        if key_event.physical_keycode == KEY_4 or key_event.physical_keycode == KEY_KP_4:
            _set_settings_page(not _settings_page_open)
            return

        if _settings_page_open or capturing_binding:
            return

        if key_event.physical_keycode == KEY_1 or key_event.physical_keycode == KEY_KP_1:
            resume_requested.emit()
        elif key_event.physical_keycode == KEY_2 or key_event.physical_keycode == KEY_KP_2:
            retreat_requested.emit()
        elif key_event.physical_keycode == KEY_3 or key_event.physical_keycode == KEY_KP_3:
            quit_to_menu_requested.emit()


func _set_settings_page(open: bool) -> void:
    _settings_page_open = open
    if _menu_actions != null:
        _menu_actions.visible = not open
    if _settings_page != null:
        _settings_page.visible = open
    if _hint_label != null:
        if open:
            _hint_label.text = "Adjust sliders and bindings. Click Key/Pad to listen. Press E or [4] to return"
        else:
            _hint_label.text = "[1] Resume  [2] Retreat  [3] Main Menu  [4] Settings"


func _is_runtime_settings_capturing() -> bool:
    if _runtime_settings_panel == null:
        return false
    if not _runtime_settings_panel.has_method("is_capturing_input"):
        return false
    return bool(_runtime_settings_panel.is_capturing_input())


func _on_resume_button_pressed() -> void:
    resume_requested.emit()


func _on_retreat_button_pressed() -> void:
    retreat_requested.emit()


func _on_menu_button_pressed() -> void:
    quit_to_menu_requested.emit()


func _on_settings_button_pressed() -> void:
    _set_settings_page(true)


func _on_settings_back_button_pressed() -> void:
    _set_settings_page(false)
