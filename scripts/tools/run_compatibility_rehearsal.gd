extends SceneTree

const CONFIG_PATH: String = "res://data/balance/compatibility_rehearsal_targets.json"
const RELEASE_GATE_JSON_PATH: String = "user://release_gate_latest.json"
const RELEASE_GATE_MD_PATH: String = "user://release_gate_latest.md"
const CI_WORKFLOW_PATH: String = "res://.github/workflows/ci.yml"
const OUTPUT_JSON_PATH: String = "user://compatibility_rehearsal_latest.json"
const OUTPUT_MD_PATH: String = "user://compatibility_rehearsal_latest.md"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cfg: Dictionary = _load_json_dict(CONFIG_PATH)
	if cfg.is_empty():
		push_error("compatibility rehearsal config load failed: %s" % CONFIG_PATH)
		quit(1)
		return

	var report: Dictionary = await _evaluate_rehearsal(cfg)
	var save_ok: bool = _save_report(report)
	_print_summary(report)

	var blockers: Array[String] = []
	var blockers_var: Variant = report.get("blockers", [])
	if blockers_var is Array:
		for row: Variant in blockers_var:
			blockers.append(str(row))

	quit(0 if save_ok and blockers.is_empty() else 1)


func _evaluate_rehearsal(cfg: Dictionary) -> Dictionary:
	var blockers: Array[String] = []
	var warnings: Array[String] = []
	var workflow_text: String = _read_text(CI_WORKFLOW_PATH)

	var publish_blockers_var: Variant = cfg.get("publish_blockers", {})
	var publish_blockers: Dictionary = publish_blockers_var if publish_blockers_var is Dictionary else {}

	var release_json_exists: bool = FileAccess.file_exists(RELEASE_GATE_JSON_PATH)
	var release_md_exists: bool = FileAccess.file_exists(RELEASE_GATE_MD_PATH)
	if bool(publish_blockers.get("require_release_gate_json", true)) and not release_json_exists:
		blockers.append("Release gate JSON missing: %s" % RELEASE_GATE_JSON_PATH)
	if bool(publish_blockers.get("require_release_gate_markdown", true)) and not release_md_exists:
		blockers.append("Release gate markdown missing: %s" % RELEASE_GATE_MD_PATH)

	var release_gate: Dictionary = {}
	if release_json_exists:
		release_gate = _load_json_dict(RELEASE_GATE_JSON_PATH)
		if release_gate.is_empty():
			blockers.append("Release gate JSON parse failed or empty")

	var release_blockers_count: int = 0
	var release_warnings_count: int = 0
	if not release_gate.is_empty():
		var rg_blockers_var: Variant = release_gate.get("blockers", [])
		var rg_warnings_var: Variant = release_gate.get("warnings", [])
		release_blockers_count = rg_blockers_var.size() if rg_blockers_var is Array else 0
		release_warnings_count = rg_warnings_var.size() if rg_warnings_var is Array else 0
		if release_blockers_count > 0:
			blockers.append("Release gate report contains blockers: %d" % release_blockers_count)

	var required_actions: Array[String] = []
	var actions_var: Variant = cfg.get("required_actions", [])
	if actions_var is Array:
		for action_var: Variant in actions_var:
			required_actions.append(str(action_var).strip_edges())

	var profile_reports: Array[Dictionary] = []
	var profile_failures: int = 0
	var missing_actions_total: int = 0

	var profiles_var: Variant = cfg.get("profiles", [])
	if profiles_var is Array:
		for profile_var: Variant in profiles_var:
			if not (profile_var is Dictionary):
				continue
			var profile_report: Dictionary = await _evaluate_profile(profile_var as Dictionary, workflow_text, required_actions)
			profile_reports.append(profile_report)
			if not bool(profile_report.get("pass", false)):
				profile_failures += 1
			missing_actions_total += int(profile_report.get("missing_actions_count", 0))

	var total_profiles: int = profile_reports.size()
	var passed_profiles: int = total_profiles - profile_failures
	var pass_rate: float = float(passed_profiles) / float(maxi(1, total_profiles))

	var thresholds_var: Variant = cfg.get("thresholds", {})
	var thresholds: Dictionary = thresholds_var if thresholds_var is Dictionary else {}
	var min_pass_rate: float = float(thresholds.get("min_profile_pass_rate", 1.0))
	var max_profile_failures: int = int(thresholds.get("max_profile_failures", 0))
	var max_missing_actions: int = int(thresholds.get("max_missing_actions", 0))

	if pass_rate < min_pass_rate:
		blockers.append("profile pass rate below threshold: %.3f < %.3f" % [pass_rate, min_pass_rate])
	if profile_failures > max_profile_failures:
		blockers.append("profile failures exceed threshold: %d > %d" % [profile_failures, max_profile_failures])
	if missing_actions_total > max_missing_actions:
		blockers.append("missing action bindings exceed threshold: %d > %d" % [missing_actions_total, max_missing_actions])

	if bool(publish_blockers.get("require_zero_profile_failures", true)) and profile_failures > 0:
		blockers.append("profile failures must be zero")

	if workflow_text.is_empty():
		warnings.append("CI workflow text is empty; platform marker checks may be unreliable")

	return {
		"generated_at": Time.get_datetime_string_from_system(true),
		"channel": str(cfg.get("channel", "unknown")),
		"platform": OS.get_name(),
		"release_gate": {
			"json_path": ProjectSettings.globalize_path(RELEASE_GATE_JSON_PATH),
			"markdown_path": ProjectSettings.globalize_path(RELEASE_GATE_MD_PATH),
			"json_exists": release_json_exists,
			"markdown_exists": release_md_exists,
			"report_blockers": release_blockers_count,
			"report_warnings": release_warnings_count,
		},
		"summary": {
			"total_profiles": total_profiles,
			"passed_profiles": passed_profiles,
			"failed_profiles": profile_failures,
			"pass_rate": pass_rate,
			"missing_actions_total": missing_actions_total,
		},
		"thresholds": thresholds,
		"profiles": profile_reports,
		"blockers": blockers,
		"warnings": warnings,
	}


func _evaluate_profile(profile: Dictionary, workflow_text: String, required_actions: Array[String]) -> Dictionary:
	var profile_id: String = str(profile.get("id", "unknown"))
	var platform_marker: String = str(profile.get("platform_marker", ""))
	var resolution_text: String = str(profile.get("resolution", ""))
	var input_mode: String = str(profile.get("input_mode", ""))
	var renderer: String = str(profile.get("renderer", ""))
	var resolution: Vector2i = _parse_resolution(resolution_text)

	var marker_ok: bool = not platform_marker.is_empty() and workflow_text.find(platform_marker) >= 0
	var action_checks: Dictionary = {}
	var missing_actions: Array[String] = []
	for action_name: String in required_actions:
		if action_name.is_empty():
			continue
		var exists: bool = InputMap.has_action(action_name)
		var events: int = InputMap.action_get_events(action_name).size() if exists else 0
		action_checks[action_name] = {
			"exists": exists,
			"events": events,
		}
		if not exists or events < 1:
			missing_actions.append(action_name)

	var scene_checks: Array[Dictionary] = []
	var scene_failures: Array[String] = []
	var scenes_var: Variant = profile.get("required_scenes", [])
	if scenes_var is Array:
		for scene_var: Variant in scenes_var:
			var scene_path: String = str(scene_var).strip_edges()
			if scene_path.is_empty():
				continue
			var scene_check: Dictionary = await _run_scene_smoke(scene_path, resolution)
			scene_checks.append(scene_check)
			if not bool(scene_check.get("pass", false)):
				scene_failures.append(scene_path)

	var profile_pass: bool = marker_ok and scene_failures.is_empty() and missing_actions.is_empty()
	if resolution.x <= 0 or resolution.y <= 0:
		profile_pass = false
		scene_failures.append("invalid_resolution")

	return {
		"id": profile_id,
		"platform_marker": platform_marker,
		"platform_marker_found": marker_ok,
		"resolution": resolution_text,
		"input_mode": input_mode,
		"renderer": renderer,
		"scene_checks": scene_checks,
		"scene_failures": scene_failures,
		"action_checks": action_checks,
		"missing_actions": missing_actions,
		"missing_actions_count": missing_actions.size(),
		"pass": profile_pass,
	}


func _run_scene_smoke(scene_path: String, resolution: Vector2i) -> Dictionary:
	if resolution.x <= 0 or resolution.y <= 0:
		return {
			"scene": scene_path,
			"pass": false,
			"error": "invalid resolution"
		}

	var packed: PackedScene = load(scene_path)
	if packed == null:
		return {
			"scene": scene_path,
			"pass": false,
			"error": "scene load failed"
		}

	var node: Node = packed.instantiate()
	if node == null:
		return {
			"scene": scene_path,
			"pass": false,
			"error": "scene instantiate failed"
		}

	var original_size: Vector2i = root.size
	root.size = resolution
	root.add_child(node)
	await process_frame
	await process_frame

	node.queue_free()
	await process_frame
	root.size = original_size

	return {
		"scene": scene_path,
		"pass": true,
		"resolution": "%dx%d" % [resolution.x, resolution.y]
	}


func _parse_resolution(text: String) -> Vector2i:
	var normalized: String = text.to_lower().strip_edges()
	var parts: PackedStringArray = normalized.split("x", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	if not parts[0].strip_edges().is_valid_int() or not parts[1].strip_edges().is_valid_int():
		return Vector2i.ZERO
	var width: int = int(parts[0])
	var height: int = int(parts[1])
	if width <= 0 or height <= 0:
		return Vector2i.ZERO
	return Vector2i(width, height)


func _save_report(report: Dictionary) -> bool:
	var json_file: FileAccess = FileAccess.open(OUTPUT_JSON_PATH, FileAccess.WRITE)
	if json_file == null:
		push_error("Cannot write compatibility rehearsal json: %s" % OUTPUT_JSON_PATH)
		return false
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()

	var md_lines: Array[String] = []
	md_lines.append("# Compatibility Rehearsal")
	md_lines.append("")
	md_lines.append("- generated_at: %s" % str(report.get("generated_at", "")))
	md_lines.append("- channel: %s" % str(report.get("channel", "unknown")))
	md_lines.append("- platform: %s" % str(report.get("platform", "")))

	var summary_var: Variant = report.get("summary", {})
	if summary_var is Dictionary:
		var summary: Dictionary = summary_var
		md_lines.append("- profiles.total: %d" % int(summary.get("total_profiles", 0)))
		md_lines.append("- profiles.passed: %d" % int(summary.get("passed_profiles", 0)))
		md_lines.append("- profiles.failed: %d" % int(summary.get("failed_profiles", 0)))
		md_lines.append("- profiles.pass_rate: %.3f" % float(summary.get("pass_rate", 0.0)))
		md_lines.append("- missing_actions_total: %d" % int(summary.get("missing_actions_total", 0)))

	md_lines.append("")
	md_lines.append("## Profile Results")
	md_lines.append("")
	md_lines.append("| profile | marker | marker_found | resolution | pass | scene_failures | missing_actions |")
	md_lines.append("|---|---|---:|---|---:|---:|---:|")

	var profiles_var: Variant = report.get("profiles", [])
	if profiles_var is Array:
		for profile_var: Variant in profiles_var:
			if not (profile_var is Dictionary):
				continue
			var profile: Dictionary = profile_var
			var scene_failures_var: Variant = profile.get("scene_failures", [])
			var missing_actions_var: Variant = profile.get("missing_actions", [])
			var scene_failures_count: int = scene_failures_var.size() if scene_failures_var is Array else 0
			var missing_actions_count: int = missing_actions_var.size() if missing_actions_var is Array else 0
			md_lines.append("| %s | %s | %s | %s | %s | %d | %d |" % [
				str(profile.get("id", "unknown")),
				str(profile.get("platform_marker", "")),
				str(profile.get("platform_marker_found", false)),
				str(profile.get("resolution", "")),
				str(profile.get("pass", false)),
				scene_failures_count,
				missing_actions_count,
			])

	md_lines.append("")
	md_lines.append("## Blockers")
	md_lines.append("")
	var blockers_var: Variant = report.get("blockers", [])
	if blockers_var is Array and not (blockers_var as Array).is_empty():
		for blocker_var: Variant in blockers_var:
			md_lines.append("- %s" % str(blocker_var))
	else:
		md_lines.append("- none")

	md_lines.append("")
	md_lines.append("## Warnings")
	md_lines.append("")
	var warnings_var: Variant = report.get("warnings", [])
	if warnings_var is Array and not (warnings_var as Array).is_empty():
		for warning_var: Variant in warnings_var:
			md_lines.append("- %s" % str(warning_var))
	else:
		md_lines.append("- none")

	var md_file: FileAccess = FileAccess.open(OUTPUT_MD_PATH, FileAccess.WRITE)
	if md_file == null:
		push_error("Cannot write compatibility rehearsal markdown: %s" % OUTPUT_MD_PATH)
		return false
	md_file.store_string("\n".join(md_lines) + "\n")
	md_file.close()
	return true


func _print_summary(report: Dictionary) -> void:
	print("Compatibility rehearsal generated:")
	print("  json: %s" % ProjectSettings.globalize_path(OUTPUT_JSON_PATH))
	print("  md:   %s" % ProjectSettings.globalize_path(OUTPUT_MD_PATH))
	var summary_var: Variant = report.get("summary", {})
	if summary_var is Dictionary:
		var summary: Dictionary = summary_var
		print("  profiles: %d total / %d passed / %d failed" % [
			int(summary.get("total_profiles", 0)),
			int(summary.get("passed_profiles", 0)),
			int(summary.get("failed_profiles", 0)),
		])
	var blockers_var: Variant = report.get("blockers", [])
	var blockers_count: int = blockers_var.size() if blockers_var is Array else 0
	var warnings_var: Variant = report.get("warnings", [])
	var warnings_count: int = warnings_var.size() if warnings_var is Array else 0
	print("  blockers: %d" % blockers_count)
	print("  warnings: %d" % warnings_count)


func _load_json_dict(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _read_text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
