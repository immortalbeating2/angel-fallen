extends Control

signal altar_closed

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _body_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body
@onready var _counter_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Counter
@onready var _hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hint

var _active: bool = false
var _fragment_ids: Array[String] = []
var _cursor: int = 0
var _archive_payload: Dictionary = {}


func _ready() -> void:
    visible = false


func show_archive(fragment_ids: Array[String], start_index: int = 0, archive_payload: Variant = []) -> void:
    _fragment_ids = fragment_ids.duplicate()
    _archive_payload = _normalize_archive_payload(archive_payload)
    if _get_total_pages() == 0:
        _title_label.text = "Memory Altar"
        var body_lines: Array[String] = []
        body_lines.append("No memory fragments unlocked yet.")
        body_lines.append("Defeat chapter bosses and resolve events to recover memories.")
        _body_label.text = "\n".join(PackedStringArray(body_lines))
        _counter_label.text = "0 / 0"
        _hint_label.text = "Press E/Esc to close"
    else:
        _cursor = _resolve_start_cursor(start_index)
        _render_current_entry()

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
    if _get_total_pages() == 0:
        return
    _cursor = posmod(_cursor - 1, _get_total_pages())
    _render_current_entry()


func _next_fragment() -> void:
    if _get_total_pages() == 0:
        return
    _cursor = posmod(_cursor + 1, _get_total_pages())
    _render_current_entry()


func _render_current_entry() -> void:
    if _get_total_pages() == 0:
        return
    if _has_archive_summary_page() and _cursor == 0:
        _render_archive_summary()
        return
    _render_current_fragment()


func _render_archive_summary() -> void:
    _title_label.text = "Memory Altar"
    var body_lines: Array[String] = ["Archive Recap"]

    var intro_lines_var: Variant = _archive_payload.get("intro_lines", [])
    if intro_lines_var is Array and not (intro_lines_var as Array).is_empty():
        for item: Variant in intro_lines_var:
            var text: String = str(item).strip_edges()
            if text != "":
                body_lines.append(text)

    var sections_var: Variant = _archive_payload.get("sections", [])
    if sections_var is Array and not (sections_var as Array).is_empty():
        for section_var: Variant in sections_var:
            if not (section_var is Dictionary):
                continue
            var section: Dictionary = section_var
            var title: String = str(section.get("title", "")).strip_edges()
            var lines_var: Variant = section.get("lines", [])
            var section_lines: Array[String] = []
            if lines_var is Array:
                for item: Variant in lines_var:
                    var text: String = str(item).strip_edges()
                    if text != "":
                        section_lines.append(text)
            if title == "" and section_lines.is_empty():
                continue
            body_lines.append("")
            if title != "":
                body_lines.append(title)
            for text: String in section_lines:
                body_lines.append("- %s" % text)

    _body_label.text = "\n".join(PackedStringArray(body_lines))
    _counter_label.text = "Page 1 / %d" % _get_total_pages()
    _hint_label.text = "1: Prev  2: Next  |  Review recap before fragments"


func _render_current_fragment() -> void:
    if _fragment_ids.is_empty():
        return

    var fragment_index: int = _get_fragment_index_for_cursor()
    var fragment_id: String = _fragment_ids[fragment_index]
    var row: Dictionary = _get_fragment_row(fragment_id)
    var title: String = str(row.get("title", fragment_id))
    var text: String = str(row.get("text", "No memory text."))

    _title_label.text = "Memory Altar"
    var body_lines: Array[String] = []
    var header_lines_var: Variant = _archive_payload.get("header_lines", [])
    if header_lines_var is Array and not (header_lines_var as Array).is_empty():
        for item: Variant in header_lines_var:
            var header_text: String = str(item).strip_edges()
            if header_text != "":
                body_lines.append(header_text)
    if not body_lines.is_empty():
        body_lines.append("")
    body_lines.append(title)
    body_lines.append("")
    body_lines.append(text)
    if _has_archive_summary_page():
        body_lines.append("")
        body_lines.append("Archive recap remains on page 1.")
    _body_label.text = "\n".join(PackedStringArray(body_lines))
    _counter_label.text = "Page %d / %d | Fragment %d / %d" % [
        _cursor + 1,
        _get_total_pages(),
        fragment_index + 1,
        _fragment_ids.size()
    ]
    _hint_label.text = "1: Prev  2: Next  |  E/Esc: Close"


func _normalize_archive_payload(value: Variant) -> Dictionary:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    if value is Array:
        return {
            "intro_lines": (value as Array).duplicate(true),
            "header_lines": (value as Array).duplicate(true),
            "sections": []
        }
    return {}


func _has_archive_summary_page() -> bool:
    if _archive_payload.is_empty():
        return false
    var intro_lines_var: Variant = _archive_payload.get("intro_lines", [])
    if intro_lines_var is Array and not (intro_lines_var as Array).is_empty():
        return true
    var sections_var: Variant = _archive_payload.get("sections", [])
    return sections_var is Array and not (sections_var as Array).is_empty()


func _get_total_pages() -> int:
    return _fragment_ids.size() + (1 if _has_archive_summary_page() else 0)


func _resolve_start_cursor(start_index: int) -> int:
    if _has_archive_summary_page():
        if _fragment_ids.is_empty():
            return 0
        if start_index <= 0:
            return 0
        return clampi(start_index + 1, 0, _get_total_pages() - 1)
    if _fragment_ids.is_empty():
        return 0
    return clampi(start_index, 0, _fragment_ids.size() - 1)


func _get_fragment_index_for_cursor() -> int:
    if _fragment_ids.is_empty():
        return 0
    var offset: int = 1 if _has_archive_summary_page() else 0
    return clampi(_cursor - offset, 0, _fragment_ids.size() - 1)


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
