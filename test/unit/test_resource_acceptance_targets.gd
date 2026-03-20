extends GutTest

const TARGETS_PATH := "res://data/balance/resource_acceptance_targets.json"
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


func _catalog_ids_by_category(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var categories: Dictionary = catalog.get("categories", {})
	for category in categories.keys():
		var id_map: Dictionary = {}
		var entries: Array = categories.get(category, [])
		for entry in entries:
			if entry is Dictionary:
				var row: Dictionary = entry
				var id: String = str(row.get("id", ""))
				if not id.is_empty():
					id_map[id] = row
		result[category] = id_map
	return result


func test_resource_acceptance_targets_schema_and_coverage() -> void:
	var targets: Dictionary = _load_json(TARGETS_PATH)
	assert_false(targets.is_empty(), "resource_acceptance_targets.json should be readable")
	if targets.is_empty():
		return

	assert_true(str(targets.get("channel", "")).length() > 0, "channel should be non-empty")

	var required_fields: Array = targets.get("required_fields", [])
	assert_true(required_fields.has("preview_texture"), "required_fields should include preview_texture")
	assert_true(required_fields.has("acceptance_scene"), "required_fields should include acceptance_scene")
	assert_true(required_fields.has("acceptance_tier"), "required_fields should include acceptance_tier")

	var scene_map: Dictionary = targets.get("acceptance_scene_map", {})
	var scene_matrix: Dictionary = targets.get("acceptance_scene_matrix", {})
	var scene_visual_requirements: Dictionary = targets.get("scene_visual_requirements", {})
	var texture_map: Dictionary = targets.get("preview_texture_map", {})
	var required_ready: Dictionary = targets.get("required_production_ready_ids", {})
	var profile_policy: Dictionary = targets.get("acceptance_profile_policy", {})
	var trend_baseline: Dictionary = targets.get("trend_baseline", {})
	var thresholds: Dictionary = targets.get("thresholds", {})
	assert_false(scene_map.is_empty(), "acceptance_scene_map should not be empty")
	assert_false(scene_matrix.is_empty(), "acceptance_scene_matrix should not be empty")
	assert_false(scene_visual_requirements.is_empty(), "scene_visual_requirements should not be empty")
	assert_false(texture_map.is_empty(), "preview_texture_map should not be empty")
	assert_false(required_ready.is_empty(), "required_production_ready_ids should not be empty")
	assert_false(profile_policy.is_empty(), "acceptance_profile_policy should not be empty")
	assert_false(trend_baseline.is_empty(), "trend_baseline should not be empty")

	var min_ready_per_category: int = int(thresholds.get("min_ready_per_category", 1))
	var min_ready_ratio_per_category: float = float(thresholds.get("min_ready_ratio_per_category", 0.0))
	var min_scene_smokes_per_category: int = int(thresholds.get("min_scene_smokes_per_category", 1))
	var min_visual_checks_per_category: int = int(thresholds.get("min_visual_checks_per_category", 1))
	var max_visual_failures: int = int(thresholds.get("max_visual_failures", -1))
	var max_profile_mismatches: int = int(thresholds.get("max_profile_mismatches", -1))
	var max_trend_regressions: int = int(thresholds.get("max_trend_regressions", -1))
	assert_gte(min_ready_per_category, 4, "D26 target should require at least 4 production-ready entries per category")
	assert_gte(min_ready_ratio_per_category, 0.95, "D26 target should enforce >= 0.95 ready ratio")
	assert_gte(min_scene_smokes_per_category, 4, "D26 target should enforce deeper cross-scene smoke coverage")
	assert_gte(min_visual_checks_per_category, 4, "D26 target should enforce denser scene visual checks per category")
	assert_eq(max_visual_failures, 0, "D26 target should enforce zero visual failures")
	assert_eq(max_profile_mismatches, 0, "D26 target should enforce zero profile mismatches")
	assert_eq(max_trend_regressions, 0, "D26 target should enforce zero trend regressions")

	var bucket_ready_ratio_min: Dictionary = trend_baseline.get("bucket_ready_ratio_min", {})
	assert_false(bucket_ready_ratio_min.is_empty(), "trend_baseline.bucket_ready_ratio_min should not be empty")
	for bucket in ["menu", "combat", "ui"]:
		assert_true(bucket_ready_ratio_min.has(bucket), "trend_baseline.bucket_ready_ratio_min should include %s" % bucket)
		assert_gte(float(bucket_ready_ratio_min.get(bucket, 0.0)), 0.95, "D26 trend baseline ready ratio should be at least 0.95: %s" % bucket)

	var required_ready_profile_tier: String = str(profile_policy.get("required_ready_profile_tier", ""))
	var profiles: Dictionary = profile_policy.get("profiles", {})
	var category_profile_map: Dictionary = profile_policy.get("category_profile_map", {})
	assert_eq(required_ready_profile_tier, "ready", "D26 should require ready tier for production_ready ids")
	assert_false(profiles.is_empty(), "acceptance_profile_policy.profiles should not be empty")
	assert_false(category_profile_map.is_empty(), "acceptance_profile_policy.category_profile_map should not be empty")

	var catalog: Dictionary = _load_json(RESOURCE_CATALOG_PATH)
	assert_eq(str(catalog.get("version", "")), "stub_catalog_v8", "resource catalog should be v8")
	var catalog_bucket_counts: Dictionary = catalog.get("acceptance_bucket_counts", {})
	var catalog_visual_requirements: Dictionary = catalog.get("scene_visual_requirements", {})
	var catalog_visual_requirement_counts: Dictionary = catalog.get("scene_visual_requirement_counts", {})
	var catalog_ready_ratios: Dictionary = catalog.get("production_ready_ratio_by_category", {})
	assert_false(catalog_bucket_counts.is_empty(), "catalog acceptance_bucket_counts should not be empty")
	assert_false(catalog_visual_requirements.is_empty(), "catalog scene_visual_requirements should not be empty")
	assert_false(catalog_visual_requirement_counts.is_empty(), "catalog scene_visual_requirement_counts should not be empty")
	assert_false(catalog_ready_ratios.is_empty(), "catalog production_ready_ratio_by_category should not be empty")
	var catalog_ids: Dictionary = _catalog_ids_by_category(catalog)
	var bucket_ready_summary: Dictionary = {}

	for category in required_ready.keys():
		var ids: Array = required_ready.get(category, [])
		assert_gte(ids.size(), min_ready_per_category, "required_production_ready_ids.%s should contain expanded ready entries" % category)
		assert_true(FileAccess.file_exists(str(scene_map.get(category, ""))), "acceptance scene for %s should exist" % category)
		assert_true(FileAccess.file_exists(str(texture_map.get(category, ""))), "preview texture for %s should exist" % category)

		var smoke_scenes: Array = scene_matrix.get(category, [])
		assert_gte(smoke_scenes.size(), min_scene_smokes_per_category, "acceptance_scene_matrix.%s should contain enough scene smokes" % category)
		for scene_path_variant in smoke_scenes:
			var scene_path: String = str(scene_path_variant)
			assert_true(scene_path.begins_with("res://"), "acceptance_scene_matrix.%s should use res:// paths" % category)
			assert_true(FileAccess.file_exists(scene_path), "acceptance_scene_matrix.%s scene should exist: %s" % [category, scene_path])

		var visual_requirements: Array = scene_visual_requirements.get(category, [])
		assert_gte(visual_requirements.size(), min_visual_checks_per_category, "scene_visual_requirements.%s should contain enough visual checks" % category)
		assert_eq(int(catalog_visual_requirement_counts.get(category, -1)), visual_requirements.size(), "catalog scene_visual_requirement_counts should match scene_visual_requirements for %s" % category)
		var catalog_visual_rows: Array = catalog_visual_requirements.get(category, [])
		assert_eq(catalog_visual_rows.size(), visual_requirements.size(), "catalog scene_visual_requirements.%s should match targets" % category)
		for idx in visual_requirements.size():
			var visual_row_variant: Variant = visual_requirements[idx]
			assert_true(visual_row_variant is Dictionary, "scene_visual_requirements.%s[%d] should be object" % [category, idx])
			if not (visual_row_variant is Dictionary):
				continue
			var visual_row: Dictionary = visual_row_variant
			assert_true(FileAccess.file_exists(str(visual_row.get("scene", ""))), "visual check scene should exist for %s[%d]" % [category, idx])
			assert_true(str(visual_row.get("node_path", "")).length() > 0, "visual check node_path should be non-empty for %s[%d]" % [category, idx])
			assert_true(str(visual_row.get("node_type", "")).length() > 0, "visual check node_type should be non-empty for %s[%d]" % [category, idx])
			assert_true(str(visual_row.get("rule", "")).length() > 0, "visual check rule should be non-empty for %s[%d]" % [category, idx])

		var by_id: Dictionary = catalog_ids.get(category, {})
		var ready_count: int = 0
		for row_variant in by_id.values():
			if row_variant is Dictionary:
				var row_dict: Dictionary = row_variant
				if str(row_dict.get("asset_state", "")) == "production_ready":
					ready_count += 1

		assert_gte(ready_count, min_ready_per_category, "catalog %s ready count should reach D26 minimum" % category)
		var ready_ratio: float = float(ready_count) / maxf(1.0, float(by_id.size()))
		assert_true(ready_ratio >= min_ready_ratio_per_category, "catalog %s ready ratio should reach D26 minimum" % category)
		assert_eq(float(catalog_ready_ratios.get(category, -1.0)), ready_ratio, "catalog production_ready_ratio_by_category should match %s ratio" % category)

		for id_variant in ids:
			var id: String = str(id_variant)
			assert_true(by_id.has(id), "catalog should include required production-ready id %s in %s" % [id, category])
			if not by_id.has(id):
				continue
			var row: Dictionary = by_id.get(id, {})
			assert_eq(str(row.get("asset_state", "")), "production_ready", "required id should be production_ready: %s" % id)
			assert_eq(str(row.get("acceptance_tier", "")), required_ready_profile_tier, "required id should use required_ready_profile_tier: %s" % id)

		var category_profiles: Dictionary = category_profile_map.get(category, {})
		if category_profiles.is_empty():
			continue
		var expected_candidate_profile: String = str(category_profiles.get("production_candidate", ""))
		var expected_ready_profile: String = str(category_profiles.get("production_ready", ""))
		assert_true(profiles.has(expected_candidate_profile), "candidate profile should exist in policy: %s" % category)
		assert_true(profiles.has(expected_ready_profile), "ready profile should exist in policy: %s" % category)
		for row_variant in by_id.values():
			if not (row_variant is Dictionary):
				continue
			var row_dict: Dictionary = row_variant
			var state: String = str(row_dict.get("asset_state", ""))
			var profile_name: String = str(row_dict.get("acceptance_profile", ""))
			if profiles.has(profile_name):
				var profile_row: Dictionary = profiles.get(profile_name, {})
				var bucket_name: String = str(profile_row.get("report_bucket", ""))
				if not bucket_name.is_empty():
					if not bucket_ready_summary.has(bucket_name):
						bucket_ready_summary[bucket_name] = {
							"entries": 0,
							"ready_entries": 0,
						}
					var bucket_row: Dictionary = bucket_ready_summary.get(bucket_name, {})
					bucket_row["entries"] = int(bucket_row.get("entries", 0)) + 1
					if state == "production_ready":
						bucket_row["ready_entries"] = int(bucket_row.get("ready_entries", 0)) + 1
					bucket_ready_summary[bucket_name] = bucket_row
			if state == "production_candidate" and not expected_candidate_profile.is_empty():
				assert_eq(profile_name, expected_candidate_profile, "candidate profile mapping should match policy: %s" % category)
			if state == "production_ready" and not expected_ready_profile.is_empty():
				assert_eq(profile_name, expected_ready_profile, "ready profile mapping should match policy: %s" % category)

	for bucket in bucket_ready_ratio_min.keys():
		var row: Dictionary = bucket_ready_summary.get(str(bucket), {})
		var entries: int = int(row.get("entries", 0))
		var ready_entries: int = int(row.get("ready_entries", 0))
		assert_gte(entries, 1, "catalog bucket %s should include at least one entry" % bucket)
		var ratio: float = float(ready_entries) / maxf(1.0, float(entries))
		assert_true(ratio >= float(bucket_ready_ratio_min.get(bucket, 0.0)), "catalog bucket %s ready ratio should meet D26 trend baseline" % bucket)
		var catalog_bucket_row: Dictionary = catalog_bucket_counts.get(str(bucket), {})
		assert_eq(int(catalog_bucket_row.get("entries", -1)), entries, "catalog acceptance_bucket_counts entries should match for bucket %s" % bucket)
		assert_eq(int(catalog_bucket_row.get("ready_entries", -1)), ready_entries, "catalog acceptance_bucket_counts ready_entries should match for bucket %s" % bucket)
