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
    "quality_baseline_targets.json",
    "release_gate_targets.json",
    "compatibility_rehearsal_targets.json",
    "resource_acceptance_targets.json",
    "visual_snapshot_targets.json",
}


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _to_float(value: Any) -> float | None:
    if _is_number(value):
        return float(value)
    return None


def _is_hex_color(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    if len(value) not in (7, 9):
        return False
    if not value.startswith("#"):
        return False
    try:
        int(value[1:], 16)
        return True
    except ValueError:
        return False


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
    treasure_challenge = data.get("treasure_challenge")
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

    if treasure_challenge is not None:
        if not isinstance(treasure_challenge, dict):
            _add_error(errors, "map_generation.json treasure_challenge must be object")
        else:
            enabled = treasure_challenge.get("enabled")
            combat_mode = treasure_challenge.get("combat_mode")
            required_kills_base = treasure_challenge.get("required_kills_base")
            required_kills_per_room = treasure_challenge.get("required_kills_per_room")
            gold_reward_base = treasure_challenge.get("gold_reward_base")
            gold_reward_per_room = treasure_challenge.get("gold_reward_per_room")
            ore_reward_base = treasure_challenge.get("ore_reward_base")
            ore_reward_step_rooms = treasure_challenge.get("ore_reward_step_rooms")
            accessory_chance_base = treasure_challenge.get("accessory_chance_base")
            accessory_chance_vanguard = treasure_challenge.get("accessory_chance_vanguard")
            accessory_chance_raider = treasure_challenge.get("accessory_chance_raider")

            if not isinstance(enabled, bool):
                _add_error(errors, "map_generation.json treasure_challenge.enabled must be bool")
            if not isinstance(combat_mode, str) or combat_mode not in {"elite", "normal"}:
                _add_error(errors, "map_generation.json treasure_challenge.combat_mode must be 'elite' or 'normal'")
            if not isinstance(required_kills_base, int) or required_kills_base < 1 or required_kills_base > 20:
                _add_error(errors, "map_generation.json treasure_challenge.required_kills_base must be int within [1, 20]")
            if not isinstance(required_kills_per_room, int) or required_kills_per_room < 0 or required_kills_per_room > 4:
                _add_error(errors, "map_generation.json treasure_challenge.required_kills_per_room must be int within [0, 4]")
            if not isinstance(gold_reward_base, int) or gold_reward_base < 1 or gold_reward_base > 120:
                _add_error(errors, "map_generation.json treasure_challenge.gold_reward_base must be int within [1, 120]")
            if not isinstance(gold_reward_per_room, int) or gold_reward_per_room < 0 or gold_reward_per_room > 12:
                _add_error(errors, "map_generation.json treasure_challenge.gold_reward_per_room must be int within [0, 12]")
            if not isinstance(ore_reward_base, int) or ore_reward_base < 1 or ore_reward_base > 8:
                _add_error(errors, "map_generation.json treasure_challenge.ore_reward_base must be int within [1, 8]")
            if not isinstance(ore_reward_step_rooms, int) or ore_reward_step_rooms < 1 or ore_reward_step_rooms > 12:
                _add_error(errors, "map_generation.json treasure_challenge.ore_reward_step_rooms must be int within [1, 12]")

            base_chance_f = _to_float(accessory_chance_base)
            vanguard_chance_f = _to_float(accessory_chance_vanguard)
            raider_chance_f = _to_float(accessory_chance_raider)
            if base_chance_f is None or base_chance_f < 0.0 or base_chance_f > 1.0:
                _add_error(errors, "map_generation.json treasure_challenge.accessory_chance_base must be within [0, 1]")
            if vanguard_chance_f is None or vanguard_chance_f < 0.0 or vanguard_chance_f > 1.0:
                _add_error(errors, "map_generation.json treasure_challenge.accessory_chance_vanguard must be within [0, 1]")
            if raider_chance_f is None or raider_chance_f < 0.0 or raider_chance_f > 1.0:
                _add_error(errors, "map_generation.json treasure_challenge.accessory_chance_raider must be within [0, 1]")

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
        hazard_anim_interval = _to_float(row.get("hazard_anim_interval", 0.16))
        if hazard_anim_interval is None or hazard_anim_interval < 0.08 or hazard_anim_interval > 0.40:
            _add_error(errors, f"environment_config.json {chapter_key}.hazard_anim_interval must be within [0.08, 0.40]")
        ambient_fx_interval = _to_float(row.get("ambient_fx_interval", 0.24))
        if ambient_fx_interval is None or ambient_fx_interval < 0.12 or ambient_fx_interval > 0.60:
            _add_error(errors, f"environment_config.json {chapter_key}.ambient_fx_interval must be within [0.12, 0.60]")

        visual_profile = row.get("visual_profile", {})
        if not isinstance(visual_profile, dict):
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile must be object")
            continue

        detail_tint = visual_profile.get("detail_tint", "#FFFFFF")
        if not _is_hex_color(detail_tint):
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.detail_tint must be hex color string")

        detail_alpha = _to_float(visual_profile.get("detail_alpha", 0.65))
        if detail_alpha is None or detail_alpha < 0.20 or detail_alpha > 1.00:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.detail_alpha must be within [0.20, 1.00]")

        detail_pulse_speed = _to_float(visual_profile.get("detail_pulse_speed", 0.0))
        if detail_pulse_speed is None or detail_pulse_speed < 0.0 or detail_pulse_speed > 6.0:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.detail_pulse_speed must be within [0.0, 6.0]")

        detail_pulse_amplitude = _to_float(visual_profile.get("detail_pulse_amplitude", 0.0))
        if detail_pulse_amplitude is None or detail_pulse_amplitude < 0.0 or detail_pulse_amplitude > 0.25:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.detail_pulse_amplitude must be within [0.0, 0.25]")

        hazard_alpha_mult = _to_float(visual_profile.get("hazard_alpha_mult", 1.0))
        if hazard_alpha_mult is None or hazard_alpha_mult < 0.40 or hazard_alpha_mult > 1.60:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.hazard_alpha_mult must be within [0.40, 1.60]")

        ambient_alpha_mult = _to_float(visual_profile.get("ambient_alpha_mult", 1.0))
        if ambient_alpha_mult is None or ambient_alpha_mult < 0.40 or ambient_alpha_mult > 1.60:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.ambient_alpha_mult must be within [0.40, 1.60]")

        ambient_wave_speed = _to_float(visual_profile.get("ambient_wave_speed", 0.0))
        if ambient_wave_speed is None or ambient_wave_speed < 0.0 or ambient_wave_speed > 6.0:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.ambient_wave_speed must be within [0.0, 6.0]")

        ambient_wave_amplitude = _to_float(visual_profile.get("ambient_wave_amplitude", 0.0))
        if ambient_wave_amplitude is None or ambient_wave_amplitude < 0.0 or ambient_wave_amplitude > 0.25:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.ambient_wave_amplitude must be within [0.0, 0.25]")

        ambient_scroll_speed_x = _to_float(visual_profile.get("ambient_scroll_speed_x", 0.0))
        if ambient_scroll_speed_x is None or ambient_scroll_speed_x < -8.0 or ambient_scroll_speed_x > 8.0:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.ambient_scroll_speed_x must be within [-8.0, 8.0]")

        ambient_scroll_speed_y = _to_float(visual_profile.get("ambient_scroll_speed_y", 0.0))
        if ambient_scroll_speed_y is None or ambient_scroll_speed_y < -8.0 or ambient_scroll_speed_y > 8.0:
            _add_error(errors, f"environment_config.json {chapter_key}.visual_profile.ambient_scroll_speed_y must be within [-8.0, 8.0]")


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


def _validate_quality_baseline_targets(data: dict[str, Any], errors: list[str]) -> None:
    scenarios = data.get("scenarios")
    targets = data.get("targets")
    compatibility = data.get("compatibility_matrix")
    required_scenarios = {
        "menu_idle",
        "game_world_idle",
        "game_world_elite_pressure_medium",
        "game_world_elite_pressure_high",
        "game_world_elite_pressure_extreme",
        "game_world_boss_pressure_endurance",
    }

    if not isinstance(scenarios, dict) or not scenarios:
        _add_error(errors, "quality_baseline_targets.json scenarios must be non-empty object")
    else:
        for scenario_id in required_scenarios:
            row = scenarios.get(scenario_id)
            if not isinstance(row, dict):
                _add_error(errors, f"quality_baseline_targets.json scenarios missing '{scenario_id}'")
                continue

            scene = row.get("scene")
            warmup_frames = row.get("warmup_frames")
            sample_frames = row.get("sample_frames")
            setup = row.get("setup", "none")

            if not isinstance(scene, str) or not scene.startswith("res://"):
                _add_error(errors, f"quality_baseline_targets.json scenarios.{scenario_id}.scene must start with 'res://'")
            if not isinstance(warmup_frames, int) or warmup_frames < 0 or warmup_frames > 300:
                _add_error(errors, f"quality_baseline_targets.json scenarios.{scenario_id}.warmup_frames must be int within [0, 300]")
            if not isinstance(sample_frames, int) or sample_frames < 60 or sample_frames > 1800:
                _add_error(errors, f"quality_baseline_targets.json scenarios.{scenario_id}.sample_frames must be int within [60, 1800]")
            if not isinstance(setup, str) or setup not in {"none", "elite_pressure_medium", "elite_pressure_high", "elite_pressure_extreme", "boss_pressure_endurance"}:
                _add_error(errors, f"quality_baseline_targets.json scenarios.{scenario_id}.setup must be one of none/elite_pressure_medium/elite_pressure_high/elite_pressure_extreme/boss_pressure_endurance")

    if not isinstance(targets, dict) or not targets:
        _add_error(errors, "quality_baseline_targets.json targets must be non-empty object")
    else:
        frame_time = targets.get("frame_time_ms")
        memory = targets.get("memory_mb")
        node_pressure = targets.get("node_pressure")
        alert_grading = targets.get("alert_grading")

        if not isinstance(frame_time, dict) or not frame_time:
            _add_error(errors, "quality_baseline_targets.json targets.frame_time_ms must be non-empty object")
        else:
            for scenario_id in required_scenarios:
                row = frame_time.get(scenario_id)
                if not isinstance(row, dict):
                    _add_error(errors, f"quality_baseline_targets.json targets.frame_time_ms missing '{scenario_id}'")
                    continue
                avg_max = _to_float(row.get("avg_max"))
                p95_max = _to_float(row.get("p95_max"))
                if avg_max is None or avg_max <= 0.0 or avg_max > 120.0:
                    _add_error(errors, f"quality_baseline_targets.json targets.frame_time_ms.{scenario_id}.avg_max must be within (0, 120]")
                if p95_max is None or p95_max <= 0.0 or p95_max > 200.0:
                    _add_error(errors, f"quality_baseline_targets.json targets.frame_time_ms.{scenario_id}.p95_max must be within (0, 200]")
                if avg_max is not None and p95_max is not None and p95_max < avg_max:
                    _add_error(errors, f"quality_baseline_targets.json targets.frame_time_ms.{scenario_id}.p95_max cannot be lower than avg_max")

        if not isinstance(memory, dict) or not memory:
            _add_error(errors, "quality_baseline_targets.json targets.memory_mb must be non-empty object")
        else:
            for scenario_id in required_scenarios:
                row = memory.get(scenario_id)
                if not isinstance(row, dict):
                    _add_error(errors, f"quality_baseline_targets.json targets.memory_mb missing '{scenario_id}'")
                    continue
                peak_max = _to_float(row.get("peak_max"))
                if peak_max is None or peak_max < 64.0 or peak_max > 4096.0:
                    _add_error(errors, f"quality_baseline_targets.json targets.memory_mb.{scenario_id}.peak_max must be within [64, 4096]")

        if not isinstance(node_pressure, dict) or not node_pressure:
            _add_error(errors, "quality_baseline_targets.json targets.node_pressure must be non-empty object")
        else:
            for key in ("enemy_peak_warning", "projectile_peak_warning", "pickup_peak_warning"):
                value = node_pressure.get(key)
                if not isinstance(value, int) or value < 1:
                    _add_error(errors, f"quality_baseline_targets.json targets.node_pressure.{key} must be int >= 1")

        if not isinstance(alert_grading, dict) or not alert_grading:
            _add_error(errors, "quality_baseline_targets.json targets.alert_grading must be non-empty object")
        else:
            frame_warning = _to_float(alert_grading.get("frame_time_ratio_warning"))
            frame_critical = _to_float(alert_grading.get("frame_time_ratio_critical"))
            memory_warning = _to_float(alert_grading.get("memory_ratio_warning"))
            memory_critical = _to_float(alert_grading.get("memory_ratio_critical"))
            pressure_warning = _to_float(alert_grading.get("node_pressure_ratio_warning"))
            pressure_critical = _to_float(alert_grading.get("node_pressure_ratio_critical"))

            if frame_warning is None or frame_warning < 1.0 or frame_warning > 2.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.frame_time_ratio_warning must be within [1.0, 2.0]")
            if frame_critical is None or frame_critical < 1.0 or frame_critical > 3.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.frame_time_ratio_critical must be within [1.0, 3.0]")
            if memory_warning is None or memory_warning < 1.0 or memory_warning > 2.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.memory_ratio_warning must be within [1.0, 2.0]")
            if memory_critical is None or memory_critical < 1.0 or memory_critical > 3.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.memory_ratio_critical must be within [1.0, 3.0]")
            if pressure_warning is None or pressure_warning < 1.0 or pressure_warning > 2.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.node_pressure_ratio_warning must be within [1.0, 2.0]")
            if pressure_critical is None or pressure_critical < 1.0 or pressure_critical > 3.0:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.node_pressure_ratio_critical must be within [1.0, 3.0]")

            if frame_warning is not None and frame_critical is not None and frame_critical < frame_warning:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.frame_time_ratio_critical cannot be lower than frame_time_ratio_warning")
            if memory_warning is not None and memory_critical is not None and memory_critical < memory_warning:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.memory_ratio_critical cannot be lower than memory_ratio_warning")
            if pressure_warning is not None and pressure_critical is not None and pressure_critical < pressure_warning:
                _add_error(errors, "quality_baseline_targets.json targets.alert_grading.node_pressure_ratio_critical cannot be lower than node_pressure_ratio_warning")

    if not isinstance(compatibility, dict) or not compatibility:
        _add_error(errors, "quality_baseline_targets.json compatibility_matrix must be non-empty object")
    else:
        platforms = compatibility.get("platforms")
        resolutions = compatibility.get("resolutions")
        required_actions = compatibility.get("required_actions")

        if not isinstance(platforms, list) or not platforms:
            _add_error(errors, "quality_baseline_targets.json compatibility_matrix.platforms must be non-empty array")
        else:
            for idx, row in enumerate(platforms):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"quality_baseline_targets.json compatibility_matrix.platforms[{idx}] must be non-empty string")

        if not isinstance(resolutions, list) or not resolutions:
            _add_error(errors, "quality_baseline_targets.json compatibility_matrix.resolutions must be non-empty array")
        else:
            for idx, row in enumerate(resolutions):
                if not isinstance(row, str) or "x" not in row:
                    _add_error(errors, f"quality_baseline_targets.json compatibility_matrix.resolutions[{idx}] must be WxH string")

        if not isinstance(required_actions, list) or not required_actions:
            _add_error(errors, "quality_baseline_targets.json compatibility_matrix.required_actions must be non-empty array")
        else:
            for idx, row in enumerate(required_actions):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"quality_baseline_targets.json compatibility_matrix.required_actions[{idx}] must be non-empty string")


def _validate_release_gate_targets(data: dict[str, Any], errors: list[str]) -> None:
    channel = data.get("channel")
    alert_limits = data.get("baseline_alert_limits")
    scenario_requirements = data.get("scenario_requirements")
    compatibility_requirements = data.get("compatibility_requirements")
    publish_blockers = data.get("publish_blockers")

    if not isinstance(channel, str) or not channel.strip():
        _add_error(errors, "release_gate_targets.json channel must be non-empty string")

    if not isinstance(alert_limits, dict) or not alert_limits:
        _add_error(errors, "release_gate_targets.json baseline_alert_limits must be non-empty object")
    else:
        for key in ("max_total", "max_critical", "max_warning"):
            value = alert_limits.get(key)
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"release_gate_targets.json baseline_alert_limits.{key} must be int >= 0")

    if not isinstance(scenario_requirements, dict) or not scenario_requirements:
        _add_error(errors, "release_gate_targets.json scenario_requirements must be non-empty object")
    else:
        must_include = scenario_requirements.get("must_include")
        if not isinstance(must_include, list) or not must_include:
            _add_error(errors, "release_gate_targets.json scenario_requirements.must_include must be non-empty array")
        else:
            for idx, row in enumerate(must_include):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"release_gate_targets.json scenario_requirements.must_include[{idx}] must be non-empty string")

    if not isinstance(compatibility_requirements, dict) or not compatibility_requirements:
        _add_error(errors, "release_gate_targets.json compatibility_requirements must be non-empty object")
    else:
        required_actions = compatibility_requirements.get("required_actions_with_events")
        required_markers = compatibility_requirements.get("required_platform_markers")
        if not isinstance(required_actions, list) or not required_actions:
            _add_error(errors, "release_gate_targets.json compatibility_requirements.required_actions_with_events must be non-empty array")
        else:
            for idx, row in enumerate(required_actions):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"release_gate_targets.json compatibility_requirements.required_actions_with_events[{idx}] must be non-empty string")

        if not isinstance(required_markers, list) or not required_markers:
            _add_error(errors, "release_gate_targets.json compatibility_requirements.required_platform_markers must be non-empty array")
        else:
            for idx, row in enumerate(required_markers):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"release_gate_targets.json compatibility_requirements.required_platform_markers[{idx}] must be non-empty string")

    if not isinstance(publish_blockers, dict) or not publish_blockers:
        _add_error(errors, "release_gate_targets.json publish_blockers must be non-empty object")
    else:
        for key in (
            "require_baseline_json",
            "require_baseline_markdown",
            "require_zero_critical_alerts",
            "require_zero_warning_alerts",
        ):
            value = publish_blockers.get(key)
            if not isinstance(value, bool):
                _add_error(errors, f"release_gate_targets.json publish_blockers.{key} must be bool")


def _validate_compatibility_rehearsal_targets(data: dict[str, Any], errors: list[str]) -> None:
    channel = data.get("channel")
    profiles = data.get("profiles")
    required_actions = data.get("required_actions")
    thresholds = data.get("thresholds")
    publish_blockers = data.get("publish_blockers")

    if not isinstance(channel, str) or not channel.strip():
        _add_error(errors, "compatibility_rehearsal_targets.json channel must be non-empty string")

    if not isinstance(profiles, list) or not profiles:
        _add_error(errors, "compatibility_rehearsal_targets.json profiles must be non-empty array")
    else:
        for idx, profile in enumerate(profiles):
            if not isinstance(profile, dict):
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}] must be object")
                continue

            profile_id = profile.get("id")
            platform_marker = profile.get("platform_marker")
            resolution = profile.get("resolution")
            input_mode = profile.get("input_mode")
            renderer = profile.get("renderer")
            required_scenes = profile.get("required_scenes")

            if not isinstance(profile_id, str) or not profile_id.strip():
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].id must be non-empty string")
            if not isinstance(platform_marker, str) or not platform_marker.strip():
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].platform_marker must be non-empty string")

            if not isinstance(resolution, str) or "x" not in resolution:
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].resolution must be WxH string")
            else:
                parts = resolution.lower().split("x")
                if len(parts) != 2 or not parts[0].strip().isdigit() or not parts[1].strip().isdigit():
                    _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].resolution must be WxH numeric string")
                else:
                    width = int(parts[0].strip())
                    height = int(parts[1].strip())
                    if width < 640 or height < 360:
                        _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].resolution must be at least 640x360")

            if not isinstance(input_mode, str) or input_mode not in {"keyboard_mouse", "gamepad"}:
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].input_mode must be keyboard_mouse or gamepad")

            if not isinstance(renderer, str) or renderer not in {"forward_plus", "mobile", "compatibility"}:
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].renderer must be forward_plus/mobile/compatibility")

            if not isinstance(required_scenes, list) or not required_scenes:
                _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].required_scenes must be non-empty array")
            else:
                for scene_idx, scene_path in enumerate(required_scenes):
                    if not isinstance(scene_path, str) or not scene_path.startswith("res://"):
                        _add_error(errors, f"compatibility_rehearsal_targets.json profiles[{idx}].required_scenes[{scene_idx}] must be res:// path")

    if not isinstance(required_actions, list) or not required_actions:
        _add_error(errors, "compatibility_rehearsal_targets.json required_actions must be non-empty array")
    else:
        for idx, action in enumerate(required_actions):
            if not isinstance(action, str) or not action.strip():
                _add_error(errors, f"compatibility_rehearsal_targets.json required_actions[{idx}] must be non-empty string")

    if not isinstance(thresholds, dict) or not thresholds:
        _add_error(errors, "compatibility_rehearsal_targets.json thresholds must be non-empty object")
    else:
        min_pass_rate = _to_float(thresholds.get("min_profile_pass_rate"))
        max_profile_failures = thresholds.get("max_profile_failures")
        max_missing_actions = thresholds.get("max_missing_actions")

        if min_pass_rate is None or min_pass_rate < 0.5 or min_pass_rate > 1.0:
            _add_error(errors, "compatibility_rehearsal_targets.json thresholds.min_profile_pass_rate must be within [0.5, 1.0]")
        if not isinstance(max_profile_failures, int) or max_profile_failures < 0:
            _add_error(errors, "compatibility_rehearsal_targets.json thresholds.max_profile_failures must be int >= 0")
        if not isinstance(max_missing_actions, int) or max_missing_actions < 0:
            _add_error(errors, "compatibility_rehearsal_targets.json thresholds.max_missing_actions must be int >= 0")

    if not isinstance(publish_blockers, dict) or not publish_blockers:
        _add_error(errors, "compatibility_rehearsal_targets.json publish_blockers must be non-empty object")
    else:
        for key in (
            "require_release_gate_json",
            "require_release_gate_markdown",
            "require_zero_profile_failures",
        ):
            value = publish_blockers.get(key)
            if not isinstance(value, bool):
                _add_error(errors, f"compatibility_rehearsal_targets.json publish_blockers.{key} must be bool")


def _validate_resource_acceptance_targets(data: dict[str, Any], errors: list[str]) -> None:
    channel = data.get("channel")
    required_fields = data.get("required_fields")
    scene_map = data.get("acceptance_scene_map")
    scene_matrix = data.get("acceptance_scene_matrix")
    scene_visual_requirements = data.get("scene_visual_requirements")
    texture_map = data.get("preview_texture_map")
    required_ready = data.get("required_production_ready_ids")
    profile_policy = data.get("acceptance_profile_policy")
    trend_baseline = data.get("trend_baseline")
    thresholds = data.get("thresholds")

    categories = (
        "characters",
        "weapons",
        "passives",
        "accessories",
        "enemies",
        "evolutions",
        "meta_upgrades",
        "forge_recipes",
    )

    if not isinstance(channel, str) or not channel.strip():
        _add_error(errors, "resource_acceptance_targets.json channel must be non-empty string")

    if not isinstance(required_fields, list) or not required_fields:
        _add_error(errors, "resource_acceptance_targets.json required_fields must be non-empty array")
    else:
        required_field_set = {
            "display_name",
            "material_profile",
            "asset_state",
            "preview_texture",
            "acceptance_scene",
            "acceptance_profile",
            "acceptance_tier",
        }
        for idx, row in enumerate(required_fields):
            if not isinstance(row, str) or not row.strip():
                _add_error(errors, f"resource_acceptance_targets.json required_fields[{idx}] must be non-empty string")
        if not required_field_set.issubset(set(required_fields)):
            _add_error(errors, "resource_acceptance_targets.json required_fields missing mandatory entries")

    if not isinstance(scene_map, dict) or not scene_map:
        _add_error(errors, "resource_acceptance_targets.json acceptance_scene_map must be non-empty object")
    else:
        for category in categories:
            path = scene_map.get(category)
            if not isinstance(path, str) or not path.startswith("res://"):
                _add_error(errors, f"resource_acceptance_targets.json acceptance_scene_map.{category} must be res:// path")

    if not isinstance(scene_matrix, dict) or not scene_matrix:
        _add_error(errors, "resource_acceptance_targets.json acceptance_scene_matrix must be non-empty object")
    else:
        for category in categories:
            rows = scene_matrix.get(category)
            if not isinstance(rows, list) or not rows:
                _add_error(errors, f"resource_acceptance_targets.json acceptance_scene_matrix.{category} must be non-empty array")
                continue
            for idx, row in enumerate(rows):
                if not isinstance(row, str) or not row.startswith("res://"):
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_scene_matrix.{category}[{idx}] must be res:// path")

    if not isinstance(scene_visual_requirements, dict) or not scene_visual_requirements:
        _add_error(errors, "resource_acceptance_targets.json scene_visual_requirements must be non-empty object")
    else:
        allowed_rules = {
            "exists",
            "non_null",
            "non_empty_string",
            "array_non_empty",
            "float_gt_zero",
            "bool_true",
        }
        for category in categories:
            rows = scene_visual_requirements.get(category)
            if not isinstance(rows, list) or not rows:
                _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category} must be non-empty array")
                continue
            for idx, row in enumerate(rows):
                if not isinstance(row, dict) or not row:
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}] must be non-empty object")
                    continue
                scene_path = row.get("scene")
                node_path = row.get("node_path")
                node_type = row.get("node_type")
                rule = row.get("rule")
                prop = row.get("property")
                if not isinstance(scene_path, str) or not scene_path.startswith("res://"):
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].scene must be res:// path")
                if not isinstance(node_path, str) or not node_path.strip():
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].node_path must be non-empty string")
                if not isinstance(node_type, str) or not node_type.strip():
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].node_type must be non-empty string")
                if not isinstance(rule, str) or rule not in allowed_rules:
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].rule must be one of {sorted(allowed_rules)}")
                if rule != "exists" and (not isinstance(prop, str) or not prop.strip()):
                    _add_error(errors, f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].property must be non-empty when rule != exists")

    if not isinstance(texture_map, dict) or not texture_map:
        _add_error(errors, "resource_acceptance_targets.json preview_texture_map must be non-empty object")
    else:
        for category in categories:
            path = texture_map.get(category)
            if not isinstance(path, str) or not path.startswith("res://"):
                _add_error(errors, f"resource_acceptance_targets.json preview_texture_map.{category} must be res:// path")

    if not isinstance(required_ready, dict) or not required_ready:
        _add_error(errors, "resource_acceptance_targets.json required_production_ready_ids must be non-empty object")
    else:
        for category in categories:
            rows = required_ready.get(category)
            if not isinstance(rows, list) or not rows:
                _add_error(errors, f"resource_acceptance_targets.json required_production_ready_ids.{category} must be non-empty array")
                continue
            for idx, row in enumerate(rows):
                if not isinstance(row, str) or not row.strip():
                    _add_error(errors, f"resource_acceptance_targets.json required_production_ready_ids.{category}[{idx}] must be non-empty string")

    profile_names: set[str] = set()
    if not isinstance(profile_policy, dict) or not profile_policy:
        _add_error(errors, "resource_acceptance_targets.json acceptance_profile_policy must be non-empty object")
    else:
        required_ready_profile_tier = profile_policy.get("required_ready_profile_tier")
        profiles = profile_policy.get("profiles")
        category_profile_map = profile_policy.get("category_profile_map")

        if not isinstance(required_ready_profile_tier, str) or required_ready_profile_tier not in {"candidate", "ready"}:
            _add_error(errors, "resource_acceptance_targets.json acceptance_profile_policy.required_ready_profile_tier must be candidate or ready")

        if not isinstance(profiles, dict) or not profiles:
            _add_error(errors, "resource_acceptance_targets.json acceptance_profile_policy.profiles must be non-empty object")
        else:
            for profile_name, row in profiles.items():
                profile_names.add(str(profile_name))
                if not isinstance(profile_name, str) or not profile_name.strip():
                    _add_error(errors, "resource_acceptance_targets.json acceptance_profile_policy.profiles key must be non-empty string")
                    continue
                if not isinstance(row, dict) or not row:
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.profiles.{profile_name} must be non-empty object")
                    continue
                tier = row.get("tier")
                report_bucket = row.get("report_bucket")
                if not isinstance(tier, str) or tier not in {"candidate", "ready"}:
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.profiles.{profile_name}.tier must be candidate or ready")
                if not isinstance(report_bucket, str) or not report_bucket.strip():
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.profiles.{profile_name}.report_bucket must be non-empty string")

        if not isinstance(category_profile_map, dict) or not category_profile_map:
            _add_error(errors, "resource_acceptance_targets.json acceptance_profile_policy.category_profile_map must be non-empty object")
        else:
            for category in categories:
                row = category_profile_map.get(category)
                if not isinstance(row, dict) or not row:
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category} must be non-empty object")
                    continue
                candidate_profile = row.get("production_candidate")
                ready_profile = row.get("production_ready")
                if not isinstance(candidate_profile, str) or not candidate_profile.strip():
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category}.production_candidate must be non-empty string")
                elif profile_names and candidate_profile not in profile_names:
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category}.production_candidate must reference profiles key")
                if not isinstance(ready_profile, str) or not ready_profile.strip():
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category}.production_ready must be non-empty string")
                elif profile_names and ready_profile not in profile_names:
                    _add_error(errors, f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category}.production_ready must reference profiles key")

    if not isinstance(thresholds, dict) or not thresholds:
        _add_error(errors, "resource_acceptance_targets.json thresholds must be non-empty object")
    else:
        min_ready_per_category = thresholds.get("min_ready_per_category")
        min_ready_ratio_per_category = _to_float(thresholds.get("min_ready_ratio_per_category"))
        min_scene_smokes_per_category = thresholds.get("min_scene_smokes_per_category")
        min_visual_checks_per_category = thresholds.get("min_visual_checks_per_category")
        max_visual_failures = thresholds.get("max_visual_failures")
        max_profile_mismatches = thresholds.get("max_profile_mismatches")
        max_trend_regressions = thresholds.get("max_trend_regressions")
        max_failures = thresholds.get("max_failures")
        if not isinstance(min_ready_per_category, int) or min_ready_per_category < 1:
            _add_error(errors, "resource_acceptance_targets.json thresholds.min_ready_per_category must be int >= 1")
        if min_ready_ratio_per_category is None or min_ready_ratio_per_category < 0.1 or min_ready_ratio_per_category > 1.0:
            _add_error(errors, "resource_acceptance_targets.json thresholds.min_ready_ratio_per_category must be within [0.1, 1.0]")
        if not isinstance(min_scene_smokes_per_category, int) or min_scene_smokes_per_category < 1:
            _add_error(errors, "resource_acceptance_targets.json thresholds.min_scene_smokes_per_category must be int >= 1")
        if not isinstance(min_visual_checks_per_category, int) or min_visual_checks_per_category < 1:
            _add_error(errors, "resource_acceptance_targets.json thresholds.min_visual_checks_per_category must be int >= 1")
        if not isinstance(max_visual_failures, int) or max_visual_failures < 0:
            _add_error(errors, "resource_acceptance_targets.json thresholds.max_visual_failures must be int >= 0")
        if not isinstance(max_profile_mismatches, int) or max_profile_mismatches < 0:
            _add_error(errors, "resource_acceptance_targets.json thresholds.max_profile_mismatches must be int >= 0")
        if not isinstance(max_trend_regressions, int) or max_trend_regressions < 0:
            _add_error(errors, "resource_acceptance_targets.json thresholds.max_trend_regressions must be int >= 0")
        if not isinstance(max_failures, int) or max_failures < 0:
            _add_error(errors, "resource_acceptance_targets.json thresholds.max_failures must be int >= 0")

    if not isinstance(trend_baseline, dict) or not trend_baseline:
        _add_error(errors, "resource_acceptance_targets.json trend_baseline must be non-empty object")
    else:
        bucket_ready_ratio_min = trend_baseline.get("bucket_ready_ratio_min")
        max_category_ratio_drop = _to_float(trend_baseline.get("max_category_ratio_drop"))
        max_bucket_ratio_drop = _to_float(trend_baseline.get("max_bucket_ratio_drop"))

        if not isinstance(bucket_ready_ratio_min, dict) or not bucket_ready_ratio_min:
            _add_error(errors, "resource_acceptance_targets.json trend_baseline.bucket_ready_ratio_min must be non-empty object")
        else:
            for bucket in ("menu", "combat", "ui"):
                ratio = _to_float(bucket_ready_ratio_min.get(bucket))
                if ratio is None or ratio < 0.1 or ratio > 1.0:
                    _add_error(errors, f"resource_acceptance_targets.json trend_baseline.bucket_ready_ratio_min.{bucket} must be within [0.1, 1.0]")

        if max_category_ratio_drop is None or max_category_ratio_drop < 0.0 or max_category_ratio_drop > 1.0:
            _add_error(errors, "resource_acceptance_targets.json trend_baseline.max_category_ratio_drop must be within [0.0, 1.0]")
        if max_bucket_ratio_drop is None or max_bucket_ratio_drop < 0.0 or max_bucket_ratio_drop > 1.0:
            _add_error(errors, "resource_acceptance_targets.json trend_baseline.max_bucket_ratio_drop must be within [0.0, 1.0]")


def _validate_visual_snapshot_targets(data: dict[str, Any], errors: list[str]) -> None:
    channel = data.get("channel")
    snapshots = data.get("snapshots")
    precision = data.get("precision")
    backend_profiles = data.get("backend_profiles")
    thresholds = data.get("thresholds")
    baseline_alignment = data.get("baseline_alignment")
    diff_whitelist = data.get("diff_whitelist")
    whitelist_policy = data.get("whitelist_policy")
    backend_attribution = data.get("backend_attribution")
    whitelist_convergence = data.get("whitelist_convergence")
    exception_lifecycle = data.get("exception_lifecycle")
    strategy_orchestration = data.get("strategy_orchestration")
    release_gate_templates = data.get("release_gate_templates")
    backend_matrix_governance = data.get("backend_matrix_governance")
    approval_workflow = data.get("approval_workflow")
    approval_audit_trail = data.get("approval_audit_trail")
    approval_history_archive = data.get("approval_history_archive")
    approval_threshold_templates = data.get("approval_threshold_templates")
    release_candidate_tracking = data.get("release_candidate_tracking")
    report_layers = data.get("report_layers")
    cross_version_baseline = data.get("cross_version_baseline")

    if not isinstance(channel, str) or not channel.strip():
        _add_error(errors, "visual_snapshot_targets.json channel must be non-empty string")
    elif channel != "chapter_snapshot_v12":
        _add_error(errors, "visual_snapshot_targets.json channel must be chapter_snapshot_v12")

    if not isinstance(snapshots, dict) or not snapshots:
        _add_error(errors, "visual_snapshot_targets.json snapshots must be a non-empty object")
        return

    for snapshot_id, row in snapshots.items():
        if not isinstance(snapshot_id, str) or not snapshot_id.strip():
            _add_error(errors, "visual_snapshot_targets.json snapshots key must be non-empty string")
            continue
        if not isinstance(row, dict):
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id} must be object")
            continue

        scene = row.get("scene")
        setup = row.get("setup")
        width = row.get("width")
        height = row.get("height")
        warmup_frames = row.get("warmup_frames")
        capture_frames = row.get("capture_frames")
        opaque_ratio_min = _to_float(row.get("opaque_ratio_min"))
        unique_colors_min = row.get("unique_colors_min")
        luma_min = _to_float(row.get("luma_min"))
        luma_max = _to_float(row.get("luma_max"))

        if not isinstance(scene, str) or not scene.startswith("res://"):
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.scene must be res:// path")
        if not isinstance(setup, str) or not setup:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.setup must be non-empty string")
        if not isinstance(width, int) or width < 320:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.width must be int >= 320")
        if not isinstance(height, int) or height < 180:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.height must be int >= 180")
        if not isinstance(warmup_frames, int) or warmup_frames < 1:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.warmup_frames must be int >= 1")
        if not isinstance(capture_frames, int) or capture_frames < 1:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.capture_frames must be int >= 1")
        if opaque_ratio_min is None or opaque_ratio_min < 0.0 or opaque_ratio_min > 1.0:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.opaque_ratio_min must be within [0.0, 1.0]")
        if not isinstance(unique_colors_min, int) or unique_colors_min < 1:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.unique_colors_min must be int >= 1")
        if luma_min is None or luma_min < 0.0 or luma_min > 1.0:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_min must be within [0.0, 1.0]")
        if luma_max is None or luma_max < 0.0 or luma_max > 1.0:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_max must be within [0.0, 1.0]")
        if luma_min is not None and luma_max is not None and luma_min > luma_max:
            _add_error(errors, f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_min cannot exceed luma_max")

    if not isinstance(precision, dict) or not precision:
        _add_error(errors, "visual_snapshot_targets.json precision must be non-empty object")
    else:
        sample_rounds = precision.get("sample_rounds")
        max_opaque_ratio_stddev = _to_float(precision.get("max_opaque_ratio_stddev"))
        max_luma_stddev = _to_float(precision.get("max_luma_stddev"))
        max_unique_color_stddev_ratio = _to_float(precision.get("max_unique_color_stddev_ratio"))

        if not isinstance(sample_rounds, int) or sample_rounds < 1 or sample_rounds > 8:
            _add_error(errors, "visual_snapshot_targets.json precision.sample_rounds must be int within [1, 8]")
        if max_opaque_ratio_stddev is None or max_opaque_ratio_stddev < 0.0 or max_opaque_ratio_stddev > 0.5:
            _add_error(errors, "visual_snapshot_targets.json precision.max_opaque_ratio_stddev must be within [0.0, 0.5]")
        if max_luma_stddev is None or max_luma_stddev < 0.0 or max_luma_stddev > 0.5:
            _add_error(errors, "visual_snapshot_targets.json precision.max_luma_stddev must be within [0.0, 0.5]")
        if max_unique_color_stddev_ratio is None or max_unique_color_stddev_ratio < 0.0 or max_unique_color_stddev_ratio > 1.0:
            _add_error(errors, "visual_snapshot_targets.json precision.max_unique_color_stddev_ratio must be within [0.0, 1.0]")

    if not isinstance(backend_profiles, dict) or not backend_profiles:
        _add_error(errors, "visual_snapshot_targets.json backend_profiles must be non-empty object")
    else:
        if "default" not in backend_profiles:
            _add_error(errors, "visual_snapshot_targets.json backend_profiles must include 'default'")
        for required_profile in ("linux_headless", "windows_headless"):
            if required_profile not in backend_profiles:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles must include '{required_profile}'")
        for profile_name, row in backend_profiles.items():
            if not isinstance(profile_name, str) or not profile_name.strip():
                _add_error(errors, "visual_snapshot_targets.json backend_profiles key must be non-empty string")
                continue
            if not isinstance(row, dict) or not row:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name} must be non-empty object")
                continue
            max_opaque_drop = _to_float(row.get("max_opaque_ratio_drop"))
            max_unique_drop = _to_float(row.get("max_unique_color_drop_ratio"))
            max_luma_delta_profile = _to_float(row.get("max_luma_delta"))
            unique_scale = _to_float(row.get("unique_colors_min_scale"))
            luma_padding = _to_float(row.get("luma_range_padding"))

            if max_opaque_drop is None or max_opaque_drop < 0.0 or max_opaque_drop > 1.0:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_opaque_ratio_drop must be within [0.0, 1.0]")
            if max_unique_drop is None or max_unique_drop < 0.0 or max_unique_drop > 1.0:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_unique_color_drop_ratio must be within [0.0, 1.0]")
            if max_luma_delta_profile is None or max_luma_delta_profile < 0.0 or max_luma_delta_profile > 1.0:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_luma_delta must be within [0.0, 1.0]")
            if unique_scale is None or unique_scale < 0.5 or unique_scale > 2.0:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name}.unique_colors_min_scale must be within [0.5, 2.0]")
            if luma_padding is None or luma_padding < 0.0 or luma_padding > 0.3:
                _add_error(errors, f"visual_snapshot_targets.json backend_profiles.{profile_name}.luma_range_padding must be within [0.0, 0.3]")

    if not isinstance(baseline_alignment, dict) or not baseline_alignment:
        _add_error(errors, "visual_snapshot_targets.json baseline_alignment must be non-empty object")
    else:
        required_snapshot_ids = baseline_alignment.get("required_snapshot_ids")
        allowed_capture_modes = baseline_alignment.get("allowed_capture_modes")
        if not isinstance(required_snapshot_ids, list) or not required_snapshot_ids:
            _add_error(errors, "visual_snapshot_targets.json baseline_alignment.required_snapshot_ids must be non-empty array")
        else:
            for idx, snapshot_id in enumerate(required_snapshot_ids):
                if not isinstance(snapshot_id, str) or not snapshot_id.strip():
                    _add_error(errors, f"visual_snapshot_targets.json baseline_alignment.required_snapshot_ids[{idx}] must be non-empty string")
                elif isinstance(snapshots, dict) and snapshot_id not in snapshots:
                    _add_error(errors, f"visual_snapshot_targets.json baseline_alignment.required_snapshot_ids[{idx}] must reference snapshots key")

        if not isinstance(allowed_capture_modes, dict) or not allowed_capture_modes:
            _add_error(errors, "visual_snapshot_targets.json baseline_alignment.allowed_capture_modes must be non-empty object")
        else:
            for required_profile in ("default", "linux_headless", "windows_headless"):
                if required_profile not in allowed_capture_modes:
                    _add_error(errors, f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes must include '{required_profile}'")
            for backend_name, modes in allowed_capture_modes.items():
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json baseline_alignment.allowed_capture_modes key must be non-empty string")
                    continue
                if not isinstance(modes, list) or not modes:
                    _add_error(errors, f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes.{backend_name} must be non-empty array")
                    continue
                for idx, mode in enumerate(modes):
                    if not isinstance(mode, str) or not mode.strip():
                        _add_error(errors, f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes.{backend_name}[{idx}] must be non-empty string")

    if diff_whitelist is not None:
        if not isinstance(diff_whitelist, dict):
            _add_error(errors, "visual_snapshot_targets.json diff_whitelist must be object when provided")
        else:
            for backend_name, backend_rows in diff_whitelist.items():
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json diff_whitelist key must be non-empty string")
                    continue
                if not isinstance(backend_rows, dict):
                    _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name} must be object")
                    continue
                for snapshot_id, row in backend_rows.items():
                    if not isinstance(snapshot_id, str) or not snapshot_id.strip():
                        _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name} snapshot key must be non-empty string")
                        continue
                    if isinstance(snapshots, dict) and snapshot_id not in snapshots:
                        _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id} must reference snapshots key")
                    if not isinstance(row, dict) or not row:
                        _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id} must be non-empty object")
                        continue
                    if "reason" in row and (not isinstance(row.get("reason"), str) or not str(row.get("reason", "")).strip()):
                        _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id}.reason must be non-empty string")
                    for numeric_key in ("max_opaque_ratio_drop", "max_unique_color_drop_ratio", "max_luma_delta"):
                        if numeric_key not in row:
                            continue
                        value = _to_float(row.get(numeric_key))
                        if value is None or value < 0.0 or value > 1.0:
                            _add_error(errors, f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id}.{numeric_key} must be within [0.0, 1.0]")

    if not isinstance(whitelist_policy, dict) or not whitelist_policy:
        _add_error(errors, "visual_snapshot_targets.json whitelist_policy must be non-empty object")
    else:
        max_hits = whitelist_policy.get("max_hits")
        max_ratio = _to_float(whitelist_policy.get("max_ratio"))
        if not isinstance(max_hits, int) or max_hits < 0:
            _add_error(errors, "visual_snapshot_targets.json whitelist_policy.max_hits must be int >= 0")
        if max_ratio is None or max_ratio < 0.0 or max_ratio > 1.0:
            _add_error(errors, "visual_snapshot_targets.json whitelist_policy.max_ratio must be within [0.0, 1.0]")

    if not isinstance(backend_attribution, dict) or not backend_attribution:
        _add_error(errors, "visual_snapshot_targets.json backend_attribution must be non-empty object")
    else:
        required_backends = backend_attribution.get("required_backends")
        max_unattributed_regressions = backend_attribution.get("max_unattributed_regressions")
        max_backend_specific_regressions = backend_attribution.get("max_backend_specific_regressions")

        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json backend_attribution.required_backends must be non-empty array")
        else:
            required_backend_set = set()
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json backend_attribution.required_backends[{idx}] must be non-empty string")
                    continue
                required_backend_set.add(backend_name)
            for must_have in ("linux_headless", "windows_headless"):
                if must_have not in required_backend_set:
                    _add_error(errors, f"visual_snapshot_targets.json backend_attribution.required_backends must include '{must_have}'")

        if not isinstance(max_unattributed_regressions, int) or max_unattributed_regressions < 0:
            _add_error(errors, "visual_snapshot_targets.json backend_attribution.max_unattributed_regressions must be int >= 0")
        if not isinstance(max_backend_specific_regressions, int) or max_backend_specific_regressions < 0:
            _add_error(errors, "visual_snapshot_targets.json backend_attribution.max_backend_specific_regressions must be int >= 0")

    if not isinstance(whitelist_convergence, dict) or not whitelist_convergence:
        _add_error(errors, "visual_snapshot_targets.json whitelist_convergence must be non-empty object")
    else:
        stale_run_threshold = whitelist_convergence.get("stale_run_threshold")
        tighten_margin_ratio = _to_float(whitelist_convergence.get("tighten_margin_ratio"))
        max_suggestions = whitelist_convergence.get("max_suggestions")

        if not isinstance(stale_run_threshold, int) or stale_run_threshold < 1:
            _add_error(errors, "visual_snapshot_targets.json whitelist_convergence.stale_run_threshold must be int >= 1")
        if tighten_margin_ratio is None or tighten_margin_ratio < 0.0 or tighten_margin_ratio > 1.0:
            _add_error(errors, "visual_snapshot_targets.json whitelist_convergence.tighten_margin_ratio must be within [0.0, 1.0]")
        if not isinstance(max_suggestions, int) or max_suggestions < 0:
            _add_error(errors, "visual_snapshot_targets.json whitelist_convergence.max_suggestions must be int >= 0")

    if not isinstance(exception_lifecycle, dict) or not exception_lifecycle:
        _add_error(errors, "visual_snapshot_targets.json exception_lifecycle must be non-empty object")
    else:
        expire_idle_runs = exception_lifecycle.get("expire_idle_runs")
        auto_reclaim_hit_streak = exception_lifecycle.get("auto_reclaim_hit_streak")
        max_expired_entries = exception_lifecycle.get("max_expired_entries")
        max_reclaim_candidates = exception_lifecycle.get("max_reclaim_candidates")

        if not isinstance(expire_idle_runs, int) or expire_idle_runs < 1:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle.expire_idle_runs must be int >= 1")
        if not isinstance(auto_reclaim_hit_streak, int) or auto_reclaim_hit_streak < 1:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle.auto_reclaim_hit_streak must be int >= 1")
        if not isinstance(max_expired_entries, int) or max_expired_entries < 0:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle.max_expired_entries must be int >= 0")
        if not isinstance(max_reclaim_candidates, int) or max_reclaim_candidates < 0:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle.max_reclaim_candidates must be int >= 0")

    if not isinstance(strategy_orchestration, dict) or not strategy_orchestration:
        _add_error(errors, "visual_snapshot_targets.json strategy_orchestration must be non-empty object")
    else:
        default_strategy = strategy_orchestration.get("default_strategy")
        strategies = strategy_orchestration.get("strategies")
        templates = strategy_orchestration.get("templates")

        if not isinstance(default_strategy, str) or not default_strategy.strip():
            _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.default_strategy must be non-empty string")

        if not isinstance(strategies, dict) or not strategies:
            _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.strategies must be non-empty object")
            strategies = {}
        if not isinstance(templates, dict) or not templates:
            _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.templates must be non-empty object")
            templates = {}

        if isinstance(default_strategy, str) and default_strategy and default_strategy not in strategies:
            _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.default_strategy must reference strategies key")

        allowed_template_sections = {
            "thresholds",
            "whitelist_policy",
            "backend_attribution",
            "whitelist_convergence",
            "exception_lifecycle",
            "cross_version_baseline",
            "report_layers",
        }

        for strategy_name, strategy_row in strategies.items():
            if not isinstance(strategy_name, str) or not strategy_name.strip():
                _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.strategies key must be non-empty string")
                continue
            if not isinstance(strategy_row, dict) or not strategy_row:
                _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name} must be non-empty object")
                continue
            template_name = strategy_row.get("template")
            if not isinstance(template_name, str) or not template_name.strip():
                _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name}.template must be non-empty string")
            elif template_name not in templates:
                _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name}.template must reference templates key")

        for template_name, template_row in templates.items():
            if not isinstance(template_name, str) or not template_name.strip():
                _add_error(errors, "visual_snapshot_targets.json strategy_orchestration.templates key must be non-empty string")
                continue
            if not isinstance(template_row, dict) or not template_row:
                _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name} must be non-empty object")
                continue
            for section_key, section_row in template_row.items():
                if section_key not in allowed_template_sections:
                    _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name}.{section_key} is not a supported override section")
                    continue
                if not isinstance(section_row, dict) or not section_row:
                    _add_error(errors, f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name}.{section_key} must be non-empty object")

    if not isinstance(release_gate_templates, dict) or not release_gate_templates:
        _add_error(errors, "visual_snapshot_targets.json release_gate_templates must be non-empty object")
    else:
        required_strategies = release_gate_templates.get("required_strategies")
        required_strategy_bindings = release_gate_templates.get("required_strategy_bindings")
        ci_mode_bindings = release_gate_templates.get("ci_mode_bindings")
        release_checklist = release_gate_templates.get("release_checklist")

        if not isinstance(required_strategies, list) or not required_strategies:
            _add_error(errors, "visual_snapshot_targets.json release_gate_templates.required_strategies must be non-empty array")
            required_strategies = []
        else:
            for idx, strategy_name in enumerate(required_strategies):
                if not isinstance(strategy_name, str) or not strategy_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategies[{idx}] must be non-empty string")

        if not isinstance(required_strategy_bindings, dict) or not required_strategy_bindings:
            _add_error(errors, "visual_snapshot_targets.json release_gate_templates.required_strategy_bindings must be non-empty object")
            required_strategy_bindings = {}
        else:
            for strategy_name, template_name in required_strategy_bindings.items():
                if not isinstance(strategy_name, str) or not strategy_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json release_gate_templates.required_strategy_bindings key must be non-empty string")
                    continue
                if not isinstance(template_name, str) or not template_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must be non-empty string")

        if not isinstance(ci_mode_bindings, dict) or not ci_mode_bindings:
            _add_error(errors, "visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must be non-empty object")
            ci_mode_bindings = {}
        else:
            for mode_name, strategy_name in ci_mode_bindings.items():
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json release_gate_templates.ci_mode_bindings key must be non-empty string")
                    continue
                if not isinstance(strategy_name, str) or not strategy_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings.{mode_name} must be non-empty string")

        if not isinstance(release_checklist, dict) or not release_checklist:
            _add_error(errors, "visual_snapshot_targets.json release_gate_templates.release_checklist must be non-empty object")
        else:
            required_reports = release_checklist.get("required_reports")
            required_strategies_for_publish = release_checklist.get("required_strategies_for_publish")
            require_zero_warnings_for = release_checklist.get("require_zero_warnings_for")
            max_checklist_failures = release_checklist.get("max_checklist_failures")

            if not isinstance(required_reports, list) or not required_reports:
                _add_error(errors, "visual_snapshot_targets.json release_gate_templates.release_checklist.required_reports must be non-empty array")
            else:
                for idx, report_path in enumerate(required_reports):
                    if not isinstance(report_path, str) or not report_path.strip() or not report_path.startswith("user://"):
                        _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_reports[{idx}] must be non-empty user:// path")

            if not isinstance(required_strategies_for_publish, list) or not required_strategies_for_publish:
                _add_error(errors, "visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish must be non-empty array")
            else:
                for idx, strategy_name in enumerate(required_strategies_for_publish):
                    if not isinstance(strategy_name, str) or not strategy_name.strip():
                        _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish[{idx}] must be non-empty string")

            if not isinstance(require_zero_warnings_for, list):
                _add_error(errors, "visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for must be array")
            else:
                for idx, strategy_name in enumerate(require_zero_warnings_for):
                    if not isinstance(strategy_name, str) or not strategy_name.strip():
                        _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for[{idx}] must be non-empty string")

            if not isinstance(max_checklist_failures, int) or max_checklist_failures < 0:
                _add_error(errors, "visual_snapshot_targets.json release_gate_templates.release_checklist.max_checklist_failures must be int >= 0")

        if isinstance(required_strategies, list) and isinstance(required_strategy_bindings, dict):
            for strategy_name in required_strategies:
                if isinstance(strategy_name, str) and strategy_name and strategy_name not in required_strategy_bindings:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings must include '{strategy_name}'")

        strategies_row = strategy_orchestration.get("strategies", {}) if isinstance(strategy_orchestration, dict) else {}
        templates_row = strategy_orchestration.get("templates", {}) if isinstance(strategy_orchestration, dict) else {}

        if isinstance(required_strategy_bindings, dict):
            for strategy_name, template_name in required_strategy_bindings.items():
                if not isinstance(strategy_name, str) or not strategy_name:
                    continue
                if isinstance(strategies_row, dict) and strategy_name not in strategies_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must reference strategy_orchestration.strategies")
                    continue
                if isinstance(strategies_row, dict):
                    strategy_row = strategies_row.get(strategy_name, {})
                    if isinstance(strategy_row, dict):
                        actual_template = strategy_row.get("template")
                        if isinstance(template_name, str) and template_name and actual_template != template_name:
                            _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must match strategy_orchestration template")
                if isinstance(template_name, str) and template_name and isinstance(templates_row, dict) and template_name not in templates_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must reference strategy_orchestration.templates")

        if isinstance(ci_mode_bindings, dict):
            for mode_name, strategy_name in ci_mode_bindings.items():
                if not isinstance(mode_name, str) or not mode_name:
                    continue
                if isinstance(strategy_name, str) and strategy_name and isinstance(strategies_row, dict) and strategy_name not in strategies_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings.{mode_name} must reference strategy_orchestration.strategies")

        if isinstance(release_checklist, dict):
            publish_strategies = release_checklist.get("required_strategies_for_publish", [])
            zero_warning_strategies = release_checklist.get("require_zero_warnings_for", [])
            if isinstance(publish_strategies, list):
                for strategy_name in publish_strategies:
                    if isinstance(strategy_name, str) and strategy_name and isinstance(required_strategies, list) and strategy_name not in required_strategies:
                        _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish must be subset of required_strategies ({strategy_name})")
            if isinstance(zero_warning_strategies, list):
                for strategy_name in zero_warning_strategies:
                    if isinstance(strategy_name, str) and strategy_name and isinstance(required_strategies, list) and strategy_name not in required_strategies:
                        _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for must be subset of required_strategies ({strategy_name})")

    if not isinstance(backend_matrix_governance, dict) or not backend_matrix_governance:
        _add_error(errors, "visual_snapshot_targets.json backend_matrix_governance must be non-empty object")
    else:
        required_backend_matrix = backend_matrix_governance.get("required_backend_matrix")
        required_run_modes = backend_matrix_governance.get("required_run_modes")
        max_missing_backend_matrix = backend_matrix_governance.get("max_missing_backend_matrix")
        max_missing_run_mode_bindings = backend_matrix_governance.get("max_missing_run_mode_bindings")

        required_backend_set: set[str] = set()
        if not isinstance(required_backend_matrix, list) or not required_backend_matrix:
            _add_error(errors, "visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backend_matrix):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix[{idx}] must be non-empty string")
                    continue
                required_backend_set.add(backend_name)
            for must_have in ("linux_headless", "windows_headless"):
                if must_have not in required_backend_set:
                    _add_error(errors, f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{must_have}'")

        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json backend_matrix_governance.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json backend_matrix_governance.required_run_modes[{idx}] must be non-empty string")

        if not isinstance(max_missing_backend_matrix, int) or max_missing_backend_matrix < 0:
            _add_error(errors, "visual_snapshot_targets.json backend_matrix_governance.max_missing_backend_matrix must be int >= 0")
        if not isinstance(max_missing_run_mode_bindings, int) or max_missing_run_mode_bindings < 0:
            _add_error(errors, "visual_snapshot_targets.json backend_matrix_governance.max_missing_run_mode_bindings must be int >= 0")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if isinstance(required_run_modes, list) and isinstance(ci_mode_bindings_row, dict):
            for mode_name in required_run_modes:
                if isinstance(mode_name, str) and mode_name and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for backend_matrix_governance.required_run_modes")

    if not isinstance(approval_workflow, dict) or not approval_workflow:
        _add_error(errors, "visual_snapshot_targets.json approval_workflow must be non-empty object")
    else:
        required_report_sections = approval_workflow.get("required_report_sections")
        require_zero_blockers = approval_workflow.get("require_zero_blockers")
        require_zero_warnings_for_strategies = approval_workflow.get("require_zero_warnings_for_strategies")
        max_approval_failures = approval_workflow.get("max_approval_failures")

        allowed_sections = {
            "Snapshots",
            "Trend",
            "Whitelist",
            "Backend Attribution",
            "Release Manifest",
            "Backend Matrix Governance",
            "Approval Workflow",
            "Approval Audit Trail",
            "Approval History Archive",
            "Approval Template",
            "Release Candidate Tracking",
        }

        if not isinstance(required_report_sections, list) or not required_report_sections:
            _add_error(errors, "visual_snapshot_targets.json approval_workflow.required_report_sections must be non-empty array")
        else:
            for idx, section_name in enumerate(required_report_sections):
                if not isinstance(section_name, str) or not section_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_workflow.required_report_sections[{idx}] must be non-empty string")
                    continue
                if section_name not in allowed_sections:
                    _add_error(errors, f"visual_snapshot_targets.json approval_workflow.required_report_sections[{idx}] is not supported")

        if not isinstance(require_zero_blockers, bool):
            _add_error(errors, "visual_snapshot_targets.json approval_workflow.require_zero_blockers must be bool")

        if not isinstance(require_zero_warnings_for_strategies, list):
            _add_error(errors, "visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies must be array")
        else:
            required_strategies_row = release_gate_templates.get("required_strategies", []) if isinstance(release_gate_templates, dict) else []
            for idx, strategy_name in enumerate(require_zero_warnings_for_strategies):
                if not isinstance(strategy_name, str) or not strategy_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies[{idx}] must be non-empty string")
                    continue
                if isinstance(required_strategies_row, list) and strategy_name not in required_strategies_row:
                    _add_error(errors, f"visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies[{idx}] must be subset of release_gate_templates.required_strategies")

        if not isinstance(max_approval_failures, int) or max_approval_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_workflow.max_approval_failures must be int >= 0")

    if not isinstance(approval_audit_trail, dict) or not approval_audit_trail:
        _add_error(errors, "visual_snapshot_targets.json approval_audit_trail must be non-empty object")
    else:
        history_file = approval_audit_trail.get("history_file")
        max_entries = approval_audit_trail.get("max_entries")
        required_run_modes = approval_audit_trail.get("required_run_modes")
        required_backends = approval_audit_trail.get("required_backends")
        require_unique_pipeline_id = approval_audit_trail.get("require_unique_pipeline_id")
        max_missing_pipeline_id = approval_audit_trail.get("max_missing_pipeline_id")
        max_history_trace_failures = approval_audit_trail.get("max_history_trace_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.history_file must be non-empty user:// path")
        if not isinstance(max_entries, int) or max_entries < 10:
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.max_entries must be int >= 10")

        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.required_run_modes must be non-empty array")
            required_run_modes = []
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_audit_trail.required_run_modes[{idx}] must be non-empty string")

        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.required_backends must be non-empty array")
            required_backends = []
        else:
            backend_set = set()
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_audit_trail.required_backends[{idx}] must be non-empty string")
                    continue
                backend_set.add(backend_name)
            for must_have in ("linux_headless", "windows_headless"):
                if must_have not in backend_set:
                    _add_error(errors, f"visual_snapshot_targets.json approval_audit_trail.required_backends must include '{must_have}'")

        if not isinstance(require_unique_pipeline_id, bool):
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.require_unique_pipeline_id must be bool")
        if not isinstance(max_missing_pipeline_id, int) or max_missing_pipeline_id < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.max_missing_pipeline_id must be int >= 0")
        if not isinstance(max_history_trace_failures, int) or max_history_trace_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_audit_trail.max_history_trace_failures must be int >= 0")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if isinstance(required_run_modes, list) and isinstance(ci_mode_bindings_row, dict):
            for mode_name in required_run_modes:
                if isinstance(mode_name, str) and mode_name and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_audit_trail.required_run_modes")

        required_backend_matrix_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if isinstance(required_backends, list) and isinstance(required_backend_matrix_row, list):
            for backend_name in required_backends:
                if isinstance(backend_name, str) and backend_name and backend_name not in required_backend_matrix_row:
                    _add_error(errors, f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{backend_name}' for approval_audit_trail.required_backends")

    if not isinstance(approval_history_archive, dict) or not approval_history_archive:
        _add_error(errors, "visual_snapshot_targets.json approval_history_archive must be non-empty object")
    else:
        archive_file = approval_history_archive.get("archive_file")
        max_entries = approval_history_archive.get("max_entries")
        aggregation_window = approval_history_archive.get("aggregation_window")
        required_archive_run_modes = approval_history_archive.get("required_run_modes")
        required_archive_backends = approval_history_archive.get("required_backends")
        max_missing_archive_backends = approval_history_archive.get("max_missing_archive_backends")
        max_missing_archive_run_modes = approval_history_archive.get("max_missing_archive_run_modes")
        max_backend_warning_delta = approval_history_archive.get("max_backend_warning_delta")
        max_backend_blocker_delta = approval_history_archive.get("max_backend_blocker_delta")
        max_archive_trace_failures = approval_history_archive.get("max_archive_trace_failures")

        if not isinstance(archive_file, str) or not archive_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.archive_file must be non-empty user:// path")
        if not isinstance(max_entries, int) or max_entries < 20:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_entries must be int >= 20")
        if not isinstance(aggregation_window, int) or aggregation_window < 10:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.aggregation_window must be int >= 10")

        if not isinstance(required_archive_run_modes, list) or not required_archive_run_modes:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.required_run_modes must be non-empty array")
            required_archive_run_modes = []
        else:
            for idx, mode_name in enumerate(required_archive_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_history_archive.required_run_modes[{idx}] must be non-empty string")

        if not isinstance(required_archive_backends, list) or not required_archive_backends:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.required_backends must be non-empty array")
            required_archive_backends = []
        else:
            archive_backend_set = set()
            for idx, backend_name in enumerate(required_archive_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json approval_history_archive.required_backends[{idx}] must be non-empty string")
                    continue
                archive_backend_set.add(backend_name)
            for must_have in ("linux_headless", "windows_headless"):
                if must_have not in archive_backend_set:
                    _add_error(errors, f"visual_snapshot_targets.json approval_history_archive.required_backends must include '{must_have}'")

        if not isinstance(max_missing_archive_backends, int) or max_missing_archive_backends < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_missing_archive_backends must be int >= 0")
        if not isinstance(max_missing_archive_run_modes, int) or max_missing_archive_run_modes < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_missing_archive_run_modes must be int >= 0")
        if not isinstance(max_backend_warning_delta, int) or max_backend_warning_delta < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_backend_warning_delta must be int >= 0")
        if not isinstance(max_backend_blocker_delta, int) or max_backend_blocker_delta < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_backend_blocker_delta must be int >= 0")
        if not isinstance(max_archive_trace_failures, int) or max_archive_trace_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json approval_history_archive.max_archive_trace_failures must be int >= 0")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if isinstance(required_archive_run_modes, list) and isinstance(ci_mode_bindings_row, dict):
            for mode_name in required_archive_run_modes:
                if isinstance(mode_name, str) and mode_name and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_history_archive.required_run_modes")

        required_backend_matrix_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if isinstance(required_archive_backends, list) and isinstance(required_backend_matrix_row, list):
            for backend_name in required_archive_backends:
                if isinstance(backend_name, str) and backend_name and backend_name not in required_backend_matrix_row:
                    _add_error(errors, f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{backend_name}' for approval_history_archive.required_backends")

    if not isinstance(approval_threshold_templates, dict) or not approval_threshold_templates:
        _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates must be non-empty object")
    else:
        default_template = approval_threshold_templates.get("default_template")
        run_mode_templates = approval_threshold_templates.get("run_mode_templates")
        templates = approval_threshold_templates.get("templates")

        if not isinstance(default_template, str) or not default_template.strip():
            _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.default_template must be non-empty string")
        if not isinstance(run_mode_templates, dict) or not run_mode_templates:
            _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.run_mode_templates must be non-empty object")
            run_mode_templates = {}
        if not isinstance(templates, dict) or not templates:
            _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.templates must be non-empty object")
            templates = {}

        if isinstance(default_template, str) and default_template and isinstance(templates, dict) and default_template not in templates:
            _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.default_template must reference templates key")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        for mode_name, template_name in run_mode_templates.items():
            if not isinstance(mode_name, str) or not mode_name.strip():
                _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.run_mode_templates key must be non-empty string")
                continue
            if not isinstance(template_name, str) or not template_name.strip():
                _add_error(errors, f"visual_snapshot_targets.json approval_threshold_templates.run_mode_templates.{mode_name} must be non-empty string")
                continue
            if isinstance(templates, dict) and template_name not in templates:
                _add_error(errors, f"visual_snapshot_targets.json approval_threshold_templates.run_mode_templates.{mode_name} must reference templates key")
            if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_threshold_templates.run_mode_templates")

        allowed_template_sections = {"approval_workflow", "approval_audit_trail", "approval_history_archive"}
        for template_name, template_row in templates.items():
            if not isinstance(template_name, str) or not template_name.strip():
                _add_error(errors, "visual_snapshot_targets.json approval_threshold_templates.templates key must be non-empty string")
                continue
            if not isinstance(template_row, dict) or not template_row:
                _add_error(errors, f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name} must be non-empty object")
                continue
            for section_name, section_row in template_row.items():
                if section_name not in allowed_template_sections:
                    _add_error(errors, f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name}.{section_name} is not a supported override section")
                    continue
                if not isinstance(section_row, dict) or not section_row:
                    _add_error(errors, f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name}.{section_name} must be non-empty object")

    if not isinstance(release_candidate_tracking, dict) or not release_candidate_tracking:
        _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking must be non-empty object")
    else:
        history_file = release_candidate_tracking.get("history_file")
        window = release_candidate_tracking.get("window")
        required_tracking_run_modes = release_candidate_tracking.get("required_run_modes")
        required_tracking_strategies = release_candidate_tracking.get("required_strategies")
        min_runs = release_candidate_tracking.get("min_runs")
        max_avg_warnings = _to_float(release_candidate_tracking.get("max_avg_warnings"))
        max_total_blockers = release_candidate_tracking.get("max_total_blockers")
        max_tracking_failures = release_candidate_tracking.get("max_tracking_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.history_file must be non-empty user:// path")
        if not isinstance(window, int) or window < 5:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.window must be int >= 5")
        if not isinstance(required_tracking_run_modes, list) or not required_tracking_run_modes:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.required_run_modes must be non-empty array")
            required_tracking_run_modes = []
        else:
            ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
            for idx, mode_name in enumerate(required_tracking_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_candidate_tracking.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for release_candidate_tracking.required_run_modes")

        if not isinstance(required_tracking_strategies, list) or not required_tracking_strategies:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.required_strategies must be non-empty array")
        else:
            required_strategies_row = release_gate_templates.get("required_strategies", []) if isinstance(release_gate_templates, dict) else []
            for idx, strategy_name in enumerate(required_tracking_strategies):
                if not isinstance(strategy_name, str) or not strategy_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_candidate_tracking.required_strategies[{idx}] must be non-empty string")
                    continue
                if isinstance(required_strategies_row, list) and strategy_name not in required_strategies_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_candidate_tracking.required_strategies[{idx}] must be subset of release_gate_templates.required_strategies")

        if not isinstance(min_runs, int) or min_runs < 1:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.min_runs must be int >= 1")
        if max_avg_warnings is None or max_avg_warnings < 0.0:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.max_avg_warnings must be float >= 0.0")
        if not isinstance(max_total_blockers, int) or max_total_blockers < 0:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.max_total_blockers must be int >= 0")
        if not isinstance(max_tracking_failures, int) or max_tracking_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json release_candidate_tracking.max_tracking_failures must be int >= 0")

    if not isinstance(report_layers, dict) or not report_layers:
        _add_error(errors, "visual_snapshot_targets.json report_layers must be non-empty object")
    else:
        for layer_name, layer_row in report_layers.items():
            if not isinstance(layer_name, str) or not layer_name.strip():
                _add_error(errors, "visual_snapshot_targets.json report_layers key must be non-empty string")
                continue
            if not isinstance(layer_row, dict) or not layer_row:
                _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name} must be non-empty object")
                continue

            snapshot_ids = layer_row.get("snapshot_ids")
            max_layer_blockers = layer_row.get("max_layer_blockers")
            max_layer_warnings = layer_row.get("max_layer_warnings")
            min_pass_ratio = _to_float(layer_row.get("min_pass_ratio"))

            if not isinstance(snapshot_ids, list) or not snapshot_ids:
                _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids must be non-empty array")
            else:
                for idx, snapshot_id in enumerate(snapshot_ids):
                    if not isinstance(snapshot_id, str) or not snapshot_id.strip():
                        _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids[{idx}] must be non-empty string")
                    elif isinstance(snapshots, dict) and snapshot_id not in snapshots:
                        _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids[{idx}] must reference snapshots key")

            if not isinstance(max_layer_blockers, int) or max_layer_blockers < 0:
                _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.max_layer_blockers must be int >= 0")
            if not isinstance(max_layer_warnings, int) or max_layer_warnings < 0:
                _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.max_layer_warnings must be int >= 0")
            if min_pass_ratio is None or min_pass_ratio < 0.0 or min_pass_ratio > 1.0:
                _add_error(errors, f"visual_snapshot_targets.json report_layers.{layer_name}.min_pass_ratio must be within [0.0, 1.0]")

    if not isinstance(cross_version_baseline, dict) or not cross_version_baseline:
        _add_error(errors, "visual_snapshot_targets.json cross_version_baseline must be non-empty object")
    else:
        reference_channels = cross_version_baseline.get("reference_channels")
        max_drift = cross_version_baseline.get("max_drift")
        max_violations = cross_version_baseline.get("max_violations")
        snapshot_references = cross_version_baseline.get("snapshot_references")

        if not isinstance(reference_channels, list) or not reference_channels:
            _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.reference_channels must be non-empty array")
            reference_channels = []
        else:
            for idx, channel_name in enumerate(reference_channels):
                if not isinstance(channel_name, str) or not channel_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.reference_channels[{idx}] must be non-empty string")

        if not isinstance(max_drift, dict) or not max_drift:
            _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.max_drift must be non-empty object")
        else:
            opaque_drift = _to_float(max_drift.get("opaque_ratio"))
            unique_drift = _to_float(max_drift.get("unique_color_ratio"))
            luma_drift = _to_float(max_drift.get("avg_luma"))
            if opaque_drift is None or opaque_drift < 0.0 or opaque_drift > 1.0:
                _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.max_drift.opaque_ratio must be within [0.0, 1.0]")
            if unique_drift is None or unique_drift < 0.0 or unique_drift > 1.0:
                _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.max_drift.unique_color_ratio must be within [0.0, 1.0]")
            if luma_drift is None or luma_drift < 0.0 or luma_drift > 1.0:
                _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.max_drift.avg_luma must be within [0.0, 1.0]")

        if not isinstance(max_violations, int) or max_violations < 0:
            _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.max_violations must be int >= 0")

        if not isinstance(snapshot_references, dict) or not snapshot_references:
            _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.snapshot_references must be non-empty object")
        else:
            for snapshot_id, ref_row in snapshot_references.items():
                if not isinstance(snapshot_id, str) or not snapshot_id.strip():
                    _add_error(errors, "visual_snapshot_targets.json cross_version_baseline.snapshot_references key must be non-empty string")
                    continue
                if isinstance(snapshots, dict) and snapshot_id not in snapshots:
                    _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id} must reference snapshots key")
                if not isinstance(ref_row, dict) or not ref_row:
                    _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id} must be non-empty object")
                    continue

                opaque_refs = ref_row.get("opaque_ratio")
                unique_refs = ref_row.get("unique_colors")
                luma_refs = ref_row.get("avg_luma")
                for metric_key, metric_refs in {
                    "opaque_ratio": opaque_refs,
                    "unique_colors": unique_refs,
                    "avg_luma": luma_refs,
                }.items():
                    if not isinstance(metric_refs, dict) or not metric_refs:
                        _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} must be non-empty object")
                        continue
                    for channel_name in reference_channels:
                        if isinstance(channel_name, str) and channel_name and channel_name not in metric_refs:
                            _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} must include {channel_name}")
                    for channel_name, metric_value in metric_refs.items():
                        if not isinstance(channel_name, str) or not channel_name.strip():
                            _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} channel key must be non-empty string")
                            continue
                        if metric_key == "unique_colors":
                            value = _to_float(metric_value)
                            if value is None or value < 1.0:
                                _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.unique_colors.{channel_name} must be >= 1")
                        else:
                            value = _to_float(metric_value)
                            if value is None or value < 0.0 or value > 1.0:
                                _add_error(errors, f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key}.{channel_name} must be within [0.0, 1.0]")

    if not isinstance(thresholds, dict) or not thresholds:
        _add_error(errors, "visual_snapshot_targets.json thresholds must be non-empty object")
        return

    min_snapshots = thresholds.get("min_snapshots")
    max_failures = thresholds.get("max_failures")
    max_trend_regressions = thresholds.get("max_trend_regressions")
    max_opaque_ratio_drop = _to_float(thresholds.get("max_opaque_ratio_drop"))
    max_unique_color_drop_ratio = _to_float(thresholds.get("max_unique_color_drop_ratio"))
    max_luma_delta = _to_float(thresholds.get("max_luma_delta"))

    if not isinstance(min_snapshots, int) or min_snapshots < 1:
        _add_error(errors, "visual_snapshot_targets.json thresholds.min_snapshots must be int >= 1")
    if not isinstance(max_failures, int) or max_failures < 0:
        _add_error(errors, "visual_snapshot_targets.json thresholds.max_failures must be int >= 0")
    if not isinstance(max_trend_regressions, int) or max_trend_regressions < 0:
        _add_error(errors, "visual_snapshot_targets.json thresholds.max_trend_regressions must be int >= 0")
    if max_opaque_ratio_drop is None or max_opaque_ratio_drop < 0.0 or max_opaque_ratio_drop > 1.0:
        _add_error(errors, "visual_snapshot_targets.json thresholds.max_opaque_ratio_drop must be within [0.0, 1.0]")
    if max_unique_color_drop_ratio is None or max_unique_color_drop_ratio < 0.0 or max_unique_color_drop_ratio > 1.0:
        _add_error(errors, "visual_snapshot_targets.json thresholds.max_unique_color_drop_ratio must be within [0.0, 1.0]")
    if max_luma_delta is None or max_luma_delta < 0.0 or max_luma_delta > 1.0:
        _add_error(errors, "visual_snapshot_targets.json thresholds.max_luma_delta must be within [0.0, 1.0]")


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
    if "quality_baseline_targets.json" in parsed_by_name:
        _validate_quality_baseline_targets(parsed_by_name["quality_baseline_targets.json"], errors)
    if "release_gate_targets.json" in parsed_by_name:
        _validate_release_gate_targets(parsed_by_name["release_gate_targets.json"], errors)
    if "compatibility_rehearsal_targets.json" in parsed_by_name:
        _validate_compatibility_rehearsal_targets(parsed_by_name["compatibility_rehearsal_targets.json"], errors)
    if "resource_acceptance_targets.json" in parsed_by_name:
        _validate_resource_acceptance_targets(parsed_by_name["resource_acceptance_targets.json"], errors)
    if "visual_snapshot_targets.json" in parsed_by_name:
        _validate_visual_snapshot_targets(parsed_by_name["visual_snapshot_targets.json"], errors)

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
