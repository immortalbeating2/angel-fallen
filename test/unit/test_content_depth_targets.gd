extends GutTest

const CHARACTERS_CONFIG_PATH := "res://data/balance/characters.json"
const EVOLUTIONS_CONFIG_PATH := "res://data/balance/evolutions.json"
const SHOP_CONFIG_PATH := "res://data/balance/shop_items.json"
const NARRATIVE_CONFIG_PATH := "res://data/balance/narrative_content.json"


func _load_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "%s should be readable" % path)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "%s should parse as Dictionary" % path)
	if parsed is Dictionary:
		return parsed
	return {}


func test_character_roster_reaches_content_depth_target() -> void:
	var cfg := _load_json_dict(CHARACTERS_CONFIG_PATH)
	var rows: Array = cfg.get("characters", [])
	assert_typeof(rows, TYPE_ARRAY, "characters should be an Array")
	assert_gte(rows.size(), 12, "characters should contain at least 12 entries")


func test_evolution_roster_reaches_content_depth_target() -> void:
	var cfg := _load_json_dict(EVOLUTIONS_CONFIG_PATH)
	var rows: Array = cfg.get("evolutions", [])
	assert_typeof(rows, TYPE_ARRAY, "evolutions should be an Array")
	assert_gte(rows.size(), 13, "evolutions should contain at least 13 entries")

	var seen_result_ids := {}
	for row_var: Variant in rows:
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var
		var result_id: String = str(row.get("result_weapon_id", ""))
		assert_ne(result_id, "", "result_weapon_id should not be empty")
		assert_false(seen_result_ids.has(result_id), "result_weapon_id should be unique: %s" % result_id)
		seen_result_ids[result_id] = true


func test_shop_pools_reach_content_depth_target() -> void:
	var cfg := _load_json_dict(SHOP_CONFIG_PATH)
	var pools: Dictionary = cfg.get("pools", {})
	assert_typeof(pools, TYPE_DICTIONARY, "pools should be a Dictionary")

	var passive_pool: Array = pools.get("passive", [])
	var weapon_pool: Array = pools.get("weapon", [])
	assert_typeof(passive_pool, TYPE_ARRAY, "passive pool should be an Array")
	assert_typeof(weapon_pool, TYPE_ARRAY, "weapon pool should be an Array")

	assert_gte(passive_pool.size(), 14, "passive pool should contain at least 14 entries")
	assert_gte(weapon_pool.size(), 15, "weapon pool should contain at least 15 entries")


func test_memory_fragments_reach_content_depth_target() -> void:
	var cfg := _load_json_dict(NARRATIVE_CONFIG_PATH)
	var memory_fragments: Dictionary = cfg.get("memory_fragments", {})
	assert_typeof(memory_fragments, TYPE_DICTIONARY, "memory_fragments should be a Dictionary")
	assert_gte(memory_fragments.size(), 22, "memory_fragments should contain at least 22 entries")
