extends SceneTree

const TARGETS_PATH := "res://data/balance/resource_acceptance_targets.json"
const CATALOG_PATH := "res://resources/resource_catalog.json"
const PREV_REPORT_JSON_PATH := "user://resource_acceptance_previous.json"
const REPORT_JSON_PATH := "user://resource_acceptance_latest.json"
const REPORT_MD_PATH := "user://resource_acceptance_latest.md"


func _initialize() -> void:
	_rotate_previous_report()
	var report: Dictionary = _run_acceptance()
	_write_reports(report)
	var blockers: int = int(report.get("blockers", 0))
	var warnings: int = int(report.get("warnings", 0))
	print("Resource acceptance complete -> blockers: %d, warnings: %d" % [blockers, warnings])
	if blockers > 0:
		quit(1)
	else:
		quit(0)


func _run_acceptance() -> Dictionary:
	var targets: Dictionary = _read_json(TARGETS_PATH)
	var catalog: Dictionary = _read_json(CATALOG_PATH)
	var previous_report: Dictionary = _read_json(PREV_REPORT_JSON_PATH)
	var report: Dictionary = {
		"generated_at_unix": Time.get_unix_time_from_system(),
		"channel": str(targets.get("channel", "unknown")),
		"blockers": 0,
		"warnings": 0,
		"checked": 0,
		"passed": 0,
		"category_ready": {},
		"scene_smokes": {},
		"visual_checks": {},
		"profile_layers": {},
		"profile_buckets": {},
		"profile_mismatches": 0,
		"visual_failures": 0,
		"trend": {
			"regressions": 0,
			"category_ratio_drops": {},
			"bucket_ratio_drops": {},
		},
		"items": [],
	}

	var profile_policy: Dictionary = targets.get("acceptance_profile_policy", {})
	var scene_visual_requirements: Dictionary = targets.get("scene_visual_requirements", {})
	var profiles: Dictionary = profile_policy.get("profiles", {})
	var category_profile_map: Dictionary = profile_policy.get("category_profile_map", {})
	var required_ready_profile_tier: String = str(profile_policy.get("required_ready_profile_tier", "ready"))

	var thresholds: Dictionary = targets.get("thresholds", {})
	var min_ready_per_category: int = int(thresholds.get("min_ready_per_category", 1))
	var min_ready_ratio_per_category: float = float(thresholds.get("min_ready_ratio_per_category", 0.0))
	var min_scene_smokes_per_category: int = int(thresholds.get("min_scene_smokes_per_category", 1))
	var min_visual_checks_per_category: int = int(thresholds.get("min_visual_checks_per_category", 1))
	var max_visual_failures: int = int(thresholds.get("max_visual_failures", 0))
	var max_profile_mismatches: int = int(thresholds.get("max_profile_mismatches", 0))
	var max_trend_regressions: int = int(thresholds.get("max_trend_regressions", 0))
	var max_failures: int = int(thresholds.get("max_failures", 0))
	var trend_baseline: Dictionary = targets.get("trend_baseline", {})
	var bucket_ready_ratio_min: Dictionary = trend_baseline.get("bucket_ready_ratio_min", {})
	var max_category_ratio_drop: float = float(trend_baseline.get("max_category_ratio_drop", 1.0))
	var max_bucket_ratio_drop: float = float(trend_baseline.get("max_bucket_ratio_drop", 1.0))
	var required_map: Dictionary = targets.get("required_production_ready_ids", {})
	var scene_matrix: Dictionary = targets.get("acceptance_scene_matrix", {})
	var categories: Dictionary = catalog.get("categories", {})
	var production_ready_counts: Dictionary = catalog.get("production_ready_counts", {})
	var production_ready_ratio_by_category: Dictionary = catalog.get("production_ready_ratio_by_category", {})
	var acceptance_bucket_counts: Dictionary = catalog.get("acceptance_bucket_counts", {})
	var scene_visual_requirement_counts: Dictionary = catalog.get("scene_visual_requirement_counts", {})

	if required_map.is_empty():
		_push_result(report, "global", "missing_required_production_ready_ids", false, "targets.required_production_ready_ids is empty")
		return report

	var profile_mismatch_count: int = 0
	var visual_failures: int = 0

	for category in required_map.keys():
		var required_ids_variant: Variant = required_map.get(category, [])
		if not (required_ids_variant is Array):
			_push_result(report, str(category), "invalid_required_ids", false, "required_production_ready_ids.%s must be array" % category)
			continue

		var required_ids: Array = required_ids_variant
		if required_ids.is_empty():
			_push_result(report, str(category), "empty_required_ids", false, "required_production_ready_ids.%s cannot be empty" % category)
			continue

		var category_entries_variant: Variant = categories.get(category, [])
		if not (category_entries_variant is Array):
			_push_result(report, str(category), "missing_category_entries", false, "catalog.categories.%s missing" % category)
			continue

		var category_entries: Array = category_entries_variant
		var by_id: Dictionary = {}
		var ready_count: int = 0
		var total_entries: int = category_entries.size()
		for row in category_entries:
			if row is Dictionary:
				var row_dict: Dictionary = row
				var row_id: String = str(row_dict.get("id", ""))
				var row_asset_state: String = str(row_dict.get("asset_state", ""))
				var row_profile: String = str(row_dict.get("acceptance_profile", ""))
				var row_tier: String = str(row_dict.get("acceptance_tier", ""))
				var report_bucket: String = "unknown"
				if not row_id.is_empty():
					by_id[row_id] = row_dict
				if row_asset_state == "production_ready":
					ready_count += 1

				var profile_layers: Dictionary = report.get("profile_layers", {})
				var layer_name: String = row_tier if not row_tier.is_empty() else "unknown"
				var layer_row: Dictionary = profile_layers.get(layer_name, {"entries": 0, "ready_entries": 0})
				layer_row["entries"] = int(layer_row.get("entries", 0)) + 1
				if row_asset_state == "production_ready":
					layer_row["ready_entries"] = int(layer_row.get("ready_entries", 0)) + 1
				profile_layers[layer_name] = layer_row
				report["profile_layers"] = profile_layers

				if not profiles.has(row_profile):
					profile_mismatch_count += 1
					_push_result(report, str(category), row_id, false, "acceptance_profile missing in acceptance_profile_policy.profiles")
				else:
					var profile_row: Dictionary = profiles.get(row_profile, {})
					var profile_tier: String = str(profile_row.get("tier", ""))
					report_bucket = str(profile_row.get("report_bucket", "")).strip_edges()
					if report_bucket.is_empty():
						report_bucket = "unknown"
					if profile_tier != row_tier:
						profile_mismatch_count += 1
						_push_result(report, str(category), row_id, false, "acceptance_tier does not match acceptance_profile_policy tier")

				var profile_buckets: Dictionary = report.get("profile_buckets", {})
				var bucket_row: Dictionary = profile_buckets.get(report_bucket, {"entries": 0, "ready_entries": 0})
				bucket_row["entries"] = int(bucket_row.get("entries", 0)) + 1
				if row_asset_state == "production_ready":
					bucket_row["ready_entries"] = int(bucket_row.get("ready_entries", 0)) + 1
				profile_buckets[report_bucket] = bucket_row
				report["profile_buckets"] = profile_buckets

				var category_profile_row: Variant = category_profile_map.get(category, {})
				if category_profile_row is Dictionary:
					var expected_profile: String = str((category_profile_row as Dictionary).get(row_asset_state, ""))
					if not expected_profile.is_empty() and row_profile != expected_profile:
						profile_mismatch_count += 1
						_push_result(report, str(category), row_id, false, "acceptance_profile does not match category_profile_map")

		if int(production_ready_counts.get(category, -1)) != ready_count:
			_push_result(
				report,
				str(category),
				"production_ready_count_mismatch",
				false,
				"catalog.production_ready_counts.%s mismatch with entries" % category
			)

		var category_ratio: float = 0.0
		if total_entries > 0:
			category_ratio = float(ready_count) / float(total_entries)
		var catalog_ratio: float = float(production_ready_ratio_by_category.get(category, -1.0))
		if catalog_ratio < 0.0 or absf(catalog_ratio - category_ratio) > 0.0001:
			_push_result(
				report,
				str(category),
				"production_ready_ratio_mismatch",
				false,
				"catalog.production_ready_ratio_by_category.%s mismatch with entries" % category
			)
		var category_ready_summary: Dictionary = report.get("category_ready", {})
		category_ready_summary[str(category)] = {
			"ready_count": ready_count,
			"total_entries": total_entries,
			"ready_ratio": category_ratio,
		}
		report["category_ready"] = category_ready_summary

		var previous_category_ready: Dictionary = previous_report.get("category_ready", {})
		var previous_category_row: Dictionary = previous_category_ready.get(str(category), {})
		if not previous_category_row.is_empty():
			var previous_ratio: float = float(previous_category_row.get("ready_ratio", category_ratio))
			var category_drop: float = maxf(0.0, previous_ratio - category_ratio)
			var trend: Dictionary = report.get("trend", {})
			var category_ratio_drops: Dictionary = trend.get("category_ratio_drops", {})
			category_ratio_drops[str(category)] = category_drop
			trend["category_ratio_drops"] = category_ratio_drops
			report["trend"] = trend
			if category_drop > max_category_ratio_drop:
				_push_warning(
					report,
					str(category),
					"category_ratio_drop",
					"ready_ratio drop %.3f exceeds max_category_ratio_drop %.3f" % [category_drop, max_category_ratio_drop]
				)
				trend["regressions"] = int(trend.get("regressions", 0)) + 1
				report["trend"] = trend

		if ready_count < min_ready_per_category:
			_push_result(
				report,
				str(category),
				"min_ready_per_category",
				false,
				"ready_count %d below min_ready_per_category %d" % [ready_count, min_ready_per_category]
			)

		if category_ratio < min_ready_ratio_per_category:
			_push_result(
				report,
				str(category),
				"min_ready_ratio_per_category",
				false,
				"ready_ratio %.2f below min_ready_ratio_per_category %.2f" % [category_ratio, min_ready_ratio_per_category]
			)

		var required_scenes: Array[String] = _sanitize_scene_list(scene_matrix.get(category, []))
		var scene_smoke_passed: int = 0
		for scene_path in required_scenes:
			if _smoke_scene(scene_path):
				scene_smoke_passed += 1
				_push_result(report, str(category), "scene:%s" % scene_path, true, "scene smoke accepted")
			else:
				_push_result(report, str(category), "scene:%s" % scene_path, false, "scene smoke failed")

		var scene_smoke_summary: Dictionary = report.get("scene_smokes", {})
		scene_smoke_summary[str(category)] = {
			"configured": required_scenes.size(),
			"required": min_scene_smokes_per_category,
			"passed": scene_smoke_passed,
		}
		report["scene_smokes"] = scene_smoke_summary

		if required_scenes.size() < min_scene_smokes_per_category:
			_push_result(
				report,
				str(category),
				"scene_matrix_size",
				false,
				"acceptance_scene_matrix entries %d below min_scene_smokes_per_category %d" % [required_scenes.size(), min_scene_smokes_per_category]
			)
		elif scene_smoke_passed < min_scene_smokes_per_category:
			_push_result(
				report,
				str(category),
				"scene_smoke_pass_rate",
				false,
				"scene smoke passed %d below required %d" % [scene_smoke_passed, min_scene_smokes_per_category]
			)

		var visual_requirements_variant: Variant = scene_visual_requirements.get(category, [])
		var visual_requirements: Array = visual_requirements_variant if visual_requirements_variant is Array else []
		var visual_passed: int = 0
		for idx in visual_requirements.size():
			var requirement_variant: Variant = visual_requirements[idx]
			if not (requirement_variant is Dictionary):
				visual_failures += 1
				_push_result(report, str(category), "visual:%d" % idx, false, "visual requirement must be object")
				continue
			var requirement: Dictionary = requirement_variant
			var visual_result: Dictionary = _run_visual_requirement(requirement)
			if bool(visual_result.get("passed", false)):
				visual_passed += 1
				_push_result(report, str(category), "visual:%d" % idx, true, str(visual_result.get("message", "visual check passed")))
			else:
				visual_failures += 1
				_push_result(report, str(category), "visual:%d" % idx, false, str(visual_result.get("message", "visual check failed")))

		var visual_summary: Dictionary = report.get("visual_checks", {})
		visual_summary[str(category)] = {
			"configured": visual_requirements.size(),
			"required": min_visual_checks_per_category,
			"passed": visual_passed,
		}
		report["visual_checks"] = visual_summary

		if visual_requirements.size() < min_visual_checks_per_category:
			_push_result(
				report,
				str(category),
				"visual_requirement_size",
				false,
				"scene_visual_requirements entries %d below min_visual_checks_per_category %d" % [visual_requirements.size(), min_visual_checks_per_category]
			)
		elif visual_passed < min_visual_checks_per_category:
			_push_result(
				report,
				str(category),
				"visual_pass_rate",
				false,
				"visual checks passed %d below required %d" % [visual_passed, min_visual_checks_per_category]
			)

		if int(scene_visual_requirement_counts.get(category, -1)) != visual_requirements.size():
			_push_result(
				report,
				str(category),
				"scene_visual_requirement_count_mismatch",
				false,
				"catalog.scene_visual_requirement_counts mismatch with configured visual requirements"
			)

		for required_id_variant in required_ids:
			var required_id: String = str(required_id_variant)
			if required_id.is_empty():
				continue
			if not by_id.has(required_id):
				_push_result(report, str(category), required_id, false, "required id not found in catalog category")
				continue

			var entry: Dictionary = by_id.get(required_id, {})
			var asset_state: String = str(entry.get("asset_state", ""))
			if asset_state != "production_ready":
				_push_result(report, str(category), required_id, false, "asset_state must be production_ready")
				continue

			var resource_path: String = str(entry.get("path", ""))
			var preview_texture: String = str(entry.get("preview_texture", ""))
			var acceptance_scene: String = str(entry.get("acceptance_scene", ""))
			var acceptance_profile: String = str(entry.get("acceptance_profile", ""))
			var acceptance_tier: String = str(entry.get("acceptance_tier", ""))

			if not FileAccess.file_exists(resource_path):
				_push_result(report, str(category), required_id, false, "resource file missing")
				continue
			if not FileAccess.file_exists(preview_texture):
				_push_result(report, str(category), required_id, false, "preview_texture file missing")
				continue
			if acceptance_profile.is_empty():
				_push_result(report, str(category), required_id, false, "acceptance_profile missing")
				continue
			if acceptance_tier != required_ready_profile_tier:
				_push_result(report, str(category), required_id, false, "production_ready acceptance_tier mismatch")
				continue

			if not ResourceLoader.exists(acceptance_scene):
				_push_result(report, str(category), required_id, false, "acceptance_scene does not exist")
				continue

			var packed_scene: PackedScene = load(acceptance_scene) as PackedScene
			if packed_scene == null:
				_push_result(report, str(category), required_id, false, "acceptance_scene load failed")
				continue

			var instance: Node = packed_scene.instantiate()
			if instance == null:
				_push_result(report, str(category), required_id, false, "acceptance_scene instantiate failed")
				continue

			instance.free()
			_push_result(report, str(category), required_id, true, "production_ready resource accepted")

	var profile_buckets: Dictionary = report.get("profile_buckets", {})
	var previous_profile_buckets: Dictionary = previous_report.get("profile_buckets", {})
	for bucket_name_variant in profile_buckets.keys():
		var bucket_name: String = str(bucket_name_variant)
		var bucket_row: Dictionary = profile_buckets.get(bucket_name, {})
		var bucket_entries: int = int(bucket_row.get("entries", 0))
		var bucket_ready_entries: int = int(bucket_row.get("ready_entries", 0))
		var bucket_ratio: float = 0.0
		if bucket_entries > 0:
			bucket_ratio = float(bucket_ready_entries) / float(bucket_entries)
		bucket_row["ready_ratio"] = bucket_ratio
		profile_buckets[bucket_name] = bucket_row

		var baseline_ratio: float = float(bucket_ready_ratio_min.get(bucket_name, -1.0))
		if baseline_ratio >= 0.0 and bucket_ratio < baseline_ratio:
			_push_warning(
				report,
				"global",
				"bucket_baseline:%s" % bucket_name,
				"bucket ready_ratio %.3f below baseline %.3f" % [bucket_ratio, baseline_ratio]
			)
			var trend_for_baseline: Dictionary = report.get("trend", {})
			trend_for_baseline["regressions"] = int(trend_for_baseline.get("regressions", 0)) + 1
			report["trend"] = trend_for_baseline

		var prev_bucket_row: Dictionary = previous_profile_buckets.get(bucket_name, {})
		if not prev_bucket_row.is_empty():
			var prev_ratio: float = float(prev_bucket_row.get("ready_ratio", bucket_ratio))
			var bucket_drop: float = maxf(0.0, prev_ratio - bucket_ratio)
			var trend: Dictionary = report.get("trend", {})
			var bucket_ratio_drops: Dictionary = trend.get("bucket_ratio_drops", {})
			bucket_ratio_drops[bucket_name] = bucket_drop
			trend["bucket_ratio_drops"] = bucket_ratio_drops
			report["trend"] = trend
			if bucket_drop > max_bucket_ratio_drop:
				_push_warning(
					report,
					"global",
					"bucket_ratio_drop:%s" % bucket_name,
					"bucket ready_ratio drop %.3f exceeds max_bucket_ratio_drop %.3f" % [bucket_drop, max_bucket_ratio_drop]
				)
				trend["regressions"] = int(trend.get("regressions", 0)) + 1
				report["trend"] = trend

		var catalog_bucket_row: Dictionary = acceptance_bucket_counts.get(bucket_name, {})
		if not catalog_bucket_row.is_empty():
			var catalog_entries: int = int(catalog_bucket_row.get("entries", -1))
			var catalog_ready_entries: int = int(catalog_bucket_row.get("ready_entries", -1))
			if catalog_entries != bucket_entries or catalog_ready_entries != bucket_ready_entries:
				_push_result(
					report,
					"global",
					"acceptance_bucket_counts:%s" % bucket_name,
					false,
					"catalog acceptance_bucket_counts mismatch with computed profile buckets"
				)

	report["profile_buckets"] = profile_buckets
	report["profile_mismatches"] = profile_mismatch_count
	report["visual_failures"] = visual_failures
	if profile_mismatch_count > max_profile_mismatches:
		_push_result(
			report,
			"global",
			"max_profile_mismatches_exceeded",
			false,
			"profile_mismatches %d exceeds max_profile_mismatches %d" % [profile_mismatch_count, max_profile_mismatches]
		)

	var trend_report: Dictionary = report.get("trend", {})
	var trend_regressions: int = int(trend_report.get("regressions", 0))
	if trend_regressions > max_trend_regressions:
		_push_result(
			report,
			"global",
			"max_trend_regressions_exceeded",
			false,
			"trend regressions %d exceeds max_trend_regressions %d" % [trend_regressions, max_trend_regressions]
		)

	var failures: int = int(report.get("blockers", 0))
	if visual_failures > max_visual_failures:
		_push_result(
			report,
			"global",
			"max_visual_failures_exceeded",
			false,
			"visual_failures %d exceeds max_visual_failures %d" % [visual_failures, max_visual_failures]
		)
	if failures > max_failures:
		_push_result(
			report,
			"global",
			"max_failures_exceeded",
			false,
			"blockers %d exceeds max_failures %d" % [failures, max_failures]
		)

	return report


func _run_visual_requirement(row: Dictionary) -> Dictionary:
	var scene_path: String = str(row.get("scene", ""))
	if scene_path.is_empty() or not scene_path.begins_with("res://"):
		return _build_visual_result(false, "invalid scene path")
	if not ResourceLoader.exists(scene_path):
		return _build_visual_result(false, "scene does not exist")
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return _build_visual_result(false, "scene load failed")
	var instance: Node = packed_scene.instantiate()
	if instance == null:
		return _build_visual_result(false, "scene instantiate failed")

	var result: Dictionary = _evaluate_visual_requirement_on_instance(instance, row)
	instance.free()
	return result


func _evaluate_visual_requirement_on_instance(instance: Node, row: Dictionary) -> Dictionary:
	var node_path: String = str(row.get("node_path", ""))
	var node_type: String = str(row.get("node_type", ""))
	var rule: String = str(row.get("rule", "exists"))
	var property_name: String = str(row.get("property", ""))

	if node_path.is_empty() or node_type.is_empty():
		return _build_visual_result(false, "visual requirement missing node_path or node_type")

	var target: Node = instance.get_node_or_null(NodePath(node_path))
	if target == null:
		return _build_visual_result(false, "node not found: %s" % node_path)
	if not target.is_class(node_type):
		return _build_visual_result(false, "node type mismatch: expected %s" % node_type)

	if rule == "exists":
		return _build_visual_result(true, "visual node exists")
	if property_name.is_empty():
		return _build_visual_result(false, "property is required for rule %s" % rule)

	var value: Variant = target.get(property_name)
	match rule:
		"non_null":
			if value != null:
				return _build_visual_result(true, "%s is non-null" % property_name)
			return _build_visual_result(false, "%s must be non-null" % property_name)
		"non_empty_string":
			if value is String and not str(value).strip_edges().is_empty():
				return _build_visual_result(true, "%s has non-empty text" % property_name)
			return _build_visual_result(false, "%s must be non-empty string" % property_name)
		"array_non_empty":
			if value is Array and (value as Array).size() > 0:
				return _build_visual_result(true, "%s has non-empty array" % property_name)
			if value is PackedVector2Array and (value as PackedVector2Array).size() > 0:
				return _build_visual_result(true, "%s has non-empty PackedVector2Array" % property_name)
			if value is PackedVector3Array and (value as PackedVector3Array).size() > 0:
				return _build_visual_result(true, "%s has non-empty PackedVector3Array" % property_name)
			return _build_visual_result(false, "%s must be non-empty array-like" % property_name)
		"float_gt_zero":
			if value is float or value is int:
				if float(value) > 0.0:
					return _build_visual_result(true, "%s > 0" % property_name)
			return _build_visual_result(false, "%s must be > 0" % property_name)
		"bool_true":
			if value is bool and bool(value):
				return _build_visual_result(true, "%s is true" % property_name)
			return _build_visual_result(false, "%s must be true" % property_name)
		_:
			return _build_visual_result(false, "unknown visual rule: %s" % rule)


func _build_visual_result(passed: bool, message: String) -> Dictionary:
	return {
		"passed": passed,
		"message": message,
	}


func _sanitize_scene_list(raw: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (raw is Array):
		return result
	var seen: Dictionary = {}
	for row in raw:
		if row is String:
			var scene_path: String = str(row)
			if scene_path.begins_with("res://") and not seen.has(scene_path):
				seen[scene_path] = true
				result.append(scene_path)
	return result


func _smoke_scene(scene_path: String) -> bool:
	if not ResourceLoader.exists(scene_path):
		return false
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return false
	var instance: Node = packed_scene.instantiate()
	if instance == null:
		return false
	instance.free()
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _rotate_previous_report() -> void:
	if not FileAccess.file_exists(REPORT_JSON_PATH):
		return
	var latest: String = FileAccess.get_file_as_string(REPORT_JSON_PATH)
	if latest.is_empty():
		return
	var prev_file: FileAccess = FileAccess.open(PREV_REPORT_JSON_PATH, FileAccess.WRITE)
	if prev_file:
		prev_file.store_string(latest)


func _push_warning(report: Dictionary, category: String, item_id: String, message: String) -> void:
	_push_result(report, category, item_id, false, message, "warning")


func _push_result(
	report: Dictionary,
	category: String,
	item_id: String,
	passed: bool,
	message: String,
	severity: String = "blocker"
) -> void:
	var items: Array = report.get("items", [])
	items.append(
		{
			"category": category,
			"id": item_id,
			"passed": passed,
			"severity": severity,
			"message": message,
		}
	)
	report["items"] = items
	report["checked"] = int(report.get("checked", 0)) + 1
	if passed:
		report["passed"] = int(report.get("passed", 0)) + 1
	elif severity == "warning":
		report["warnings"] = int(report.get("warnings", 0)) + 1
	else:
		report["blockers"] = int(report.get("blockers", 0)) + 1


func _write_reports(report: Dictionary) -> void:
	var json_text: String = JSON.stringify(report, "\t")
	var json_file: FileAccess = FileAccess.open(REPORT_JSON_PATH, FileAccess.WRITE)
	if json_file:
		json_file.store_string(json_text)

	var lines: Array[String] = []
	lines.append("# Resource Acceptance Report")
	lines.append("")
	lines.append("- channel: %s" % str(report.get("channel", "unknown")))
	lines.append("- checked: %d" % int(report.get("checked", 0)))
	lines.append("- passed: %d" % int(report.get("passed", 0)))
	lines.append("- blockers: %d" % int(report.get("blockers", 0)))
	lines.append("- warnings: %d" % int(report.get("warnings", 0)))
	lines.append("- profile_mismatches: %d" % int(report.get("profile_mismatches", 0)))
	lines.append("- visual_failures: %d" % int(report.get("visual_failures", 0)))
	lines.append("")
	lines.append("## Profile Layers")
	var profile_layers: Dictionary = report.get("profile_layers", {})
	for layer_name in profile_layers.keys():
		var layer_row: Dictionary = profile_layers.get(layer_name, {})
		lines.append(
			"- %s: entries=%d, ready_entries=%d" % [
				str(layer_name),
				int(layer_row.get("entries", 0)),
				int(layer_row.get("ready_entries", 0)),
			]
		)
	lines.append("")
	lines.append("## Profile Buckets")
	var profile_buckets: Dictionary = report.get("profile_buckets", {})
	for bucket_name in profile_buckets.keys():
		var bucket_row: Dictionary = profile_buckets.get(bucket_name, {})
		lines.append(
			"- %s: entries=%d, ready_entries=%d, ready_ratio=%.3f" % [
				str(bucket_name),
				int(bucket_row.get("entries", 0)),
				int(bucket_row.get("ready_entries", 0)),
				float(bucket_row.get("ready_ratio", 0.0)),
			]
		)
	lines.append("")
	lines.append("## Category Ready")
	var category_ready: Dictionary = report.get("category_ready", {})
	for category in category_ready.keys():
		var row: Dictionary = category_ready.get(category, {})
		lines.append(
			"- %s: ready=%d / total=%d (ratio=%.2f)" % [
				str(category),
				int(row.get("ready_count", 0)),
				int(row.get("total_entries", 0)),
				float(row.get("ready_ratio", 0.0)),
			]
		)
	lines.append("")
	lines.append("## Scene Smokes")
	var scene_smokes: Dictionary = report.get("scene_smokes", {})
	for category in scene_smokes.keys():
		var row: Dictionary = scene_smokes.get(category, {})
		lines.append(
			"- %s: passed=%d / required=%d (configured=%d)" % [
				str(category),
				int(row.get("passed", 0)),
				int(row.get("required", 0)),
				int(row.get("configured", 0)),
			]
		)
	lines.append("")
	lines.append("## Visual Checks")
	var visual_checks: Dictionary = report.get("visual_checks", {})
	for category in visual_checks.keys():
		var row: Dictionary = visual_checks.get(category, {})
		lines.append(
			"- %s: passed=%d / required=%d (configured=%d)" % [
				str(category),
				int(row.get("passed", 0)),
				int(row.get("required", 0)),
				int(row.get("configured", 0)),
			]
		)
	lines.append("")
	lines.append("## Trend")
	var trend: Dictionary = report.get("trend", {})
	lines.append("- regressions: %d" % int(trend.get("regressions", 0)))
	var category_ratio_drops: Dictionary = trend.get("category_ratio_drops", {})
	for category in category_ratio_drops.keys():
		lines.append("- category_drop %s: %.3f" % [str(category), float(category_ratio_drops.get(category, 0.0))])
	var bucket_ratio_drops: Dictionary = trend.get("bucket_ratio_drops", {})
	for bucket in bucket_ratio_drops.keys():
		lines.append("- bucket_drop %s: %.3f" % [str(bucket), float(bucket_ratio_drops.get(bucket, 0.0))])
	lines.append("")
	lines.append("## Items")
	var items: Array = report.get("items", [])
	for item in items:
		if item is Dictionary:
			var row: Dictionary = item
			var status: String = "PASS"
			if not bool(row.get("passed", false)):
				status = "WARN" if str(row.get("severity", "blocker")) == "warning" else "FAIL"
			lines.append("- [%s] %s / %s -> %s" % [status, str(row.get("category", "")), str(row.get("id", "")), str(row.get("message", ""))])

	var markdown_file: FileAccess = FileAccess.open(REPORT_MD_PATH, FileAccess.WRITE)
	if markdown_file:
		markdown_file.store_string("\n".join(lines) + "\n")
