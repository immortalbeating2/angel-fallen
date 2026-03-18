extends Control

signal intro_closed

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _subtitle_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Subtitle
@onready var _hazards_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hazards
@onready var _blessing_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Blessing

var _active: bool = false


func _ready() -> void:
    visible = false


func show_intro(chapter_index: int, hazards_text: String, blessing_text: String) -> void:
    var row: Dictionary = _get_intro_data(chapter_index)
    _title_label.text = str(row.get("title", "Chapter Start"))
    _subtitle_label.text = str(row.get("subtitle", ""))
    _hazards_label.text = "Hazards: %s\n%s" % [hazards_text, str(row.get("hazard_hint", ""))]
    _blessing_label.text = "Active Blessing: %s" % blessing_text

    _active = true
    visible = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _close()


func _on_continue_pressed() -> void:
    _close()


func _close() -> void:
    if not _active:
        return
    _active = false
    visible = false
    intro_closed.emit()


func _get_intro_data(chapter_id: int) -> Dictionary:
    var key: String = "chapter_%d" % chapter_id
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var intro_rows: Variant = config.get("chapter_intros", {})
    if intro_rows is Dictionary:
        var row_variant: Variant = (intro_rows as Dictionary).get(key, {})
        if row_variant is Dictionary:
            return row_variant

    return {
        "title": "Chapter %d" % chapter_id,
        "subtitle": "Stay focused.",
        "hazard_hint": "Watch room hazards and keep your gauges low between fights."
    }
