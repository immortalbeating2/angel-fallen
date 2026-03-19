extends Node

var _run_choices: Array[Dictionary] = []
var _chapter_event_history: Dictionary = {}


func _ready() -> void:
    _run_choices.clear()
    _chapter_event_history.clear()


func reset_run_choices() -> void:
    _run_choices.clear()
    _chapter_event_history.clear()


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


func get_chapter_event(chapter_index: int, alignment: float = 0.0, route_style: String = "neutral", route_weight_mult: float = 1.0) -> Dictionary:
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

    var unlocked_endings: Array[String] = []
    if SaveManager != null and SaveManager.has_method("get_unlocked_endings"):
        unlocked_endings = SaveManager.get_unlocked_endings()

    var weighted_events: Array[Dictionary] = []
    var total_weight: float = 0.0

    for item: Variant in chapter_events:
        if not (item is Dictionary):
            continue
        var row: Dictionary = (item as Dictionary)
        var weight: float = _calc_event_weight(row, chapter_id, alignment, unlocked_endings, route_style, route_weight_mult)
        if weight <= 0.0:
            continue
        weighted_events.append({
            "event": row.duplicate(true),
            "weight": weight
        })
        total_weight += weight

    if weighted_events.is_empty() or total_weight <= 0.0:
        return {}

    var roll: float = randf() * total_weight
    var cursor: float = 0.0
    for item: Dictionary in weighted_events:
        cursor += float(item.get("weight", 0.0))
        if roll <= cursor:
            var picked_event: Dictionary = item.get("event", {})
            _record_event_history(chapter_id, str(picked_event.get("id", "")))
            return picked_event

    var fallback: Dictionary = weighted_events[weighted_events.size() - 1].get("event", {})
    _record_event_history(chapter_id, str(fallback.get("id", "")))
    return fallback


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


func _calc_event_weight(event_row: Dictionary, chapter_id: String, alignment: float, unlocked_endings: Array[String], route_style: String, route_weight_mult: float) -> float:
    if not _is_event_allowed_by_endings(event_row, unlocked_endings):
        return 0.0

    var weight: float = maxf(0.0, float(event_row.get("weight_base", 1.0)))
    if alignment >= 30.0:
        weight *= maxf(0.0, float(event_row.get("weight_if_holy", 1.0)))
    elif alignment <= -30.0:
        weight *= maxf(0.0, float(event_row.get("weight_if_void", 1.0)))
    else:
        weight *= maxf(0.0, float(event_row.get("weight_if_balance", 1.0)))

    if unlocked_endings.has("nar_ending_redeem"):
        weight *= maxf(0.0, float(event_row.get("weight_if_ending_redeem", 1.0)))
    if unlocked_endings.has("nar_ending_fall"):
        weight *= maxf(0.0, float(event_row.get("weight_if_ending_fall", 1.0)))
    if unlocked_endings.has("nar_ending_balance"):
        weight *= maxf(0.0, float(event_row.get("weight_if_ending_balance", 1.0)))

    var style_key: String = "weight_if_route_%s" % route_style
    weight *= maxf(0.0, float(event_row.get(style_key, 1.0)))
    weight *= maxf(0.0, route_weight_mult)

    var event_id: String = str(event_row.get("id", ""))
    weight *= _get_recent_event_factor(chapter_id, event_id)
    return weight


func _is_event_allowed_by_endings(event_row: Dictionary, unlocked_endings: Array[String]) -> bool:
    var requires_var: Variant = event_row.get("requires_endings_any", [])
    if requires_var is Array and not (requires_var as Array).is_empty():
        var allowed: bool = false
        for item: Variant in requires_var:
            if unlocked_endings.has(str(item)):
                allowed = true
                break
        if not allowed:
            return false

    var forbid_var: Variant = event_row.get("forbid_endings_any", [])
    if forbid_var is Array and not (forbid_var as Array).is_empty():
        for item: Variant in forbid_var:
            if unlocked_endings.has(str(item)):
                return false

    return true


func _get_recent_event_factor(chapter_id: String, event_id: String) -> float:
    if event_id == "":
        return 1.0

    var history_var: Variant = _chapter_event_history.get(chapter_id, [])
    if not (history_var is Array):
        return 1.0
    var history: Array = history_var
    if history.is_empty():
        return 1.0

    var last_event_id: String = str(history[history.size() - 1])
    if last_event_id == event_id:
        return 0.15
    if history.has(event_id):
        return 0.45
    return 1.0


func _record_event_history(chapter_id: String, event_id: String) -> void:
    if event_id == "":
        return

    var history_var: Variant = _chapter_event_history.get(chapter_id, [])
    var history: Array = []
    if history_var is Array:
        history = (history_var as Array).duplicate()

    history.append(event_id)
    while history.size() > 5:
        history.remove_at(0)

    _chapter_event_history[chapter_id] = history
