extends GutTest

const RESOURCE_DIRS := [
	"res://resources/characters",
	"res://resources/weapons",
	"res://resources/passives",
	"res://resources/accessories",
	"res://resources/enemies",
	"res://resources/evolutions",
	"res://resources/meta_upgrades",
	"res://resources/forge_recipes",
]
const RESOURCE_CATALOG_PATH := "res://resources/resource_catalog.json"


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _collect_ids(items: Array, key: String = "id") -> Dictionary:
	var ids: Dictionary = {}
	for item in items:
		if item is Dictionary:
			var value: String = str(item.get(key, ""))
			if not value.is_empty():
				ids[value] = true
	return ids


func test_resource_directory_baseline_exists() -> void:
	for path in RESOURCE_DIRS:
		assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)), "%s should exist" % path)


func test_resource_catalog_entries_reference_existing_sources() -> void:
	var catalog: Dictionary = _load_json(RESOURCE_CATALOG_PATH)
	assert_false(catalog.is_empty(), "resource catalog should be readable")
	if catalog.is_empty():
		return

	assert_eq(str(catalog.get("version", "")), "stub_catalog_v8", "resource catalog should use expected version")
	var production_ready_counts: Dictionary = catalog.get("production_ready_counts", {})
	assert_true(not production_ready_counts.is_empty(), "production_ready_counts should not be empty")
	var production_ready_ratio_by_category: Dictionary = catalog.get("production_ready_ratio_by_category", {})
	assert_true(not production_ready_ratio_by_category.is_empty(), "production_ready_ratio_by_category should not be empty")
	var acceptance_tier_counts: Dictionary = catalog.get("acceptance_tier_counts", {})
	assert_true(not acceptance_tier_counts.is_empty(), "acceptance_tier_counts should not be empty")
	var acceptance_bucket_counts: Dictionary = catalog.get("acceptance_bucket_counts", {})
	assert_true(not acceptance_bucket_counts.is_empty(), "acceptance_bucket_counts should not be empty")
	var scene_visual_requirements: Dictionary = catalog.get("scene_visual_requirements", {})
	assert_true(not scene_visual_requirements.is_empty(), "scene_visual_requirements should not be empty")
	var scene_visual_requirement_counts: Dictionary = catalog.get("scene_visual_requirement_counts", {})
	assert_true(not scene_visual_requirement_counts.is_empty(), "scene_visual_requirement_counts should not be empty")
	var profile_policy: Dictionary = catalog.get("acceptance_profile_policy", {})
	var profiles: Dictionary = profile_policy.get("profiles", {})
	var category_profile_map: Dictionary = profile_policy.get("category_profile_map", {})
	var required_ready_profile_tier: String = str(profile_policy.get("required_ready_profile_tier", "ready"))
	assert_false(profiles.is_empty(), "acceptance_profile_policy.profiles should not be empty")
	assert_false(category_profile_map.is_empty(), "acceptance_profile_policy.category_profile_map should not be empty")
	var categories: Dictionary = catalog.get("categories", {})
	assert_true(not categories.is_empty(), "resource catalog categories should not be empty")
	if categories.is_empty():
		return

	var bucket_counts: Dictionary = {}

	for dir_path in RESOURCE_DIRS:
		var category_name: String = String(dir_path).get_file()
		var entries: Array = categories.get(category_name, [])
		var visual_rows: Array = scene_visual_requirements.get(category_name, [])
		assert_gte(visual_rows.size(), 4, "catalog scene_visual_requirements.%s should contain at least 4 checks" % category_name)
		assert_eq(int(scene_visual_requirement_counts.get(category_name, -1)), visual_rows.size(), "catalog scene_visual_requirement_counts should match visual requirements for %s" % category_name)
		assert_gt(entries.size(), 0, "catalog category %s should contain entries" % category_name)
		var ready_count: int = 0
		var tier_counts: Dictionary = {
			"candidate": 0,
			"ready": 0,
		}
		var profile_map_row: Dictionary = category_profile_map.get(category_name, {})
		var expected_candidate_profile: String = str(profile_map_row.get("production_candidate", ""))
		var expected_ready_profile: String = str(profile_map_row.get("production_ready", ""))
		if not profile_map_row.is_empty():
			assert_true(not expected_candidate_profile.is_empty(), "category_profile_map should define production_candidate profile for %s" % category_name)
			assert_true(not expected_ready_profile.is_empty(), "category_profile_map should define production_ready profile for %s" % category_name)
		for entry in entries:
			assert_true(entry is Dictionary, "catalog entry in %s should be Dictionary" % category_name)
			if not (entry is Dictionary):
				continue
			var row: Dictionary = entry
			var id: String = str(row.get("id", ""))
			var path: String = str(row.get("path", ""))
			var source_json: String = str(row.get("source_json", ""))
			var material_profile: String = str(row.get("material_profile", ""))
			var asset_state: String = str(row.get("asset_state", ""))
			var preview_texture: String = str(row.get("preview_texture", ""))
			var acceptance_scene: String = str(row.get("acceptance_scene", ""))
			var acceptance_profile: String = str(row.get("acceptance_profile", ""))
			var acceptance_tier: String = str(row.get("acceptance_tier", ""))
			assert_true(not id.is_empty(), "catalog entry id in %s should be non-empty" % category_name)
			assert_true(path.begins_with("res://resources/"), "catalog path should be in resources: %s" % path)
			assert_true(source_json.begins_with("res://"), "catalog source_json should start with res://")
			assert_true(material_profile.begins_with("res://resources/material_profiles/"), "catalog material_profile should be in material_profiles")
			assert_true(asset_state == "production_candidate" or asset_state == "production_ready", "catalog asset_state should be candidate or ready")
			assert_true(preview_texture.begins_with("res://"), "catalog preview_texture should be res:// path")
			assert_true(acceptance_scene.begins_with("res://"), "catalog acceptance_scene should be res:// path")
			assert_true(not acceptance_profile.is_empty(), "catalog acceptance_profile should be non-empty")
			assert_true(acceptance_tier == "candidate" or acceptance_tier == "ready", "catalog acceptance_tier should be candidate or ready")
			assert_true(profiles.has(acceptance_profile), "catalog acceptance_profile should exist in acceptance_profile_policy")
			if profiles.has(acceptance_profile):
				var profile_row: Dictionary = profiles.get(acceptance_profile, {})
				assert_eq(str(profile_row.get("tier", "")), acceptance_tier, "catalog acceptance_tier should match profile tier")
				var report_bucket: String = str(profile_row.get("report_bucket", ""))
				assert_true(not report_bucket.is_empty(), "profile report_bucket should be non-empty")
				if not report_bucket.is_empty():
					if not bucket_counts.has(report_bucket):
						bucket_counts[report_bucket] = {
							"entries": 0,
							"ready_entries": 0,
						}
					var bucket_row: Dictionary = bucket_counts.get(report_bucket, {})
					bucket_row["entries"] = int(bucket_row.get("entries", 0)) + 1
					if asset_state == "production_ready":
						bucket_row["ready_entries"] = int(bucket_row.get("ready_entries", 0)) + 1
					bucket_counts[report_bucket] = bucket_row
			if asset_state == "production_ready":
				ready_count += 1
				assert_eq(acceptance_tier, required_ready_profile_tier, "production_ready entries should use required ready tier")
				if not expected_ready_profile.is_empty():
					assert_eq(acceptance_profile, expected_ready_profile, "production_ready profile should match category policy")
			elif not expected_candidate_profile.is_empty():
				assert_eq(acceptance_profile, expected_candidate_profile, "production_candidate profile should match category policy")

			tier_counts[acceptance_tier] = int(tier_counts.get(acceptance_tier, 0)) + 1
			assert_true(FileAccess.file_exists(path), "catalog resource file should exist: %s" % path)
			assert_true(FileAccess.file_exists(source_json), "catalog source_json target should exist: %s" % source_json)
			assert_true(FileAccess.file_exists(material_profile), "catalog material_profile target should exist: %s" % material_profile)
			assert_true(FileAccess.file_exists(preview_texture), "catalog preview_texture target should exist: %s" % preview_texture)
			assert_true(FileAccess.file_exists(acceptance_scene), "catalog acceptance_scene target should exist: %s" % acceptance_scene)
			if not FileAccess.file_exists(path):
				continue
			var resource_text: String = FileAccess.get_file_as_string(path)
			assert_true(resource_text.find('id = "%s"' % id) >= 0, "resource id should match catalog id for %s" % path)
			assert_true(resource_text.find('source_json = "%s"' % source_json) >= 0, "resource source_json should match catalog for %s" % path)
			assert_true(resource_text.find('material_profile = "%s"' % material_profile) >= 0, "resource material_profile should match catalog for %s" % path)
			assert_true(resource_text.find('asset_state = "%s"' % asset_state) >= 0, "resource asset_state should match catalog for %s" % path)
			assert_true(resource_text.find('preview_texture = "%s"' % preview_texture) >= 0, "resource preview_texture should match catalog for %s" % path)
			assert_true(resource_text.find('acceptance_scene = "%s"' % acceptance_scene) >= 0, "resource acceptance_scene should match catalog for %s" % path)
			assert_true(resource_text.find('acceptance_profile = "%s"' % acceptance_profile) >= 0, "resource acceptance_profile should match catalog for %s" % path)
			assert_true(resource_text.find('acceptance_tier = "%s"' % acceptance_tier) >= 0, "resource acceptance_tier should match catalog for %s" % path)

		assert_eq(int(production_ready_counts.get(category_name, -1)), ready_count, "production_ready_counts should match %s entries" % category_name)
		var expected_ratio: float = float(ready_count) / maxf(1.0, float(entries.size()))
		assert_eq(float(production_ready_ratio_by_category.get(category_name, -1.0)), expected_ratio, "production_ready_ratio_by_category should match %s entries" % category_name)
		var tier_count_row: Dictionary = acceptance_tier_counts.get(category_name, {})
		assert_eq(int(tier_count_row.get("candidate", -1)), int(tier_counts.get("candidate", -1)), "acceptance_tier_counts candidate should match %s entries" % category_name)
		assert_eq(int(tier_count_row.get("ready", -1)), int(tier_counts.get("ready", -1)), "acceptance_tier_counts ready should match %s entries" % category_name)

	for bucket_name in bucket_counts.keys():
		var local_row: Dictionary = bucket_counts.get(bucket_name, {})
		var catalog_row: Dictionary = acceptance_bucket_counts.get(bucket_name, {})
		assert_eq(int(catalog_row.get("entries", -1)), int(local_row.get("entries", -1)), "acceptance_bucket_counts entries should match bucket %s" % bucket_name)
		assert_eq(int(catalog_row.get("ready_entries", -1)), int(local_row.get("ready_entries", -1)), "acceptance_bucket_counts ready_entries should match bucket %s" % bucket_name)


func test_resource_catalog_covers_content_ids() -> void:
	var catalog: Dictionary = _load_json(RESOURCE_CATALOG_PATH)
	var categories: Dictionary = catalog.get("categories", {})
	if categories.is_empty():
		assert_true(false, "resource catalog categories should be available")
		return

	var character_data: Dictionary = _load_json("res://data/balance/characters.json")
	var evolution_data: Dictionary = _load_json("res://data/balance/evolutions.json")
	var shop_data: Dictionary = _load_json("res://data/balance/shop_items.json")
	var meta_data: Dictionary = _load_json("res://data/balance/meta_upgrades.json")
	var enemy_scaling_data: Dictionary = _load_json("res://data/balance/enemy_scaling.json")
	var boss_phase_data: Dictionary = _load_json("res://data/balance/boss_phases.json")

	var character_ids: Dictionary = _collect_ids(character_data.get("characters", []))
	var evolution_ids: Dictionary = _collect_ids(evolution_data.get("evolutions", []))
	var meta_ids: Dictionary = _collect_ids(meta_data.get("upgrades", []))

	var weapon_ids: Dictionary = {}
	for id in shop_data.get("pools", {}).get("weapon", []):
		if id is String and not String(id).is_empty():
			weapon_ids[String(id)] = true

	var passive_ids: Dictionary = {}
	for id in shop_data.get("pools", {}).get("passive", []):
		if id is String and not String(id).is_empty():
			passive_ids[String(id)] = true

	var enemy_ids: Dictionary = {}
	for chapter_data in enemy_scaling_data.get("chapter_archetype_map", {}).values():
		if chapter_data is Dictionary:
			for enemy_id in chapter_data.values():
				if enemy_id is String and not String(enemy_id).is_empty():
					enemy_ids[String(enemy_id)] = true
	for boss_id in boss_phase_data.get("bosses", {}).keys():
		if boss_id is String and not String(boss_id).is_empty():
			enemy_ids[String(boss_id)] = true

	var accessory_ids: Dictionary = {
		"acc_heart_of_mine": true,
		"acc_flame_core": true,
		"acc_zero_mark": true,
		"acc_void_eye": true,
	}

	var category_ids: Dictionary = {}
	for category_name in ["characters", "weapons", "passives", "accessories", "enemies", "evolutions", "meta_upgrades", "forge_recipes"]:
		var entries: Array = categories.get(category_name, [])
		var ids: Dictionary = {}
		for entry in entries:
			if entry is Dictionary:
				var value: String = str(entry.get("id", ""))
				if not value.is_empty():
					ids[value] = true
		category_ids[category_name] = ids

	var category_characters: Dictionary = category_ids.get("characters", {})
	var category_weapons: Dictionary = category_ids.get("weapons", {})
	var category_passives: Dictionary = category_ids.get("passives", {})
	var category_accessories: Dictionary = category_ids.get("accessories", {})
	var category_enemies: Dictionary = category_ids.get("enemies", {})
	var category_evolutions: Dictionary = category_ids.get("evolutions", {})
	var category_meta: Dictionary = category_ids.get("meta_upgrades", {})
	var category_forge: Dictionary = category_ids.get("forge_recipes", {})

	for id in character_ids.keys():
		assert_true(category_characters.has(id), "characters catalog should include %s" % id)
	for id in weapon_ids.keys():
		assert_true(category_weapons.has(id), "weapons catalog should include %s" % id)
	for id in passive_ids.keys():
		assert_true(category_passives.has(id), "passives catalog should include %s" % id)
	for id in accessory_ids.keys():
		assert_true(category_accessories.has(id), "accessories catalog should include %s" % id)
	for id in enemy_ids.keys():
		assert_true(category_enemies.has(id), "enemies catalog should include %s" % id)
	for id in evolution_ids.keys():
		assert_true(category_evolutions.has(id), "evolutions catalog should include %s" % id)
	for id in meta_ids.keys():
		assert_true(category_meta.has(id), "meta catalog should include %s" % id)

	assert_eq(category_forge.size(), evolution_ids.size(), "forge recipe stubs should map one-to-one with evolutions")
