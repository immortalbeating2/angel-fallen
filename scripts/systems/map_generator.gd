extends Node

const ROOM_TYPE_COMBAT: String = "combat"
const ROOM_TYPE_BOSS: String = "boss"
const ROOM_TYPE_EVENT: String = "event"
const ROOM_TYPE_SHOP: String = "shop"
const ROOM_TYPE_TREASURE: String = "treasure"
const ROOM_TYPE_SAFE_CAMP: String = "safe_camp"
const ROOM_TYPE_ELITE: String = "elite"

const ROLLABLE_ROOM_TYPES: Array[String] = [
    ROOM_TYPE_COMBAT,
    ROOM_TYPE_EVENT,
    ROOM_TYPE_SHOP,
    ROOM_TYPE_TREASURE,
    ROOM_TYPE_ELITE
]


func generate_run_plan(config: Dictionary) -> Dictionary:
    var room_count: int = maxi(8, int(config.get("room_count", 15)))
    var layout_cols: int = clampi(int(config.get("layout_cols", 5)), 3, 8)

    var chapter_order: Array[String] = []
    var chapter_order_var: Variant = config.get("chapter_order", [])
    if chapter_order_var is Array:
        for item: Variant in chapter_order_var:
            chapter_order.append(str(item))

    if chapter_order.is_empty():
        chapter_order = ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]

    var chapters: Dictionary = {}
    var chapters_var: Variant = config.get("chapters", {})
    if chapters_var is Dictionary:
        chapters = chapters_var

    var fixed_room_types: Dictionary = _extract_fixed_rooms(config.get("fixed_rooms", []))

    var base_weights: Dictionary = {
        ROOM_TYPE_COMBAT: 52.0,
        ROOM_TYPE_EVENT: 14.0,
        ROOM_TYPE_SHOP: 16.0,
        ROOM_TYPE_TREASURE: 8.0,
        ROOM_TYPE_ELITE: 12.0
    }
    var base_weight_var: Variant = config.get("base_room_weights", {})
    if base_weight_var is Dictionary:
        base_weights = _normalize_weights(base_weight_var, base_weights)

    var chapter_weight_mult: Dictionary = {}
    var chapter_mult_var: Variant = config.get("chapter_room_weight_mult", {})
    if chapter_mult_var is Dictionary:
        chapter_weight_mult = chapter_mult_var

    var constraints: Dictionary = {}
    var constraints_var: Variant = config.get("constraints", {})
    if constraints_var is Dictionary:
        constraints = constraints_var

    var max_consecutive_same_type: int = maxi(1, int(constraints.get("max_consecutive_same_type", 2)))
    var max_treasure_per_chapter: int = maxi(0, int(constraints.get("max_treasure_per_chapter", 1)))
    var max_room_type_per_chapter: Dictionary = _normalize_room_type_caps(constraints.get("max_room_type_per_chapter", {}))
    var min_room_type_per_chapter: Dictionary = _normalize_room_type_mins(constraints.get("min_room_type_per_chapter", {}))
    if not max_room_type_per_chapter.has(ROOM_TYPE_TREASURE):
        max_room_type_per_chapter[ROOM_TYPE_TREASURE] = max_treasure_per_chapter
    if not min_room_type_per_chapter.has(ROOM_TYPE_TREASURE):
        min_room_type_per_chapter[ROOM_TYPE_TREASURE] = 0
    var avoid_shop_near_boss: bool = bool(constraints.get("avoid_shop_near_boss", true))
    var avoid_event_near_boss: bool = bool(constraints.get("avoid_event_near_boss", true))

    var rooms: Array[Dictionary] = []
    var room_plan_map: Dictionary = {}
    var history_types: Array[String] = []
    var room_type_count_by_chapter: Dictionary = {}
    var chapter_rollable_slots: Dictionary = _build_chapter_rollable_slots(chapter_order, chapters, room_count, fixed_room_types, avoid_shop_near_boss, avoid_event_near_boss)
    var chapter_slot_cursor: Dictionary = {}

    # 主线 run plan 在逐房生成时同时满足固定房、章节权重、最小/最大类型约束和 Boss 邻近限制。
    for room_index in range(1, room_count + 1):
        var chapter_id: String = _resolve_chapter_id(room_index, chapter_order, chapters)
        var chapter_row: Dictionary = chapters.get(chapter_id, {})
        var chapter_index: int = int(chapter_row.get("index", _fallback_chapter_index(chapter_id)))
        var boss_room: int = int(chapter_row.get("boss_room", -1))
        var intro_room: int = int(chapter_row.get("intro_room", int(chapter_row.get("start_room", 1))))
        var boss_id: String = ""

        var room_type: String = ROOM_TYPE_COMBAT
        if room_index == 1:
            room_type = ROOM_TYPE_COMBAT
        elif room_index == boss_room:
            room_type = ROOM_TYPE_BOSS
            boss_id = str(chapter_row.get("boss_id", "boss_unknown"))
        elif fixed_room_types.has(room_index):
            room_type = str(fixed_room_types.get(room_index, ROOM_TYPE_COMBAT))
        else:
            var chapter_weights: Dictionary = _build_chapter_weights(chapter_id, base_weights, chapter_weight_mult)
            var chapter_weights_before_min: Dictionary = chapter_weights.duplicate(true)
            var chapter_type_counter: Dictionary = {}
            var chapter_type_counter_var: Variant = room_type_count_by_chapter.get(chapter_id, {})
            if chapter_type_counter_var is Dictionary:
                chapter_type_counter = chapter_type_counter_var

            for room_type_key in ROLLABLE_ROOM_TYPES:
                var cap_value: Variant = max_room_type_per_chapter.get(room_type_key, -1)
                var cap_count: int = int(cap_value)
                if cap_count < 0:
                    continue
                var current_count: int = int(chapter_type_counter.get(room_type_key, 0))
                if current_count >= cap_count:
                    chapter_weights[room_type_key] = 0.0
            if avoid_shop_near_boss and boss_room > 0 and room_index >= boss_room - 1:
                chapter_weights[ROOM_TYPE_SHOP] = 0.0
            if avoid_event_near_boss and boss_room > 0 and room_index >= boss_room - 1:
                chapter_weights[ROOM_TYPE_EVENT] = 0.0

            var chapter_slots: Array = []
            var chapter_slots_var: Variant = chapter_rollable_slots.get(chapter_id, [])
            if chapter_slots_var is Array:
                chapter_slots = chapter_slots_var

            var slot_cursor: int = int(chapter_slot_cursor.get(chapter_id, 0))
            var deficits: Dictionary = {}
            for room_type_key in ROLLABLE_ROOM_TYPES:
                var min_required: int = int(min_room_type_per_chapter.get(room_type_key, 0))
                if min_required <= 0:
                    continue
                var current_count: int = int(chapter_type_counter.get(room_type_key, 0))
                if current_count < min_required:
                    deficits[room_type_key] = min_required - current_count

            if not deficits.is_empty() and not chapter_slots.is_empty():
                var forced_types: Array[String] = _collect_forced_min_types(deficits, chapter_slots, slot_cursor)
                var remaining_slots: int = maxi(0, chapter_slots.size() - slot_cursor)
                var required_slots: int = 0
                for deficit_value in deficits.values():
                    required_slots += int(deficit_value)

                var restrict_types: Array[String] = forced_types.duplicate(true)
                if restrict_types.is_empty() and required_slots >= remaining_slots:
                    for deficit_key in deficits.keys():
                        restrict_types.append(str(deficit_key))

                if not restrict_types.is_empty():
                    # 当某类房间的最低配额快来不及补齐时，临时收紧候选池，优先把欠账的类型补回来。
                    var restricted_total: float = 0.0
                    for room_type_key in ROLLABLE_ROOM_TYPES:
                        if not restrict_types.has(room_type_key):
                            chapter_weights[room_type_key] = 0.0
                        else:
                            restricted_total += float(chapter_weights.get(room_type_key, 0.0))

                    if restricted_total <= 0.0:
                        chapter_weights = chapter_weights_before_min.duplicate(true)

            room_type = _roll_room_type(chapter_weights, history_types, max_consecutive_same_type)

            chapter_slot_cursor[chapter_id] = slot_cursor + 1

        if ROLLABLE_ROOM_TYPES.has(room_type):
            var chapter_type_counter: Dictionary = {}
            var chapter_type_counter_var: Variant = room_type_count_by_chapter.get(chapter_id, {})
            if chapter_type_counter_var is Dictionary:
                chapter_type_counter = chapter_type_counter_var.duplicate(true)
            chapter_type_counter[room_type] = int(chapter_type_counter.get(room_type, 0)) + 1
            room_type_count_by_chapter[chapter_id] = chapter_type_counter

        history_types.append(room_type)
        if history_types.size() > max_consecutive_same_type + 1:
            history_types.pop_front()

        var row: Dictionary = {
            "index": room_index,
            "room_type": room_type,
            "chapter_id": chapter_id,
            "chapter_index": chapter_index,
            "show_intro": room_index == intro_room,
            "boss_id": boss_id,
            "is_boss_room": room_type == ROOM_TYPE_BOSS,
            "next_rooms": [],
            "previous_rooms": []
        }
        rooms.append(row)
        room_plan_map[room_index] = row

    var graph: Dictionary = _build_room_graph(room_plan_map, chapter_order, chapters)
    _apply_room_graph(room_plan_map, graph)
    var map_bounds: Dictionary = _assign_map_coordinates(room_plan_map, chapter_order, chapters)

    var computed_cols: int = int(map_bounds.get("cols", layout_cols))
    if computed_cols > 0:
        layout_cols = maxi(layout_cols, computed_cols)

    var rebuilt_rooms: Array[Dictionary] = []
    for room_index in range(1, room_count + 1):
        var room_row_var: Variant = room_plan_map.get(room_index, {})
        if room_row_var is Dictionary:
            rebuilt_rooms.append((room_row_var as Dictionary).duplicate(true))

    return {
        "room_count": room_count,
        "layout_cols": layout_cols,
        "map_bounds": map_bounds,
        "chapter_order": chapter_order,
        "start_room": 1,
        "rooms": rebuilt_rooms,
        "room_plan_map": room_plan_map
    }


func get_hidden_layer_profiles(config: Dictionary = {}) -> Dictionary:
    var source: Dictionary = config
    if source.is_empty() and ConfigManager != null:
        source = ConfigManager.get_config("map_generation", {})
    var rows_var: Variant = source.get("hidden_layers", {})
    if rows_var is Dictionary:
        return (rows_var as Dictionary).duplicate(true)
    return {}


func get_hidden_layer_profile(layer_id: String, config: Dictionary = {}) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    var rows: Dictionary = get_hidden_layer_profiles(config)
    var row_var: Variant = rows.get(layer_key, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["layer_id"] = layer_key
    return row


func generate_hidden_layer_stub_plan(layer_id: String, config: Dictionary = {}) -> Dictionary:
    var profile: Dictionary = get_hidden_layer_profile(layer_id, config)
    if profile.is_empty():
        return {}

    var map_profile_var: Variant = profile.get("map_profile", {})
    if not (map_profile_var is Dictionary):
        return {}
    var map_profile: Dictionary = map_profile_var
    var mode: String = str(map_profile.get("mode", "")).strip_edges().to_lower()
    var room_count: int = int(map_profile.get("room_count", 0))
    var entry_room_type: String = str(map_profile.get("entry_room_type", "hidden_entry")).strip_edges()
    var encounter_room_type: String = str(map_profile.get("encounter_room_type", "hidden_room")).strip_edges()
    var boss_room_type: String = str(map_profile.get("boss_room_type", encounter_room_type)).strip_edges()
    var settlement_room_type: String = str(map_profile.get("settlement_room_type", "hidden_settlement")).strip_edges()
    var rooms: Array[Dictionary] = []

    match mode:
        "survival":
            rooms.append({
                "index": 1,
                "room_type": entry_room_type,
                "room_role": "entry",
                "next_rooms": [2],
                "previous_rooms": []
            })
            rooms.append({
                "index": 2,
                "room_type": encounter_room_type,
                "room_role": "survival_loop",
                "next_rooms": [2, 3],
                "previous_rooms": [1, 2],
                "is_loop_anchor": true,
                "boss_room_type": boss_room_type
            })
            rooms.append({
                "index": 3,
                "room_type": settlement_room_type,
                "room_role": "settlement",
                "next_rooms": [],
                "previous_rooms": [2]
            })
        "trial_chain":
            var room_roles: Array[String] = _as_string_array(map_profile.get("room_roles", []))
            var safe_room_count: int = maxi(1, room_count)
            for idx in range(safe_room_count):
                var room_role: String = "trial_%d" % [idx + 1]
                if idx < room_roles.size():
                    room_role = room_roles[idx]
                var room_type: String = encounter_room_type
                if idx == safe_room_count - 1:
                    room_type = boss_room_type
                rooms.append({
                    "index": idx + 1,
                    "room_type": room_type,
                    "room_role": room_role,
                    "next_rooms": ([] if idx == safe_room_count - 1 else [idx + 2]),
                    "previous_rooms": ([] if idx == 0 else [idx]),
                    "entry_room_type": entry_room_type,
                    "settlement_room_type": settlement_room_type
                })
        _:
            return {}

    return {
        "layer_id": str(profile.get("layer_id", layer_id)).strip_edges().to_upper(),
        "title": str(profile.get("title", layer_id)).strip_edges(),
        "theme": str(profile.get("theme", "")).strip_edges(),
        "map_mode": mode,
        "room_count": room_count,
        "room_count_label": str(map_profile.get("room_count_label", "")).strip_edges(),
        "entry_hint": str(profile.get("entrance_hint", "")).strip_edges(),
        "rooms": rooms,
        "combat_profile": (profile.get("combat_profile", {}) as Dictionary).duplicate(true) if profile.get("combat_profile", {}) is Dictionary else {},
        "reward_profile": (profile.get("reward_profile", {}) as Dictionary).duplicate(true) if profile.get("reward_profile", {}) is Dictionary else {},
        "settlement_profile": (profile.get("settlement_profile", {}) as Dictionary).duplicate(true) if profile.get("settlement_profile", {}) is Dictionary else {}
    }


func generate_hidden_layer_run_plan(layer_id: String, config: Dictionary = {}) -> Dictionary:
    var profile: Dictionary = get_hidden_layer_profile(layer_id, config)
    if profile.is_empty():
        return {}

    var layer_key: String = str(profile.get("layer_id", layer_id)).strip_edges().to_upper()
    match layer_key:
        "FS1":
            return _build_hidden_layer_run_plan_fs1(profile)
        "FS2":
            return _build_hidden_layer_run_plan_fs2(profile)
        _:
            return {}


func generate_challenge_layer_run_plan(layer_id: String, _config: Dictionary = {}) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    match layer_key:
        "CL1":
            pass
        "CL2":
            var chapter_id_cl2: String = "challenge_cl2"
            var chapter_index_cl2: int = 8
            var title_cl2: String = "Challenge Layer II"
            var rooms_cl2: Array[Dictionary] = [
                _build_hidden_layer_room(1, ROOM_TYPE_SAFE_CAMP, chapter_id_cl2, chapter_index_cl2, 0, 0, [2], [], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl2,
                    "challenge_phase": "entry",
                    "title": "Challenge Layer II Entry",
                    "objective": "Stabilize the deeper archive route and confirm the crucible checkpoint.",
                    "status_hint": "Press E to enter the archive crucible.",
                    "checkpoint_label": "Challenge Gate II",
                    "reward_summary": "Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2",
                    "settlement_summary": "The deeper challenge archive opens a broader postgame loop for later layers."
                }),
                _build_hidden_layer_room(2, ROOM_TYPE_ELITE, chapter_id_cl2, chapter_index_cl2, 1, 0, [3], [1], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl2,
                    "challenge_phase": "combat",
                    "title": "Archive Crucible",
                    "objective": "Break the elite archive wardens and expose the crown trial.",
                    "status_hint": "The crucible expects a cleaner clear before the crown seal opens.",
                    "checkpoint_label": "Crucible Ring",
                    "clear_banner": "Archive crucible stabilized.",
                    "required_kills": 14,
                    "reward_mult": 1.32,
                    "reward_summary": "Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2",
                    "settlement_summary": "The deeper challenge archive opens a broader postgame loop for later layers."
                }),
                _build_hidden_layer_room(3, ROOM_TYPE_BOSS, chapter_id_cl2, chapter_index_cl2, 2, 0, [4], [2], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl2,
                    "challenge_phase": "boss",
                    "title": "Crown Trial",
                    "objective": "Defeat the crowned archive echo and unlock the deeper settlement ledger.",
                    "status_hint": "Only a full crown clear records the second challenge layer.",
                    "checkpoint_label": "Crown Seal",
                    "clear_banner": "Crown trial archived.",
                    "boss_id": "boss_void_lord",
                    "is_boss_room": true,
                    "reward_mult": 1.4,
                    "reward_summary": "Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2",
                    "settlement_summary": "The deeper challenge archive opens a broader postgame loop for later layers."
                }),
                _build_hidden_layer_room(4, ROOM_TYPE_SAFE_CAMP, chapter_id_cl2, chapter_index_cl2, 3, 0, [], [3], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl2,
                    "challenge_phase": "settlement",
                    "title": "Challenge Layer II Settlement",
                    "objective": "Archive the deeper challenge clear and claim a reinforced settlement reward.",
                    "status_hint": "Press E to archive the deeper challenge and finish the run.",
                    "checkpoint_label": "Challenge Archive II",
                    "reward_summary": "Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2",
                    "settlement_summary": "The second settlement records a deeper challenge clear for the next archive horizon."
                })
            ]

            var room_plan_map_cl2: Dictionary = {}
            for row_cl2: Dictionary in rooms_cl2:
                room_plan_map_cl2[int(row_cl2.get("index", 0))] = row_cl2.duplicate(true)

            return {
                "layer_id": layer_key,
                "title": title_cl2,
                "theme": "Deeper archive crucible loop.",
                "map_mode": "challenge_crucible",
                "room_count": rooms_cl2.size(),
                "layout_cols": 4,
                "room_count_label": "Entry + elite + boss + settlement",
                "entry_hint": "Complete Archive Return to unlock the second challenge layer.",
                "reward_profile": {"summary": "Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2"},
                "settlement_profile": {"summary": "Archive the deeper challenge clear and prepare broader postgame routes."},
                "map_bounds": {"min_x": 0, "max_x": 3, "min_y": 0, "max_y": 0, "cols": 4, "rows": 1},
                "chapter_order": [chapter_id_cl2],
                "start_room": 1,
                "rooms": rooms_cl2,
                "room_plan_map": room_plan_map_cl2
            }
        "CL3":
            var chapter_id_cl3: String = "challenge_cl3"
            var chapter_index_cl3: int = 9
            var title_cl3: String = "Challenge Layer III"
            var rooms_cl3: Array[Dictionary] = [
                _build_hidden_layer_room(1, ROOM_TYPE_SAFE_CAMP, chapter_id_cl3, chapter_index_cl3, 0, 0, [2], [], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl3,
                    "challenge_phase": "entry",
                    "title": "Challenge Layer III Entry",
                    "objective": "Stabilize the sovereign archive route and confirm the null gauntlet.",
                    "status_hint": "Press E to enter the null gauntlet.",
                    "checkpoint_label": "Challenge Gate III",
                    "reward_summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3",
                    "settlement_summary": "The sovereign archive opens the deepest postgame frontier so far."
                }),
                _build_hidden_layer_room(2, ROOM_TYPE_ELITE, chapter_id_cl3, chapter_index_cl3, 1, 0, [3], [1], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl3,
                    "challenge_phase": "combat",
                    "title": "Null Gauntlet",
                    "objective": "Break the null wardens and expose the breach route.",
                    "status_hint": "The gauntlet collapses only after the elite wardens fall.",
                    "checkpoint_label": "Null Ring",
                    "clear_banner": "Null gauntlet stabilized.",
                    "required_kills": 16,
                    "reward_mult": 1.42,
                    "reward_summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3",
                    "settlement_summary": "The sovereign archive opens the deepest postgame frontier so far."
                }),
                _build_hidden_layer_room(3, ROOM_TYPE_COMBAT, chapter_id_cl3, chapter_index_cl3, 2, 0, [4], [2], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl3,
                    "challenge_phase": "combat",
                    "title": "Archive Breach",
                    "objective": "Hold the breach against the archive swarm and force the sovereign seal open.",
                    "status_hint": "A sustained breach is required before the sovereign echo manifests.",
                    "checkpoint_label": "Breach Seal",
                    "clear_banner": "Archive breach stabilized.",
                    "required_kills": 18,
                    "reward_mult": 1.5,
                    "reward_summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3",
                    "settlement_summary": "The sovereign archive opens the deepest postgame frontier so far."
                }),
                _build_hidden_layer_room(4, ROOM_TYPE_BOSS, chapter_id_cl3, chapter_index_cl3, 3, 0, [5], [3], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl3,
                    "challenge_phase": "boss",
                    "title": "Sovereign Echo",
                    "objective": "Defeat the sovereign archive echo and secure the final settlement ledger.",
                    "status_hint": "Only a sovereign clear records the third challenge layer.",
                    "checkpoint_label": "Sovereign Seal",
                    "clear_banner": "Sovereign echo archived.",
                    "boss_id": "boss_frost_king",
                    "is_boss_room": true,
                    "reward_mult": 1.62,
                    "reward_summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3",
                    "settlement_summary": "The sovereign archive opens the deepest postgame frontier so far."
                }),
                _build_hidden_layer_room(5, ROOM_TYPE_SAFE_CAMP, chapter_id_cl3, chapter_index_cl3, 4, 0, [], [4], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl3,
                    "challenge_phase": "settlement",
                    "title": "Challenge Layer III Settlement",
                    "objective": "Archive the sovereign clear and claim a frontier settlement reward.",
                    "status_hint": "Press E to archive the sovereign challenge and finish the run.",
                    "checkpoint_label": "Challenge Archive III",
                    "reward_summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3",
                    "settlement_summary": "The third settlement records a sovereign challenge clear for the final archive frontier."
                })
            ]

            var room_plan_map_cl3: Dictionary = {}
            for row_cl3: Dictionary in rooms_cl3:
                room_plan_map_cl3[int(row_cl3.get("index", 0))] = row_cl3.duplicate(true)

            return {
                "layer_id": layer_key,
                "title": title_cl3,
                "theme": "Sovereign archive gauntlet loop.",
                "map_mode": "challenge_sovereign",
                "room_count": rooms_cl3.size(),
                "layout_cols": 5,
                "room_count_label": "Entry + elite + combat + boss + settlement",
                "entry_hint": "Clear Challenge Layer II once to unlock the third challenge layer.",
                "reward_profile": {"summary": "Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3"},
                "settlement_profile": {"summary": "Archive the sovereign challenge clear and prepare the final archive frontier."},
                "map_bounds": {"min_x": 0, "max_x": 4, "min_y": 0, "max_y": 0, "cols": 5, "rows": 1},
                "chapter_order": [chapter_id_cl3],
                "start_room": 1,
                "rooms": rooms_cl3,
                "room_plan_map": room_plan_map_cl3
            }
        "CL4":
            var chapter_id_cl4: String = "challenge_cl4"
            var chapter_index_cl4: int = 10
            var title_cl4: String = "Challenge Layer IV"
            var rooms_cl4: Array[Dictionary] = [
                _build_hidden_layer_room(1, ROOM_TYPE_SAFE_CAMP, chapter_id_cl4, chapter_index_cl4, 0, 0, [2], [], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "entry",
                    "title": "Challenge Layer IV Entry",
                    "objective": "Stabilize the apex archive ascent and confirm the summit breach.",
                    "status_hint": "Press E to enter the ascent wardens.",
                    "checkpoint_label": "Challenge Gate IV",
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The apex archive completes the final Stage 6 frontier and locks in the deepest return ladder."
                }),
                _build_hidden_layer_room(2, ROOM_TYPE_ELITE, chapter_id_cl4, chapter_index_cl4, 1, 0, [3], [1], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "combat",
                    "title": "Ascent Wardens",
                    "objective": "Break the ascent wardens and force the summit breach open.",
                    "status_hint": "The ascent only advances after the wardens collapse.",
                    "checkpoint_label": "Ascent Ring",
                    "clear_banner": "Ascent wardens broken.",
                    "required_kills": 18,
                    "reward_mult": 1.56,
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The apex archive completes the final Stage 6 frontier and locks in the deepest return ladder."
                }),
                _build_hidden_layer_room(3, ROOM_TYPE_COMBAT, chapter_id_cl4, chapter_index_cl4, 2, 0, [4], [2], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "combat",
                    "title": "Summit Breach",
                    "objective": "Hold the summit breach against the archive storm and reveal the throne approach.",
                    "status_hint": "The breach must hold before the throne wardens answer.",
                    "checkpoint_label": "Summit Seal",
                    "clear_banner": "Summit breach secured.",
                    "required_kills": 20,
                    "reward_mult": 1.64,
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The apex archive completes the final Stage 6 frontier and locks in the deepest return ladder."
                }),
                _build_hidden_layer_room(4, ROOM_TYPE_ELITE, chapter_id_cl4, chapter_index_cl4, 3, 0, [5], [3], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "combat",
                    "title": "Throne Approach",
                    "objective": "Shatter the throne approach and expose the apex sovereign.",
                    "status_hint": "Only a clean advance opens the apex throne.",
                    "checkpoint_label": "Throne Gate",
                    "clear_banner": "Throne approach broken.",
                    "required_kills": 22,
                    "reward_mult": 1.72,
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The apex archive completes the final Stage 6 frontier and locks in the deepest return ladder."
                }),
                _build_hidden_layer_room(5, ROOM_TYPE_BOSS, chapter_id_cl4, chapter_index_cl4, 4, 0, [6], [4], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "boss",
                    "title": "Apex Throne",
                    "objective": "Defeat the apex sovereign and secure the final return protocol.",
                    "status_hint": "Only an apex clear records the fourth challenge layer.",
                    "checkpoint_label": "Apex Seal",
                    "clear_banner": "Apex throne archived.",
                    "boss_id": "boss_void_lord",
                    "is_boss_room": true,
                    "reward_mult": 1.82,
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The apex archive completes the final Stage 6 frontier and locks in the deepest return ladder."
                }),
                _build_hidden_layer_room(6, ROOM_TYPE_SAFE_CAMP, chapter_id_cl4, chapter_index_cl4, 5, 0, [], [5], {
                    "challenge_layer_id": layer_key,
                    "challenge_layer_title": title_cl4,
                    "challenge_phase": "settlement",
                    "title": "Challenge Layer IV Settlement",
                    "objective": "Archive the apex clear and claim the final frontier settlement reward.",
                    "status_hint": "Press E to archive the apex challenge and finish the run.",
                    "checkpoint_label": "Challenge Archive IV",
                    "reward_summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4",
                    "settlement_summary": "The fourth settlement records the apex challenge clear for the final return frontier."
                })
            ]

            var room_plan_map_cl4: Dictionary = {}
            for row_cl4: Dictionary in rooms_cl4:
                room_plan_map_cl4[int(row_cl4.get("index", 0))] = row_cl4.duplicate(true)

            return {
                "layer_id": layer_key,
                "title": title_cl4,
                "theme": "Apex archive ascent loop.",
                "map_mode": "challenge_apex",
                "room_count": rooms_cl4.size(),
                "layout_cols": 6,
                "room_count_label": "Entry + elite + combat + elite + boss + settlement",
                "entry_hint": "Clear Challenge Layer III once to unlock the fourth challenge layer.",
                "reward_profile": {"summary": "Apex archive sealed | Meta +100 | Sigil +4 | Insight +4"},
                "settlement_profile": {"summary": "Archive the apex challenge clear and complete the Stage 6 frontier."},
                "map_bounds": {"min_x": 0, "max_x": 5, "min_y": 0, "max_y": 0, "cols": 6, "rows": 1},
                "chapter_order": [chapter_id_cl4],
                "start_room": 1,
                "rooms": rooms_cl4,
                "room_plan_map": room_plan_map_cl4
            }
        _:
            return {}

    var chapter_id: String = "challenge_cl1"
    var chapter_index: int = 7
    var title: String = "Challenge Layer"
    var rooms: Array[Dictionary] = [
        _build_hidden_layer_room(1, ROOM_TYPE_SAFE_CAMP, chapter_id, chapter_index, 0, 0, [2], [], {
            "challenge_layer_id": layer_key,
            "challenge_layer_title": title,
            "challenge_phase": "entry",
            "title": "Challenge Layer Entry",
            "objective": "Step into the challenge archive route and confirm the first checkpoint.",
            "status_hint": "Press E to enter the first challenge combat ring.",
            "checkpoint_label": "Challenge Gate",
            "reward_summary": "Challenge archive sealed | Meta +40 | Sigil +1",
            "settlement_summary": "The challenge archive opens a thin postgame loop for future layers."
        }),
        _build_hidden_layer_room(2, ROOM_TYPE_COMBAT, chapter_id, chapter_index, 1, 0, [3], [1], {
            "challenge_layer_id": layer_key,
            "challenge_layer_title": title,
            "challenge_phase": "combat",
            "title": "Challenge Combat Ring",
            "objective": "Defeat the archive guardians and stabilize the settlement route.",
            "status_hint": "A minimal combat proof before deeper challenge rooms arrive.",
            "checkpoint_label": "Challenge Ring",
            "clear_banner": "Challenge ring stabilized.",
            "required_kills": 10,
            "reward_mult": 1.2,
            "reward_summary": "Challenge archive sealed | Meta +40 | Sigil +1",
            "settlement_summary": "The challenge archive opens a thin postgame loop for future layers."
        }),
        _build_hidden_layer_room(3, ROOM_TYPE_SAFE_CAMP, chapter_id, chapter_index, 2, 0, [], [2], {
            "challenge_layer_id": layer_key,
            "challenge_layer_title": title,
            "challenge_phase": "settlement",
            "title": "Challenge Settlement",
            "objective": "Archive the challenge clear and claim the first settlement reward.",
            "status_hint": "Press E to archive the challenge and finish the run.",
            "checkpoint_label": "Challenge Archive",
            "reward_summary": "Challenge archive sealed | Meta +40 | Sigil +1",
            "settlement_summary": "The settlement records this challenge clear for the next postgame step."
        })
    ]

    var room_plan_map: Dictionary = {}
    for row: Dictionary in rooms:
        room_plan_map[int(row.get("index", 0))] = row.duplicate(true)

    return {
        "layer_id": layer_key,
        "title": title,
        "theme": "Late-game challenge archive shell.",
        "map_mode": "challenge_entry",
        "room_count": rooms.size(),
        "layout_cols": 3,
        "room_count_label": "Entry + combat + settlement",
        "entry_hint": "Clear the full difficulty/meta-return chain to stabilize the first challenge layer.",
        "reward_profile": {"summary": "Challenge archive sealed | Meta +40 | Sigil +1"},
        "settlement_profile": {"summary": "Archive the challenge clear and prepare the next late-game route."},
        "map_bounds": {"min_x": 0, "max_x": 2, "min_y": 0, "max_y": 0, "cols": 3, "rows": 1},
        "chapter_order": [chapter_id],
        "start_room": 1,
        "rooms": rooms,
        "room_plan_map": room_plan_map
    }


func _build_hidden_layer_run_plan_fs1(profile: Dictionary) -> Dictionary:
    var layer_id: String = str(profile.get("layer_id", "FS1")).strip_edges().to_upper()
    var title: String = str(profile.get("title", "Time Rift")).strip_edges()
    var theme: String = str(profile.get("theme", "")).strip_edges()
    var entry_hint: String = str(profile.get("entrance_hint", "")).strip_edges()
    var reward_profile: Dictionary = profile.get("reward_profile", {}).duplicate(true) if profile.get("reward_profile", {}) is Dictionary else {}
    var settlement_profile: Dictionary = profile.get("settlement_profile", {}).duplicate(true) if profile.get("settlement_profile", {}) is Dictionary else {}
    var chapter_id: String = "hidden_fs1"
    var chapter_index: int = 5
    var rooms: Array[Dictionary] = [
        _build_hidden_layer_room(1, ROOM_TYPE_COMBAT, chapter_id, chapter_index, 0, 0, [2], [], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": "entry",
            "title": "Time Rift Threshold",
            "objective": "Stabilize the fracture and survive the first echo wave",
            "status_hint": "Echo pressure opens at 20.0x and tightens every five minutes.",
            "route_tag": "RIFT_ENTRY",
            "mainline_node": "Cross the altar seam and hold the split second open.",
            "clear_banner": "Threshold stabilized.",
            "checkpoint_label": "Rift Entry",
            "required_kills": 16,
            "runtime_spawn_rate_mult": 1.12,
            "runtime_enemy_hp_mult": 1.08,
            "runtime_enemy_damage_mult": 1.05,
            "reward_mult": 1.15,
            "pressure_label": "Threshold Pulse",
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(2, ROOM_TYPE_ELITE, chapter_id, chapter_index, 1, -1, [3], [1], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": "survival_loop",
            "title": "Echo Surge",
            "objective": "Break the accelerated echo pack before the rift folds shut",
            "status_hint": "A boss echo forms once the surge collapses.",
            "route_tag": "RIFT_SURGE",
            "mainline_node": "The rift compacts the run's strongest ghosts into one wave.",
            "clear_banner": "Echo surge broken.",
            "checkpoint_label": "Loop Anchor",
            "required_kills": 12,
            "runtime_spawn_rate_mult": 1.18,
            "runtime_enemy_hp_mult": 1.12,
            "runtime_enemy_damage_mult": 1.08,
            "reward_mult": 1.35,
            "minimum_clear_seconds": 30.0,
            "required_pressure_stage": 2,
            "max_pressure_stage": 3,
            "pressure_interval_seconds": 15.0,
            "pressure_stage_spawn_step": 0.09,
            "pressure_stage_hp_step": 0.07,
            "pressure_stage_damage_step": 0.05,
            "pressure_label": "Rift Surge",
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(3, ROOM_TYPE_BOSS, chapter_id, chapter_index, 2, 0, [4], [2], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": "boss_echo",
            "title": "Echo Apex",
            "objective": "Defeat the Void Lord echo and lock in the rift payout",
            "status_hint": "Clearing this echo converts the fracture into a recoverable archive.",
            "route_tag": "RIFT_BOSS",
            "mainline_node": "A void echo descends to measure whether the run can persist.",
            "clear_banner": "Echo apex broken.",
            "checkpoint_label": "Boss Echo",
            "boss_id": "boss_void_lord",
            "boss_echo_pool": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
            "is_boss_room": true,
            "runtime_spawn_rate_mult": 1.24,
            "runtime_enemy_hp_mult": 1.18,
            "runtime_enemy_damage_mult": 1.12,
            "pressure_label": "Echo Apex",
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(4, ROOM_TYPE_SAFE_CAMP, chapter_id, chapter_index, 3, 0, [], [3], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": "settlement",
            "title": "Rift Settlement",
            "objective": "Archive the fracture and claim the rewind reward",
            "status_hint": "Press E to cash out the rift archive and finish the run.",
            "route_tag": "RIFT_EXIT",
            "mainline_node": "Seal the fracture before it collapses back into the campaign.",
            "checkpoint_label": "Rift Archive",
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        })
    ]
    return _build_hidden_layer_runtime_plan(profile, rooms)


func _build_hidden_layer_run_plan_fs2(profile: Dictionary) -> Dictionary:
    var layer_id: String = str(profile.get("layer_id", "FS2")).strip_edges().to_upper()
    var title: String = str(profile.get("title", "Genesis Forge")).strip_edges()
    var entry_hint: String = str(profile.get("entrance_hint", "")).strip_edges()
    var reward_profile: Dictionary = profile.get("reward_profile", {}).duplicate(true) if profile.get("reward_profile", {}) is Dictionary else {}
    var settlement_profile: Dictionary = profile.get("settlement_profile", {}).duplicate(true) if profile.get("settlement_profile", {}) is Dictionary else {}
    var room_roles: Array[String] = []
    var map_profile_var: Variant = profile.get("map_profile", {})
    if map_profile_var is Dictionary:
        room_roles = _as_string_array((map_profile_var as Dictionary).get("room_roles", []))
    var chapter_id: String = "hidden_fs2"
    var chapter_index: int = 6
    var rooms: Array[Dictionary] = [
        _build_hidden_layer_room(1, ROOM_TYPE_COMBAT, chapter_id, chapter_index, 0, 0, [2], [], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": _resolve_hidden_room_role(room_roles, 0, "ore_tempering"),
            "title": "Ore Tempering",
            "objective": "Crack the first forge wave and stabilize the relic mold",
            "status_hint": "Each forge trial locks in one step of the legendary pattern.",
            "route_tag": "FORGE_1",
            "mainline_node": "Raw relic ore enters the furnace under impossible pressure.",
            "clear_banner": "Ore tempered.",
            "checkpoint_label": "Forge Trial I",
            "required_kills": 14,
            "trial_depth": 1,
            "trial_depth_max": 5,
            "trial_label": "Forge Trial I: Ore Tempering",
            "runtime_spawn_rate_mult": 1.08,
            "runtime_enemy_hp_mult": 1.10,
            "runtime_enemy_damage_mult": 1.04,
            "reward_mult": 1.10,
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(2, ROOM_TYPE_ELITE, chapter_id, chapter_index, 1, -1, [3], [1], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": _resolve_hidden_room_role(room_roles, 1, "ember_fold"),
            "title": "Ember Fold",
            "objective": "Cut through the forge elites before the ember fold seals",
            "status_hint": "The forge rewards clean, disciplined clears.",
            "route_tag": "FORGE_2",
            "mainline_node": "The ember fold compresses heat into a single lethal seam.",
            "clear_banner": "Ember fold broken.",
            "checkpoint_label": "Forge Trial II",
            "required_kills": 10,
            "trial_depth": 2,
            "trial_depth_max": 5,
            "trial_label": "Forge Trial II: Ember Fold",
            "runtime_spawn_rate_mult": 1.14,
            "runtime_enemy_hp_mult": 1.12,
            "runtime_enemy_damage_mult": 1.08,
            "reward_mult": 1.18,
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(3, ROOM_TYPE_COMBAT, chapter_id, chapter_index, 2, 0, [4], [2], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": _resolve_hidden_room_role(room_roles, 2, "frost_bind"),
            "title": "Frost Bind",
            "objective": "Hold formation while the forge cools the relic shell",
            "status_hint": "The bind phase punishes drifting out of the core lane.",
            "route_tag": "FORGE_3",
            "mainline_node": "The forge flash-freezes the relic seam before the next fold.",
            "clear_banner": "Frost bind stabilized.",
            "checkpoint_label": "Forge Trial III",
            "required_kills": 18,
            "trial_depth": 3,
            "trial_depth_max": 5,
            "trial_label": "Forge Trial III: Frost Bind",
            "runtime_spawn_rate_mult": 1.18,
            "runtime_enemy_hp_mult": 1.16,
            "runtime_enemy_damage_mult": 1.10,
            "reward_mult": 1.22,
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(4, ROOM_TYPE_ELITE, chapter_id, chapter_index, 3, 1, [5], [3], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": _resolve_hidden_room_role(room_roles, 3, "void_sunder"),
            "title": "Void Sunder",
            "objective": "Break the void-tempered guardians and expose the genesis core",
            "status_hint": "Only the last trial remains once the sunder collapses.",
            "route_tag": "FORGE_4",
            "mainline_node": "The forge sunder strips every false relic imprint away.",
            "clear_banner": "Void sunder complete.",
            "checkpoint_label": "Forge Trial IV",
            "required_kills": 12,
            "trial_depth": 4,
            "trial_depth_max": 5,
            "trial_label": "Forge Trial IV: Void Sunder",
            "runtime_spawn_rate_mult": 1.22,
            "runtime_enemy_hp_mult": 1.18,
            "runtime_enemy_damage_mult": 1.12,
            "reward_mult": 1.28,
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(5, ROOM_TYPE_BOSS, chapter_id, chapter_index, 4, 0, [6], [4], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": _resolve_hidden_room_role(room_roles, 4, "genesis_core"),
            "title": "Genesis Core",
            "objective": "Defeat the forge core and stabilize the legendary recipe chain",
            "status_hint": "A clean forge clear unlocks the settlement archive.",
            "route_tag": "FORGE_CORE",
            "mainline_node": "The forge heart tests whether the relic chain can become legend.",
            "clear_banner": "Genesis core extinguished.",
            "checkpoint_label": "Forge Core",
            "boss_id": "boss_flame_lord",
            "is_boss_room": true,
            "trial_depth": 5,
            "trial_depth_max": 5,
            "trial_label": "Forge Trial V: Genesis Core",
            "runtime_spawn_rate_mult": 1.28,
            "runtime_enemy_hp_mult": 1.22,
            "runtime_enemy_damage_mult": 1.16,
            "reward_mult": 1.35,
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        }),
        _build_hidden_layer_room(6, ROOM_TYPE_SAFE_CAMP, chapter_id, chapter_index, 5, 0, [], [5], {
            "hidden_layer_id": layer_id,
            "hidden_layer_title": title,
            "room_role": "settlement",
            "title": "Forge Settlement",
            "objective": "Archive the stabilized relic chain and claim the legendary draft",
            "status_hint": "Press E to finalize the forge archive and finish the run.",
            "route_tag": "FORGE_EXIT",
            "mainline_node": "The forge settles into a usable pattern for future runs.",
            "checkpoint_label": "Forge Archive",
            "entry_hint": entry_hint,
            "reward_summary": str(reward_profile.get("summary", "")),
            "settlement_summary": str(settlement_profile.get("summary", ""))
        })
    ]
    return _build_hidden_layer_runtime_plan(profile, rooms)


func _build_hidden_layer_runtime_plan(profile: Dictionary, rooms: Array[Dictionary]) -> Dictionary:
    var room_plan_map: Dictionary = {}
    var min_x: int = 0
    var max_x: int = 0
    var min_y: int = 0
    var max_y: int = 0
    var first_coord: bool = true

    for row: Dictionary in rooms:
        var room_index: int = int(row.get("index", 0))
        room_plan_map[room_index] = row.duplicate(true)
        var map_x: int = int(row.get("map_x", 0))
        var map_y: int = int(row.get("map_y", 0))
        if first_coord:
            min_x = map_x
            max_x = map_x
            min_y = map_y
            max_y = map_y
            first_coord = false
        else:
            min_x = mini(min_x, map_x)
            max_x = maxi(max_x, map_x)
            min_y = mini(min_y, map_y)
            max_y = maxi(max_y, map_y)

    var map_bounds: Dictionary = {
        "min_x": min_x,
        "max_x": max_x,
        "min_y": min_y,
        "max_y": max_y,
        "cols": max_x - min_x + 1,
        "rows": max_y - min_y + 1
    }

    var rebuilt_rooms: Array[Dictionary] = []
    for room_id in range(1, rooms.size() + 1):
        var room_row_var: Variant = room_plan_map.get(room_id, {})
        if room_row_var is Dictionary:
            rebuilt_rooms.append((room_row_var as Dictionary).duplicate(true))

    var map_profile: Dictionary = profile.get("map_profile", {}).duplicate(true) if profile.get("map_profile", {}) is Dictionary else {}
    var reward_profile: Dictionary = profile.get("reward_profile", {}).duplicate(true) if profile.get("reward_profile", {}) is Dictionary else {}
    var settlement_profile: Dictionary = profile.get("settlement_profile", {}).duplicate(true) if profile.get("settlement_profile", {}) is Dictionary else {}
    return {
        "layer_id": str(profile.get("layer_id", "")).strip_edges().to_upper(),
        "title": str(profile.get("title", "Hidden Layer")).strip_edges(),
        "theme": str(profile.get("theme", "")).strip_edges(),
        "map_mode": str(map_profile.get("mode", "")).strip_edges(),
        "room_count": rooms.size(),
        "layout_cols": maxi(3, int(map_bounds.get("cols", 3))),
        "room_count_label": str(map_profile.get("room_count_label", "%d rooms" % rooms.size())).strip_edges(),
        "entry_hint": str(profile.get("entrance_hint", "")).strip_edges(),
        "reward_profile": reward_profile,
        "settlement_profile": settlement_profile,
        "map_bounds": map_bounds,
        "chapter_order": [str(rebuilt_rooms[0].get("chapter_id", "hidden_layer"))] if not rebuilt_rooms.is_empty() else [],
        "start_room": 1,
        "rooms": rebuilt_rooms,
        "room_plan_map": room_plan_map
    }


func _build_hidden_layer_room(index: int, room_type: String, chapter_id: String, chapter_index: int, map_x: int, map_y: int, next_rooms: Array[int], previous_rooms: Array[int], extras: Dictionary = {}) -> Dictionary:
    var row: Dictionary = {
        "index": index,
        "room_type": room_type,
        "chapter_id": chapter_id,
        "chapter_index": chapter_index,
        "show_intro": false,
        "boss_id": "",
        "is_boss_room": room_type == ROOM_TYPE_BOSS,
        "next_rooms": next_rooms.duplicate(),
        "previous_rooms": previous_rooms.duplicate(),
        "map_x": map_x,
        "map_y": map_y
    }
    for key_var: Variant in extras.keys():
        row[str(key_var)] = extras.get(key_var)
    return row


func _resolve_hidden_room_role(room_roles: Array[String], index: int, fallback: String) -> String:
    if index >= 0 and index < room_roles.size():
        var room_role: String = room_roles[index]
        if room_role != "":
            return room_role
    return fallback


func _build_room_graph(room_plan_map: Dictionary, chapter_order: Array[String], chapters: Dictionary) -> Dictionary:
    var graph: Dictionary = {}
    for room_id_var: Variant in room_plan_map.keys():
        graph[int(room_id_var)] = []

    var previous_boss_room: int = -1
    for chapter_id in chapter_order:
        var chapter_row_var: Variant = chapters.get(chapter_id, {})
        if not (chapter_row_var is Dictionary):
            continue
        var chapter_row: Dictionary = chapter_row_var
        var start_room: int = int(chapter_row.get("start_room", -1))
        var end_room: int = int(chapter_row.get("end_room", -1))
        var boss_room: int = int(chapter_row.get("boss_room", -1))
        if start_room <= 0 or end_room < start_room or boss_room <= 0:
            continue

        var chapter_rooms: Array[int] = []
        for room_id in range(start_room, end_room + 1):
            if room_plan_map.has(room_id):
                chapter_rooms.append(room_id)

        if chapter_rooms.is_empty():
            continue

        var ordered_rooms: Array[int] = chapter_rooms.duplicate()
        ordered_rooms.sort()

        if previous_boss_room > 0 and start_room != previous_boss_room:
            _add_edge(graph, previous_boss_room, start_room)

        var middle_rooms: Array[int] = []
        for room_id in ordered_rooms:
            if room_id == start_room or room_id == boss_room:
                continue
            middle_rooms.append(room_id)

        if middle_rooms.size() >= 2:
            var branch_a: int = middle_rooms[0]
            var branch_b: int = middle_rooms[1]
            _add_edge(graph, start_room, branch_a)
            _add_edge(graph, start_room, branch_b)
            _add_edge(graph, branch_a, boss_room)
            _add_edge(graph, branch_b, boss_room)
            _set_branch_anchor(room_plan_map, start_room)

            for idx in range(2, middle_rooms.size()):
                var extra_room: int = middle_rooms[idx]
                var target_room: int = branch_a if idx % 2 == 0 else branch_b
                _add_edge(graph, start_room, extra_room)
                _add_edge(graph, extra_room, target_room)
        elif middle_rooms.size() == 1:
            var mid_room: int = middle_rooms[0]
            _add_edge(graph, start_room, mid_room)
            _add_edge(graph, mid_room, boss_room)
        else:
            _add_edge(graph, start_room, boss_room)

        previous_boss_room = boss_room

    return graph


func _apply_room_graph(room_plan_map: Dictionary, graph: Dictionary) -> void:
    var previous_map: Dictionary = {}
    for room_id_var: Variant in graph.keys():
        var room_id: int = int(room_id_var)
        var next_rows: Array[int] = []
        var raw_next_var: Variant = graph.get(room_id, [])
        if raw_next_var is Array:
            for target_var: Variant in raw_next_var:
                var target_id: int = int(target_var)
                if target_id <= 0 or not room_plan_map.has(target_id):
                    continue
                if not next_rows.has(target_id):
                    next_rows.append(target_id)
                    if not previous_map.has(target_id):
                        previous_map[target_id] = []
                    var previous_rows: Array = previous_map.get(target_id, [])
                    if not previous_rows.has(room_id):
                        previous_rows.append(room_id)
                    previous_map[target_id] = previous_rows

        var room_row_var: Variant = room_plan_map.get(room_id, {})
        if room_row_var is Dictionary:
            var room_row: Dictionary = room_row_var
            room_row["next_rooms"] = next_rows
            room_plan_map[room_id] = room_row

    for room_id_var: Variant in room_plan_map.keys():
        var room_id: int = int(room_id_var)
        var room_row_var: Variant = room_plan_map.get(room_id, {})
        if not (room_row_var is Dictionary):
            continue
        var room_row: Dictionary = room_row_var
        var previous_rows_out: Array[int] = []
        var previous_rows_var: Variant = previous_map.get(room_id, [])
        if previous_rows_var is Array:
            for source_var: Variant in previous_rows_var:
                var source_id: int = int(source_var)
                if source_id > 0 and not previous_rows_out.has(source_id):
                    previous_rows_out.append(source_id)
        room_row["previous_rooms"] = previous_rows_out
        room_plan_map[room_id] = room_row


func _assign_map_coordinates(room_plan_map: Dictionary, chapter_order: Array[String], chapters: Dictionary) -> Dictionary:
    var chapter_offset_x: int = 0

    for chapter_id in chapter_order:
        var chapter_row_var: Variant = chapters.get(chapter_id, {})
        if not (chapter_row_var is Dictionary):
            continue
        var chapter_row: Dictionary = chapter_row_var
        var start_room: int = int(chapter_row.get("start_room", -1))
        var end_room: int = int(chapter_row.get("end_room", -1))
        var boss_room: int = int(chapter_row.get("boss_room", -1))
        if start_room <= 0 or end_room < start_room:
            continue

        var chapter_rooms: Array[int] = []
        for room_id in range(start_room, end_room + 1):
            if room_plan_map.has(room_id):
                chapter_rooms.append(room_id)
        if chapter_rooms.is_empty():
            continue

        var middle_rooms: Array[int] = []
        for room_id in chapter_rooms:
            if room_id == start_room or room_id == boss_room:
                continue
            middle_rooms.append(room_id)
        middle_rooms.sort()

        _set_room_map_coord(room_plan_map, start_room, chapter_offset_x, 0)
        if boss_room > 0 and room_plan_map.has(boss_room):
            _set_room_map_coord(room_plan_map, boss_room, chapter_offset_x + 2, 0)

        if middle_rooms.size() == 1:
            _set_room_map_coord(room_plan_map, middle_rooms[0], chapter_offset_x + 1, 0)
        elif middle_rooms.size() >= 2:
            _set_room_map_coord(room_plan_map, middle_rooms[0], chapter_offset_x + 1, -1)
            _set_room_map_coord(room_plan_map, middle_rooms[1], chapter_offset_x + 1, 1)

            var extra_offsets: Array[int] = _build_extra_lane_offsets(middle_rooms.size() - 2)
            for idx in range(2, middle_rooms.size()):
                _set_room_map_coord(room_plan_map, middle_rooms[idx], chapter_offset_x + 1, extra_offsets[idx - 2])

        chapter_offset_x += 3

    for room_id_var: Variant in room_plan_map.keys():
        var room_id: int = int(room_id_var)
        var row_var: Variant = room_plan_map.get(room_id, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        if row.has("map_x") and row.has("map_y"):
            continue

        var chapter_index: int = maxi(1, int(row.get("chapter_index", 1)))
        _set_room_map_coord(room_plan_map, room_id, (chapter_index - 1) * 3 + 1, 0)

    var min_x: int = 0
    var max_x: int = 0
    var min_y: int = 0
    var max_y: int = 0
    var first: bool = true

    for row_var: Variant in room_plan_map.values():
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var map_x: int = int(row.get("map_x", 0))
        var map_y: int = int(row.get("map_y", 0))
        if first:
            min_x = map_x
            max_x = map_x
            min_y = map_y
            max_y = map_y
            first = false
        else:
            min_x = mini(min_x, map_x)
            max_x = maxi(max_x, map_x)
            min_y = mini(min_y, map_y)
            max_y = maxi(max_y, map_y)

    return {
        "min_x": min_x,
        "max_x": max_x,
        "min_y": min_y,
        "max_y": max_y,
        "cols": max_x - min_x + 1,
        "rows": max_y - min_y + 1
    }


func _set_room_map_coord(room_plan_map: Dictionary, room_id: int, map_x: int, map_y: int) -> void:
    var row_var: Variant = room_plan_map.get(room_id, {})
    if not (row_var is Dictionary):
        return
    var row: Dictionary = row_var
    row["map_x"] = map_x
    row["map_y"] = map_y
    room_plan_map[room_id] = row


func _build_extra_lane_offsets(count: int) -> Array[int]:
    var output: Array[int] = []
    var depth: int = 2
    while output.size() < count:
        output.append(-depth)
        if output.size() >= count:
            break
        output.append(depth)
        depth += 1
    return output


func _set_branch_anchor(room_plan_map: Dictionary, room_id: int) -> void:
    var row_var: Variant = room_plan_map.get(room_id, {})
    if row_var is Dictionary:
        var row: Dictionary = row_var
        row["is_branch_anchor"] = true
        room_plan_map[room_id] = row


func _add_edge(graph: Dictionary, from_room: int, to_room: int) -> void:
    if from_room <= 0 or to_room <= 0 or from_room == to_room:
        return
    if not graph.has(from_room):
        graph[from_room] = []
    var next_rows: Array = graph.get(from_room, [])
    if not next_rows.has(to_room):
        next_rows.append(to_room)
    graph[from_room] = next_rows


func _extract_fixed_rooms(rows_var: Variant) -> Dictionary:
    var output: Dictionary = {}
    if not (rows_var is Array):
        return output

    for item: Variant in rows_var:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var index: int = int(row.get("index", -1))
        var room_type: String = str(row.get("type", "")).strip_edges()
        if index <= 0:
            continue
        if not _is_valid_room_type(room_type):
            continue
        output[index] = room_type
    return output


func _normalize_weights(raw_weights: Dictionary, fallback: Dictionary) -> Dictionary:
    var normalized: Dictionary = fallback.duplicate(true)
    for room_type in ROLLABLE_ROOM_TYPES:
        normalized[room_type] = maxf(0.0, float(raw_weights.get(room_type, fallback.get(room_type, 0.0))))
    return normalized


func _normalize_room_type_caps(raw_caps_var: Variant) -> Dictionary:
    var output: Dictionary = {}
    if not (raw_caps_var is Dictionary):
        return output

    var raw_caps: Dictionary = raw_caps_var
    for room_type in ROLLABLE_ROOM_TYPES:
        if not raw_caps.has(room_type):
            continue
        output[room_type] = maxi(-1, int(raw_caps.get(room_type, -1)))
    return output


func _normalize_room_type_mins(raw_mins_var: Variant) -> Dictionary:
    var output: Dictionary = {}
    if not (raw_mins_var is Dictionary):
        return output

    var raw_mins: Dictionary = raw_mins_var
    for room_type in ROLLABLE_ROOM_TYPES:
        if not raw_mins.has(room_type):
            continue
        output[room_type] = maxi(0, int(raw_mins.get(room_type, 0)))
    return output


func _as_string_array(value: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (value is Array):
        return rows
    for item: Variant in value:
        var text: String = str(item).strip_edges()
        if text != "":
            rows.append(text)
    return rows


func _build_chapter_rollable_slots(chapter_order: Array[String], chapters: Dictionary, room_count: int, fixed_room_types: Dictionary, avoid_shop_near_boss: bool, avoid_event_near_boss: bool) -> Dictionary:
    var output: Dictionary = {}

    for chapter_id in chapter_order:
        var chapter_row_var: Variant = chapters.get(chapter_id, {})
        if not (chapter_row_var is Dictionary):
            continue
        var chapter_row: Dictionary = chapter_row_var
        var start_room: int = int(chapter_row.get("start_room", -1))
        var end_room: int = int(chapter_row.get("end_room", -1))
        var boss_room: int = int(chapter_row.get("boss_room", -1))
        if start_room <= 0 or end_room < start_room:
            continue

        var slots: Array[Dictionary] = []
        for room_index in range(start_room, mini(end_room, room_count) + 1):
            if room_index == 1:
                continue
            if room_index == boss_room:
                continue
            if fixed_room_types.has(room_index):
                continue

            var eligible_types: Array[String] = ROLLABLE_ROOM_TYPES.duplicate(true)
            if avoid_shop_near_boss and boss_room > 0 and room_index >= boss_room - 1:
                eligible_types.erase(ROOM_TYPE_SHOP)
            if avoid_event_near_boss and boss_room > 0 and room_index >= boss_room - 1:
                eligible_types.erase(ROOM_TYPE_EVENT)

            slots.append({
                "index": room_index,
                "eligible_types": eligible_types
            })

        output[chapter_id] = slots

    return output


func _collect_forced_min_types(deficits: Dictionary, chapter_slots: Array, slot_cursor: int) -> Array[String]:
    var forced_types: Array[String] = []
    if slot_cursor < 0 or slot_cursor >= chapter_slots.size():
        return forced_types

    var current_slot_var: Variant = chapter_slots[slot_cursor]
    if not (current_slot_var is Dictionary):
        return forced_types
    var current_slot: Dictionary = current_slot_var
    var current_eligible_var: Variant = current_slot.get("eligible_types", [])
    var current_eligible: Array = current_eligible_var if current_eligible_var is Array else []

    for deficit_key in deficits.keys():
        var room_type_key: String = str(deficit_key)
        var deficit: int = int(deficits.get(room_type_key, 0))
        if deficit <= 0:
            continue

        var eligible_remaining: int = 0
        for idx in range(slot_cursor, chapter_slots.size()):
            var slot_row_var: Variant = chapter_slots[idx]
            if not (slot_row_var is Dictionary):
                continue
            var eligible_var: Variant = (slot_row_var as Dictionary).get("eligible_types", [])
            if eligible_var is Array and (eligible_var as Array).has(room_type_key):
                eligible_remaining += 1

        if eligible_remaining > 0 and eligible_remaining <= deficit and current_eligible.has(room_type_key):
            forced_types.append(room_type_key)

    return forced_types


func _resolve_chapter_id(room_index: int, chapter_order: Array[String], chapters: Dictionary) -> String:
    for chapter_id in chapter_order:
        var row_var: Variant = chapters.get(chapter_id, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var start_room: int = int(row.get("start_room", 1))
        var end_room: int = int(row.get("end_room", 1))
        if room_index >= start_room and room_index <= end_room:
            return chapter_id

    var chapter_size: int = maxi(1, int(ceil(float(room_index) / 4.0)))
    return "chapter_%d" % chapter_size


func _fallback_chapter_index(chapter_id: String) -> int:
    var suffix: String = chapter_id.trim_prefix("chapter_")
    if suffix.is_valid_int():
        return maxi(1, int(suffix))
    return 1


func _build_chapter_weights(chapter_id: String, base_weights: Dictionary, chapter_weight_mult: Dictionary) -> Dictionary:
    var output: Dictionary = base_weights.duplicate(true)
    var chapter_mult_var: Variant = chapter_weight_mult.get(chapter_id, {})
    if chapter_mult_var is Dictionary:
        var chapter_mult: Dictionary = chapter_mult_var
        for room_type in ROLLABLE_ROOM_TYPES:
            var base_weight: float = maxf(0.0, float(output.get(room_type, 0.0)))
            var mult: float = clampf(float(chapter_mult.get(room_type, 1.0)), 0.0, 3.0)
            output[room_type] = base_weight * mult
    return output


func _roll_room_type(weights: Dictionary, history_types: Array[String], max_consecutive_same_type: int) -> String:
    var blocked_type: String = ""
    if history_types.size() >= max_consecutive_same_type:
        var tail_type: String = history_types[history_types.size() - 1]
        var same_count: int = 1
        for idx in range(history_types.size() - 2, -1, -1):
            if history_types[idx] == tail_type:
                same_count += 1
            else:
                break
        if same_count >= max_consecutive_same_type:
            blocked_type = tail_type

    var total: float = 0.0
    var weighted_rows: Array[Dictionary] = []
    for room_type in ROLLABLE_ROOM_TYPES:
        var weight: float = maxf(0.0, float(weights.get(room_type, 0.0)))
        if room_type == blocked_type:
            weight = 0.0
        if weight <= 0.0:
            continue
        weighted_rows.append({"type": room_type, "weight": weight})
        total += weight

    if total <= 0.0 or weighted_rows.is_empty():
        if blocked_type != ROOM_TYPE_COMBAT:
            return ROOM_TYPE_COMBAT
        return ROOM_TYPE_EVENT

    var roll: float = randf() * total
    var cursor: float = 0.0
    for row in weighted_rows:
        cursor += float(row.get("weight", 0.0))
        if roll <= cursor:
            return str(row.get("type", ROOM_TYPE_COMBAT))

    return str(weighted_rows[weighted_rows.size() - 1].get("type", ROOM_TYPE_COMBAT))


func _is_valid_room_type(room_type: String) -> bool:
    return room_type == ROOM_TYPE_COMBAT \
        or room_type == ROOM_TYPE_BOSS \
        or room_type == ROOM_TYPE_EVENT \
        or room_type == ROOM_TYPE_SHOP \
        or room_type == ROOM_TYPE_TREASURE \
        or room_type == ROOM_TYPE_SAFE_CAMP \
        or room_type == ROOM_TYPE_ELITE
