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
    var difficulty_label: String = str(run_result.get("difficulty_label", "")).strip_edges()
    if difficulty_label != "":
        _summary_label.text += " | Diff %s" % difficulty_label
    var difficulty_summary: String = str(run_result.get("difficulty_summary", "")).strip_edges()
    if difficulty_summary != "":
        _summary_label.text += " | %s" % difficulty_summary
    var meta_return_summary: String = str(run_result.get("meta_return_summary", "")).strip_edges()
    if meta_return_summary != "":
        _summary_label.text += " | %s" % meta_return_summary

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
        var payoff_var: Variant = run_result.get("ending_payoff", {})
        if payoff_var is Dictionary and not (payoff_var as Dictionary).is_empty():
            var payoff: Dictionary = payoff_var
            ending_body += "\n\nPayoff: %s\n%s" % [
                str(payoff.get("title", "Final Payoff")),
                str(payoff.get("summary", ""))
            ]
            var payoff_arc_id: String = str(payoff.get("arc_id", "")).strip_edges().to_upper()
            var payoff_style_echo: String = str(payoff.get("style_echo", "")).strip_edges()
            if payoff_arc_id != "" or payoff_style_echo != "":
                var payoff_route_parts: PackedStringArray = PackedStringArray()
                if payoff_arc_id != "":
                    payoff_route_parts.append(payoff_arc_id)
                if payoff_style_echo != "":
                    payoff_route_parts.append(payoff_style_echo)
                ending_body += "\nRoute Echo: %s" % " | ".join(payoff_route_parts)
            var legacy: String = str(payoff.get("legacy", "")).strip_edges()
            if legacy != "":
                ending_body += "\nLegacy: %s" % legacy
            var fragment_hook: String = str(payoff.get("fragment_hook", "")).strip_edges()
            if fragment_hook != "":
                ending_body += "\nFragment Hook: %s" % fragment_hook
            ending_body += "\nReview Entry: Ending Archive -> Current Ending"
        if epilogue != "":
            ending_body += "\n\nEpilogue: %s" % epilogue
            ending_body += "\nEpilogue Review Entry: Ending Archive -> Current Ending"
        var epilogue_chain_var: Variant = run_result.get("ending_epilogue_chain", [])
        if epilogue_chain_var is Array and not (epilogue_chain_var as Array).is_empty():
            var chain_rows: Array[String] = []
            for item: Variant in epilogue_chain_var:
                var text: String = str(item).strip_edges()
                if text != "":
                    chain_rows.append("- %s" % text)
            if not chain_rows.is_empty():
                ending_body += "\n\nEpilogue Chain:\n%s" % "\n".join(PackedStringArray(chain_rows))
                ending_body += "\nChain Review Entry: Ending Archive -> Current Ending"
        var epilogue_branch_var: Variant = run_result.get("epilogue_branch", {})
        if epilogue_branch_var is Dictionary and not (epilogue_branch_var as Dictionary).is_empty():
            var epilogue_branch: Dictionary = epilogue_branch_var
            ending_body += "\n\nEpilogue Branch: %s [%s]" % [
                str(epilogue_branch.get("title", "Archive Branch")),
                _get_branch_mode_label(str(epilogue_branch.get("branch_key", "")))
            ]
            var branch_body: String = str(epilogue_branch.get("body", "")).strip_edges()
            if branch_body != "":
                ending_body += "\n%s" % branch_body
            var branch_style_echo: String = str(epilogue_branch.get("style_echo", "")).strip_edges()
            if branch_style_echo != "":
                ending_body += "\nBranch Echo: %s" % branch_style_echo
            var archive_hook: String = str(epilogue_branch.get("archive_hook", "")).strip_edges()
            if archive_hook != "":
                ending_body += "\nArchive Hook: %s" % archive_hook
            ending_body += "\nReview Entry: Ending Archive -> Current Ending"
        _ending_label.text = ending_body
    else:
        _ending_label.text = "No ending unlocked in this run"

    var burst_rows: Array[String] = []
    burst_rows.append_array(_build_achievement_unlock_rows(_as_string_array(run_result.get("new_achievements", []))))
    burst_rows.append_array(_build_codex_unlock_rows(run_result.get("new_codex_unlocks", [])))
    burst_rows.append_array(_build_difficulty_unlock_rows(run_result.get("new_difficulty_unlocks", [])))
    burst_rows.append_array(_build_meta_return_unlock_rows(run_result.get("new_meta_return_unlocks", [])))
    if not burst_rows.is_empty():
        lines.append("Burst Unlocks:\n%s" % "\n".join(PackedStringArray(burst_rows)))

    if meta_return_summary != "" or str(run_result.get("meta_return_next_hint", "")).strip_edges() != "":
        var meta_rows: Array[String] = []
        if meta_return_summary != "":
            meta_rows.append(meta_return_summary)
        var meta_return_next_hint: String = str(run_result.get("meta_return_next_hint", "")).strip_edges()
        if meta_return_next_hint != "":
            meta_rows.append(meta_return_next_hint)
        lines.append("Meta Return:\n%s" % "\n".join(PackedStringArray(meta_rows)))

    var fragment_recap_var: Variant = run_result.get("fragment_recap", {})
    if fragment_recap_var is Dictionary and not (fragment_recap_var as Dictionary).is_empty():
        var recap_rows: Array[String] = _build_fragment_recap_rows(fragment_recap_var as Dictionary)
        if not recap_rows.is_empty():
            lines.append("Fragment Recap:\n%s" % "\n".join(PackedStringArray(recap_rows)))

    var hidden_layer_hook_var: Variant = run_result.get("hidden_layer_hook", {})
    if hidden_layer_hook_var is Dictionary and not (hidden_layer_hook_var as Dictionary).is_empty():
        var hook_rows: Array[String] = _build_hidden_layer_rows(hidden_layer_hook_var as Dictionary)
        if not hook_rows.is_empty():
            lines.append("Hidden Route:\n%s" % "\n".join(PackedStringArray(hook_rows)))

    var hidden_layer_statuses_var: Variant = run_result.get("hidden_layer_statuses", {})
    if hidden_layer_statuses_var is Dictionary and not (hidden_layer_statuses_var as Dictionary).is_empty():
        var hidden_layer_rows: Array[String] = _build_hidden_layer_status_rows(
            hidden_layer_statuses_var as Dictionary,
            _as_string_array(run_result.get("new_hidden_layers", []))
        )
        if not hidden_layer_rows.is_empty():
            lines.append("Hidden Layers:\n%s" % "\n".join(PackedStringArray(hidden_layer_rows)))

    var hidden_layer_id: String = str(run_result.get("hidden_layer_id", "")).strip_edges().to_upper()
    if hidden_layer_id != "":
        var clear_rows: Array[String] = []
        clear_rows.append("%s completion archived" % hidden_layer_id)
        var hidden_reward_summary: String = str(run_result.get("hidden_layer_reward_summary", "")).strip_edges()
        if hidden_reward_summary != "":
            clear_rows.append("Reward Cache: %s" % hidden_reward_summary)
        var hidden_layer_gameplay_var: Variant = run_result.get("hidden_layer_gameplay", {})
        if hidden_layer_gameplay_var is Dictionary and not (hidden_layer_gameplay_var as Dictionary).is_empty():
            var hidden_layer_gameplay: Dictionary = hidden_layer_gameplay_var as Dictionary
            var gameplay_rows: Array[String] = _build_hidden_layer_clear_gameplay_rows(hidden_layer_id, hidden_layer_gameplay)
            for gameplay_row: String in gameplay_rows:
                clear_rows.append(gameplay_row)
        var hidden_layer_story_var: Variant = run_result.get("hidden_layer_story", {})
        if hidden_layer_story_var is Dictionary and not (hidden_layer_story_var as Dictionary).is_empty():
            var hidden_layer_story: Dictionary = hidden_layer_story_var as Dictionary
            clear_rows.append("Story: %s" % str(hidden_layer_story.get("title", "Hidden Archive")))
            var story_body: String = str(hidden_layer_story.get("body", "")).strip_edges()
            if story_body != "":
                clear_rows.append(story_body)
            var story_arc_id: String = str(hidden_layer_story.get("arc_id", "")).strip_edges().to_upper()
            var story_style_echo: String = str(hidden_layer_story.get("style_echo", "")).strip_edges()
            if story_arc_id != "" or story_style_echo != "":
                var story_route_parts: PackedStringArray = PackedStringArray()
                if story_arc_id != "":
                    story_route_parts.append(story_arc_id)
                if story_style_echo != "":
                    story_route_parts.append(story_style_echo)
                clear_rows.append("Route Echo: %s" % " | ".join(story_route_parts))
            var story_ending_id: String = str(hidden_layer_story.get("ending_id", hidden_layer_story.get("ending_link", ""))).strip_edges()
            if story_ending_id != "":
                clear_rows.append("Ending Link: %s [%s]" % [
                    story_ending_id.trim_prefix("nar_ending_").to_upper(),
                    "READY" if bool(hidden_layer_story.get("ending_ready", false)) else "TRACKING"
                ])
            var archive_echo: String = str(hidden_layer_story.get("archive_echo", "")).strip_edges()
            if archive_echo != "":
                clear_rows.append("Archive Echo: %s" % archive_echo)
            var fragment_title: String = str(hidden_layer_story.get("fragment_title", hidden_layer_story.get("fragment_id", ""))).strip_edges()
            if fragment_title != "":
                clear_rows.append("Fragment Archive: %s [%s]" % [
                    fragment_title,
                    "NEW" if bool(hidden_layer_story.get("fragment_newly_unlocked", false)) else "ECHO"
                ])
            var fragment_text: String = str(hidden_layer_story.get("fragment_text", "")).strip_edges()
            if fragment_text != "":
                clear_rows.append("Fragment Text: %s" % fragment_text)
            clear_rows.append("Review Entry: Memory Altar -> Hidden Layer Track")
        var hidden_layer_record_var: Variant = run_result.get("hidden_layer_record", {})
        if hidden_layer_record_var is Dictionary and not (hidden_layer_record_var as Dictionary).is_empty():
            var hidden_layer_record: Dictionary = hidden_layer_record_var as Dictionary
            clear_rows.append("Archive Stats: attempts=%d | clears=%d | best_rooms=%d" % [
                int(hidden_layer_record.get("attempts", 0)),
                int(hidden_layer_record.get("clears", 0)),
                int(hidden_layer_record.get("best_rooms_cleared", 0))
            ])
        lines.append("Hidden Layer Clear:\n%s" % "\n".join(PackedStringArray(clear_rows)))

    var challenge_layer_id: String = str(run_result.get("challenge_layer_id", "")).strip_edges().to_upper()
    if challenge_layer_id != "":
        var challenge_rows: Array[String] = []
        challenge_rows.append("%s -> %s" % [challenge_layer_id, str(run_result.get("challenge_layer_title", "Challenge Layer"))])
        var challenge_phase: String = str(run_result.get("challenge_layer_phase", "")).strip_edges()
        if challenge_phase != "":
            challenge_rows.append("Phase: %s" % challenge_phase.capitalize())
        var challenge_reward_title: String = str(run_result.get("challenge_layer_reward_title", "")).strip_edges()
        if challenge_reward_title != "":
            challenge_rows.append("Reward Choice: %s" % challenge_reward_title)
        var challenge_reward_payload_var: Variant = run_result.get("challenge_layer_reward_payload", {})
        if challenge_reward_payload_var is Dictionary and not (challenge_reward_payload_var as Dictionary).is_empty():
            var challenge_reward_payload: Dictionary = challenge_reward_payload_var as Dictionary
            challenge_rows.append("Selected Reward Detail: Meta +%d | Sigil +%d | Insight +%d" % [
                int(challenge_reward_payload.get("meta_bonus", 0)),
                int(challenge_reward_payload.get("sigils", 0)),
                int(challenge_reward_payload.get("insight", 0))
            ])
        var challenge_settlement_summary: String = str(run_result.get("challenge_layer_settlement_summary", "")).strip_edges()
        if challenge_settlement_summary != "":
            challenge_rows.append("Settlement: %s" % challenge_settlement_summary)
        var challenge_difficulty_summary: String = str(run_result.get("difficulty_summary", "")).strip_edges()
        if challenge_difficulty_summary != "":
            challenge_rows.append("Difficulty tuning: %s" % challenge_difficulty_summary)
        var challenge_reward_summary: String = str(run_result.get("challenge_layer_reward_summary", "")).strip_edges()
        if challenge_reward_summary != "":
            challenge_rows.append(challenge_reward_summary)
        var challenge_rooms_cleared: int = int(run_result.get("challenge_layer_rooms_cleared", 0))
        var challenge_kills: int = int(run_result.get("challenge_layer_kills", 0))
        if challenge_rooms_cleared > 0 or challenge_kills > 0:
            challenge_rows.append("Run Stats: rooms=%d | kills=%d" % [challenge_rooms_cleared, challenge_kills])
        var challenge_record_var: Variant = run_result.get("challenge_layer_record", {})
        if challenge_record_var is Dictionary and not (challenge_record_var as Dictionary).is_empty():
            var challenge_record: Dictionary = challenge_record_var as Dictionary
            challenge_rows.append("Archive Stats: attempts=%d | clears=%d | best_rooms=%d | best_kills=%d" % [
                int(challenge_record.get("attempts", 0)),
                int(challenge_record.get("clears", 0)),
                int(challenge_record.get("best_rooms", 0)),
                int(challenge_record.get("best_kills", 0))
            ])
            challenge_rows.append("Reward Ledger: Meta +%d | Sigil +%d | Insight +%d" % [
                int(challenge_record.get("total_meta_bonus", 0)),
                int(challenge_record.get("total_sigils", 0)),
                int(challenge_record.get("total_insight", 0))
            ])
            var last_reward_title: String = str(challenge_record.get("last_reward_title", "")).strip_edges()
            if last_reward_title != "":
                challenge_rows.append("Last Reward: %s" % last_reward_title)
        lines.append("Challenge Layer:\n%s" % "\n".join(PackedStringArray(challenge_rows)))

    var fragment_triggers_var: Variant = run_result.get("fragment_triggers", [])
    if fragment_triggers_var is Array and not (fragment_triggers_var as Array).is_empty():
        var fragment_lines: Array[String] = []
        for item: Variant in fragment_triggers_var:
            if not (item is Dictionary):
                continue
            var row: Dictionary = item
            var title: String = str(row.get("fragment_title", row.get("fragment_id", "memory"))).strip_edges()
            if title == "":
                continue
            var prefix: String = "Echoed"
            if bool(row.get("newly_unlocked", false)):
                prefix = "Unlocked"
            fragment_lines.append("%s: %s [%s/%s]" % [
                prefix,
                title,
                str(row.get("chapter_id", "chapter")),
                str(row.get("trigger_type", "trigger"))
            ])
        if not fragment_lines.is_empty():
            lines.append("Fragments:\n%s" % "\n".join(PackedStringArray(fragment_lines)))

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


func _get_branch_mode_label(branch_key: String) -> String:
    match branch_key:
        "first_unlock":
            return "FIRST"
        "repeat_unlock":
            return "REPEAT"
        _:
            return "ARCHIVE"


func _build_fragment_recap_rows(recap: Dictionary) -> Array[String]:
    var rows: Array[String] = []
    rows.append("%s - %s" % [
        str(recap.get("title", "Archive Recap")),
        str(recap.get("summary", ""))
    ])

    var route_parts: PackedStringArray = PackedStringArray()
    var arc_id: String = str(recap.get("arc_id", "")).strip_edges().to_upper()
    var style_echo: String = str(recap.get("style_echo", "")).strip_edges()
    if arc_id != "":
        route_parts.append(arc_id)
    if style_echo != "":
        route_parts.append(style_echo)
    if not route_parts.is_empty():
        rows.append("Route Echo: %s" % " | ".join(route_parts))

    var pace_hint: String = str(recap.get("pace_hint", "")).strip_edges()
    if pace_hint != "":
        rows.append("Pace Hint: %s" % pace_hint)

    rows.append("Recap Stats: triggers=%d | new=%d" % [
        int(recap.get("trigger_count", 0)),
        int(recap.get("new_unlock_count", 0))
    ])

    var trigger_types_var: Variant = recap.get("trigger_types", [])
    if trigger_types_var is Array and not (trigger_types_var as Array).is_empty():
        var trigger_types: PackedStringArray = PackedStringArray()
        for item: Variant in trigger_types_var:
            var text: String = str(item).strip_edges()
            if text != "":
                trigger_types.append(text.to_upper())
        if not trigger_types.is_empty():
            rows.append("Trigger Focus: %s" % ", ".join(trigger_types))

    rows.append("Review Entry: Memory Altar -> Archive Recap")

    return rows


func _build_hidden_layer_rows(hook: Dictionary) -> Array[String]:
    var rows: Array[String] = []
    rows.append("%s -> %s [%s]" % [
        str(hook.get("target_layer", "FS?")),
        str(hook.get("title", "Unknown Hook")),
        "READY" if bool(hook.get("ready", false)) else "TRACKING"
    ])

    var teaser: String = str(hook.get("teaser", "")).strip_edges()
    if teaser != "":
        rows.append("Teaser: %s" % teaser)

    var unlock_hint: String = str(hook.get("unlock_hint", "")).strip_edges()
    if unlock_hint != "":
        rows.append("Unlock Hint: %s" % unlock_hint)

    var hook_arc_id: String = str(hook.get("arc_id", "")).strip_edges().to_upper()
    var hook_style_echo: String = str(hook.get("style_echo", "")).strip_edges()
    if hook_arc_id != "" or hook_style_echo != "":
        var route_parts: PackedStringArray = PackedStringArray()
        if hook_arc_id != "":
            route_parts.append(hook_arc_id)
        if hook_style_echo != "":
            route_parts.append(hook_style_echo)
        rows.append("Route Echo: %s" % " | ".join(route_parts))

    rows.append("Review Entry: Memory Altar -> Hidden Route Lead")

    return rows


func _build_achievement_unlock_rows(achievement_ids: Array[String]) -> Array[String]:
    var rows: Array[String] = []
    for achievement_id: String in achievement_ids:
        var normalized_id: String = achievement_id.strip_edges()
        if normalized_id == "":
            continue
        rows.append("Achievement: %s" % _get_achievement_title(normalized_id))
    return rows


func _build_codex_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var category: String = str(row.get("category", "")).strip_edges().to_lower()
        var entry_id: String = str(row.get("entry_id", "")).strip_edges()
        if category == "" or entry_id == "":
            continue
        var line: String = "Codex: [%s] %s" % [
            _get_codex_category_label(category),
            _get_codex_entry_title(category, entry_id)
        ]
        var source: String = str(row.get("source", "")).strip_edges()
        if source != "":
            line += " (%s)" % _get_codex_source_label(source)
        rows.append(line)
    return rows


func _build_difficulty_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var label: String = str(row.get("label", _prettify_id(str(row.get("tier", ""))))).strip_edges()
        if label == "":
            continue
        rows.append("Difficulty: %s unlocked" % label)
    return rows


func _build_meta_return_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var label: String = str(row.get("label", "")).strip_edges()
        if label == "":
            continue
        var line: String = "Meta Return: %s" % label
        var bonus_text: String = str(row.get("bonus_text", "")).strip_edges()
        if bonus_text != "":
            line += " (%s)" % bonus_text
        rows.append(line)
    return rows


func _build_hidden_layer_status_rows(status_rows: Dictionary, new_hidden_layers: Array[String]) -> Array[String]:
    var rows: Array[String] = []
    for layer_id: String in ["FS1", "FS2"]:
        var row_var: Variant = status_rows.get(layer_id, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var state_label: String = "UNLOCKED" if bool(row.get("unlocked", false)) else "LOCKED"
        if new_hidden_layers.has(layer_id):
            state_label = "NEW"
        rows.append("%s -> %s [%s]" % [
            layer_id,
            str(row.get("title", layer_id)),
            state_label
        ])
        rows.append("Progress: %s" % str(row.get("progress_label", "No progress")))
        var detail: String = str(row.get("detail", "")).strip_edges()
        if detail != "":
            rows.append("Rule: %s" % detail)
        var entry_hint: String = str(row.get("entry_hint", "")).strip_edges()
        if entry_hint != "":
            rows.append("Entry: %s" % entry_hint)
        var reward_summary: String = str(row.get("reward_summary", "")).strip_edges()
        if reward_summary != "":
            rows.append("Reward: %s" % reward_summary)
        var settlement_summary: String = str(row.get("settlement_summary", "")).strip_edges()
        if settlement_summary != "":
            rows.append("Settlement: %s" % settlement_summary)
        var record_label: String = str(row.get("record_label", "")).strip_edges()
        if record_label != "":
            rows.append("Record: %s" % record_label)
        var story_label: String = str(row.get("story_label", "")).strip_edges()
        if story_label != "":
            rows.append("Archive: %s" % story_label)
        var gameplay_label: String = str(row.get("gameplay_label", "")).strip_edges()
        if gameplay_label != "":
            rows.append("Gameplay: %s" % gameplay_label)
        var collection_label: String = str(row.get("collection_label", "")).strip_edges()
        if collection_label != "":
            rows.append("Collection: %s" % collection_label)
        var mastery_label: String = str(row.get("mastery_label", "")).strip_edges()
        if mastery_label != "":
            rows.append("Mastery: %s" % mastery_label)
    if not rows.is_empty():
        rows.append("Review Entry: Memory Altar -> Hidden Layer Track")
    return rows


func _build_hidden_layer_clear_gameplay_rows(layer_id: String, gameplay: Dictionary) -> Array[String]:
    var rows: Array[String] = []
    match layer_id:
        "FS1":
            var parts: Array[String] = []
            var pressure_label: String = str(gameplay.get("pressure_label", "Rift Surge")).strip_edges()
            var pressure_stage: int = int(gameplay.get("pressure_stage", 0))
            var required_stage: int = int(gameplay.get("required_pressure_stage", 0))
            if pressure_stage > 0 or required_stage > 0:
                parts.append("%s %d/%d" % [pressure_label, pressure_stage, maxi(required_stage, pressure_stage)])
            var survival_seconds: float = float(gameplay.get("survival_seconds", 0.0))
            if survival_seconds > 0.0:
                parts.append("Hold %.1fs" % survival_seconds)
            var echo_title: String = str(gameplay.get("boss_echo_title", gameplay.get("boss_echo_id", ""))).strip_edges()
            if echo_title != "":
                parts.append("Echo %s" % echo_title)
            if not parts.is_empty():
                rows.append("Pressure: %s" % " | ".join(PackedStringArray(parts)))
            var echo_collection: Array[String] = _as_string_array(gameplay.get("boss_echo_collection", []))
            if not echo_collection.is_empty():
                var echo_titles: Array[String] = []
                for boss_id: String in echo_collection:
                    var echo_title_item: String = str(gameplay.get("boss_echo_title", "")).strip_edges() if boss_id == str(gameplay.get("boss_echo_id", "")).strip_edges() else _get_boss_echo_title(boss_id)
                    if echo_title_item != "":
                        echo_titles.append(echo_title_item)
                var collection_text: String = "Echoes %d/4" % echo_collection.size()
                if not echo_titles.is_empty():
                    collection_text += " | %s" % ", ".join(PackedStringArray(echo_titles))
                rows.append("Collection: %s" % collection_text)
            var mastery_label_fs1: String = str(gameplay.get("mastery_label", "")).strip_edges()
            if mastery_label_fs1 != "":
                rows.append("Mastery: %s" % mastery_label_fs1)
        "FS2":
            var trial_label: String = str(gameplay.get("trial_label", "")).strip_edges()
            if trial_label == "":
                var trial_depth: int = int(gameplay.get("trial_depth", 0))
                var trial_depth_max: int = maxi(trial_depth, int(gameplay.get("trial_depth_max", 0)))
                if trial_depth > 0:
                    trial_label = "Forge Trial %d/%d" % [trial_depth, maxi(1, trial_depth_max)]
            if trial_label != "":
                rows.append("Trial: %s" % trial_label)
            var trial_labels: Array[String] = _as_string_array(gameplay.get("trial_labels", []))
            if not trial_labels.is_empty():
                var deepest_label: String = str(gameplay.get("deepest_trial_label", trial_labels[trial_labels.size() - 1])).strip_edges()
                var collection_text: String = "Trials %d/%d" % [trial_labels.size(), maxi(1, int(gameplay.get("trial_depth_max", 5)))]
                if deepest_label != "":
                    collection_text += " | %s" % deepest_label
                rows.append("Collection: %s" % collection_text)
            var mastery_label_fs2: String = str(gameplay.get("mastery_label", "")).strip_edges()
            if mastery_label_fs2 != "":
                rows.append("Mastery: %s" % mastery_label_fs2)
    return rows


func _get_boss_echo_title(boss_id: String) -> String:
    match boss_id.strip_edges():
        "boss_rock_colossus":
            return "Rock Colossus"
        "boss_flame_lord":
            return "Flame Lord"
        "boss_frost_king":
            return "Frost King"
        "boss_void_lord":
            return "Void Lord"
        _:
            return ""


func _get_archive_codex_title(entry_id: String) -> String:
    match entry_id.strip_edges():
        "fs1_echo_archive":
            return "Time Rift Archive"
        "fs1_echo_mastery":
            return "Time Rift Mastery"
        "fs2_trial_archive":
            return "Genesis Forge Archive"
        "fs2_trial_mastery":
            return "Genesis Forge Mastery"
        "hard_clear_archive":
            return "Hard Archive"
        "nightmare_clear_archive":
            return "Nightmare Archive"
        "nightmare_hidden_archive":
            return "Nightmare Hidden Archive"
        _:
            return _prettify_id(entry_id)


func _get_achievement_title(achievement_id: String) -> String:
    var config: Dictionary = ConfigManager.get_config("achievements", {})
    var rows_var: Variant = config.get("achievements", [])
    if rows_var is Array:
        for item: Variant in rows_var:
            if not (item is Dictionary):
                continue
            var row: Dictionary = item
            if str(row.get("id", "")).strip_edges() == achievement_id:
                return str(row.get("title", achievement_id))
    return _prettify_id(achievement_id)


func _get_codex_category_label(category: String) -> String:
    match category.strip_edges().to_lower():
        "characters":
            return "Characters"
        "weapons":
            return "Weapons"
        "passives":
            return "Passives"
        "enemies":
            return "Enemies"
        "accessories":
            return "Accessories"
        "archives":
            return "Archives"
        _:
            return _prettify_id(category)


func _get_codex_entry_title(category: String, entry_id: String) -> String:
    match category.strip_edges().to_lower():
        "archives":
            return _get_archive_codex_title(entry_id)
        "enemies":
            var boss_title: String = _get_boss_echo_title(entry_id)
            if boss_title != "":
                return boss_title
            return _prettify_id(entry_id)
        _:
            return _prettify_id(entry_id)


func _get_codex_source_label(source: String) -> String:
    match source.strip_edges():
        "difficulty_clear":
            return "Difficulty Clear"
        "difficulty_hidden_clear":
            return "Nightmare Hidden Clear"
        "hidden_layer_clear":
            return "Hidden Layer Clear"
        "hidden_layer_mastery":
            return "Hidden Layer Mastery"
        "character_select":
            return "Character Selection"
        "run_start":
            return "Run Start"
        "level_up_choice":
            return "Level Up Choice"
        "enemy_kill":
            return "Enemy Defeat"
        "accessory_pickup":
            return "Accessory Pickup"
        _:
            return _prettify_id(source)


func _prettify_id(raw_id: String) -> String:
    var text: String = raw_id.strip_edges()
    if text.begins_with("char_") or text.begins_with("wpn_") or text.begins_with("acc_") or text.begins_with("enemy_"):
        var parts: PackedStringArray = text.split("_", false, 1)
        if parts.size() == 2:
            text = parts[1]
    text = text.replace("_", " ")
    return text.capitalize()


func _as_string_array(value: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (value is Array):
        return rows
    for item: Variant in value:
        rows.append(str(item).strip_edges())
    return rows


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
