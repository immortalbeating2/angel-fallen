extends Node

var _run_choices: Array[Dictionary] = []


func _ready() -> void:
    _run_choices.clear()


func reset_run_choices() -> void:
    _run_choices.clear()


func record_choice(chapter_id: String, segment_id: String, choice_id: String, alignment_delta: float) -> void:
    _run_choices.append({
        "chapter_id": chapter_id,
        "segment_id": segment_id,
        "choice_id": choice_id,
        "alignment_delta": alignment_delta
    })


func get_run_choices() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for item: Variant in _run_choices:
        if item is Dictionary:
            result.append((item as Dictionary).duplicate(true))
    return result


func get_chapter_event(chapter_index: int) -> Dictionary:
    var chapter_id: String = "chapter_%d" % chapter_index
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var event_rows: Variant = config.get("chapter_events", {})
    if not (event_rows is Dictionary):
        return {}

    var chapter_events_var: Variant = (event_rows as Dictionary).get(chapter_id, [])
    if not (chapter_events_var is Array):
        return {}
    var chapter_events: Array = chapter_events_var
    if chapter_events.is_empty():
        return {}

    var picked: Variant = chapter_events[randi_range(0, chapter_events.size() - 1)]
    if not (picked is Dictionary):
        return {}
    return (picked as Dictionary).duplicate(true)


func get_fragment_data(fragment_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows: Variant = config.get("memory_fragments", {})
    if rows is Dictionary:
        var item: Variant = (rows as Dictionary).get(fragment_id, {})
        if item is Dictionary:
            return item
    return {}


func is_registered_narrative_id(segment_id: String) -> bool:
    var index_data: Dictionary = ConfigManager.get_config("narrative_index", {})
    var rows: Variant = index_data.get("segments", [])
    if not (rows is Array):
        return false

    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        if str((item as Dictionary).get("id", "")) == segment_id:
            return true
    return false
