extends CanvasLayer

signal intro_closed

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/CenterContainer/PanelContainer
@onready var _title_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var _subtitle_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Subtitle
@onready var _hazards_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Hazards
@onready var _blessing_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Blessing
@onready var _continue_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

var _active: bool = false


func _ready() -> void:
    visible = false
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    _refresh_layout()

func show_intro(chapter_index: int, hazards_text: String, blessing_text: String) -> void:
    var row: Dictionary = _get_intro_data(chapter_index)
    _title_label.text = str(row.get("title", "Chapter Start"))
    _subtitle_label.text = str(row.get("subtitle", ""))
    _hazards_label.text = "Hazards: %s\n%s" % [hazards_text, str(row.get("hazard_hint", ""))]
    _blessing_label.text = "Active Blessing: %s" % blessing_text

    _active = true
    _refresh_layout()
    visible = true
    _continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _close()
        get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
    _close()


func _close() -> void:
    if not _active:
        return
    _active = false
    visible = false
    intro_closed.emit()


func _refresh_layout() -> void:
    if _panel == null:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var panel_width: float = clampf(viewport_size.x * 0.54, 520.0, 760.0)
    if viewport_size.x < 700.0:
        panel_width = maxf(320.0, viewport_size.x - 40.0)
    _panel.custom_minimum_size = Vector2(panel_width, 0)


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
