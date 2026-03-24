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


func get_route_arc_summary(alignment: float, route_style: String = "neutral") -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var arc_rows_var: Variant = config.get("route_arc_profiles", {})
    if not (arc_rows_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (arc_rows_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    return row


func get_camp_reflection(chapter_id: String, alignment: float = 0.0, route_style: String = "neutral", unlocked_fragments: Array[String] = []) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var reflection_rows_var: Variant = config.get("camp_reflections", {})
    if not (reflection_rows_var is Dictionary):
        return {}

    var chapter_row_var: Variant = (reflection_rows_var as Dictionary).get(chapter_id, {})
    if not (chapter_row_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (chapter_row_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    row["fragment_progress"] = _build_fragment_progress_text(unlocked_fragments)
    row["recent_choice_summary"] = get_recent_choice_summary(chapter_id)
    return row


func get_recent_choice_summary(chapter_id: String = "", limit: int = 3) -> String:
    var rows: Array[String] = []
    var safe_limit: int = maxi(1, limit)
    for i in range(_run_choices.size() - 1, -1, -1):
        var row_var: Variant = _run_choices[i]
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var row_chapter: String = str(row.get("chapter_id", ""))
        if chapter_id != "" and row_chapter != chapter_id:
            continue
        var choice_id: String = str(row.get("choice_id", "")).replace("_", " ")
        if choice_id == "":
            continue
        rows.append(choice_id.capitalize())
        if rows.size() >= safe_limit:
            break

    rows.reverse()
    if rows.is_empty():
        return "No recent vows recorded yet."
    return "Recent vows: %s" % " -> ".join(PackedStringArray(rows))


func get_ending_payoff(ending_id: String, alignment: float = 0.0, route_style: String = "neutral") -> Dictionary:
    if ending_id == "":
        return {}

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var payoff_rows_var: Variant = config.get("ending_payoff_profiles", {})
    if not (payoff_rows_var is Dictionary):
        return {}

    var row_var: Variant = (payoff_rows_var as Dictionary).get(ending_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["ending_id"] = ending_id
    row["arc_id"] = _resolve_route_arc_id(alignment)
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    return row


func get_epilogue_chain(ending_id: String) -> Array[String]:
    if ending_id == "":
        return []

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var chain_rows_var: Variant = config.get("epilogue_chains", {})
    if not (chain_rows_var is Dictionary):
        return []

    var row_var: Variant = (chain_rows_var as Dictionary).get(ending_id, [])
    var rows: Array[String] = []
    if row_var is Array:
        for item: Variant in row_var:
            var text: String = str(item).strip_edges()
            if text != "":
                rows.append(text)
    return rows


func get_fragment_trigger_payload(chapter_id: String, trigger_type: String, alignment: float = 0.0, route_style: String = "neutral") -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var trigger_rows_var: Variant = config.get("fragment_trigger_profiles", {})
    if not (trigger_rows_var is Dictionary):
        return {}

    var chapter_row_var: Variant = (trigger_rows_var as Dictionary).get(chapter_id, {})
    if not (chapter_row_var is Dictionary):
        return {}

    var trigger_row_var: Variant = (chapter_row_var as Dictionary).get(trigger_type, {})
    if not (trigger_row_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var fragment_id: String = str((trigger_row_var as Dictionary).get(arc_id, "")).strip_edges()
    if fragment_id == "":
        return {}

    var fragment_data: Dictionary = get_fragment_data(fragment_id)
    return {
        "chapter_id": chapter_id,
        "trigger_type": trigger_type,
        "arc_id": arc_id,
        "style": route_style,
        "fragment_id": fragment_id,
        "fragment_title": str(fragment_data.get("title", fragment_id)),
        "fragment_text": str(fragment_data.get("text", ""))
    }


func get_epilogue_branch_summary(ending_id: String, newly_unlocked: bool, route_style: String = "neutral") -> Dictionary:
    if ending_id == "":
        return {}

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("epilogue_branch_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var ending_row_var: Variant = (rows_var as Dictionary).get(ending_id, {})
    if not (ending_row_var is Dictionary):
        return {}

    var branch_key: String = "first_unlock" if newly_unlocked else "repeat_unlock"
    var branch_row_var: Variant = (ending_row_var as Dictionary).get(branch_key, {})
    if not (branch_row_var is Dictionary):
        return {}

    var row: Dictionary = (branch_row_var as Dictionary).duplicate(true)
    row["ending_id"] = ending_id
    row["branch_key"] = branch_key
    row["archive_hook"] = str((ending_row_var as Dictionary).get("archive_hook", ""))
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    return row


func get_fragment_recap_summary(fragment_triggers: Array[Dictionary], alignment: float = 0.0, route_style: String = "neutral") -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("fragment_recap_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (rows_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var trigger_count: int = 0
    var newly_unlocked_count: int = 0
    var trigger_types: Array[String] = []
    for item: Dictionary in fragment_triggers:
        trigger_count += 1
        if bool(item.get("newly_unlocked", false)):
            newly_unlocked_count += 1
        var trigger_type: String = str(item.get("trigger_type", "")).strip_edges()
        if trigger_type != "" and not trigger_types.has(trigger_type):
            trigger_types.append(trigger_type)

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    row["trigger_count"] = trigger_count
    row["new_unlock_count"] = newly_unlocked_count
    row["trigger_types"] = trigger_types
    return row


func get_hidden_layer_hook(alignment: float = 0.0, route_style: String = "neutral", unlocked_endings: Array[String] = []) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("hidden_layer_hooks", {})
    if not (rows_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (rows_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    row["unlocked_endings"] = unlocked_endings.duplicate()
    row["ready"] = unlocked_endings.has("nar_ending_%s" % arc_id)
    return row


func get_hidden_layer_story_payload(layer_id: String, alignment: float = 0.0, route_style: String = "neutral", unlocked_endings: Array = []) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    if layer_key == "":
        return {}

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("hidden_layer_story_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var layer_row_var: Variant = (rows_var as Dictionary).get(layer_key, {})
    if not (layer_row_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (layer_row_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    var ending_id: String = str(row.get("ending_link", row.get("ending_id", ""))).strip_edges()
    var fragment_id: String = str(row.get("fragment_id", "")).strip_edges()
    var fragment_data: Dictionary = get_fragment_data(fragment_id)
    row["layer_id"] = layer_key
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    row["ending_id"] = ending_id
    row["ending_link"] = ending_id
    row["ending_ready"] = ending_id != "" and unlocked_endings.has(ending_id)
    row["fragment_id"] = fragment_id
    row["fragment_title"] = str(fragment_data.get("title", fragment_id))
    row["fragment_text"] = str(fragment_data.get("text", ""))
    return row


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


func _resolve_route_arc_id(alignment: float) -> String:
    if alignment >= 60.0:
        return "redeem"
    if alignment <= -60.0:
        return "fall"
    return "balance"


func _get_route_style_echo(route_style: String) -> String:
    match route_style:
        "vanguard":
            return "Vanguard routes favor safer pressure and disciplined pacing."
        "raider":
            return "Raider routes trade stability for burst rewards and sharper pressure."
        _:
            return "Neutral routes keep both ending paths open while you shape the run."


func _build_fragment_progress_text(unlocked_fragments: Array[String]) -> String:
    var index_data: Dictionary = ConfigManager.get_config("narrative_index", {})
    var fragment_meta: Dictionary = index_data.get("memory_fragments", {})
    var total: int = maxi(1, int(fragment_meta.get("total", 0)))
    return "Fragment progress: %d / %d" % [unlocked_fragments.size(), total]
