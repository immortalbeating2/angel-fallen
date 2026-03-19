extends GutTest

const EVOLUTION_CONFIG_PATH := "res://data/balance/evolutions.json"


func _load_evolution_config() -> Dictionary:
	var file := FileAccess.open(EVOLUTION_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "evolutions.json should be readable")
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "evolutions.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func test_evolutions_schema_includes_required_fields() -> void:
	var cfg := _load_evolution_config()
	var rows: Array = cfg.get("evolutions", [])
	assert_typeof(rows, TYPE_ARRAY, "evolutions should be an Array")
	assert_gt(rows.size(), 0, "evolutions should not be empty")

	var seen_ids := {}
	for i in range(rows.size()):
		var row_var: Variant = rows[i]
		assert_typeof(row_var, TYPE_DICTIONARY, "evolutions[%d] should be Dictionary" % i)
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var

		var evo_id: String = str(row.get("id", ""))
		assert_ne(evo_id, "", "evolutions[%d].id should not be empty" % i)
		assert_false(seen_ids.has(evo_id), "evolutions id should be unique: %s" % evo_id)
		seen_ids[evo_id] = true

		var weapon_id: String = str(row.get("weapon_id", ""))
		var passive_id: String = str(row.get("passive_id", ""))
		var result_weapon_id: String = str(row.get("result_weapon_id", ""))
		assert_true(weapon_id.begins_with("wpn_"), "weapon_id should start with wpn_")
		assert_true(passive_id.begins_with("pas_"), "passive_id should start with pas_")
		assert_true(result_weapon_id.begins_with("wpn_"), "result_weapon_id should start with wpn_")
		assert_ne(result_weapon_id, weapon_id, "result weapon should differ from source weapon")

		assert_ne(str(row.get("title", "")), "", "title should not be empty")
		assert_ne(str(row.get("desc", "")), "", "desc should not be empty")
		assert_gte(int(row.get("required_passive_level", 0)), 1, "required_passive_level lower bound")
		assert_lte(int(row.get("required_passive_level", 99)), 5, "required_passive_level upper bound")


func test_evolution_profile_ranges_are_reasonable() -> void:
	var cfg := _load_evolution_config()
	var rows: Array = cfg.get("evolutions", [])

	for i in range(rows.size()):
		var row_var: Variant = rows[i]
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var
		var profile: Dictionary = row.get("evolution_profile", {})
		assert_typeof(profile, TYPE_DICTIONARY, "evolution_profile should be Dictionary")
		if profile.is_empty():
			continue

		assert_gte(float(profile.get("damage_mult", 0.0)), 0.8, "damage_mult lower bound")
		assert_lte(float(profile.get("damage_mult", 9.0)), 3.0, "damage_mult upper bound")
		assert_gte(float(profile.get("flat_damage_bonus", -1.0)), 0.0, "flat_damage_bonus lower bound")
		assert_lte(float(profile.get("flat_damage_bonus", 999.0)), 30.0, "flat_damage_bonus upper bound")
		assert_gte(float(profile.get("interval_mult", 0.0)), 0.35, "interval_mult lower bound")
		assert_lte(float(profile.get("interval_mult", 9.0)), 1.25, "interval_mult upper bound")

		var mode: String = str(profile.get("weapon_mode", ""))
		assert_true(mode == "single" or mode == "spread", "weapon_mode must be single or spread")
		assert_gte(int(profile.get("projectile_count", 0)), 1, "projectile_count lower bound")
		assert_lte(int(profile.get("projectile_count", 99)), 8, "projectile_count upper bound")
		assert_gte(float(profile.get("spread_angle_deg", -1.0)), 0.0, "spread_angle_deg lower bound")
		assert_lte(float(profile.get("spread_angle_deg", 999.0)), 60.0, "spread_angle_deg upper bound")
		assert_gte(float(profile.get("spread_jitter_deg", -1.0)), 0.0, "spread_jitter_deg lower bound")
		assert_lte(float(profile.get("spread_jitter_deg", 999.0)), 20.0, "spread_jitter_deg upper bound")
		assert_gte(int(profile.get("projectile_hits", 0)), 1, "projectile_hits lower bound")
		assert_lte(int(profile.get("projectile_hits", 99)), 12, "projectile_hits upper bound")
		assert_ne(str(profile.get("projectile_style", "")), "", "projectile_style should not be empty")
