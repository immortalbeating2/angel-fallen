extends Control

signal back_to_menu_requested

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _summary_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Summary
@onready var _ending_label: Label = $CenterContainer/PanelContainer/VBoxContainer/EndingStory
@onready var _choices_label: Label = $CenterContainer/PanelContainer/VBoxContainer/NarrativeChoices
@onready var _route_style_label: Label = $CenterContainer/PanelContainer/VBoxContainer/RouteStyleSummary
@onready var _effects_timeline_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ChapterEffectsTimeline
@onready var _timeline_filter_button: Button = $CenterContainer/PanelContainer/VBoxContainer/TimelineFilterButton
@onready var _timeline_view_button: Button = $CenterContainer/PanelContainer/VBoxContainer/TimelineViewButton
@onready var _timeline_anchor_button: Button = $CenterContainer/PanelContainer/VBoxContainer/TimelineAnchorButton
@onready var _timeline_scope_button: Button = $CenterContainer/PanelContainer/VBoxContainer/TimelineScopeButton
@onready var _unlock_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Unlocks
@onready var _hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hint

var _active: bool = false
var _timeline_filter_index: int = 0
var _timeline_rows: Array = []
var _timeline_grouped_view: bool = false
var _grouped_chapter_order: Array[String] = []
var _grouped_anchor_index: int = 0
var _grouped_anchor_only_scope: bool = false
var _current_ending_id: String = ""

const TIMELINE_FILTER_ORDER: Array[String] = ["all", "boon", "curse", "mixed"]
const TIMELINE_FILTER_THEME: Dictionary = {
    "all": {
        "tint": Color(0.9, 0.92, 0.98, 1.0),
        "tag": "[ALL]"
    },
    "boon": {
        "tint": Color(0.78, 0.98, 0.74, 1.0),
        "tag": "[BOON]"
    },
    "curse": {
        "tint": Color(1.0, 0.72, 0.7, 1.0),
        "tag": "[CURSE]"
    },
    "mixed": {
        "tint": Color(0.9, 0.86, 1.0, 1.0),
        "tag": "[MIXED]"
    }
}

const ENDING_FACTION_THEME: Dictionary = {
    "nar_ending_redeem": {
        "tag": "[REDEEM]",
        "tint": Color(0.70, 0.90, 1.0, 1.0)
    },
    "nar_ending_fall": {
        "tag": "[FALL]",
        "tint": Color(1.0, 0.68, 0.66, 1.0)
    },
    "nar_ending_balance": {
        "tag": "[BALANCE]",
        "tint": Color(0.80, 0.96, 0.76, 1.0)
    },
    "default": {
        "tag": "[ARCHIVE]",
        "tint": Color(0.88, 0.90, 0.96, 1.0)
    }
}


func _ready() -> void:
    visible = false


func show_result(run_result: Dictionary) -> void:
    var outcome: String = str(run_result.get("outcome", "death")).to_upper()
    _title_label.text = "Run %s" % outcome

    _summary_label.text = "Rooms %d | Kills %d | Lv %d | Meta +%d" % [
        int(run_result.get("rooms_cleared", 0)),
        int(run_result.get("kills", 0)),
        int(run_result.get("level_reached", 1)),
        int(run_result.get("meta_reward", 0))
    ]

    var lines: Array[String] = []
    _choices_label.text = _build_choices_summary(run_result.get("narrative_choices", []))
    _route_style_label.text = _build_route_style_summary(
        run_result.get("chapter_route_styles", {}),
        run_result.get("route_style_timeline", [])
    )
    _timeline_rows = []
    var timeline_var: Variant = run_result.get("chapter_effect_timeline", [])
    if timeline_var is Array:
        _timeline_rows = timeline_var
    _timeline_filter_index = posmod(_timeline_filter_index, TIMELINE_FILTER_ORDER.size())
    _grouped_anchor_index = 0
    _grouped_chapter_order.clear()
    _refresh_timeline_view()

    var ending_id: String = str(run_result.get("ending_id", ""))
    _current_ending_id = ending_id
    if ending_id != "":
        var epilogue: String = str(run_result.get("ending_epilogue", ""))
        var ending_body: String = "%s\n%s" % [_get_ending_title(ending_id), _get_ending_story(ending_id)]
        if epilogue != "":
            ending_body += "\n\nEpilogue: %s" % epilogue
        _ending_label.text = ending_body
    else:
        _ending_label.text = "No ending unlocked in this run"

    var new_achievements_var: Variant = run_result.get("new_achievements", [])
    if new_achievements_var is Array and not (new_achievements_var as Array).is_empty():
        var ids: PackedStringArray = PackedStringArray()
        for ach_id: Variant in new_achievements_var:
            ids.append(str(ach_id))
        lines.append("New Achievements: %s" % ", ".join(ids))

    if lines.is_empty():
        lines.append("No new unlocks this run")
    _unlock_label.text = "\n".join(PackedStringArray(lines))

    visible = true
    _active = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if _timeline_grouped_view and event is InputEventKey:
        var key_event: InputEventKey = event
        if key_event.pressed and not key_event.echo:
            if key_event.physical_keycode == KEY_Q:
                _shift_grouped_anchor(-1)
                return
            if key_event.physical_keycode == KEY_E:
                _shift_grouped_anchor(1)
                return
            if key_event.physical_keycode == KEY_3 or key_event.physical_keycode == KEY_KP_3:
                _toggle_grouped_anchor_scope()
                return

    if event.is_action_pressed("narrative_choice_1"):
        _cycle_timeline_filter()
        return

    if event.is_action_pressed("narrative_choice_2"):
        _toggle_timeline_view()
        return

    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _request_back()


func _on_back_button_pressed() -> void:
    _request_back()


func _request_back() -> void:
    if not _active:
        return
    _active = false
    visible = false
    back_to_menu_requested.emit()


func _on_timeline_filter_button_pressed() -> void:
    _cycle_timeline_filter()


func _on_timeline_view_button_pressed() -> void:
    _toggle_timeline_view()


func _on_timeline_anchor_button_pressed() -> void:
    _shift_grouped_anchor(1)


func _on_timeline_scope_button_pressed() -> void:
    _toggle_grouped_anchor_scope()


func _cycle_timeline_filter() -> void:
    _timeline_filter_index = (_timeline_filter_index + 1) % TIMELINE_FILTER_ORDER.size()
    _refresh_timeline_view()


func _toggle_timeline_view() -> void:
    _timeline_grouped_view = not _timeline_grouped_view
    _refresh_timeline_view()


func _toggle_grouped_anchor_scope() -> void:
    if not _timeline_grouped_view:
        return
    _grouped_anchor_only_scope = not _grouped_anchor_only_scope
    _refresh_timeline_view()


func _refresh_timeline_view() -> void:
    var mode: String = TIMELINE_FILTER_ORDER[_timeline_filter_index]
    _rebuild_grouped_chapter_order(mode)

    if _timeline_grouped_view:
        _effects_timeline_label.text = _build_grouped_timeline_summary(_timeline_rows, mode)
    else:
        _effects_timeline_label.text = _build_chapter_effect_timeline_summary(_timeline_rows, mode)

    _apply_timeline_filter_theme(mode)
    _apply_anchor_faction_theme()

    if _timeline_filter_button != null:
        var tag: String = _get_timeline_mode_tag(mode)
        _timeline_filter_button.text = "%s Timeline Filter: %s (click / [1])" % [tag, mode.to_upper()]

    if _timeline_view_button != null:
        var view_text: String = "Timeline View: %s (click / [2])" % ("GROUPED" if _timeline_grouped_view else "FLAT")
        if _timeline_grouped_view:
            var chapter_hint: String = _chapter_anchor_title(_get_active_grouped_chapter_id())
            if chapter_hint == "":
                chapter_hint = "none"
            view_text += " | Anchor: %s (Q/E)" % chapter_hint
        _timeline_view_button.text = view_text

    if _timeline_anchor_button != null:
        var faction_tag: String = _get_ending_faction_tag(_current_ending_id)
        var anchor_hint: String = _chapter_anchor_title(_get_active_grouped_chapter_id())
        if anchor_hint == "":
            anchor_hint = "none"
        _timeline_anchor_button.disabled = (not _timeline_grouped_view) or _grouped_chapter_order.is_empty()
        _timeline_anchor_button.text = "%s Anchor Next: %s (click / E)" % [faction_tag, anchor_hint]

    if _timeline_scope_button != null:
        _timeline_scope_button.disabled = (not _timeline_grouped_view) or _grouped_chapter_order.is_empty()
        var scope_text: String = "ANCHOR ONLY" if _grouped_anchor_only_scope else "ALL CHAPTERS"
        _timeline_scope_button.text = "Scope: %s (click / [3])" % scope_text

    if _hint_label != null:
        if _timeline_grouped_view:
            _hint_label.text = "[1] Filter | [2] View | [3] Scope | Q/E anchor | Esc to return"
        else:
            _hint_label.text = "[1] Switch filter | [2] Switch view | E / Esc to return"


func _get_ending_title(ending_id: String) -> String:
    var configured: Dictionary = _get_ending_row(ending_id)
    if not configured.is_empty():
        return str(configured.get("title", "Ending"))

    match ending_id:
        "nar_ending_redeem":
            return "Ending: REDEEM"
        "nar_ending_fall":
            return "Ending: FALL"
        "nar_ending_balance":
            return "Ending: BALANCE"
        _:
            return "Ending: %s" % ending_id


func _get_ending_story(ending_id: String) -> String:
    var configured: Dictionary = _get_ending_row(ending_id)
    if not configured.is_empty():
        return str(configured.get("story", "A new fate is recorded."))

    match ending_id:
        "nar_ending_redeem":
            return "You rise with broken wings healed by grace. The abyss closes, but your oath remains."
        "nar_ending_fall":
            return "You wear the void as a crown. Salvation is denied, and power becomes your final prayer."
        "nar_ending_balance":
            return "Neither halo nor abyss claims you. You walk the narrow dusk, guarding both worlds."
        _:
            return "A new fate is recorded."


func _get_ending_row(ending_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var ending_rows: Variant = config.get("endings", {})
    if ending_rows is Dictionary:
        var row: Variant = (ending_rows as Dictionary).get(ending_id, {})
        if row is Dictionary:
            return row
    return {}


func _build_choices_summary(raw_choices: Variant) -> String:
    if not (raw_choices is Array):
        return "Narrative Choices: none"

    var choices: Array = raw_choices
    if choices.is_empty():
        return "Narrative Choices: none"

    var lines: Array[String] = ["Narrative Choices:"]
    var display_limit: int = mini(6, choices.size())
    for i in range(display_limit):
        var item: Variant = choices[i]
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var chapter_id: String = str(row.get("chapter_id", "chapter"))
        var segment_id: String = str(row.get("segment_id", "segment"))
        var choice_id: String = str(row.get("choice_id", "choice"))
        var alignment_delta: float = float(row.get("alignment_delta", 0.0))
        lines.append("- %s / %s -> %s (%+.0f)" % [chapter_id, segment_id, choice_id, alignment_delta])

    if choices.size() > display_limit:
        lines.append("... +%d more" % (choices.size() - display_limit))

    return "\n".join(PackedStringArray(lines))


func _build_route_style_summary(raw_styles: Variant, raw_timeline: Variant) -> String:
    var styles: Dictionary = {}
    if raw_styles is Dictionary:
        styles = raw_styles

    var lines: Array[String] = ["Route Style Evolution:"]
    var chapter_parts: Array[String] = []
    for idx in range(1, 5):
        var chapter_id: String = "chapter_%d" % idx
        var style_id: String = str(styles.get(chapter_id, "neutral"))
        chapter_parts.append("CH%d:%s" % [idx, _route_style_label_for_id(style_id)])
    lines.append("  " + " | ".join(PackedStringArray(chapter_parts)))

    if raw_timeline is Array and not (raw_timeline as Array).is_empty():
        var timeline: Array = raw_timeline
        lines.append("Locks:")
        var limit: int = mini(6, timeline.size())
        for i in range(limit):
            var row_var: Variant = timeline[i]
            if not (row_var is Dictionary):
                continue
            var row: Dictionary = row_var
            lines.append("- R%d %s -> %s (slot %d)" % [
                int(row.get("room_index", 0)),
                str(row.get("chapter_id", "chapter")),
                _route_style_label_for_id(str(row.get("style_id", "neutral"))),
                int(row.get("selected_slot", 0)) + 1
            ])
        if timeline.size() > limit:
            lines.append("... +%d more" % (timeline.size() - limit))
    else:
        lines.append("Locks: none (all chapters remained NEUTRAL)")

    return "\n".join(PackedStringArray(lines))


func _route_style_label_for_id(style_id: String) -> String:
    match style_id:
        "vanguard":
            return "VANGUARD"
        "raider":
            return "RAIDER"
        _:
            return "NEUTRAL"


func _build_chapter_effect_timeline_summary(raw_timeline: Variant, mode: String) -> String:
    if not (raw_timeline is Array):
        return "Chapter Effect Timeline (%s): none" % mode.to_upper()

    var timeline: Array = raw_timeline
    if timeline.is_empty():
        return "Chapter Effect Timeline (%s): none" % mode.to_upper()

    var counts: Dictionary = _count_timeline_modes(timeline)
    var lines: Array[String] = [
        _build_timeline_mode_header(mode),
        "Segments -> BOON:%d  CURSE:%d  MIXED:%d" % [
            int(counts.get("boon", 0)),
            int(counts.get("curse", 0)),
            int(counts.get("mixed", 0))
        ]
    ]
    var display_limit: int = 8
    var shown: int = 0
    var matched_total: int = 0
    for i in range(timeline.size()):
        var item: Variant = timeline[i]
        if not (item is Dictionary):
            continue

        var row: Dictionary = item
        if not _timeline_row_matches_mode(row, mode):
            continue
        matched_total += 1

        var room_index: int = int(row.get("room_index", 0))
        var chapter_id: String = str(row.get("chapter_id", "chapter"))
        var icon: String = str(row.get("icon", "[~]"))
        var title: String = str(row.get("title", "Chapter Effect"))
        var duration_rooms: int = int(row.get("duration_rooms", 1))
        var desc: String = str(row.get("desc", ""))

        var body: String = "- R%d %s %s %s (%dR)" % [room_index, chapter_id, icon, title, duration_rooms]
        if desc != "":
            body += " | %s" % desc
        lines.append(body)
        shown += 1
        if shown >= display_limit:
            break

    if shown == 0:
        lines.append("- none under current filter")
    elif matched_total > shown:
        lines.append("... +%d more" % (matched_total - shown))

    return "\n".join(PackedStringArray(lines))


func _build_grouped_timeline_summary(raw_timeline: Variant, mode: String) -> String:
    if not (raw_timeline is Array):
        return "Chapter Effect Timeline (%s): none" % mode.to_upper()

    var timeline: Array = raw_timeline
    if timeline.is_empty():
        return "Chapter Effect Timeline (%s): none" % mode.to_upper()

    var counts: Dictionary = _count_timeline_modes(timeline)
    var grouped: Dictionary = {}
    var filtered_rows: Array = []

    for item: Variant in timeline:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        if not _timeline_row_matches_mode(row, mode):
            continue
        filtered_rows.append(row)
        var chapter_id: String = str(row.get("chapter_id", "chapter_unknown"))
        if not grouped.has(chapter_id):
            grouped[chapter_id] = []
        (grouped[chapter_id] as Array).append(row)

    var lines: Array[String] = [
        _build_timeline_mode_header(mode),
        "Segments -> BOON:%d  CURSE:%d  MIXED:%d" % [
            int(counts.get("boon", 0)),
            int(counts.get("curse", 0)),
            int(counts.get("mixed", 0))
        ],
        "View: Grouped by chapter (collapsed preview)"
    ]

    if filtered_rows.is_empty():
        lines.append("- none under current filter")
        return "\n".join(PackedStringArray(lines))

    var chapter_order: Array[String] = _grouped_chapter_order
    if chapter_order.is_empty():
        chapter_order = ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]
    var anchor_id: String = _get_active_grouped_chapter_id()
    if _grouped_anchor_only_scope and anchor_id != "":
        chapter_order = [anchor_id]
    var faction_tag: String = _get_ending_faction_tag(_current_ending_id)

    var total_lines_limit: int = 12
    var emitted_rows: int = 0
    for chapter_id_var: Variant in chapter_order:
        var chapter_id: String = str(chapter_id_var)
        if not grouped.has(chapter_id):
            continue
        var chapter_rows: Array = grouped[chapter_id]
        if chapter_rows.is_empty():
            continue

        var is_anchor: bool = chapter_id == anchor_id
        lines.append("")
        lines.append("%s%s [%s] (%d)" % ["> " if is_anchor else "  ", faction_tag, _chapter_anchor_title(chapter_id), chapter_rows.size()])

        var chapter_limit: int = mini(4 if is_anchor else 1, chapter_rows.size())
        for i in range(chapter_limit):
            var row: Dictionary = chapter_rows[i]
            lines.append(_format_timeline_row(row, "    - "))
            emitted_rows += 1
            if emitted_rows >= total_lines_limit:
                break

        if chapter_rows.size() > chapter_limit:
            lines.append("    ... +%d more" % (chapter_rows.size() - chapter_limit))

        if emitted_rows >= total_lines_limit:
            lines.append("... timeline preview truncated")
            break

    return "\n".join(PackedStringArray(lines))


func _format_timeline_row(row: Dictionary, prefix: String) -> String:
    var room_index: int = int(row.get("room_index", 0))
    var icon: String = str(row.get("icon", "[~]"))
    var title: String = str(row.get("title", "Chapter Effect"))
    var duration_rooms: int = int(row.get("duration_rooms", 1))
    var desc: String = str(row.get("desc", ""))

    var body: String = "%sR%d %s %s (%dR)" % [prefix, room_index, icon, title, duration_rooms]
    if desc != "":
        body += " | %s" % desc
    return body


func _build_timeline_mode_header(mode: String) -> String:
    var tag: String = _get_timeline_mode_tag(mode)
    match mode:
        "boon":
            return "%s Chapter Effect Timeline: Blessing Route" % tag
        "curse":
            return "%s Chapter Effect Timeline: Burden Route" % tag
        "mixed":
            return "%s Chapter Effect Timeline: Hybrid Route" % tag
        _:
            return "%s Chapter Effect Timeline: Full Replay" % tag


func _count_timeline_modes(timeline: Array) -> Dictionary:
    var counts: Dictionary = {
        "boon": 0,
        "curse": 0,
        "mixed": 0
    }
    for item: Variant in timeline:
        if not (item is Dictionary):
            continue
        var mode: String = _resolve_timeline_row_mode(item)
        counts[mode] = int(counts.get(mode, 0)) + 1
    return counts


func _rebuild_grouped_chapter_order(mode: String) -> void:
    var previous_anchor_id: String = _get_active_grouped_chapter_id()

    var preferred: Array[String] = ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]
    var dynamic: Array[String] = []
    for item: Variant in _timeline_rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        if not _timeline_row_matches_mode(row, mode):
            continue
        var chapter_id: String = str(row.get("chapter_id", "chapter_unknown"))
        if chapter_id == "":
            chapter_id = "chapter_unknown"
        if not dynamic.has(chapter_id):
            dynamic.append(chapter_id)

    _grouped_chapter_order.clear()
    for chapter_id_var: Variant in preferred:
        var chapter_id: String = str(chapter_id_var)
        if dynamic.has(chapter_id):
            _grouped_chapter_order.append(chapter_id)

    var overflow: Array[String] = []
    for chapter_id_var: Variant in dynamic:
        var chapter_id: String = str(chapter_id_var)
        if not _grouped_chapter_order.has(chapter_id):
            overflow.append(chapter_id)
    overflow.sort()
    for chapter_id_var: Variant in overflow:
        _grouped_chapter_order.append(str(chapter_id_var))

    if _grouped_chapter_order.is_empty():
        _grouped_anchor_index = 0
        return

    if previous_anchor_id != "" and _grouped_chapter_order.has(previous_anchor_id):
        _grouped_anchor_index = _grouped_chapter_order.find(previous_anchor_id)
    else:
        _grouped_anchor_index = clampi(_grouped_anchor_index, 0, _grouped_chapter_order.size() - 1)


func _shift_grouped_anchor(step: int) -> void:
    if not _timeline_grouped_view or _grouped_chapter_order.is_empty():
        return
    _grouped_anchor_index = posmod(_grouped_anchor_index + step, _grouped_chapter_order.size())
    _refresh_timeline_view()


func _get_active_grouped_chapter_id() -> String:
    if _grouped_chapter_order.is_empty():
        return ""
    var safe_index: int = clampi(_grouped_anchor_index, 0, _grouped_chapter_order.size() - 1)
    return _grouped_chapter_order[safe_index]


func _chapter_anchor_title(chapter_id: String) -> String:
    if chapter_id.begins_with("chapter_"):
        var suffix: String = chapter_id.trim_prefix("chapter_")
        if suffix.is_valid_int():
            return "CH%s" % suffix
    if chapter_id == "":
        return ""
    return chapter_id.to_upper()


func _resolve_timeline_row_mode(row: Dictionary) -> String:
    var score: float = _timeline_row_score(row)
    if score >= 0.25:
        return "boon"
    if score <= -0.25:
        return "curse"
    return "mixed"


func _timeline_row_score(row: Dictionary) -> float:
    if row.has("score"):
        return float(row.get("score", 0.0))

    var icon: String = str(row.get("icon", "[~]"))
    if icon == "[+]":
        return 1.0
    if icon == "[-]":
        return -1.0
    return 0.0


func _timeline_row_matches_mode(row: Dictionary, mode: String) -> bool:
    if mode == "all":
        return true

    var score: float = _timeline_row_score(row)

    if mode == "boon":
        return score >= 0.25
    if mode == "curse":
        return score <= -0.25
    if mode == "mixed":
        return score > -0.25 and score < 0.25
    return true


func _get_timeline_mode_tag(mode: String) -> String:
    var row: Dictionary = _get_timeline_theme(mode)
    return str(row.get("tag", "[ALL]"))


func _apply_timeline_filter_theme(mode: String) -> void:
    var row: Dictionary = _get_timeline_theme(mode)
    var tint: Color = row.get("tint", TIMELINE_FILTER_THEME["all"]["tint"])
    if _effects_timeline_label != null:
        _effects_timeline_label.modulate = tint
    if _timeline_filter_button != null:
        _timeline_filter_button.modulate = tint
    if _timeline_view_button != null:
        _timeline_view_button.modulate = tint
    if _timeline_scope_button != null:
        _timeline_scope_button.modulate = tint


func _apply_anchor_faction_theme() -> void:
    var theme: Dictionary = _get_ending_faction_theme(_current_ending_id)
    var tint: Color = theme.get("tint", ENDING_FACTION_THEME["default"]["tint"])
    if _timeline_anchor_button != null:
        _timeline_anchor_button.modulate = tint


func _get_timeline_theme(mode: String) -> Dictionary:
    if TIMELINE_FILTER_THEME.has(mode):
        return TIMELINE_FILTER_THEME[mode]
    return TIMELINE_FILTER_THEME["all"]


func _get_ending_faction_theme(ending_id: String) -> Dictionary:
    if ENDING_FACTION_THEME.has(ending_id):
        return ENDING_FACTION_THEME[ending_id]
    return ENDING_FACTION_THEME["default"]


func _get_ending_faction_tag(ending_id: String) -> String:
    var row: Dictionary = _get_ending_faction_theme(ending_id)
    return str(row.get("tag", "[ARCHIVE]"))
