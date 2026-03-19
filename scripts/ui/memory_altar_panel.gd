extends Control

signal altar_closed

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _body_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body
@onready var _counter_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Counter
@onready var _hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hint

var _active: bool = false
var _fragment_ids: Array[String] = []
var _cursor: int = 0


func _ready() -> void:
    visible = false


func show_archive(fragment_ids: Array[String], start_index: int = 0) -> void:
    _fragment_ids = fragment_ids.duplicate()
    if _fragment_ids.is_empty():
        _title_label.text = "Memory Altar"
        _body_label.text = "No memory fragments unlocked yet.\nDefeat chapter bosses and resolve events to recover memories."
        _counter_label.text = "0 / 0"
        _hint_label.text = "Press E/Esc to close"
    else:
        _cursor = clampi(start_index, 0, _fragment_ids.size() - 1)
        _render_current_fragment()

    _active = true
    visible = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if event.is_action_pressed("narrative_choice_1"):
        _prev_fragment()
        return
    if event.is_action_pressed("narrative_choice_2"):
        _next_fragment()
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _close_panel()


func _on_prev_button_pressed() -> void:
    _prev_fragment()


func _on_next_button_pressed() -> void:
    _next_fragment()


func _on_close_button_pressed() -> void:
    _close_panel()


func _prev_fragment() -> void:
    if _fragment_ids.is_empty():
        return
    _cursor = posmod(_cursor - 1, _fragment_ids.size())
    _render_current_fragment()


func _next_fragment() -> void:
    if _fragment_ids.is_empty():
        return
    _cursor = posmod(_cursor + 1, _fragment_ids.size())
    _render_current_fragment()


func _render_current_fragment() -> void:
    if _fragment_ids.is_empty():
        return

    var fragment_id: String = _fragment_ids[_cursor]
    var row: Dictionary = _get_fragment_row(fragment_id)
    var title: String = str(row.get("title", fragment_id))
    var text: String = str(row.get("text", "No memory text."))

    _title_label.text = "Memory Altar"
    _body_label.text = "%s\n\n%s" % [title, text]
    _counter_label.text = "%d / %d" % [_cursor + 1, _fragment_ids.size()]
    _hint_label.text = "1: Prev  2: Next  |  E/Esc: Close"


func _get_fragment_row(fragment_id: String) -> Dictionary:
    var content: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = content.get("memory_fragments", {})
    if rows_var is Dictionary:
        var row_var: Variant = (rows_var as Dictionary).get(fragment_id, {})
        if row_var is Dictionary:
            return row_var
    return {}


func _close_panel() -> void:
    if not _active:
        return
    _active = false
    visible = false
    altar_closed.emit()
