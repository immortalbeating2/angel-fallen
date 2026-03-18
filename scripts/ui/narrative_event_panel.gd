extends Control

signal event_choice_committed(event_id: String, choice_id: String, choice_data: Dictionary)
signal event_closed

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _body_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body
@onready var _option_1: Button = $CenterContainer/PanelContainer/VBoxContainer/Option1
@onready var _option_2: Button = $CenterContainer/PanelContainer/VBoxContainer/Option2
@onready var _hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hint

var _active: bool = false
var _choice_done: bool = false
var _event_id: String = ""
var _choice_1: Dictionary = {}
var _choice_2: Dictionary = {}


func _ready() -> void:
    visible = false


func show_event_panel(event_data: Dictionary, alignment: float) -> void:
    _event_id = str(event_data.get("id", "event_unknown"))
    var choices: Array = event_data.get("choices", [])
    if choices.size() < 2:
        return

    _choice_1 = choices[0] if choices[0] is Dictionary else {}
    _choice_2 = choices[1] if choices[1] is Dictionary else {}
    if _choice_1.is_empty() or _choice_2.is_empty():
        return

    _title_label.text = str(event_data.get("title", "Event"))
    _body_label.text = "%s\n\nAlignment: %.0f" % [
        str(event_data.get("body", "")),
        alignment
    ]
    _option_1.text = "1) %s" % str(_choice_1.get("label", "Option 1"))
    _option_2.text = "2) %s" % str(_choice_2.get("label", "Option 2"))
    _hint_label.text = "Press 1/2 to choose"

    _option_1.disabled = false
    _option_2.disabled = false
    _choice_done = false
    _active = true
    visible = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if not _choice_done:
        if event.is_action_pressed("narrative_choice_1"):
            _commit(_choice_1)
        elif event.is_action_pressed("narrative_choice_2"):
            _commit(_choice_2)
        return

    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _close()


func _on_option_1_pressed() -> void:
    _commit(_choice_1)


func _on_option_2_pressed() -> void:
    _commit(_choice_2)


func _on_continue_pressed() -> void:
    if _choice_done:
        _close()


func _commit(choice_data: Dictionary) -> void:
    if not _active or _choice_done:
        return
    _choice_done = true
    _option_1.disabled = true
    _option_2.disabled = true
    var choice_id: String = str(choice_data.get("id", "choice"))
    _hint_label.text = "Choice committed: %s. Press E/Esc to continue" % choice_id
    event_choice_committed.emit(_event_id, choice_id, choice_data.duplicate(true))


func _close() -> void:
    if not _active:
        return
    _active = false
    visible = false
    event_closed.emit()
