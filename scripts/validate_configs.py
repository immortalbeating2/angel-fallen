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


def _validate_environment_visual_profile(profile: dict[str, Any], prefix: str, errors: list[str]) -> None:
    detail_tint = profile.get("detail_tint", "#FFFFFF")
    if not _is_hex_color(detail_tint):
        _add_error(errors, f"{prefix}.detail_tint must be hex color string")

    detail_alpha = _to_float(profile.get("detail_alpha", 0.65))
    if detail_alpha is None or detail_alpha < 0.20 or detail_alpha > 1.00:
        _add_error(errors, f"{prefix}.detail_alpha must be within [0.20, 1.00]")

    detail_pulse_speed = _to_float(profile.get("detail_pulse_speed", 0.0))
    if detail_pulse_speed is None or detail_pulse_speed < 0.0 or detail_pulse_speed > 6.0:
        _add_error(errors, f"{prefix}.detail_pulse_speed must be within [0.0, 6.0]")

    detail_pulse_amplitude = _to_float(profile.get("detail_pulse_amplitude", 0.0))
    if detail_pulse_amplitude is None or detail_pulse_amplitude < 0.0 or detail_pulse_amplitude > 0.25:
        _add_error(errors, f"{prefix}.detail_pulse_amplitude must be within [0.0, 0.25]")

    hazard_alpha_mult = _to_float(profile.get("hazard_alpha_mult", 1.0))
    if hazard_alpha_mult is None or hazard_alpha_mult < 0.40 or hazard_alpha_mult > 1.60:
        _add_error(errors, f"{prefix}.hazard_alpha_mult must be within [0.40, 1.60]")

    ambient_alpha_mult = _to_float(profile.get("ambient_alpha_mult", 1.0))
    if ambient_alpha_mult is None or ambient_alpha_mult < 0.40 or ambient_alpha_mult > 1.60:
        _add_error(errors, f"{prefix}.ambient_alpha_mult must be within [0.40, 1.60]")

    ambient_wave_speed = _to_float(profile.get("ambient_wave_speed", 0.0))
    if ambient_wave_speed is None or ambient_wave_speed < 0.0 or ambient_wave_speed > 6.0:
        _add_error(errors, f"{prefix}.ambient_wave_speed must be within [0.0, 6.0]")

    ambient_wave_amplitude = _to_float(profile.get("ambient_wave_amplitude", 0.0))
    if ambient_wave_amplitude is None or ambient_wave_amplitude < 0.0 or ambient_wave_amplitude > 0.25:
        _add_error(errors, f"{prefix}.ambient_wave_amplitude must be within [0.0, 0.25]")

    ambient_scroll_speed_x = _to_float(profile.get("ambient_scroll_speed_x", 0.0))
    if ambient_scroll_speed_x is None or ambient_scroll_speed_x < -8.0 or ambient_scroll_speed_x > 8.0:
        _add_error(errors, f"{prefix}.ambient_scroll_speed_x must be within [-8.0, 8.0]")

    ambient_scroll_speed_y = _to_float(profile.get("ambient_scroll_speed_y", 0.0))
    if ambient_scroll_speed_y is None or ambient_scroll_speed_y < -8.0 or ambient_scroll_speed_y > 8.0:
        _add_error(errors, f"{prefix}.ambient_scroll_speed_y must be within [-8.0, 8.0]")


def _validate_environment_room_profiles(chapter_key: str, row: dict[str, Any], errors: list[str]) -> None:
    room_profiles = row.get("room_profiles", {})
    if not isinstance(room_profiles, dict):
        _add_error(errors, f"environment_config.json {chapter_key}.room_profiles must be object")
        return

    required_room_types = ("combat", "elite", "boss", "safe_camp")
    for room_type in required_room_types:
        room_profile = room_profiles.get(room_type)
        if not isinstance(room_profile, dict):
            _add_error(errors, f"environment_config.json {chapter_key}.room_profiles.{room_type} must be object")
            continue

        profile_hazards = room_profile.get("hazards")
        if not isinstance(profile_hazards, list):
            _add_error(errors, f"environment_config.json {chapter_key}.room_profiles.{room_type}.hazards must be array")
        elif room_type != "safe_camp" and not profile_hazards:
            _add_error(errors, f"environment_config.json {chapter_key}.room_profiles.{room_type}.hazards must not be empty")

        hazard_pressure = _to_float(room_profile.get("hazard_pressure", 1.0))
        if hazard_pressure is None or hazard_pressure < 0.0 or hazard_pressure > 2.5:
            _add_error(errors, f"environment_config.json {chapter_key}.room_profiles.{room_type}.hazard_pressure must be within [0.0, 2.5]")

        overrides = room_profile.get("visual_profile_overrides", {})
        if not isinstance(overrides, dict):
            _add_error(errors, f"environment_config.json {chapter_key}.room_profiles.{room_type}.visual_profile_overrides must be object")
        else:
            _validate_environment_visual_profile(
                overrides,
                f"environment_config.json {chapter_key}.room_profiles.{room_type}.visual_profile_overrides",
                errors,
            )


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
    chapter_profiles = data.get("chapter_room_profiles")
    chapter_progression_profiles = data.get("chapter_progression_profiles")
    hidden_layers = data.get("hidden_layers")
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

    _validate_map_generation_room_profiles(chapter_order, chapter_profiles, errors)
    _validate_map_generation_progression_profiles(chapter_order, chapter_progression_profiles, errors)
    _validate_map_generation_hidden_layers(hidden_layers, errors)

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

    chapter_profiles = data.get("chapter_reward_profiles")
    if not isinstance(chapter_profiles, dict) or not chapter_profiles:
        _add_error(errors, "drop_tables.json chapter_reward_profiles must be non-empty object")
    else:
        for chapter_id in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
            row = chapter_profiles.get(chapter_id)
            prefix = f"drop_tables.json chapter_reward_profiles.{chapter_id}"
            if not isinstance(row, dict):
                _add_error(errors, f"{prefix} must be object")
                continue
            for field_name in ("xp_mult", "gold_mult", "ore_mult", "treasure_mult"):
                value = _to_float(row.get(field_name))
                if value is None or value < 0.6 or value > 2.5:
                    _add_error(errors, f"{prefix}.{field_name} must be within [0.6, 2.5]")

    long_run_curve = data.get("long_run_room_curve")
    if not isinstance(long_run_curve, dict) or not long_run_curve:
        _add_error(errors, "drop_tables.json long_run_room_curve must be non-empty object")
    else:
        room_bonus_start = long_run_curve.get("room_bonus_start")
        if not isinstance(room_bonus_start, int) or room_bonus_start < 1 or room_bonus_start > 20:
            _add_error(errors, "drop_tables.json long_run_room_curve.room_bonus_start must be int within [1, 20]")

        room_bonus_per_room = _to_float(long_run_curve.get("room_bonus_per_room"))
        if room_bonus_per_room is None or room_bonus_per_room < 0.0 or room_bonus_per_room > 0.25:
            _add_error(errors, "drop_tables.json long_run_room_curve.room_bonus_per_room must be within [0.0, 0.25]")

        room_bonus_cap = _to_float(long_run_curve.get("room_bonus_cap"))
        if room_bonus_cap is None or room_bonus_cap < 0.0 or room_bonus_cap > 1.0:
            _add_error(errors, "drop_tables.json long_run_room_curve.room_bonus_cap must be within [0.0, 1.0]")

        for field_name in ("xp_weight", "gold_weight", "ore_weight", "treasure_weight"):
            value = _to_float(long_run_curve.get(field_name))
            if value is None or value < 0.0 or value > 2.0:
                _add_error(errors, f"drop_tables.json long_run_room_curve.{field_name} must be within [0.0, 2.0]")


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
    forge_recipes = data.get("forge_recipes")

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

    if not isinstance(forge_recipes, dict) or not forge_recipes:
        _add_error(errors, "shop_items.json forge_recipes must be non-empty object")
    else:
        for recipe_key in ("damage", "speed"):
            recipe_row = forge_recipes.get(recipe_key)
            if not isinstance(recipe_row, dict):
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key} must be object")
                continue

            ore_cost = recipe_row.get("ore_cost")
            if not isinstance(ore_cost, int) or ore_cost < 1 or ore_cost > 20:
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.ore_cost must be int within [1, 20]")

            success_text = recipe_row.get("success_text")
            if not isinstance(success_text, str) or not success_text.strip():
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.success_text must be non-empty string")

            anchor = recipe_row.get("anchor")
            if not isinstance(anchor, str) or not anchor.strip():
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.anchor must be non-empty string")

            anchor_amount = _to_float(recipe_row.get("anchor_amount"))
            if anchor_amount is None or anchor_amount < 0.0 or anchor_amount > 3.0:
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.anchor_amount must be within [0.0, 3.0]")

            effect_present = False

            damage_mult = _to_float(recipe_row.get("damage_mult"))
            if damage_mult is not None:
                effect_present = True
                if damage_mult < 0.9 or damage_mult > 2.0:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.damage_mult must be within [0.9, 2.0]")

            interval_mult = _to_float(recipe_row.get("interval_mult"))
            if interval_mult is not None:
                effect_present = True
                if interval_mult < 0.6 or interval_mult > 1.1:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.interval_mult must be within [0.6, 1.1]")

            crit_chance_add = _to_float(recipe_row.get("crit_chance_add"))
            if crit_chance_add is not None:
                effect_present = True
                if crit_chance_add < 0.0 or crit_chance_add > 0.25:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.crit_chance_add must be within [0.0, 0.25]")

            crit_multiplier_add = _to_float(recipe_row.get("crit_multiplier_add"))
            if crit_multiplier_add is not None:
                effect_present = True
                if crit_multiplier_add < 0.0 or crit_multiplier_add > 0.8:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.crit_multiplier_add must be within [0.0, 0.8]")

            max_hp_add = recipe_row.get("max_hp_add")
            if max_hp_add is not None:
                effect_present = True
                if not isinstance(max_hp_add, int) or max_hp_add < 0 or max_hp_add > 120:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.max_hp_add must be int within [0, 120]")

            heal_flat = _to_float(recipe_row.get("heal_flat"))
            if heal_flat is not None:
                effect_present = True
                if heal_flat < 0.0 or heal_flat > 120.0:
                    _add_error(errors, f"shop_items.json forge_recipes.{recipe_key}.heal_flat must be within [0.0, 120.0]")

            if not effect_present:
                _add_error(errors, f"shop_items.json forge_recipes.{recipe_key} must define at least one forge effect field")

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
        else:
            _validate_environment_visual_profile(visual_profile, f"environment_config.json {chapter_key}.visual_profile", errors)

        _validate_environment_room_profiles(chapter_key, row, errors)


def _validate_map_generation_room_profiles(chapter_order: list[Any], chapter_profiles: Any, errors: list[str]) -> None:
    required_room_types = ("combat", "elite", "boss", "event", "treasure", "shop", "safe_camp")
    if not isinstance(chapter_profiles, dict) or not chapter_profiles:
        _add_error(errors, "map_generation.json chapter_room_profiles must be non-empty object")
        return

    for chapter_id in chapter_order:
        chapter_key = str(chapter_id)
        row = chapter_profiles.get(chapter_key)
        if not isinstance(row, dict):
            _add_error(errors, f"map_generation.json chapter_room_profiles missing '{chapter_key}'")
            continue

        for room_type in required_room_types:
            profile = row.get(room_type)
            prefix = f"map_generation.json chapter_room_profiles.{chapter_key}.{room_type}"
            if not isinstance(profile, dict):
                _add_error(errors, f"{prefix} must be object")
                continue

            for field_name in ("title", "objective", "route_tag", "status_hint"):
                value = profile.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"{prefix}.{field_name} must be non-empty string")

            route_tag = profile.get("route_tag")
            if isinstance(route_tag, str) and len(route_tag) > 18:
                _add_error(errors, f"{prefix}.route_tag should be <= 18 characters")

            required_kills_mult = _to_float(profile.get("required_kills_mult", 1.0))
            if required_kills_mult is None or required_kills_mult < 0.5 or required_kills_mult > 2.5:
                _add_error(errors, f"{prefix}.required_kills_mult must be within [0.5, 2.5]")

            required_kills_add = profile.get("required_kills_add")
            if not isinstance(required_kills_add, int) or required_kills_add < -4 or required_kills_add > 8:
                _add_error(errors, f"{prefix}.required_kills_add must be int within [-4, 8]")

            reward_mult = _to_float(profile.get("reward_mult", 1.0))
            if reward_mult is None or reward_mult < 0.5 or reward_mult > 2.5:
                _add_error(errors, f"{prefix}.reward_mult must be within [0.5, 2.5]")


def _validate_map_generation_progression_profiles(chapter_order: list[Any], chapter_profiles: Any, errors: list[str]) -> None:
    required_room_types = ("combat", "elite", "boss", "event", "treasure", "shop", "safe_camp")
    if not isinstance(chapter_profiles, dict) or not chapter_profiles:
        _add_error(errors, "map_generation.json chapter_progression_profiles must be non-empty object")
        return

    for chapter_id in chapter_order:
        chapter_key = str(chapter_id)
        row = chapter_profiles.get(chapter_key)
        prefix = f"map_generation.json chapter_progression_profiles.{chapter_key}"
        if not isinstance(row, dict):
            _add_error(errors, f"map_generation.json chapter_progression_profiles missing '{chapter_key}'")
            continue

        for field_name in ("clear_banner", "transition_intro", "transition_resolved", "event_resolved", "camp_recovery_note", "checkpoint_label"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"{prefix}.{field_name} must be non-empty string")

        history_recap_prefix = row.get("history_recap_prefix")
        if not isinstance(history_recap_prefix, str) or not history_recap_prefix.strip():
            _add_error(errors, f"{prefix}.history_recap_prefix must be non-empty string")
        elif len(history_recap_prefix) > 64:
            _add_error(errors, f"{prefix}.history_recap_prefix should be <= 64 characters")

        history_recap_limit = row.get("history_recap_limit")
        if not isinstance(history_recap_limit, int) or history_recap_limit < 1 or history_recap_limit > 8:
            _add_error(errors, f"{prefix}.history_recap_limit must be int within [1, 8]")

        checkpoint_label = row.get("checkpoint_label")
        if isinstance(checkpoint_label, str) and len(checkpoint_label) > 24:
            _add_error(errors, f"{prefix}.checkpoint_label should be <= 24 characters")

        mainline_nodes = row.get("mainline_nodes")
        if not isinstance(mainline_nodes, dict) or not mainline_nodes:
            _add_error(errors, f"{prefix}.mainline_nodes must be non-empty object")
        else:
            for room_type in required_room_types:
                node_value = mainline_nodes.get(room_type)
                if not isinstance(node_value, str) or not node_value.strip():
                    _add_error(errors, f"{prefix}.mainline_nodes.{room_type} must be non-empty string")
                    continue
                if len(node_value) > 72:
                    _add_error(errors, f"{prefix}.mainline_nodes.{room_type} should be <= 72 characters")

        pace_tags = row.get("history_pace_tags")
        if not isinstance(pace_tags, dict) or not pace_tags:
            _add_error(errors, f"{prefix}.history_pace_tags must be non-empty object")
            continue

        for room_type in required_room_types:
            tag_value = pace_tags.get(room_type)
            if not isinstance(tag_value, str) or not tag_value.strip():
                _add_error(errors, f"{prefix}.history_pace_tags.{room_type} must be non-empty string")
                continue
            if len(tag_value) > 32:
                _add_error(errors, f"{prefix}.history_pace_tags.{room_type} should be <= 32 characters")


def _validate_map_generation_hidden_layers(hidden_layers: Any, errors: list[str]) -> None:
    if not isinstance(hidden_layers, dict) or not hidden_layers:
        _add_error(errors, "map_generation.json hidden_layers must be non-empty object")
        return

    for layer_id in ("FS1", "FS2"):
        row = hidden_layers.get(layer_id)
        prefix = f"map_generation.json hidden_layers.{layer_id}"
        if not isinstance(row, dict):
            _add_error(errors, f"{prefix} must be object")
            continue

        for field_name in ("title", "theme", "unlock_rule", "entrance_hint"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"{prefix}.{field_name} must be non-empty string")

        map_profile = row.get("map_profile")
        if not isinstance(map_profile, dict):
            _add_error(errors, f"{prefix}.map_profile must be object")
        else:
            mode = map_profile.get("mode")
            room_count = map_profile.get("room_count")
            room_count_label = map_profile.get("room_count_label")
            entry_room_type = map_profile.get("entry_room_type")
            encounter_room_type = map_profile.get("encounter_room_type")
            boss_room_type = map_profile.get("boss_room_type")
            settlement_room_type = map_profile.get("settlement_room_type")
            room_roles = map_profile.get("room_roles", [])

            if not isinstance(mode, str) or mode not in {"survival", "trial_chain"}:
                _add_error(errors, f"{prefix}.map_profile.mode must be 'survival' or 'trial_chain'")
            if not isinstance(room_count, int) or room_count < -1 or room_count == 0 or room_count > 12:
                _add_error(errors, f"{prefix}.map_profile.room_count must be int within [-1, 12] excluding 0")
            if not isinstance(room_count_label, str) or not room_count_label.strip():
                _add_error(errors, f"{prefix}.map_profile.room_count_label must be non-empty string")
            if not isinstance(entry_room_type, str) or not entry_room_type.strip():
                _add_error(errors, f"{prefix}.map_profile.entry_room_type must be non-empty string")
            if not isinstance(encounter_room_type, str) or not encounter_room_type.strip():
                _add_error(errors, f"{prefix}.map_profile.encounter_room_type must be non-empty string")
            if not isinstance(boss_room_type, str) or not boss_room_type.strip():
                _add_error(errors, f"{prefix}.map_profile.boss_room_type must be non-empty string")
            if not isinstance(settlement_room_type, str) or not settlement_room_type.strip():
                _add_error(errors, f"{prefix}.map_profile.settlement_room_type must be non-empty string")

            if mode == "survival" and room_count != -1:
                _add_error(errors, f"{prefix}.map_profile.room_count must be -1 for survival layers")
            if mode == "trial_chain" and (not isinstance(room_count, int) or room_count < 1):
                _add_error(errors, f"{prefix}.map_profile.room_count must be >= 1 for trial_chain layers")

            if mode == "trial_chain":
                expected_room_count = room_count if isinstance(room_count, int) else -1
                if not isinstance(room_roles, list) or len(room_roles) != expected_room_count:
                    _add_error(errors, f"{prefix}.map_profile.room_roles must match room_count for trial_chain layers")
                else:
                    for idx, role in enumerate(room_roles):
                        if not isinstance(role, str) or not role.strip():
                            _add_error(errors, f"{prefix}.map_profile.room_roles[{idx}] must be non-empty string")

        combat_profile = row.get("combat_profile")
        if not isinstance(combat_profile, dict):
            _add_error(errors, f"{prefix}.combat_profile must be object")
        else:
            enemy_multiplier_base = _to_float(combat_profile.get("enemy_multiplier_base"))
            enemy_multiplier_step = _to_float(combat_profile.get("enemy_multiplier_step"))
            enemy_step_minutes = combat_profile.get("enemy_step_minutes")
            boss_cycle_minutes = combat_profile.get("boss_cycle_minutes")
            enemy_pool_tags = combat_profile.get("enemy_pool_tags")
            boss_pool_tags = combat_profile.get("boss_pool_tags")

            if enemy_multiplier_base is None or enemy_multiplier_base < 10.0 or enemy_multiplier_base > 50.0:
                _add_error(errors, f"{prefix}.combat_profile.enemy_multiplier_base must be within [10.0, 50.0]")
            if enemy_multiplier_step is None or enemy_multiplier_step < 0.0 or enemy_multiplier_step > 10.0:
                _add_error(errors, f"{prefix}.combat_profile.enemy_multiplier_step must be within [0.0, 10.0]")
            if not isinstance(enemy_step_minutes, int) or enemy_step_minutes < 0 or enemy_step_minutes > 20:
                _add_error(errors, f"{prefix}.combat_profile.enemy_step_minutes must be int within [0, 20]")
            if not isinstance(boss_cycle_minutes, int) or boss_cycle_minutes < 0 or boss_cycle_minutes > 20:
                _add_error(errors, f"{prefix}.combat_profile.boss_cycle_minutes must be int within [0, 20]")
            if not isinstance(enemy_pool_tags, list) or not enemy_pool_tags:
                _add_error(errors, f"{prefix}.combat_profile.enemy_pool_tags must be non-empty array")
            else:
                for idx, tag in enumerate(enemy_pool_tags):
                    if not isinstance(tag, str) or not tag.strip():
                        _add_error(errors, f"{prefix}.combat_profile.enemy_pool_tags[{idx}] must be non-empty string")
            if not isinstance(boss_pool_tags, list) or not boss_pool_tags:
                _add_error(errors, f"{prefix}.combat_profile.boss_pool_tags must be non-empty array")
            else:
                for idx, tag in enumerate(boss_pool_tags):
                    if not isinstance(tag, str) or not tag.strip():
                        _add_error(errors, f"{prefix}.combat_profile.boss_pool_tags[{idx}] must be non-empty string")

            mode = str(row.get("map_profile", {}).get("mode", "")) if isinstance(row.get("map_profile"), dict) else ""
            if mode == "survival":
                if enemy_multiplier_step is not None and enemy_multiplier_step <= 0.0:
                    _add_error(errors, f"{prefix}.combat_profile.enemy_multiplier_step must be > 0 for survival layers")
                if isinstance(enemy_step_minutes, int) and enemy_step_minutes <= 0:
                    _add_error(errors, f"{prefix}.combat_profile.enemy_step_minutes must be > 0 for survival layers")
                if isinstance(boss_cycle_minutes, int) and boss_cycle_minutes <= 0:
                    _add_error(errors, f"{prefix}.combat_profile.boss_cycle_minutes must be > 0 for survival layers")

        reward_profile = row.get("reward_profile")
        if not isinstance(reward_profile, dict):
            _add_error(errors, f"{prefix}.reward_profile must be object")
        else:
            for field_name in ("track", "summary", "repeat_motivation"):
                value = reward_profile.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"{prefix}.reward_profile.{field_name} must be non-empty string")

        settlement_profile = row.get("settlement_profile")
        if not isinstance(settlement_profile, dict):
            _add_error(errors, f"{prefix}.settlement_profile must be object")
        else:
            for field_name in ("mode", "summary"):
                value = settlement_profile.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"{prefix}.settlement_profile.{field_name} must be non-empty string")


def _validate_boss_phases(data: dict[str, Any], errors: list[str]) -> None:
    bosses = data.get("bosses")
    if not isinstance(bosses, dict) or not bosses:
        _add_error(errors, "boss_phases.json bosses must be non-empty object")
        return

    required_bosses: dict[str, int] = {
        "enemy_rock_colossus": 3,
        "enemy_flame_lord": 3,
        "enemy_frost_king": 3,
        "enemy_void_lord": 4,
    }
    for boss_id, min_thresholds in required_bosses.items():
        thresholds_var = bosses.get(boss_id)
        if not isinstance(thresholds_var, list):
            _add_error(errors, f"boss_phases.json missing required boss thresholds '{boss_id}'")
            continue
        if len(thresholds_var) < min_thresholds:
            _add_error(errors, f"boss_phases.json {boss_id} must contain at least {min_thresholds} thresholds")

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

    content_path = root / "data" / "balance" / "narrative_content.json"
    if content_path.exists():
        try:
            narrative_content = json.loads(content_path.read_text(encoding="utf-8"))
            fragment_rows = narrative_content.get("memory_fragments") if isinstance(narrative_content, dict) else None
            if isinstance(total, int) and isinstance(fragment_rows, dict) and total != len(fragment_rows):
                _add_error(
                    errors,
                    "narrative_index.json memory_fragments.total must match narrative_content.json memory_fragments count",
                )
        except Exception as exc:
            warnings.append(f"narrative_index.json could not cross-check fragment total -> {exc}")


def _validate_narrative_content(data: dict[str, Any], errors: list[str]) -> None:
    transitions = data.get("chapter_transitions")
    events = data.get("chapter_events")
    endings = data.get("endings")
    route_styles = data.get("route_styles")
    route_arc_profiles = data.get("route_arc_profiles")
    camp_reflections = data.get("camp_reflections")
    ending_payoff_profiles = data.get("ending_payoff_profiles")
    epilogue_chains = data.get("epilogue_chains")
    epilogue_branch_profiles = data.get("epilogue_branch_profiles")
    fragment_recap_profiles = data.get("fragment_recap_profiles")
    hidden_layer_hooks = data.get("hidden_layer_hooks")
    hidden_layer_story_profiles = data.get("hidden_layer_story_profiles")
    fragment_trigger_profiles = data.get("fragment_trigger_profiles")
    memory_fragments = data.get("memory_fragments")

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

    if not isinstance(route_arc_profiles, dict) or not route_arc_profiles:
        _add_error(errors, "narrative_content.json route_arc_profiles must be non-empty object")
    else:
        _validate_route_arc_profiles(route_arc_profiles, errors)

    if not isinstance(camp_reflections, dict) or not camp_reflections:
        _add_error(errors, "narrative_content.json camp_reflections must be non-empty object")
    else:
        _validate_camp_reflections(camp_reflections, errors)

    _validate_ending_payoff_profiles(ending_payoff_profiles, errors)
    _validate_epilogue_chains(epilogue_chains, errors)
    _validate_stage5_batch3_profiles(epilogue_branch_profiles, fragment_recap_profiles, hidden_layer_hooks, errors)
    _validate_hidden_layer_story_profiles(hidden_layer_story_profiles, memory_fragments, errors)
    _validate_fragment_trigger_profiles(fragment_trigger_profiles, errors)

    if not isinstance(endings, dict) or not endings:
        _add_error(errors, "narrative_content.json endings must be non-empty object")


def _validate_route_arc_profiles(route_arc_profiles: dict[str, Any], errors: list[str]) -> None:
    for arc_id in ("balance", "redeem", "fall"):
        row = route_arc_profiles.get(arc_id)
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_content.json route_arc_profiles.{arc_id} must be object")
            continue
        for field_name in ("title", "summary", "camp_focus", "fragment_hint"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"narrative_content.json route_arc_profiles.{arc_id}.{field_name} must be non-empty string")


def _validate_camp_reflections(camp_reflections: dict[str, Any], errors: list[str]) -> None:
    for chapter_key in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
        chapter_row = camp_reflections.get(chapter_key)
        if not isinstance(chapter_row, dict):
            _add_error(errors, f"narrative_content.json camp_reflections.{chapter_key} must be object")
            continue
        for arc_id in ("balance", "redeem", "fall"):
            row = chapter_row.get(arc_id)
            if not isinstance(row, dict):
                _add_error(errors, f"narrative_content.json camp_reflections.{chapter_key}.{arc_id} must be object")
                continue
            for field_name in ("title", "body", "fragment_hint"):
                value = row.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"narrative_content.json camp_reflections.{chapter_key}.{arc_id}.{field_name} must be non-empty string")


def _validate_ending_payoff_profiles(ending_payoff_profiles: Any, errors: list[str]) -> None:
    if not isinstance(ending_payoff_profiles, dict) or not ending_payoff_profiles:
        _add_error(errors, "narrative_content.json ending_payoff_profiles must be non-empty object")
        return
    for ending_id in ("nar_ending_redeem", "nar_ending_fall", "nar_ending_balance"):
        row = ending_payoff_profiles.get(ending_id)
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_content.json ending_payoff_profiles.{ending_id} must be object")
            continue
        for field_name in ("title", "summary", "legacy", "fragment_hook"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"narrative_content.json ending_payoff_profiles.{ending_id}.{field_name} must be non-empty string")


def _validate_epilogue_chains(epilogue_chains: Any, errors: list[str]) -> None:
    if not isinstance(epilogue_chains, dict) or not epilogue_chains:
        _add_error(errors, "narrative_content.json epilogue_chains must be non-empty object")
        return
    for ending_id in ("nar_ending_redeem", "nar_ending_fall", "nar_ending_balance"):
        chain = epilogue_chains.get(ending_id)
        if not isinstance(chain, list) or len(chain) < 3:
            _add_error(errors, f"narrative_content.json epilogue_chains.{ending_id} must be array with at least 3 steps")
            continue
        for i, text in enumerate(chain):
            if not isinstance(text, str) or not text.strip():
                _add_error(errors, f"narrative_content.json epilogue_chains.{ending_id}[{i}] must be non-empty string")


def _validate_stage5_batch3_profiles(
    epilogue_branch_profiles: Any,
    fragment_recap_profiles: Any,
    hidden_layer_hooks: Any,
    errors: list[str],
) -> None:
    _validate_epilogue_branch_profiles(epilogue_branch_profiles, errors)
    _validate_fragment_recap_profiles(fragment_recap_profiles, errors)
    _validate_hidden_layer_hooks(hidden_layer_hooks, errors)


def _validate_epilogue_branch_profiles(epilogue_branch_profiles: Any, errors: list[str]) -> None:
    if not isinstance(epilogue_branch_profiles, dict) or not epilogue_branch_profiles:
        _add_error(errors, "narrative_content.json epilogue_branch_profiles must be non-empty object")
        return
    for ending_id in ("nar_ending_redeem", "nar_ending_fall", "nar_ending_balance"):
        row = epilogue_branch_profiles.get(ending_id)
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_content.json epilogue_branch_profiles.{ending_id} must be object")
            continue
        for branch_key in ("first_unlock", "repeat_unlock"):
            branch_row = row.get(branch_key)
            if not isinstance(branch_row, dict):
                _add_error(errors, f"narrative_content.json epilogue_branch_profiles.{ending_id}.{branch_key} must be object")
                continue
            for field_name in ("title", "body"):
                value = branch_row.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"narrative_content.json epilogue_branch_profiles.{ending_id}.{branch_key}.{field_name} must be non-empty string")
        archive_hook = row.get("archive_hook")
        if not isinstance(archive_hook, str) or not archive_hook.strip():
            _add_error(errors, f"narrative_content.json epilogue_branch_profiles.{ending_id}.archive_hook must be non-empty string")


def _validate_fragment_recap_profiles(fragment_recap_profiles: Any, errors: list[str]) -> None:
    if not isinstance(fragment_recap_profiles, dict) or not fragment_recap_profiles:
        _add_error(errors, "narrative_content.json fragment_recap_profiles must be non-empty object")
        return
    for arc_id in ("balance", "redeem", "fall"):
        row = fragment_recap_profiles.get(arc_id)
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_content.json fragment_recap_profiles.{arc_id} must be object")
            continue
        for field_name in ("title", "summary", "pace_hint"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"narrative_content.json fragment_recap_profiles.{arc_id}.{field_name} must be non-empty string")


def _validate_hidden_layer_hooks(hidden_layer_hooks: Any, errors: list[str]) -> None:
    if not isinstance(hidden_layer_hooks, dict) or not hidden_layer_hooks:
        _add_error(errors, "narrative_content.json hidden_layer_hooks must be non-empty object")
        return
    for arc_id in ("balance", "redeem", "fall"):
        row = hidden_layer_hooks.get(arc_id)
        if not isinstance(row, dict):
            _add_error(errors, f"narrative_content.json hidden_layer_hooks.{arc_id} must be object")
            continue
        target_layer = row.get("target_layer")
        if not isinstance(target_layer, str) or target_layer not in {"FS1", "FS2"}:
            _add_error(errors, f"narrative_content.json hidden_layer_hooks.{arc_id}.target_layer must be 'FS1' or 'FS2'")
        for field_name in ("title", "teaser", "unlock_hint"):
            value = row.get(field_name)
            if not isinstance(value, str) or not value.strip():
                _add_error(errors, f"narrative_content.json hidden_layer_hooks.{arc_id}.{field_name} must be non-empty string")


def _validate_hidden_layer_story_profiles(hidden_layer_story_profiles: Any, memory_fragments: Any, errors: list[str]) -> None:
    if not isinstance(hidden_layer_story_profiles, dict) or not hidden_layer_story_profiles:
        _add_error(errors, "narrative_content.json hidden_layer_story_profiles must be non-empty object")
        return

    fragment_rows: dict[str, Any] = memory_fragments if isinstance(memory_fragments, dict) else {}
    allowed_endings = {"nar_ending_balance", "nar_ending_redeem", "nar_ending_fall"}
    for layer_id in ("FS1", "FS2"):
        layer_row = hidden_layer_story_profiles.get(layer_id)
        if not isinstance(layer_row, dict):
            _add_error(errors, f"narrative_content.json hidden_layer_story_profiles.{layer_id} must be object")
            continue
        for arc_id in ("balance", "redeem", "fall"):
            row = layer_row.get(arc_id)
            if not isinstance(row, dict):
                _add_error(errors, f"narrative_content.json hidden_layer_story_profiles.{layer_id}.{arc_id} must be object")
                continue
            for field_name in ("title", "body", "archive_echo", "ending_link", "fragment_id"):
                value = row.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    _add_error(errors, f"narrative_content.json hidden_layer_story_profiles.{layer_id}.{arc_id}.{field_name} must be non-empty string")
            ending_link = row.get("ending_link")
            if isinstance(ending_link, str) and ending_link not in allowed_endings:
                _add_error(errors, f"narrative_content.json hidden_layer_story_profiles.{layer_id}.{arc_id}.ending_link must target a main ending id")
            fragment_id = row.get("fragment_id")
            if isinstance(fragment_id, str) and fragment_id not in fragment_rows:
                _add_error(errors, f"narrative_content.json hidden_layer_story_profiles.{layer_id}.{arc_id}.fragment_id must exist in memory_fragments")


def _validate_fragment_trigger_profiles(fragment_trigger_profiles: Any, errors: list[str]) -> None:
    if not isinstance(fragment_trigger_profiles, dict) or not fragment_trigger_profiles:
        _add_error(errors, "narrative_content.json fragment_trigger_profiles must be non-empty object")
        return
    for chapter_key in ("chapter_1", "chapter_2", "chapter_3", "chapter_4"):
        chapter_row = fragment_trigger_profiles.get(chapter_key)
        if not isinstance(chapter_row, dict):
            _add_error(errors, f"narrative_content.json fragment_trigger_profiles.{chapter_key} must be object")
            continue
        for trigger_type in ("camp", "event", "transition"):
            trigger_row = chapter_row.get(trigger_type)
            if not isinstance(trigger_row, dict):
                _add_error(errors, f"narrative_content.json fragment_trigger_profiles.{chapter_key}.{trigger_type} must be object")
                continue
            for arc_id in ("balance", "redeem", "fall"):
                fragment_id = trigger_row.get(arc_id)
                if not isinstance(fragment_id, str) or not fragment_id.strip():
                    _add_error(errors, f"narrative_content.json fragment_trigger_profiles.{chapter_key}.{trigger_type}.{arc_id} must be non-empty string")


def _validate_achievements(data: dict[str, Any], errors: list[str]) -> None:
    rows = data.get("achievements")
    if not isinstance(rows, list) or not rows:
        _add_error(errors, "achievements.json achievements must be non-empty array")
        return

    seen: set[str] = set()
    prefixes = ("clear_floor_", "alignment_ge_", "alignment_le_", "kills_ge_", "reach_level_")
    exact_conditions = {
        "victory_once",
        "hidden_layer_clear_fs1",
        "hidden_layer_mastery_fs1",
        "hidden_layer_clear_fs2",
        "hidden_layer_mastery_fs2",
        "difficulty_clear_hard",
        "difficulty_clear_nightmare",
        "difficulty_hidden_clear_nightmare",
    }
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
        if condition not in exact_conditions and not condition.startswith(prefixes):
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
    stability_scoring = data.get("stability_scoring")
    stability_tiers = data.get("stability_tiers")
    convergence_dashboard = data.get("convergence_dashboard")
    ci_signal_contract = data.get("ci_signal_contract")
    convergence_trend_reinforcement = data.get("convergence_trend_reinforcement")
    exception_lifecycle_linkage = data.get("exception_lifecycle_linkage")
    visual_performance_cogate = data.get("visual_performance_cogate")
    cogate_threshold_templates = data.get("cogate_threshold_templates")
    cross_platform_alignment = data.get("cross_platform_alignment")
    pressure_scenario_standardization = data.get("pressure_scenario_standardization")
    alignment_dashboard_refinement = data.get("alignment_dashboard_refinement")
    pressure_alignment_convergence_gate = data.get("pressure_alignment_convergence_gate")
    regression_cycle_window_governance = data.get("regression_cycle_window_governance")
    multi_cycle_adaptive_gate = data.get("multi_cycle_adaptive_gate")
    release_feedback_governance = data.get("release_feedback_governance")
    report_layers = data.get("report_layers")
    cross_version_baseline = data.get("cross_version_baseline")

    if not isinstance(channel, str) or not channel.strip():
        _add_error(errors, "visual_snapshot_targets.json channel must be non-empty string")
    elif channel != "chapter_snapshot_v19":
        _add_error(errors, "visual_snapshot_targets.json channel must be chapter_snapshot_v19")

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
            "Stability Scoring",
            "Convergence Dashboard",
            "CI Signal Contract",
            "Convergence Trend Reinforcement",
            "Exception Lifecycle Linkage",
            "Visual-Performance Co-Gate",
            "Co-Gate Threshold Template",
            "Cross-Platform Alignment",
            "Pressure Scenario Standardization",
            "Alignment Dashboard Refinement",
            "Pressure Alignment Convergence Gate",
            "Regression Cycle Window Governance",
            "Multi-Cycle Adaptive Gate",
            "Release Feedback Governance",
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

    tier_names: set[str] = set()
    if not isinstance(stability_scoring, dict) or not stability_scoring:
        _add_error(errors, "visual_snapshot_targets.json stability_scoring must be non-empty object")
    else:
        weights = stability_scoring.get("weights")
        failure_caps = stability_scoring.get("failure_caps")
        confidence = stability_scoring.get("confidence")
        score_round_digits = stability_scoring.get("score_round_digits")

        if not isinstance(weights, dict) or not weights:
            _add_error(errors, "visual_snapshot_targets.json stability_scoring.weights must be non-empty object")
        else:
            required_weight_keys = ("matching_runs", "avg_warnings", "total_blockers", "tracking_failures")
            weight_sum = 0.0
            for key in required_weight_keys:
                value = _to_float(weights.get(key))
                if value is None or value < 0.0 or value > 1.0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_scoring.weights.{key} must be within [0.0, 1.0]")
                else:
                    weight_sum += value
            if weight_sum <= 0.0:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.weights sum must be > 0")

        if not isinstance(failure_caps, dict) or not failure_caps:
            _add_error(errors, "visual_snapshot_targets.json stability_scoring.failure_caps must be non-empty object")
        else:
            max_avg_warnings_cap = _to_float(failure_caps.get("max_avg_warnings"))
            max_total_blockers_cap = failure_caps.get("max_total_blockers")
            max_tracking_failures_cap = failure_caps.get("max_tracking_failures")
            if max_avg_warnings_cap is None or max_avg_warnings_cap <= 0.0:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.failure_caps.max_avg_warnings must be float > 0.0")
            if not isinstance(max_total_blockers_cap, int) or max_total_blockers_cap < 0:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.failure_caps.max_total_blockers must be int >= 0")
            if not isinstance(max_tracking_failures_cap, int) or max_tracking_failures_cap < 0:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.failure_caps.max_tracking_failures must be int >= 0")

        if not isinstance(confidence, dict) or not confidence:
            _add_error(errors, "visual_snapshot_targets.json stability_scoring.confidence must be non-empty object")
        else:
            reference_runs = confidence.get("reference_runs")
            min_confidence = _to_float(confidence.get("min_confidence"))
            if not isinstance(reference_runs, int) or reference_runs < 1:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.confidence.reference_runs must be int >= 1")
            if min_confidence is None or min_confidence < 0.0 or min_confidence > 1.0:
                _add_error(errors, "visual_snapshot_targets.json stability_scoring.confidence.min_confidence must be within [0.0, 1.0]")

        if not isinstance(score_round_digits, int) or score_round_digits < 0 or score_round_digits > 5:
            _add_error(errors, "visual_snapshot_targets.json stability_scoring.score_round_digits must be int within [0, 5]")

    if not isinstance(stability_tiers, dict) or not stability_tiers:
        _add_error(errors, "visual_snapshot_targets.json stability_tiers must be non-empty object")
    else:
        default_tier = stability_tiers.get("default_tier")
        tiers = stability_tiers.get("tiers")

        if not isinstance(default_tier, str) or not default_tier.strip():
            _add_error(errors, "visual_snapshot_targets.json stability_tiers.default_tier must be non-empty string")
        if not isinstance(tiers, list) or not tiers:
            _add_error(errors, "visual_snapshot_targets.json stability_tiers.tiers must be non-empty array")
        else:
            for idx, tier_row in enumerate(tiers):
                if not isinstance(tier_row, dict) or not tier_row:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}] must be non-empty object")
                    continue
                tier_name = tier_row.get("name")
                min_score = _to_float(tier_row.get("min_score"))
                max_avg_warnings = _to_float(tier_row.get("max_avg_warnings"))
                max_total_blockers = tier_row.get("max_total_blockers")
                max_tracking_failures = tier_row.get("max_tracking_failures")
                min_confidence = _to_float(tier_row.get("min_confidence"))

                if not isinstance(tier_name, str) or not tier_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].name must be non-empty string")
                else:
                    if tier_name in tier_names:
                        _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].name must be unique ({tier_name})")
                    tier_names.add(tier_name)

                if min_score is None or min_score < 0.0 or min_score > 100.0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].min_score must be within [0.0, 100.0]")
                if max_avg_warnings is None or max_avg_warnings < 0.0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_avg_warnings must be float >= 0.0")
                if not isinstance(max_total_blockers, int) or max_total_blockers < 0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_total_blockers must be int >= 0")
                if not isinstance(max_tracking_failures, int) or max_tracking_failures < 0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_tracking_failures must be int >= 0")
                if min_confidence is None or min_confidence < 0.0 or min_confidence > 1.0:
                    _add_error(errors, f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].min_confidence must be within [0.0, 1.0]")

        if isinstance(default_tier, str) and default_tier and tier_names and default_tier not in tier_names:
            _add_error(errors, "visual_snapshot_targets.json stability_tiers.default_tier must reference tiers.name")

    if not isinstance(convergence_dashboard, dict) or not convergence_dashboard:
        _add_error(errors, "visual_snapshot_targets.json convergence_dashboard must be non-empty object")
    else:
        for key in (
            "max_approval_failures",
            "max_tracking_failures",
            "max_trace_failures",
            "max_manifest_failures",
            "max_blockers",
            "max_warnings",
            "max_dashboard_failures",
        ):
            value = convergence_dashboard.get(key)
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json convergence_dashboard.{key} must be int >= 0")

    if not isinstance(ci_signal_contract, dict) or not ci_signal_contract:
        _add_error(errors, "visual_snapshot_targets.json ci_signal_contract must be non-empty object")
    else:
        required_fields = ci_signal_contract.get("required_fields")
        tier_requirements = ci_signal_contract.get("tier_requirements")
        max_contract_failures = ci_signal_contract.get("max_contract_failures")

        if not isinstance(required_fields, list) or not required_fields:
            _add_error(errors, "visual_snapshot_targets.json ci_signal_contract.required_fields must be non-empty array")
        else:
            for idx, field_name in enumerate(required_fields):
                if not isinstance(field_name, str) or not field_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json ci_signal_contract.required_fields[{idx}] must be non-empty string")

        if not isinstance(tier_requirements, dict) or not tier_requirements:
            _add_error(errors, "visual_snapshot_targets.json ci_signal_contract.tier_requirements must be non-empty object")
        else:
            ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
            for mode_name, tier_name in tier_requirements.items():
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json ci_signal_contract.tier_requirements key must be non-empty string")
                    continue
                if not isinstance(tier_name, str) or not tier_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json ci_signal_contract.tier_requirements.{mode_name} must be non-empty string")
                    continue
                if tier_names and tier_name not in tier_names:
                    _add_error(errors, f"visual_snapshot_targets.json ci_signal_contract.tier_requirements.{mode_name} must reference stability_tiers.tiers.name")
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for ci_signal_contract.tier_requirements")

        if not isinstance(max_contract_failures, int) or max_contract_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json ci_signal_contract.max_contract_failures must be int >= 0")

    if not isinstance(convergence_trend_reinforcement, dict) or not convergence_trend_reinforcement:
        _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement must be non-empty object")
    else:
        history_file = convergence_trend_reinforcement.get("history_file")
        long_window = convergence_trend_reinforcement.get("long_window")
        short_window = convergence_trend_reinforcement.get("short_window")
        min_samples = convergence_trend_reinforcement.get("min_samples")
        required_metrics = convergence_trend_reinforcement.get("required_metrics")
        max_worsening_metrics = convergence_trend_reinforcement.get("max_worsening_metrics")
        max_worsening_delta = _to_float(convergence_trend_reinforcement.get("max_worsening_delta"))
        min_improving_metrics = convergence_trend_reinforcement.get("min_improving_metrics")
        min_improvement_delta = _to_float(convergence_trend_reinforcement.get("min_improvement_delta"))
        max_trend_failures = convergence_trend_reinforcement.get("max_trend_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.history_file must be non-empty user:// path")
        archive_file_row = approval_history_archive.get("archive_file") if isinstance(approval_history_archive, dict) else None
        if isinstance(history_file, str) and isinstance(archive_file_row, str) and archive_file_row and history_file != archive_file_row:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.history_file must match approval_history_archive.archive_file")

        if not isinstance(long_window, int) or long_window < 5:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.long_window must be int >= 5")
        if not isinstance(short_window, int) or short_window < 3:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.short_window must be int >= 3")
        if isinstance(long_window, int) and isinstance(short_window, int) and short_window > long_window:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.short_window cannot exceed long_window")
        if not isinstance(min_samples, int) or min_samples < 1:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.min_samples must be int >= 1")
        if isinstance(short_window, int) and isinstance(min_samples, int) and min_samples > short_window:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.min_samples cannot exceed short_window")

        allowed_metrics = {
            "warnings",
            "blockers",
            "approval_failures",
            "tracking_failures",
            "dashboard_failures",
            "contract_failures",
            "stability_score",
        }
        if not isinstance(required_metrics, list) or not required_metrics:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics must be non-empty array")
            required_metrics = []
        else:
            for idx, metric_name in enumerate(required_metrics):
                if not isinstance(metric_name, str) or not metric_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics[{idx}] must be non-empty string")
                    continue
                if metric_name not in allowed_metrics:
                    _add_error(errors, f"visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics[{idx}] is not supported")

        if not isinstance(max_worsening_metrics, int) or max_worsening_metrics < 0:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_metrics must be int >= 0")
        elif isinstance(required_metrics, list) and max_worsening_metrics > len(required_metrics):
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_metrics cannot exceed required_metrics size")

        if max_worsening_delta is None or max_worsening_delta < 0.0:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_delta must be float >= 0.0")

        if not isinstance(min_improving_metrics, int) or min_improving_metrics < 0:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.min_improving_metrics must be int >= 0")
        elif isinstance(required_metrics, list) and min_improving_metrics > len(required_metrics):
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.min_improving_metrics cannot exceed required_metrics size")

        if min_improvement_delta is None or min_improvement_delta < 0.0:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.min_improvement_delta must be float >= 0.0")
        if not isinstance(max_trend_failures, int) or max_trend_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json convergence_trend_reinforcement.max_trend_failures must be int >= 0")

    if not isinstance(exception_lifecycle_linkage, dict) or not exception_lifecycle_linkage:
        _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage must be non-empty object")
    else:
        required_states = exception_lifecycle_linkage.get("required_states")
        stale_idle_runs = exception_lifecycle_linkage.get("stale_idle_runs")
        min_transition_count = exception_lifecycle_linkage.get("min_transition_count")
        max_orphan_entries = exception_lifecycle_linkage.get("max_orphan_entries")
        max_unlinked_reclaims = exception_lifecycle_linkage.get("max_unlinked_reclaims")
        max_unlinked_expired = exception_lifecycle_linkage.get("max_unlinked_expired")
        max_linkage_failures = exception_lifecycle_linkage.get("max_linkage_failures")

        allowed_states = {"active", "stale", "reclaim_candidate", "expired"}
        if not isinstance(required_states, list):
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage.required_states must be array")
        else:
            for idx, state_name in enumerate(required_states):
                if not isinstance(state_name, str) or not state_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json exception_lifecycle_linkage.required_states[{idx}] must be non-empty string")
                    continue
                if state_name not in allowed_states:
                    _add_error(errors, f"visual_snapshot_targets.json exception_lifecycle_linkage.required_states[{idx}] is not supported")

        if not isinstance(stale_idle_runs, int) or stale_idle_runs < 1:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage.stale_idle_runs must be int >= 1")
        expire_idle_runs = exception_lifecycle.get("expire_idle_runs") if isinstance(exception_lifecycle, dict) else None
        if isinstance(stale_idle_runs, int) and isinstance(expire_idle_runs, int) and stale_idle_runs >= expire_idle_runs:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage.stale_idle_runs must be < exception_lifecycle.expire_idle_runs")

        if not isinstance(min_transition_count, int) or min_transition_count < 0:
            _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage.min_transition_count must be int >= 0")
        else:
            max_expired = exception_lifecycle.get("max_expired_entries") if isinstance(exception_lifecycle, dict) else None
            max_reclaims = exception_lifecycle.get("max_reclaim_candidates") if isinstance(exception_lifecycle, dict) else None
            if isinstance(max_expired, int) and isinstance(max_reclaims, int):
                if min_transition_count > (max_expired + max_reclaims):
                    _add_error(errors, "visual_snapshot_targets.json exception_lifecycle_linkage.min_transition_count cannot exceed exception_lifecycle capacity")

        for key, value in {
            "max_orphan_entries": max_orphan_entries,
            "max_unlinked_reclaims": max_unlinked_reclaims,
            "max_unlinked_expired": max_unlinked_expired,
            "max_linkage_failures": max_linkage_failures,
        }.items():
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json exception_lifecycle_linkage.{key} must be int >= 0")

    if not isinstance(visual_performance_cogate, dict) or not visual_performance_cogate:
        _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate must be non-empty object")
    else:
        baseline_report = visual_performance_cogate.get("baseline_report")
        required_run_modes = visual_performance_cogate.get("required_run_modes")
        max_alert_total = visual_performance_cogate.get("max_alert_total")
        max_alert_critical = visual_performance_cogate.get("max_alert_critical")
        max_alert_warning = visual_performance_cogate.get("max_alert_warning")
        max_scenario_failures = visual_performance_cogate.get("max_scenario_failures")
        required_scenarios = visual_performance_cogate.get("required_scenarios")
        max_frame_ms_ratio = _to_float(visual_performance_cogate.get("max_frame_ms_ratio"))
        max_memory_mb_ratio = _to_float(visual_performance_cogate.get("max_memory_mb_ratio"))
        max_cogate_failures = visual_performance_cogate.get("max_cogate_failures")

        if not isinstance(baseline_report, str) or not baseline_report.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.baseline_report must be non-empty user:// path")

        release_checklist_row = release_gate_templates.get("release_checklist", {}) if isinstance(release_gate_templates, dict) else {}
        required_reports_row = release_checklist_row.get("required_reports", []) if isinstance(release_checklist_row, dict) else []
        if isinstance(baseline_report, str) and isinstance(required_reports_row, list) and baseline_report not in required_reports_row:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.baseline_report must be listed in release_gate_templates.release_checklist.required_reports")

        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.required_run_modes must be non-empty array")
        else:
            ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json visual_performance_cogate.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for visual_performance_cogate.required_run_modes")

        if not isinstance(max_alert_total, int) or max_alert_total < 0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_alert_total must be int >= 0")
        if not isinstance(max_alert_critical, int) or max_alert_critical < 0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_alert_critical must be int >= 0")
        if not isinstance(max_alert_warning, int) or max_alert_warning < 0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_alert_warning must be int >= 0")
        if not isinstance(max_scenario_failures, int) or max_scenario_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_scenario_failures must be int >= 0")

        if not isinstance(required_scenarios, list):
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.required_scenarios must be array")
        else:
            for idx, scenario_id in enumerate(required_scenarios):
                if not isinstance(scenario_id, str) or not scenario_id.strip():
                    _add_error(errors, f"visual_snapshot_targets.json visual_performance_cogate.required_scenarios[{idx}] must be non-empty string")

        if max_frame_ms_ratio is None or max_frame_ms_ratio < 1.0 or max_frame_ms_ratio > 3.0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_frame_ms_ratio must be within [1.0, 3.0]")
        if max_memory_mb_ratio is None or max_memory_mb_ratio < 1.0 or max_memory_mb_ratio > 3.0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_memory_mb_ratio must be within [1.0, 3.0]")
        if not isinstance(max_cogate_failures, int) or max_cogate_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json visual_performance_cogate.max_cogate_failures must be int >= 0")

    if not isinstance(cogate_threshold_templates, dict) or not cogate_threshold_templates:
        _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates must be non-empty object")
    else:
        default_template = cogate_threshold_templates.get("default_template")
        run_mode_templates = cogate_threshold_templates.get("run_mode_templates")
        templates = cogate_threshold_templates.get("templates")

        if not isinstance(default_template, str) or not default_template.strip():
            _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.default_template must be non-empty string")

        template_names = set()
        if not isinstance(templates, dict) or not templates:
            _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.templates must be non-empty object")
        else:
            for template_name, template_row in templates.items():
                if not isinstance(template_name, str) or not template_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.templates key must be non-empty string")
                    continue
                template_names.add(template_name)
                if not isinstance(template_row, dict) or not template_row:
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name} must be non-empty object")
                    continue

                for key in [
                    "max_alert_total",
                    "max_alert_critical",
                    "max_alert_warning",
                    "max_scenario_failures",
                    "max_cogate_failures",
                ]:
                    value = template_row.get(key)
                    if not isinstance(value, int) or value < 0:
                        _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.{key} must be int >= 0")

                frame_ratio = _to_float(template_row.get("max_frame_ms_ratio"))
                memory_ratio = _to_float(template_row.get("max_memory_mb_ratio"))
                if frame_ratio is None or frame_ratio < 1.0 or frame_ratio > 3.0:
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.max_frame_ms_ratio must be within [1.0, 3.0]")
                if memory_ratio is None or memory_ratio < 1.0 or memory_ratio > 3.0:
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.max_memory_mb_ratio must be within [1.0, 3.0]")

        if isinstance(default_template, str) and default_template and template_names and default_template not in template_names:
            _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.default_template must exist in templates")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(run_mode_templates, dict) or not run_mode_templates:
            _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates must be non-empty object")
        else:
            for run_mode_name, template_name in run_mode_templates.items():
                if not isinstance(run_mode_name, str) or not run_mode_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates key must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and run_mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{run_mode_name}' for cogate_threshold_templates.run_mode_templates")
                if not isinstance(template_name, str) or not template_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates.{run_mode_name} must be non-empty string")
                    continue
                if template_names and template_name not in template_names:
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates.{run_mode_name} must reference templates key")

            cogate_run_modes = visual_performance_cogate.get("required_run_modes", []) if isinstance(visual_performance_cogate, dict) else []
            for mode_name in cogate_run_modes if isinstance(cogate_run_modes, list) else []:
                if isinstance(mode_name, str) and mode_name and mode_name not in run_mode_templates:
                    _add_error(errors, f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates must include '{mode_name}' from visual_performance_cogate.required_run_modes")

    if not isinstance(cross_platform_alignment, dict) or not cross_platform_alignment:
        _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment must be non-empty object")
    else:
        history_file = cross_platform_alignment.get("history_file")
        aggregation_window = cross_platform_alignment.get("aggregation_window")
        required_run_modes = cross_platform_alignment.get("required_run_modes")
        required_backends = cross_platform_alignment.get("required_backends")
        metric_limits = cross_platform_alignment.get("metric_limits")
        max_missing_backends = cross_platform_alignment.get("max_missing_backends")
        max_missing_run_modes = cross_platform_alignment.get("max_missing_run_modes")
        max_alignment_failures = cross_platform_alignment.get("max_alignment_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.history_file must be non-empty user:// path")
        archive_file_row = approval_history_archive.get("archive_file") if isinstance(approval_history_archive, dict) else None
        if isinstance(history_file, str) and isinstance(archive_file_row, str) and archive_file_row and history_file != archive_file_row:
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.history_file must match approval_history_archive.archive_file")

        if not isinstance(aggregation_window, int) or aggregation_window < 10:
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.aggregation_window must be int >= 10")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json cross_platform_alignment.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for cross_platform_alignment.required_run_modes")

        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.required_backends must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json cross_platform_alignment.required_backends[{idx}] must be non-empty string")

        if not isinstance(metric_limits, dict) or not metric_limits:
            _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.metric_limits must be non-empty object")
        else:
            allowed_metrics = {
                "performance_alert_total",
                "performance_alert_critical",
                "performance_alert_warning",
                "performance_scenario_failures",
                "performance_cogate_failures",
            }
            for metric_name, limit_value in metric_limits.items():
                if not isinstance(metric_name, str) or not metric_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json cross_platform_alignment.metric_limits key must be non-empty string")
                    continue
                if metric_name not in allowed_metrics:
                    _add_error(errors, f"visual_snapshot_targets.json cross_platform_alignment.metric_limits.{metric_name} is not supported")
                    continue
                if not isinstance(limit_value, int) or limit_value < 0:
                    _add_error(errors, f"visual_snapshot_targets.json cross_platform_alignment.metric_limits.{metric_name} must be int >= 0")

        for key, value in {
            "max_missing_backends": max_missing_backends,
            "max_missing_run_modes": max_missing_run_modes,
            "max_alignment_failures": max_alignment_failures,
        }.items():
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json cross_platform_alignment.{key} must be int >= 0")

    if not isinstance(pressure_scenario_standardization, dict) or not pressure_scenario_standardization:
        _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization must be non-empty object")
    else:
        baseline_targets_file = pressure_scenario_standardization.get("baseline_targets_file")
        baseline_report = pressure_scenario_standardization.get("baseline_report")
        required_run_modes = pressure_scenario_standardization.get("required_run_modes")
        required_scenarios = pressure_scenario_standardization.get("required_scenarios")
        max_avg_frame_ms_ratio = _to_float(pressure_scenario_standardization.get("max_avg_frame_ms_ratio"))
        max_p95_frame_ms_ratio = _to_float(pressure_scenario_standardization.get("max_p95_frame_ms_ratio"))
        max_peak_memory_mb_ratio = _to_float(pressure_scenario_standardization.get("max_peak_memory_mb_ratio"))
        max_standardization_failures = pressure_scenario_standardization.get("max_standardization_failures")

        if not isinstance(baseline_targets_file, str) or not baseline_targets_file.startswith("res://"):
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.baseline_targets_file must be non-empty res:// path")
        if not isinstance(baseline_report, str) or not baseline_report.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.baseline_report must be non-empty user:// path")

        release_checklist_row = release_gate_templates.get("release_checklist", {}) if isinstance(release_gate_templates, dict) else {}
        required_reports_row = release_checklist_row.get("required_reports", []) if isinstance(release_checklist_row, dict) else []
        if isinstance(baseline_report, str) and isinstance(required_reports_row, list) and baseline_report not in required_reports_row:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.baseline_report must be listed in release_gate_templates.release_checklist.required_reports")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json pressure_scenario_standardization.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for pressure_scenario_standardization.required_run_modes")

        if not isinstance(required_scenarios, list) or not required_scenarios:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.required_scenarios must be non-empty array")
        else:
            for idx, scenario_name in enumerate(required_scenarios):
                if not isinstance(scenario_name, str) or not scenario_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json pressure_scenario_standardization.required_scenarios[{idx}] must be non-empty string")

        if max_avg_frame_ms_ratio is None or max_avg_frame_ms_ratio < 1.0 or max_avg_frame_ms_ratio > 3.0:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.max_avg_frame_ms_ratio must be within [1.0, 3.0]")
        if max_p95_frame_ms_ratio is None or max_p95_frame_ms_ratio < 1.0 or max_p95_frame_ms_ratio > 3.0:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.max_p95_frame_ms_ratio must be within [1.0, 3.0]")
        if max_peak_memory_mb_ratio is None or max_peak_memory_mb_ratio < 1.0 or max_peak_memory_mb_ratio > 3.0:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.max_peak_memory_mb_ratio must be within [1.0, 3.0]")
        if not isinstance(max_standardization_failures, int) or max_standardization_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json pressure_scenario_standardization.max_standardization_failures must be int >= 0")

    if not isinstance(alignment_dashboard_refinement, dict) or not alignment_dashboard_refinement:
        _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement must be non-empty object")
    else:
        required_run_modes = alignment_dashboard_refinement.get("required_run_modes")
        metric_weights = alignment_dashboard_refinement.get("metric_weights")
        missing_backend_weight = _to_float(alignment_dashboard_refinement.get("missing_backend_weight"))
        missing_run_mode_weight = _to_float(alignment_dashboard_refinement.get("missing_run_mode_weight"))
        watch_score_threshold = _to_float(alignment_dashboard_refinement.get("watch_score_threshold"))
        critical_score_threshold = _to_float(alignment_dashboard_refinement.get("critical_score_threshold"))
        max_dashboard_failures = alignment_dashboard_refinement.get("max_dashboard_failures")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json alignment_dashboard_refinement.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for alignment_dashboard_refinement.required_run_modes")

        allowed_dashboard_metrics = {
            "performance_alert_total",
            "performance_alert_critical",
            "performance_alert_warning",
            "performance_scenario_failures",
            "performance_cogate_failures",
        }
        metric_limits_row = cross_platform_alignment.get("metric_limits", {}) if isinstance(cross_platform_alignment, dict) else {}
        if not isinstance(metric_weights, dict) or not metric_weights:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights must be non-empty object")
        else:
            for metric_name, weight_value in metric_weights.items():
                if not isinstance(metric_name, str) or not metric_name.strip():
                    _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights key must be non-empty string")
                    continue
                if metric_name not in allowed_dashboard_metrics:
                    _add_error(errors, f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} is not supported")
                    continue
                if isinstance(metric_limits_row, dict) and metric_name not in metric_limits_row:
                    _add_error(errors, f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} must exist in cross_platform_alignment.metric_limits")
                weight_float = _to_float(weight_value)
                if weight_float is None or weight_float < 0.0 or weight_float > 5.0:
                    _add_error(errors, f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} must be within [0.0, 5.0]")

        if missing_backend_weight is None or missing_backend_weight < 0.0 or missing_backend_weight > 5.0:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.missing_backend_weight must be within [0.0, 5.0]")
        if missing_run_mode_weight is None or missing_run_mode_weight < 0.0 or missing_run_mode_weight > 5.0:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.missing_run_mode_weight must be within [0.0, 5.0]")
        if watch_score_threshold is None or watch_score_threshold < 0.0:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.watch_score_threshold must be float >= 0.0")
        if critical_score_threshold is None or critical_score_threshold < 0.0:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.critical_score_threshold must be float >= 0.0")
        if watch_score_threshold is not None and critical_score_threshold is not None and critical_score_threshold < watch_score_threshold:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.critical_score_threshold must be >= watch_score_threshold")
        if not isinstance(max_dashboard_failures, int) or max_dashboard_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json alignment_dashboard_refinement.max_dashboard_failures must be int >= 0")

    if not isinstance(pressure_alignment_convergence_gate, dict) or not pressure_alignment_convergence_gate:
        _add_error(errors, "visual_snapshot_targets.json pressure_alignment_convergence_gate must be non-empty object")
    else:
        required_run_modes = pressure_alignment_convergence_gate.get("required_run_modes")
        required_backends = pressure_alignment_convergence_gate.get("required_backends")
        max_standardization_failures = pressure_alignment_convergence_gate.get("max_standardization_failures")
        max_alignment_failures = pressure_alignment_convergence_gate.get("max_alignment_failures")
        max_dashboard_failures = pressure_alignment_convergence_gate.get("max_dashboard_failures")
        max_critical_severity_count = pressure_alignment_convergence_gate.get("max_critical_severity_count")
        max_convergence_failures = pressure_alignment_convergence_gate.get("max_convergence_failures")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json pressure_alignment_convergence_gate.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for pressure_alignment_convergence_gate.required_run_modes")

        backend_matrix_required_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends[{idx}] must be non-empty string")
                    continue
                if isinstance(backend_matrix_required_row, list) and backend_name not in backend_matrix_required_row:
                    _add_error(errors, f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")

        for key, value in {
            "max_standardization_failures": max_standardization_failures,
            "max_alignment_failures": max_alignment_failures,
            "max_dashboard_failures": max_dashboard_failures,
            "max_critical_severity_count": max_critical_severity_count,
            "max_convergence_failures": max_convergence_failures,
        }.items():
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json pressure_alignment_convergence_gate.{key} must be int >= 0")

    if not isinstance(regression_cycle_window_governance, dict) or not regression_cycle_window_governance:
        _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance must be non-empty object")
    else:
        history_file = regression_cycle_window_governance.get("history_file")
        cycle_window_size = regression_cycle_window_governance.get("cycle_window_size")
        min_cycle_entries = regression_cycle_window_governance.get("min_cycle_entries")
        required_run_modes = regression_cycle_window_governance.get("required_run_modes")
        required_backends = regression_cycle_window_governance.get("required_backends")
        max_warning_delta = regression_cycle_window_governance.get("max_warning_delta")
        max_blocker_delta = regression_cycle_window_governance.get("max_blocker_delta")
        max_alignment_score_delta = _to_float(regression_cycle_window_governance.get("max_alignment_score_delta"))
        max_cycle_failures = regression_cycle_window_governance.get("max_cycle_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.history_file must be non-empty user:// path")
        archive_file_row = approval_history_archive.get("archive_file", "") if isinstance(approval_history_archive, dict) else ""
        if isinstance(history_file, str) and isinstance(archive_file_row, str) and archive_file_row and history_file != archive_file_row:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.history_file must match approval_history_archive.archive_file")

        if not isinstance(cycle_window_size, int) or cycle_window_size < 10:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.cycle_window_size must be int >= 10")
        if not isinstance(min_cycle_entries, int) or min_cycle_entries < 1:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.min_cycle_entries must be int >= 1")
        if isinstance(cycle_window_size, int) and isinstance(min_cycle_entries, int) and min_cycle_entries > cycle_window_size:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.min_cycle_entries must be <= cycle_window_size")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json regression_cycle_window_governance.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for regression_cycle_window_governance.required_run_modes")

        backend_matrix_required_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.required_backends must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json regression_cycle_window_governance.required_backends[{idx}] must be non-empty string")
                    continue
                if isinstance(backend_matrix_required_row, list) and backend_name not in backend_matrix_required_row:
                    _add_error(errors, f"visual_snapshot_targets.json regression_cycle_window_governance.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")

        if not isinstance(max_warning_delta, int) or max_warning_delta < 0:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.max_warning_delta must be int >= 0")
        if not isinstance(max_blocker_delta, int) or max_blocker_delta < 0:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.max_blocker_delta must be int >= 0")
        if max_alignment_score_delta is None or max_alignment_score_delta < 0.0 or max_alignment_score_delta > 5.0:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.max_alignment_score_delta must be within [0.0, 5.0]")
        if not isinstance(max_cycle_failures, int) or max_cycle_failures < 0:
            _add_error(errors, "visual_snapshot_targets.json regression_cycle_window_governance.max_cycle_failures must be int >= 0")

    if not isinstance(multi_cycle_adaptive_gate, dict) or not multi_cycle_adaptive_gate:
        _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate must be non-empty object")
    else:
        history_file = multi_cycle_adaptive_gate.get("history_file")
        window_sizes = multi_cycle_adaptive_gate.get("window_sizes")
        min_window_entries = multi_cycle_adaptive_gate.get("min_window_entries")
        required_run_modes = multi_cycle_adaptive_gate.get("required_run_modes")
        required_backends = multi_cycle_adaptive_gate.get("required_backends")
        max_warning_slopes = multi_cycle_adaptive_gate.get("max_warning_slopes")
        max_blocker_slopes = multi_cycle_adaptive_gate.get("max_blocker_slopes")
        max_missing_run_modes = multi_cycle_adaptive_gate.get("max_missing_run_modes")
        max_missing_backends = multi_cycle_adaptive_gate.get("max_missing_backends")
        max_adaptive_failures = multi_cycle_adaptive_gate.get("max_adaptive_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.history_file must be non-empty user:// path")
        archive_file_row = approval_history_archive.get("archive_file", "") if isinstance(approval_history_archive, dict) else ""
        if isinstance(history_file, str) and isinstance(archive_file_row, str) and archive_file_row and history_file != archive_file_row:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.history_file must match approval_history_archive.archive_file")

        short_window = None
        if not isinstance(window_sizes, dict) or not window_sizes:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes must be non-empty object")
        else:
            short_window = window_sizes.get("short")
            mid_window = window_sizes.get("mid")
            long_window = window_sizes.get("long")
            if not isinstance(short_window, int) or short_window < 4:
                _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.short must be int >= 4")
            if not isinstance(mid_window, int) or mid_window < 4:
                _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.mid must be int >= 4")
            if not isinstance(long_window, int) or long_window < 4:
                _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.long must be int >= 4")
            if isinstance(short_window, int) and isinstance(mid_window, int) and mid_window < short_window:
                _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.mid must be >= short")
            if isinstance(mid_window, int) and isinstance(long_window, int) and long_window < mid_window:
                _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.long must be >= mid")

        if not isinstance(min_window_entries, int) or min_window_entries < 1:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.min_window_entries must be int >= 1")
        elif isinstance(short_window, int) and min_window_entries > short_window:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.min_window_entries must be <= window_sizes.short")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for multi_cycle_adaptive_gate.required_run_modes")

        backend_matrix_required_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends[{idx}] must be non-empty string")
                    continue
                if isinstance(backend_matrix_required_row, list) and backend_name not in backend_matrix_required_row:
                    _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")

        for key, slope_row in {
            "max_warning_slopes": max_warning_slopes,
            "max_blocker_slopes": max_blocker_slopes,
        }.items():
            if not isinstance(slope_row, dict) or not slope_row:
                _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key} must be non-empty object")
                continue
            for window_key in ("short", "mid", "long"):
                slope_value = _to_float(slope_row.get(window_key))
                if slope_value is None or slope_value < 0.0 or slope_value > 10.0:
                    _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key}.{window_key} must be within [0.0, 10.0]")

        for key, value in {
            "max_missing_run_modes": max_missing_run_modes,
            "max_missing_backends": max_missing_backends,
            "max_adaptive_failures": max_adaptive_failures,
        }.items():
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key} must be int >= 0")

    if not isinstance(release_feedback_governance, dict) or not release_feedback_governance:
        _add_error(errors, "visual_snapshot_targets.json release_feedback_governance must be non-empty object")
    else:
        history_file = release_feedback_governance.get("history_file")
        feedback_window_size = release_feedback_governance.get("feedback_window_size")
        min_feedback_entries = release_feedback_governance.get("min_feedback_entries")
        required_run_modes = release_feedback_governance.get("required_run_modes")
        required_backends = release_feedback_governance.get("required_backends")
        issue_metrics = release_feedback_governance.get("issue_metrics")
        min_closure_rate = _to_float(release_feedback_governance.get("min_closure_rate"))
        max_unresolved_issues = release_feedback_governance.get("max_unresolved_issues")
        max_missing_run_modes = release_feedback_governance.get("max_missing_run_modes")
        max_missing_backends = release_feedback_governance.get("max_missing_backends")
        max_feedback_failures = release_feedback_governance.get("max_feedback_failures")

        if not isinstance(history_file, str) or not history_file.startswith("user://"):
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.history_file must be non-empty user:// path")
        archive_file_row = approval_history_archive.get("archive_file", "") if isinstance(approval_history_archive, dict) else ""
        if isinstance(history_file, str) and isinstance(archive_file_row, str) and archive_file_row and history_file != archive_file_row:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.history_file must match approval_history_archive.archive_file")

        if not isinstance(feedback_window_size, int) or feedback_window_size < 5:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.feedback_window_size must be int >= 5")
        if not isinstance(min_feedback_entries, int) or min_feedback_entries < 1:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.min_feedback_entries must be int >= 1")
        if isinstance(feedback_window_size, int) and isinstance(min_feedback_entries, int) and min_feedback_entries > feedback_window_size:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.min_feedback_entries must be <= feedback_window_size")

        ci_mode_bindings_row = release_gate_templates.get("ci_mode_bindings", {}) if isinstance(release_gate_templates, dict) else {}
        if not isinstance(required_run_modes, list) or not required_run_modes:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.required_run_modes must be non-empty array")
        else:
            for idx, mode_name in enumerate(required_run_modes):
                if not isinstance(mode_name, str) or not mode_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.required_run_modes[{idx}] must be non-empty string")
                    continue
                if isinstance(ci_mode_bindings_row, dict) and mode_name not in ci_mode_bindings_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for release_feedback_governance.required_run_modes")

        backend_matrix_required_row = backend_matrix_governance.get("required_backend_matrix", []) if isinstance(backend_matrix_governance, dict) else []
        if not isinstance(required_backends, list) or not required_backends:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.required_backends must be non-empty array")
        else:
            for idx, backend_name in enumerate(required_backends):
                if not isinstance(backend_name, str) or not backend_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.required_backends[{idx}] must be non-empty string")
                    continue
                if isinstance(backend_matrix_required_row, list) and backend_name not in backend_matrix_required_row:
                    _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")

        allowed_issue_metrics = {
            "blockers",
            "warnings",
            "approval_failures",
            "tracking_failures",
            "dashboard_failures",
            "contract_failures",
            "performance_cogate_failures",
            "performance_scenario_failures",
            "pressure_standardization_failures",
            "alignment_dashboard_failures",
        }
        if not isinstance(issue_metrics, list) or not issue_metrics:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.issue_metrics must be non-empty array")
        else:
            for idx, metric_name in enumerate(issue_metrics):
                if not isinstance(metric_name, str) or not metric_name.strip():
                    _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.issue_metrics[{idx}] must be non-empty string")
                    continue
                if metric_name not in allowed_issue_metrics:
                    _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.issue_metrics[{idx}] is not supported")

        if min_closure_rate is None or min_closure_rate < 0.0 or min_closure_rate > 1.0:
            _add_error(errors, "visual_snapshot_targets.json release_feedback_governance.min_closure_rate must be within [0.0, 1.0]")

        for key, value in {
            "max_unresolved_issues": max_unresolved_issues,
            "max_missing_run_modes": max_missing_run_modes,
            "max_missing_backends": max_missing_backends,
            "max_feedback_failures": max_feedback_failures,
        }.items():
            if not isinstance(value, int) or value < 0:
                _add_error(errors, f"visual_snapshot_targets.json release_feedback_governance.{key} must be int >= 0")

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
