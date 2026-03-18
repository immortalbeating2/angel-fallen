extends Control

signal option_selected(option_id: String)

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _button_1: Button = $CenterContainer/PanelContainer/VBoxContainer/Option1
@onready var _button_2: Button = $CenterContainer/PanelContainer/VBoxContainer/Option2
@onready var _button_3: Button = $CenterContainer/PanelContainer/VBoxContainer/Option3

var _options: Array[Dictionary] = []


func _ready() -> void:
    visible = false


func show_options(options: Array[Dictionary], new_level: int) -> void:
    if options.size() < 3:
        return

    _options = options
    _title_label.text = "Level %d Up - Choose 1" % new_level

    _button_1.text = _format_option_text(_options[0])
    _button_2.text = _format_option_text(_options[1])
    _button_3.text = _format_option_text(_options[2])

    visible = true


func _format_option_text(option: Dictionary) -> String:
    return "%s\n%s" % [str(option.get("title", "Upgrade")), str(option.get("desc", ""))]


func _on_option_1_pressed() -> void:
    _pick_option(0)


func _on_option_2_pressed() -> void:
    _pick_option(1)


func _on_option_3_pressed() -> void:
    _pick_option(2)


func _pick_option(index: int) -> void:
    if index < 0 or index >= _options.size():
        return

    var id: String = str(_options[index].get("id", ""))
    visible = false
    option_selected.emit(id)
