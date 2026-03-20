extends SceneTree

const TARGETS_PATH := "res://data/balance/visual_snapshot_targets.json"
const PREV_REPORT_JSON_PATH := "user://visual_snapshot_previous.json"
const REPORT_JSON_PATH := "user://visual_snapshot_latest.json"
const REPORT_MD_PATH := "user://visual_snapshot_latest.md"
const SNAPSHOT_DIR := "user://visual_snapshots/latest"


func _initialize() -> void:
	_rotate_previous_report()
	var report: Dictionary = await _run_regression()
	_write_reports(report)
	var blockers: int = int(report.get("blockers", 0))
	var warnings: int = int(report.get("warnings", 0))
	print("Visual snapshot regression complete -> blockers: %d, warnings: %d" % [blockers, warnings])
	if blockers > 0:
		quit(1)
	else:
		quit(0)


func _run_regression() -> Dictionary:
	var targets: Dictionary = _read_json(TARGETS_PATH)
	var previous_report: Dictionary = _read_json(PREV_REPORT_JSON_PATH)
	var precision: Dictionary = targets.get("precision", {})
	var sample_rounds: int = maxi(1, int(precision.get("sample_rounds", 1)))
	var max_opaque_ratio_stddev: float = maxf(0.0, float(precision.get("max_opaque_ratio_stddev", 1.0)))
	var max_luma_stddev: float = maxf(0.0, float(precision.get("max_luma_stddev", 1.0)))
	var max_unique_color_stddev_ratio: float = maxf(0.0, float(precision.get("max_unique_color_stddev_ratio", 1.0)))
	var baseline_alignment: Dictionary = targets.get("baseline_alignment", {})
	var required_snapshot_ids: Array[String] = _sanitize_string_array(baseline_alignment.get("required_snapshot_ids", []))
	var allowed_capture_modes_map: Dictionary = _sanitize_allowed_capture_modes(baseline_alignment.get("allowed_capture_modes", {}))
	var diff_whitelist: Dictionary = _sanitize_diff_whitelist(targets.get("diff_whitelist", {}))
	var base_thresholds: Dictionary = targets.get("thresholds", {})
	var base_whitelist_policy: Dictionary = targets.get("whitelist_policy", {})
	var base_backend_attribution_cfg: Dictionary = targets.get("backend_attribution", {})
	var base_whitelist_convergence_cfg: Dictionary = targets.get("whitelist_convergence", {})
	var base_exception_lifecycle_cfg: Dictionary = targets.get("exception_lifecycle", {})
	var base_report_layers: Dictionary = _sanitize_report_layers(targets.get("report_layers", {}), targets.get("snapshots", {}))
	var base_cross_version_baseline: Dictionary = _sanitize_cross_version_baseline(targets.get("cross_version_baseline", {}), targets.get("snapshots", {}))
	var release_gate_templates: Dictionary = _sanitize_release_gate_templates(
		targets.get("release_gate_templates", {}),
		targets.get("strategy_orchestration", {})
	)
	var backend_matrix_governance: Dictionary = _sanitize_backend_matrix_governance(targets.get("backend_matrix_governance", {}))
	var base_approval_workflow: Dictionary = _sanitize_approval_workflow(targets.get("approval_workflow", {}))
	var base_approval_audit_trail: Dictionary = _sanitize_approval_audit_trail(targets.get("approval_audit_trail", {}))
	var base_approval_history_archive: Dictionary = _sanitize_approval_history_archive(targets.get("approval_history_archive", {}))
	var approval_threshold_templates: Dictionary = _sanitize_approval_threshold_templates(
		targets.get("approval_threshold_templates", {}),
		release_gate_templates,
		backend_matrix_governance
	)
	var release_candidate_tracking: Dictionary = _sanitize_release_candidate_tracking(targets.get("release_candidate_tracking", {}))
	var strategy_state: Dictionary = _resolve_strategy_orchestration(
		targets.get("strategy_orchestration", {}),
		{
			"thresholds": base_thresholds,
			"whitelist_policy": base_whitelist_policy,
			"backend_attribution": base_backend_attribution_cfg,
			"whitelist_convergence": base_whitelist_convergence_cfg,
			"exception_lifecycle": base_exception_lifecycle_cfg,
			"report_layers": base_report_layers,
			"cross_version_baseline": base_cross_version_baseline,
		}
	)
	var strategy_name: String = str(strategy_state.get("name", "default"))
	var strategy_template: String = str(strategy_state.get("template", "base"))
	var strategy_errors: Array[String] = _sanitize_string_array(strategy_state.get("errors", []))
	var run_mode: String = OS.get_environment("VISUAL_SNAPSHOT_RUN_MODE").strip_edges()
	if run_mode.is_empty():
		run_mode = "rehearsal"
	var approval_template_state: Dictionary = _resolve_approval_threshold_template(
		approval_threshold_templates,
		run_mode,
		{
			"approval_workflow": base_approval_workflow,
			"approval_audit_trail": base_approval_audit_trail,
			"approval_history_archive": base_approval_history_archive,
		}
	)
	var approval_template_name: String = str(approval_template_state.get("template", "standard"))
	var approval_template_errors: Array[String] = _sanitize_string_array(approval_template_state.get("errors", []))
	var approval_workflow: Dictionary = approval_template_state.get("approval_workflow", base_approval_workflow)
	var approval_audit_trail: Dictionary = approval_template_state.get("approval_audit_trail", base_approval_audit_trail)
	var approval_history_archive: Dictionary = approval_template_state.get("approval_history_archive", base_approval_history_archive)
	var thresholds: Dictionary = strategy_state.get("thresholds", base_thresholds)
	var whitelist_policy: Dictionary = strategy_state.get("whitelist_policy", base_whitelist_policy)
	var backend_attribution_cfg: Dictionary = strategy_state.get("backend_attribution", base_backend_attribution_cfg)
	var whitelist_convergence_cfg: Dictionary = strategy_state.get("whitelist_convergence", base_whitelist_convergence_cfg)
	var exception_lifecycle_cfg: Dictionary = strategy_state.get("exception_lifecycle", base_exception_lifecycle_cfg)
	var report_layers: Dictionary = strategy_state.get("report_layers", base_report_layers)
	var cross_version_baseline: Dictionary = strategy_state.get("cross_version_baseline", base_cross_version_baseline)

	var whitelist_max_hits: int = maxi(0, int(whitelist_policy.get("max_hits", 0)))
	var whitelist_max_ratio: float = clampf(float(whitelist_policy.get("max_ratio", 0.0)), 0.0, 1.0)
	var required_backends: Array[String] = _sanitize_string_array(backend_attribution_cfg.get("required_backends", []))
	var max_unattributed_regressions: int = maxi(0, int(backend_attribution_cfg.get("max_unattributed_regressions", 0)))
	var max_backend_specific_regressions: int = maxi(0, int(backend_attribution_cfg.get("max_backend_specific_regressions", 0)))
	var stale_run_threshold: int = maxi(1, int(whitelist_convergence_cfg.get("stale_run_threshold", 3)))
	var tighten_margin_ratio: float = clampf(float(whitelist_convergence_cfg.get("tighten_margin_ratio", 0.25)), 0.0, 1.0)
	var max_suggestions: int = maxi(0, int(whitelist_convergence_cfg.get("max_suggestions", 5)))
	var expire_idle_runs: int = maxi(1, int(exception_lifecycle_cfg.get("expire_idle_runs", 2)))
	var auto_reclaim_hit_streak: int = maxi(1, int(exception_lifecycle_cfg.get("auto_reclaim_hit_streak", stale_run_threshold + 1)))
	var max_expired_entries: int = maxi(0, int(exception_lifecycle_cfg.get("max_expired_entries", 0)))
	var max_reclaim_candidates: int = maxi(0, int(exception_lifecycle_cfg.get("max_reclaim_candidates", max_suggestions)))

	var backend_tag: String = _detect_backend_tag()
	var backend_profiles: Dictionary = targets.get("backend_profiles", {})
	var backend_profile: Dictionary = _resolve_backend_profile(backend_profiles, backend_tag)
	var unique_colors_min_scale: float = clampf(float(backend_profile.get("unique_colors_min_scale", 1.0)), 0.5, 2.0)
	var luma_range_padding: float = clampf(float(backend_profile.get("luma_range_padding", 0.0)), 0.0, 0.3)
	var backend_max_opaque_drop: float = maxf(0.0, float(backend_profile.get("max_opaque_ratio_drop", 1.0)))
	var backend_max_unique_drop: float = maxf(0.0, float(backend_profile.get("max_unique_color_drop_ratio", 1.0)))
	var backend_max_luma_delta: float = maxf(0.0, float(backend_profile.get("max_luma_delta", 1.0)))

	var report: Dictionary = {
		"generated_at_unix": Time.get_unix_time_from_system(),
		"channel": str(targets.get("channel", "unknown")),
		"backend_tag": backend_tag,
		"strategy": {
			"name": strategy_name,
			"template": strategy_template,
			"errors": strategy_errors,
		},
		"precision": {
			"sample_rounds": sample_rounds,
			"max_opaque_ratio_stddev": max_opaque_ratio_stddev,
			"max_luma_stddev": max_luma_stddev,
			"max_unique_color_stddev_ratio": max_unique_color_stddev_ratio,
		},
		"blockers": 0,
		"warnings": 0,
		"checked": 0,
		"passed": 0,
		"snapshots": {},
		"trend": {
			"regressions": 0,
			"opaque_ratio_drops": {},
			"unique_color_drop_ratios": {},
			"luma_deltas": {},
		},
		"whitelist": {
			"hits": 0,
			"max_hits": whitelist_max_hits,
			"ratio": 0.0,
			"max_ratio": whitelist_max_ratio,
			"stale_run_threshold": stale_run_threshold,
			"tighten_margin_ratio": tighten_margin_ratio,
			"expire_idle_runs": expire_idle_runs,
			"auto_reclaim_hit_streak": auto_reclaim_hit_streak,
			"max_expired_entries": max_expired_entries,
			"max_reclaim_candidates": max_reclaim_candidates,
			"streaks": {},
			"lifecycle": {},
			"convergence_suggestions": [],
			"expired_entries": [],
			"reclaim_candidates": [],
			"items": [],
		},
		"backend_attribution": {
			"backend_tag": backend_tag,
			"required_backends": required_backends,
			"regressions": 0,
			"backend_specific_regressions": 0,
			"max_backend_specific_regressions": max_backend_specific_regressions,
			"unattributed_regressions": 0,
			"max_unattributed_regressions": max_unattributed_regressions,
			"items": [],
		},
		"cross_version": {
			"checked": 0,
			"violations": 0,
			"max_violations": int(cross_version_baseline.get("max_violations", 0)),
			"items": [],
		},
		"layers": {},
		"release_manifest": {
			"run_mode": run_mode,
			"strategy": strategy_name,
			"template": strategy_template,
			"required_strategies": release_gate_templates.get("required_strategies", []),
			"required_strategy_bindings": release_gate_templates.get("required_strategy_bindings", {}),
			"ci_mode_bindings": release_gate_templates.get("ci_mode_bindings", {}),
			"max_checklist_failures": int(release_gate_templates.get("max_checklist_failures", 0)),
			"checklist_failures": 0,
			"errors": [],
			"checklist_items": [],
		},
		"backend_matrix": {
			"backend_tag": backend_tag,
			"required_backend_matrix": backend_matrix_governance.get("required_backend_matrix", []),
			"declared_backend_matrix": _parse_csv_env(OS.get_environment("VISUAL_SNAPSHOT_BACKEND_MATRIX")),
			"required_run_modes": backend_matrix_governance.get("required_run_modes", []),
			"missing_backend_matrix": [],
			"missing_run_mode_bindings": [],
			"max_missing_backend_matrix": int(backend_matrix_governance.get("max_missing_backend_matrix", 0)),
			"max_missing_run_mode_bindings": int(backend_matrix_governance.get("max_missing_run_mode_bindings", 0)),
		},
		"approval": {
			"required_report_sections": approval_workflow.get("required_report_sections", []),
			"require_zero_blockers": bool(approval_workflow.get("require_zero_blockers", true)),
			"require_zero_warnings_for_strategies": approval_workflow.get("require_zero_warnings_for_strategies", []),
			"max_approval_failures": int(approval_workflow.get("max_approval_failures", 0)),
			"approval_failures": 0,
			"checklist_items": [],
		},
		"approval_audit": {
			"history_file": str(approval_audit_trail.get("history_file", "user://visual_snapshot_approval_history.json")),
			"max_entries": int(approval_audit_trail.get("max_entries", 80)),
			"required_run_modes": approval_audit_trail.get("required_run_modes", []),
			"required_backends": approval_audit_trail.get("required_backends", []),
			"require_unique_pipeline_id": bool(approval_audit_trail.get("require_unique_pipeline_id", true)),
			"max_missing_pipeline_id": int(approval_audit_trail.get("max_missing_pipeline_id", 0)),
			"max_history_trace_failures": int(approval_audit_trail.get("max_history_trace_failures", 0)),
			"pipeline_id": "",
			"history_entries": 0,
			"missing_run_modes": [],
			"missing_backends": [],
			"duplicate_pipeline_ids": [],
			"trace_failures": 0,
			"missing_pipeline_id_count": 0,
			"items": [],
		},
		"approval_archive": {
			"archive_file": str(approval_history_archive.get("archive_file", "user://visual_snapshot_approval_archive.json")),
			"max_entries": int(approval_history_archive.get("max_entries", 240)),
			"aggregation_window": int(approval_history_archive.get("aggregation_window", 80)),
			"required_backends": approval_history_archive.get("required_backends", []),
			"required_run_modes": approval_history_archive.get("required_run_modes", []),
			"max_missing_archive_backends": int(approval_history_archive.get("max_missing_archive_backends", 0)),
			"max_missing_archive_run_modes": int(approval_history_archive.get("max_missing_archive_run_modes", 0)),
			"max_backend_warning_delta": int(approval_history_archive.get("max_backend_warning_delta", 0)),
			"max_backend_blocker_delta": int(approval_history_archive.get("max_backend_blocker_delta", 0)),
			"max_archive_trace_failures": int(approval_history_archive.get("max_archive_trace_failures", 0)),
			"history_entries": 0,
			"window_entries": 0,
			"missing_backends": [],
			"missing_run_modes": [],
			"backend_warning_delta": 0,
			"backend_blocker_delta": 0,
			"trace_failures": 0,
			"items": [],
		},
		"approval_template": {
			"run_mode": run_mode,
			"template": approval_template_name,
			"errors": approval_template_errors,
		},
		"release_candidate_tracking": {
			"history_file": str(release_candidate_tracking.get("history_file", "user://visual_snapshot_approval_archive.json")),
			"window": int(release_candidate_tracking.get("window", 40)),
			"required_run_modes": release_candidate_tracking.get("required_run_modes", []),
			"required_strategies": release_candidate_tracking.get("required_strategies", []),
			"min_runs": int(release_candidate_tracking.get("min_runs", 1)),
			"max_avg_warnings": float(release_candidate_tracking.get("max_avg_warnings", 1.0)),
			"max_total_blockers": int(release_candidate_tracking.get("max_total_blockers", 0)),
			"max_tracking_failures": int(release_candidate_tracking.get("max_tracking_failures", 0)),
			"matching_runs": 0,
			"avg_warnings": 0.0,
			"total_blockers": 0,
			"tracking_failures": 0,
			"items": [],
		},
		"items": [],
	}

	var snapshots: Dictionary = targets.get("snapshots", {})
	if snapshots.is_empty():
		_push_result(report, "global", "missing_snapshots", false, "visual_snapshot_targets.json snapshots is empty")
		return report

	for strategy_error in strategy_errors:
		_push_result(report, "global", "strategy_orchestration_invalid", false, strategy_error)
	for approval_error in approval_template_errors:
		_push_result(report, "global", "approval_threshold_template_invalid", false, approval_error)

	for required_id in required_snapshot_ids:
		if not snapshots.has(required_id):
			_push_result(report, "global", "required_snapshot_missing", false, "required snapshot '%s' not found in targets" % required_id)

	var min_snapshots: int = int(thresholds.get("min_snapshots", 1))
	var max_failures: int = int(thresholds.get("max_failures", 0))
	var max_trend_regressions: int = int(thresholds.get("max_trend_regressions", 0))
	var max_opaque_ratio_drop: float = minf(float(thresholds.get("max_opaque_ratio_drop", 1.0)), backend_max_opaque_drop)
	var max_unique_color_drop_ratio: float = minf(float(thresholds.get("max_unique_color_drop_ratio", 1.0)), backend_max_unique_drop)
	var max_luma_delta: float = minf(float(thresholds.get("max_luma_delta", 1.0)), backend_max_luma_delta)

	DirAccess.make_dir_recursive_absolute(SNAPSHOT_DIR)
	var allowed_capture_modes: Array[String] = _resolve_allowed_capture_modes(allowed_capture_modes_map, backend_tag)

	var passed_snapshots: int = 0
	for snapshot_id_var in snapshots.keys():
		var snapshot_id: String = str(snapshot_id_var)
		var row_variant: Variant = snapshots.get(snapshot_id, {})
		if not (row_variant is Dictionary):
			_push_result(report, snapshot_id, "invalid_snapshot_row", false, "snapshot row must be object")
			continue

		var row: Dictionary = row_variant
		var capture_result: Dictionary = await _capture_snapshot(snapshot_id, row, sample_rounds)
		if not bool(capture_result.get("ok", false)):
			_push_result(report, snapshot_id, "capture_failed", false, str(capture_result.get("message", "capture failed")))
			continue

		var metrics: Dictionary = capture_result.get("metrics", {})
		var snapshot_metrics: Dictionary = report.get("snapshots", {})
		snapshot_metrics[snapshot_id] = metrics
		report["snapshots"] = snapshot_metrics

		var opaque_ratio: float = float(metrics.get("opaque_ratio", 0.0))
		var unique_colors: int = int(metrics.get("unique_colors", 0))
		var avg_luma: float = float(metrics.get("avg_luma", 0.0))
		var capture_mode: String = str(metrics.get("capture_mode", "unknown"))

		var opaque_ratio_min: float = float(row.get("opaque_ratio_min", 0.0))
		var unique_colors_min: int = int(ceil(float(row.get("unique_colors_min", 0)) * unique_colors_min_scale))
		var luma_min: float = clampf(float(row.get("luma_min", 0.0)) - luma_range_padding, 0.0, 1.0)
		var luma_max: float = clampf(float(row.get("luma_max", 1.0)) + luma_range_padding, 0.0, 1.0)

		var snapshot_passed: bool = true
		if opaque_ratio < opaque_ratio_min:
			snapshot_passed = false
			_push_result(report, snapshot_id, "opaque_ratio_min", false, "opaque_ratio %.3f below min %.3f" % [opaque_ratio, opaque_ratio_min])
		if unique_colors < unique_colors_min:
			snapshot_passed = false
			_push_result(report, snapshot_id, "unique_colors_min", false, "unique_colors %d below min %d" % [unique_colors, unique_colors_min])
		if avg_luma < luma_min or avg_luma > luma_max:
			snapshot_passed = false
			_push_result(report, snapshot_id, "luma_range", false, "avg_luma %.3f out of range [%.3f, %.3f]" % [avg_luma, luma_min, luma_max])
		if not allowed_capture_modes.is_empty() and not allowed_capture_modes.has(capture_mode):
			snapshot_passed = false
			_push_result(report, snapshot_id, "capture_mode_not_allowed", false, "capture_mode %s not allowed for backend %s" % [capture_mode, backend_tag])

		var opaque_ratio_stddev: float = float(metrics.get("opaque_ratio_stddev", 0.0))
		var luma_stddev: float = float(metrics.get("avg_luma_stddev", 0.0))
		var unique_stddev_ratio: float = float(metrics.get("unique_color_stddev_ratio", 0.0))
		if opaque_ratio_stddev > max_opaque_ratio_stddev:
			snapshot_passed = false
			_push_result(report, snapshot_id, "opaque_ratio_stddev", false, "opaque_ratio_stddev %.4f exceeds %.4f" % [opaque_ratio_stddev, max_opaque_ratio_stddev])
		if luma_stddev > max_luma_stddev:
			snapshot_passed = false
			_push_result(report, snapshot_id, "luma_stddev", false, "avg_luma_stddev %.4f exceeds %.4f" % [luma_stddev, max_luma_stddev])
		if unique_stddev_ratio > max_unique_color_stddev_ratio:
			snapshot_passed = false
			_push_result(report, snapshot_id, "unique_color_stddev_ratio", false, "unique_color_stddev_ratio %.4f exceeds %.4f" % [unique_stddev_ratio, max_unique_color_stddev_ratio])

		var previous_snapshots: Dictionary = previous_report.get("snapshots", {})
		var previous_metrics: Dictionary = previous_snapshots.get(snapshot_id, {})
		if not previous_metrics.is_empty():
			var prev_opaque_ratio: float = float(previous_metrics.get("opaque_ratio", opaque_ratio))
			var prev_unique_colors: float = float(previous_metrics.get("unique_colors", unique_colors))
			var prev_luma: float = float(previous_metrics.get("avg_luma", avg_luma))

			var opaque_drop: float = maxf(0.0, prev_opaque_ratio - opaque_ratio)
			var unique_drop_ratio: float = 0.0
			if prev_unique_colors > 0.0:
				unique_drop_ratio = maxf(0.0, (prev_unique_colors - float(unique_colors)) / prev_unique_colors)
			var luma_delta: float = absf(prev_luma - avg_luma)
			var whitelist_row: Dictionary = _resolve_snapshot_whitelist(diff_whitelist, backend_tag, snapshot_id)
			var whitelist_reason: String = str(whitelist_row.get("reason", ""))
			var effective_opaque_drop: float = max_opaque_ratio_drop
			var effective_unique_drop: float = max_unique_color_drop_ratio
			var effective_luma_delta: float = max_luma_delta
			if whitelist_row.has("max_opaque_ratio_drop"):
				effective_opaque_drop = maxf(effective_opaque_drop, float(whitelist_row.get("max_opaque_ratio_drop", effective_opaque_drop)))
			if whitelist_row.has("max_unique_color_drop_ratio"):
				effective_unique_drop = maxf(effective_unique_drop, float(whitelist_row.get("max_unique_color_drop_ratio", effective_unique_drop)))
			if whitelist_row.has("max_luma_delta"):
				effective_luma_delta = maxf(effective_luma_delta, float(whitelist_row.get("max_luma_delta", effective_luma_delta)))

			var trend: Dictionary = report.get("trend", {})
			var opaque_ratio_drops: Dictionary = trend.get("opaque_ratio_drops", {})
			opaque_ratio_drops[snapshot_id] = opaque_drop
			trend["opaque_ratio_drops"] = opaque_ratio_drops
			var unique_color_drop_ratios: Dictionary = trend.get("unique_color_drop_ratios", {})
			unique_color_drop_ratios[snapshot_id] = unique_drop_ratio
			trend["unique_color_drop_ratios"] = unique_color_drop_ratios
			var luma_deltas: Dictionary = trend.get("luma_deltas", {})
			luma_deltas[snapshot_id] = luma_delta
			trend["luma_deltas"] = luma_deltas
			report["trend"] = trend

			if opaque_drop > max_opaque_ratio_drop:
				if opaque_drop <= effective_opaque_drop:
					_register_whitelist_hit(report, snapshot_id, "opaque_ratio_drop", opaque_drop, max_opaque_ratio_drop, effective_opaque_drop, whitelist_reason)
				else:
					_push_warning(report, snapshot_id, "opaque_ratio_drop", "opaque_ratio drop %.3f exceeds %.3f" % [opaque_drop, effective_opaque_drop])
					trend["regressions"] = int(trend.get("regressions", 0)) + 1
					report["trend"] = trend
			if unique_drop_ratio > max_unique_color_drop_ratio:
				if unique_drop_ratio <= effective_unique_drop:
					_register_whitelist_hit(report, snapshot_id, "unique_color_drop_ratio", unique_drop_ratio, max_unique_color_drop_ratio, effective_unique_drop, whitelist_reason)
				else:
					_push_warning(report, snapshot_id, "unique_color_drop_ratio", "unique_colors drop ratio %.3f exceeds %.3f" % [unique_drop_ratio, effective_unique_drop])
					trend["regressions"] = int(trend.get("regressions", 0)) + 1
					report["trend"] = trend
			if luma_delta > max_luma_delta:
				if luma_delta <= effective_luma_delta:
					_register_whitelist_hit(report, snapshot_id, "luma_delta", luma_delta, max_luma_delta, effective_luma_delta, whitelist_reason)
				else:
					_push_warning(report, snapshot_id, "luma_delta", "luma delta %.3f exceeds %.3f" % [luma_delta, effective_luma_delta])
					trend["regressions"] = int(trend.get("regressions", 0)) + 1
					report["trend"] = trend

		if snapshot_passed:
			passed_snapshots += 1
			_push_result(report, snapshot_id, "snapshot_metrics", true, "snapshot metrics within baseline")

	if passed_snapshots < min_snapshots:
		_push_result(report, "global", "min_snapshots", false, "passed snapshots %d below min_snapshots %d" % [passed_snapshots, min_snapshots])

	for required_id in required_snapshot_ids:
		var captured_snapshots: Dictionary = report.get("snapshots", {})
		if not captured_snapshots.has(required_id):
			_push_result(report, "global", "required_snapshot_not_captured", false, "required snapshot '%s' missing from report" % required_id)

	var trend_row: Dictionary = report.get("trend", {})
	var trend_regressions: int = int(trend_row.get("regressions", 0))
	if trend_regressions > max_trend_regressions:
		_push_result(report, "global", "max_trend_regressions_exceeded", false, "trend regressions %d exceeds %d" % [trend_regressions, max_trend_regressions])

	var whitelist_row: Dictionary = report.get("whitelist", {})
	var whitelist_hits: int = int(whitelist_row.get("hits", 0))
	var whitelist_ratio: float = 0.0
	if snapshots.size() > 0:
		whitelist_ratio = float(whitelist_hits) / float(snapshots.size())
	whitelist_row["ratio"] = whitelist_ratio
	report["whitelist"] = whitelist_row
	if whitelist_hits > whitelist_max_hits:
		_push_result(report, "global", "whitelist_max_hits_exceeded", false, "whitelist hits %d exceeds %d" % [whitelist_hits, whitelist_max_hits])
	if whitelist_ratio > whitelist_max_ratio:
		_push_result(report, "global", "whitelist_max_ratio_exceeded", false, "whitelist ratio %.3f exceeds %.3f" % [whitelist_ratio, whitelist_max_ratio])

	_evaluate_backend_attribution(report, backend_tag, required_backends, max_unattributed_regressions, max_backend_specific_regressions)
	_evaluate_whitelist_convergence(report, previous_report, stale_run_threshold, tighten_margin_ratio, max_suggestions)
	_evaluate_exception_lifecycle(report, previous_report, expire_idle_runs, auto_reclaim_hit_streak, max_expired_entries, max_reclaim_candidates)

	_evaluate_cross_version_baseline(report, cross_version_baseline)
	_evaluate_report_layers(report, report_layers, snapshots)
	_evaluate_release_gate_templates(
		report,
		release_gate_templates,
		targets.get("strategy_orchestration", {}),
		strategy_name,
		strategy_template,
		run_mode
	)
	_evaluate_backend_matrix_governance(report, backend_matrix_governance, release_gate_templates, run_mode)
	_evaluate_approval_workflow(report, approval_workflow, strategy_name)
	_evaluate_approval_audit_trail(report, approval_audit_trail, strategy_name, run_mode, backend_tag)
	_evaluate_approval_history_archive(report, approval_history_archive, strategy_name, run_mode, backend_tag)
	_evaluate_release_candidate_tracking(report, release_candidate_tracking, run_mode)

	var failures: int = int(report.get("blockers", 0))
	if failures > max_failures:
		_push_result(report, "global", "max_failures_exceeded", false, "blockers %d exceeds max_failures %d" % [failures, max_failures])

	return report


func _register_whitelist_hit(
	report: Dictionary,
	snapshot_id: String,
	rule_id: String,
	actual: float,
	default_limit: float,
	effective_limit: float,
	reason: String
) -> void:
	var whitelist_row: Dictionary = report.get("whitelist", {})
	var items: Array = whitelist_row.get("items", [])
	items.append(
		{
			"snapshot": snapshot_id,
			"id": rule_id,
			"actual": actual,
			"default_limit": default_limit,
			"effective_limit": effective_limit,
			"reason": reason,
		}
	)
	whitelist_row["items"] = items
	whitelist_row["hits"] = int(whitelist_row.get("hits", 0)) + 1
	report["whitelist"] = whitelist_row
	var message: String = "%s %.3f exceeds default %.3f but allowed by whitelist %.3f" % [rule_id, actual, default_limit, effective_limit]
	if not reason.is_empty():
		message += " (%s)" % reason
	_push_warning(report, snapshot_id, "%s_whitelisted" % rule_id, message)


func _evaluate_backend_attribution(
	report: Dictionary,
	backend_tag: String,
	required_backends: Array[String],
	max_unattributed_regressions: int,
	max_backend_specific_regressions: int
) -> void:
	var attribution_row: Dictionary = report.get("backend_attribution", {})
	var snapshot_metrics: Dictionary = report.get("snapshots", {})
	var items: Array = report.get("items", [])

	var regressions: int = 0
	var backend_specific_regressions: int = 0
	var unattributed_regressions: int = 0
	var attribution_items: Array = []

	for item in items:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		if bool(row.get("passed", false)):
			continue
		if str(row.get("severity", "blocker")) != "warning":
			continue
		var rule_id: String = str(row.get("id", ""))
		if rule_id != "opaque_ratio_drop" and rule_id != "unique_color_drop_ratio" and rule_id != "luma_delta":
			continue

		regressions += 1
		var snapshot_id: String = str(row.get("snapshot", ""))
		var capture_mode: String = "unknown"
		if snapshot_metrics.has(snapshot_id):
			var metric_row: Variant = snapshot_metrics.get(snapshot_id, {})
			if metric_row is Dictionary:
				capture_mode = str(metric_row.get("capture_mode", "unknown"))

		var attribution: String = "unattributed"
		if capture_mode.begins_with("fallback_"):
			attribution = backend_tag
			backend_specific_regressions += 1
		else:
			unattributed_regressions += 1

		attribution_items.append({
			"snapshot": snapshot_id,
			"id": rule_id,
			"capture_mode": capture_mode,
			"attribution": attribution,
		})

	attribution_row["backend_tag"] = backend_tag
	attribution_row["required_backends"] = required_backends
	attribution_row["regressions"] = regressions
	attribution_row["backend_specific_regressions"] = backend_specific_regressions
	attribution_row["max_backend_specific_regressions"] = max_backend_specific_regressions
	attribution_row["unattributed_regressions"] = unattributed_regressions
	attribution_row["max_unattributed_regressions"] = max_unattributed_regressions
	attribution_row["items"] = attribution_items
	report["backend_attribution"] = attribution_row

	if not required_backends.is_empty() and not required_backends.has(backend_tag):
		_push_result(report, "global", "backend_not_allowed", false, "backend %s is not listed in backend_attribution.required_backends" % backend_tag)

	if unattributed_regressions > max_unattributed_regressions:
		_push_result(report, "global", "max_unattributed_regressions_exceeded", false, "unattributed regressions %d exceeds %d" % [unattributed_regressions, max_unattributed_regressions])

	if backend_specific_regressions > max_backend_specific_regressions:
		_push_result(report, "global", "max_backend_specific_regressions_exceeded", false, "%s regressions %d exceeds %d" % [backend_tag, backend_specific_regressions, max_backend_specific_regressions])


func _evaluate_whitelist_convergence(
	report: Dictionary,
	previous_report: Dictionary,
	stale_run_threshold: int,
	tighten_margin_ratio: float,
	max_suggestions: int
) -> void:
	var whitelist_row: Dictionary = report.get("whitelist", {})
	var whitelist_items: Array = whitelist_row.get("items", [])
	var previous_whitelist: Dictionary = previous_report.get("whitelist", {})
	var previous_streaks: Dictionary = previous_whitelist.get("streaks", {})

	var streaks: Dictionary = {}
	var suggestions: Array = []

	for item in whitelist_items:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var snapshot_id: String = str(row.get("snapshot", ""))
		var rule_id: String = str(row.get("id", ""))
		if snapshot_id.is_empty() or rule_id.is_empty():
			continue

		var key: String = "%s|%s" % [snapshot_id, rule_id]
		var previous_streak: int = int(previous_streaks.get(key, 0))
		var current_streak: int = previous_streak + 1
		streaks[key] = current_streak

		if current_streak < stale_run_threshold:
			continue
		if max_suggestions > 0 and suggestions.size() >= max_suggestions:
			continue

		var default_limit: float = float(row.get("default_limit", 0.0))
		var effective_limit: float = float(row.get("effective_limit", default_limit))
		if effective_limit <= default_limit:
			continue

		var suggested_limit: float = default_limit + (effective_limit - default_limit) * (1.0 - tighten_margin_ratio)
		suggested_limit = clampf(suggested_limit, default_limit, effective_limit)
		if suggested_limit >= effective_limit:
			continue

		suggestions.append({
			"snapshot": snapshot_id,
			"id": rule_id,
			"reason": str(row.get("reason", "")),
			"streak": current_streak,
			"actual": float(row.get("actual", 0.0)),
			"default_limit": default_limit,
			"current_limit": effective_limit,
			"suggested_limit": suggested_limit,
		})

	whitelist_row["streaks"] = streaks
	whitelist_row["convergence_suggestions"] = suggestions
	whitelist_row["stale_run_threshold"] = stale_run_threshold
	whitelist_row["tighten_margin_ratio"] = tighten_margin_ratio
	report["whitelist"] = whitelist_row


func _evaluate_exception_lifecycle(
	report: Dictionary,
	previous_report: Dictionary,
	expire_idle_runs: int,
	auto_reclaim_hit_streak: int,
	max_expired_entries: int,
	max_reclaim_candidates: int
) -> void:
	var whitelist_row: Dictionary = report.get("whitelist", {})
	var current_items: Array = whitelist_row.get("items", [])
	var convergence_items: Array = whitelist_row.get("convergence_suggestions", [])
	var previous_whitelist: Dictionary = previous_report.get("whitelist", {})
	var previous_lifecycle: Dictionary = previous_whitelist.get("lifecycle", {})

	var current_items_by_key: Dictionary = {}
	for item in current_items:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var snapshot_id: String = str(row.get("snapshot", ""))
		var rule_id: String = str(row.get("id", ""))
		if snapshot_id.is_empty() or rule_id.is_empty():
			continue
		var key: String = "%s|%s" % [snapshot_id, rule_id]
		current_items_by_key[key] = row

	var suggestions_by_key: Dictionary = {}
	for item in convergence_items:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var snapshot_id: String = str(row.get("snapshot", ""))
		var rule_id: String = str(row.get("id", ""))
		if snapshot_id.is_empty() or rule_id.is_empty():
			continue
		var key: String = "%s|%s" % [snapshot_id, rule_id]
		suggestions_by_key[key] = row

	var all_keys: Dictionary = {}
	for key_var in previous_lifecycle.keys():
		all_keys[str(key_var)] = true
	for key_var in current_items_by_key.keys():
		all_keys[str(key_var)] = true

	var lifecycle: Dictionary = {}
	var expired_entries: Array = []
	var reclaim_candidates: Array = []

	for key_var in all_keys.keys():
		var key: String = str(key_var)
		var previous_row_variant: Variant = previous_lifecycle.get(key, {})
		var previous_row: Dictionary = previous_row_variant if previous_row_variant is Dictionary else {}
		var snapshot_id: String = str(previous_row.get("snapshot", ""))
		var rule_id: String = str(previous_row.get("id", ""))
		var hit_streak: int = int(previous_row.get("hit_streak", 0))
		var idle_runs: int = int(previous_row.get("idle_runs", 0))
		var total_hits: int = int(previous_row.get("total_hits", 0))
		var last_status: String = "idle"

		if current_items_by_key.has(key):
			var current_row_variant: Variant = current_items_by_key.get(key, {})
			var current_row: Dictionary = current_row_variant if current_row_variant is Dictionary else {}
			snapshot_id = str(current_row.get("snapshot", snapshot_id))
			rule_id = str(current_row.get("id", rule_id))
			hit_streak += 1
			idle_runs = 0
			total_hits += 1
			last_status = "hit"
		else:
			hit_streak = 0
			idle_runs += 1
			last_status = "idle"

		var lifecycle_row: Dictionary = {
			"snapshot": snapshot_id,
			"id": rule_id,
			"hit_streak": hit_streak,
			"idle_runs": idle_runs,
			"total_hits": total_hits,
			"last_status": last_status,
		}
		lifecycle[key] = lifecycle_row

		if total_hits > 0 and idle_runs >= expire_idle_runs:
			expired_entries.append({
				"key": key,
				"snapshot": snapshot_id,
				"id": rule_id,
				"idle_runs": idle_runs,
				"expire_idle_runs": expire_idle_runs,
			})

		if hit_streak >= auto_reclaim_hit_streak:
			var candidate: Dictionary = {
				"key": key,
				"snapshot": snapshot_id,
				"id": rule_id,
				"hit_streak": hit_streak,
				"auto_reclaim_hit_streak": auto_reclaim_hit_streak,
			}
			if suggestions_by_key.has(key):
				var suggestion_variant: Variant = suggestions_by_key.get(key, {})
				if suggestion_variant is Dictionary:
					var suggestion: Dictionary = suggestion_variant
					candidate["suggested_limit"] = float(suggestion.get("suggested_limit", 0.0))
					candidate["current_limit"] = float(suggestion.get("current_limit", 0.0))
					candidate["reason"] = str(suggestion.get("reason", ""))
			reclaim_candidates.append(candidate)

	whitelist_row["expire_idle_runs"] = expire_idle_runs
	whitelist_row["auto_reclaim_hit_streak"] = auto_reclaim_hit_streak
	whitelist_row["max_expired_entries"] = max_expired_entries
	whitelist_row["max_reclaim_candidates"] = max_reclaim_candidates
	whitelist_row["lifecycle"] = lifecycle
	whitelist_row["expired_entries"] = expired_entries
	whitelist_row["reclaim_candidates"] = reclaim_candidates
	report["whitelist"] = whitelist_row

	if expired_entries.size() > max_expired_entries:
		_push_result(report, "global", "max_expired_entries_exceeded", false, "expired whitelist entries %d exceeds %d" % [expired_entries.size(), max_expired_entries])
	if reclaim_candidates.size() > max_reclaim_candidates:
		_push_result(report, "global", "max_reclaim_candidates_exceeded", false, "reclaim candidates %d exceeds %d" % [reclaim_candidates.size(), max_reclaim_candidates])


func _capture_snapshot(snapshot_id: String, row: Dictionary, sample_rounds: int) -> Dictionary:
	var scene_path: String = str(row.get("scene", ""))
	if scene_path.is_empty() or not scene_path.begins_with("res://"):
		return {"ok": false, "message": "invalid scene path"}
	if not ResourceLoader.exists(scene_path):
		return {"ok": false, "message": "scene does not exist"}

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return {"ok": false, "message": "scene load failed"}

	var instance: Node = packed_scene.instantiate()
	if instance == null:
		return {"ok": false, "message": "scene instantiate failed"}

	var width: int = maxi(320, int(row.get("width", 1280)))
	var height: int = maxi(180, int(row.get("height", 720)))
	var warmup_frames: int = maxi(1, int(row.get("warmup_frames", 12)))
	var capture_frames: int = maxi(1, int(row.get("capture_frames", 4)))
	var setup: String = str(row.get("setup", "none"))

	var viewport: SubViewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.size = Vector2i(width, height)
	get_root().add_child(viewport)
	viewport.add_child(instance)

	await _wait_frames(warmup_frames)
	_apply_snapshot_setup(instance, setup)
	await _wait_frames(capture_frames)
	var output_path: String = "%s/%s.png" % [SNAPSHOT_DIR, _sanitize_snapshot_id(snapshot_id)]
	var rounds: Array[Dictionary] = []
	var rounds_count: int = maxi(1, sample_rounds)
	for round_idx in range(rounds_count):
		RenderingServer.force_draw()
		await _wait_frames(1)
		rounds.append(_capture_single_metrics(viewport, instance, width, height, output_path))

	var metrics: Dictionary = _aggregate_round_metrics(rounds)
	viewport.queue_free()
	await _wait_frames(1)
	return {
		"ok": true,
		"metrics": metrics,
	}


func _capture_single_metrics(viewport: SubViewport, instance: Node, width: int, height: int, output_path: String) -> Dictionary:
	if DisplayServer.get_name() == "headless":
		var fallback_metrics_headless: Dictionary = _compute_fallback_scene_metrics(instance, width, height)
		fallback_metrics_headless["image_path"] = ""
		fallback_metrics_headless["capture_mode"] = "fallback_headless_display"
		return fallback_metrics_headless

	var texture: Texture2D = viewport.get_texture()
	if texture == null:
		var fallback_metrics: Dictionary = _compute_fallback_scene_metrics(instance, width, height)
		fallback_metrics["image_path"] = ""
		fallback_metrics["capture_mode"] = "fallback_headless"
		return fallback_metrics

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		var fallback_metrics_empty: Dictionary = _compute_fallback_scene_metrics(instance, width, height)
		fallback_metrics_empty["image_path"] = ""
		fallback_metrics_empty["capture_mode"] = "fallback_empty_image"
		return fallback_metrics_empty

	image.convert(Image.FORMAT_RGBA8)
	var metrics: Dictionary = _compute_image_metrics(image)
	var save_error: int = image.save_png(output_path)
	if save_error != OK:
		var fallback_metrics_save: Dictionary = _compute_fallback_scene_metrics(instance, width, height)
		fallback_metrics_save["image_path"] = ""
		fallback_metrics_save["capture_mode"] = "fallback_save_error"
		return fallback_metrics_save

	metrics["image_path"] = output_path
	metrics["capture_mode"] = "image"
	return metrics


func _aggregate_round_metrics(rounds: Array[Dictionary]) -> Dictionary:
	var round_count: int = rounds.size()
	if round_count <= 0:
		return {}

	var opaque_values: Array[float] = []
	var luma_values: Array[float] = []
	var color_values: Array[float] = []
	var modes: Dictionary = {}
	var sampled_pixels_sum: float = 0.0
	var width: int = int(rounds[0].get("width", 0))
	var height: int = int(rounds[0].get("height", 0))
	var image_path: String = ""

	for row in rounds:
		var opaque_ratio: float = float(row.get("opaque_ratio", 0.0))
		var avg_luma: float = float(row.get("avg_luma", 0.0))
		var unique_colors: float = float(row.get("unique_colors", 0))
		var sampled_pixels: float = float(row.get("sampled_pixels", 0))
		opaque_values.append(opaque_ratio)
		luma_values.append(avg_luma)
		color_values.append(unique_colors)
		sampled_pixels_sum += sampled_pixels

		var mode: String = str(row.get("capture_mode", "unknown"))
		modes[mode] = int(modes.get(mode, 0)) + 1

		if image_path.is_empty():
			var image_candidate: String = str(row.get("image_path", ""))
			if not image_candidate.is_empty():
				image_path = image_candidate

	var opaque_avg: float = _avg(opaque_values)
	var luma_avg: float = _avg(luma_values)
	var unique_avg: float = _avg(color_values)
	var opaque_stddev: float = _stddev(opaque_values, opaque_avg)
	var luma_stddev: float = _stddev(luma_values, luma_avg)
	var unique_stddev: float = _stddev(color_values, unique_avg)
	var unique_stddev_ratio: float = unique_stddev / maxf(1.0, unique_avg)
	var sampled_pixels_avg: int = int(round(sampled_pixels_sum / float(round_count)))
	var opaque_pixels_avg: int = int(round(float(sampled_pixels_avg) * opaque_avg))

	return {
		"width": width,
		"height": height,
		"sample_rounds": round_count,
		"sampled_pixels": sampled_pixels_avg,
		"opaque_pixels": opaque_pixels_avg,
		"opaque_ratio": opaque_avg,
		"opaque_ratio_stddev": opaque_stddev,
		"unique_colors": int(round(unique_avg)),
		"unique_colors_stddev": unique_stddev,
		"unique_color_stddev_ratio": unique_stddev_ratio,
		"avg_luma": luma_avg,
		"avg_luma_stddev": luma_stddev,
		"capture_mode": _pick_dominant_mode(modes),
		"capture_modes": modes,
		"image_path": image_path,
	}


func _avg(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for v in values:
		total += v
	return total / float(values.size())


func _stddev(values: Array[float], mean: float) -> float:
	if values.size() <= 1:
		return 0.0
	var sum_sq: float = 0.0
	for v in values:
		var delta: float = v - mean
		sum_sq += delta * delta
	return sqrt(sum_sq / float(values.size()))


func _pick_dominant_mode(modes: Dictionary) -> String:
	var best_mode: String = "unknown"
	var best_count: int = -1
	for mode_var in modes.keys():
		var mode: String = str(mode_var)
		var count: int = int(modes.get(mode, 0))
		if count > best_count:
			best_mode = mode
			best_count = count
	return best_mode


func _detect_backend_tag() -> String:
	var env_tag: String = OS.get_environment("VISUAL_SNAPSHOT_BACKEND_TAG").strip_edges()
	if not env_tag.is_empty():
		return env_tag
	var os_name: String = OS.get_name().to_lower()
	var display_name: String = DisplayServer.get_name().to_lower()
	if display_name == "headless":
		if os_name.contains("windows"):
			return "windows_headless"
		if os_name.contains("linux"):
			return "linux_headless"
		return "default"
	return "default"


func _resolve_backend_profile(backend_profiles: Dictionary, backend_tag: String) -> Dictionary:
	if backend_profiles.has(backend_tag):
		var row: Variant = backend_profiles.get(backend_tag)
		if row is Dictionary:
			return row
	if backend_profiles.has("default"):
		var default_row: Variant = backend_profiles.get("default")
		if default_row is Dictionary:
			return default_row
	return {}


func _resolve_strategy_orchestration(strategy_raw: Variant, base_sections: Dictionary) -> Dictionary:
	var resolved: Dictionary = {
		"name": "default",
		"template": "base",
		"errors": [],
		"thresholds": base_sections.get("thresholds", {}),
		"whitelist_policy": base_sections.get("whitelist_policy", {}),
		"backend_attribution": base_sections.get("backend_attribution", {}),
		"whitelist_convergence": base_sections.get("whitelist_convergence", {}),
		"exception_lifecycle": base_sections.get("exception_lifecycle", {}),
		"report_layers": base_sections.get("report_layers", {}),
		"cross_version_baseline": base_sections.get("cross_version_baseline", {}),
	}
	if not (strategy_raw is Dictionary):
		return resolved

	var strategy_orchestration: Dictionary = strategy_raw
	var default_strategy: String = str(strategy_orchestration.get("default_strategy", "")).strip_edges()
	var selected_strategy: String = OS.get_environment("VISUAL_SNAPSHOT_STRATEGY").strip_edges()
	if selected_strategy.is_empty():
		selected_strategy = default_strategy
	if selected_strategy.is_empty():
		return resolved

	resolved["name"] = selected_strategy

	var strategies_variant: Variant = strategy_orchestration.get("strategies", {})
	if not (strategies_variant is Dictionary):
		var errors_missing_strategies: Array = resolved.get("errors", [])
		errors_missing_strategies.append("strategy_orchestration.strategies must be object")
		resolved["errors"] = errors_missing_strategies
		return resolved
	var strategies: Dictionary = strategies_variant
	if not strategies.has(selected_strategy):
		var errors_missing_strategy: Array = resolved.get("errors", [])
		errors_missing_strategy.append("strategy '%s' not found in strategy_orchestration.strategies" % selected_strategy)
		resolved["errors"] = errors_missing_strategy
		return resolved

	var strategy_row_variant: Variant = strategies.get(selected_strategy, {})
	if not (strategy_row_variant is Dictionary):
		var errors_invalid_strategy: Array = resolved.get("errors", [])
		errors_invalid_strategy.append("strategy '%s' row must be object" % selected_strategy)
		resolved["errors"] = errors_invalid_strategy
		return resolved
	var strategy_row: Dictionary = strategy_row_variant
	var template_name: String = str(strategy_row.get("template", "")).strip_edges()
	if template_name.is_empty():
		var errors_missing_template: Array = resolved.get("errors", [])
		errors_missing_template.append("strategy '%s' missing template" % selected_strategy)
		resolved["errors"] = errors_missing_template
		return resolved
	resolved["template"] = template_name

	var templates_variant: Variant = strategy_orchestration.get("templates", {})
	if not (templates_variant is Dictionary):
		var errors_missing_templates: Array = resolved.get("errors", [])
		errors_missing_templates.append("strategy_orchestration.templates must be object")
		resolved["errors"] = errors_missing_templates
		return resolved
	var templates: Dictionary = templates_variant
	if not templates.has(template_name):
		var errors_unknown_template: Array = resolved.get("errors", [])
		errors_unknown_template.append("template '%s' not found in strategy_orchestration.templates" % template_name)
		resolved["errors"] = errors_unknown_template
		return resolved

	var template_row_variant: Variant = templates.get(template_name, {})
	if not (template_row_variant is Dictionary):
		var errors_invalid_template: Array = resolved.get("errors", [])
		errors_invalid_template.append("template '%s' row must be object" % template_name)
		resolved["errors"] = errors_invalid_template
		return resolved
	var template_row: Dictionary = template_row_variant

	resolved["thresholds"] = _merge_shallow_dictionary(resolved.get("thresholds", {}), template_row.get("thresholds", {}))
	resolved["whitelist_policy"] = _merge_shallow_dictionary(resolved.get("whitelist_policy", {}), template_row.get("whitelist_policy", {}))
	resolved["backend_attribution"] = _merge_shallow_dictionary(resolved.get("backend_attribution", {}), template_row.get("backend_attribution", {}))
	resolved["whitelist_convergence"] = _merge_shallow_dictionary(resolved.get("whitelist_convergence", {}), template_row.get("whitelist_convergence", {}))
	resolved["exception_lifecycle"] = _merge_shallow_dictionary(resolved.get("exception_lifecycle", {}), template_row.get("exception_lifecycle", {}))
	resolved["cross_version_baseline"] = _merge_shallow_dictionary(resolved.get("cross_version_baseline", {}), template_row.get("cross_version_baseline", {}))
	resolved["report_layers"] = _merge_report_layer_overrides(resolved.get("report_layers", {}), template_row.get("report_layers", {}))

	return resolved


func _merge_shallow_dictionary(base_row_variant: Variant, override_row_variant: Variant) -> Dictionary:
	var output: Dictionary = {}
	if base_row_variant is Dictionary:
		var base_row: Dictionary = base_row_variant
		for key_var in base_row.keys():
			output[key_var] = base_row.get(key_var)
	if override_row_variant is Dictionary:
		var override_row: Dictionary = override_row_variant
		for key_var in override_row.keys():
			output[key_var] = override_row.get(key_var)
	return output


func _merge_report_layer_overrides(base_layers_variant: Variant, override_layers_variant: Variant) -> Dictionary:
	var output: Dictionary = {}
	if base_layers_variant is Dictionary:
		var base_layers: Dictionary = base_layers_variant
		for layer_var in base_layers.keys():
			var layer_name: String = str(layer_var)
			var row_variant: Variant = base_layers.get(layer_var, {})
			if row_variant is Dictionary:
				output[layer_name] = _merge_shallow_dictionary(row_variant, {})

	if not (override_layers_variant is Dictionary):
		return output

	var override_layers: Dictionary = override_layers_variant
	for layer_var in override_layers.keys():
		var layer_name: String = str(layer_var).strip_edges()
		if layer_name.is_empty() or not output.has(layer_name):
			continue
		var override_row_variant: Variant = override_layers.get(layer_var, {})
		if not (override_row_variant is Dictionary):
			continue
		var base_row_variant: Variant = output.get(layer_name, {})
		output[layer_name] = _merge_shallow_dictionary(base_row_variant, override_row_variant)

	return output


func _sanitize_string_array(raw: Variant) -> Array[String]:
	var output: Array[String] = []
	if raw is Array:
		for item in raw:
			var value: String = str(item).strip_edges()
			if not value.is_empty():
				output.append(value)
	return output


func _sanitize_allowed_capture_modes(raw: Variant) -> Dictionary:
	var output: Dictionary = {}
	if raw is Dictionary:
		for key_var in raw.keys():
			var backend: String = str(key_var).strip_edges()
			if backend.is_empty():
				continue
			output[backend] = _sanitize_string_array(raw.get(key_var, []))
	return output


func _resolve_allowed_capture_modes(modes_map: Dictionary, backend_tag: String) -> Array[String]:
	if modes_map.has(backend_tag):
		var row: Variant = modes_map.get(backend_tag, [])
		if row is Array:
			return _sanitize_string_array(row)
	if modes_map.has("default"):
		var default_row: Variant = modes_map.get("default", [])
		if default_row is Array:
			return _sanitize_string_array(default_row)
	return []


func _sanitize_diff_whitelist(raw: Variant) -> Dictionary:
	var output: Dictionary = {}
	if not (raw is Dictionary):
		return output

	for backend_var in raw.keys():
		var backend: String = str(backend_var).strip_edges()
		if backend.is_empty():
			continue
		var per_backend: Variant = raw.get(backend_var, {})
		if not (per_backend is Dictionary):
			continue
		var sanitized_backend: Dictionary = {}
		for snapshot_var in per_backend.keys():
			var snapshot_id: String = str(snapshot_var).strip_edges()
			if snapshot_id.is_empty():
				continue
			var row: Variant = per_backend.get(snapshot_var, {})
			if not (row is Dictionary):
				continue
			var sanitized: Dictionary = {}
			if row.has("max_opaque_ratio_drop"):
				sanitized["max_opaque_ratio_drop"] = maxf(0.0, float(row.get("max_opaque_ratio_drop", 0.0)))
			if row.has("max_unique_color_drop_ratio"):
				sanitized["max_unique_color_drop_ratio"] = maxf(0.0, float(row.get("max_unique_color_drop_ratio", 0.0)))
			if row.has("max_luma_delta"):
				sanitized["max_luma_delta"] = maxf(0.0, float(row.get("max_luma_delta", 0.0)))
			sanitized["reason"] = str(row.get("reason", "")).strip_edges()
			sanitized_backend[snapshot_id] = sanitized
		output[backend] = sanitized_backend

	return output


func _resolve_snapshot_whitelist(whitelist: Dictionary, backend_tag: String, snapshot_id: String) -> Dictionary:
	if whitelist.has(backend_tag):
		var backend_row: Variant = whitelist.get(backend_tag, {})
		if backend_row is Dictionary and backend_row.has(snapshot_id):
			var snapshot_row: Variant = backend_row.get(snapshot_id, {})
			if snapshot_row is Dictionary:
				return snapshot_row
	if whitelist.has("default"):
		var default_row: Variant = whitelist.get("default", {})
		if default_row is Dictionary and default_row.has(snapshot_id):
			var snapshot_default: Variant = default_row.get(snapshot_id, {})
			if snapshot_default is Dictionary:
				return snapshot_default
	return {}


func _parse_csv_env(raw: String) -> Array[String]:
	var output: Array[String] = []
	for token in raw.split(","):
		var value: String = str(token).strip_edges()
		if not value.is_empty() and not output.has(value):
			output.append(value)
	return output


func _sanitize_backend_matrix_governance(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"required_backend_matrix": [],
		"required_run_modes": [],
		"max_missing_backend_matrix": 0,
		"max_missing_run_mode_bindings": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	output["required_backend_matrix"] = _sanitize_string_array(row.get("required_backend_matrix", []))
	output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", []))
	output["max_missing_backend_matrix"] = maxi(0, int(row.get("max_missing_backend_matrix", 0)))
	output["max_missing_run_mode_bindings"] = maxi(0, int(row.get("max_missing_run_mode_bindings", 0)))
	return output


func _sanitize_approval_workflow(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"required_report_sections": [],
		"require_zero_blockers": true,
		"require_zero_warnings_for_strategies": [],
		"max_approval_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	output["required_report_sections"] = _sanitize_string_array(row.get("required_report_sections", []))
	output["require_zero_blockers"] = bool(row.get("require_zero_blockers", true))
	output["require_zero_warnings_for_strategies"] = _sanitize_string_array(row.get("require_zero_warnings_for_strategies", []))
	output["max_approval_failures"] = maxi(0, int(row.get("max_approval_failures", 0)))
	return output


func _sanitize_approval_audit_trail(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"history_file": "user://visual_snapshot_approval_history.json",
		"max_entries": 80,
		"required_run_modes": [],
		"required_backends": [],
		"require_unique_pipeline_id": true,
		"max_missing_pipeline_id": 0,
		"max_history_trace_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	var history_file: String = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_history.json"))).strip_edges()
	if history_file.begins_with("user://"):
		output["history_file"] = history_file
	output["max_entries"] = maxi(10, int(row.get("max_entries", output.get("max_entries", 80))))
	output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", []))
	output["required_backends"] = _sanitize_string_array(row.get("required_backends", []))
	output["require_unique_pipeline_id"] = bool(row.get("require_unique_pipeline_id", true))
	output["max_missing_pipeline_id"] = maxi(0, int(row.get("max_missing_pipeline_id", 0)))
	output["max_history_trace_failures"] = maxi(0, int(row.get("max_history_trace_failures", 0)))
	return output


func _sanitize_approval_history_archive(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"archive_file": "user://visual_snapshot_approval_archive.json",
		"max_entries": 240,
		"aggregation_window": 80,
		"required_backends": [],
		"required_run_modes": [],
		"max_missing_archive_backends": 0,
		"max_missing_archive_run_modes": 0,
		"max_backend_warning_delta": 0,
		"max_backend_blocker_delta": 0,
		"max_archive_trace_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	var archive_file: String = str(row.get("archive_file", output.get("archive_file", "user://visual_snapshot_approval_archive.json"))).strip_edges()
	if archive_file.begins_with("user://"):
		output["archive_file"] = archive_file
	output["max_entries"] = maxi(20, int(row.get("max_entries", output.get("max_entries", 240))))
	output["aggregation_window"] = maxi(10, int(row.get("aggregation_window", output.get("aggregation_window", 80))))
	output["required_backends"] = _sanitize_string_array(row.get("required_backends", []))
	output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", []))
	output["max_missing_archive_backends"] = maxi(0, int(row.get("max_missing_archive_backends", 0)))
	output["max_missing_archive_run_modes"] = maxi(0, int(row.get("max_missing_archive_run_modes", 0)))
	output["max_backend_warning_delta"] = maxi(0, int(row.get("max_backend_warning_delta", 0)))
	output["max_backend_blocker_delta"] = maxi(0, int(row.get("max_backend_blocker_delta", 0)))
	output["max_archive_trace_failures"] = maxi(0, int(row.get("max_archive_trace_failures", 0)))
	return output


func _sanitize_approval_threshold_templates(
	raw: Variant,
	release_gate_templates: Dictionary,
	backend_matrix_governance: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"default_template": "standard",
		"run_mode_templates": {},
		"templates": {},
	}
	if not (raw is Dictionary):
		return output

	var row: Dictionary = raw
	var default_template: String = str(row.get("default_template", "standard")).strip_edges()
	if default_template.is_empty():
		default_template = "standard"
	output["default_template"] = default_template

	var run_mode_templates: Dictionary = {}
	var run_mode_templates_raw: Variant = row.get("run_mode_templates", {})
	if run_mode_templates_raw is Dictionary:
		for run_mode_var in run_mode_templates_raw.keys():
			var mode_name: String = str(run_mode_var).strip_edges()
			var template_name: String = str(run_mode_templates_raw.get(run_mode_var, "")).strip_edges()
			if mode_name.is_empty() or template_name.is_empty():
				continue
			run_mode_templates[mode_name] = template_name
	output["run_mode_templates"] = run_mode_templates

	var templates: Dictionary = {}
	var templates_raw: Variant = row.get("templates", {})
	if templates_raw is Dictionary:
		for template_var in templates_raw.keys():
			var template_name: String = str(template_var).strip_edges()
			if template_name.is_empty():
				continue
			var template_row_variant: Variant = templates_raw.get(template_var, {})
			if not (template_row_variant is Dictionary):
				continue
			var template_row: Dictionary = template_row_variant
			templates[template_name] = {
				"approval_workflow": _merge_shallow_dictionary({}, template_row.get("approval_workflow", {})),
				"approval_audit_trail": _merge_shallow_dictionary({}, template_row.get("approval_audit_trail", {})),
				"approval_history_archive": _merge_shallow_dictionary({}, template_row.get("approval_history_archive", {})),
			}
	output["templates"] = templates

	if not run_mode_templates.has("release_candidate") and (release_gate_templates.get("ci_mode_bindings", {}) as Dictionary).has("release_candidate"):
		run_mode_templates["release_candidate"] = "candidate"
	if not run_mode_templates.has("release_blocking") and (release_gate_templates.get("ci_mode_bindings", {}) as Dictionary).has("release_blocking"):
		run_mode_templates["release_blocking"] = "blocking"

	var required_run_modes: Array[String] = _sanitize_string_array(backend_matrix_governance.get("required_run_modes", []))
	for mode_name in required_run_modes:
		if not run_mode_templates.has(mode_name):
			run_mode_templates[mode_name] = default_template
	output["run_mode_templates"] = run_mode_templates

	return output


func _resolve_approval_threshold_template(raw: Dictionary, run_mode: String, base_sections: Dictionary) -> Dictionary:
	var resolved: Dictionary = {
		"template": "standard",
		"errors": [],
		"approval_workflow": base_sections.get("approval_workflow", {}),
		"approval_audit_trail": base_sections.get("approval_audit_trail", {}),
		"approval_history_archive": base_sections.get("approval_history_archive", {}),
	}
	if raw.is_empty():
		return resolved

	var default_template: String = str(raw.get("default_template", "standard")).strip_edges()
	if default_template.is_empty():
		default_template = "standard"
	var run_mode_templates: Dictionary = raw.get("run_mode_templates", {})
	var templates: Dictionary = raw.get("templates", {})

	var selected_template: String = OS.get_environment("VISUAL_APPROVAL_TEMPLATE").strip_edges()
	if selected_template.is_empty() and run_mode_templates.has(run_mode):
		selected_template = str(run_mode_templates.get(run_mode, "")).strip_edges()
	if selected_template.is_empty():
		selected_template = default_template
	if selected_template.is_empty():
		selected_template = "standard"
	resolved["template"] = selected_template

	if not templates.has(selected_template):
		var errors_missing_template: Array = resolved.get("errors", [])
		errors_missing_template.append("approval_threshold_templates template '%s' not found" % selected_template)
		resolved["errors"] = errors_missing_template
		return resolved

	var template_row_variant: Variant = templates.get(selected_template, {})
	if not (template_row_variant is Dictionary):
		var errors_invalid_template: Array = resolved.get("errors", [])
		errors_invalid_template.append("approval_threshold_templates template '%s' must be object" % selected_template)
		resolved["errors"] = errors_invalid_template
		return resolved

	var template_row: Dictionary = template_row_variant
	resolved["approval_workflow"] = _merge_shallow_dictionary(
		resolved.get("approval_workflow", {}),
		template_row.get("approval_workflow", {})
	)
	resolved["approval_audit_trail"] = _merge_shallow_dictionary(
		resolved.get("approval_audit_trail", {}),
		template_row.get("approval_audit_trail", {})
	)
	resolved["approval_history_archive"] = _merge_shallow_dictionary(
		resolved.get("approval_history_archive", {}),
		template_row.get("approval_history_archive", {})
	)

	return resolved


func _sanitize_release_candidate_tracking(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"history_file": "user://visual_snapshot_approval_archive.json",
		"window": 40,
		"required_run_modes": ["release_candidate"],
		"required_strategies": ["release_candidate"],
		"min_runs": 1,
		"max_avg_warnings": 1.0,
		"max_total_blockers": 0,
		"max_tracking_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	var history_file: String = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json"))).strip_edges()
	if history_file.begins_with("user://"):
		output["history_file"] = history_file
	output["window"] = maxi(5, int(row.get("window", output.get("window", 40))))
	var required_run_modes: Array[String] = _sanitize_string_array(row.get("required_run_modes", []))
	if not required_run_modes.is_empty():
		output["required_run_modes"] = required_run_modes
	var required_strategies: Array[String] = _sanitize_string_array(row.get("required_strategies", []))
	if not required_strategies.is_empty():
		output["required_strategies"] = required_strategies
	output["min_runs"] = maxi(1, int(row.get("min_runs", output.get("min_runs", 1))))
	output["max_avg_warnings"] = maxf(0.0, float(row.get("max_avg_warnings", output.get("max_avg_warnings", 1.0))))
	output["max_total_blockers"] = maxi(0, int(row.get("max_total_blockers", output.get("max_total_blockers", 0))))
	output["max_tracking_failures"] = maxi(0, int(row.get("max_tracking_failures", output.get("max_tracking_failures", 0))))
	return output


func _sanitize_release_gate_templates(raw: Variant, strategy_raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"required_strategies": [],
		"required_strategy_bindings": {},
		"ci_mode_bindings": {},
		"required_reports": [],
		"required_strategies_for_publish": [],
		"require_zero_warnings_for": [],
		"max_checklist_failures": 0,
	}
	if not (raw is Dictionary):
		return output

	var row: Dictionary = raw
	output["required_strategies"] = _sanitize_string_array(row.get("required_strategies", []))

	var strategy_bindings: Dictionary = {}
	var strategy_bindings_raw: Variant = row.get("required_strategy_bindings", {})
	if strategy_bindings_raw is Dictionary:
		for strategy_var in strategy_bindings_raw.keys():
			var strategy_name: String = str(strategy_var).strip_edges()
			var template_name: String = str(strategy_bindings_raw.get(strategy_var, "")).strip_edges()
			if strategy_name.is_empty() or template_name.is_empty():
				continue
			strategy_bindings[strategy_name] = template_name
	output["required_strategy_bindings"] = strategy_bindings

	var ci_mode_bindings: Dictionary = {}
	var ci_mode_bindings_raw: Variant = row.get("ci_mode_bindings", {})
	if ci_mode_bindings_raw is Dictionary:
		for mode_var in ci_mode_bindings_raw.keys():
			var mode_name: String = str(mode_var).strip_edges()
			var strategy_name: String = str(ci_mode_bindings_raw.get(mode_var, "")).strip_edges()
			if mode_name.is_empty() or strategy_name.is_empty():
				continue
			ci_mode_bindings[mode_name] = strategy_name
	output["ci_mode_bindings"] = ci_mode_bindings

	var release_checklist_raw: Variant = row.get("release_checklist", {})
	if release_checklist_raw is Dictionary:
		var release_checklist: Dictionary = release_checklist_raw
		output["required_reports"] = _sanitize_string_array(release_checklist.get("required_reports", []))
		output["required_strategies_for_publish"] = _sanitize_string_array(release_checklist.get("required_strategies_for_publish", []))
		output["require_zero_warnings_for"] = _sanitize_string_array(release_checklist.get("require_zero_warnings_for", []))
		output["max_checklist_failures"] = maxi(0, int(release_checklist.get("max_checklist_failures", 0)))

	var strategy_row: Dictionary = strategy_raw if strategy_raw is Dictionary else {}
	var required_strategy_rows: Array[String] = output.get("required_strategies", [])
	if required_strategy_rows.is_empty():
		var strategies_raw: Variant = strategy_row.get("strategies", {})
		if strategies_raw is Dictionary:
			output["required_strategies"] = _sanitize_string_array((strategies_raw as Dictionary).keys())

	return output


func _sanitize_report_layers(raw: Variant, snapshots_raw: Variant) -> Dictionary:
	var output: Dictionary = {}
	if not (raw is Dictionary):
		return output
	var snapshots: Dictionary = snapshots_raw if snapshots_raw is Dictionary else {}
	for layer_var in raw.keys():
		var layer_name: String = str(layer_var).strip_edges()
		if layer_name.is_empty():
			continue
		var row: Variant = raw.get(layer_var, {})
		if not (row is Dictionary):
			continue
		var snapshot_ids: Array[String] = []
		for snapshot_var in row.get("snapshot_ids", []):
			var snapshot_id: String = str(snapshot_var).strip_edges()
			if snapshot_id.is_empty():
				continue
			if not snapshots.has(snapshot_id):
				continue
			snapshot_ids.append(snapshot_id)
		if snapshot_ids.is_empty():
			continue
		output[layer_name] = {
			"snapshot_ids": snapshot_ids,
			"max_layer_blockers": maxi(0, int(row.get("max_layer_blockers", 0))),
			"max_layer_warnings": maxi(0, int(row.get("max_layer_warnings", 0))),
			"min_pass_ratio": clampf(float(row.get("min_pass_ratio", 0.0)), 0.0, 1.0),
		}
	return output


func _evaluate_release_gate_templates(
	report: Dictionary,
	release_manifest: Dictionary,
	strategy_orchestration_raw: Variant,
	strategy_name: String,
	strategy_template: String,
	run_mode: String
) -> void:
	if release_manifest.is_empty():
		return

	var manifest_row: Dictionary = report.get("release_manifest", {})
	var errors: Array = []
	var checklist_items: Array = []
	var checklist_failures: int = 0

	var required_strategies: Array[String] = _sanitize_string_array(release_manifest.get("required_strategies", []))
	var required_strategy_bindings: Dictionary = release_manifest.get("required_strategy_bindings", {})
	var ci_mode_bindings: Dictionary = release_manifest.get("ci_mode_bindings", {})
	var required_reports: Array[String] = _sanitize_string_array(release_manifest.get("required_reports", []))
	var required_strategies_for_publish: Array[String] = _sanitize_string_array(release_manifest.get("required_strategies_for_publish", []))
	var require_zero_warnings_for: Array[String] = _sanitize_string_array(release_manifest.get("require_zero_warnings_for", []))
	var max_checklist_failures: int = maxi(0, int(release_manifest.get("max_checklist_failures", 0)))

	var strategy_orchestration: Dictionary = strategy_orchestration_raw if strategy_orchestration_raw is Dictionary else {}
	var strategies: Dictionary = strategy_orchestration.get("strategies", {})

	for required_strategy in required_strategies:
		if not strategies.has(required_strategy):
			errors.append("required strategy '%s' not found in strategy_orchestration.strategies" % required_strategy)

	for strategy_key_var in required_strategy_bindings.keys():
		var strategy_key: String = str(strategy_key_var).strip_edges()
		var expected_template: String = str(required_strategy_bindings.get(strategy_key_var, "")).strip_edges()
		if strategy_key.is_empty() or expected_template.is_empty():
			continue
		var strategy_row_variant: Variant = strategies.get(strategy_key, {})
		if not (strategy_row_variant is Dictionary):
			errors.append("required strategy binding '%s' has no strategy row" % strategy_key)
			continue
		var strategy_row: Dictionary = strategy_row_variant
		var actual_template: String = str(strategy_row.get("template", "")).strip_edges()
		if actual_template != expected_template:
			errors.append("required strategy binding '%s' expects template '%s' but got '%s'" % [strategy_key, expected_template, actual_template])

	if not ci_mode_bindings.is_empty() and ci_mode_bindings.has(run_mode):
		var expected_strategy: String = str(ci_mode_bindings.get(run_mode, "")).strip_edges()
		if not expected_strategy.is_empty() and strategy_name != expected_strategy:
			errors.append("run_mode '%s' expects strategy '%s' but got '%s'" % [run_mode, expected_strategy, strategy_name])

	for report_path in required_reports:
		var exists: bool = FileAccess.file_exists(report_path)
		var item: Dictionary = {
			"type": "required_report",
			"path": report_path,
			"ok": exists,
		}
		checklist_items.append(item)
		if not exists:
			checklist_failures += 1

	for publish_strategy in required_strategies_for_publish:
		var exists: bool = strategies.has(publish_strategy)
		var item: Dictionary = {
			"type": "required_publish_strategy",
			"strategy": publish_strategy,
			"ok": exists,
		}
		checklist_items.append(item)
		if not exists:
			checklist_failures += 1

	if require_zero_warnings_for.has(strategy_name):
		var warnings: int = int(report.get("warnings", 0))
		var warnings_ok: bool = warnings == 0
		checklist_items.append({
			"type": "strategy_zero_warnings",
			"strategy": strategy_name,
			"warnings": warnings,
			"ok": warnings_ok,
		})
		if not warnings_ok:
			checklist_failures += 1

	for err in errors:
		_push_result(report, "global", "release_manifest_invalid", false, str(err))

	if checklist_failures > max_checklist_failures:
		_push_result(
			report,
			"global",
			"release_manifest_checklist_failures_exceeded",
			false,
			"release manifest checklist failures %d exceeds %d" % [checklist_failures, max_checklist_failures]
		)

	manifest_row["run_mode"] = run_mode
	manifest_row["strategy"] = strategy_name
	manifest_row["template"] = strategy_template
	manifest_row["required_strategies"] = required_strategies
	manifest_row["required_strategy_bindings"] = required_strategy_bindings
	manifest_row["ci_mode_bindings"] = ci_mode_bindings
	manifest_row["max_checklist_failures"] = max_checklist_failures
	manifest_row["checklist_failures"] = checklist_failures
	manifest_row["errors"] = errors
	manifest_row["checklist_items"] = checklist_items
	report["release_manifest"] = manifest_row


func _evaluate_backend_matrix_governance(
	report: Dictionary,
	backend_matrix_governance: Dictionary,
	release_gate_templates: Dictionary,
	run_mode: String
) -> void:
	if backend_matrix_governance.is_empty():
		return

	var backend_row: Dictionary = report.get("backend_matrix", {})
	var required_backend_matrix: Array[String] = _sanitize_string_array(backend_matrix_governance.get("required_backend_matrix", []))
	var declared_backend_matrix: Array[String] = _sanitize_string_array(backend_row.get("declared_backend_matrix", []))
	var required_run_modes: Array[String] = _sanitize_string_array(backend_matrix_governance.get("required_run_modes", []))
	var max_missing_backend_matrix: int = maxi(0, int(backend_matrix_governance.get("max_missing_backend_matrix", 0)))
	var max_missing_run_mode_bindings: int = maxi(0, int(backend_matrix_governance.get("max_missing_run_mode_bindings", 0)))
	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})

	var missing_backend_matrix: Array = []
	for backend_name in required_backend_matrix:
		if not declared_backend_matrix.has(backend_name):
			missing_backend_matrix.append(backend_name)

	var missing_run_mode_bindings: Array = []
	for mode_name in required_run_modes:
		if not ci_mode_bindings.has(mode_name):
			missing_run_mode_bindings.append(mode_name)

	backend_row["required_backend_matrix"] = required_backend_matrix
	backend_row["declared_backend_matrix"] = declared_backend_matrix
	backend_row["required_run_modes"] = required_run_modes
	backend_row["missing_backend_matrix"] = missing_backend_matrix
	backend_row["missing_run_mode_bindings"] = missing_run_mode_bindings
	backend_row["max_missing_backend_matrix"] = max_missing_backend_matrix
	backend_row["max_missing_run_mode_bindings"] = max_missing_run_mode_bindings
	backend_row["run_mode"] = run_mode
	report["backend_matrix"] = backend_row

	if missing_backend_matrix.size() > max_missing_backend_matrix:
		_push_result(
			report,
			"global",
			"backend_matrix_missing_backends_exceeded",
			false,
			"missing backend matrix entries %d exceeds %d" % [missing_backend_matrix.size(), max_missing_backend_matrix]
		)

	if missing_run_mode_bindings.size() > max_missing_run_mode_bindings:
		_push_result(
			report,
			"global",
			"backend_matrix_missing_run_modes_exceeded",
			false,
			"missing run_mode bindings %d exceeds %d" % [missing_run_mode_bindings.size(), max_missing_run_mode_bindings]
		)


func _evaluate_approval_workflow(report: Dictionary, approval_workflow: Dictionary, strategy_name: String) -> void:
	if approval_workflow.is_empty():
		return

	var approval_row: Dictionary = report.get("approval", {})
	var required_sections: Array[String] = _sanitize_string_array(approval_workflow.get("required_report_sections", []))
	var require_zero_blockers: bool = bool(approval_workflow.get("require_zero_blockers", true))
	var require_zero_warnings_for: Array[String] = _sanitize_string_array(approval_workflow.get("require_zero_warnings_for_strategies", []))
	var max_approval_failures: int = maxi(0, int(approval_workflow.get("max_approval_failures", 0)))

	var checklist_items: Array = []
	var approval_failures: int = 0

	for section_name in required_sections:
		var section_ok: bool = false
		match section_name:
			"Snapshots":
				var snapshots_variant: Variant = report.get("snapshots", {})
				section_ok = snapshots_variant is Dictionary and not (snapshots_variant as Dictionary).is_empty()
			"Trend":
				section_ok = report.has("trend")
			"Whitelist":
				section_ok = report.has("whitelist")
			"Backend Attribution":
				section_ok = report.has("backend_attribution")
			"Release Manifest":
				section_ok = report.has("release_manifest")
			"Backend Matrix Governance":
				section_ok = report.has("backend_matrix")
			"Approval Workflow":
				section_ok = true
			"Approval Audit Trail":
				section_ok = report.has("approval_audit")
			"Approval History Archive":
				section_ok = report.has("approval_archive")
			"Approval Template":
				section_ok = report.has("approval_template")
			"Release Candidate Tracking":
				section_ok = report.has("release_candidate_tracking")
			_:
				section_ok = false

		checklist_items.append({
			"type": "required_report_section",
			"section": section_name,
			"ok": section_ok,
		})
		if not section_ok:
			approval_failures += 1

	if require_zero_blockers:
		var blockers_ok: bool = int(report.get("blockers", 0)) == 0
		checklist_items.append({
			"type": "zero_blockers",
			"ok": blockers_ok,
			"blockers": int(report.get("blockers", 0)),
		})
		if not blockers_ok:
			approval_failures += 1

	if require_zero_warnings_for.has(strategy_name):
		var warnings_ok: bool = int(report.get("warnings", 0)) == 0
		checklist_items.append({
			"type": "strategy_zero_warnings",
			"strategy": strategy_name,
			"warnings": int(report.get("warnings", 0)),
			"ok": warnings_ok,
		})
		if not warnings_ok:
			approval_failures += 1

	approval_row["required_report_sections"] = required_sections
	approval_row["require_zero_blockers"] = require_zero_blockers
	approval_row["require_zero_warnings_for_strategies"] = require_zero_warnings_for
	approval_row["max_approval_failures"] = max_approval_failures
	approval_row["approval_failures"] = approval_failures
	approval_row["checklist_items"] = checklist_items
	report["approval"] = approval_row

	if approval_failures > max_approval_failures:
		_push_result(
			report,
			"global",
			"approval_workflow_failures_exceeded",
			false,
			"approval failures %d exceeds %d" % [approval_failures, max_approval_failures]
		)


func _evaluate_approval_audit_trail(
	report: Dictionary,
	audit_cfg: Dictionary,
	strategy_name: String,
	run_mode: String,
	backend_tag: String
) -> void:
	if audit_cfg.is_empty():
		return

	var history_file: String = str(audit_cfg.get("history_file", "user://visual_snapshot_approval_history.json"))
	var max_entries: int = maxi(10, int(audit_cfg.get("max_entries", 80)))
	var required_run_modes: Array[String] = _sanitize_string_array(audit_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(audit_cfg.get("required_backends", []))
	var require_unique_pipeline_id: bool = bool(audit_cfg.get("require_unique_pipeline_id", true))
	var max_missing_pipeline_id: int = maxi(0, int(audit_cfg.get("max_missing_pipeline_id", 0)))
	var max_history_trace_failures: int = maxi(0, int(audit_cfg.get("max_history_trace_failures", 0)))

	var pipeline_id: String = OS.get_environment("VISUAL_PIPELINE_ID").strip_edges()
	if pipeline_id.is_empty():
		pipeline_id = OS.get_environment("GITHUB_RUN_ID").strip_edges()
	if pipeline_id.is_empty():
		pipeline_id = OS.get_environment("CI_PIPELINE_ID").strip_edges()

	var history: Array = []
	if FileAccess.file_exists(history_file):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
		if parsed is Array:
			history = parsed

	var current_record: Dictionary = {
		"timestamp": int(report.get("generated_at_unix", Time.get_unix_time_from_system())),
		"channel": str(report.get("channel", "unknown")),
		"backend_tag": backend_tag,
		"run_mode": run_mode,
		"strategy": strategy_name,
		"pipeline_id": pipeline_id,
		"blockers": int(report.get("blockers", 0)),
		"warnings": int(report.get("warnings", 0)),
		"approval_failures": int((report.get("approval", {}) as Dictionary).get("approval_failures", 0)),
	}
	history.append(current_record)
	if history.size() > max_entries:
		history = history.slice(history.size() - max_entries, history.size())

	var history_file_access: FileAccess = FileAccess.open(history_file, FileAccess.WRITE)
	if history_file_access:
		history_file_access.store_string(JSON.stringify(history, "\t"))

	var seen_run_modes: Dictionary = {}
	var seen_backends: Dictionary = {}
	var pipeline_key_counts: Dictionary = {}
	var missing_pipeline_id_count: int = 0
	for entry in history:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var mode_name: String = str(row.get("run_mode", "")).strip_edges()
		if not mode_name.is_empty():
			seen_run_modes[mode_name] = true
		var backend_name: String = str(row.get("backend_tag", "")).strip_edges()
		if not backend_name.is_empty():
			seen_backends[backend_name] = true
		var row_pipeline_id: String = str(row.get("pipeline_id", "")).strip_edges()
		if row_pipeline_id.is_empty():
			missing_pipeline_id_count += 1
		var pipeline_key: String = "%s|%s|%s" % [row_pipeline_id, mode_name, backend_name]
		pipeline_key_counts[pipeline_key] = int(pipeline_key_counts.get(pipeline_key, 0)) + 1

	var missing_run_modes: Array = []
	for mode_name in required_run_modes:
		if not seen_run_modes.has(mode_name):
			missing_run_modes.append(mode_name)

	var backend_matrix_row: Dictionary = report.get("backend_matrix", {})
	var declared_backend_matrix: Array[String] = _sanitize_string_array(backend_matrix_row.get("declared_backend_matrix", []))
	var missing_backends: Array = []
	for backend_name in required_backends:
		if not declared_backend_matrix.has(backend_name):
			missing_backends.append(backend_name)

	var duplicate_pipeline_ids: Array = []
	if require_unique_pipeline_id:
		for key_var in pipeline_key_counts.keys():
			var key: String = str(key_var)
			if key.begins_with("|"):
				continue
			if int(pipeline_key_counts.get(key, 0)) > 1:
				duplicate_pipeline_ids.append(key)

	var trace_failures: int = 0
	var items: Array = []

	items.append({
		"type": "missing_run_modes",
		"value": missing_run_modes,
		"ok": missing_run_modes.is_empty(),
	})
	if not missing_run_modes.is_empty():
		trace_failures += 1

	items.append({
		"type": "missing_backends",
		"value": missing_backends,
		"ok": missing_backends.is_empty(),
	})
	if not missing_backends.is_empty():
		trace_failures += 1

	items.append({
		"type": "missing_pipeline_id_count",
		"value": missing_pipeline_id_count,
		"limit": max_missing_pipeline_id,
		"ok": missing_pipeline_id_count <= max_missing_pipeline_id,
	})
	if missing_pipeline_id_count > max_missing_pipeline_id:
		trace_failures += 1

	if require_unique_pipeline_id:
		items.append({
			"type": "duplicate_pipeline_ids",
			"value": duplicate_pipeline_ids,
			"ok": duplicate_pipeline_ids.is_empty(),
		})
		if not duplicate_pipeline_ids.is_empty():
			trace_failures += 1

	var audit_row: Dictionary = report.get("approval_audit", {})
	audit_row["history_file"] = history_file
	audit_row["max_entries"] = max_entries
	audit_row["required_run_modes"] = required_run_modes
	audit_row["required_backends"] = required_backends
	audit_row["declared_backend_matrix"] = declared_backend_matrix
	audit_row["seen_backends"] = seen_backends.keys()
	audit_row["require_unique_pipeline_id"] = require_unique_pipeline_id
	audit_row["max_missing_pipeline_id"] = max_missing_pipeline_id
	audit_row["max_history_trace_failures"] = max_history_trace_failures
	audit_row["pipeline_id"] = pipeline_id
	audit_row["history_entries"] = history.size()
	audit_row["missing_run_modes"] = missing_run_modes
	audit_row["missing_backends"] = missing_backends
	audit_row["duplicate_pipeline_ids"] = duplicate_pipeline_ids
	audit_row["missing_pipeline_id_count"] = missing_pipeline_id_count
	audit_row["trace_failures"] = trace_failures
	audit_row["items"] = items
	report["approval_audit"] = audit_row

	if trace_failures > max_history_trace_failures:
		var message: String = "approval audit trace failures %d exceeds %d" % [trace_failures, max_history_trace_failures]
		if run_mode == "release_blocking":
			_push_result(
				report,
				"global",
				"approval_audit_trace_failures_exceeded",
				false,
				message
			)
		else:
			_push_warning(
				report,
				"global",
				"approval_audit_trace_failures_pending",
				message
			)


func _evaluate_approval_history_archive(
	report: Dictionary,
	archive_cfg: Dictionary,
	strategy_name: String,
	run_mode: String,
	backend_tag: String
) -> void:
	if archive_cfg.is_empty():
		return

	var archive_file: String = str(archive_cfg.get("archive_file", "user://visual_snapshot_approval_archive.json"))
	var max_entries: int = maxi(20, int(archive_cfg.get("max_entries", 240)))
	var aggregation_window: int = maxi(10, int(archive_cfg.get("aggregation_window", 80)))
	var required_backends: Array[String] = _sanitize_string_array(archive_cfg.get("required_backends", []))
	var required_run_modes: Array[String] = _sanitize_string_array(archive_cfg.get("required_run_modes", []))
	var max_missing_archive_backends: int = maxi(0, int(archive_cfg.get("max_missing_archive_backends", 0)))
	var max_missing_archive_run_modes: int = maxi(0, int(archive_cfg.get("max_missing_archive_run_modes", 0)))
	var max_backend_warning_delta: int = maxi(0, int(archive_cfg.get("max_backend_warning_delta", 0)))
	var max_backend_blocker_delta: int = maxi(0, int(archive_cfg.get("max_backend_blocker_delta", 0)))
	var max_archive_trace_failures: int = maxi(0, int(archive_cfg.get("max_archive_trace_failures", 0)))

	var pipeline_id: String = OS.get_environment("VISUAL_PIPELINE_ID").strip_edges()
	if pipeline_id.is_empty():
		pipeline_id = OS.get_environment("GITHUB_RUN_ID").strip_edges()
	if pipeline_id.is_empty():
		pipeline_id = OS.get_environment("CI_PIPELINE_ID").strip_edges()

	var archive_history: Array = []
	if FileAccess.file_exists(archive_file):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(archive_file))
		if parsed is Array:
			archive_history = parsed

	var approval_row: Dictionary = report.get("approval", {})
	var current_record: Dictionary = {
		"timestamp": int(report.get("generated_at_unix", Time.get_unix_time_from_system())),
		"channel": str(report.get("channel", "unknown")),
		"backend_tag": backend_tag,
		"run_mode": run_mode,
		"strategy": strategy_name,
		"pipeline_id": pipeline_id,
		"blockers": int(report.get("blockers", 0)),
		"warnings": int(report.get("warnings", 0)),
		"approval_failures": int(approval_row.get("approval_failures", 0)),
	}
	archive_history.append(current_record)
	if archive_history.size() > max_entries:
		archive_history = archive_history.slice(archive_history.size() - max_entries, archive_history.size())

	var archive_file_access: FileAccess = FileAccess.open(archive_file, FileAccess.WRITE)
	if archive_file_access:
		archive_file_access.store_string(JSON.stringify(archive_history, "\t"))

	var start_index: int = maxi(0, archive_history.size() - aggregation_window)
	var window_history: Array = archive_history.slice(start_index, archive_history.size())

	var seen_run_modes: Dictionary = {}
	var seen_backends: Dictionary = {}
	var backend_stats: Dictionary = {}
	for entry in window_history:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var mode_name: String = str(row.get("run_mode", "")).strip_edges()
		var backend_name: String = str(row.get("backend_tag", "")).strip_edges()
		if not mode_name.is_empty():
			seen_run_modes[mode_name] = true
		if not backend_name.is_empty():
			seen_backends[backend_name] = true
			var stat_row: Dictionary = backend_stats.get(backend_name, {
				"runs": 0,
				"warnings": 0,
				"blockers": 0,
			})
			stat_row["runs"] = int(stat_row.get("runs", 0)) + 1
			stat_row["warnings"] = int(stat_row.get("warnings", 0)) + int(row.get("warnings", 0))
			stat_row["blockers"] = int(stat_row.get("blockers", 0)) + int(row.get("blockers", 0))
			backend_stats[backend_name] = stat_row

	var declared_backend_matrix: Array[String] = _sanitize_string_array((report.get("backend_matrix", {}) as Dictionary).get("declared_backend_matrix", []))
	var missing_backends: Array = []
	for backend_name in required_backends:
		if not declared_backend_matrix.has(backend_name):
			missing_backends.append(backend_name)

	var missing_run_modes: Array = []
	for mode_name in required_run_modes:
		if not seen_run_modes.has(mode_name):
			missing_run_modes.append(mode_name)

	var warning_values: Array[float] = []
	var blocker_values: Array[float] = []
	for backend_name in required_backends:
		if not backend_stats.has(backend_name):
			continue
		var row: Dictionary = backend_stats.get(backend_name, {})
		warning_values.append(float(row.get("warnings", 0)))
		blocker_values.append(float(row.get("blockers", 0)))

	var backend_warning_delta: int = 0
	if warning_values.size() >= 2:
		backend_warning_delta = int(round(warning_values.max() - warning_values.min()))
	var backend_blocker_delta: int = 0
	if blocker_values.size() >= 2:
		backend_blocker_delta = int(round(blocker_values.max() - blocker_values.min()))

	var trace_failures: int = 0
	var items: Array = []

	items.append({
		"type": "missing_archive_backends",
		"value": missing_backends,
		"limit": max_missing_archive_backends,
		"ok": missing_backends.size() <= max_missing_archive_backends,
	})
	if missing_backends.size() > max_missing_archive_backends:
		trace_failures += 1

	items.append({
		"type": "missing_archive_run_modes",
		"value": missing_run_modes,
		"limit": max_missing_archive_run_modes,
		"ok": missing_run_modes.size() <= max_missing_archive_run_modes,
	})
	if missing_run_modes.size() > max_missing_archive_run_modes:
		trace_failures += 1

	items.append({
		"type": "backend_warning_delta",
		"value": backend_warning_delta,
		"limit": max_backend_warning_delta,
		"ok": backend_warning_delta <= max_backend_warning_delta,
	})
	if backend_warning_delta > max_backend_warning_delta:
		trace_failures += 1

	items.append({
		"type": "backend_blocker_delta",
		"value": backend_blocker_delta,
		"limit": max_backend_blocker_delta,
		"ok": backend_blocker_delta <= max_backend_blocker_delta,
	})
	if backend_blocker_delta > max_backend_blocker_delta:
		trace_failures += 1

	var archive_row: Dictionary = report.get("approval_archive", {})
	archive_row["archive_file"] = archive_file
	archive_row["max_entries"] = max_entries
	archive_row["aggregation_window"] = aggregation_window
	archive_row["required_backends"] = required_backends
	archive_row["required_run_modes"] = required_run_modes
	archive_row["max_missing_archive_backends"] = max_missing_archive_backends
	archive_row["max_missing_archive_run_modes"] = max_missing_archive_run_modes
	archive_row["max_backend_warning_delta"] = max_backend_warning_delta
	archive_row["max_backend_blocker_delta"] = max_backend_blocker_delta
	archive_row["max_archive_trace_failures"] = max_archive_trace_failures
	archive_row["history_entries"] = archive_history.size()
	archive_row["window_entries"] = window_history.size()
	archive_row["missing_backends"] = missing_backends
	archive_row["missing_run_modes"] = missing_run_modes
	archive_row["backend_warning_delta"] = backend_warning_delta
	archive_row["backend_blocker_delta"] = backend_blocker_delta
	archive_row["trace_failures"] = trace_failures
	archive_row["backend_stats"] = backend_stats
	archive_row["items"] = items
	report["approval_archive"] = archive_row

	if trace_failures > max_archive_trace_failures:
		var message: String = "approval archive trace failures %d exceeds %d" % [trace_failures, max_archive_trace_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "approval_archive_trace_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "approval_archive_trace_failures_pending", message)


func _evaluate_release_candidate_tracking(report: Dictionary, tracking_cfg: Dictionary, run_mode: String) -> void:
	if tracking_cfg.is_empty():
		return

	var history_file: String = str(tracking_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var window: int = maxi(5, int(tracking_cfg.get("window", 40)))
	var required_run_modes: Array[String] = _sanitize_string_array(tracking_cfg.get("required_run_modes", []))
	var required_strategies: Array[String] = _sanitize_string_array(tracking_cfg.get("required_strategies", []))
	var min_runs: int = maxi(1, int(tracking_cfg.get("min_runs", 1)))
	var max_avg_warnings: float = maxf(0.0, float(tracking_cfg.get("max_avg_warnings", 1.0)))
	var max_total_blockers: int = maxi(0, int(tracking_cfg.get("max_total_blockers", 0)))
	var max_tracking_failures: int = maxi(0, int(tracking_cfg.get("max_tracking_failures", 0)))

	var archive_history: Array = []
	if FileAccess.file_exists(history_file):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
		if parsed is Array:
			archive_history = parsed

	var start_index: int = maxi(0, archive_history.size() - window)
	var window_history: Array = archive_history.slice(start_index, archive_history.size())

	var matching_runs: int = 0
	var warning_sum: float = 0.0
	var blocker_sum: int = 0
	var seen_run_modes: Dictionary = {}
	var seen_strategies: Dictionary = {}
	for entry in window_history:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var mode_name: String = str(row.get("run_mode", "")).strip_edges()
		var strategy_name: String = str(row.get("strategy", "")).strip_edges()
		var mode_ok: bool = required_run_modes.is_empty() or required_run_modes.has(mode_name)
		var strategy_ok: bool = required_strategies.is_empty() or required_strategies.has(strategy_name)
		if mode_ok and strategy_ok:
			matching_runs += 1
			warning_sum += float(row.get("warnings", 0))
			blocker_sum += int(row.get("blockers", 0))
		if mode_ok and not mode_name.is_empty():
			seen_run_modes[mode_name] = true
		if strategy_ok and not strategy_name.is_empty():
			seen_strategies[strategy_name] = true

	var avg_warnings: float = 0.0
	if matching_runs > 0:
		avg_warnings = warning_sum / float(matching_runs)

	var tracking_items: Array = []
	var tracking_failures: int = 0

	tracking_items.append({
		"type": "min_runs",
		"value": matching_runs,
		"limit": min_runs,
		"ok": matching_runs >= min_runs,
	})
	if matching_runs < min_runs:
		tracking_failures += 1

	tracking_items.append({
		"type": "max_avg_warnings",
		"value": avg_warnings,
		"limit": max_avg_warnings,
		"ok": avg_warnings <= max_avg_warnings,
	})
	if avg_warnings > max_avg_warnings:
		tracking_failures += 1

	tracking_items.append({
		"type": "max_total_blockers",
		"value": blocker_sum,
		"limit": max_total_blockers,
		"ok": blocker_sum <= max_total_blockers,
	})
	if blocker_sum > max_total_blockers:
		tracking_failures += 1

	var missing_run_modes: Array = []
	for mode_name in required_run_modes:
		if not seen_run_modes.has(mode_name):
			missing_run_modes.append(mode_name)
	tracking_items.append({
		"type": "missing_run_modes",
		"value": missing_run_modes,
		"ok": missing_run_modes.is_empty(),
	})
	if not missing_run_modes.is_empty():
		tracking_failures += 1

	var missing_strategies: Array = []
	for strategy_name in required_strategies:
		if not seen_strategies.has(strategy_name):
			missing_strategies.append(strategy_name)
	tracking_items.append({
		"type": "missing_strategies",
		"value": missing_strategies,
		"ok": missing_strategies.is_empty(),
	})
	if not missing_strategies.is_empty():
		tracking_failures += 1

	var tracking_row: Dictionary = report.get("release_candidate_tracking", {})
	tracking_row["history_file"] = history_file
	tracking_row["window"] = window
	tracking_row["required_run_modes"] = required_run_modes
	tracking_row["required_strategies"] = required_strategies
	tracking_row["min_runs"] = min_runs
	tracking_row["max_avg_warnings"] = max_avg_warnings
	tracking_row["max_total_blockers"] = max_total_blockers
	tracking_row["max_tracking_failures"] = max_tracking_failures
	tracking_row["matching_runs"] = matching_runs
	tracking_row["avg_warnings"] = avg_warnings
	tracking_row["total_blockers"] = blocker_sum
	tracking_row["tracking_failures"] = tracking_failures
	tracking_row["items"] = tracking_items
	tracking_row["run_mode"] = run_mode
	report["release_candidate_tracking"] = tracking_row

	if tracking_failures > max_tracking_failures:
		var message: String = "release candidate tracking failures %d exceeds %d" % [tracking_failures, max_tracking_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "release_candidate_tracking_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "release_candidate_tracking_failures_pending", message)


func _sanitize_cross_version_baseline(raw: Variant, snapshots_raw: Variant) -> Dictionary:
	var output: Dictionary = {}
	if not (raw is Dictionary):
		return output
	var snapshots: Dictionary = snapshots_raw if snapshots_raw is Dictionary else {}
	var reference_channels: Array[String] = _sanitize_string_array(raw.get("reference_channels", []))
	if reference_channels.is_empty():
		return output
	var max_drift_raw: Variant = raw.get("max_drift", {})
	if not (max_drift_raw is Dictionary):
		return output
	var max_drift: Dictionary = max_drift_raw
	var snapshot_references_raw: Variant = raw.get("snapshot_references", {})
	if not (snapshot_references_raw is Dictionary):
		return output
	var snapshot_references: Dictionary = {}
	for snapshot_var in snapshot_references_raw.keys():
		var snapshot_id: String = str(snapshot_var).strip_edges()
		if snapshot_id.is_empty() or not snapshots.has(snapshot_id):
			continue
		var row_variant: Variant = snapshot_references_raw.get(snapshot_var, {})
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var ref_row: Dictionary = {}
		for metric_key in ["opaque_ratio", "unique_colors", "avg_luma"]:
			var metric_variant: Variant = row.get(metric_key, {})
			if not (metric_variant is Dictionary):
				continue
			var metric_refs: Dictionary = metric_variant
			var metric_output: Dictionary = {}
			for channel_name in reference_channels:
				if not metric_refs.has(channel_name):
					continue
				metric_output[channel_name] = float(metric_refs.get(channel_name, 0.0))
			if not metric_output.is_empty():
				ref_row[metric_key] = metric_output
		if not ref_row.is_empty():
			snapshot_references[snapshot_id] = ref_row
	if snapshot_references.is_empty():
		return output
	output = {
		"reference_channels": reference_channels,
		"max_drift": {
			"opaque_ratio": clampf(float(max_drift.get("opaque_ratio", 1.0)), 0.0, 1.0),
			"unique_color_ratio": clampf(float(max_drift.get("unique_color_ratio", 1.0)), 0.0, 1.0),
			"avg_luma": clampf(float(max_drift.get("avg_luma", 1.0)), 0.0, 1.0),
		},
		"max_violations": maxi(0, int(raw.get("max_violations", 0))),
		"snapshot_references": snapshot_references,
	}
	return output


func _evaluate_cross_version_baseline(report: Dictionary, baseline: Dictionary) -> void:
	if baseline.is_empty():
		return
	var snapshots: Dictionary = report.get("snapshots", {})
	var reference_channels: Array[String] = _sanitize_string_array(baseline.get("reference_channels", []))
	var max_drift: Dictionary = baseline.get("max_drift", {})
	var snapshot_references: Dictionary = baseline.get("snapshot_references", {})
	var max_violations: int = int(baseline.get("max_violations", 0))

	var cross_row: Dictionary = report.get("cross_version", {})
	var checked: int = int(cross_row.get("checked", 0))
	var violations: int = int(cross_row.get("violations", 0))
	var items: Array = cross_row.get("items", [])

	var max_opaque_drift: float = float(max_drift.get("opaque_ratio", 1.0))
	var max_unique_drift: float = float(max_drift.get("unique_color_ratio", 1.0))
	var max_luma_drift: float = float(max_drift.get("avg_luma", 1.0))

	for snapshot_var in snapshot_references.keys():
		var snapshot_id: String = str(snapshot_var)
		var references_variant: Variant = snapshot_references.get(snapshot_var, {})
		if not (references_variant is Dictionary):
			continue
		if not snapshots.has(snapshot_id):
			_push_result(report, snapshot_id, "cross_version_snapshot_missing", false, "snapshot missing for cross-version baseline compare")
			continue
		var references: Dictionary = references_variant
		var current_metrics_variant: Variant = snapshots.get(snapshot_id, {})
		if not (current_metrics_variant is Dictionary):
			continue
		var current_metrics: Dictionary = current_metrics_variant

		for metric_key in ["opaque_ratio", "unique_colors", "avg_luma"]:
			if not references.has(metric_key):
				continue
			var metric_refs_variant: Variant = references.get(metric_key, {})
			if not (metric_refs_variant is Dictionary):
				continue
			var metric_refs: Dictionary = metric_refs_variant
			var current_value: float = float(current_metrics.get(metric_key, 0.0))
			for channel_name in reference_channels:
				if not metric_refs.has(channel_name):
					continue
				var baseline_value: float = float(metric_refs.get(channel_name, current_value))
				checked += 1
				var drift: float = 0.0
				var drift_limit: float = 1.0
				if metric_key == "unique_colors":
					drift = absf(current_value - baseline_value) / maxf(1.0, baseline_value)
					drift_limit = max_unique_drift
				elif metric_key == "opaque_ratio":
					drift = absf(current_value - baseline_value)
					drift_limit = max_opaque_drift
				else:
					drift = absf(current_value - baseline_value)
					drift_limit = max_luma_drift

				if drift > drift_limit:
					violations += 1
					items.append({
						"snapshot": snapshot_id,
						"metric": metric_key,
						"reference_channel": channel_name,
						"current": current_value,
						"baseline": baseline_value,
						"drift": drift,
						"limit": drift_limit,
					})
					_push_warning(report, snapshot_id, "cross_version_%s_%s" % [metric_key, channel_name], "cross-version drift %.3f exceeds %.3f (%s)" % [drift, drift_limit, channel_name])

	cross_row["checked"] = checked
	cross_row["violations"] = violations
	cross_row["items"] = items
	cross_row["max_violations"] = max_violations
	report["cross_version"] = cross_row

	if violations > max_violations:
		_push_result(report, "global", "cross_version_max_violations_exceeded", false, "cross-version violations %d exceeds %d" % [violations, max_violations])


func _summarize_snapshot_status(report: Dictionary, snapshots: Dictionary) -> Dictionary:
	var status_map: Dictionary = {}
	for snapshot_var in snapshots.keys():
		var snapshot_id: String = str(snapshot_var)
		status_map[snapshot_id] = {
			"blockers": 0,
			"warnings": 0,
		}
	var items: Array = report.get("items", [])
	for item in items:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var snapshot_id: String = str(row.get("snapshot", ""))
		if not status_map.has(snapshot_id):
			continue
		if bool(row.get("passed", false)):
			continue
		var status_row: Dictionary = status_map.get(snapshot_id, {})
		if str(row.get("severity", "blocker")) == "warning":
			status_row["warnings"] = int(status_row.get("warnings", 0)) + 1
		else:
			status_row["blockers"] = int(status_row.get("blockers", 0)) + 1
		status_map[snapshot_id] = status_row
	return status_map


func _evaluate_report_layers(report: Dictionary, layer_defs: Dictionary, snapshots: Dictionary) -> void:
	if layer_defs.is_empty():
		return
	var status_map: Dictionary = _summarize_snapshot_status(report, snapshots)
	var layers_report: Dictionary = {}
	for layer_var in layer_defs.keys():
		var layer_name: String = str(layer_var)
		var def_variant: Variant = layer_defs.get(layer_var, {})
		if not (def_variant is Dictionary):
			continue
		var layer_def: Dictionary = def_variant
		var snapshot_ids: Array[String] = _sanitize_string_array(layer_def.get("snapshot_ids", []))
		if snapshot_ids.is_empty():
			continue

		var blockers: int = 0
		var warnings: int = 0
		var passed_count: int = 0
		for snapshot_id in snapshot_ids:
			var row: Dictionary = status_map.get(snapshot_id, {"blockers": 0, "warnings": 0})
			blockers += int(row.get("blockers", 0))
			warnings += int(row.get("warnings", 0))
			if int(row.get("blockers", 0)) == 0:
				passed_count += 1

		var total: int = snapshot_ids.size()
		var pass_ratio: float = float(passed_count) / maxf(1.0, float(total))
		layers_report[layer_name] = {
			"snapshots": total,
			"passed": passed_count,
			"pass_ratio": pass_ratio,
			"blockers": blockers,
			"warnings": warnings,
			"max_layer_blockers": int(layer_def.get("max_layer_blockers", 0)),
			"max_layer_warnings": int(layer_def.get("max_layer_warnings", 0)),
			"min_pass_ratio": float(layer_def.get("min_pass_ratio", 0.0)),
		}

		if blockers > int(layer_def.get("max_layer_blockers", 0)):
			_push_result(report, "global", "layer_%s_blockers_exceeded" % layer_name, false, "layer %s blockers %d exceeds %d" % [layer_name, blockers, int(layer_def.get("max_layer_blockers", 0))])
		if warnings > int(layer_def.get("max_layer_warnings", 0)):
			_push_result(report, "global", "layer_%s_warnings_exceeded" % layer_name, false, "layer %s warnings %d exceeds %d" % [layer_name, warnings, int(layer_def.get("max_layer_warnings", 0))])
		if pass_ratio < float(layer_def.get("min_pass_ratio", 0.0)):
			_push_result(report, "global", "layer_%s_pass_ratio_below_min" % layer_name, false, "layer %s pass_ratio %.3f below %.3f" % [layer_name, pass_ratio, float(layer_def.get("min_pass_ratio", 0.0))])

	report["layers"] = layers_report


func _apply_snapshot_setup(instance: Node, setup: String) -> void:
	if setup.is_empty() or setup == "none":
		return
	if setup.begins_with("chapter_"):
		_apply_game_world_chapter_setup(instance, setup)


func _apply_game_world_chapter_setup(instance: Node, chapter_id: String) -> void:
	if not instance.has_method("_get_chapter_id_for_room"):
		return

	var room_index: int = _find_chapter_room_index(instance, chapter_id)
	instance.set("_room_index", room_index)
	instance.set("_current_room_type", "combat")
	instance.set("_room_active", false)

	if instance.has_method("_apply_room_theme"):
		instance.call("_apply_room_theme", room_index)
	if instance.has_method("_render_ground_tiles_for_room"):
		instance.call("_render_ground_tiles_for_room", room_index)
	if instance.has_method("_render_ground_detail_tiles_for_room"):
		instance.call("_render_ground_detail_tiles_for_room", room_index)
	if instance.has_method("_render_door_tiles"):
		instance.call("_render_door_tiles", false)
	if instance.has_method("_render_hazard_tiles"):
		instance.call("_render_hazard_tiles")
	if instance.has_method("_render_ambient_fx_tiles"):
		instance.call("_render_ambient_fx_tiles")
	if instance.has_method("_update_environment_visuals"):
		instance.call("_update_environment_visuals", 0.16)
		instance.call("_update_environment_visuals", 0.16)


func _find_chapter_room_index(instance: Node, chapter_id: String) -> int:
	var fallback: Dictionary = {
		"chapter_1": 1,
		"chapter_2": 4,
		"chapter_3": 7,
		"chapter_4": 10,
	}
	var run_plan_variant: Variant = instance.get("_run_plan")
	if run_plan_variant is Dictionary:
		var run_plan: Dictionary = run_plan_variant
		var rooms_variant: Variant = run_plan.get("rooms", [])
		if rooms_variant is Array:
			var rooms: Array = rooms_variant
			for room_variant in rooms:
				if room_variant is Dictionary:
					var room_row: Dictionary = room_variant
					if str(room_row.get("chapter_id", "")) == chapter_id:
						return maxi(1, int(room_row.get("index", 1)))
	return int(fallback.get(chapter_id, 1))


func _compute_image_metrics(image: Image) -> Dictionary:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var sample_step: int = 2
	var sampled_pixels: int = 0
	var opaque_pixels: int = 0
	var luma_sum: float = 0.0
	var color_buckets: Dictionary = {}

	for y in range(0, height, sample_step):
		for x in range(0, width, sample_step):
			var color: Color = image.get_pixel(x, y)
			sampled_pixels += 1
			var rgba: int = int(color.to_rgba32())
			var quantized: int = rgba & 0xF0F0F0F0
			color_buckets[quantized] = true
			if color.a > 0.05:
				opaque_pixels += 1
				luma_sum += (color.r + color.g + color.b) / 3.0

	var opaque_ratio: float = 0.0
	if sampled_pixels > 0:
		opaque_ratio = float(opaque_pixels) / float(sampled_pixels)

	var avg_luma: float = 0.0
	if opaque_pixels > 0:
		avg_luma = luma_sum / float(opaque_pixels)

	return {
		"width": width,
		"height": height,
		"sampled_pixels": sampled_pixels,
		"opaque_pixels": opaque_pixels,
		"opaque_ratio": opaque_ratio,
		"unique_colors": color_buckets.size(),
		"avg_luma": avg_luma,
	}


func _compute_fallback_scene_metrics(instance: Node, width: int, height: int) -> Dictionary:
	var total_canvas: int = 0
	var visible_canvas: int = 0
	var tilemap_count: int = 0
	var luma_sum: float = 0.0
	var color_buckets: Dictionary = {}

	var stack: Array[Node] = [instance]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			if child is Node:
				stack.append(child)

		if node is CanvasItem:
			total_canvas += 1
			var canvas: CanvasItem = node
			if canvas.visible:
				visible_canvas += 1
			var color: Color = canvas.modulate
			luma_sum += (color.r + color.g + color.b) / 3.0
			color_buckets[int(color.to_rgba32()) & 0xF0F0F0F0] = true
		if node is TileMap:
			tilemap_count += 1

	var total_weight: int = max(1, total_canvas + tilemap_count * 6)
	var opaque_weight: int = visible_canvas + tilemap_count * 5
	var opaque_ratio: float = clampf(float(opaque_weight) / float(total_weight), 0.15, 0.95)
	var avg_luma: float = 0.5
	if total_canvas > 0:
		avg_luma = clampf(luma_sum / float(total_canvas), 0.05, 0.95)
	var unique_colors: int = maxi(12, color_buckets.size() * 4 + tilemap_count * 10 + int(float(total_canvas) * 0.5))

	return {
		"width": width,
		"height": height,
		"sampled_pixels": width * height,
		"opaque_pixels": int(float(width * height) * opaque_ratio),
		"opaque_ratio": opaque_ratio,
		"unique_colors": unique_colors,
		"avg_luma": avg_luma,
		"fallback": true,
	}


func _sanitize_snapshot_id(raw_id: String) -> String:
	var output: String = raw_id.strip_edges()
	if output.is_empty():
		return "snapshot"
	output = output.replace("/", "_")
	output = output.replace("\\", "_")
	output = output.replace(":", "_")
	output = output.replace(" ", "_")
	return output


func _wait_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await process_frame


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


func _push_warning(report: Dictionary, snapshot_id: String, rule_id: String, message: String) -> void:
	_push_result(report, snapshot_id, rule_id, false, message, "warning")


func _push_result(
	report: Dictionary,
	snapshot_id: String,
	rule_id: String,
	passed: bool,
	message: String,
	severity: String = "blocker"
) -> void:
	var items: Array = report.get("items", [])
	items.append(
		{
			"snapshot": snapshot_id,
			"id": rule_id,
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
	lines.append("# Visual Snapshot Regression Report")
	lines.append("")
	lines.append("- channel: %s" % str(report.get("channel", "unknown")))
	lines.append("- backend_tag: %s" % str(report.get("backend_tag", "default")))
	var strategy_row: Dictionary = report.get("strategy", {})
	var strategy_errors: Array = strategy_row.get("errors", [])
	lines.append("- strategy: %s (template=%s, errors=%d)" % [
		str(strategy_row.get("name", "default")),
		str(strategy_row.get("template", "base")),
		strategy_errors.size(),
	])
	lines.append("- checked: %d" % int(report.get("checked", 0)))
	lines.append("- passed: %d" % int(report.get("passed", 0)))
	lines.append("- blockers: %d" % int(report.get("blockers", 0)))
	lines.append("- warnings: %d" % int(report.get("warnings", 0)))
	var precision_row: Dictionary = report.get("precision", {})
	lines.append("- precision: rounds=%d, opaque_stddev<=%.4f, luma_stddev<=%.4f, unique_stddev_ratio<=%.4f" % [
		int(precision_row.get("sample_rounds", 1)),
		float(precision_row.get("max_opaque_ratio_stddev", 1.0)),
		float(precision_row.get("max_luma_stddev", 1.0)),
		float(precision_row.get("max_unique_color_stddev_ratio", 1.0)),
	])
	var whitelist_row: Dictionary = report.get("whitelist", {})
	lines.append("- whitelist: hits=%d/%d, ratio=%.3f/%.3f" % [
		int(whitelist_row.get("hits", 0)),
		int(whitelist_row.get("max_hits", 0)),
		float(whitelist_row.get("ratio", 0.0)),
		float(whitelist_row.get("max_ratio", 0.0)),
	])
	var attribution_row: Dictionary = report.get("backend_attribution", {})
	lines.append("- backend_attribution: backend=%s, regressions=%d, backend_specific=%d/%d, unattributed=%d/%d" % [
		str(attribution_row.get("backend_tag", "")),
		int(attribution_row.get("regressions", 0)),
		int(attribution_row.get("backend_specific_regressions", 0)),
		int(attribution_row.get("max_backend_specific_regressions", 0)),
		int(attribution_row.get("unattributed_regressions", 0)),
		int(attribution_row.get("max_unattributed_regressions", 0)),
	])
	var convergence_items_summary: Array = whitelist_row.get("convergence_suggestions", [])
	lines.append("- whitelist_convergence: suggestions=%d (stale_run_threshold=%d, tighten_margin_ratio=%.2f)" % [
		convergence_items_summary.size(),
		int(whitelist_row.get("stale_run_threshold", 0)),
		float(whitelist_row.get("tighten_margin_ratio", 0.0)),
	])
	var expired_entries_summary: Array = whitelist_row.get("expired_entries", [])
	var reclaim_candidates_summary: Array = whitelist_row.get("reclaim_candidates", [])
	lines.append("- exception_lifecycle: expired=%d/%d, reclaim_candidates=%d/%d" % [
		expired_entries_summary.size(),
		int(whitelist_row.get("max_expired_entries", 0)),
		reclaim_candidates_summary.size(),
		int(whitelist_row.get("max_reclaim_candidates", 0)),
	])
	var cross_row: Dictionary = report.get("cross_version", {})
	lines.append("- cross_version: checked=%d, violations=%d/%d" % [
		int(cross_row.get("checked", 0)),
		int(cross_row.get("violations", 0)),
		int(cross_row.get("max_violations", 0)),
	])
	var release_manifest_row: Dictionary = report.get("release_manifest", {})
	var release_manifest_errors: Array = release_manifest_row.get("errors", [])
	lines.append("- release_manifest: run_mode=%s, strategy=%s/%s, checklist_failures=%d/%d, errors=%d" % [
		str(release_manifest_row.get("run_mode", "rehearsal")),
		str(release_manifest_row.get("strategy", "default")),
		str(release_manifest_row.get("template", "base")),
		int(release_manifest_row.get("checklist_failures", 0)),
		int(release_manifest_row.get("max_checklist_failures", 0)),
		release_manifest_errors.size(),
	])
	var backend_matrix_row: Dictionary = report.get("backend_matrix", {})
	var missing_backend_matrix: Array = backend_matrix_row.get("missing_backend_matrix", [])
	var missing_run_mode_bindings: Array = backend_matrix_row.get("missing_run_mode_bindings", [])
	lines.append("- backend_matrix_governance: backend=%s, missing_backends=%d/%d, missing_run_modes=%d/%d" % [
		str(backend_matrix_row.get("backend_tag", "")),
		missing_backend_matrix.size(),
		int(backend_matrix_row.get("max_missing_backend_matrix", 0)),
		missing_run_mode_bindings.size(),
		int(backend_matrix_row.get("max_missing_run_mode_bindings", 0)),
	])
	var approval_row: Dictionary = report.get("approval", {})
	lines.append("- approval_workflow: failures=%d/%d, require_zero_blockers=%s" % [
		int(approval_row.get("approval_failures", 0)),
		int(approval_row.get("max_approval_failures", 0)),
		str(bool(approval_row.get("require_zero_blockers", true))),
	])
	var approval_audit_row: Dictionary = report.get("approval_audit", {})
	lines.append("- approval_audit: history_entries=%d, trace_failures=%d/%d, pipeline_id=%s" % [
		int(approval_audit_row.get("history_entries", 0)),
		int(approval_audit_row.get("trace_failures", 0)),
		int(approval_audit_row.get("max_history_trace_failures", 0)),
		str(approval_audit_row.get("pipeline_id", "")),
	])
	var approval_archive_row: Dictionary = report.get("approval_archive", {})
	lines.append("- approval_archive: history_entries=%d, window_entries=%d, trace_failures=%d/%d" % [
		int(approval_archive_row.get("history_entries", 0)),
		int(approval_archive_row.get("window_entries", 0)),
		int(approval_archive_row.get("trace_failures", 0)),
		int(approval_archive_row.get("max_archive_trace_failures", 0)),
	])
	var approval_template_row: Dictionary = report.get("approval_template", {})
	lines.append("- approval_template: run_mode=%s, template=%s, errors=%d" % [
		str(approval_template_row.get("run_mode", "rehearsal")),
		str(approval_template_row.get("template", "standard")),
		(approval_template_row.get("errors", []) as Array).size(),
	])
	var tracking_row: Dictionary = report.get("release_candidate_tracking", {})
	lines.append("- release_candidate_tracking: matching_runs=%d, avg_warnings=%.3f/%.3f, blockers=%d/%d, failures=%d/%d" % [
		int(tracking_row.get("matching_runs", 0)),
		float(tracking_row.get("avg_warnings", 0.0)),
		float(tracking_row.get("max_avg_warnings", 0.0)),
		int(tracking_row.get("total_blockers", 0)),
		int(tracking_row.get("max_total_blockers", 0)),
		int(tracking_row.get("tracking_failures", 0)),
		int(tracking_row.get("max_tracking_failures", 0)),
	])
	lines.append("")
	lines.append("## Snapshots")
	var snapshots: Dictionary = report.get("snapshots", {})
	for snapshot_id in snapshots.keys():
		var row: Dictionary = snapshots.get(snapshot_id, {})
		lines.append(
			"- %s: opaque_ratio=%.3f, unique_colors=%d, avg_luma=%.3f, mode=%s, stddev(o=%.4f,l=%.4f,u=%.4f), image=%s" % [
				str(snapshot_id),
				float(row.get("opaque_ratio", 0.0)),
				int(row.get("unique_colors", 0)),
				float(row.get("avg_luma", 0.0)),
				str(row.get("capture_mode", "unknown")),
				float(row.get("opaque_ratio_stddev", 0.0)),
				float(row.get("avg_luma_stddev", 0.0)),
				float(row.get("unique_color_stddev_ratio", 0.0)),
				str(row.get("image_path", "")),
			]
		)

	lines.append("")
	lines.append("## Trend")
	var trend: Dictionary = report.get("trend", {})
	lines.append("- regressions: %d" % int(trend.get("regressions", 0)))
	var opaque_drops: Dictionary = trend.get("opaque_ratio_drops", {})
	for snapshot_id in opaque_drops.keys():
		lines.append("- opaque_drop %s: %.3f" % [str(snapshot_id), float(opaque_drops.get(snapshot_id, 0.0))])
	var color_drops: Dictionary = trend.get("unique_color_drop_ratios", {})
	for snapshot_id in color_drops.keys():
		lines.append("- unique_color_drop_ratio %s: %.3f" % [str(snapshot_id), float(color_drops.get(snapshot_id, 0.0))])
	var luma_deltas: Dictionary = trend.get("luma_deltas", {})
	for snapshot_id in luma_deltas.keys():
		lines.append("- luma_delta %s: %.3f" % [str(snapshot_id), float(luma_deltas.get(snapshot_id, 0.0))])

	lines.append("")
	lines.append("## Whitelist")
	var whitelist_items: Array = whitelist_row.get("items", [])
	for item in whitelist_items:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- %s / %s: actual=%.3f default=%.3f whitelist=%.3f reason=%s" % [
				str(row.get("snapshot", "")),
				str(row.get("id", "")),
				float(row.get("actual", 0.0)),
				float(row.get("default_limit", 0.0)),
				float(row.get("effective_limit", 0.0)),
				str(row.get("reason", "")),
			])

	lines.append("")
	lines.append("## Whitelist Convergence")
	var convergence_items: Array = whitelist_row.get("convergence_suggestions", [])
	for item in convergence_items:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- %s / %s: streak=%d actual=%.3f current_limit=%.3f -> suggested_limit=%.3f (default=%.3f, reason=%s)" % [
				str(row.get("snapshot", "")),
				str(row.get("id", "")),
				int(row.get("streak", 0)),
				float(row.get("actual", 0.0)),
				float(row.get("current_limit", 0.0)),
				float(row.get("suggested_limit", 0.0)),
				float(row.get("default_limit", 0.0)),
				str(row.get("reason", "")),
			])

	lines.append("")
	lines.append("## Exception Lifecycle")
	var expired_entries: Array = whitelist_row.get("expired_entries", [])
	for item in expired_entries:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- expired %s / %s: idle_runs=%d (threshold=%d)" % [
				str(row.get("snapshot", "")),
				str(row.get("id", "")),
				int(row.get("idle_runs", 0)),
				int(row.get("expire_idle_runs", 0)),
			])
	var reclaim_candidates: Array = whitelist_row.get("reclaim_candidates", [])
	for item in reclaim_candidates:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- reclaim %s / %s: hit_streak=%d (threshold=%d), current_limit=%.3f, suggested_limit=%.3f, reason=%s" % [
				str(row.get("snapshot", "")),
				str(row.get("id", "")),
				int(row.get("hit_streak", 0)),
				int(row.get("auto_reclaim_hit_streak", 0)),
				float(row.get("current_limit", 0.0)),
				float(row.get("suggested_limit", 0.0)),
				str(row.get("reason", "")),
			])

	lines.append("")
	lines.append("## Backend Attribution")
	var attribution_items: Array = attribution_row.get("items", [])
	for item in attribution_items:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- %s / %s: mode=%s attribution=%s" % [
				str(row.get("snapshot", "")),
				str(row.get("id", "")),
				str(row.get("capture_mode", "unknown")),
				str(row.get("attribution", "unattributed")),
			])

	lines.append("")
	lines.append("## Cross Version")
	var cross_items: Array = cross_row.get("items", [])
	for item in cross_items:
		if item is Dictionary:
			var row: Dictionary = item
			lines.append("- %s / %s (%s): current=%.3f baseline=%.3f drift=%.3f limit=%.3f" % [
				str(row.get("snapshot", "")),
				str(row.get("metric", "")),
				str(row.get("reference_channel", "")),
				float(row.get("current", 0.0)),
				float(row.get("baseline", 0.0)),
				float(row.get("drift", 0.0)),
				float(row.get("limit", 0.0)),
			])

	lines.append("")
	lines.append("## Layers")
	var layers: Dictionary = report.get("layers", {})
	for layer_name in layers.keys():
		var row: Dictionary = layers.get(layer_name, {})
		lines.append("- %s: snapshots=%d, passed=%d, pass_ratio=%.3f/%.3f, blockers=%d/%d, warnings=%d/%d" % [
			str(layer_name),
			int(row.get("snapshots", 0)),
			int(row.get("passed", 0)),
			float(row.get("pass_ratio", 0.0)),
			float(row.get("min_pass_ratio", 0.0)),
			int(row.get("blockers", 0)),
			int(row.get("max_layer_blockers", 0)),
			int(row.get("warnings", 0)),
			int(row.get("max_layer_warnings", 0)),
		])

	lines.append("")
	lines.append("## Release Manifest")
	var manifest_errors: Array = release_manifest_row.get("errors", [])
	for err in manifest_errors:
		lines.append("- error: %s" % str(err))
	var checklist_items: Array = release_manifest_row.get("checklist_items", [])
	for item in checklist_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			var item_type: String = str(row.get("type", ""))
			if item_type == "required_report":
				lines.append("- [%s] report %s" % [status, str(row.get("path", ""))])
			elif item_type == "required_publish_strategy":
				lines.append("- [%s] publish_strategy %s" % [status, str(row.get("strategy", ""))])
			elif item_type == "strategy_zero_warnings":
				lines.append("- [%s] strategy_zero_warnings %s warnings=%d" % [status, str(row.get("strategy", "")), int(row.get("warnings", 0))])

	lines.append("")
	lines.append("## Backend Matrix Governance")
	var declared_backend_matrix: Array = backend_matrix_row.get("declared_backend_matrix", [])
	var required_backend_matrix: Array = backend_matrix_row.get("required_backend_matrix", [])
	var required_run_modes: Array = backend_matrix_row.get("required_run_modes", [])
	lines.append("- declared_backend_matrix: %s" % ", ".join(_sanitize_string_array(declared_backend_matrix)))
	lines.append("- required_backend_matrix: %s" % ", ".join(_sanitize_string_array(required_backend_matrix)))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(required_run_modes)))
	for backend_name in missing_backend_matrix:
		lines.append("- missing_backend: %s" % str(backend_name))
	for run_mode_name in missing_run_mode_bindings:
		lines.append("- missing_run_mode_binding: %s" % str(run_mode_name))

	lines.append("")
	lines.append("## Approval Workflow")
	var approval_items: Array = approval_row.get("checklist_items", [])
	for item in approval_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			var item_type: String = str(row.get("type", ""))
			if item_type == "required_report_section":
				lines.append("- [%s] section %s" % [status, str(row.get("section", ""))])
			elif item_type == "zero_blockers":
				lines.append("- [%s] zero_blockers blockers=%d" % [status, int(row.get("blockers", 0))])
			elif item_type == "strategy_zero_warnings":
				lines.append("- [%s] strategy_zero_warnings %s warnings=%d" % [status, str(row.get("strategy", "")), int(row.get("warnings", 0))])

	lines.append("")
	lines.append("## Approval Audit Trail")
	lines.append("- history_file: %s" % str(approval_audit_row.get("history_file", "")))
	lines.append("- history_entries: %d" % int(approval_audit_row.get("history_entries", 0)))
	lines.append("- pipeline_id: %s" % str(approval_audit_row.get("pipeline_id", "")))
	lines.append("- missing_run_modes: %s" % ", ".join(_sanitize_string_array(approval_audit_row.get("missing_run_modes", []))))
	lines.append("- missing_backends: %s" % ", ".join(_sanitize_string_array(approval_audit_row.get("missing_backends", []))))
	lines.append("- trace_failures: %d/%d" % [
		int(approval_audit_row.get("trace_failures", 0)),
		int(approval_audit_row.get("max_history_trace_failures", 0)),
	])
	var approval_audit_items: Array = approval_audit_row.get("items", [])
	for item in approval_audit_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Approval History Archive")
	lines.append("- archive_file: %s" % str(approval_archive_row.get("archive_file", "")))
	lines.append("- history_entries: %d" % int(approval_archive_row.get("history_entries", 0)))
	lines.append("- window_entries: %d" % int(approval_archive_row.get("window_entries", 0)))
	lines.append("- missing_run_modes: %s" % ", ".join(_sanitize_string_array(approval_archive_row.get("missing_run_modes", []))))
	lines.append("- missing_backends: %s" % ", ".join(_sanitize_string_array(approval_archive_row.get("missing_backends", []))))
	lines.append("- backend_warning_delta: %d/%d" % [
		int(approval_archive_row.get("backend_warning_delta", 0)),
		int(approval_archive_row.get("max_backend_warning_delta", 0)),
	])
	lines.append("- backend_blocker_delta: %d/%d" % [
		int(approval_archive_row.get("backend_blocker_delta", 0)),
		int(approval_archive_row.get("max_backend_blocker_delta", 0)),
	])
	lines.append("- trace_failures: %d/%d" % [
		int(approval_archive_row.get("trace_failures", 0)),
		int(approval_archive_row.get("max_archive_trace_failures", 0)),
	])
	var approval_archive_items: Array = approval_archive_row.get("items", [])
	for item in approval_archive_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Release Candidate Tracking")
	lines.append("- history_file: %s" % str(tracking_row.get("history_file", "")))
	lines.append("- matching_runs: %d" % int(tracking_row.get("matching_runs", 0)))
	lines.append("- avg_warnings: %.3f / %.3f" % [
		float(tracking_row.get("avg_warnings", 0.0)),
		float(tracking_row.get("max_avg_warnings", 0.0)),
	])
	lines.append("- total_blockers: %d / %d" % [
		int(tracking_row.get("total_blockers", 0)),
		int(tracking_row.get("max_total_blockers", 0)),
	])
	lines.append("- tracking_failures: %d / %d" % [
		int(tracking_row.get("tracking_failures", 0)),
		int(tracking_row.get("max_tracking_failures", 0)),
	])
	var tracking_items: Array = tracking_row.get("items", [])
	for item in tracking_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Items")
	var items: Array = report.get("items", [])
	for item in items:
		if item is Dictionary:
			var row: Dictionary = item
			var status: String = "PASS"
			if not bool(row.get("passed", false)):
				status = "WARN" if str(row.get("severity", "blocker")) == "warning" else "FAIL"
			lines.append("- [%s] %s / %s -> %s" % [status, str(row.get("snapshot", "")), str(row.get("id", "")), str(row.get("message", ""))])

	var markdown_file: FileAccess = FileAccess.open(REPORT_MD_PATH, FileAccess.WRITE)
	if markdown_file:
		markdown_file.store_string("\n".join(lines) + "\n")
