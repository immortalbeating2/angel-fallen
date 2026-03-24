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
	var stability_scoring: Dictionary = _sanitize_stability_scoring(targets.get("stability_scoring", {}))
	var stability_tiers: Dictionary = _sanitize_stability_tiers(targets.get("stability_tiers", {}))
	var convergence_dashboard: Dictionary = _sanitize_convergence_dashboard(targets.get("convergence_dashboard", {}))
	var ci_signal_contract: Dictionary = _sanitize_ci_signal_contract(
		targets.get("ci_signal_contract", {}),
		release_gate_templates
	)
	var convergence_trend_reinforcement: Dictionary = _sanitize_convergence_trend_reinforcement(
		targets.get("convergence_trend_reinforcement", {}),
		release_candidate_tracking,
		base_approval_history_archive
	)
	var exception_lifecycle_linkage: Dictionary = _sanitize_exception_lifecycle_linkage(
		targets.get("exception_lifecycle_linkage", {}),
		base_exception_lifecycle_cfg
	)
	var visual_performance_cogate: Dictionary = _sanitize_visual_performance_cogate(
		targets.get("visual_performance_cogate", {}),
		release_gate_templates
	)
	var cogate_threshold_templates: Dictionary = _sanitize_cogate_threshold_templates(
		targets.get("cogate_threshold_templates", {}),
		release_gate_templates
	)
	var cross_platform_alignment: Dictionary = _sanitize_cross_platform_alignment(
		targets.get("cross_platform_alignment", {}),
		base_approval_history_archive,
		release_gate_templates
	)
	var pressure_scenario_standardization: Dictionary = _sanitize_pressure_scenario_standardization(
		targets.get("pressure_scenario_standardization", {}),
		visual_performance_cogate,
		release_gate_templates
	)
	var alignment_dashboard_refinement: Dictionary = _sanitize_alignment_dashboard_refinement(
		targets.get("alignment_dashboard_refinement", {}),
		cross_platform_alignment,
		release_gate_templates
	)
	var pressure_alignment_convergence_gate: Dictionary = _sanitize_pressure_alignment_convergence_gate(
		targets.get("pressure_alignment_convergence_gate", {}),
		cross_platform_alignment,
		release_gate_templates
	)
	var regression_cycle_window_governance: Dictionary = _sanitize_regression_cycle_window_governance(
		targets.get("regression_cycle_window_governance", {}),
		base_approval_history_archive,
		release_gate_templates,
		cross_platform_alignment
	)
	var multi_cycle_adaptive_gate: Dictionary = _sanitize_multi_cycle_adaptive_gate(
		targets.get("multi_cycle_adaptive_gate", {}),
		base_approval_history_archive,
		release_gate_templates,
		cross_platform_alignment
	)
	var release_feedback_governance: Dictionary = _sanitize_release_feedback_governance(
		targets.get("release_feedback_governance", {}),
		base_approval_history_archive,
		release_gate_templates,
		cross_platform_alignment
	)
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
	var cogate_template_state: Dictionary = _resolve_cogate_threshold_template(
		cogate_threshold_templates,
		visual_performance_cogate,
		run_mode
	)
	var resolved_visual_performance_cogate: Dictionary = cogate_template_state.get("config", visual_performance_cogate)
	var cogate_template_name: String = str(cogate_template_state.get("template", ""))
	var cogate_template_errors: Array[String] = _sanitize_string_array(cogate_template_state.get("errors", []))
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
		"stability_scoring": {
			"score": 0.0,
			"tier": str(stability_tiers.get("default_tier", "D")),
			"confidence": 0.0,
			"min_confidence": float((stability_scoring.get("confidence", {}) as Dictionary).get("min_confidence", 0.4)),
			"scoring_failures": 0,
			"items": [],
		},
		"convergence_dashboard": {
			"dashboard_failures": 0,
			"max_dashboard_failures": int(convergence_dashboard.get("max_dashboard_failures", 0)),
			"items": [],
		},
		"ci_signal": {
			"required_fields": ci_signal_contract.get("required_fields", []),
			"tier_requirements": ci_signal_contract.get("tier_requirements", {}),
			"max_contract_failures": int(ci_signal_contract.get("max_contract_failures", 0)),
			"contract_failures": 0,
			"items": [],
		},
		"convergence_trend": {
			"trend_failures": 0,
			"max_trend_failures": int(convergence_trend_reinforcement.get("max_trend_failures", 0)),
			"items": [],
		},
		"exception_lifecycle_linkage": {
			"linkage_failures": 0,
			"max_linkage_failures": int(exception_lifecycle_linkage.get("max_linkage_failures", 0)),
			"items": [],
		},
		"visual_performance_cogate": {
			"required_run_modes": resolved_visual_performance_cogate.get("required_run_modes", []),
			"max_cogate_failures": int(resolved_visual_performance_cogate.get("max_cogate_failures", 0)),
			"cogate_failures": 0,
			"items": [],
		},
		"cogate_template": {
			"run_mode": run_mode,
			"template": cogate_template_name,
			"errors": cogate_template_errors,
		},
		"cross_platform_alignment": {
			"history_file": str(cross_platform_alignment.get("history_file", "user://visual_snapshot_approval_archive.json")),
			"aggregation_window": int(cross_platform_alignment.get("aggregation_window", 80)),
			"required_run_modes": cross_platform_alignment.get("required_run_modes", []),
			"required_backends": cross_platform_alignment.get("required_backends", []),
			"max_missing_backends": int(cross_platform_alignment.get("max_missing_backends", 0)),
			"max_missing_run_modes": int(cross_platform_alignment.get("max_missing_run_modes", 0)),
			"max_alignment_failures": int(cross_platform_alignment.get("max_alignment_failures", 0)),
			"alignment_failures": 0,
			"items": [],
		},
		"pressure_scenario_standardization": {
			"required_run_modes": pressure_scenario_standardization.get("required_run_modes", []),
			"required_scenarios": pressure_scenario_standardization.get("required_scenarios", []),
			"max_standardization_failures": int(pressure_scenario_standardization.get("max_standardization_failures", 0)),
			"standardization_failures": 0,
			"items": [],
		},
		"alignment_dashboard_refinement": {
			"required_run_modes": alignment_dashboard_refinement.get("required_run_modes", []),
			"max_dashboard_failures": int(alignment_dashboard_refinement.get("max_dashboard_failures", 0)),
			"dashboard_failures": 0,
			"items": [],
		},
		"pressure_alignment_convergence_gate": {
			"required_run_modes": pressure_alignment_convergence_gate.get("required_run_modes", []),
			"required_backends": pressure_alignment_convergence_gate.get("required_backends", []),
			"max_convergence_failures": int(pressure_alignment_convergence_gate.get("max_convergence_failures", 0)),
			"convergence_failures": 0,
			"items": [],
		},
		"regression_cycle_window_governance": {
			"required_run_modes": regression_cycle_window_governance.get("required_run_modes", []),
			"required_backends": regression_cycle_window_governance.get("required_backends", []),
			"cycle_window_size": int(regression_cycle_window_governance.get("cycle_window_size", 20)),
			"min_cycle_entries": int(regression_cycle_window_governance.get("min_cycle_entries", 8)),
			"max_cycle_failures": int(regression_cycle_window_governance.get("max_cycle_failures", 0)),
			"cycle_failures": 0,
			"items": [],
		},
		"multi_cycle_adaptive_gate": {
			"required_run_modes": multi_cycle_adaptive_gate.get("required_run_modes", []),
			"required_backends": multi_cycle_adaptive_gate.get("required_backends", []),
			"window_sizes": multi_cycle_adaptive_gate.get("window_sizes", {}),
			"min_window_entries": int(multi_cycle_adaptive_gate.get("min_window_entries", 6)),
			"max_adaptive_failures": int(multi_cycle_adaptive_gate.get("max_adaptive_failures", 0)),
			"adaptive_failures": 0,
			"items": [],
		},
		"release_feedback_governance": {
			"required_run_modes": release_feedback_governance.get("required_run_modes", []),
			"required_backends": release_feedback_governance.get("required_backends", []),
			"feedback_window_size": int(release_feedback_governance.get("feedback_window_size", 24)),
			"min_feedback_entries": int(release_feedback_governance.get("min_feedback_entries", 8)),
			"max_feedback_failures": int(release_feedback_governance.get("max_feedback_failures", 0)),
			"feedback_failures": 0,
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
	for cogate_error in cogate_template_errors:
		_push_result(report, "global", "cogate_threshold_template_invalid", false, cogate_error)

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
	_evaluate_stability_scoring(report, stability_scoring, stability_tiers, run_mode)
	_evaluate_convergence_dashboard(report, convergence_dashboard, run_mode)
	_evaluate_ci_signal_contract(report, ci_signal_contract, stability_tiers, run_mode)
	_evaluate_convergence_trend_reinforcement(report, convergence_trend_reinforcement, run_mode)
	_evaluate_exception_lifecycle_linkage(report, exception_lifecycle_linkage, run_mode)
	_evaluate_cogate_threshold_template(report, cogate_template_errors, run_mode)
	_evaluate_visual_performance_cogate(report, resolved_visual_performance_cogate, run_mode)
	_evaluate_cross_platform_alignment(report, cross_platform_alignment, run_mode, backend_tag)
	_evaluate_pressure_scenario_standardization(report, pressure_scenario_standardization, run_mode)
	_evaluate_alignment_dashboard_refinement(report, alignment_dashboard_refinement, run_mode)
	_evaluate_pressure_alignment_convergence_gate(report, pressure_alignment_convergence_gate, run_mode, backend_tag)
	_evaluate_regression_cycle_window_governance(report, regression_cycle_window_governance, run_mode, backend_tag)
	_evaluate_multi_cycle_adaptive_gate(report, multi_cycle_adaptive_gate, run_mode, backend_tag)
	_evaluate_release_feedback_governance(report, release_feedback_governance, run_mode, backend_tag)

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


func _sanitize_stability_scoring(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"weights": {
			"matching_runs": 0.3,
			"avg_warnings": 0.25,
			"total_blockers": 0.35,
			"tracking_failures": 0.1,
		},
		"failure_caps": {
			"max_avg_warnings": 2.0,
			"max_total_blockers": 2,
			"max_tracking_failures": 2,
		},
		"confidence": {
			"reference_runs": 8,
			"min_confidence": 0.4,
		},
		"score_round_digits": 3,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw

	var weights_raw: Variant = row.get("weights", {})
	if weights_raw is Dictionary:
		var weights: Dictionary = output.get("weights", {})
		for key in ["matching_runs", "avg_warnings", "total_blockers", "tracking_failures"]:
			if (weights_raw as Dictionary).has(key):
				weights[key] = clampf(float((weights_raw as Dictionary).get(key, weights.get(key, 0.0))), 0.0, 1.0)
		output["weights"] = weights

	var caps_raw: Variant = row.get("failure_caps", {})
	if caps_raw is Dictionary:
		var caps: Dictionary = output.get("failure_caps", {})
		caps["max_avg_warnings"] = maxf(0.1, float((caps_raw as Dictionary).get("max_avg_warnings", caps.get("max_avg_warnings", 2.0))))
		caps["max_total_blockers"] = maxi(1, int((caps_raw as Dictionary).get("max_total_blockers", caps.get("max_total_blockers", 2))))
		caps["max_tracking_failures"] = maxi(1, int((caps_raw as Dictionary).get("max_tracking_failures", caps.get("max_tracking_failures", 2))))
		output["failure_caps"] = caps

	var confidence_raw: Variant = row.get("confidence", {})
	if confidence_raw is Dictionary:
		var confidence: Dictionary = output.get("confidence", {})
		confidence["reference_runs"] = maxi(1, int((confidence_raw as Dictionary).get("reference_runs", confidence.get("reference_runs", 8))))
		confidence["min_confidence"] = clampf(float((confidence_raw as Dictionary).get("min_confidence", confidence.get("min_confidence", 0.4))), 0.0, 1.0)
		output["confidence"] = confidence

	output["score_round_digits"] = clampi(int(row.get("score_round_digits", output.get("score_round_digits", 3))), 0, 5)
	return output


func _sanitize_stability_tiers(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"default_tier": "D",
		"tiers": [
			{
				"name": "S",
				"min_score": 95.0,
				"max_avg_warnings": 0.2,
				"max_total_blockers": 0,
				"max_tracking_failures": 0,
				"min_confidence": 0.8,
			},
			{
				"name": "A",
				"min_score": 85.0,
				"max_avg_warnings": 0.5,
				"max_total_blockers": 0,
				"max_tracking_failures": 0,
				"min_confidence": 0.7,
			},
			{
				"name": "B",
				"min_score": 70.0,
				"max_avg_warnings": 1.0,
				"max_total_blockers": 0,
				"max_tracking_failures": 1,
				"min_confidence": 0.55,
			},
			{
				"name": "C",
				"min_score": 50.0,
				"max_avg_warnings": 1.5,
				"max_total_blockers": 1,
				"max_tracking_failures": 1,
				"min_confidence": 0.4,
			},
			{
				"name": "D",
				"min_score": 0.0,
				"max_avg_warnings": 2.0,
				"max_total_blockers": 2,
				"max_tracking_failures": 2,
				"min_confidence": 0.0,
			},
		],
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw

	var default_tier: String = str(row.get("default_tier", output.get("default_tier", "D"))).strip_edges()
	if not default_tier.is_empty():
		output["default_tier"] = default_tier

	var tiers_raw: Variant = row.get("tiers", [])
	if tiers_raw is Array:
		var tiers: Array = []
		for tier_row_variant in tiers_raw:
			if not (tier_row_variant is Dictionary):
				continue
			var tier_row: Dictionary = tier_row_variant
			var name: String = str(tier_row.get("name", "")).strip_edges()
			if name.is_empty():
				continue
			tiers.append({
				"name": name,
				"min_score": clampf(float(tier_row.get("min_score", 0.0)), 0.0, 100.0),
				"max_avg_warnings": maxf(0.0, float(tier_row.get("max_avg_warnings", 999.0))),
				"max_total_blockers": maxi(0, int(tier_row.get("max_total_blockers", 999))),
				"max_tracking_failures": maxi(0, int(tier_row.get("max_tracking_failures", 999))),
				"min_confidence": clampf(float(tier_row.get("min_confidence", 0.0)), 0.0, 1.0),
			})
		if not tiers.is_empty():
			tiers.sort_custom(_sort_tier_rows_desc)
			output["tiers"] = tiers

	return output


func _sort_tier_rows_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("min_score", 0.0)) > float(b.get("min_score", 0.0))


func _sanitize_convergence_dashboard(raw: Variant) -> Dictionary:
	var output: Dictionary = {
		"max_approval_failures": 0,
		"max_tracking_failures": 0,
		"max_trace_failures": 0,
		"max_manifest_failures": 0,
		"max_blockers": 0,
		"max_warnings": 2,
		"max_dashboard_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	for key in output.keys():
		output[key] = maxi(0, int(row.get(key, output.get(key, 0))))
	return output


func _sanitize_ci_signal_contract(raw: Variant, release_gate_templates: Dictionary) -> Dictionary:
	var output: Dictionary = {
		"required_fields": [
			"run_mode",
			"strategy",
			"stability_score",
			"stability_tier",
			"confidence",
			"dashboard_failures",
		],
		"tier_requirements": {
			"rehearsal": "C",
			"trend_gate": "B",
			"release_candidate": "B",
			"release_blocking": "A",
		},
		"max_contract_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw

	var required_fields: Array[String] = _sanitize_string_array(row.get("required_fields", output.get("required_fields", [])))
	if not required_fields.is_empty():
		output["required_fields"] = required_fields

	var tier_requirements_raw: Variant = row.get("tier_requirements", {})
	if tier_requirements_raw is Dictionary:
		var tier_requirements: Dictionary = {}
		for run_mode_var in (tier_requirements_raw as Dictionary).keys():
			var mode_name: String = str(run_mode_var).strip_edges()
			var tier_name: String = str((tier_requirements_raw as Dictionary).get(run_mode_var, "")).strip_edges()
			if mode_name.is_empty() or tier_name.is_empty():
				continue
			tier_requirements[mode_name] = tier_name
		if not tier_requirements.is_empty():
			output["tier_requirements"] = tier_requirements

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	var tier_requirements_output: Dictionary = output.get("tier_requirements", {})
	for run_mode in _sanitize_string_array(ci_mode_bindings.keys()):
		if not tier_requirements_output.has(run_mode):
			tier_requirements_output[run_mode] = "C"
	output["tier_requirements"] = tier_requirements_output

	output["max_contract_failures"] = maxi(0, int(row.get("max_contract_failures", output.get("max_contract_failures", 0))))
	return output


func _sanitize_convergence_trend_reinforcement(
	raw: Variant,
	tracking_cfg: Dictionary,
	archive_cfg: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"history_file": str(archive_cfg.get("archive_file", tracking_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))),
		"long_window": maxi(10, int(tracking_cfg.get("window", archive_cfg.get("aggregation_window", 40)))),
		"short_window": 12,
		"min_samples": 6,
		"required_metrics": [
			"warnings",
			"blockers",
			"approval_failures",
			"tracking_failures",
			"dashboard_failures",
		],
		"max_worsening_metrics": 1,
		"max_worsening_delta": 0.25,
		"min_improving_metrics": 0,
		"min_improvement_delta": 0.1,
		"max_trend_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw

	output["history_file"] = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json")))
	output["long_window"] = maxi(10, int(row.get("long_window", output.get("long_window", 40))))
	output["short_window"] = maxi(3, int(row.get("short_window", output.get("short_window", 12))))
	if int(output.get("short_window", 12)) > int(output.get("long_window", 40)):
		output["short_window"] = int(output.get("long_window", 40))
	output["min_samples"] = maxi(1, int(row.get("min_samples", output.get("min_samples", 6))))
	output["required_metrics"] = _sanitize_string_array(row.get("required_metrics", output.get("required_metrics", [])))
	output["max_worsening_metrics"] = maxi(0, int(row.get("max_worsening_metrics", output.get("max_worsening_metrics", 1))))
	output["max_worsening_delta"] = maxf(0.0, float(row.get("max_worsening_delta", output.get("max_worsening_delta", 0.25))))
	output["min_improving_metrics"] = maxi(0, int(row.get("min_improving_metrics", output.get("min_improving_metrics", 0))))
	output["min_improvement_delta"] = maxf(0.0, float(row.get("min_improvement_delta", output.get("min_improvement_delta", 0.1))))
	output["max_trend_failures"] = maxi(0, int(row.get("max_trend_failures", output.get("max_trend_failures", 0))))
	return output


func _sanitize_exception_lifecycle_linkage(raw: Variant, lifecycle_cfg: Dictionary) -> Dictionary:
	var output: Dictionary = {
		"required_states": [],
		"stale_idle_runs": maxi(1, int(lifecycle_cfg.get("expire_idle_runs", 2)) - 1),
		"min_transition_count": 0,
		"max_orphan_entries": 0,
		"max_unlinked_reclaims": 0,
		"max_unlinked_expired": 0,
		"max_linkage_failures": 0,
	}
	if not (raw is Dictionary):
		return output
	var row: Dictionary = raw
	output["required_states"] = _sanitize_string_array(row.get("required_states", output.get("required_states", [])))
	output["stale_idle_runs"] = maxi(1, int(row.get("stale_idle_runs", output.get("stale_idle_runs", 1))))
	output["min_transition_count"] = maxi(0, int(row.get("min_transition_count", output.get("min_transition_count", 0))))
	output["max_orphan_entries"] = maxi(0, int(row.get("max_orphan_entries", output.get("max_orphan_entries", 0))))
	output["max_unlinked_reclaims"] = maxi(0, int(row.get("max_unlinked_reclaims", output.get("max_unlinked_reclaims", 0))))
	output["max_unlinked_expired"] = maxi(0, int(row.get("max_unlinked_expired", output.get("max_unlinked_expired", 0))))
	output["max_linkage_failures"] = maxi(0, int(row.get("max_linkage_failures", output.get("max_linkage_failures", 0))))
	return output


func _sanitize_visual_performance_cogate(raw: Variant, release_gate_templates: Dictionary) -> Dictionary:
	var required_reports: Array[String] = _sanitize_string_array(release_gate_templates.get("required_reports", []))
	var baseline_report: String = "user://quality_baseline_latest.json"
	for report_path in required_reports:
		if str(report_path).ends_with("quality_baseline_latest.json"):
			baseline_report = str(report_path)
			break

	var output: Dictionary = {
		"baseline_report": baseline_report,
		"required_run_modes": ["release_candidate", "release_blocking"],
		"max_alert_total": 0,
		"max_alert_critical": 0,
		"max_alert_warning": 0,
		"max_scenario_failures": 0,
		"required_scenarios": [],
		"max_frame_ms_ratio": 1.15,
		"max_memory_mb_ratio": 1.1,
		"max_cogate_failures": 0,
	}
	if not (raw is Dictionary):
		return output

	var row: Dictionary = raw
	output["baseline_report"] = str(row.get("baseline_report", output.get("baseline_report", baseline_report)))
	output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
	output["max_alert_total"] = maxi(0, int(row.get("max_alert_total", output.get("max_alert_total", 0))))
	output["max_alert_critical"] = maxi(0, int(row.get("max_alert_critical", output.get("max_alert_critical", 0))))
	output["max_alert_warning"] = maxi(0, int(row.get("max_alert_warning", output.get("max_alert_warning", 0))))
	output["max_scenario_failures"] = maxi(0, int(row.get("max_scenario_failures", output.get("max_scenario_failures", 0))))
	output["required_scenarios"] = _sanitize_string_array(row.get("required_scenarios", output.get("required_scenarios", [])))
	output["max_frame_ms_ratio"] = maxf(1.0, float(row.get("max_frame_ms_ratio", output.get("max_frame_ms_ratio", 1.15))))
	output["max_memory_mb_ratio"] = maxf(1.0, float(row.get("max_memory_mb_ratio", output.get("max_memory_mb_ratio", 1.1))))
	output["max_cogate_failures"] = maxi(0, int(row.get("max_cogate_failures", output.get("max_cogate_failures", 0))))
	return output


func _sanitize_cogate_threshold_templates(raw: Variant, release_gate_templates: Dictionary) -> Dictionary:
	var output: Dictionary = {
		"default_template": "standard",
		"run_mode_templates": {
			"rehearsal": "relaxed",
			"trend_gate": "standard",
			"release_candidate": "candidate",
			"release_blocking": "blocking",
		},
		"templates": {
			"relaxed": {
				"max_alert_total": 2,
				"max_alert_critical": 0,
				"max_alert_warning": 2,
				"max_scenario_failures": 1,
				"max_frame_ms_ratio": 1.25,
				"max_memory_mb_ratio": 1.2,
				"max_cogate_failures": 1,
			},
			"standard": {
				"max_alert_total": 1,
				"max_alert_critical": 0,
				"max_alert_warning": 1,
				"max_scenario_failures": 0,
				"max_frame_ms_ratio": 1.2,
				"max_memory_mb_ratio": 1.15,
				"max_cogate_failures": 0,
			},
			"candidate": {
				"max_alert_total": 0,
				"max_alert_critical": 0,
				"max_alert_warning": 0,
				"max_scenario_failures": 0,
				"max_frame_ms_ratio": 1.15,
				"max_memory_mb_ratio": 1.1,
				"max_cogate_failures": 0,
			},
			"blocking": {
				"max_alert_total": 0,
				"max_alert_critical": 0,
				"max_alert_warning": 0,
				"max_scenario_failures": 0,
				"max_frame_ms_ratio": 1.1,
				"max_memory_mb_ratio": 1.05,
				"max_cogate_failures": 0,
			},
		},
	}
	if raw is Dictionary:
		var row: Dictionary = raw
		var default_template: String = str(row.get("default_template", output.get("default_template", "standard"))).strip_edges()
		if not default_template.is_empty():
			output["default_template"] = default_template

		var run_mode_templates_raw: Variant = row.get("run_mode_templates", {})
		if run_mode_templates_raw is Dictionary:
			var run_mode_templates: Dictionary = {}
			for run_mode_var in (run_mode_templates_raw as Dictionary).keys():
				var run_mode_name: String = str(run_mode_var).strip_edges()
				var template_name: String = str((run_mode_templates_raw as Dictionary).get(run_mode_var, "")).strip_edges()
				if run_mode_name.is_empty() or template_name.is_empty():
					continue
				run_mode_templates[run_mode_name] = template_name
			if not run_mode_templates.is_empty():
				output["run_mode_templates"] = run_mode_templates

		var templates_raw: Variant = row.get("templates", {})
		if templates_raw is Dictionary:
			var templates: Dictionary = {}
			for template_var in (templates_raw as Dictionary).keys():
				var template_name: String = str(template_var).strip_edges()
				var template_row_var: Variant = (templates_raw as Dictionary).get(template_var, {})
				if template_name.is_empty() or not (template_row_var is Dictionary):
					continue
				var template_row: Dictionary = template_row_var
				templates[template_name] = {
					"max_alert_total": maxi(0, int(template_row.get("max_alert_total", 0))),
					"max_alert_critical": maxi(0, int(template_row.get("max_alert_critical", 0))),
					"max_alert_warning": maxi(0, int(template_row.get("max_alert_warning", 0))),
					"max_scenario_failures": maxi(0, int(template_row.get("max_scenario_failures", 0))),
					"max_frame_ms_ratio": clampf(float(template_row.get("max_frame_ms_ratio", 1.15)), 1.0, 3.0),
					"max_memory_mb_ratio": clampf(float(template_row.get("max_memory_mb_ratio", 1.1)), 1.0, 3.0),
					"max_cogate_failures": maxi(0, int(template_row.get("max_cogate_failures", 0))),
				}
			if not templates.is_empty():
				output["templates"] = templates

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	var run_mode_templates_fallback: Dictionary = output.get("run_mode_templates", {})
	var fallback_template: String = str(output.get("default_template", "standard"))
	for run_mode in _sanitize_string_array(ci_mode_bindings.keys()):
		if not run_mode_templates_fallback.has(run_mode):
			run_mode_templates_fallback[run_mode] = fallback_template
	output["run_mode_templates"] = run_mode_templates_fallback
	return output


func _resolve_cogate_threshold_template(
	templates_cfg: Dictionary,
	base_cogate_cfg: Dictionary,
	run_mode: String
) -> Dictionary:
	var errors: Array[String] = []
	var run_mode_templates: Dictionary = templates_cfg.get("run_mode_templates", {})
	var templates: Dictionary = templates_cfg.get("templates", {})
	var default_template: String = str(templates_cfg.get("default_template", "standard")).strip_edges()
	if default_template.is_empty():
		default_template = "standard"

	var template_name: String = str(run_mode_templates.get(run_mode, default_template)).strip_edges()
	if template_name.is_empty():
		template_name = default_template
		errors.append("cogate template name for run_mode '%s' is empty; fallback to %s" % [run_mode, default_template])

	if not templates.has(template_name):
		errors.append("cogate template '%s' for run_mode '%s' not found; fallback to %s" % [template_name, run_mode, default_template])
		template_name = default_template

	if not templates.has(template_name):
		errors.append("default cogate template '%s' not found" % default_template)
		return {
			"template": template_name,
			"config": base_cogate_cfg,
			"errors": errors,
		}

	var template_row_var: Variant = templates.get(template_name, {})
	if not (template_row_var is Dictionary):
		errors.append("cogate template '%s' row must be object" % template_name)
		return {
			"template": template_name,
			"config": base_cogate_cfg,
			"errors": errors,
		}

	var template_row: Dictionary = template_row_var
	var resolved: Dictionary = base_cogate_cfg.duplicate(true)
	for key in [
		"max_alert_total",
		"max_alert_critical",
		"max_alert_warning",
		"max_scenario_failures",
		"max_frame_ms_ratio",
		"max_memory_mb_ratio",
		"max_cogate_failures",
	]:
		if template_row.has(key):
			resolved[key] = template_row.get(key)
	resolved["template"] = template_name

	return {
		"template": template_name,
		"config": resolved,
		"errors": errors,
	}


func _sanitize_cross_platform_alignment(
	raw: Variant,
	approval_history_archive: Dictionary,
	release_gate_templates: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"history_file": str(approval_history_archive.get("archive_file", "user://visual_snapshot_approval_archive.json")),
		"aggregation_window": maxi(20, int(approval_history_archive.get("aggregation_window", 80))),
		"required_run_modes": ["release_candidate", "release_blocking"],
		"required_backends": _sanitize_string_array(approval_history_archive.get("required_backends", [])),
		"metric_limits": {
			"performance_alert_total": 0,
			"performance_alert_critical": 0,
			"performance_alert_warning": 1,
			"performance_scenario_failures": 0,
			"performance_cogate_failures": 0,
		},
		"max_missing_backends": 0,
		"max_missing_run_modes": 0,
		"max_alignment_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["history_file"] = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json")))
		output["aggregation_window"] = maxi(20, int(row.get("aggregation_window", output.get("aggregation_window", 80))))
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_backends"] = _sanitize_string_array(row.get("required_backends", output.get("required_backends", [])))
		var metric_limits_raw: Variant = row.get("metric_limits", {})
		if metric_limits_raw is Dictionary:
			var metric_limits: Dictionary = output.get("metric_limits", {})
			for metric_name in metric_limits.keys():
				metric_limits[metric_name] = maxi(0, int((metric_limits_raw as Dictionary).get(metric_name, metric_limits.get(metric_name, 0))))
			output["metric_limits"] = metric_limits
		output["max_missing_backends"] = maxi(0, int(row.get("max_missing_backends", output.get("max_missing_backends", 0))))
		output["max_missing_run_modes"] = maxi(0, int(row.get("max_missing_run_modes", output.get("max_missing_run_modes", 0))))
		output["max_alignment_failures"] = maxi(0, int(row.get("max_alignment_failures", output.get("max_alignment_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_pressure_scenario_standardization(
	raw: Variant,
	base_cogate_cfg: Dictionary,
	release_gate_templates: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"baseline_targets_file": "res://data/balance/quality_baseline_targets.json",
		"baseline_report": str(base_cogate_cfg.get("baseline_report", "user://quality_baseline_latest.json")),
		"required_run_modes": _sanitize_string_array(base_cogate_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"required_scenarios": [
			"game_world_elite_pressure_medium",
			"game_world_elite_pressure_high",
			"game_world_elite_pressure_extreme",
			"game_world_boss_pressure_endurance",
		],
		"max_avg_frame_ms_ratio": 1.1,
		"max_p95_frame_ms_ratio": 1.12,
		"max_peak_memory_mb_ratio": 1.1,
		"max_standardization_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["baseline_targets_file"] = str(row.get("baseline_targets_file", output.get("baseline_targets_file", "res://data/balance/quality_baseline_targets.json")))
		output["baseline_report"] = str(row.get("baseline_report", output.get("baseline_report", "user://quality_baseline_latest.json")))
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_scenarios"] = _sanitize_string_array(row.get("required_scenarios", output.get("required_scenarios", [])))
		output["max_avg_frame_ms_ratio"] = clampf(float(row.get("max_avg_frame_ms_ratio", output.get("max_avg_frame_ms_ratio", 1.1))), 1.0, 3.0)
		output["max_p95_frame_ms_ratio"] = clampf(float(row.get("max_p95_frame_ms_ratio", output.get("max_p95_frame_ms_ratio", 1.12))), 1.0, 3.0)
		output["max_peak_memory_mb_ratio"] = clampf(float(row.get("max_peak_memory_mb_ratio", output.get("max_peak_memory_mb_ratio", 1.1))), 1.0, 3.0)
		output["max_standardization_failures"] = maxi(0, int(row.get("max_standardization_failures", output.get("max_standardization_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_alignment_dashboard_refinement(
	raw: Variant,
	base_alignment_cfg: Dictionary,
	release_gate_templates: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"required_run_modes": _sanitize_string_array(base_alignment_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"metric_weights": {
			"performance_alert_total": 1.0,
			"performance_alert_critical": 1.2,
			"performance_alert_warning": 0.8,
			"performance_scenario_failures": 1.2,
			"performance_cogate_failures": 1.4,
		},
		"missing_backend_weight": 1.0,
		"missing_run_mode_weight": 1.0,
		"watch_score_threshold": 0.35,
		"critical_score_threshold": 0.7,
		"max_dashboard_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))

		var metric_weights_raw: Variant = row.get("metric_weights", {})
		if metric_weights_raw is Dictionary:
			var metric_weights: Dictionary = output.get("metric_weights", {})
			for metric_key in metric_weights.keys():
				metric_weights[metric_key] = clampf(float((metric_weights_raw as Dictionary).get(metric_key, metric_weights.get(metric_key, 1.0))), 0.0, 5.0)
			output["metric_weights"] = metric_weights

		output["missing_backend_weight"] = clampf(float(row.get("missing_backend_weight", output.get("missing_backend_weight", 1.0))), 0.0, 5.0)
		output["missing_run_mode_weight"] = clampf(float(row.get("missing_run_mode_weight", output.get("missing_run_mode_weight", 1.0))), 0.0, 5.0)
		output["watch_score_threshold"] = maxf(0.0, float(row.get("watch_score_threshold", output.get("watch_score_threshold", 0.35))))
		output["critical_score_threshold"] = maxf(
			float(output.get("watch_score_threshold", 0.35)),
			float(row.get("critical_score_threshold", output.get("critical_score_threshold", 0.7)))
		)
		output["max_dashboard_failures"] = maxi(0, int(row.get("max_dashboard_failures", output.get("max_dashboard_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_pressure_alignment_convergence_gate(
	raw: Variant,
	base_alignment_cfg: Dictionary,
	release_gate_templates: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"required_run_modes": _sanitize_string_array(base_alignment_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"required_backends": _sanitize_string_array(base_alignment_cfg.get("required_backends", ["linux_headless", "windows_headless"])),
		"max_standardization_failures": 0,
		"max_alignment_failures": 0,
		"max_dashboard_failures": 0,
		"max_critical_severity_count": 0,
		"max_convergence_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_backends"] = _sanitize_string_array(row.get("required_backends", output.get("required_backends", [])))
		output["max_standardization_failures"] = maxi(0, int(row.get("max_standardization_failures", output.get("max_standardization_failures", 0))))
		output["max_alignment_failures"] = maxi(0, int(row.get("max_alignment_failures", output.get("max_alignment_failures", 0))))
		output["max_dashboard_failures"] = maxi(0, int(row.get("max_dashboard_failures", output.get("max_dashboard_failures", 0))))
		output["max_critical_severity_count"] = maxi(0, int(row.get("max_critical_severity_count", output.get("max_critical_severity_count", 0))))
		output["max_convergence_failures"] = maxi(0, int(row.get("max_convergence_failures", output.get("max_convergence_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_regression_cycle_window_governance(
	raw: Variant,
	approval_history_archive: Dictionary,
	release_gate_templates: Dictionary,
	base_alignment_cfg: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"history_file": str(approval_history_archive.get("archive_file", "user://visual_snapshot_approval_archive.json")),
		"cycle_window_size": 20,
		"min_cycle_entries": 8,
		"required_run_modes": _sanitize_string_array(base_alignment_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"required_backends": _sanitize_string_array(approval_history_archive.get("required_backends", base_alignment_cfg.get("required_backends", ["linux_headless", "windows_headless"]))),
		"max_warning_delta": maxi(0, int(approval_history_archive.get("max_backend_warning_delta", 1))),
		"max_blocker_delta": maxi(0, int(approval_history_archive.get("max_backend_blocker_delta", 0))),
		"max_alignment_score_delta": 0.2,
		"max_cycle_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["history_file"] = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json")))
		output["cycle_window_size"] = maxi(10, int(row.get("cycle_window_size", output.get("cycle_window_size", 20))))
		output["min_cycle_entries"] = maxi(1, int(row.get("min_cycle_entries", output.get("min_cycle_entries", 8))))
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_backends"] = _sanitize_string_array(row.get("required_backends", output.get("required_backends", [])))
		output["max_warning_delta"] = maxi(0, int(row.get("max_warning_delta", output.get("max_warning_delta", 1))))
		output["max_blocker_delta"] = maxi(0, int(row.get("max_blocker_delta", output.get("max_blocker_delta", 0))))
		output["max_alignment_score_delta"] = clampf(float(row.get("max_alignment_score_delta", output.get("max_alignment_score_delta", 0.2))), 0.0, 5.0)
		output["max_cycle_failures"] = maxi(0, int(row.get("max_cycle_failures", output.get("max_cycle_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_multi_cycle_adaptive_gate(
	raw: Variant,
	approval_history_archive: Dictionary,
	release_gate_templates: Dictionary,
	base_alignment_cfg: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"history_file": str(approval_history_archive.get("archive_file", "user://visual_snapshot_approval_archive.json")),
		"window_sizes": {
			"short": 8,
			"mid": 16,
			"long": 32,
		},
		"min_window_entries": 6,
		"required_run_modes": _sanitize_string_array(base_alignment_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"required_backends": _sanitize_string_array(approval_history_archive.get("required_backends", base_alignment_cfg.get("required_backends", ["linux_headless", "windows_headless"]))),
		"max_warning_slopes": {
			"short": 0.25,
			"mid": 0.15,
			"long": 0.1,
		},
		"max_blocker_slopes": {
			"short": 0.0,
			"mid": 0.0,
			"long": 0.0,
		},
		"max_missing_run_modes": 0,
		"max_missing_backends": 0,
		"max_adaptive_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["history_file"] = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json")))
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_backends"] = _sanitize_string_array(row.get("required_backends", output.get("required_backends", [])))

		var default_window_sizes: Dictionary = output.get("window_sizes", {})
		var window_sizes_raw: Variant = row.get("window_sizes", {})
		var short_size: int = maxi(4, int(default_window_sizes.get("short", 8)))
		var mid_size: int = maxi(short_size, int(default_window_sizes.get("mid", 16)))
		var long_size: int = maxi(mid_size, int(default_window_sizes.get("long", 32)))
		if window_sizes_raw is Dictionary:
			short_size = maxi(4, int((window_sizes_raw as Dictionary).get("short", short_size)))
			mid_size = maxi(short_size, int((window_sizes_raw as Dictionary).get("mid", mid_size)))
			long_size = maxi(mid_size, int((window_sizes_raw as Dictionary).get("long", long_size)))
		output["window_sizes"] = {
			"short": short_size,
			"mid": mid_size,
			"long": long_size,
		}

		var min_window_entries: int = maxi(1, int(row.get("min_window_entries", output.get("min_window_entries", 6))))
		output["min_window_entries"] = clampi(min_window_entries, 1, short_size)

		var warning_slopes_default: Dictionary = output.get("max_warning_slopes", {})
		var warning_slopes_raw: Variant = row.get("max_warning_slopes", {})
		var warning_short: float = clampf(float(warning_slopes_default.get("short", 0.25)), 0.0, 10.0)
		var warning_mid: float = clampf(float(warning_slopes_default.get("mid", 0.15)), 0.0, 10.0)
		var warning_long: float = clampf(float(warning_slopes_default.get("long", 0.1)), 0.0, 10.0)
		if warning_slopes_raw is Dictionary:
			warning_short = clampf(float((warning_slopes_raw as Dictionary).get("short", warning_short)), 0.0, 10.0)
			warning_mid = clampf(float((warning_slopes_raw as Dictionary).get("mid", warning_mid)), 0.0, 10.0)
			warning_long = clampf(float((warning_slopes_raw as Dictionary).get("long", warning_long)), 0.0, 10.0)
		output["max_warning_slopes"] = {
			"short": warning_short,
			"mid": warning_mid,
			"long": warning_long,
		}

		var blocker_slopes_default: Dictionary = output.get("max_blocker_slopes", {})
		var blocker_slopes_raw: Variant = row.get("max_blocker_slopes", {})
		var blocker_short: float = clampf(float(blocker_slopes_default.get("short", 0.0)), 0.0, 10.0)
		var blocker_mid: float = clampf(float(blocker_slopes_default.get("mid", 0.0)), 0.0, 10.0)
		var blocker_long: float = clampf(float(blocker_slopes_default.get("long", 0.0)), 0.0, 10.0)
		if blocker_slopes_raw is Dictionary:
			blocker_short = clampf(float((blocker_slopes_raw as Dictionary).get("short", blocker_short)), 0.0, 10.0)
			blocker_mid = clampf(float((blocker_slopes_raw as Dictionary).get("mid", blocker_mid)), 0.0, 10.0)
			blocker_long = clampf(float((blocker_slopes_raw as Dictionary).get("long", blocker_long)), 0.0, 10.0)
		output["max_blocker_slopes"] = {
			"short": blocker_short,
			"mid": blocker_mid,
			"long": blocker_long,
		}

		output["max_missing_run_modes"] = maxi(0, int(row.get("max_missing_run_modes", output.get("max_missing_run_modes", 0))))
		output["max_missing_backends"] = maxi(0, int(row.get("max_missing_backends", output.get("max_missing_backends", 0))))
		output["max_adaptive_failures"] = maxi(0, int(row.get("max_adaptive_failures", output.get("max_adaptive_failures", 0))))

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

	return output


func _sanitize_release_feedback_governance(
	raw: Variant,
	approval_history_archive: Dictionary,
	release_gate_templates: Dictionary,
	base_alignment_cfg: Dictionary
) -> Dictionary:
	var output: Dictionary = {
		"history_file": str(approval_history_archive.get("archive_file", "user://visual_snapshot_approval_archive.json")),
		"feedback_window_size": 24,
		"min_feedback_entries": 8,
		"required_run_modes": _sanitize_string_array(base_alignment_cfg.get("required_run_modes", ["release_candidate", "release_blocking"])),
		"required_backends": _sanitize_string_array(approval_history_archive.get("required_backends", base_alignment_cfg.get("required_backends", ["linux_headless", "windows_headless"]))),
		"issue_metrics": [
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
		],
		"min_closure_rate": 0.7,
		"max_unresolved_issues": 2,
		"max_missing_run_modes": 0,
		"max_missing_backends": 0,
		"max_feedback_failures": 0,
	}

	if raw is Dictionary:
		var row: Dictionary = raw
		output["history_file"] = str(row.get("history_file", output.get("history_file", "user://visual_snapshot_approval_archive.json")))
		output["feedback_window_size"] = maxi(5, int(row.get("feedback_window_size", output.get("feedback_window_size", 24))))
		output["min_feedback_entries"] = maxi(1, int(row.get("min_feedback_entries", output.get("min_feedback_entries", 8))))
		output["required_run_modes"] = _sanitize_string_array(row.get("required_run_modes", output.get("required_run_modes", [])))
		output["required_backends"] = _sanitize_string_array(row.get("required_backends", output.get("required_backends", [])))
		var issue_metrics: Array[String] = _sanitize_string_array(row.get("issue_metrics", output.get("issue_metrics", [])))
		if not issue_metrics.is_empty():
			output["issue_metrics"] = issue_metrics
		output["min_closure_rate"] = clampf(float(row.get("min_closure_rate", output.get("min_closure_rate", 0.7))), 0.0, 1.0)
		output["max_unresolved_issues"] = maxi(0, int(row.get("max_unresolved_issues", output.get("max_unresolved_issues", 2))))
		output["max_missing_run_modes"] = maxi(0, int(row.get("max_missing_run_modes", output.get("max_missing_run_modes", 0))))
		output["max_missing_backends"] = maxi(0, int(row.get("max_missing_backends", output.get("max_missing_backends", 0))))
		output["max_feedback_failures"] = maxi(0, int(row.get("max_feedback_failures", output.get("max_feedback_failures", 0))))

	var feedback_window_size: int = int(output.get("feedback_window_size", 24))
	var min_feedback_entries: int = int(output.get("min_feedback_entries", 8))
	output["min_feedback_entries"] = clampi(min_feedback_entries, 1, feedback_window_size)

	var ci_mode_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	if (output.get("required_run_modes", []) as Array).is_empty() and not ci_mode_bindings.is_empty():
		output["required_run_modes"] = _sanitize_string_array(ci_mode_bindings.keys())

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
			"Stability Scoring":
				section_ok = report.has("stability_scoring")
			"Convergence Dashboard":
				section_ok = report.has("convergence_dashboard")
			"CI Signal Contract":
				section_ok = report.has("ci_signal")
			"Convergence Trend Reinforcement":
				section_ok = report.has("convergence_trend")
			"Exception Lifecycle Linkage":
				section_ok = report.has("exception_lifecycle_linkage")
			"Visual-Performance Co-Gate":
				section_ok = report.has("visual_performance_cogate")
			"Co-Gate Threshold Template":
				section_ok = report.has("cogate_template")
			"Cross-Platform Alignment":
				section_ok = report.has("cross_platform_alignment")
			"Pressure Scenario Standardization":
				section_ok = report.has("pressure_scenario_standardization")
			"Alignment Dashboard Refinement":
				section_ok = report.has("alignment_dashboard_refinement")
			"Pressure Alignment Convergence Gate":
				section_ok = report.has("pressure_alignment_convergence_gate")
			"Regression Cycle Window Governance":
				section_ok = report.has("regression_cycle_window_governance")
			"Multi-Cycle Adaptive Gate":
				section_ok = report.has("multi_cycle_adaptive_gate")
			"Release Feedback Governance":
				section_ok = report.has("release_feedback_governance")
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
	var tracking_row: Dictionary = report.get("release_candidate_tracking", {})
	var dashboard_row: Dictionary = report.get("convergence_dashboard", {})
	var ci_row: Dictionary = report.get("ci_signal", {})
	var scoring_row: Dictionary = report.get("stability_scoring", {})
	var cogate_row: Dictionary = report.get("visual_performance_cogate", {})
	var cogate_alerts: Dictionary = cogate_row.get("alerts", {})
	var standardization_row: Dictionary = report.get("pressure_scenario_standardization", {})
	var refinement_row: Dictionary = report.get("alignment_dashboard_refinement", {})
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
		"tracking_failures": int(tracking_row.get("tracking_failures", 0)),
		"dashboard_failures": int(dashboard_row.get("dashboard_failures", 0)),
		"contract_failures": int(ci_row.get("contract_failures", 0)),
		"stability_score": float(scoring_row.get("score", 0.0)),
		"stability_tier": str(scoring_row.get("tier", "")),
		"performance_cogate_failures": int(cogate_row.get("cogate_failures", 0)),
		"performance_scenario_failures": int(cogate_row.get("scenario_failures", 0)),
		"performance_alert_total": int(cogate_alerts.get("total", 0)),
		"performance_alert_critical": int(cogate_alerts.get("critical", 0)),
		"performance_alert_warning": int(cogate_alerts.get("warning", 0)),
		"pressure_standardization_failures": int(standardization_row.get("standardization_failures", 0)),
		"alignment_dashboard_score": float(refinement_row.get("score", 0.0)),
		"alignment_dashboard_failures": int(refinement_row.get("dashboard_failures", 0)),
		"alignment_dashboard_severity": str(refinement_row.get("severity", "normal")),
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


func _evaluate_stability_scoring(
	report: Dictionary,
	scoring_cfg: Dictionary,
	tier_cfg: Dictionary,
	run_mode: String
) -> void:
	if scoring_cfg.is_empty():
		return

	var tracking_row: Dictionary = report.get("release_candidate_tracking", {})
	var matching_runs: int = maxi(0, int(tracking_row.get("matching_runs", 0)))
	var avg_warnings: float = maxf(0.0, float(tracking_row.get("avg_warnings", 0.0)))
	var total_blockers: int = maxi(0, int(tracking_row.get("total_blockers", 0)))
	var tracking_failures: int = maxi(0, int(tracking_row.get("tracking_failures", 0)))
	var min_runs: int = maxi(1, int(tracking_row.get("min_runs", 1)))

	var weights: Dictionary = scoring_cfg.get("weights", {})
	var failure_caps: Dictionary = scoring_cfg.get("failure_caps", {})
	var confidence_cfg: Dictionary = scoring_cfg.get("confidence", {})
	var score_round_digits: int = clampi(int(scoring_cfg.get("score_round_digits", 3)), 0, 5)

	var matching_component: float = clampf(float(matching_runs) / float(min_runs), 0.0, 1.0)
	var warning_cap: float = maxf(0.1, float(failure_caps.get("max_avg_warnings", 2.0)))
	var blocker_cap: int = maxi(1, int(failure_caps.get("max_total_blockers", 2)))
	var tracking_cap: int = maxi(1, int(failure_caps.get("max_tracking_failures", 2)))
	var warnings_component: float = 1.0 - clampf(avg_warnings / warning_cap, 0.0, 1.0)
	var blockers_component: float = 1.0 - clampf(float(total_blockers) / float(blocker_cap), 0.0, 1.0)
	var tracking_component: float = 1.0 - clampf(float(tracking_failures) / float(tracking_cap), 0.0, 1.0)

	var weighted_score: float = 0.0
	weighted_score += matching_component * clampf(float(weights.get("matching_runs", 0.3)), 0.0, 1.0)
	weighted_score += warnings_component * clampf(float(weights.get("avg_warnings", 0.25)), 0.0, 1.0)
	weighted_score += blockers_component * clampf(float(weights.get("total_blockers", 0.35)), 0.0, 1.0)
	weighted_score += tracking_component * clampf(float(weights.get("tracking_failures", 0.1)), 0.0, 1.0)
	var weight_total: float = clampf(
		clampf(float(weights.get("matching_runs", 0.3)), 0.0, 1.0)
		+ clampf(float(weights.get("avg_warnings", 0.25)), 0.0, 1.0)
		+ clampf(float(weights.get("total_blockers", 0.35)), 0.0, 1.0)
		+ clampf(float(weights.get("tracking_failures", 0.1)), 0.0, 1.0),
		0.0001,
		4.0
	)
	var score: float = clampf((weighted_score / weight_total) * 100.0, 0.0, 100.0)
	var score_multiplier: float = pow(10.0, float(score_round_digits))
	if score_multiplier > 0.0:
		score = roundf(score * score_multiplier) / score_multiplier

	var reference_runs: int = maxi(1, int(confidence_cfg.get("reference_runs", 8)))
	var min_confidence: float = clampf(float(confidence_cfg.get("min_confidence", 0.4)), 0.0, 1.0)
	var confidence: float = clampf(float(matching_runs) / float(reference_runs), 0.0, 1.0)

	var tier_resolution: Dictionary = _resolve_stability_tier(
		score,
		avg_warnings,
		total_blockers,
		tracking_failures,
		confidence,
		tier_cfg
	)
	var tier_name: String = str(tier_resolution.get("tier", str(tier_cfg.get("default_tier", "D"))))
	var tier_matched: bool = bool(tier_resolution.get("matched", false))
	var tier_rule: Dictionary = tier_resolution.get("rule", {})

	var scoring_failures: int = 0
	var scoring_items: Array = []

	scoring_items.append({
		"type": "confidence",
		"value": confidence,
		"limit": min_confidence,
		"ok": confidence >= min_confidence,
	})
	if confidence < min_confidence:
		scoring_failures += 1

	scoring_items.append({
		"type": "tier_match",
		"value": tier_name,
		"ok": tier_matched,
	})
	if not tier_matched:
		scoring_failures += 1

	var scoring_row: Dictionary = report.get("stability_scoring", {})
	scoring_row["score"] = score
	scoring_row["tier"] = tier_name
	scoring_row["confidence"] = confidence
	scoring_row["reference_runs"] = reference_runs
	scoring_row["min_confidence"] = min_confidence
	scoring_row["matching_component"] = matching_component
	scoring_row["warnings_component"] = warnings_component
	scoring_row["blockers_component"] = blockers_component
	scoring_row["tracking_component"] = tracking_component
	scoring_row["score_round_digits"] = score_round_digits
	scoring_row["tier_rule"] = tier_rule
	scoring_row["scoring_failures"] = scoring_failures
	scoring_row["items"] = scoring_items
	report["stability_scoring"] = scoring_row

	if scoring_failures > 0:
		var message: String = "stability scoring has %d unresolved checks" % scoring_failures
		if run_mode == "release_blocking":
			_push_result(report, "global", "stability_scoring_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "stability_scoring_failures_pending", message)


func _evaluate_convergence_dashboard(report: Dictionary, dashboard_cfg: Dictionary, run_mode: String) -> void:
	if dashboard_cfg.is_empty():
		return

	var approval_row: Dictionary = report.get("approval", {})
	var audit_row: Dictionary = report.get("approval_audit", {})
	var archive_row: Dictionary = report.get("approval_archive", {})
	var tracking_row: Dictionary = report.get("release_candidate_tracking", {})

	var approval_failures: int = maxi(0, int(approval_row.get("approval_failures", 0)))
	var tracking_failures: int = maxi(0, int(tracking_row.get("tracking_failures", 0)))
	var trace_failures: int = maxi(0, int(audit_row.get("trace_failures", 0))) + maxi(0, int(archive_row.get("trace_failures", 0)))
	var manifest_failures: int = maxi(0, int((report.get("release_manifest", {}) as Dictionary).get("checklist_failures", 0)))
	var blockers: int = maxi(0, int(report.get("blockers", 0)))
	var warnings: int = maxi(0, int(report.get("warnings", 0)))

	var max_approval_failures: int = maxi(0, int(dashboard_cfg.get("max_approval_failures", 0)))
	var max_tracking_failures: int = maxi(0, int(dashboard_cfg.get("max_tracking_failures", 0)))
	var max_trace_failures: int = maxi(0, int(dashboard_cfg.get("max_trace_failures", 0)))
	var max_manifest_failures: int = maxi(0, int(dashboard_cfg.get("max_manifest_failures", 0)))
	var max_blockers: int = maxi(0, int(dashboard_cfg.get("max_blockers", 0)))
	var max_warnings: int = maxi(0, int(dashboard_cfg.get("max_warnings", 0)))
	var max_dashboard_failures: int = maxi(0, int(dashboard_cfg.get("max_dashboard_failures", 0)))

	var dashboard_items: Array = []
	var dashboard_failures: int = 0

	for row in [
		{"type": "approval_failures", "value": approval_failures, "limit": max_approval_failures},
		{"type": "tracking_failures", "value": tracking_failures, "limit": max_tracking_failures},
		{"type": "trace_failures", "value": trace_failures, "limit": max_trace_failures},
		{"type": "manifest_failures", "value": manifest_failures, "limit": max_manifest_failures},
		{"type": "blockers", "value": blockers, "limit": max_blockers},
		{"type": "warnings", "value": warnings, "limit": max_warnings},
	]:
		var item: Dictionary = row
		item["ok"] = int(item.get("value", 0)) <= int(item.get("limit", 0))
		dashboard_items.append(item)
		if not bool(item.get("ok", false)):
			dashboard_failures += 1

	var dashboard_row: Dictionary = report.get("convergence_dashboard", {})
	dashboard_row["approval_failures"] = approval_failures
	dashboard_row["tracking_failures"] = tracking_failures
	dashboard_row["trace_failures"] = trace_failures
	dashboard_row["manifest_failures"] = manifest_failures
	dashboard_row["blockers"] = blockers
	dashboard_row["warnings"] = warnings
	dashboard_row["max_approval_failures"] = max_approval_failures
	dashboard_row["max_tracking_failures"] = max_tracking_failures
	dashboard_row["max_trace_failures"] = max_trace_failures
	dashboard_row["max_manifest_failures"] = max_manifest_failures
	dashboard_row["max_blockers"] = max_blockers
	dashboard_row["max_warnings"] = max_warnings
	dashboard_row["max_dashboard_failures"] = max_dashboard_failures
	dashboard_row["dashboard_failures"] = dashboard_failures
	dashboard_row["items"] = dashboard_items
	report["convergence_dashboard"] = dashboard_row

	if dashboard_failures > max_dashboard_failures:
		var message: String = "convergence dashboard failures %d exceeds %d" % [dashboard_failures, max_dashboard_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "convergence_dashboard_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "convergence_dashboard_failures_pending", message)


func _evaluate_ci_signal_contract(
	report: Dictionary,
	contract_cfg: Dictionary,
	tier_cfg: Dictionary,
	run_mode: String
) -> void:
	if contract_cfg.is_empty():
		return

	var scoring_row: Dictionary = report.get("stability_scoring", {})
	var dashboard_row: Dictionary = report.get("convergence_dashboard", {})
	var required_fields: Array[String] = _sanitize_string_array(contract_cfg.get("required_fields", []))
	var tier_requirements: Dictionary = contract_cfg.get("tier_requirements", {})
	var max_contract_failures: int = maxi(0, int(contract_cfg.get("max_contract_failures", 0)))
	var strategy_name: String = str((report.get("strategy", {}) as Dictionary).get("name", "")).strip_edges()

	var ci_signal: Dictionary = {
		"run_mode": run_mode,
		"strategy": strategy_name,
		"stability_score": float(scoring_row.get("score", 0.0)),
		"stability_tier": str(scoring_row.get("tier", str(tier_cfg.get("default_tier", "D")))),
		"confidence": float(scoring_row.get("confidence", 0.0)),
		"dashboard_failures": int(dashboard_row.get("dashboard_failures", 0)),
		"blockers": int(report.get("blockers", 0)),
		"warnings": int(report.get("warnings", 0)),
	}

	var contract_failures: int = 0
	var contract_items: Array = []

	for field_name in required_fields:
		var value: Variant = ci_signal.get(field_name)
		var ok: bool = value != null
		if value is String:
			ok = not str(value).strip_edges().is_empty()
		contract_items.append({
			"type": "required_field",
			"field": field_name,
			"ok": ok,
		})
		if not ok:
			contract_failures += 1

	var required_tier: String = str(tier_requirements.get(run_mode, "")).strip_edges()
	if not required_tier.is_empty():
		var actual_tier: String = str(ci_signal.get("stability_tier", "")).strip_edges()
		var tier_ok: bool = _tier_rank(actual_tier, tier_cfg) >= _tier_rank(required_tier, tier_cfg)
		contract_items.append({
			"type": "tier_requirement",
			"value": actual_tier,
			"limit": required_tier,
			"ok": tier_ok,
		})
		if not tier_ok:
			contract_failures += 1

	var ci_row: Dictionary = report.get("ci_signal", {})
	ci_row["required_fields"] = required_fields
	ci_row["tier_requirements"] = tier_requirements
	ci_row["max_contract_failures"] = max_contract_failures
	ci_row["contract_failures"] = contract_failures
	ci_row["signal"] = ci_signal
	ci_row["items"] = contract_items
	report["ci_signal"] = ci_row

	if contract_failures > max_contract_failures:
		var message: String = "ci signal contract failures %d exceeds %d" % [contract_failures, max_contract_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "ci_signal_contract_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "ci_signal_contract_failures_pending", message)


func _resolve_stability_tier(
	score: float,
	avg_warnings: float,
	total_blockers: int,
	tracking_failures: int,
	confidence: float,
	tier_cfg: Dictionary
) -> Dictionary:
	var default_tier: String = str(tier_cfg.get("default_tier", "D"))
	var tiers: Array = tier_cfg.get("tiers", [])
	for tier_variant in tiers:
		if not (tier_variant is Dictionary):
			continue
		var tier_row: Dictionary = tier_variant
		var min_score: float = float(tier_row.get("min_score", 0.0))
		var max_avg_warnings: float = float(tier_row.get("max_avg_warnings", 999.0))
		var max_total_blockers: int = int(tier_row.get("max_total_blockers", 999))
		var max_tracking_failures: int = int(tier_row.get("max_tracking_failures", 999))
		var min_confidence: float = float(tier_row.get("min_confidence", 0.0))
		if score < min_score:
			continue
		if avg_warnings > max_avg_warnings:
			continue
		if total_blockers > max_total_blockers:
			continue
		if tracking_failures > max_tracking_failures:
			continue
		if confidence < min_confidence:
			continue
		return {
			"tier": str(tier_row.get("name", default_tier)),
			"matched": true,
			"rule": tier_row,
		}
	return {
		"tier": default_tier,
		"matched": false,
		"rule": {},
	}


func _tier_rank(tier_name: String, tier_cfg: Dictionary) -> int:
	var tiers: Array = tier_cfg.get("tiers", [])
	var index: int = 0
	for tier_variant in tiers:
		if not (tier_variant is Dictionary):
			index += 1
			continue
		var tier_row: Dictionary = tier_variant
		if str(tier_row.get("name", "")) == tier_name:
			return tiers.size() - index
		index += 1
	return 0


func _metric_stats_from_history(history: Array, metric_name: String) -> Dictionary:
	var count: int = 0
	var total: float = 0.0
	for entry in history:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		if not row.has(metric_name):
			continue
		count += 1
		total += float(row.get(metric_name, 0.0))
	var average: float = 0.0
	if count > 0:
		average = total / float(count)
	return {
		"count": count,
		"sum": total,
		"average": average,
	}


func _evaluate_convergence_trend_reinforcement(
	report: Dictionary,
	trend_cfg: Dictionary,
	run_mode: String
) -> void:
	if trend_cfg.is_empty():
		return

	var history_file: String = str(trend_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var long_window: int = maxi(10, int(trend_cfg.get("long_window", 40)))
	var short_window: int = maxi(3, int(trend_cfg.get("short_window", 12)))
	short_window = mini(short_window, long_window)
	var min_samples: int = maxi(1, int(trend_cfg.get("min_samples", 6)))
	var required_metrics: Array[String] = _sanitize_string_array(trend_cfg.get("required_metrics", []))
	var max_worsening_metrics: int = maxi(0, int(trend_cfg.get("max_worsening_metrics", 1)))
	var max_worsening_delta: float = maxf(0.0, float(trend_cfg.get("max_worsening_delta", 0.25)))
	var min_improving_metrics: int = maxi(0, int(trend_cfg.get("min_improving_metrics", 0)))
	var min_improvement_delta: float = maxf(0.0, float(trend_cfg.get("min_improvement_delta", 0.1)))
	var max_trend_failures: int = maxi(0, int(trend_cfg.get("max_trend_failures", 0)))

	var archive_history: Array = []
	if FileAccess.file_exists(history_file):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
		if parsed is Array:
			archive_history = parsed

	var long_start: int = maxi(0, archive_history.size() - long_window)
	var long_history: Array = archive_history.slice(long_start, archive_history.size())
	var short_start: int = maxi(0, archive_history.size() - short_window)
	var short_history: Array = archive_history.slice(short_start, archive_history.size())

	var trend_items: Array = []
	var trend_failures: int = 0

	trend_items.append({
		"type": "min_samples_long_window",
		"value": long_history.size(),
		"limit": min_samples,
		"ok": long_history.size() >= min_samples,
	})
	if long_history.size() < min_samples:
		trend_failures += 1

	trend_items.append({
		"type": "min_samples_short_window",
		"value": short_history.size(),
		"limit": min_samples,
		"ok": short_history.size() >= min_samples,
	})
	if short_history.size() < min_samples:
		trend_failures += 1

	var metric_deltas: Dictionary = {}
	var missing_metrics: Array = []
	var worsening_metrics: Array = []
	var improving_metrics: Array = []

	for metric_name in required_metrics:
		var long_stats: Dictionary = _metric_stats_from_history(long_history, metric_name)
		var short_stats: Dictionary = _metric_stats_from_history(short_history, metric_name)
		var long_count: int = int(long_stats.get("count", 0))
		var short_count: int = int(short_stats.get("count", 0))
		if long_count == 0 or short_count == 0:
			missing_metrics.append(metric_name)
			continue
		var long_avg: float = float(long_stats.get("average", 0.0))
		var short_avg: float = float(short_stats.get("average", 0.0))
		var delta: float = short_avg - long_avg
		metric_deltas[metric_name] = {
			"long_avg": long_avg,
			"short_avg": short_avg,
			"delta": delta,
		}
		if delta > max_worsening_delta:
			worsening_metrics.append(metric_name)
		if delta <= -min_improvement_delta:
			improving_metrics.append(metric_name)

	trend_items.append({
		"type": "missing_metrics",
		"value": missing_metrics,
		"ok": missing_metrics.is_empty(),
	})
	if not missing_metrics.is_empty():
		trend_failures += 1

	trend_items.append({
		"type": "max_worsening_metrics",
		"value": worsening_metrics.size(),
		"limit": max_worsening_metrics,
		"metrics": worsening_metrics,
		"ok": worsening_metrics.size() <= max_worsening_metrics,
	})
	if worsening_metrics.size() > max_worsening_metrics:
		trend_failures += 1

	trend_items.append({
		"type": "min_improving_metrics",
		"value": improving_metrics.size(),
		"limit": min_improving_metrics,
		"metrics": improving_metrics,
		"ok": improving_metrics.size() >= min_improving_metrics,
	})
	if improving_metrics.size() < min_improving_metrics:
		trend_failures += 1

	var trend_row: Dictionary = report.get("convergence_trend", {})
	trend_row["history_file"] = history_file
	trend_row["long_window"] = long_window
	trend_row["short_window"] = short_window
	trend_row["min_samples"] = min_samples
	trend_row["required_metrics"] = required_metrics
	trend_row["max_worsening_metrics"] = max_worsening_metrics
	trend_row["max_worsening_delta"] = max_worsening_delta
	trend_row["min_improving_metrics"] = min_improving_metrics
	trend_row["min_improvement_delta"] = min_improvement_delta
	trend_row["max_trend_failures"] = max_trend_failures
	trend_row["long_sample_count"] = long_history.size()
	trend_row["short_sample_count"] = short_history.size()
	trend_row["metric_deltas"] = metric_deltas
	trend_row["missing_metrics"] = missing_metrics
	trend_row["worsening_metrics"] = worsening_metrics
	trend_row["improving_metrics"] = improving_metrics
	trend_row["trend_failures"] = trend_failures
	trend_row["items"] = trend_items
	report["convergence_trend"] = trend_row

	if trend_failures > max_trend_failures:
		var message: String = "convergence trend failures %d exceeds %d" % [trend_failures, max_trend_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "convergence_trend_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "convergence_trend_failures_pending", message)


func _evaluate_exception_lifecycle_linkage(
	report: Dictionary,
	linkage_cfg: Dictionary,
	run_mode: String
) -> void:
	if linkage_cfg.is_empty():
		return

	var whitelist_row: Dictionary = report.get("whitelist", {})
	var lifecycle: Dictionary = whitelist_row.get("lifecycle", {})
	var expired_entries: Array = whitelist_row.get("expired_entries", [])
	var reclaim_candidates: Array = whitelist_row.get("reclaim_candidates", [])

	var required_states: Array[String] = _sanitize_string_array(linkage_cfg.get("required_states", []))
	var stale_idle_runs: int = maxi(1, int(linkage_cfg.get("stale_idle_runs", 1)))
	var min_transition_count: int = maxi(0, int(linkage_cfg.get("min_transition_count", 0)))
	var max_orphan_entries: int = maxi(0, int(linkage_cfg.get("max_orphan_entries", 0)))
	var max_unlinked_reclaims: int = maxi(0, int(linkage_cfg.get("max_unlinked_reclaims", 0)))
	var max_unlinked_expired: int = maxi(0, int(linkage_cfg.get("max_unlinked_expired", 0)))
	var max_linkage_failures: int = maxi(0, int(linkage_cfg.get("max_linkage_failures", 0)))

	var lifecycle_keys: Dictionary = {}
	for key_var in lifecycle.keys():
		lifecycle_keys[str(key_var)] = true

	var expired_keys: Dictionary = {}
	var orphan_entries: Array = []
	var unlinked_expired: Array = []
	for entry in expired_entries:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var key: String = str(row.get("key", "")).strip_edges()
		if key.is_empty():
			var snapshot_id: String = str(row.get("snapshot", "")).strip_edges()
			var rule_id: String = str(row.get("id", "")).strip_edges()
			if not snapshot_id.is_empty() and not rule_id.is_empty():
				key = "%s|%s" % [snapshot_id, rule_id]
		if key.is_empty():
			continue
		expired_keys[key] = true
		if not lifecycle_keys.has(key):
			orphan_entries.append(key)
		var idle_runs: int = maxi(0, int(row.get("idle_runs", 0)))
		var expire_limit: int = maxi(1, int(row.get("expire_idle_runs", stale_idle_runs + 1)))
		if idle_runs < expire_limit:
			unlinked_expired.append(key)

	var reclaim_keys: Dictionary = {}
	var unlinked_reclaims: Array = []
	for entry in reclaim_candidates:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var key: String = str(row.get("key", "")).strip_edges()
		if key.is_empty():
			var snapshot_id: String = str(row.get("snapshot", "")).strip_edges()
			var rule_id: String = str(row.get("id", "")).strip_edges()
			if not snapshot_id.is_empty() and not rule_id.is_empty():
				key = "%s|%s" % [snapshot_id, rule_id]
		if key.is_empty():
			continue
		reclaim_keys[key] = true
		if not lifecycle_keys.has(key):
			orphan_entries.append(key)
		if not row.has("suggested_limit"):
			unlinked_reclaims.append(key)

	var state_counts: Dictionary = {
		"active": 0,
		"stale": 0,
		"reclaim_candidate": 0,
		"expired": 0,
		"idle": 0,
	}
	for key_var in lifecycle.keys():
		var key: String = str(key_var)
		var row_variant: Variant = lifecycle.get(key_var, {})
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var hit_streak: int = maxi(0, int(row.get("hit_streak", 0)))
		var idle_runs: int = maxi(0, int(row.get("idle_runs", 0)))
		var total_hits: int = maxi(0, int(row.get("total_hits", 0)))
		var state_name: String = "idle"
		if expired_keys.has(key):
			state_name = "expired"
		elif reclaim_keys.has(key):
			state_name = "reclaim_candidate"
		elif idle_runs >= stale_idle_runs:
			state_name = "stale"
		elif hit_streak > 0 or total_hits > 0:
			state_name = "active"
		state_counts[state_name] = int(state_counts.get(state_name, 0)) + 1

	var missing_required_states: Array = []
	for state_name in required_states:
		if int(state_counts.get(state_name, 0)) <= 0:
			missing_required_states.append(state_name)

	var transition_count: int = int(state_counts.get("stale", 0)) + int(state_counts.get("reclaim_candidate", 0)) + int(state_counts.get("expired", 0))
	var linkage_failures: int = 0
	var linkage_items: Array = []

	linkage_items.append({
		"type": "max_orphan_entries",
		"value": orphan_entries.size(),
		"limit": max_orphan_entries,
		"ok": orphan_entries.size() <= max_orphan_entries,
		"entries": orphan_entries,
	})
	if orphan_entries.size() > max_orphan_entries:
		linkage_failures += 1

	linkage_items.append({
		"type": "max_unlinked_reclaims",
		"value": unlinked_reclaims.size(),
		"limit": max_unlinked_reclaims,
		"ok": unlinked_reclaims.size() <= max_unlinked_reclaims,
		"entries": unlinked_reclaims,
	})
	if unlinked_reclaims.size() > max_unlinked_reclaims:
		linkage_failures += 1

	linkage_items.append({
		"type": "max_unlinked_expired",
		"value": unlinked_expired.size(),
		"limit": max_unlinked_expired,
		"ok": unlinked_expired.size() <= max_unlinked_expired,
		"entries": unlinked_expired,
	})
	if unlinked_expired.size() > max_unlinked_expired:
		linkage_failures += 1

	linkage_items.append({
		"type": "required_states",
		"value": missing_required_states,
		"ok": missing_required_states.is_empty(),
	})
	if not missing_required_states.is_empty():
		linkage_failures += 1

	linkage_items.append({
		"type": "min_transition_count",
		"value": transition_count,
		"limit": min_transition_count,
		"ok": transition_count >= min_transition_count,
	})
	if transition_count < min_transition_count:
		linkage_failures += 1

	var linkage_row: Dictionary = report.get("exception_lifecycle_linkage", {})
	linkage_row["required_states"] = required_states
	linkage_row["stale_idle_runs"] = stale_idle_runs
	linkage_row["min_transition_count"] = min_transition_count
	linkage_row["max_orphan_entries"] = max_orphan_entries
	linkage_row["max_unlinked_reclaims"] = max_unlinked_reclaims
	linkage_row["max_unlinked_expired"] = max_unlinked_expired
	linkage_row["max_linkage_failures"] = max_linkage_failures
	linkage_row["state_counts"] = state_counts
	linkage_row["orphan_entries"] = orphan_entries
	linkage_row["unlinked_reclaims"] = unlinked_reclaims
	linkage_row["unlinked_expired"] = unlinked_expired
	linkage_row["missing_required_states"] = missing_required_states
	linkage_row["transition_count"] = transition_count
	linkage_row["linkage_failures"] = linkage_failures
	linkage_row["items"] = linkage_items
	report["exception_lifecycle_linkage"] = linkage_row

	if linkage_failures > max_linkage_failures:
		var message: String = "exception lifecycle linkage failures %d exceeds %d" % [linkage_failures, max_linkage_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "exception_lifecycle_linkage_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "exception_lifecycle_linkage_failures_pending", message)


func _index_baseline_scenarios(rows: Array) -> Dictionary:
	var index: Dictionary = {}
	for row_var in rows:
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var
		var scenario_id: String = str(row.get("id", "")).strip_edges()
		if scenario_id.is_empty():
			continue
		index[scenario_id] = row
	return index


func _evaluate_visual_performance_cogate(
	report: Dictionary,
	cogate_cfg: Dictionary,
	run_mode: String
) -> void:
	if cogate_cfg.is_empty():
		return

	var cogate_row: Dictionary = report.get("visual_performance_cogate", {})
	var required_run_modes: Array[String] = _sanitize_string_array(cogate_cfg.get("required_run_modes", []))
	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	var baseline_report: String = str(cogate_cfg.get("baseline_report", "user://quality_baseline_latest.json"))
	var max_alert_total: int = maxi(0, int(cogate_cfg.get("max_alert_total", 0)))
	var max_alert_critical: int = maxi(0, int(cogate_cfg.get("max_alert_critical", 0)))
	var max_alert_warning: int = maxi(0, int(cogate_cfg.get("max_alert_warning", 0)))
	var max_scenario_failures: int = maxi(0, int(cogate_cfg.get("max_scenario_failures", 0)))
	var required_scenarios: Array[String] = _sanitize_string_array(cogate_cfg.get("required_scenarios", []))
	var max_frame_ms_ratio: float = maxf(1.0, float(cogate_cfg.get("max_frame_ms_ratio", 1.15)))
	var max_memory_mb_ratio: float = maxf(1.0, float(cogate_cfg.get("max_memory_mb_ratio", 1.1)))
	var max_cogate_failures: int = maxi(0, int(cogate_cfg.get("max_cogate_failures", 0)))

	cogate_row["baseline_report"] = baseline_report
	cogate_row["required_run_modes"] = required_run_modes
	cogate_row["enabled_for_mode"] = enabled_for_mode
	cogate_row["max_alert_total"] = max_alert_total
	cogate_row["max_alert_critical"] = max_alert_critical
	cogate_row["max_alert_warning"] = max_alert_warning
	cogate_row["max_scenario_failures"] = max_scenario_failures
	cogate_row["required_scenarios"] = required_scenarios
	cogate_row["max_frame_ms_ratio"] = max_frame_ms_ratio
	cogate_row["max_memory_mb_ratio"] = max_memory_mb_ratio
	cogate_row["max_cogate_failures"] = max_cogate_failures

	if not enabled_for_mode:
		cogate_row["cogate_failures"] = 0
		cogate_row["scenario_failures"] = 0
		cogate_row["alerts"] = {"total": 0, "critical": 0, "warning": 0}
		cogate_row["items"] = [
			{
				"type": "run_mode_skipped",
				"value": run_mode,
				"required_run_modes": required_run_modes,
				"ok": true,
			}
		]
		report["visual_performance_cogate"] = cogate_row
		return

	var cogate_items: Array = []
	var cogate_failures: int = 0
	var scenario_failures: int = 0

	if not FileAccess.file_exists(baseline_report):
		cogate_items.append({
			"type": "baseline_report_exists",
			"path": baseline_report,
			"ok": false,
		})
		cogate_failures += 1
		cogate_row["cogate_failures"] = cogate_failures
		cogate_row["scenario_failures"] = scenario_failures
		cogate_row["alerts"] = {"total": 0, "critical": 0, "warning": 0}
		cogate_row["items"] = cogate_items
		report["visual_performance_cogate"] = cogate_row
		if cogate_failures > max_cogate_failures:
			var missing_message: String = "visual-performance co-gate failures %d exceeds %d" % [cogate_failures, max_cogate_failures]
			if run_mode == "release_blocking":
				_push_result(report, "global", "visual_performance_cogate_failures_exceeded", false, missing_message)
			else:
				_push_warning(report, "global", "visual_performance_cogate_failures_pending", missing_message)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(baseline_report))
	if not (parsed is Dictionary):
		cogate_items.append({
			"type": "baseline_report_parse",
			"path": baseline_report,
			"ok": false,
		})
		cogate_failures += 1
		cogate_row["cogate_failures"] = cogate_failures
		cogate_row["scenario_failures"] = scenario_failures
		cogate_row["alerts"] = {"total": 0, "critical": 0, "warning": 0}
		cogate_row["items"] = cogate_items
		report["visual_performance_cogate"] = cogate_row
		if cogate_failures > max_cogate_failures:
			var parse_message: String = "visual-performance co-gate failures %d exceeds %d" % [cogate_failures, max_cogate_failures]
			if run_mode == "release_blocking":
				_push_result(report, "global", "visual_performance_cogate_failures_exceeded", false, parse_message)
			else:
				_push_warning(report, "global", "visual_performance_cogate_failures_pending", parse_message)
		return

	var baseline: Dictionary = parsed
	var alerts: Dictionary = baseline.get("alerts", {})
	var total_alerts: int = maxi(0, int(alerts.get("total", 0)))
	var critical_alerts: int = maxi(0, int(alerts.get("critical", 0)))
	var warning_alerts: int = maxi(0, int(alerts.get("warning", 0)))

	for row in [
		{"type": "max_alert_total", "value": total_alerts, "limit": max_alert_total},
		{"type": "max_alert_critical", "value": critical_alerts, "limit": max_alert_critical},
		{"type": "max_alert_warning", "value": warning_alerts, "limit": max_alert_warning},
	]:
		var ok: bool = int(row.get("value", 0)) <= int(row.get("limit", 0))
		cogate_items.append({
			"type": str(row.get("type", "")),
			"value": int(row.get("value", 0)),
			"limit": int(row.get("limit", 0)),
			"ok": ok,
		})
		if not ok:
			cogate_failures += 1

	var scenarios_variant: Variant = baseline.get("scenarios", [])
	var scenarios: Array = scenarios_variant if scenarios_variant is Array else []
	var scenario_index: Dictionary = _index_baseline_scenarios(scenarios)
	var baseline_targets: Dictionary = baseline.get("targets", {})
	var frame_targets: Dictionary = baseline_targets.get("frame_time_ms", {})
	var memory_targets: Dictionary = baseline_targets.get("memory_mb", {})

	var evaluation_scenarios: Array[String] = required_scenarios
	if evaluation_scenarios.is_empty():
		evaluation_scenarios = _sanitize_string_array(scenario_index.keys())

	for scenario_id in evaluation_scenarios:
		if not scenario_index.has(scenario_id):
			scenario_failures += 1
			cogate_items.append({
				"type": "required_scenario_missing",
				"scenario": scenario_id,
				"ok": false,
			})
			continue

		var scenario_row_variant: Variant = scenario_index.get(scenario_id, {})
		if not (scenario_row_variant is Dictionary):
			scenario_failures += 1
			cogate_items.append({
				"type": "scenario_row_invalid",
				"scenario": scenario_id,
				"ok": false,
			})
			continue

		var scenario_row: Dictionary = scenario_row_variant
		if scenario_row.has("error"):
			scenario_failures += 1
			cogate_items.append({
				"type": "scenario_runtime_error",
				"scenario": scenario_id,
				"error": str(scenario_row.get("error", "")),
				"ok": false,
			})
			continue

		var frame_target: Dictionary = frame_targets.get(scenario_id, {})
		var memory_target: Dictionary = memory_targets.get(scenario_id, {})
		var avg_frame_ms: float = float(scenario_row.get("avg_frame_ms", 0.0))
		var p95_frame_ms: float = float(scenario_row.get("p95_frame_ms", 0.0))
		var peak_memory_mb: float = float(scenario_row.get("peak_memory_mb", 0.0))

		if frame_target is Dictionary and not frame_target.is_empty():
			var avg_limit: float = float(frame_target.get("avg_max", avg_frame_ms)) * max_frame_ms_ratio
			var p95_limit: float = float(frame_target.get("p95_max", p95_frame_ms)) * max_frame_ms_ratio
			var avg_ok: bool = avg_frame_ms <= avg_limit
			var p95_ok: bool = p95_frame_ms <= p95_limit
			cogate_items.append({
				"type": "scenario_frame_avg",
				"scenario": scenario_id,
				"value": avg_frame_ms,
				"limit": avg_limit,
				"ok": avg_ok,
			})
			cogate_items.append({
				"type": "scenario_frame_p95",
				"scenario": scenario_id,
				"value": p95_frame_ms,
				"limit": p95_limit,
				"ok": p95_ok,
			})
			if not avg_ok:
				scenario_failures += 1
			if not p95_ok:
				scenario_failures += 1

		if memory_target is Dictionary and not memory_target.is_empty():
			var memory_limit: float = float(memory_target.get("peak_max", peak_memory_mb)) * max_memory_mb_ratio
			var memory_ok: bool = peak_memory_mb <= memory_limit
			cogate_items.append({
				"type": "scenario_peak_memory",
				"scenario": scenario_id,
				"value": peak_memory_mb,
				"limit": memory_limit,
				"ok": memory_ok,
			})
			if not memory_ok:
				scenario_failures += 1

	cogate_items.append({
		"type": "max_scenario_failures",
		"value": scenario_failures,
		"limit": max_scenario_failures,
		"ok": scenario_failures <= max_scenario_failures,
	})
	if scenario_failures > max_scenario_failures:
		cogate_failures += 1

	cogate_row["alerts"] = {
		"total": total_alerts,
		"critical": critical_alerts,
		"warning": warning_alerts,
	}
	cogate_row["scenario_failures"] = scenario_failures
	cogate_row["cogate_failures"] = cogate_failures
	cogate_row["items"] = cogate_items
	report["visual_performance_cogate"] = cogate_row

	if cogate_failures > max_cogate_failures:
		var message: String = "visual-performance co-gate failures %d exceeds %d" % [cogate_failures, max_cogate_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "visual_performance_cogate_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "visual_performance_cogate_failures_pending", message)


func _evaluate_cogate_threshold_template(
	report: Dictionary,
	template_errors: Array[String],
	run_mode: String
) -> void:
	var template_row: Dictionary = report.get("cogate_template", {})
	template_row["run_mode"] = run_mode
	template_row["errors"] = template_errors
	report["cogate_template"] = template_row

	for err in template_errors:
		var message: String = str(err)
		if run_mode == "release_blocking":
			_push_result(report, "global", "cogate_threshold_template_invalid", false, message)
		else:
			_push_warning(report, "global", "cogate_threshold_template_pending", message)


func _evaluate_cross_platform_alignment(
	report: Dictionary,
	alignment_cfg: Dictionary,
	run_mode: String,
	backend_tag: String
) -> void:
	if alignment_cfg.is_empty():
		return

	var alignment_row: Dictionary = report.get("cross_platform_alignment", {})
	var history_file: String = str(alignment_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var aggregation_window: int = maxi(1, int(alignment_cfg.get("aggregation_window", 80)))
	var required_run_modes: Array[String] = _sanitize_string_array(alignment_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(alignment_cfg.get("required_backends", []))
	var metric_limits: Dictionary = alignment_cfg.get("metric_limits", {})
	var max_missing_backends: int = maxi(0, int(alignment_cfg.get("max_missing_backends", 0)))
	var max_missing_run_modes: int = maxi(0, int(alignment_cfg.get("max_missing_run_modes", 0)))
	var max_alignment_failures: int = maxi(0, int(alignment_cfg.get("max_alignment_failures", 0)))

	alignment_row["history_file"] = history_file
	alignment_row["aggregation_window"] = aggregation_window
	alignment_row["required_run_modes"] = required_run_modes
	alignment_row["required_backends"] = required_backends
	alignment_row["metric_limits"] = metric_limits
	alignment_row["max_missing_backends"] = max_missing_backends
	alignment_row["max_missing_run_modes"] = max_missing_run_modes
	alignment_row["max_alignment_failures"] = max_alignment_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	alignment_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		alignment_row["alignment_failures"] = 0
		alignment_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["cross_platform_alignment"] = alignment_row
		return

	var items: Array = []
	var alignment_failures: int = 0

	if not FileAccess.file_exists(history_file):
		items.append({
			"type": "history_file_exists",
			"path": history_file,
			"ok": false,
		})
		alignment_failures += 1
		alignment_row["alignment_failures"] = alignment_failures
		alignment_row["items"] = items
		report["cross_platform_alignment"] = alignment_row
		if alignment_failures > max_alignment_failures:
			var missing_message: String = "cross-platform alignment failures %d exceeds %d" % [alignment_failures, max_alignment_failures]
			if run_mode == "release_blocking":
				_push_result(report, "global", "cross_platform_alignment_failures_exceeded", false, missing_message)
			else:
				_push_warning(report, "global", "cross_platform_alignment_failures_pending", missing_message)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
	if not (parsed is Dictionary):
		items.append({
			"type": "history_file_parse",
			"path": history_file,
			"ok": false,
		})
		alignment_failures += 1
		alignment_row["alignment_failures"] = alignment_failures
		alignment_row["items"] = items
		report["cross_platform_alignment"] = alignment_row
		if alignment_failures > max_alignment_failures:
			var parse_message: String = "cross-platform alignment failures %d exceeds %d" % [alignment_failures, max_alignment_failures]
			if run_mode == "release_blocking":
				_push_result(report, "global", "cross_platform_alignment_failures_exceeded", false, parse_message)
			else:
				_push_warning(report, "global", "cross_platform_alignment_failures_pending", parse_message)
		return

	var history_root: Dictionary = parsed
	var history_variant: Variant = history_root.get("history", [])
	var history_rows: Array = history_variant if history_variant is Array else []
	if history_rows.is_empty():
		items.append({
			"type": "history_entries",
			"value": 0,
			"limit": 1,
			"ok": false,
		})
		alignment_failures += 1
		alignment_row["alignment_failures"] = alignment_failures
		alignment_row["items"] = items
		report["cross_platform_alignment"] = alignment_row
		if alignment_failures > max_alignment_failures:
			var empty_message: String = "cross-platform alignment failures %d exceeds %d" % [alignment_failures, max_alignment_failures]
			if run_mode == "release_blocking":
				_push_result(report, "global", "cross_platform_alignment_failures_exceeded", false, empty_message)
			else:
				_push_warning(report, "global", "cross_platform_alignment_failures_pending", empty_message)
		return

	var sample_count: int = mini(aggregation_window, history_rows.size())
	var sample_slice: Array = history_rows.slice(history_rows.size() - sample_count, history_rows.size())

	var discovered_backends: Dictionary = {}
	var backend_mode_index: Dictionary = {}
	for row_var in sample_slice:
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		var row_mode: String = str(row.get("run_mode", "")).strip_edges()
		if row_backend.is_empty() or row_mode.is_empty():
			continue
		discovered_backends[row_backend] = true
		var mode_index: Dictionary = backend_mode_index.get(row_backend, {})
		mode_index[row_mode] = row
		backend_mode_index[row_backend] = mode_index

	if required_backends.is_empty():
		required_backends = _sanitize_string_array(discovered_backends.keys())

	var missing_backends: Array = []
	for backend_name in required_backends:
		if not backend_mode_index.has(backend_name):
			missing_backends.append(backend_name)
	items.append({
		"type": "missing_backends",
		"value": missing_backends.size(),
		"limit": max_missing_backends,
		"ok": missing_backends.size() <= max_missing_backends,
		"entries": missing_backends,
	})
	if missing_backends.size() > max_missing_backends:
		alignment_failures += 1

	var missing_run_mode_entries: Array = []
	for backend_name in required_backends:
		if not backend_mode_index.has(backend_name):
			continue
		var mode_rows: Dictionary = backend_mode_index.get(backend_name, {})
		for mode_name in required_run_modes:
			if not mode_rows.has(mode_name):
				missing_run_mode_entries.append("%s:%s" % [backend_name, mode_name])
	items.append({
		"type": "missing_run_modes",
		"value": missing_run_mode_entries.size(),
		"limit": max_missing_run_modes,
		"ok": missing_run_mode_entries.size() <= max_missing_run_modes,
		"entries": missing_run_mode_entries,
	})
	if missing_run_mode_entries.size() > max_missing_run_modes:
		alignment_failures += 1

	var metric_deltas: Dictionary = {}
	for metric_var in metric_limits.keys():
		var metric_name: String = str(metric_var).strip_edges()
		if metric_name.is_empty():
			continue
		var metric_limit: int = maxi(0, int(metric_limits.get(metric_var, 0)))
		var values: Array[float] = []
		for backend_name in required_backends:
			if not backend_mode_index.has(backend_name):
				continue
			var mode_rows: Dictionary = backend_mode_index.get(backend_name, {})
			for mode_name in required_run_modes:
				if not mode_rows.has(mode_name):
					continue
				var row_variant: Variant = mode_rows.get(mode_name, {})
				if not (row_variant is Dictionary):
					continue
				values.append(float((row_variant as Dictionary).get(metric_name, 0.0)))
		if values.size() < 2:
			metric_deltas[metric_name] = {
				"min": 0.0,
				"max": 0.0,
				"delta": 0.0,
				"samples": values.size(),
			}
			items.append({
				"type": "metric_alignment",
				"metric": metric_name,
				"delta": 0.0,
				"limit": metric_limit,
				"samples": values.size(),
				"ok": true,
			})
			continue

		var min_value: float = values[0]
		var max_value: float = values[0]
		for metric_value in values:
			min_value = minf(min_value, metric_value)
			max_value = maxf(max_value, metric_value)
		var delta: float = max_value - min_value
		metric_deltas[metric_name] = {
			"min": min_value,
			"max": max_value,
			"delta": delta,
			"samples": values.size(),
		}
		var metric_ok: bool = delta <= float(metric_limit)
		items.append({
			"type": "metric_alignment",
			"metric": metric_name,
			"delta": delta,
			"limit": metric_limit,
			"samples": values.size(),
			"ok": metric_ok,
		})
		if not metric_ok:
			alignment_failures += 1

	alignment_row["active_backend"] = backend_tag
	alignment_row["sample_count"] = sample_count
	alignment_row["missing_backends"] = missing_backends
	alignment_row["missing_run_mode_entries"] = missing_run_mode_entries
	alignment_row["metric_deltas"] = metric_deltas
	alignment_row["alignment_failures"] = alignment_failures
	alignment_row["items"] = items
	report["cross_platform_alignment"] = alignment_row

	if alignment_failures > max_alignment_failures:
		var message: String = "cross-platform alignment failures %d exceeds %d" % [alignment_failures, max_alignment_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "cross_platform_alignment_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "cross_platform_alignment_failures_pending", message)


func _evaluate_pressure_scenario_standardization(
	report: Dictionary,
	standard_cfg: Dictionary,
	run_mode: String
) -> void:
	if standard_cfg.is_empty():
		return

	var standard_row: Dictionary = report.get("pressure_scenario_standardization", {})
	var baseline_targets_file: String = str(standard_cfg.get("baseline_targets_file", "res://data/balance/quality_baseline_targets.json"))
	var baseline_report: String = str(standard_cfg.get("baseline_report", "user://quality_baseline_latest.json"))
	var required_run_modes: Array[String] = _sanitize_string_array(standard_cfg.get("required_run_modes", []))
	var required_scenarios: Array[String] = _sanitize_string_array(standard_cfg.get("required_scenarios", []))
	var max_avg_ratio: float = maxf(1.0, float(standard_cfg.get("max_avg_frame_ms_ratio", 1.1)))
	var max_p95_ratio: float = maxf(1.0, float(standard_cfg.get("max_p95_frame_ms_ratio", 1.12)))
	var max_memory_ratio: float = maxf(1.0, float(standard_cfg.get("max_peak_memory_mb_ratio", 1.1)))
	var max_standardization_failures: int = maxi(0, int(standard_cfg.get("max_standardization_failures", 0)))

	standard_row["baseline_targets_file"] = baseline_targets_file
	standard_row["baseline_report"] = baseline_report
	standard_row["required_run_modes"] = required_run_modes
	standard_row["required_scenarios"] = required_scenarios
	standard_row["max_avg_frame_ms_ratio"] = max_avg_ratio
	standard_row["max_p95_frame_ms_ratio"] = max_p95_ratio
	standard_row["max_peak_memory_mb_ratio"] = max_memory_ratio
	standard_row["max_standardization_failures"] = max_standardization_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	standard_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		standard_row["standardization_failures"] = 0
		standard_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["pressure_scenario_standardization"] = standard_row
		return

	var items: Array = []
	var standardization_failures: int = 0

	var targets_root: Dictionary = _read_json(baseline_targets_file)
	if targets_root.is_empty():
		items.append({
			"type": "baseline_targets_file_parse",
			"path": baseline_targets_file,
			"ok": false,
		})
		standardization_failures += 1

	var report_root: Dictionary = _read_json(baseline_report)
	if report_root.is_empty():
		items.append({
			"type": "baseline_report_parse",
			"path": baseline_report,
			"ok": false,
		})
		standardization_failures += 1

	var target_frame: Dictionary = {}
	var target_memory: Dictionary = {}
	if not targets_root.is_empty():
		var targets_row: Dictionary = targets_root.get("targets", {})
		target_frame = targets_row.get("frame_time_ms", {})
		target_memory = targets_row.get("memory_mb", {})
		if required_scenarios.is_empty():
			required_scenarios = _sanitize_string_array(targets_root.get("scenarios", []))

	var report_scenarios_variant: Variant = report_root.get("scenarios", []) if not report_root.is_empty() else []
	var report_scenarios: Array = report_scenarios_variant if report_scenarios_variant is Array else []
	var report_index: Dictionary = _index_baseline_scenarios(report_scenarios)

	for scenario_id in required_scenarios:
		if not report_index.has(scenario_id):
			standardization_failures += 1
			items.append({
				"type": "required_scenario_missing",
				"scenario": scenario_id,
				"ok": false,
			})
			continue

		var scenario_row_variant: Variant = report_index.get(scenario_id, {})
		if not (scenario_row_variant is Dictionary):
			standardization_failures += 1
			items.append({
				"type": "scenario_row_invalid",
				"scenario": scenario_id,
				"ok": false,
			})
			continue

		var scenario_row: Dictionary = scenario_row_variant
		if scenario_row.has("error"):
			standardization_failures += 1
			items.append({
				"type": "scenario_runtime_error",
				"scenario": scenario_id,
				"error": str(scenario_row.get("error", "")),
				"ok": false,
			})
			continue

		var frame_target_row: Dictionary = target_frame.get(scenario_id, {})
		var memory_target_row: Dictionary = target_memory.get(scenario_id, {})
		if frame_target_row.is_empty() or memory_target_row.is_empty():
			standardization_failures += 1
			items.append({
				"type": "scenario_target_missing",
				"scenario": scenario_id,
				"ok": false,
			})
			continue

		var avg_frame_ms: float = float(scenario_row.get("avg_frame_ms", 0.0))
		var p95_frame_ms: float = float(scenario_row.get("p95_frame_ms", 0.0))
		var peak_memory_mb: float = float(scenario_row.get("peak_memory_mb", 0.0))

		var avg_limit: float = float(frame_target_row.get("avg_max", avg_frame_ms)) * max_avg_ratio
		var p95_limit: float = float(frame_target_row.get("p95_max", p95_frame_ms)) * max_p95_ratio
		var memory_limit: float = float(memory_target_row.get("peak_max", peak_memory_mb)) * max_memory_ratio

		var avg_ok: bool = avg_frame_ms <= avg_limit
		var p95_ok: bool = p95_frame_ms <= p95_limit
		var memory_ok: bool = peak_memory_mb <= memory_limit

		items.append({
			"type": "scenario_avg_frame_ms",
			"scenario": scenario_id,
			"value": avg_frame_ms,
			"limit": avg_limit,
			"ok": avg_ok,
		})
		items.append({
			"type": "scenario_p95_frame_ms",
			"scenario": scenario_id,
			"value": p95_frame_ms,
			"limit": p95_limit,
			"ok": p95_ok,
		})
		items.append({
			"type": "scenario_peak_memory_mb",
			"scenario": scenario_id,
			"value": peak_memory_mb,
			"limit": memory_limit,
			"ok": memory_ok,
		})

		if not avg_ok:
			standardization_failures += 1
		if not p95_ok:
			standardization_failures += 1
		if not memory_ok:
			standardization_failures += 1

	items.append({
		"type": "max_standardization_failures",
		"value": standardization_failures,
		"limit": max_standardization_failures,
		"ok": standardization_failures <= max_standardization_failures,
	})

	standard_row["required_scenarios"] = required_scenarios
	standard_row["standardization_failures"] = standardization_failures
	standard_row["items"] = items
	report["pressure_scenario_standardization"] = standard_row

	if standardization_failures > max_standardization_failures:
		var message: String = "pressure standardization failures %d exceeds %d" % [standardization_failures, max_standardization_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "pressure_scenario_standardization_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "pressure_scenario_standardization_failures_pending", message)


func _evaluate_alignment_dashboard_refinement(
	report: Dictionary,
	dashboard_cfg: Dictionary,
	run_mode: String
) -> void:
	if dashboard_cfg.is_empty():
		return

	var dashboard_row: Dictionary = report.get("alignment_dashboard_refinement", {})
	var required_run_modes: Array[String] = _sanitize_string_array(dashboard_cfg.get("required_run_modes", []))
	var metric_weights: Dictionary = dashboard_cfg.get("metric_weights", {})
	var missing_backend_weight: float = maxf(0.0, float(dashboard_cfg.get("missing_backend_weight", 1.0)))
	var missing_run_mode_weight: float = maxf(0.0, float(dashboard_cfg.get("missing_run_mode_weight", 1.0)))
	var watch_score_threshold: float = maxf(0.0, float(dashboard_cfg.get("watch_score_threshold", 0.35)))
	var critical_score_threshold: float = maxf(watch_score_threshold, float(dashboard_cfg.get("critical_score_threshold", 0.7)))
	var max_dashboard_failures: int = maxi(0, int(dashboard_cfg.get("max_dashboard_failures", 0)))

	dashboard_row["required_run_modes"] = required_run_modes
	dashboard_row["metric_weights"] = metric_weights
	dashboard_row["missing_backend_weight"] = missing_backend_weight
	dashboard_row["missing_run_mode_weight"] = missing_run_mode_weight
	dashboard_row["watch_score_threshold"] = watch_score_threshold
	dashboard_row["critical_score_threshold"] = critical_score_threshold
	dashboard_row["max_dashboard_failures"] = max_dashboard_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	dashboard_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		dashboard_row["score"] = 0.0
		dashboard_row["severity"] = "skipped"
		dashboard_row["dashboard_failures"] = 0
		dashboard_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["alignment_dashboard_refinement"] = dashboard_row
		return

	var alignment_row: Dictionary = report.get("cross_platform_alignment", {})
	var metric_deltas: Dictionary = alignment_row.get("metric_deltas", {})
	var metric_limits: Dictionary = alignment_row.get("metric_limits", {})
	var missing_backends: Array = alignment_row.get("missing_backends", [])
	var missing_run_modes: Array = alignment_row.get("missing_run_mode_entries", [])

	var items: Array = []
	var score: float = 0.0
	var dashboard_failures: int = 0
	var missing_metrics: Array = []

	for metric_var in metric_weights.keys():
		var metric_name: String = str(metric_var).strip_edges()
		var weight: float = clampf(float(metric_weights.get(metric_var, 0.0)), 0.0, 5.0)
		if metric_name.is_empty() or weight <= 0.0:
			continue
		if not metric_deltas.has(metric_name):
			missing_metrics.append(metric_name)
			continue

		var metric_row_variant: Variant = metric_deltas.get(metric_name, {})
		if not (metric_row_variant is Dictionary):
			missing_metrics.append(metric_name)
			continue

		var metric_row: Dictionary = metric_row_variant
		var delta: float = float(metric_row.get("delta", 0.0))
		var limit: float = float(metric_limits.get(metric_name, 0.0))
		var normalized_delta: float = 0.0
		if limit <= 0.0:
			normalized_delta = 1.0 if delta > 0.0 else 0.0
		else:
			normalized_delta = delta / limit
		var weighted_value: float = normalized_delta * weight
		score += weighted_value
		items.append({
			"type": "metric_score",
			"metric": metric_name,
			"delta": delta,
			"limit": limit,
			"weight": weight,
			"weighted": weighted_value,
			"ok": normalized_delta <= 1.0,
		})

	if not missing_metrics.is_empty():
		dashboard_failures += 1
		items.append({
			"type": "missing_metrics",
			"entries": missing_metrics,
			"ok": false,
		})

	if missing_backends.size() > 0:
		var missing_backend_weighted: float = float(missing_backends.size()) * missing_backend_weight
		score += missing_backend_weighted
		items.append({
			"type": "missing_backends_weighted",
			"count": missing_backends.size(),
			"weight": missing_backend_weight,
			"weighted": missing_backend_weighted,
			"ok": false,
		})

	if missing_run_modes.size() > 0:
		var missing_run_mode_weighted: float = float(missing_run_modes.size()) * missing_run_mode_weight
		score += missing_run_mode_weighted
		items.append({
			"type": "missing_run_modes_weighted",
			"count": missing_run_modes.size(),
			"weight": missing_run_mode_weight,
			"weighted": missing_run_mode_weighted,
			"ok": false,
		})

	var severity: String = "ok"
	if score >= critical_score_threshold:
		severity = "critical"
		dashboard_failures += 1
	elif score >= watch_score_threshold:
		severity = "watch"

	items.append({
		"type": "dashboard_severity",
		"value": severity,
		"score": score,
		"watch_score_threshold": watch_score_threshold,
		"critical_score_threshold": critical_score_threshold,
		"ok": severity != "critical",
	})

	dashboard_row["score"] = score
	dashboard_row["severity"] = severity
	dashboard_row["missing_metrics"] = missing_metrics
	dashboard_row["dashboard_failures"] = dashboard_failures
	dashboard_row["items"] = items
	report["alignment_dashboard_refinement"] = dashboard_row

	if dashboard_failures > max_dashboard_failures:
		var message: String = "alignment dashboard failures %d exceeds %d" % [dashboard_failures, max_dashboard_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "alignment_dashboard_refinement_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "alignment_dashboard_refinement_failures_pending", message)


func _evaluate_pressure_alignment_convergence_gate(
	report: Dictionary,
	convergence_cfg: Dictionary,
	run_mode: String,
	backend_tag: String
) -> void:
	if convergence_cfg.is_empty():
		return

	var gate_row: Dictionary = report.get("pressure_alignment_convergence_gate", {})
	var required_run_modes: Array[String] = _sanitize_string_array(convergence_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(convergence_cfg.get("required_backends", []))
	var max_standardization_failures: int = maxi(0, int(convergence_cfg.get("max_standardization_failures", 0)))
	var max_alignment_failures: int = maxi(0, int(convergence_cfg.get("max_alignment_failures", 0)))
	var max_dashboard_failures: int = maxi(0, int(convergence_cfg.get("max_dashboard_failures", 0)))
	var max_critical_severity_count: int = maxi(0, int(convergence_cfg.get("max_critical_severity_count", 0)))
	var max_convergence_failures: int = maxi(0, int(convergence_cfg.get("max_convergence_failures", 0)))

	gate_row["required_run_modes"] = required_run_modes
	gate_row["required_backends"] = required_backends
	gate_row["max_standardization_failures"] = max_standardization_failures
	gate_row["max_alignment_failures"] = max_alignment_failures
	gate_row["max_dashboard_failures"] = max_dashboard_failures
	gate_row["max_critical_severity_count"] = max_critical_severity_count
	gate_row["max_convergence_failures"] = max_convergence_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	gate_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		gate_row["convergence_failures"] = 0
		gate_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["pressure_alignment_convergence_gate"] = gate_row
		return

	var standard_row: Dictionary = report.get("pressure_scenario_standardization", {})
	var alignment_row: Dictionary = report.get("cross_platform_alignment", {})
	var dashboard_row: Dictionary = report.get("alignment_dashboard_refinement", {})

	var standardization_failures: int = int(standard_row.get("standardization_failures", 0))
	var alignment_failures: int = int(alignment_row.get("alignment_failures", 0))
	var dashboard_failures: int = int(dashboard_row.get("dashboard_failures", 0))
	var dashboard_severity: String = str(dashboard_row.get("severity", "ok"))
	var critical_severity_count: int = 1 if dashboard_severity == "critical" else 0

	var items: Array = []
	var convergence_failures: int = 0

	var backend_ok: bool = required_backends.is_empty() or required_backends.has(backend_tag)
	items.append({
		"type": "active_backend_covered",
		"backend": backend_tag,
		"required_backends": required_backends,
		"ok": backend_ok,
	})
	if not backend_ok:
		convergence_failures += 1

	var standardization_ok: bool = standardization_failures <= max_standardization_failures
	items.append({
		"type": "standardization_failures",
		"value": standardization_failures,
		"limit": max_standardization_failures,
		"ok": standardization_ok,
	})
	if not standardization_ok:
		convergence_failures += 1

	var alignment_ok: bool = alignment_failures <= max_alignment_failures
	items.append({
		"type": "alignment_failures",
		"value": alignment_failures,
		"limit": max_alignment_failures,
		"ok": alignment_ok,
	})
	if not alignment_ok:
		convergence_failures += 1

	var dashboard_ok: bool = dashboard_failures <= max_dashboard_failures
	items.append({
		"type": "dashboard_failures",
		"value": dashboard_failures,
		"limit": max_dashboard_failures,
		"severity": dashboard_severity,
		"ok": dashboard_ok,
	})
	if not dashboard_ok:
		convergence_failures += 1

	var critical_ok: bool = critical_severity_count <= max_critical_severity_count
	items.append({
		"type": "critical_severity_count",
		"value": critical_severity_count,
		"limit": max_critical_severity_count,
		"ok": critical_ok,
	})
	if not critical_ok:
		convergence_failures += 1

	gate_row["backend_tag"] = backend_tag
	gate_row["standardization_failures"] = standardization_failures
	gate_row["alignment_failures"] = alignment_failures
	gate_row["dashboard_failures"] = dashboard_failures
	gate_row["dashboard_severity"] = dashboard_severity
	gate_row["critical_severity_count"] = critical_severity_count
	gate_row["convergence_failures"] = convergence_failures
	gate_row["items"] = items
	report["pressure_alignment_convergence_gate"] = gate_row

	if convergence_failures > max_convergence_failures:
		var message: String = "pressure alignment convergence failures %d exceeds %d" % [convergence_failures, max_convergence_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "pressure_alignment_convergence_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "pressure_alignment_convergence_failures_pending", message)


func _evaluate_regression_cycle_window_governance(
	report: Dictionary,
	cycle_cfg: Dictionary,
	run_mode: String,
	backend_tag: String
) -> void:
	if cycle_cfg.is_empty():
		return

	var cycle_row: Dictionary = report.get("regression_cycle_window_governance", {})
	var history_file: String = str(cycle_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var cycle_window_size: int = maxi(10, int(cycle_cfg.get("cycle_window_size", 20)))
	var min_cycle_entries: int = maxi(1, int(cycle_cfg.get("min_cycle_entries", 8)))
	var required_run_modes: Array[String] = _sanitize_string_array(cycle_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(cycle_cfg.get("required_backends", []))
	var max_warning_delta: int = maxi(0, int(cycle_cfg.get("max_warning_delta", 1)))
	var max_blocker_delta: int = maxi(0, int(cycle_cfg.get("max_blocker_delta", 0)))
	var max_alignment_score_delta: float = maxf(0.0, float(cycle_cfg.get("max_alignment_score_delta", 0.2)))
	var max_cycle_failures: int = maxi(0, int(cycle_cfg.get("max_cycle_failures", 0)))

	cycle_row["history_file"] = history_file
	cycle_row["cycle_window_size"] = cycle_window_size
	cycle_row["min_cycle_entries"] = min_cycle_entries
	cycle_row["required_run_modes"] = required_run_modes
	cycle_row["required_backends"] = required_backends
	cycle_row["max_warning_delta"] = max_warning_delta
	cycle_row["max_blocker_delta"] = max_blocker_delta
	cycle_row["max_alignment_score_delta"] = max_alignment_score_delta
	cycle_row["max_cycle_failures"] = max_cycle_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	cycle_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		cycle_row["cycle_failures"] = 0
		cycle_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["regression_cycle_window_governance"] = cycle_row
		return

	var items: Array = []
	var cycle_failures: int = 0

	if not FileAccess.file_exists(history_file):
		cycle_failures += 1
		items.append({
			"type": "history_file_missing",
			"path": history_file,
			"ok": false,
		})
		cycle_row["window_entries"] = 0
		cycle_row["cycle_failures"] = cycle_failures
		cycle_row["items"] = items
		report["regression_cycle_window_governance"] = cycle_row
		var missing_message: String = "regression cycle history file is missing: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "regression_cycle_window_history_missing", false, missing_message)
		else:
			_push_warning(report, "global", "regression_cycle_window_history_pending", missing_message)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
	if not (parsed is Array):
		cycle_failures += 1
		items.append({
			"type": "history_file_parse",
			"path": history_file,
			"ok": false,
		})
		cycle_row["window_entries"] = 0
		cycle_row["cycle_failures"] = cycle_failures
		cycle_row["items"] = items
		report["regression_cycle_window_governance"] = cycle_row
		var parse_message: String = "regression cycle history file parse failed: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "regression_cycle_window_history_parse_failed", false, parse_message)
		else:
			_push_warning(report, "global", "regression_cycle_window_history_parse_pending", parse_message)
		return

	var history_rows: Array = parsed
	var filtered_rows: Array = []
	for row_variant in history_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_run_mode: String = str(row.get("run_mode", "")).strip_edges()
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		if not required_run_modes.is_empty() and not required_run_modes.has(row_run_mode):
			continue
		if not required_backends.is_empty() and not required_backends.has(row_backend):
			continue
		filtered_rows.append(row)

	var window_rows: Array = []
	if filtered_rows.size() > cycle_window_size:
		window_rows = filtered_rows.slice(filtered_rows.size() - cycle_window_size, filtered_rows.size())
	else:
		window_rows = filtered_rows

	var window_entries: int = window_rows.size()
	cycle_row["window_entries"] = window_entries

	var entry_count_ok: bool = window_entries >= min_cycle_entries
	items.append({
		"type": "min_cycle_entries",
		"value": window_entries,
		"limit": min_cycle_entries,
		"ok": entry_count_ok,
	})
	if not entry_count_ok:
		cycle_failures += 1

	var missing_backend_entries: Array = []
	for backend_name in required_backends:
		var backend_found: bool = false
		for row_variant in window_rows:
			if row_variant is Dictionary and str((row_variant as Dictionary).get("backend_tag", "")).strip_edges() == backend_name:
				backend_found = true
				break
		if not backend_found:
			missing_backend_entries.append(backend_name)
	items.append({
		"type": "missing_backends",
		"value": missing_backend_entries,
		"ok": missing_backend_entries.is_empty(),
	})
	if not missing_backend_entries.is_empty():
		cycle_failures += 1

	var missing_mode_entries: Array = []
	for mode_name in required_run_modes:
		var mode_found: bool = false
		for row_variant in window_rows:
			if row_variant is Dictionary and str((row_variant as Dictionary).get("run_mode", "")).strip_edges() == mode_name:
				mode_found = true
				break
		if not mode_found:
			missing_mode_entries.append(mode_name)
	items.append({
		"type": "missing_run_modes",
		"value": missing_mode_entries,
		"ok": missing_mode_entries.is_empty(),
	})
	if not missing_mode_entries.is_empty():
		cycle_failures += 1

	var warning_min: int = 0
	var warning_max: int = 0
	var blocker_min: int = 0
	var blocker_max: int = 0
	var alignment_min: float = 0.0
	var alignment_max: float = 0.0
	if window_entries > 0:
		warning_min = int((window_rows[0] as Dictionary).get("warnings", 0))
		warning_max = warning_min
		blocker_min = int((window_rows[0] as Dictionary).get("blockers", 0))
		blocker_max = blocker_min
		alignment_min = float((window_rows[0] as Dictionary).get("alignment_dashboard_score", 0.0))
		alignment_max = alignment_min
		for row_variant in window_rows:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = row_variant
			var row_warnings: int = int(row.get("warnings", 0))
			var row_blockers: int = int(row.get("blockers", 0))
			var row_alignment_score: float = float(row.get("alignment_dashboard_score", 0.0))
			warning_min = mini(warning_min, row_warnings)
			warning_max = maxi(warning_max, row_warnings)
			blocker_min = mini(blocker_min, row_blockers)
			blocker_max = maxi(blocker_max, row_blockers)
			alignment_min = minf(alignment_min, row_alignment_score)
			alignment_max = maxf(alignment_max, row_alignment_score)

	var warning_delta: int = warning_max - warning_min
	var blocker_delta: int = blocker_max - blocker_min
	var alignment_score_delta: float = alignment_max - alignment_min

	var warning_delta_ok: bool = warning_delta <= max_warning_delta
	items.append({
		"type": "warning_delta",
		"value": warning_delta,
		"limit": max_warning_delta,
		"ok": warning_delta_ok,
	})
	if not warning_delta_ok:
		cycle_failures += 1

	var blocker_delta_ok: bool = blocker_delta <= max_blocker_delta
	items.append({
		"type": "blocker_delta",
		"value": blocker_delta,
		"limit": max_blocker_delta,
		"ok": blocker_delta_ok,
	})
	if not blocker_delta_ok:
		cycle_failures += 1

	var alignment_score_delta_ok: bool = alignment_score_delta <= max_alignment_score_delta
	items.append({
		"type": "alignment_score_delta",
		"value": alignment_score_delta,
		"limit": max_alignment_score_delta,
		"ok": alignment_score_delta_ok,
	})
	if not alignment_score_delta_ok:
		cycle_failures += 1

	cycle_row["active_backend"] = backend_tag
	cycle_row["warning_delta"] = warning_delta
	cycle_row["blocker_delta"] = blocker_delta
	cycle_row["alignment_score_delta"] = alignment_score_delta
	cycle_row["cycle_failures"] = cycle_failures
	cycle_row["items"] = items
	report["regression_cycle_window_governance"] = cycle_row

	if cycle_failures > max_cycle_failures:
		var message: String = "regression cycle failures %d exceeds %d" % [cycle_failures, max_cycle_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "regression_cycle_window_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "regression_cycle_window_failures_pending", message)


func _extract_metric_series(rows: Array, metric_name: String) -> Array[float]:
	var values: Array[float] = []
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		values.append(float((row_variant as Dictionary).get(metric_name, 0.0)))
	return values


func _calculate_series_slope(values: Array[float]) -> float:
	if values.size() <= 1:
		return 0.0
	var first_value: float = values[0]
	var last_value: float = values[values.size() - 1]
	return (last_value - first_value) / float(maxi(1, values.size() - 1))


func _is_feedback_clean_row(row: Dictionary, issue_metrics: Array[String]) -> bool:
	for metric_name in issue_metrics:
		if float(row.get(metric_name, 0.0)) > 0.0:
			return false
	return true


func _evaluate_multi_cycle_adaptive_gate(
	report: Dictionary,
	adaptive_cfg: Dictionary,
	run_mode: String,
	backend_tag: String
) -> void:
	if adaptive_cfg.is_empty():
		return

	var adaptive_row: Dictionary = report.get("multi_cycle_adaptive_gate", {})
	var history_file: String = str(adaptive_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var window_sizes: Dictionary = adaptive_cfg.get("window_sizes", {})
	var min_window_entries: int = maxi(1, int(adaptive_cfg.get("min_window_entries", 6)))
	var required_run_modes: Array[String] = _sanitize_string_array(adaptive_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(adaptive_cfg.get("required_backends", []))
	var max_warning_slopes: Dictionary = adaptive_cfg.get("max_warning_slopes", {})
	var max_blocker_slopes: Dictionary = adaptive_cfg.get("max_blocker_slopes", {})
	var max_missing_run_modes: int = maxi(0, int(adaptive_cfg.get("max_missing_run_modes", 0)))
	var max_missing_backends: int = maxi(0, int(adaptive_cfg.get("max_missing_backends", 0)))
	var max_adaptive_failures: int = maxi(0, int(adaptive_cfg.get("max_adaptive_failures", 0)))

	adaptive_row["history_file"] = history_file
	adaptive_row["window_sizes"] = window_sizes
	adaptive_row["min_window_entries"] = min_window_entries
	adaptive_row["required_run_modes"] = required_run_modes
	adaptive_row["required_backends"] = required_backends
	adaptive_row["max_warning_slopes"] = max_warning_slopes
	adaptive_row["max_blocker_slopes"] = max_blocker_slopes
	adaptive_row["max_missing_run_modes"] = max_missing_run_modes
	adaptive_row["max_missing_backends"] = max_missing_backends
	adaptive_row["max_adaptive_failures"] = max_adaptive_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	adaptive_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		adaptive_row["adaptive_failures"] = 0
		adaptive_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["multi_cycle_adaptive_gate"] = adaptive_row
		return

	var items: Array = []
	var adaptive_failures: int = 0

	if not FileAccess.file_exists(history_file):
		adaptive_failures += 1
		items.append({
			"type": "history_file_missing",
			"path": history_file,
			"ok": false,
		})
		adaptive_row["adaptive_failures"] = adaptive_failures
		adaptive_row["window_analysis"] = {}
		adaptive_row["items"] = items
		report["multi_cycle_adaptive_gate"] = adaptive_row
		var missing_message: String = "multi-cycle adaptive history file is missing: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "multi_cycle_adaptive_history_missing", false, missing_message)
		else:
			_push_warning(report, "global", "multi_cycle_adaptive_history_pending", missing_message)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
	if not (parsed is Array):
		adaptive_failures += 1
		items.append({
			"type": "history_file_parse",
			"path": history_file,
			"ok": false,
		})
		adaptive_row["adaptive_failures"] = adaptive_failures
		adaptive_row["window_analysis"] = {}
		adaptive_row["items"] = items
		report["multi_cycle_adaptive_gate"] = adaptive_row
		var parse_message: String = "multi-cycle adaptive history file parse failed: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "multi_cycle_adaptive_history_parse_failed", false, parse_message)
		else:
			_push_warning(report, "global", "multi_cycle_adaptive_history_parse_pending", parse_message)
		return

	var history_rows: Array = parsed
	var filtered_rows: Array = []
	for row_variant in history_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_run_mode: String = str(row.get("run_mode", "")).strip_edges()
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		if not required_run_modes.is_empty() and not required_run_modes.has(row_run_mode):
			continue
		if not required_backends.is_empty() and not required_backends.has(row_backend):
			continue
		filtered_rows.append(row)

	var backend_ok: bool = required_backends.is_empty() or required_backends.has(backend_tag)
	items.append({
		"type": "active_backend_covered",
		"backend": backend_tag,
		"required_backends": required_backends,
		"ok": backend_ok,
	})
	if not backend_ok:
		adaptive_failures += 1

	var window_labels: Array[String] = ["short", "mid", "long"]
	var window_analysis: Dictionary = {}
	var coverage_rows: Array = []
	for label in window_labels:
		var window_size: int = maxi(1, int(window_sizes.get(label, min_window_entries)))
		var window_rows: Array = []
		if filtered_rows.size() > window_size:
			window_rows = filtered_rows.slice(filtered_rows.size() - window_size, filtered_rows.size())
		else:
			window_rows = filtered_rows
		if label == "long":
			coverage_rows = window_rows

		var entries: int = window_rows.size()
		var entries_ok: bool = entries >= min_window_entries
		items.append({
			"type": "%s_window_entries" % label,
			"value": entries,
			"limit": min_window_entries,
			"ok": entries_ok,
		})
		if not entries_ok:
			adaptive_failures += 1

		var warning_slope: float = _calculate_series_slope(_extract_metric_series(window_rows, "warnings"))
		var blocker_slope: float = _calculate_series_slope(_extract_metric_series(window_rows, "blockers"))
		var warning_limit: float = maxf(0.0, float(max_warning_slopes.get(label, 0.0)))
		var blocker_limit: float = maxf(0.0, float(max_blocker_slopes.get(label, 0.0)))
		var warning_ok: bool = warning_slope <= warning_limit
		var blocker_ok: bool = blocker_slope <= blocker_limit

		items.append({
			"type": "%s_warning_slope" % label,
			"value": warning_slope,
			"limit": warning_limit,
			"ok": warning_ok,
		})
		if not warning_ok:
			adaptive_failures += 1

		items.append({
			"type": "%s_blocker_slope" % label,
			"value": blocker_slope,
			"limit": blocker_limit,
			"ok": blocker_ok,
		})
		if not blocker_ok:
			adaptive_failures += 1

		window_analysis[label] = {
			"window_size": window_size,
			"entries": entries,
			"warning_slope": warning_slope,
			"max_warning_slope": warning_limit,
			"blocker_slope": blocker_slope,
			"max_blocker_slope": blocker_limit,
		}

	if coverage_rows.is_empty():
		coverage_rows = filtered_rows
	var seen_backends: Dictionary = {}
	var seen_run_modes: Dictionary = {}
	for row_variant in coverage_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		var row_mode: String = str(row.get("run_mode", "")).strip_edges()
		if not row_backend.is_empty():
			seen_backends[row_backend] = true
		if not row_mode.is_empty():
			seen_run_modes[row_mode] = true

	var missing_backends: Array = []
	for backend_name in required_backends:
		if not seen_backends.has(backend_name):
			missing_backends.append(backend_name)
	var missing_run_modes: Array = []
	for mode_name in required_run_modes:
		if not seen_run_modes.has(mode_name):
			missing_run_modes.append(mode_name)

	var missing_backends_ok: bool = missing_backends.size() <= max_missing_backends
	items.append({
		"type": "missing_backends",
		"value": missing_backends,
		"limit": max_missing_backends,
		"ok": missing_backends_ok,
	})
	if not missing_backends_ok:
		adaptive_failures += 1

	var missing_modes_ok: bool = missing_run_modes.size() <= max_missing_run_modes
	items.append({
		"type": "missing_run_modes",
		"value": missing_run_modes,
		"limit": max_missing_run_modes,
		"ok": missing_modes_ok,
	})
	if not missing_modes_ok:
		adaptive_failures += 1

	adaptive_row["window_entries"] = {
		"filtered_rows": filtered_rows.size(),
		"coverage_window_entries": coverage_rows.size(),
	}
	adaptive_row["window_analysis"] = window_analysis
	adaptive_row["missing_backends"] = missing_backends
	adaptive_row["missing_run_modes"] = missing_run_modes
	adaptive_row["adaptive_failures"] = adaptive_failures
	adaptive_row["items"] = items
	report["multi_cycle_adaptive_gate"] = adaptive_row

	if adaptive_failures > max_adaptive_failures:
		var message: String = "multi-cycle adaptive failures %d exceeds %d" % [adaptive_failures, max_adaptive_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "multi_cycle_adaptive_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "multi_cycle_adaptive_failures_pending", message)


func _evaluate_release_feedback_governance(
	report: Dictionary,
	feedback_cfg: Dictionary,
	run_mode: String,
	backend_tag: String
) -> void:
	if feedback_cfg.is_empty():
		return

	var feedback_row: Dictionary = report.get("release_feedback_governance", {})
	var history_file: String = str(feedback_cfg.get("history_file", "user://visual_snapshot_approval_archive.json"))
	var feedback_window_size: int = maxi(5, int(feedback_cfg.get("feedback_window_size", 24)))
	var min_feedback_entries: int = maxi(1, int(feedback_cfg.get("min_feedback_entries", 8)))
	var required_run_modes: Array[String] = _sanitize_string_array(feedback_cfg.get("required_run_modes", []))
	var required_backends: Array[String] = _sanitize_string_array(feedback_cfg.get("required_backends", []))
	var issue_metrics: Array[String] = _sanitize_string_array(feedback_cfg.get("issue_metrics", []))
	var min_closure_rate: float = clampf(float(feedback_cfg.get("min_closure_rate", 0.7)), 0.0, 1.0)
	var max_unresolved_issues: int = maxi(0, int(feedback_cfg.get("max_unresolved_issues", 2)))
	var max_missing_run_modes: int = maxi(0, int(feedback_cfg.get("max_missing_run_modes", 0)))
	var max_missing_backends: int = maxi(0, int(feedback_cfg.get("max_missing_backends", 0)))
	var max_feedback_failures: int = maxi(0, int(feedback_cfg.get("max_feedback_failures", 0)))

	feedback_row["history_file"] = history_file
	feedback_row["feedback_window_size"] = feedback_window_size
	feedback_row["min_feedback_entries"] = min_feedback_entries
	feedback_row["required_run_modes"] = required_run_modes
	feedback_row["required_backends"] = required_backends
	feedback_row["issue_metrics"] = issue_metrics
	feedback_row["min_closure_rate"] = min_closure_rate
	feedback_row["max_unresolved_issues"] = max_unresolved_issues
	feedback_row["max_missing_run_modes"] = max_missing_run_modes
	feedback_row["max_missing_backends"] = max_missing_backends
	feedback_row["max_feedback_failures"] = max_feedback_failures

	var enabled_for_mode: bool = required_run_modes.is_empty() or required_run_modes.has(run_mode)
	feedback_row["enabled_for_mode"] = enabled_for_mode
	if not enabled_for_mode:
		feedback_row["feedback_failures"] = 0
		feedback_row["items"] = [{
			"type": "run_mode_skipped",
			"value": run_mode,
			"required_run_modes": required_run_modes,
			"ok": true,
		}]
		report["release_feedback_governance"] = feedback_row
		return

	var items: Array = []
	var feedback_failures: int = 0

	if not FileAccess.file_exists(history_file):
		feedback_failures += 1
		items.append({
			"type": "history_file_missing",
			"path": history_file,
			"ok": false,
		})
		feedback_row["feedback_failures"] = feedback_failures
		feedback_row["window_entries"] = 0
		feedback_row["items"] = items
		report["release_feedback_governance"] = feedback_row
		var missing_message: String = "release feedback history file is missing: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "release_feedback_history_missing", false, missing_message)
		else:
			_push_warning(report, "global", "release_feedback_history_pending", missing_message)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(history_file))
	if not (parsed is Array):
		feedback_failures += 1
		items.append({
			"type": "history_file_parse",
			"path": history_file,
			"ok": false,
		})
		feedback_row["feedback_failures"] = feedback_failures
		feedback_row["window_entries"] = 0
		feedback_row["items"] = items
		report["release_feedback_governance"] = feedback_row
		var parse_message: String = "release feedback history file parse failed: %s" % history_file
		if run_mode == "release_blocking":
			_push_result(report, "global", "release_feedback_history_parse_failed", false, parse_message)
		else:
			_push_warning(report, "global", "release_feedback_history_parse_pending", parse_message)
		return

	var history_rows: Array = parsed
	var filtered_rows: Array = []
	for row_variant in history_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_run_mode: String = str(row.get("run_mode", "")).strip_edges()
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		if not required_run_modes.is_empty() and not required_run_modes.has(row_run_mode):
			continue
		if not required_backends.is_empty() and not required_backends.has(row_backend):
			continue
		filtered_rows.append(row)

	var window_rows: Array = []
	if filtered_rows.size() > feedback_window_size:
		window_rows = filtered_rows.slice(filtered_rows.size() - feedback_window_size, filtered_rows.size())
	else:
		window_rows = filtered_rows

	var window_entries: int = window_rows.size()
	feedback_row["window_entries"] = window_entries

	var backend_ok: bool = required_backends.is_empty() or required_backends.has(backend_tag)
	items.append({
		"type": "active_backend_covered",
		"backend": backend_tag,
		"required_backends": required_backends,
		"ok": backend_ok,
	})
	if not backend_ok:
		feedback_failures += 1

	var entries_ok: bool = window_entries >= min_feedback_entries
	items.append({
		"type": "min_feedback_entries",
		"value": window_entries,
		"limit": min_feedback_entries,
		"ok": entries_ok,
	})
	if not entries_ok:
		feedback_failures += 1

	var seen_backends: Dictionary = {}
	var seen_run_modes: Dictionary = {}
	for row_variant in window_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_backend: String = str(row.get("backend_tag", "")).strip_edges()
		var row_mode: String = str(row.get("run_mode", "")).strip_edges()
		if not row_backend.is_empty():
			seen_backends[row_backend] = true
		if not row_mode.is_empty():
			seen_run_modes[row_mode] = true

	var missing_backends: Array = []
	for backend_name in required_backends:
		if not seen_backends.has(backend_name):
			missing_backends.append(backend_name)
	var missing_run_modes: Array = []
	for mode_name in required_run_modes:
		if not seen_run_modes.has(mode_name):
			missing_run_modes.append(mode_name)

	var missing_backends_ok: bool = missing_backends.size() <= max_missing_backends
	items.append({
		"type": "missing_backends",
		"value": missing_backends,
		"limit": max_missing_backends,
		"ok": missing_backends_ok,
	})
	if not missing_backends_ok:
		feedback_failures += 1

	var missing_modes_ok: bool = missing_run_modes.size() <= max_missing_run_modes
	items.append({
		"type": "missing_run_modes",
		"value": missing_run_modes,
		"limit": max_missing_run_modes,
		"ok": missing_modes_ok,
	})
	if not missing_modes_ok:
		feedback_failures += 1

	var issue_count: int = 0
	var closed_issue_count: int = 0
	var unresolved_issues: Array = []
	for row_index in range(window_rows.size()):
		var row_variant: Variant = window_rows[row_index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if _is_feedback_clean_row(row, issue_metrics):
			continue
		issue_count += 1
		var resolved: bool = false
		for next_index in range(row_index + 1, window_rows.size()):
			var next_variant: Variant = window_rows[next_index]
			if not (next_variant is Dictionary):
				continue
			if _is_feedback_clean_row(next_variant as Dictionary, issue_metrics):
				resolved = true
				break
		if resolved:
			closed_issue_count += 1
		else:
			unresolved_issues.append({
				"index": row_index,
				"timestamp": int(row.get("timestamp", 0)),
				"run_mode": str(row.get("run_mode", "")),
				"backend_tag": str(row.get("backend_tag", "")),
			})

	var closure_rate: float = 1.0
	if issue_count > 0:
		closure_rate = float(closed_issue_count) / float(issue_count)

	var closure_rate_ok: bool = closure_rate >= min_closure_rate
	items.append({
		"type": "closure_rate",
		"value": closure_rate,
		"limit": min_closure_rate,
		"issues": issue_count,
		"closed": closed_issue_count,
		"ok": closure_rate_ok,
	})
	if not closure_rate_ok:
		feedback_failures += 1

	var unresolved_ok: bool = unresolved_issues.size() <= max_unresolved_issues
	items.append({
		"type": "unresolved_issues",
		"value": unresolved_issues.size(),
		"limit": max_unresolved_issues,
		"ok": unresolved_ok,
	})
	if not unresolved_ok:
		feedback_failures += 1

	feedback_row["issue_count"] = issue_count
	feedback_row["closed_issue_count"] = closed_issue_count
	feedback_row["unresolved_issues"] = unresolved_issues
	feedback_row["closure_rate"] = closure_rate
	feedback_row["missing_backends"] = missing_backends
	feedback_row["missing_run_modes"] = missing_run_modes
	feedback_row["feedback_failures"] = feedback_failures
	feedback_row["items"] = items
	report["release_feedback_governance"] = feedback_row

	if feedback_failures > max_feedback_failures:
		var message: String = "release feedback governance failures %d exceeds %d" % [feedback_failures, max_feedback_failures]
		if run_mode == "release_blocking":
			_push_result(report, "global", "release_feedback_governance_failures_exceeded", false, message)
		else:
			_push_warning(report, "global", "release_feedback_governance_failures_pending", message)


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
	# 每次写新报告前先保留上一份，供趋势比较和回退诊断直接复用。
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
	# 所有检查统一走一个结果入口，保证 json / markdown 汇总口径完全一致。
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

	# Markdown 报告保留人类快速阅读的摘要层，详细机器数据仍以 JSON 为准。
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
	var stability_row: Dictionary = report.get("stability_scoring", {})
	lines.append("- stability_scoring: score=%.3f, tier=%s, confidence=%.3f/%.3f, failures=%d" % [
		float(stability_row.get("score", 0.0)),
		str(stability_row.get("tier", "D")),
		float(stability_row.get("confidence", 0.0)),
		float(stability_row.get("min_confidence", 0.0)),
		int(stability_row.get("scoring_failures", 0)),
	])
	var dashboard_row: Dictionary = report.get("convergence_dashboard", {})
	lines.append("- convergence_dashboard: failures=%d/%d, blockers=%d/%d, warnings=%d/%d" % [
		int(dashboard_row.get("dashboard_failures", 0)),
		int(dashboard_row.get("max_dashboard_failures", 0)),
		int(dashboard_row.get("blockers", 0)),
		int(dashboard_row.get("max_blockers", 0)),
		int(dashboard_row.get("warnings", 0)),
		int(dashboard_row.get("max_warnings", 0)),
	])
	var ci_signal_row: Dictionary = report.get("ci_signal", {})
	var ci_signal_payload: Dictionary = ci_signal_row.get("signal", {})
	lines.append("- ci_signal_contract: run_mode=%s, tier=%s, required_fields=%d, failures=%d/%d" % [
		str(ci_signal_payload.get("run_mode", "")),
		str(ci_signal_payload.get("stability_tier", "")),
		(ci_signal_row.get("required_fields", []) as Array).size(),
		int(ci_signal_row.get("contract_failures", 0)),
		int(ci_signal_row.get("max_contract_failures", 0)),
	])
	var convergence_trend_row: Dictionary = report.get("convergence_trend", {})
	lines.append("- convergence_trend: failures=%d/%d, worsening=%d/%d, improving=%d/%d" % [
		int(convergence_trend_row.get("trend_failures", 0)),
		int(convergence_trend_row.get("max_trend_failures", 0)),
		(convergence_trend_row.get("worsening_metrics", []) as Array).size(),
		int(convergence_trend_row.get("max_worsening_metrics", 0)),
		(convergence_trend_row.get("improving_metrics", []) as Array).size(),
		int(convergence_trend_row.get("min_improving_metrics", 0)),
	])
	var lifecycle_linkage_row: Dictionary = report.get("exception_lifecycle_linkage", {})
	lines.append("- exception_lifecycle_linkage: failures=%d/%d, transitions=%d/%d, missing_states=%d" % [
		int(lifecycle_linkage_row.get("linkage_failures", 0)),
		int(lifecycle_linkage_row.get("max_linkage_failures", 0)),
		int(lifecycle_linkage_row.get("transition_count", 0)),
		int(lifecycle_linkage_row.get("min_transition_count", 0)),
		(lifecycle_linkage_row.get("missing_required_states", []) as Array).size(),
	])
	var cogate_row: Dictionary = report.get("visual_performance_cogate", {})
	var cogate_alerts: Dictionary = cogate_row.get("alerts", {})
	lines.append("- visual_performance_cogate: failures=%d/%d, alerts(total=%d,critical=%d,warning=%d), scenario_failures=%d/%d" % [
		int(cogate_row.get("cogate_failures", 0)),
		int(cogate_row.get("max_cogate_failures", 0)),
		int(cogate_alerts.get("total", 0)),
		int(cogate_alerts.get("critical", 0)),
		int(cogate_alerts.get("warning", 0)),
		int(cogate_row.get("scenario_failures", 0)),
		int(cogate_row.get("max_scenario_failures", 0)),
	])
	var cogate_template_row: Dictionary = report.get("cogate_template", {})
	lines.append("- cogate_template: run_mode=%s, template=%s, errors=%d" % [
		str(cogate_template_row.get("run_mode", "")),
		str(cogate_template_row.get("template", "")),
		(cogate_template_row.get("errors", []) as Array).size(),
	])
	var alignment_row: Dictionary = report.get("cross_platform_alignment", {})
	lines.append("- cross_platform_alignment: failures=%d/%d, samples=%d, missing_backends=%d/%d, missing_run_modes=%d/%d" % [
		int(alignment_row.get("alignment_failures", 0)),
		int(alignment_row.get("max_alignment_failures", 0)),
		int(alignment_row.get("sample_count", 0)),
		(alignment_row.get("missing_backends", []) as Array).size(),
		int(alignment_row.get("max_missing_backends", 0)),
		(alignment_row.get("missing_run_mode_entries", []) as Array).size(),
		int(alignment_row.get("max_missing_run_modes", 0)),
	])
	var standardization_summary_row: Dictionary = report.get("pressure_scenario_standardization", {})
	lines.append("- pressure_scenario_standardization: failures=%d/%d, scenario_failures=%d, scenarios=%d" % [
		int(standardization_summary_row.get("standardization_failures", 0)),
		int(standardization_summary_row.get("max_standardization_failures", 0)),
		int(standardization_summary_row.get("scenario_failures", 0)),
		(_sanitize_string_array(standardization_summary_row.get("required_scenarios", []))).size(),
	])
	var refinement_summary_row: Dictionary = report.get("alignment_dashboard_refinement", {})
	lines.append("- alignment_dashboard_refinement: score=%.3f, severity=%s, failures=%d/%d" % [
		float(refinement_summary_row.get("score", 0.0)),
		str(refinement_summary_row.get("severity", "normal")),
		int(refinement_summary_row.get("dashboard_failures", 0)),
		int(refinement_summary_row.get("max_dashboard_failures", 0)),
	])
	var convergence_gate_summary_row: Dictionary = report.get("pressure_alignment_convergence_gate", {})
	lines.append("- pressure_alignment_convergence_gate: failures=%d/%d, standardization=%d, alignment=%d, dashboard=%d" % [
		int(convergence_gate_summary_row.get("convergence_failures", 0)),
		int(convergence_gate_summary_row.get("max_convergence_failures", 0)),
		int(convergence_gate_summary_row.get("standardization_failures", 0)),
		int(convergence_gate_summary_row.get("alignment_failures", 0)),
		int(convergence_gate_summary_row.get("dashboard_failures", 0)),
	])
	var cycle_summary_row: Dictionary = report.get("regression_cycle_window_governance", {})
	lines.append("- regression_cycle_window_governance: failures=%d/%d, window_entries=%d, warning_delta=%d, blocker_delta=%d, alignment_score_delta=%.3f" % [
		int(cycle_summary_row.get("cycle_failures", 0)),
		int(cycle_summary_row.get("max_cycle_failures", 0)),
		int(cycle_summary_row.get("window_entries", 0)),
		int(cycle_summary_row.get("warning_delta", 0)),
		int(cycle_summary_row.get("blocker_delta", 0)),
		float(cycle_summary_row.get("alignment_score_delta", 0.0)),
	])
	var adaptive_summary_row: Dictionary = report.get("multi_cycle_adaptive_gate", {})
	var adaptive_windows: Dictionary = adaptive_summary_row.get("window_analysis", {})
	var adaptive_short: Dictionary = adaptive_windows.get("short", {})
	var adaptive_mid: Dictionary = adaptive_windows.get("mid", {})
	var adaptive_long: Dictionary = adaptive_windows.get("long", {})
	lines.append("- multi_cycle_adaptive_gate: failures=%d/%d, short(w=%.3f,b=%.3f), mid(w=%.3f,b=%.3f), long(w=%.3f,b=%.3f)" % [
		int(adaptive_summary_row.get("adaptive_failures", 0)),
		int(adaptive_summary_row.get("max_adaptive_failures", 0)),
		float(adaptive_short.get("warning_slope", 0.0)),
		float(adaptive_short.get("blocker_slope", 0.0)),
		float(adaptive_mid.get("warning_slope", 0.0)),
		float(adaptive_mid.get("blocker_slope", 0.0)),
		float(adaptive_long.get("warning_slope", 0.0)),
		float(adaptive_long.get("blocker_slope", 0.0)),
	])
	var feedback_summary_row: Dictionary = report.get("release_feedback_governance", {})
	lines.append("- release_feedback_governance: failures=%d/%d, closure_rate=%.3f, unresolved=%d/%d, issues=%d" % [
		int(feedback_summary_row.get("feedback_failures", 0)),
		int(feedback_summary_row.get("max_feedback_failures", 0)),
		float(feedback_summary_row.get("closure_rate", 1.0)),
		(feedback_summary_row.get("unresolved_issues", []) as Array).size(),
		int(feedback_summary_row.get("max_unresolved_issues", 0)),
		int(feedback_summary_row.get("issue_count", 0)),
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
	lines.append("## Stability Scoring")
	lines.append("- score: %.3f" % float(stability_row.get("score", 0.0)))
	lines.append("- tier: %s" % str(stability_row.get("tier", "D")))
	lines.append("- confidence: %.3f / %.3f" % [
		float(stability_row.get("confidence", 0.0)),
		float(stability_row.get("min_confidence", 0.0)),
	])
	lines.append("- components: matching=%.3f warnings=%.3f blockers=%.3f tracking=%.3f" % [
		float(stability_row.get("matching_component", 0.0)),
		float(stability_row.get("warnings_component", 0.0)),
		float(stability_row.get("blockers_component", 0.0)),
		float(stability_row.get("tracking_component", 0.0)),
	])
	var scoring_items: Array = stability_row.get("items", [])
	for item in scoring_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Convergence Dashboard")
	lines.append("- dashboard_failures: %d / %d" % [
		int(dashboard_row.get("dashboard_failures", 0)),
		int(dashboard_row.get("max_dashboard_failures", 0)),
	])
	var dashboard_items: Array = dashboard_row.get("items", [])
	for item in dashboard_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", 0)),
				str(row.get("limit", 0)),
			])

	lines.append("")
	lines.append("## CI Signal Contract")
	lines.append("- signal_run_mode: %s" % str(ci_signal_payload.get("run_mode", "")))
	lines.append("- signal_strategy: %s" % str(ci_signal_payload.get("strategy", "")))
	lines.append("- signal_tier: %s" % str(ci_signal_payload.get("stability_tier", "")))
	lines.append("- signal_score: %.3f" % float(ci_signal_payload.get("stability_score", 0.0)))
	lines.append("- contract_failures: %d / %d" % [
		int(ci_signal_row.get("contract_failures", 0)),
		int(ci_signal_row.get("max_contract_failures", 0)),
	])
	var ci_items: Array = ci_signal_row.get("items", [])
	for item in ci_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			if str(row.get("type", "")) == "required_field":
				lines.append("- [%s] required_field %s" % [status, str(row.get("field", ""))])
			else:
				lines.append("- [%s] %s -> %s / %s" % [
					status,
					str(row.get("type", "")),
					str(row.get("value", "")),
					str(row.get("limit", "")),
				])

	lines.append("")
	lines.append("## Convergence Trend Reinforcement")
	lines.append("- history_file: %s" % str(convergence_trend_row.get("history_file", "")))
	lines.append("- sample_windows: short=%d, long=%d, min_samples=%d" % [
		int(convergence_trend_row.get("short_sample_count", 0)),
		int(convergence_trend_row.get("long_sample_count", 0)),
		int(convergence_trend_row.get("min_samples", 0)),
	])
	lines.append("- trend_failures: %d / %d" % [
		int(convergence_trend_row.get("trend_failures", 0)),
		int(convergence_trend_row.get("max_trend_failures", 0)),
	])
	var metric_deltas: Dictionary = convergence_trend_row.get("metric_deltas", {})
	for metric_name in metric_deltas.keys():
		var row_variant: Variant = metric_deltas.get(metric_name, {})
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			lines.append("- %s: short_avg=%.3f long_avg=%.3f delta=%.3f" % [
				str(metric_name),
				float(row.get("short_avg", 0.0)),
				float(row.get("long_avg", 0.0)),
				float(row.get("delta", 0.0)),
			])
	var trend_items: Array = convergence_trend_row.get("items", [])
	for item in trend_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Exception Lifecycle Linkage")
	lines.append("- linkage_failures: %d / %d" % [
		int(lifecycle_linkage_row.get("linkage_failures", 0)),
		int(lifecycle_linkage_row.get("max_linkage_failures", 0)),
	])
	lines.append("- transition_count: %d / %d" % [
		int(lifecycle_linkage_row.get("transition_count", 0)),
		int(lifecycle_linkage_row.get("min_transition_count", 0)),
	])
	lines.append("- state_counts: %s" % JSON.stringify(lifecycle_linkage_row.get("state_counts", {})))
	var linkage_items: Array = lifecycle_linkage_row.get("items", [])
	for item in linkage_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s" % [status, str(row.get("type", "")), str(row.get("value", row.get("limit", "")))])

	lines.append("")
	lines.append("## Visual-Performance Co-Gate")
	lines.append("- baseline_report: %s" % str(cogate_row.get("baseline_report", "")))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(cogate_row.get("required_run_modes", []))))
	lines.append("- alerts: total=%d/%d, critical=%d/%d, warning=%d/%d" % [
		int(cogate_alerts.get("total", 0)),
		int(cogate_row.get("max_alert_total", 0)),
		int(cogate_alerts.get("critical", 0)),
		int(cogate_row.get("max_alert_critical", 0)),
		int(cogate_alerts.get("warning", 0)),
		int(cogate_row.get("max_alert_warning", 0)),
	])
	lines.append("- scenario_failures: %d/%d" % [
		int(cogate_row.get("scenario_failures", 0)),
		int(cogate_row.get("max_scenario_failures", 0)),
	])
	lines.append("- cogate_failures: %d/%d" % [
		int(cogate_row.get("cogate_failures", 0)),
		int(cogate_row.get("max_cogate_failures", 0)),
	])
	var cogate_items: Array = cogate_row.get("items", [])
	for item in cogate_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("scenario", ""))),
				str(row.get("limit", "")),
			])

	lines.append("")
	lines.append("## Co-Gate Threshold Template")
	lines.append("- run_mode: %s" % str(cogate_template_row.get("run_mode", "")))
	lines.append("- template: %s" % str(cogate_template_row.get("template", "")))
	var cogate_template_errors: Array = cogate_template_row.get("errors", [])
	for template_error in cogate_template_errors:
		lines.append("- error: %s" % str(template_error))

	lines.append("")
	lines.append("## Cross-Platform Alignment")
	lines.append("- history_file: %s" % str(alignment_row.get("history_file", "")))
	lines.append("- aggregation_window: %d" % int(alignment_row.get("aggregation_window", 0)))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(alignment_row.get("required_run_modes", []))))
	lines.append("- required_backends: %s" % ", ".join(_sanitize_string_array(alignment_row.get("required_backends", []))))
	lines.append("- alignment_failures: %d/%d" % [
		int(alignment_row.get("alignment_failures", 0)),
		int(alignment_row.get("max_alignment_failures", 0)),
	])
	lines.append("- missing_backends: %s" % ", ".join(_sanitize_string_array(alignment_row.get("missing_backends", []))))
	lines.append("- missing_run_mode_entries: %s" % ", ".join(_sanitize_string_array(alignment_row.get("missing_run_mode_entries", []))))
	var alignment_metric_deltas: Dictionary = alignment_row.get("metric_deltas", {})
	for metric_name in alignment_metric_deltas.keys():
		var metric_row_variant: Variant = alignment_metric_deltas.get(metric_name, {})
		if metric_row_variant is Dictionary:
			var metric_row: Dictionary = metric_row_variant
			lines.append("- %s: min=%.3f max=%.3f delta=%.3f samples=%d" % [
				str(metric_name),
				float(metric_row.get("min", 0.0)),
				float(metric_row.get("max", 0.0)),
				float(metric_row.get("delta", 0.0)),
				int(metric_row.get("samples", 0)),
			])
	var alignment_items: Array = alignment_row.get("items", [])
	for item in alignment_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("delta", row.get("entries", "")))),
				str(row.get("limit", "")),
			])

	var pressure_standard_row: Dictionary = report.get("pressure_scenario_standardization", {})
	lines.append("")
	lines.append("## Pressure Scenario Standardization")
	lines.append("- baseline_targets_file: %s" % str(pressure_standard_row.get("baseline_targets_file", "")))
	lines.append("- baseline_report: %s" % str(pressure_standard_row.get("baseline_report", "")))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(pressure_standard_row.get("required_run_modes", []))))
	lines.append("- required_scenarios: %s" % ", ".join(_sanitize_string_array(pressure_standard_row.get("required_scenarios", []))))
	lines.append("- standardization_failures: %d/%d" % [
		int(pressure_standard_row.get("standardization_failures", 0)),
		int(pressure_standard_row.get("max_standardization_failures", 0)),
	])
	var pressure_standard_items: Array = pressure_standard_row.get("items", [])
	for item in pressure_standard_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("scenario", ""))),
				str(row.get("limit", "")),
			])

	var refinement_row: Dictionary = report.get("alignment_dashboard_refinement", {})
	lines.append("")
	lines.append("## Alignment Dashboard Refinement")
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(refinement_row.get("required_run_modes", []))))
	lines.append("- score: %.3f" % float(refinement_row.get("score", 0.0)))
	lines.append("- severity: %s" % str(refinement_row.get("severity", "normal")))
	lines.append("- dashboard_failures: %d/%d" % [
		int(refinement_row.get("dashboard_failures", 0)),
		int(refinement_row.get("max_dashboard_failures", 0)),
	])
	var refinement_items: Array = refinement_row.get("items", [])
	for item in refinement_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("score", ""))),
				str(row.get("limit", "")),
			])

	var convergence_gate_row: Dictionary = report.get("pressure_alignment_convergence_gate", {})
	lines.append("")
	lines.append("## Pressure Alignment Convergence Gate")
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(convergence_gate_row.get("required_run_modes", []))))
	lines.append("- required_backends: %s" % ", ".join(_sanitize_string_array(convergence_gate_row.get("required_backends", []))))
	lines.append("- convergence_failures: %d/%d" % [
		int(convergence_gate_row.get("convergence_failures", 0)),
		int(convergence_gate_row.get("max_convergence_failures", 0)),
	])
	lines.append("- standardization_failures: %d/%d" % [
		int(convergence_gate_row.get("standardization_failures", 0)),
		int(convergence_gate_row.get("max_standardization_failures", 0)),
	])
	lines.append("- alignment_failures: %d/%d" % [
		int(convergence_gate_row.get("alignment_failures", 0)),
		int(convergence_gate_row.get("max_alignment_failures", 0)),
	])
	lines.append("- dashboard_failures: %d/%d severity=%s" % [
		int(convergence_gate_row.get("dashboard_failures", 0)),
		int(convergence_gate_row.get("max_dashboard_failures", 0)),
		str(convergence_gate_row.get("dashboard_severity", "ok")),
	])
	var convergence_gate_items: Array = convergence_gate_row.get("items", [])
	for item in convergence_gate_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("backend", ""))),
				str(row.get("limit", "")),
			])

	var cycle_row: Dictionary = report.get("regression_cycle_window_governance", {})
	lines.append("")
	lines.append("## Regression Cycle Window Governance")
	lines.append("- history_file: %s" % str(cycle_row.get("history_file", "")))
	lines.append("- cycle_window_size: %d" % int(cycle_row.get("cycle_window_size", 0)))
	lines.append("- min_cycle_entries: %d" % int(cycle_row.get("min_cycle_entries", 0)))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(cycle_row.get("required_run_modes", []))))
	lines.append("- required_backends: %s" % ", ".join(_sanitize_string_array(cycle_row.get("required_backends", []))))
	lines.append("- window_entries: %d" % int(cycle_row.get("window_entries", 0)))
	lines.append("- cycle_failures: %d/%d" % [
		int(cycle_row.get("cycle_failures", 0)),
		int(cycle_row.get("max_cycle_failures", 0)),
	])
	lines.append("- warning_delta: %d / %d" % [
		int(cycle_row.get("warning_delta", 0)),
		int(cycle_row.get("max_warning_delta", 0)),
	])
	lines.append("- blocker_delta: %d / %d" % [
		int(cycle_row.get("blocker_delta", 0)),
		int(cycle_row.get("max_blocker_delta", 0)),
	])
	lines.append("- alignment_score_delta: %.3f / %.3f" % [
		float(cycle_row.get("alignment_score_delta", 0.0)),
		float(cycle_row.get("max_alignment_score_delta", 0.0)),
	])
	var cycle_items: Array = cycle_row.get("items", [])
	for item in cycle_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("entries", ""))),
				str(row.get("limit", "")),
			])

	var adaptive_row: Dictionary = report.get("multi_cycle_adaptive_gate", {})
	lines.append("")
	lines.append("## Multi-Cycle Adaptive Gate")
	lines.append("- history_file: %s" % str(adaptive_row.get("history_file", "")))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(adaptive_row.get("required_run_modes", []))))
	lines.append("- required_backends: %s" % ", ".join(_sanitize_string_array(adaptive_row.get("required_backends", []))))
	lines.append("- adaptive_failures: %d/%d" % [
		int(adaptive_row.get("adaptive_failures", 0)),
		int(adaptive_row.get("max_adaptive_failures", 0)),
	])
	var adaptive_window_analysis: Dictionary = adaptive_row.get("window_analysis", {})
	for window_name in ["short", "mid", "long"]:
		var window_row: Dictionary = adaptive_window_analysis.get(window_name, {})
		if window_row.is_empty():
			continue
		lines.append("- %s_window: entries=%d/%d, warning_slope=%.3f/%.3f, blocker_slope=%.3f/%.3f" % [
			window_name,
			int(window_row.get("entries", 0)),
			int(adaptive_row.get("min_window_entries", 0)),
			float(window_row.get("warning_slope", 0.0)),
			float(window_row.get("max_warning_slope", 0.0)),
			float(window_row.get("blocker_slope", 0.0)),
			float(window_row.get("max_blocker_slope", 0.0)),
		])
	var adaptive_items: Array = adaptive_row.get("items", [])
	for item in adaptive_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("backend", ""))),
				str(row.get("limit", "")),
			])

	var feedback_row: Dictionary = report.get("release_feedback_governance", {})
	lines.append("")
	lines.append("## Release Feedback Governance")
	lines.append("- history_file: %s" % str(feedback_row.get("history_file", "")))
	lines.append("- feedback_window_size: %d" % int(feedback_row.get("feedback_window_size", 0)))
	lines.append("- min_feedback_entries: %d" % int(feedback_row.get("min_feedback_entries", 0)))
	lines.append("- required_run_modes: %s" % ", ".join(_sanitize_string_array(feedback_row.get("required_run_modes", []))))
	lines.append("- required_backends: %s" % ", ".join(_sanitize_string_array(feedback_row.get("required_backends", []))))
	lines.append("- feedback_failures: %d/%d" % [
		int(feedback_row.get("feedback_failures", 0)),
		int(feedback_row.get("max_feedback_failures", 0)),
	])
	lines.append("- closure_rate: %.3f / %.3f" % [
		float(feedback_row.get("closure_rate", 1.0)),
		float(feedback_row.get("min_closure_rate", 0.0)),
	])
	lines.append("- unresolved_issues: %d / %d" % [
		(feedback_row.get("unresolved_issues", []) as Array).size(),
		int(feedback_row.get("max_unresolved_issues", 0)),
	])
	var feedback_items: Array = feedback_row.get("items", [])
	for item in feedback_items:
		if item is Dictionary:
			var row: Dictionary = item
			var ok: bool = bool(row.get("ok", false))
			var status: String = "OK" if ok else "FAIL"
			lines.append("- [%s] %s -> %s / %s" % [
				status,
				str(row.get("type", "")),
				str(row.get("value", row.get("issues", ""))),
				str(row.get("limit", "")),
			])

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
