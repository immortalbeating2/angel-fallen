import json
from pathlib import Path
from typing import Any


REQUIRED_FILES = {
    "characters.json",
    "map_generation.json",
    "xp_curve.json",
    "enemy_scaling.json",
    "drop_tables.json",
    "evolutions.json",
    "shop_items.json",
    "environment_config.json",
    "boss_phases.json",
    "narrative_index.json",
    "narrative_content.json",
    "achievements.json",
    "meta_upgrades.json",
}


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _to_float(value: Any) -> float | None:
    if _is_number(value):
        return float(value)
    return None


def _add_error(errors: list[str], message: str) -> None:
    errors.append(message)


def _validate_required_files(parsed: dict[str, Any], errors: list[str]) -> None:
    existing = set(parsed.keys())
    missing = sorted(REQUIRED_FILES - existing)
    if missing:
        _add_error(errors, f"Missing required config files: {', '.join(missing)}")


def _validate_xp_curve(data: dict[str, Any], errors: list[str]) -> None:
    for key in ("base_xp", "curve_exponent", "max_level", "levels"):
        if key not in data:
            _add_error(errors, f"xp_curve.json missing key '{key}'")
            return

    if not _is_number(data["base_xp"]) or data["base_xp"] <= 0:
        _add_error(errors, "xp_curve.json base_xp must be > 0")
    if not _is_number(data["curve_exponent"]) or data["curve_exponent"] <= 1.0:
        _add_error(errors, "xp_curve.json curve_exponent should be > 1.0")
    if not isinstance(data["max_level"], int) or data["max_level"] < 5:
        _add_error(errors, "xp_curve.json max_level must be integer >= 5")

    levels = data.get("levels")
    if not isinstance(levels, dict) or not levels:
        _add_error(errors, "xp_curve.json levels must be a non-empty object")
        return

    for key, value in levels.items():
        if not str(key).isdigit():
            _add_error(errors, f"xp_curve.json invalid level key '{key}'")
        if not isinstance(value, int) or value <= 0:
            _add_error(errors, f"xp_curve.json level '{key}' xp must be positive int")


def _validate_characters(data: dict[str, Any], errors: list[str]) -> None:
    default_id = data.get("default_character_id")
    rows = data.get("characters")
    if not isinstance(default_id, str) or not default_id:
        _add_error(errors, "characters.json default_character_id must be non-empty string")
    if not isinstance(rows, list) or not rows:
        _add_error(errors, "characters.json characters must be non-empty array")
        return

    seen: set[str] = set()
    valid_ids: set[str] = set()
    unlock_type_by_id: dict[str, str] = {}
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            _add_error(errors, f"characters.json characters[{i}] must be object")
            continue

        char_id = row.get("id")
        if not isinstance(char_id, str) or not char_id:
            _add_error(errors, f"characters.json characters[{i}].id invalid")
            continue
        if char_id in seen:
            _add_error(errors, f"characters.json duplicate id '{char_id}'")
        seen.add(char_id)
        valid_ids.add(char_id)

        if not isinstance(row.get("name"), str) or not row.get("name"):
            _add_error(errors, f"characters.json {char_id}.name invalid")
        if not isinstance(row.get("description"), str) or not row.get("description"):
            _add_error(errors, f"characters.json {char_id}.description invalid")

        unlock_type = row.get("unlock_type", "default")
        unlock_value = row.get("unlock_value", "")
        unlock_desc = row.get("unlock_desc", "")
        allowed_unlock_types = {"default", "achievement", "ending", "meta_runs"}
        if not isinstance(unlock_type, str) or unlock_type not in allowed_unlock_types:
            _add_error(errors, f"characters.json {char_id}.unlock_type invalid")
            unlock_type = "default"
        unlock_type_by_id[char_id] = unlock_type

        if not isinstance(unlock_desc, str):
            _add_error(errors, f"characters.json {char_id}.unlock_desc must be string")

        if unlock_type != "default":
            if not isinstance(unlock_value, str) or not unlock_value:
                _add_error(errors, f"characters.json {char_id}.unlock_value required for unlock_type '{unlock_type}'")
            elif unlock_type == "meta_runs" and not unlock_value.isdigit():
                _add_error(errors, f"characters.json {char_id}.unlock_value for meta_runs must be integer string")

        if not isinstance(row.get("trait_id"), str) or not row.get("trait_id"):
            _add_error(errors, f"characters.json {char_id}.trait_id invalid")
        if not isinstance(row.get("trait_name"), str) or not row.get("trait_name"):
            _add_error(errors, f"characters.json {char_id}.trait_name invalid")
        if not isinstance(row.get("trait_desc"), str) or not row.get("trait_desc"):
            _add_error(errors, f"characters.json {char_id}.trait_desc invalid")

        weapon_profile = row.get("weapon_profile")
        if not isinstance(weapon_profile, dict):
            _add_error(errors, f"characters.json {char_id}.weapon_profile must be object")
        else:
            mode = weapon_profile.get("mode", "single")
            projectile_count = _to_float(weapon_profile.get("projectile_count"))
            spread_angle_deg = _to_float(weapon_profile.get("spread_angle_deg"))
            spread_jitter_deg = _to_float(weapon_profile.get("spread_jitter_deg", 0.0))
            projectile_hits = _to_float(weapon_profile.get("projectile_hits"))
            projectile_style = weapon_profile.get("projectile_style", "default")

            if not isinstance(mode, str) or mode not in {"single", "spread"}:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.mode must be 'single' or 'spread'")
            if projectile_count is None or projectile_count < 1 or projectile_count > 7:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.projectile_count must be within [1, 7]")
            if spread_angle_deg is None or spread_angle_deg < 0 or spread_angle_deg > 45:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.spread_angle_deg must be within [0, 45]")
            if spread_jitter_deg is None or spread_jitter_deg < 0 or spread_jitter_deg > 15:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.spread_jitter_deg must be within [0, 15]")
            if projectile_hits is None or projectile_hits < 1 or projectile_hits > 8:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.projectile_hits must be within [1, 8]")
            if not isinstance(projectile_style, str) or not projectile_style:
                _add_error(errors, f"characters.json {char_id}.weapon_profile.projectile_style must be non-empty string")

        trait_effects = row.get("trait_effects")
        if not isinstance(trait_effects, dict):
            _add_error(errors, f"characters.json {char_id}.trait_effects must be object")
        elif not trait_effects:
            _add_error(errors, f"characters.json {char_id}.trait_effects cannot be empty")
        else:
            allowed_trait_keys = {
                "max_hp_bonus",
                "armor_bonus",
                "damage_bonus_pct",
                "move_speed_mult",
                "crit_chance_bonus",
                "crit_multiplier_bonus",
                "weapon_damage_flat",
                "attack_interval_mult",
                "frostbite_resistance_bonus",
                "void_resistance_bonus",
            }
            for key, value in trait_effects.items():
                if key not in allowed_trait_keys:
                    _add_error(errors, f"characters.json {char_id}.trait_effects key '{key}' is not supported")
                    continue
                if not _is_number(value):
                    _add_error(errors, f"characters.json {char_id}.trait_effects['{key}'] must be numeric")
                    continue

                value_f = float(value)
                if key == "move_speed_mult" and value_f <= 0:
                    _add_error(errors, f"characters.json {char_id}.trait_effects['{key}'] must be > 0")
                if key == "attack_interval_mult" and value_f <= 0:
                    _add_error(errors, f"characters.json {char_id}.trait_effects['{key}'] must be > 0")

        max_hp = _to_float(row.get("max_hp"))
        move_speed = _to_float(row.get("move_speed"))
        stamina_max = _to_float(row.get("stamina_max"))
        armor = _to_float(row.get("armor"))
        crit_chance = _to_float(row.get("crit_chance"))
        crit_multiplier = _to_float(row.get("crit_multiplier"))
        base_damage = _to_float(row.get("base_damage"))
        attack_interval = _to_float(row.get("attack_interval"))

        if max_hp is None or max_hp <= 0:
            _add_error(errors, f"characters.json {char_id}.max_hp must be > 0")
        if move_speed is None or move_speed <= 0:
            _add_error(errors, f"characters.json {char_id}.move_speed must be > 0")
        if stamina_max is None or stamina_max <= 0:
            _add_error(errors, f"characters.json {char_id}.stamina_max must be > 0")
        if armor is None or armor < 0.0 or armor > 0.75:
            _add_error(errors, f"characters.json {char_id}.armor must be within [0, 0.75]")
        if crit_chance is None or crit_chance < 0.0 or crit_chance > 0.95:
            _add_error(errors, f"characters.json {char_id}.crit_chance must be within [0, 0.95]")
        if crit_multiplier is None or crit_multiplier < 1.1:
            _add_error(errors, f"characters.json {char_id}.crit_multiplier must be >= 1.1")
        if base_damage is None or base_damage <= 0:
            _add_error(errors, f"characters.json {char_id}.base_damage must be > 0")
        if attack_interval is None or attack_interval <= 0:
            _add_error(errors, f"characters.json {char_id}.attack_interval must be > 0")

    if isinstance(default_id, str) and default_id and default_id not in valid_ids:
        _add_error(errors, f"characters.json default_character_id '{default_id}' not found in characters list")
    elif isinstance(default_id, str) and default_id:
        if unlock_type_by_id.get(default_id, "default") != "default":
            _add_error(errors, f"characters.json default_character_id '{default_id}' must use unlock_type 'default'")


def _validate_map_generation(data: dict[str, Any], errors: list[str]) -> None:
    room_count = data.get("room_count")
    layout_cols = data.get("layout_cols")
    chapter_order = data.get("chapter_order")
    chapters = data.get("chapters")
    fixed_rooms = data.get("fixed_rooms")
    base_weights = data.get("base_room_weights")
    chapter_mult = data.get("chapter_room_weight_mult")
    constraints = data.get("constraints")

    if not isinstance(room_count, int) or room_count < 8:
        _add_error(errors, "map_generation.json room_count must be int >= 8")
        room_count = 15
    if not isinstance(layout_cols, int) or layout_cols < 3:
        _add_error(errors, "map_generation.json layout_cols must be int >= 3")

    if not isinstance(chapter_order, list) or not chapter_order:
        _add_error(errors, "map_generation.json chapter_order must be non-empty array")
        chapter_order = ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]

    if not isinstance(chapters, dict) or not chapters:
        _add_error(errors, "map_generation.json chapters must be non-empty object")
        return

    previous_end = 0
    boss_rooms: set[int] = set()
    for idx, chapter_id in enumerate(chapter_order):
        row = chapters.get(chapter_id)
        if not isinstance(row, dict):
            _add_error(errors, f"map_generation.json chapters missing '{chapter_id}'")
            continue

        chapter_index = row.get("index")
        start_room = row.get("start_room")
        end_room = row.get("end_room")
        intro_room = row.get("intro_room")
        boss_room = row.get("boss_room")
        boss_id = row.get("boss_id")

        if not isinstance(chapter_index, int) or chapter_index < 1:
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.index must be int >= 1")
        if isinstance(chapter_index, int) and chapter_index != idx + 1:
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.index should equal order position ({idx + 1})")

        if not isinstance(start_room, int) or not isinstance(end_room, int):
            _add_error(errors, f"map_generation.json chapters.{chapter_id} start/end must be ints")
            continue
        if start_room < 1 or end_room < start_room:
            _add_error(errors, f"map_generation.json chapters.{chapter_id} invalid room range")
            continue
        if start_room != previous_end + 1:
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.start_room should continue previous chapter range")
        previous_end = end_room

        if not isinstance(intro_room, int) or intro_room < start_room or intro_room > end_room:
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.intro_room must be within chapter range")
        if not isinstance(boss_room, int) or boss_room < start_room or boss_room > end_room:
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.boss_room must be within chapter range")
        else:
            if boss_room in boss_rooms:
                _add_error(errors, f"map_generation.json duplicate boss_room {boss_room}")
            boss_rooms.add(boss_room)
        if not isinstance(boss_id, str) or not boss_id.startswith("boss_"):
            _add_error(errors, f"map_generation.json chapters.{chapter_id}.boss_id must start with 'boss_'")

    if previous_end != room_count:
        _add_error(errors, "map_generation.json chapter ranges must end exactly at room_count")

    allowed_fixed_types = {"combat", "event", "shop", "treasure", "safe_camp", "elite"}
    if not isinstance(fixed_rooms, list):
        _add_error(errors, "map_generation.json fixed_rooms must be array")
    else:
        seen_indices: set[int] = set()
        for i, row in enumerate(fixed_rooms):
            if not isinstance(row, dict):
                _add_error(errors, f"map_generation.json fixed_rooms[{i}] must be object")
                continue
            index = row.get("index")
            room_type = row.get("type")
            if not isinstance(index, int) or index < 1 or index > room_count:
                _add_error(errors, f"map_generation.json fixed_rooms[{i}].index out of range")
            elif index in seen_indices:
                _add_error(errors, f"map_generation.json fixed_rooms duplicate index {index}")
            else:
                seen_indices.add(index)
            if not isinstance(room_type, str) or room_type not in allowed_fixed_types:
                _add_error(errors, f"map_generation.json fixed_rooms[{i}].type invalid")

    required_weight_keys = ("combat", "event", "shop", "treasure", "elite")
    if not isinstance(base_weights, dict) or not base_weights:
        _add_error(errors, "map_generation.json base_room_weights must be non-empty object")
    else:
        total = 0.0
        for key in required_weight_keys:
            weight = _to_float(base_weights.get(key))
            if weight is None or weight < 0:
                _add_error(errors, f"map_generation.json base_room_weights.{key} must be >= 0")
            else:
                total += weight
        if total <= 0:
            _add_error(errors, "map_generation.json base_room_weights total must be > 0")

    if not isinstance(chapter_mult, dict):
        _add_error(errors, "map_generation.json chapter_room_weight_mult must be object")
    else:
        for chapter_id in chapter_order:
            row = chapter_mult.get(chapter_id)
            if not isinstance(row, dict):
                _add_error(errors, f"map_generation.json chapter_room_weight_mult missing '{chapter_id}'")
                continue
            for key in required_weight_keys:
                value = _to_float(row.get(key))
                if value is None or value < 0.0 or value > 3.0:
                    _add_error(errors, f"map_generation.json chapter_room_weight_mult.{chapter_id}.{key} must be within [0, 3]")

    if constraints is not None:
        if not isinstance(constraints, dict):
            _add_error(errors, "map_generation.json constraints must be object")
        else:
            max_consecutive = constraints.get("max_consecutive_same_type")
            max_treasure_per_chapter = constraints.get("max_treasure_per_chapter")
            max_room_type_per_chapter = constraints.get("max_room_type_per_chapter")
            min_room_type_per_chapter = constraints.get("min_room_type_per_chapter")
            if not isinstance(max_consecutive, int) or max_consecutive < 1 or max_consecutive > 5:
                _add_error(errors, "map_generation.json constraints.max_consecutive_same_type must be int within [1, 5]")
            if not isinstance(max_treasure_per_chapter, int) or max_treasure_per_chapter < 0 or max_treasure_per_chapter > 5:
                _add_error(errors, "map_generation.json constraints.max_treasure_per_chapter must be int within [0, 5]")

            required_cap_keys = ("event", "shop", "elite", "treasure")
            if not isinstance(max_room_type_per_chapter, dict) or not max_room_type_per_chapter:
                _add_error(errors, "map_generation.json constraints.max_room_type_per_chapter must be non-empty object")
            else:
                for key in required_cap_keys:
                    value = max_room_type_per_chapter.get(key)
                    if not isinstance(value, int) or value < 0 or value > room_count:
                        _add_error(errors, f"map_generation.json constraints.max_room_type_per_chapter.{key} must be int within [0, room_count]")

                if isinstance(max_treasure_per_chapter, int):
                    treasure_cap = max_room_type_per_chapter.get("treasure")
                    if isinstance(treasure_cap, int) and treasure_cap != max_treasure_per_chapter:
                        _add_error(errors, "map_generation.json constraints.max_treasure_per_chapter must match max_room_type_per_chapter.treasure")

            required_min_keys = ("event", "shop", "elite", "treasure")
            if not isinstance(min_room_type_per_chapter, dict) or not min_room_type_per_chapter:
                _add_error(errors, "map_generation.json constraints.min_room_type_per_chapter must be non-empty object")
            else:
                for key in required_min_keys:
                    value = min_room_type_per_chapter.get(key)
                    if not isinstance(value, int) or value < 0 or value > room_count:
                        _add_error(errors, f"map_generation.json constraints.min_room_type_per_chapter.{key} must be int within [0, room_count]")

                    if isinstance(max_room_type_per_chapter, dict):
                        max_value = max_room_type_per_chapter.get(key)
                        if isinstance(value, int) and isinstance(max_value, int) and value > max_value:
                            _add_error(errors, f"map_generation.json constraints.min_room_type_per_chapter.{key} cannot exceed max_room_type_per_chapter.{key}")

                if isinstance(max_treasure_per_chapter, int):
                    treasure_min = min_room_type_per_chapter.get("treasure")
                    if isinstance(treasure_min, int) and treasure_min > max_treasure_per_chapter:
                        _add_error(errors, "map_generation.json constraints.min_room_type_per_chapter.treasure cannot exceed max_treasure_per_chapter")
            for key in ("avoid_shop_near_boss", "avoid_event_near_boss"):
                value = constraints.get(key)
                if not isinstance(value, bool):
                    _add_error(errors, f"map_generation.json constraints.{key} must be bool")


def _validate_enemy_scaling(data: dict[str, Any], errors: list[str]) -> None:
    brackets = data.get("room_time_brackets")
    multipliers = data.get("floor_multipliers")
    elite_wave_interval = data.get("elite_wave_interval")
    type_weights = data.get("enemy_type_weights")
    chapter_map = data.get("chapter_archetype_map")
    if not isinstance(brackets, list) or not brackets:
        _add_error(errors, "enemy_scaling.json room_time_brackets must be a non-empty array")
    else:
        last_max = -1.0
        for i, row in enumerate(brackets):
            if not isinstance(row, dict):
                _add_error(errors, f"enemy_scaling.json bracket[{i}] must be object")
                continue
            max_seconds = row.get("max_seconds")
            hp_mult = row.get("hp_mult")
            dmg_mult = row.get("damage_mult")
            max_seconds_f = _to_float(max_seconds)
            if max_seconds_f is None:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].max_seconds must be > 0")
            elif max_seconds_f <= 0:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].max_seconds must be > 0")
            elif max_seconds_f <= last_max:
                _add_error(errors, "enemy_scaling.json room_time_brackets must be strictly increasing")
            else:
                last_max = max_seconds_f

            hp_mult_f = _to_float(hp_mult)
            if hp_mult_f is None:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].hp_mult must be > 0")
            elif hp_mult_f <= 0:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].hp_mult must be > 0")

            dmg_mult_f = _to_float(dmg_mult)
            if dmg_mult_f is None:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].damage_mult must be > 0")
            elif dmg_mult_f <= 0:
                _add_error(errors, f"enemy_scaling.json bracket[{i}].damage_mult must be > 0")

    if not isinstance(multipliers, dict):
        _add_error(errors, "enemy_scaling.json floor_multipliers must be an object")
    else:
        for floor in range(1, 16):
            key = str(floor)
            if key not in multipliers:
                _add_error(errors, f"enemy_scaling.json missing floor multiplier for floor {floor}")
                continue
            value = multipliers[key]
            value_f = _to_float(value)
            if value_f is None:
                _add_error(errors, f"enemy_scaling.json floor {floor} multiplier must be > 0")
            elif value_f <= 0:
                _add_error(errors, f"enemy_scaling.json floor {floor} multiplier must be > 0")

    if not isinstance(elite_wave_interval, int) or elite_wave_interval < 3:
        _add_error(errors, "enemy_scaling.json elite_wave_interval must be int >= 3")

    required_enemy_types = ("normal", "fast", "tank", "ranged")
    if not isinstance(type_weights, dict):
        _add_error(errors, "enemy_scaling.json enemy_type_weights must be an object")
    else:
        total_weight = 0.0
        for enemy_type in required_enemy_types:
            if enemy_type not in type_weights:
                _add_error(errors, f"enemy_scaling.json enemy_type_weights missing '{enemy_type}'")
                continue
            weight_f = _to_float(type_weights.get(enemy_type))
            if weight_f is None:
                _add_error(errors, f"enemy_scaling.json enemy_type_weights['{enemy_type}'] must be >= 0")
                continue
            if weight_f < 0:
                _add_error(errors, f"enemy_scaling.json enemy_type_weights['{enemy_type}'] must be >= 0")
                continue
            total_weight += weight_f
        if total_weight <= 0:
            _add_error(errors, "enemy_scaling.json enemy_type_weights total must be > 0")

    required_enemy_types = ("normal", "fast", "tank", "ranged")
    if not isinstance(chapter_map, dict):
        _add_error(errors, "enemy_scaling.json chapter_archetype_map must be an object")
    else:
        for chapter_id in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
            chapter_row = chapter_map.get(chapter_id)
            if not isinstance(chapter_row, dict):
                _add_error(errors, f"enemy_scaling.json chapter_archetype_map missing '{chapter_id}'")
                continue
            for enemy_type in required_enemy_types:
                enemy_id = chapter_row.get(enemy_type)
                if not isinstance(enemy_id, str) or not enemy_id.startswith("enemy_"):
                    _add_error(errors, f"enemy_scaling.json chapter_archetype_map.{chapter_id}.{enemy_type} must start with 'enemy_'")


def _validate_drop_tables(data: dict[str, Any], errors: list[str]) -> None:
    for table_name in ("normal", "elite", "boss"):
        table = data.get(table_name)
        if not isinstance(table, dict):
            _add_error(errors, f"drop_tables.json missing table '{table_name}'")
            continue

        guaranteed = table.get("guaranteed")
        weighted = table.get("weighted")
        if not isinstance(guaranteed, list) or not guaranteed:
            _add_error(errors, f"drop_tables.json {table_name}.guaranteed must be non-empty array")
        if not isinstance(weighted, list) or not weighted:
            _add_error(errors, f"drop_tables.json {table_name}.weighted must be non-empty array")
            continue

        for i, row in enumerate(weighted):
            if not isinstance(row, dict):
                _add_error(errors, f"drop_tables.json {table_name}.weighted[{i}] must be object")
                continue
            item_id = row.get("id")
            weight = row.get("weight")
            if not isinstance(item_id, str) or not item_id:
                _add_error(errors, f"drop_tables.json {table_name}.weighted[{i}].id invalid")
            weight_f = _to_float(weight)
            if weight_f is None:
                _add_error(errors, f"drop_tables.json {table_name}.weighted[{i}].weight must be > 0")
            elif weight_f <= 0:
                _add_error(errors, f"drop_tables.json {table_name}.weighted[{i}].weight must be > 0")


def _validate_shop_items(data: dict[str, Any], errors: list[str]) -> None:
    slots = data.get("slots")
    restock_cost = data.get("restock_cost")
    restock_growth = data.get("restock_growth")
    restock_cost_cap = data.get("restock_cost_cap")
    catchup_discount = data.get("catchup_discount")
    ore_exchange = data.get("ore_exchange")
    chapter_overrides = data.get("chapter_overrides")
    route_style_overrides = data.get("route_style_overrides")
    quality_weights = data.get("quality_weights")
    category_weights = data.get("category_weights")
    pools = data.get("pools")

    if not isinstance(slots, int) or slots < 1:
        _add_error(errors, "shop_items.json slots must be int >= 1")
    if isinstance(slots, int) and slots > 8:
        _add_error(errors, "shop_items.json slots should be <= 8")
    if not isinstance(restock_cost, int) or restock_cost < 0:
        _add_error(errors, "shop_items.json restock_cost must be int >= 0")
    restock_growth_f = _to_float(restock_growth)
    if restock_growth_f is None or restock_growth_f < 0.0:
        _add_error(errors, "shop_items.json restock_growth must be numeric >= 0")
    elif restock_growth_f > 1.2:
        _add_error(errors, "shop_items.json restock_growth should be <= 1.2")
    if not isinstance(restock_cost_cap, int) or restock_cost_cap < int(restock_cost if isinstance(restock_cost, int) else 0):
        _add_error(errors, "shop_items.json restock_cost_cap must be int >= restock_cost")

    if not isinstance(catchup_discount, dict):
        _add_error(errors, "shop_items.json catchup_discount must be object")
    else:
        target_gold = catchup_discount.get("target_gold_per_room")
        max_discount = catchup_discount.get("max_discount")
        high_markup = catchup_discount.get("high_gold_markup")
        high_threshold = catchup_discount.get("high_gold_threshold_mult")

        target_gold_f = _to_float(target_gold)
        max_discount_f = _to_float(max_discount)
        high_markup_f = _to_float(high_markup)
        high_threshold_f = _to_float(high_threshold)

        if target_gold_f is None or target_gold_f <= 0:
            _add_error(errors, "shop_items.json catchup_discount.target_gold_per_room must be > 0")
        if max_discount_f is None or max_discount_f < 0.0 or max_discount_f > 0.75:
            _add_error(errors, "shop_items.json catchup_discount.max_discount must be within [0, 0.75]")
        if high_markup_f is None or high_markup_f < 0.0 or high_markup_f > 0.45:
            _add_error(errors, "shop_items.json catchup_discount.high_gold_markup must be within [0, 0.45]")
        if high_threshold_f is None or high_threshold_f < 1.0:
            _add_error(errors, "shop_items.json catchup_discount.high_gold_threshold_mult must be >= 1.0")

    if not isinstance(ore_exchange, dict):
        _add_error(errors, "shop_items.json ore_exchange must be object")
    else:
        enabled = ore_exchange.get("enabled")
        ore_per_trade = ore_exchange.get("ore_per_trade")
        gold_per_trade = ore_exchange.get("gold_per_trade")
        max_trades = ore_exchange.get("max_trades_per_shop")
        bonus_chance = ore_exchange.get("bonus_trade_chance")
        bonus_gold = ore_exchange.get("bonus_gold")

        if not isinstance(enabled, bool):
            _add_error(errors, "shop_items.json ore_exchange.enabled must be bool")
        if not isinstance(ore_per_trade, int) or ore_per_trade < 1:
            _add_error(errors, "shop_items.json ore_exchange.ore_per_trade must be int >= 1")
        if not isinstance(gold_per_trade, int) or gold_per_trade < 1:
            _add_error(errors, "shop_items.json ore_exchange.gold_per_trade must be int >= 1")
        if not isinstance(max_trades, int) or max_trades < 1:
            _add_error(errors, "shop_items.json ore_exchange.max_trades_per_shop must be int >= 1")
        bonus_chance_f = _to_float(bonus_chance)
        if bonus_chance_f is None or bonus_chance_f < 0.0 or bonus_chance_f > 1.0:
            _add_error(errors, "shop_items.json ore_exchange.bonus_trade_chance must be within [0, 1]")
        if not isinstance(bonus_gold, int) or bonus_gold < 0:
            _add_error(errors, "shop_items.json ore_exchange.bonus_gold must be int >= 0")

    if not isinstance(chapter_overrides, dict):
        _add_error(errors, "shop_items.json chapter_overrides must be object")
    else:
        expected_chapters = ("chapter_1", "chapter_2", "chapter_3", "chapter_4")
        for chapter_id in expected_chapters:
            chapter_row = chapter_overrides.get(chapter_id)
            if not isinstance(chapter_row, dict):
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id} must be object")
                continue

            price_mult = _to_float(chapter_row.get("price_mult"))
            restock_cost_mult = _to_float(chapter_row.get("restock_cost_mult"))
            restock_growth_add = _to_float(chapter_row.get("restock_growth_add"))
            target_gold_mult = _to_float(chapter_row.get("target_gold_mult"))
            max_discount_add = _to_float(chapter_row.get("max_discount_add"))
            high_markup_add = _to_float(chapter_row.get("high_markup_add"))
            exchange_gold_add = chapter_row.get("ore_exchange_gold_add")
            exchange_trades_add = chapter_row.get("ore_exchange_max_trades_add")
            exchange_bonus_chance_add = _to_float(chapter_row.get("ore_exchange_bonus_chance_add"))
            exchange_bonus_gold_add = chapter_row.get("ore_exchange_bonus_gold_add")
            chapter_quality_mult = chapter_row.get("quality_weight_mult")
            chapter_category_mult = chapter_row.get("category_weight_mult")
            chapter_pool_overrides = chapter_row.get("pool_overrides")

            if price_mult is None or price_mult < 0.6 or price_mult > 1.6:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.price_mult must be within [0.6, 1.6]")
            if restock_cost_mult is None or restock_cost_mult < 0.6 or restock_cost_mult > 1.9:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.restock_cost_mult must be within [0.6, 1.9]")
            if restock_growth_add is None or restock_growth_add < -0.5 or restock_growth_add > 0.8:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.restock_growth_add must be within [-0.5, 0.8]")
            if target_gold_mult is None or target_gold_mult < 0.5 or target_gold_mult > 2.0:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.target_gold_mult must be within [0.5, 2.0]")
            if max_discount_add is None or max_discount_add < -0.4 or max_discount_add > 0.4:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.max_discount_add must be within [-0.4, 0.4]")
            if high_markup_add is None or high_markup_add < -0.3 or high_markup_add > 0.3:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.high_markup_add must be within [-0.3, 0.3]")
            if not isinstance(exchange_gold_add, int) or exchange_gold_add < -30 or exchange_gold_add > 30:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.ore_exchange_gold_add must be int within [-30, 30]")
            if not isinstance(exchange_trades_add, int) or exchange_trades_add < -3 or exchange_trades_add > 5:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.ore_exchange_max_trades_add must be int within [-3, 5]")
            if exchange_bonus_chance_add is None or exchange_bonus_chance_add < -0.6 or exchange_bonus_chance_add > 0.6:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.ore_exchange_bonus_chance_add must be within [-0.6, 0.6]")
            if not isinstance(exchange_bonus_gold_add, int) or exchange_bonus_gold_add < -10 or exchange_bonus_gold_add > 20:
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.ore_exchange_bonus_gold_add must be int within [-10, 20]")

            if not isinstance(chapter_quality_mult, dict):
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.quality_weight_mult must be object")
            else:
                for quality_key in ("common", "rare", "epic", "legendary"):
                    quality_mult_value = _to_float(chapter_quality_mult.get(quality_key))
                    if quality_mult_value is None or quality_mult_value < 0.0 or quality_mult_value > 3.5:
                        _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.quality_weight_mult.{quality_key} must be within [0.0, 3.5]")

            if not isinstance(chapter_category_mult, dict):
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.category_weight_mult must be object")
            else:
                for category_key in ("consumable", "passive", "weapon"):
                    category_mult_value = _to_float(chapter_category_mult.get(category_key))
                    if category_mult_value is None or category_mult_value < 0.0 or category_mult_value > 3.0:
                        _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.category_weight_mult.{category_key} must be within [0.0, 3.0]")

            if not isinstance(chapter_pool_overrides, dict):
                _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.pool_overrides must be object")
            else:
                for category_key, rows in chapter_pool_overrides.items():
                    if category_key not in ("consumable", "passive", "weapon"):
                        _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.pool_overrides has unknown category '{category_key}'")
                        continue
                    if not isinstance(rows, list) or not rows:
                        _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.pool_overrides['{category_key}'] must be non-empty array")
                        continue
                    for row in rows:
                        if not isinstance(row, str) or not row:
                            _add_error(errors, f"shop_items.json chapter_overrides.{chapter_id}.pool_overrides['{category_key}'] entries must be non-empty strings")

    if not isinstance(route_style_overrides, dict) or not route_style_overrides:
        _add_error(errors, "shop_items.json route_style_overrides must be non-empty object")
    else:
        expected_styles = ("neutral", "vanguard", "raider")
        for style_id in expected_styles:
            style_row = route_style_overrides.get(style_id)
            if not isinstance(style_row, dict):
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id} must be object")
                continue

            price_mult = _to_float(style_row.get("price_mult"))
            target_gold_mult = _to_float(style_row.get("target_gold_mult"))
            max_discount_add = _to_float(style_row.get("max_discount_add"))
            high_markup_add = _to_float(style_row.get("high_markup_add"))
            exchange_gold_add = style_row.get("exchange_gold_add")
            quality_mult = style_row.get("quality_weight_mult")
            category_mult = style_row.get("category_weight_mult")

            if price_mult is None or price_mult < 0.7 or price_mult > 1.5:
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.price_mult must be within [0.7, 1.5]")
            if target_gold_mult is None or target_gold_mult < 0.6 or target_gold_mult > 1.8:
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.target_gold_mult must be within [0.6, 1.8]")
            if max_discount_add is None or max_discount_add < -0.35 or max_discount_add > 0.35:
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.max_discount_add must be within [-0.35, 0.35]")
            if high_markup_add is None or high_markup_add < -0.25 or high_markup_add > 0.35:
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.high_markup_add must be within [-0.25, 0.35]")
            if not isinstance(exchange_gold_add, int) or exchange_gold_add < -15 or exchange_gold_add > 25:
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.exchange_gold_add must be int within [-15, 25]")

            if not isinstance(quality_mult, dict):
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.quality_weight_mult must be object")
            else:
                for quality_key in ("common", "rare", "epic", "legendary"):
                    quality_mult_value = _to_float(quality_mult.get(quality_key))
                    if quality_mult_value is None or quality_mult_value < 0.0 or quality_mult_value > 3.0:
                        _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.quality_weight_mult.{quality_key} must be within [0.0, 3.0]")

            if not isinstance(category_mult, dict):
                _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.category_weight_mult must be object")
            else:
                for category_key in ("consumable", "passive", "weapon"):
                    category_mult_value = _to_float(category_mult.get(category_key))
                    if category_mult_value is None or category_mult_value < 0.0 or category_mult_value > 3.0:
                        _add_error(errors, f"shop_items.json route_style_overrides.{style_id}.category_weight_mult.{category_key} must be within [0.0, 3.0]")

    if not isinstance(quality_weights, dict) or not quality_weights:
        _add_error(errors, "shop_items.json quality_weights must be non-empty object")
    else:
        total = 0.0
        for key, value in quality_weights.items():
            if not _is_number(value) or float(value) < 0:
                _add_error(errors, f"shop_items.json quality_weights['{key}'] must be >= 0")
            else:
                total += float(value)
        if total <= 0:
            _add_error(errors, "shop_items.json quality_weights total must be > 0")

    if not isinstance(category_weights, dict) or not category_weights:
        _add_error(errors, "shop_items.json category_weights must be non-empty object")
    else:
        total = 0.0
        for category_key in ("consumable", "passive", "weapon"):
            value_f = _to_float(category_weights.get(category_key))
            if value_f is None or value_f < 0:
                _add_error(errors, f"shop_items.json category_weights['{category_key}'] must be >= 0")
            else:
                total += value_f
        if total <= 0:
            _add_error(errors, "shop_items.json category_weights total must be > 0")

    if not isinstance(pools, dict) or not pools:
        _add_error(errors, "shop_items.json pools must be non-empty object")
    else:
        for category, rows in pools.items():
            if not isinstance(rows, list) or not rows:
                _add_error(errors, f"shop_items.json pools['{category}'] must be non-empty array")


def _validate_environment_config(data: dict[str, Any], errors: list[str]) -> None:
    chapters = data.get("chapters")
    if not isinstance(chapters, dict):
        _add_error(errors, "environment_config.json chapters must be an object")
        return

    for chapter_key in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
        row = chapters.get(chapter_key)
        if not isinstance(row, dict):
            _add_error(errors, f"environment_config.json missing '{chapter_key}'")
            continue
        if not isinstance(row.get("theme"), str) or not row["theme"]:
            _add_error(errors, f"environment_config.json {chapter_key}.theme invalid")
        hazards = row.get("hazards")
        if not isinstance(hazards, list) or not hazards:
            _add_error(errors, f"environment_config.json {chapter_key}.hazards must be non-empty array")


def _validate_boss_phases(data: dict[str, Any], errors: list[str]) -> None:
    bosses = data.get("bosses")
    if not isinstance(bosses, dict) or not bosses:
        _add_error(errors, "boss_phases.json bosses must be non-empty object")
        return

    for boss_id, thresholds in bosses.items():
        if not isinstance(thresholds, list) or len(thresholds) < 2:
            _add_error(errors, f"boss_phases.json {boss_id} thresholds must contain at least 2 values")
            continue

        prev = None
        for i, value in enumerate(thresholds):
            if not _is_number(value):
                _add_error(errors, f"boss_phases.json {boss_id}[{i}] must be numeric")
                continue
            v = float(value)
            if v <= 0.0 or v > 1.0:
                _add_error(errors, f"boss_phases.json {boss_id}[{i}] must be within (0, 1]")
            if i == 0 and abs(v - 1.0) > 0.001:
                _add_error(errors, f"boss_phases.json {boss_id} first threshold must be 1.0")
            if prev is not None and v >= prev:
                _add_error(errors, f"boss_phases.json {boss_id} thresholds must be strictly descending")
            prev = v


def _validate_narrative_index(root: Path, data: dict[str, Any], errors: list[str], warnings: list[str]) -> None:
    segments = data.get("segments")
    if not isinstance(segments, list) or not segments:
        _add_error(errors, "narrative_index.json segments must be non-empty array")
        return

    seen_ids: set[str] = set()
    for i, row in enumerate(segments):
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_index.json segments[{i}] must be object")
            continue
        seg_id = row.get("id")
        path = row.get("resource_path")
        if not isinstance(seg_id, str) or not seg_id:
            _add_error(errors, f"narrative_index.json segments[{i}].id invalid")
            continue
        if seg_id in seen_ids:
            _add_error(errors, f"narrative_index.json duplicate segment id '{seg_id}'")
        seen_ids.add(seg_id)
        if not isinstance(path, str) or not path.startswith("res://"):
            _add_error(errors, f"narrative_index.json segments[{i}].resource_path must start with res://")
            continue

        disk_path = root / path.replace("res://", "")
        if not disk_path.exists():
            warnings.append(f"narrative_index.json missing resource file: {path}")

    memory_fragments = data.get("memory_fragments")
    if not isinstance(memory_fragments, dict):
        _add_error(errors, "narrative_index.json memory_fragments must be object")
        return

    total = memory_fragments.get("total")
    categories = memory_fragments.get("categories")
    if not isinstance(total, int) or total <= 0:
        _add_error(errors, "narrative_index.json memory_fragments.total must be int > 0")
    if not isinstance(categories, list) or not categories:
        _add_error(errors, "narrative_index.json memory_fragments.categories must be non-empty array")


def _validate_narrative_content(data: dict[str, Any], errors: list[str]) -> None:
    transitions = data.get("chapter_transitions")
    events = data.get("chapter_events")
    endings = data.get("endings")
    route_styles = data.get("route_styles")

    if not isinstance(transitions, dict):
        _add_error(errors, "narrative_content.json chapter_transitions must be object")
    else:
        for chapter_key in ("chapter_1", "chapter_2", "chapter_3"):
            row = transitions.get(chapter_key)
            if not isinstance(row, dict):
                _add_error(errors, f"narrative_content.json missing transition '{chapter_key}'")
                continue
            choices = row.get("choices")
            if not isinstance(choices, list) or len(choices) < 2:
                _add_error(errors, f"narrative_content.json {chapter_key}.choices must have at least 2 entries")

    if not isinstance(events, dict):
        _add_error(errors, "narrative_content.json chapter_events must be object")
    else:
        for chapter_key in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
            rows = events.get(chapter_key)
            if not isinstance(rows, list) or not rows:
                _add_error(errors, f"narrative_content.json chapter_events.{chapter_key} must be non-empty array")
                continue
            for i, event_row in enumerate(rows):
                if not isinstance(event_row, dict):
                    _add_error(errors, f"narrative_content.json {chapter_key}[{i}] must be object")
                    continue

                for route_key in ("weight_if_route_vanguard", "weight_if_route_raider"):
                    route_weight = _to_float(event_row.get(route_key))
                    if route_weight is None or route_weight <= 0.0 or route_weight > 3.0:
                        _add_error(errors, f"narrative_content.json {chapter_key}[{i}].{route_key} must be within (0, 3]")

                choices = event_row.get("choices")
                if not isinstance(choices, list) or len(choices) < 2:
                    _add_error(errors, f"narrative_content.json {chapter_key}[{i}] choices must have at least 2 entries")
                    continue
                for j, choice in enumerate(choices):
                    if not isinstance(choice, dict):
                        _add_error(errors, f"narrative_content.json {chapter_key}[{i}].choices[{j}] must be object")
                        continue
                    effect = choice.get("chapter_effect")
                    if effect is None:
                        continue
                    if not isinstance(effect, dict):
                        _add_error(errors, f"narrative_content.json {chapter_key}[{i}].choices[{j}].chapter_effect must be object")
                        continue
                    if not isinstance(effect.get("duration_rooms"), int) or int(effect.get("duration_rooms", 0)) < 1:
                        _add_error(errors, f"narrative_content.json {chapter_key}[{i}].choices[{j}] chapter_effect.duration_rooms must be >= 1")
                    effects_obj = effect.get("effects")
                    if not isinstance(effects_obj, dict) or not effects_obj:
                        _add_error(errors, f"narrative_content.json {chapter_key}[{i}].choices[{j}] chapter_effect.effects must be non-empty object")

    if not isinstance(route_styles, dict) or not route_styles:
        _add_error(errors, "narrative_content.json route_styles must be non-empty object")
    else:
        expected_styles = ("neutral", "vanguard", "raider")
        for style_id in expected_styles:
            style_row = route_styles.get(style_id)
            if not isinstance(style_row, dict):
                _add_error(errors, f"narrative_content.json route_styles.{style_id} must be object")
                continue

            event_weight_mult = _to_float(style_row.get("event_weight_mult"))
            hazard_mult = _to_float(style_row.get("hazard_mult"))
            gold_drop_mult = _to_float(style_row.get("gold_drop_mult"))
            ore_drop_mult = _to_float(style_row.get("ore_drop_mult"))
            theme_tint = style_row.get("theme_tint")
            theme_blend = _to_float(style_row.get("theme_blend"))
            boss_hp_mult = _to_float(style_row.get("boss_hp_mult"))
            boss_damage_mult = _to_float(style_row.get("boss_damage_mult"))
            boss_speed_mult = _to_float(style_row.get("boss_speed_mult"))
            boss_scale_mult = _to_float(style_row.get("boss_scale_mult"))
            boss_color = style_row.get("boss_color")

            if event_weight_mult is None or event_weight_mult < 0.5 or event_weight_mult > 1.8:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.event_weight_mult must be within [0.5, 1.8]")
            if hazard_mult is None or hazard_mult < 0.6 or hazard_mult > 1.5:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.hazard_mult must be within [0.6, 1.5]")
            if gold_drop_mult is None or gold_drop_mult < 0.5 or gold_drop_mult > 2.0:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.gold_drop_mult must be within [0.5, 2.0]")
            if ore_drop_mult is None or ore_drop_mult < 0.5 or ore_drop_mult > 2.0:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.ore_drop_mult must be within [0.5, 2.0]")
            if not isinstance(theme_tint, str) or not theme_tint:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.theme_tint must be non-empty string")
            if theme_blend is None or theme_blend < 0.0 or theme_blend > 0.5:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.theme_blend must be within [0.0, 0.5]")
            if boss_hp_mult is None or boss_hp_mult < 0.7 or boss_hp_mult > 1.4:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.boss_hp_mult must be within [0.7, 1.4]")
            if boss_damage_mult is None or boss_damage_mult < 0.7 or boss_damage_mult > 1.5:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.boss_damage_mult must be within [0.7, 1.5]")
            if boss_speed_mult is None or boss_speed_mult < 0.7 or boss_speed_mult > 1.5:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.boss_speed_mult must be within [0.7, 1.5]")
            if boss_scale_mult is None or boss_scale_mult < 0.85 or boss_scale_mult > 1.25:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.boss_scale_mult must be within [0.85, 1.25]")
            if not isinstance(boss_color, str) or not boss_color:
                _add_error(errors, f"narrative_content.json route_styles.{style_id}.boss_color must be non-empty string")

    if not isinstance(endings, dict) or not endings:
        _add_error(errors, "narrative_content.json endings must be non-empty object")


def _validate_achievements(data: dict[str, Any], errors: list[str]) -> None:
    rows = data.get("achievements")
    if not isinstance(rows, list) or not rows:
        _add_error(errors, "achievements.json achievements must be non-empty array")
        return

    seen: set[str] = set()
    prefixes = ("clear_floor_", "alignment_ge_", "alignment_le_", "kills_ge_", "reach_level_")
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            _add_error(errors, f"achievements.json achievements[{i}] must be object")
            continue
        ach_id = row.get("id")
        condition = row.get("condition")
        if not isinstance(ach_id, str) or not ach_id:
            _add_error(errors, f"achievements.json achievements[{i}].id invalid")
            continue
        if ach_id in seen:
            _add_error(errors, f"achievements.json duplicate id '{ach_id}'")
        seen.add(ach_id)
        if not isinstance(condition, str) or not condition:
            _add_error(errors, f"achievements.json achievements[{i}].condition invalid")
            continue
        if condition != "victory_once" and not condition.startswith(prefixes):
            _add_error(errors, f"achievements.json achievements[{i}] unsupported condition '{condition}'")


def _validate_meta_upgrades(data: dict[str, Any], errors: list[str]) -> None:
    rows = data.get("upgrades")
    if not isinstance(rows, list) or not rows:
        _add_error(errors, "meta_upgrades.json upgrades must be non-empty array")
        return

    seen: set[str] = set()
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            _add_error(errors, f"meta_upgrades.json upgrades[{i}] must be object")
            continue
        upgrade_id = row.get("id")
        if not isinstance(upgrade_id, str) or not upgrade_id:
            _add_error(errors, f"meta_upgrades.json upgrades[{i}].id invalid")
            continue
        if upgrade_id in seen:
            _add_error(errors, f"meta_upgrades.json duplicate id '{upgrade_id}'")
        seen.add(upgrade_id)

        if not isinstance(row.get("effect"), str) or not row["effect"]:
            _add_error(errors, f"meta_upgrades.json {upgrade_id}.effect invalid")
        if not isinstance(row.get("max_level"), int) or row["max_level"] < 1:
            _add_error(errors, f"meta_upgrades.json {upgrade_id}.max_level must be int >= 1")
        if not _is_number(row.get("value_per_level")):
            _add_error(errors, f"meta_upgrades.json {upgrade_id}.value_per_level must be numeric")
        if not isinstance(row.get("base_cost"), int) or row["base_cost"] < 0:
            _add_error(errors, f"meta_upgrades.json {upgrade_id}.base_cost must be int >= 0")
        if not isinstance(row.get("cost_step"), int) or row["cost_step"] < 0:
            _add_error(errors, f"meta_upgrades.json {upgrade_id}.cost_step must be int >= 0")


def _validate_evolutions(data: dict[str, Any], errors: list[str]) -> None:
    rows = data.get("evolutions")
    if not isinstance(rows, list) or not rows:
        _add_error(errors, "evolutions.json evolutions must be non-empty array")
        return

    seen_ids: set[str] = set()
    seen_results: set[str] = set()
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            _add_error(errors, f"evolutions.json evolutions[{i}] must be object")
            continue

        evo_id = row.get("id")
        if not isinstance(evo_id, str) or not evo_id:
            _add_error(errors, f"evolutions.json evolutions[{i}].id must be non-empty string")
        elif evo_id in seen_ids:
            _add_error(errors, f"evolutions.json duplicate id '{evo_id}'")
        else:
            seen_ids.add(evo_id)

        weapon_id = row.get("weapon_id")
        passive_id = row.get("passive_id")
        result_weapon_id = row.get("result_weapon_id")
        if not isinstance(weapon_id, str) or not weapon_id.startswith("wpn_"):
            _add_error(errors, f"evolutions.json evolutions[{i}].weapon_id must start with 'wpn_'")
        if not isinstance(passive_id, str) or not passive_id.startswith("pas_"):
            _add_error(errors, f"evolutions.json evolutions[{i}].passive_id must start with 'pas_'")
        if not isinstance(result_weapon_id, str) or not result_weapon_id.startswith("wpn_"):
            _add_error(errors, f"evolutions.json evolutions[{i}].result_weapon_id must start with 'wpn_'")
        if isinstance(weapon_id, str) and isinstance(result_weapon_id, str) and weapon_id == result_weapon_id:
            _add_error(errors, f"evolutions.json evolutions[{i}] result_weapon_id must differ from weapon_id")

        if isinstance(result_weapon_id, str) and result_weapon_id:
            if result_weapon_id in seen_results:
                _add_error(errors, f"evolutions.json duplicate result_weapon_id '{result_weapon_id}'")
            else:
                seen_results.add(result_weapon_id)

        title = row.get("title")
        desc = row.get("desc")
        if not isinstance(title, str) or not title.strip():
            _add_error(errors, f"evolutions.json evolutions[{i}].title must be non-empty string")
        if not isinstance(desc, str) or not desc.strip():
            _add_error(errors, f"evolutions.json evolutions[{i}].desc must be non-empty string")

        required_level = row.get("required_passive_level")
        if not isinstance(required_level, int) or required_level < 1 or required_level > 5:
            _add_error(errors, f"evolutions.json evolutions[{i}].required_passive_level must be int within [1, 5]")

        profile = row.get("evolution_profile")
        if not isinstance(profile, dict) or not profile:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile must be non-empty object")
            continue

        damage_mult = _to_float(profile.get("damage_mult"))
        flat_damage_bonus = _to_float(profile.get("flat_damage_bonus"))
        interval_mult = _to_float(profile.get("interval_mult"))
        weapon_mode = profile.get("weapon_mode")
        projectile_count = profile.get("projectile_count")
        spread_angle_deg = _to_float(profile.get("spread_angle_deg"))
        spread_jitter_deg = _to_float(profile.get("spread_jitter_deg"))
        projectile_hits = profile.get("projectile_hits")
        projectile_style = profile.get("projectile_style")

        if damage_mult is None or damage_mult < 0.8 or damage_mult > 3.0:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.damage_mult must be within [0.8, 3.0]")
        if flat_damage_bonus is None or flat_damage_bonus < 0.0 or flat_damage_bonus > 30.0:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.flat_damage_bonus must be within [0.0, 30.0]")
        if interval_mult is None or interval_mult < 0.35 or interval_mult > 1.25:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.interval_mult must be within [0.35, 1.25]")
        if not isinstance(weapon_mode, str) or weapon_mode not in {"single", "spread"}:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.weapon_mode must be 'single' or 'spread'")
        if not isinstance(projectile_count, int) or projectile_count < 1 or projectile_count > 8:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.projectile_count must be int within [1, 8]")
        if spread_angle_deg is None or spread_angle_deg < 0.0 or spread_angle_deg > 60.0:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.spread_angle_deg must be within [0, 60]")
        if spread_jitter_deg is None or spread_jitter_deg < 0.0 or spread_jitter_deg > 20.0:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.spread_jitter_deg must be within [0, 20]")
        if not isinstance(projectile_hits, int) or projectile_hits < 1 or projectile_hits > 12:
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.projectile_hits must be int within [1, 12]")
        if not isinstance(projectile_style, str) or not projectile_style.strip():
            _add_error(errors, f"evolutions.json evolutions[{i}].evolution_profile.projectile_style must be non-empty string")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    balance_dir = root / "data" / "balance"
    files = sorted(balance_dir.glob("*.json"))
    if not files:
        print("No JSON config files found.")
        return 1

    parsed_by_name: dict[str, Any] = {}
    errors: list[str] = []
    warnings: list[str] = []

    for file in files:
        try:
            parsed_by_name[file.name] = json.loads(file.read_text(encoding="utf-8"))
        except Exception as exc:
            _add_error(errors, f"Invalid JSON: {file.name} -> {exc}")

    _validate_required_files(parsed_by_name, errors)

    if "xp_curve.json" in parsed_by_name:
        _validate_xp_curve(parsed_by_name["xp_curve.json"], errors)
    if "characters.json" in parsed_by_name:
        _validate_characters(parsed_by_name["characters.json"], errors)
    if "map_generation.json" in parsed_by_name:
        _validate_map_generation(parsed_by_name["map_generation.json"], errors)
    if "enemy_scaling.json" in parsed_by_name:
        _validate_enemy_scaling(parsed_by_name["enemy_scaling.json"], errors)
    if "drop_tables.json" in parsed_by_name:
        _validate_drop_tables(parsed_by_name["drop_tables.json"], errors)
    if "shop_items.json" in parsed_by_name:
        _validate_shop_items(parsed_by_name["shop_items.json"], errors)
    if "environment_config.json" in parsed_by_name:
        _validate_environment_config(parsed_by_name["environment_config.json"], errors)
    if "boss_phases.json" in parsed_by_name:
        _validate_boss_phases(parsed_by_name["boss_phases.json"], errors)
    if "narrative_index.json" in parsed_by_name:
        _validate_narrative_index(root, parsed_by_name["narrative_index.json"], errors, warnings)
    if "narrative_content.json" in parsed_by_name:
        _validate_narrative_content(parsed_by_name["narrative_content.json"], errors)
    if "achievements.json" in parsed_by_name:
        _validate_achievements(parsed_by_name["achievements.json"], errors)
    if "meta_upgrades.json" in parsed_by_name:
        _validate_meta_upgrades(parsed_by_name["meta_upgrades.json"], errors)
    if "evolutions.json" in parsed_by_name:
        _validate_evolutions(parsed_by_name["evolutions.json"], errors)

    if warnings:
        for message in warnings:
            print(f"Warning: {message}")

    if errors:
        print(f"Validation failed with {len(errors)} error(s):")
        for message in errors:
            print(f"- {message}")
        return 1

    print(f"Validated {len(files)} JSON config files successfully.")
    if warnings:
        print(f"Validation completed with {len(warnings)} warning(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
