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
