extends SceneTree

const GATE_CONFIG_PATH: String = "res://data/balance/release_gate_targets.json"
const BASELINE_JSON_PATH: String = "user://quality_baseline_latest.json"
const BASELINE_MD_PATH: String = "user://quality_baseline_latest.md"
const CI_WORKFLOW_PATH: String = "res://.github/workflows/ci.yml"
const OUTPUT_JSON_PATH: String = "user://release_gate_latest.json"
const OUTPUT_MD_PATH: String = "user://release_gate_latest.md"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gate_cfg: Dictionary = _load_json_dict(GATE_CONFIG_PATH)
	if gate_cfg.is_empty():
		push_error("release gate config load failed: %s" % GATE_CONFIG_PATH)
		quit(1)
		return

	var report: Dictionary = _evaluate_gate(gate_cfg)
	var save_ok: bool = _save_report(report)
	_print_summary(report)

	var blockers: Array[String] = []
	var blockers_var: Variant = report.get("blockers", [])
	if blockers_var is Array:
		for item: Variant in blockers_var:
			blockers.append(str(item))

	quit(0 if save_ok and blockers.is_empty() else 1)


func _evaluate_gate(cfg: Dictionary) -> Dictionary:
	var blockers: Array[String] = []
	var warnings: Array[String] = []
	var baseline_json_exists: bool = FileAccess.file_exists(BASELINE_JSON_PATH)
	var baseline_md_exists: bool = FileAccess.file_exists(BASELINE_MD_PATH)

	var publish_blockers_var: Variant = cfg.get("publish_blockers", {})
	var publish_blockers: Dictionary = publish_blockers_var if publish_blockers_var is Dictionary else {}

	if bool(publish_blockers.get("require_baseline_json", true)) and not baseline_json_exists:
		blockers.append("Baseline JSON missing: %s" % BASELINE_JSON_PATH)
	if bool(publish_blockers.get("require_baseline_markdown", true)) and not baseline_md_exists:
		blockers.append("Baseline markdown missing: %s" % BASELINE_MD_PATH)

	var baseline: Dictionary = {}
	if baseline_json_exists:
		baseline = _load_json_dict(BASELINE_JSON_PATH)
		if baseline.is_empty():
			blockers.append("Baseline JSON parse failed or empty")

	var alerts_var: Variant = baseline.get("alerts", {})
	var alerts: Dictionary = alerts_var if alerts_var is Dictionary else {}
	var total_alerts: int = int(alerts.get("total", 0))
	var critical_alerts: int = int(alerts.get("critical", 0))
	var warning_alerts: int = int(alerts.get("warning", 0))

	var limits_var: Variant = cfg.get("baseline_alert_limits", {})
	var limits: Dictionary = limits_var if limits_var is Dictionary else {}
	var max_total: int = int(limits.get("max_total", 0))
	var max_critical: int = int(limits.get("max_critical", 0))
	var max_warning: int = int(limits.get("max_warning", 0))

	if total_alerts > max_total:
		blockers.append("alerts.total exceeds gate: %d > %d" % [total_alerts, max_total])
	if critical_alerts > max_critical:
		blockers.append("alerts.critical exceeds gate: %d > %d" % [critical_alerts, max_critical])
	if warning_alerts > max_warning:
		blockers.append("alerts.warning exceeds gate: %d > %d" % [warning_alerts, max_warning])

	if bool(publish_blockers.get("require_zero_critical_alerts", true)) and critical_alerts > 0:
		blockers.append("critical alerts must be zero")
	if bool(publish_blockers.get("require_zero_warning_alerts", true)) and warning_alerts > 0:
		blockers.append("warning alerts must be zero")

	var scenario_ids: Dictionary = {}
	var scenarios_var: Variant = baseline.get("scenarios", [])
	if scenarios_var is Array:
		for row_var: Variant in scenarios_var:
			if not (row_var is Dictionary):
				continue
			var row: Dictionary = row_var
			var scenario_id: String = str(row.get("id", "")).strip_edges()
			if not scenario_id.is_empty():
				scenario_ids[scenario_id] = true

	var scenario_req_var: Variant = cfg.get("scenario_requirements", {})
	if scenario_req_var is Dictionary:
		var must_include_var: Variant = (scenario_req_var as Dictionary).get("must_include", [])
		if must_include_var is Array:
			for required_var: Variant in must_include_var:
				var required_id: String = str(required_var).strip_edges()
				if required_id.is_empty():
					continue
				if not scenario_ids.has(required_id):
					blockers.append("missing baseline scenario: %s" % required_id)

	var compatibility_req_var: Variant = cfg.get("compatibility_requirements", {})
	if compatibility_req_var is Dictionary:
		var compatibility_req: Dictionary = compatibility_req_var
		var snapshot_var: Variant = baseline.get("compatibility_snapshot", {})
		var snapshot: Dictionary = snapshot_var if snapshot_var is Dictionary else {}
		var action_status_var: Variant = snapshot.get("required_actions", {})
		var action_status: Dictionary = action_status_var if action_status_var is Dictionary else {}

		var required_actions_var: Variant = compatibility_req.get("required_actions_with_events", [])
		if required_actions_var is Array:
			for action_var: Variant in required_actions_var:
				var action_name: String = str(action_var).strip_edges()
				if action_name.is_empty():
					continue
				var status_var: Variant = action_status.get(action_name, {})
				if not (status_var is Dictionary):
					blockers.append("compat action missing in snapshot: %s" % action_name)
					continue
				var status: Dictionary = status_var
				if not bool(status.get("exists", false)):
					blockers.append("compat action missing in InputMap: %s" % action_name)
				if int(status.get("events", 0)) < 1:
					blockers.append("compat action has no bound events: %s" % action_name)

		var workflow_text: String = _read_text(CI_WORKFLOW_PATH)
		if workflow_text.is_empty():
			blockers.append("cannot read CI workflow for platform marker checks")
		else:
			var required_markers_var: Variant = compatibility_req.get("required_platform_markers", [])
			if required_markers_var is Array:
				for marker_var: Variant in required_markers_var:
					var marker: String = str(marker_var).strip_edges()
					if marker.is_empty():
						continue
					if workflow_text.find(marker) < 0:
						blockers.append("CI workflow missing platform marker: %s" % marker)

	if baseline.is_empty() and baseline_json_exists:
		warnings.append("Baseline JSON exists but report content is empty")

	return {
		"generated_at": Time.get_datetime_string_from_system(true),
		"channel": str(cfg.get("channel", "unknown")),
		"baseline": {
			"json_path": ProjectSettings.globalize_path(BASELINE_JSON_PATH),
			"markdown_path": ProjectSettings.globalize_path(BASELINE_MD_PATH),
			"json_exists": baseline_json_exists,
			"markdown_exists": baseline_md_exists
		},
		"alerts_summary": {
			"total": total_alerts,
			"critical": critical_alerts,
			"warning": warning_alerts
		},
		"blockers": blockers,
		"warnings": warnings,
	}


func _save_report(report: Dictionary) -> bool:
	var json_file: FileAccess = FileAccess.open(OUTPUT_JSON_PATH, FileAccess.WRITE)
	if json_file == null:
		push_error("Cannot write release gate json: %s" % OUTPUT_JSON_PATH)
		return false
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()

	var md_lines: Array[String] = []
	md_lines.append("# Release Gate Rehearsal")
	md_lines.append("")
	md_lines.append("- generated_at: %s" % str(report.get("generated_at", "")))
	md_lines.append("- channel: %s" % str(report.get("channel", "unknown")))

	var alerts_summary_var: Variant = report.get("alerts_summary", {})
	if alerts_summary_var is Dictionary:
		var alerts_summary: Dictionary = alerts_summary_var
		md_lines.append("- alerts.total: %d" % int(alerts_summary.get("total", 0)))
		md_lines.append("- alerts.critical: %d" % int(alerts_summary.get("critical", 0)))
		md_lines.append("- alerts.warning: %d" % int(alerts_summary.get("warning", 0)))

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
		push_error("Cannot write release gate markdown: %s" % OUTPUT_MD_PATH)
		return false
	md_file.store_string("\n".join(md_lines) + "\n")
	md_file.close()
	return true


func _print_summary(report: Dictionary) -> void:
	print("Release gate rehearsal generated:")
	print("  json: %s" % ProjectSettings.globalize_path(OUTPUT_JSON_PATH))
	print("  md:   %s" % ProjectSettings.globalize_path(OUTPUT_MD_PATH))
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
