extends GutTest

const VISUAL_SNAPSHOT_TARGETS_PATH := "res://data/balance/visual_snapshot_targets.json"


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


func test_visual_snapshot_targets_schema_is_valid() -> void:
	var cfg: Dictionary = _load_json_dict(VISUAL_SNAPSHOT_TARGETS_PATH)
	var channel: String = str(cfg.get("channel", ""))
	var snapshots: Dictionary = cfg.get("snapshots", {})
	var precision: Dictionary = cfg.get("precision", {})
	var backend_profiles: Dictionary = cfg.get("backend_profiles", {})
	var thresholds: Dictionary = cfg.get("thresholds", {})
	var baseline_alignment: Dictionary = cfg.get("baseline_alignment", {})
	var diff_whitelist: Dictionary = cfg.get("diff_whitelist", {})
	var whitelist_policy: Dictionary = cfg.get("whitelist_policy", {})
	var backend_attribution: Dictionary = cfg.get("backend_attribution", {})
	var whitelist_convergence: Dictionary = cfg.get("whitelist_convergence", {})
	var exception_lifecycle: Dictionary = cfg.get("exception_lifecycle", {})
	var strategy_orchestration: Dictionary = cfg.get("strategy_orchestration", {})
	var release_gate_templates: Dictionary = cfg.get("release_gate_templates", {})
	var backend_matrix_governance: Dictionary = cfg.get("backend_matrix_governance", {})
	var approval_workflow: Dictionary = cfg.get("approval_workflow", {})
	var approval_audit_trail: Dictionary = cfg.get("approval_audit_trail", {})
	var approval_history_archive: Dictionary = cfg.get("approval_history_archive", {})
	var approval_threshold_templates: Dictionary = cfg.get("approval_threshold_templates", {})
	var release_candidate_tracking: Dictionary = cfg.get("release_candidate_tracking", {})
	var report_layers: Dictionary = cfg.get("report_layers", {})
	var cross_version_baseline: Dictionary = cfg.get("cross_version_baseline", {})

	assert_ne(channel, "", "channel should be non-empty")
	assert_eq(channel, "chapter_snapshot_v12", "D36 should use chapter_snapshot_v12 channel")
	assert_typeof(snapshots, TYPE_DICTIONARY, "snapshots should be Dictionary")
	assert_typeof(precision, TYPE_DICTIONARY, "precision should be Dictionary")
	assert_typeof(backend_profiles, TYPE_DICTIONARY, "backend_profiles should be Dictionary")
	assert_typeof(thresholds, TYPE_DICTIONARY, "thresholds should be Dictionary")
	assert_typeof(baseline_alignment, TYPE_DICTIONARY, "baseline_alignment should be Dictionary")
	assert_typeof(diff_whitelist, TYPE_DICTIONARY, "diff_whitelist should be Dictionary")
	assert_typeof(whitelist_policy, TYPE_DICTIONARY, "whitelist_policy should be Dictionary")
	assert_typeof(backend_attribution, TYPE_DICTIONARY, "backend_attribution should be Dictionary")
	assert_typeof(whitelist_convergence, TYPE_DICTIONARY, "whitelist_convergence should be Dictionary")
	assert_typeof(exception_lifecycle, TYPE_DICTIONARY, "exception_lifecycle should be Dictionary")
	assert_typeof(strategy_orchestration, TYPE_DICTIONARY, "strategy_orchestration should be Dictionary")
	assert_typeof(release_gate_templates, TYPE_DICTIONARY, "release_gate_templates should be Dictionary")
	assert_typeof(backend_matrix_governance, TYPE_DICTIONARY, "backend_matrix_governance should be Dictionary")
	assert_typeof(approval_workflow, TYPE_DICTIONARY, "approval_workflow should be Dictionary")
	assert_typeof(approval_audit_trail, TYPE_DICTIONARY, "approval_audit_trail should be Dictionary")
	assert_typeof(approval_history_archive, TYPE_DICTIONARY, "approval_history_archive should be Dictionary")
	assert_typeof(approval_threshold_templates, TYPE_DICTIONARY, "approval_threshold_templates should be Dictionary")
	assert_typeof(release_candidate_tracking, TYPE_DICTIONARY, "release_candidate_tracking should be Dictionary")
	assert_typeof(report_layers, TYPE_DICTIONARY, "report_layers should be Dictionary")
	assert_typeof(cross_version_baseline, TYPE_DICTIONARY, "cross_version_baseline should be Dictionary")
	assert_gte(snapshots.size(), 5, "D36 should define at least 5 snapshot targets")

	assert_gte(int(precision.get("sample_rounds", 0)), 3, "D36 sample_rounds should be >= 3")
	assert_gte(float(precision.get("max_opaque_ratio_stddev", -1.0)), 0.0, "max_opaque_ratio_stddev should be >= 0")
	assert_lte(float(precision.get("max_opaque_ratio_stddev", -1.0)), 0.5, "max_opaque_ratio_stddev should be <= 0.5")
	assert_gte(float(precision.get("max_luma_stddev", -1.0)), 0.0, "max_luma_stddev should be >= 0")
	assert_lte(float(precision.get("max_luma_stddev", -1.0)), 0.5, "max_luma_stddev should be <= 0.5")
	assert_gte(float(precision.get("max_unique_color_stddev_ratio", -1.0)), 0.0, "max_unique_color_stddev_ratio should be >= 0")
	assert_lte(float(precision.get("max_unique_color_stddev_ratio", -1.0)), 1.0, "max_unique_color_stddev_ratio should be <= 1")

	assert_true(backend_profiles.has("default"), "backend_profiles should include default")
	assert_true(backend_profiles.has("linux_headless"), "backend_profiles should include linux_headless")
	assert_true(backend_profiles.has("windows_headless"), "backend_profiles should include windows_headless")
	for profile_name_var: Variant in backend_profiles.keys():
		var profile_name: String = str(profile_name_var)
		var profile: Dictionary = backend_profiles.get(profile_name, {})
		assert_typeof(profile, TYPE_DICTIONARY, "%s profile should be Dictionary" % profile_name)
		assert_gte(float(profile.get("max_opaque_ratio_drop", -1.0)), 0.0, "%s max_opaque_ratio_drop should be >= 0" % profile_name)
		assert_lte(float(profile.get("max_opaque_ratio_drop", -1.0)), 1.0, "%s max_opaque_ratio_drop should be <= 1" % profile_name)
		assert_gte(float(profile.get("max_unique_color_drop_ratio", -1.0)), 0.0, "%s max_unique_color_drop_ratio should be >= 0" % profile_name)
		assert_lte(float(profile.get("max_unique_color_drop_ratio", -1.0)), 1.0, "%s max_unique_color_drop_ratio should be <= 1" % profile_name)
		assert_gte(float(profile.get("max_luma_delta", -1.0)), 0.0, "%s max_luma_delta should be >= 0" % profile_name)
		assert_lte(float(profile.get("max_luma_delta", -1.0)), 1.0, "%s max_luma_delta should be <= 1" % profile_name)
		assert_gte(float(profile.get("unique_colors_min_scale", -1.0)), 0.5, "%s unique_colors_min_scale should be >= 0.5" % profile_name)
		assert_lte(float(profile.get("unique_colors_min_scale", -1.0)), 2.0, "%s unique_colors_min_scale should be <= 2.0" % profile_name)
		assert_gte(float(profile.get("luma_range_padding", -1.0)), 0.0, "%s luma_range_padding should be >= 0" % profile_name)
		assert_lte(float(profile.get("luma_range_padding", -1.0)), 0.3, "%s luma_range_padding should be <= 0.3" % profile_name)

	var required_snapshot_ids: Array = baseline_alignment.get("required_snapshot_ids", [])
	var allowed_capture_modes: Dictionary = baseline_alignment.get("allowed_capture_modes", {})
	assert_typeof(required_snapshot_ids, TYPE_ARRAY, "required_snapshot_ids should be Array")
	assert_gte(required_snapshot_ids.size(), 5, "D34 required_snapshot_ids should include all snapshot keys")
	for snapshot_id_var: Variant in required_snapshot_ids:
		var required_snapshot_id: String = str(snapshot_id_var)
		assert_true(snapshots.has(required_snapshot_id), "required_snapshot_ids should reference existing snapshot keys")

	assert_typeof(allowed_capture_modes, TYPE_DICTIONARY, "allowed_capture_modes should be Dictionary")
	for backend_name in ["default", "linux_headless", "windows_headless"]:
		assert_true(allowed_capture_modes.has(backend_name), "allowed_capture_modes should include %s" % backend_name)
		var modes: Array = allowed_capture_modes.get(backend_name, [])
		assert_typeof(modes, TYPE_ARRAY, "%s allowed modes should be Array" % backend_name)
		assert_gte(modes.size(), 1, "%s allowed modes should be non-empty" % backend_name)

	for backend_name_var: Variant in diff_whitelist.keys():
		var backend_name: String = str(backend_name_var)
		var backend_rows: Dictionary = diff_whitelist.get(backend_name, {})
		assert_typeof(backend_rows, TYPE_DICTIONARY, "diff_whitelist.%s should be Dictionary" % backend_name)
		for snapshot_id_var: Variant in backend_rows.keys():
			var snapshot_id: String = str(snapshot_id_var)
			var row: Dictionary = backend_rows.get(snapshot_id, {})
			assert_true(snapshots.has(snapshot_id), "diff_whitelist.%s.%s should reference existing snapshot" % [backend_name, snapshot_id])
			assert_typeof(row, TYPE_DICTIONARY, "diff_whitelist row should be Dictionary")
			if row.has("max_opaque_ratio_drop"):
				assert_gte(float(row.get("max_opaque_ratio_drop", -1.0)), 0.0, "whitelist max_opaque_ratio_drop should be >= 0")
				assert_lte(float(row.get("max_opaque_ratio_drop", -1.0)), 1.0, "whitelist max_opaque_ratio_drop should be <= 1")
			if row.has("max_unique_color_drop_ratio"):
				assert_gte(float(row.get("max_unique_color_drop_ratio", -1.0)), 0.0, "whitelist max_unique_color_drop_ratio should be >= 0")
				assert_lte(float(row.get("max_unique_color_drop_ratio", -1.0)), 1.0, "whitelist max_unique_color_drop_ratio should be <= 1")
			if row.has("max_luma_delta"):
				assert_gte(float(row.get("max_luma_delta", -1.0)), 0.0, "whitelist max_luma_delta should be >= 0")
				assert_lte(float(row.get("max_luma_delta", -1.0)), 1.0, "whitelist max_luma_delta should be <= 1")

	assert_gte(int(whitelist_policy.get("max_hits", -1)), 0, "whitelist max_hits should be >= 0")
	assert_gte(float(whitelist_policy.get("max_ratio", -1.0)), 0.0, "whitelist max_ratio should be >= 0")
	assert_lte(float(whitelist_policy.get("max_ratio", 2.0)), 1.0, "whitelist max_ratio should be <= 1")

	var required_backends: Array = backend_attribution.get("required_backends", [])
	assert_typeof(required_backends, TYPE_ARRAY, "backend_attribution.required_backends should be Array")
	assert_true(required_backends.has("linux_headless"), "backend_attribution.required_backends should include linux_headless")
	assert_true(required_backends.has("windows_headless"), "backend_attribution.required_backends should include windows_headless")
	assert_gte(int(backend_attribution.get("max_unattributed_regressions", -1)), 0, "max_unattributed_regressions should be >= 0")
	assert_gte(int(backend_attribution.get("max_backend_specific_regressions", -1)), 0, "max_backend_specific_regressions should be >= 0")

	assert_gte(int(whitelist_convergence.get("stale_run_threshold", 0)), 1, "whitelist_convergence.stale_run_threshold should be >= 1")
	assert_gte(float(whitelist_convergence.get("tighten_margin_ratio", -1.0)), 0.0, "whitelist_convergence.tighten_margin_ratio should be >= 0")
	assert_lte(float(whitelist_convergence.get("tighten_margin_ratio", 2.0)), 1.0, "whitelist_convergence.tighten_margin_ratio should be <= 1")
	assert_gte(int(whitelist_convergence.get("max_suggestions", -1)), 0, "whitelist_convergence.max_suggestions should be >= 0")

	assert_gte(int(exception_lifecycle.get("expire_idle_runs", 0)), 1, "exception_lifecycle.expire_idle_runs should be >= 1")
	assert_gte(int(exception_lifecycle.get("auto_reclaim_hit_streak", 0)), 1, "exception_lifecycle.auto_reclaim_hit_streak should be >= 1")
	assert_gte(int(exception_lifecycle.get("max_expired_entries", -1)), 0, "exception_lifecycle.max_expired_entries should be >= 0")
	assert_gte(int(exception_lifecycle.get("max_reclaim_candidates", -1)), 0, "exception_lifecycle.max_reclaim_candidates should be >= 0")

	var matrix_required_backends: Array = backend_matrix_governance.get("required_backend_matrix", [])
	var matrix_required_run_modes: Array = backend_matrix_governance.get("required_run_modes", [])
	assert_typeof(matrix_required_backends, TYPE_ARRAY, "backend_matrix_governance.required_backend_matrix should be Array")
	assert_typeof(matrix_required_run_modes, TYPE_ARRAY, "backend_matrix_governance.required_run_modes should be Array")
	assert_true(matrix_required_backends.has("linux_headless"), "backend_matrix_governance.required_backend_matrix should include linux_headless")
	assert_true(matrix_required_backends.has("windows_headless"), "backend_matrix_governance.required_backend_matrix should include windows_headless")
	for run_mode_name in ["rehearsal", "trend_gate", "release_candidate", "release_blocking"]:
		assert_true(matrix_required_run_modes.has(run_mode_name), "backend_matrix_governance.required_run_modes should include %s" % run_mode_name)
	assert_gte(int(backend_matrix_governance.get("max_missing_backend_matrix", -1)), 0, "backend_matrix_governance.max_missing_backend_matrix should be >= 0")
	assert_gte(int(backend_matrix_governance.get("max_missing_run_mode_bindings", -1)), 0, "backend_matrix_governance.max_missing_run_mode_bindings should be >= 0")

	var approval_required_sections: Array = approval_workflow.get("required_report_sections", [])
	var approval_zero_warning: Array = approval_workflow.get("require_zero_warnings_for_strategies", [])
	assert_typeof(approval_required_sections, TYPE_ARRAY, "approval_workflow.required_report_sections should be Array")
	assert_true(approval_required_sections.has("Release Manifest"), "approval_workflow.required_report_sections should include Release Manifest")
	assert_true(approval_required_sections.has("Backend Matrix Governance"), "approval_workflow.required_report_sections should include Backend Matrix Governance")
	assert_true(approval_required_sections.has("Approval Workflow"), "approval_workflow.required_report_sections should include Approval Workflow")
	assert_true(approval_required_sections.has("Approval Audit Trail"), "approval_workflow.required_report_sections should include Approval Audit Trail")
	assert_true(bool(approval_workflow.get("require_zero_blockers", false)), "approval_workflow.require_zero_blockers should be true")
	assert_typeof(approval_zero_warning, TYPE_ARRAY, "approval_workflow.require_zero_warnings_for_strategies should be Array")
	assert_true(approval_zero_warning.has("release_blocking"), "approval_workflow.require_zero_warnings_for_strategies should include release_blocking")
	assert_gte(int(approval_workflow.get("max_approval_failures", -1)), 0, "approval_workflow.max_approval_failures should be >= 0")

	var audit_history_file: String = str(approval_audit_trail.get("history_file", ""))
	var audit_required_modes: Array = approval_audit_trail.get("required_run_modes", [])
	var audit_required_backends: Array = approval_audit_trail.get("required_backends", [])
	assert_true(audit_history_file.begins_with("user://"), "approval_audit_trail.history_file should be user:// path")
	assert_gte(int(approval_audit_trail.get("max_entries", 0)), 10, "approval_audit_trail.max_entries should be >= 10")
	assert_typeof(audit_required_modes, TYPE_ARRAY, "approval_audit_trail.required_run_modes should be Array")
	assert_typeof(audit_required_backends, TYPE_ARRAY, "approval_audit_trail.required_backends should be Array")
	for run_mode_name in ["rehearsal", "trend_gate", "release_candidate", "release_blocking"]:
		assert_true(audit_required_modes.has(run_mode_name), "approval_audit_trail.required_run_modes should include %s" % run_mode_name)
	for backend_name in ["linux_headless", "windows_headless"]:
		assert_true(audit_required_backends.has(backend_name), "approval_audit_trail.required_backends should include %s" % backend_name)
		assert_true(matrix_required_backends.has(backend_name), "backend_matrix_governance.required_backend_matrix should include %s for D36 approval audit" % backend_name)
	assert_typeof(approval_audit_trail.get("require_unique_pipeline_id", null), TYPE_BOOL, "approval_audit_trail.require_unique_pipeline_id should be bool")
	assert_gte(int(approval_audit_trail.get("max_missing_pipeline_id", -1)), 0, "approval_audit_trail.max_missing_pipeline_id should be >= 0")
	assert_gte(int(approval_audit_trail.get("max_history_trace_failures", -1)), 0, "approval_audit_trail.max_history_trace_failures should be >= 0")

	var archive_file: String = str(approval_history_archive.get("archive_file", ""))
	var archive_required_modes: Array = approval_history_archive.get("required_run_modes", [])
	var archive_required_backends: Array = approval_history_archive.get("required_backends", [])
	assert_true(archive_file.begins_with("user://"), "approval_history_archive.archive_file should be user:// path")
	assert_gte(int(approval_history_archive.get("max_entries", 0)), 20, "approval_history_archive.max_entries should be >= 20")
	assert_gte(int(approval_history_archive.get("aggregation_window", 0)), 10, "approval_history_archive.aggregation_window should be >= 10")
	assert_typeof(archive_required_modes, TYPE_ARRAY, "approval_history_archive.required_run_modes should be Array")
	assert_typeof(archive_required_backends, TYPE_ARRAY, "approval_history_archive.required_backends should be Array")
	var archive_ci_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	for run_mode_name in ["rehearsal", "trend_gate", "release_candidate", "release_blocking"]:
		assert_true(archive_required_modes.has(run_mode_name), "approval_history_archive.required_run_modes should include %s" % run_mode_name)
		assert_true(archive_ci_bindings.has(run_mode_name), "release_gate_templates.ci_mode_bindings should include %s for D36 archive" % run_mode_name)
	for backend_name in ["linux_headless", "windows_headless"]:
		assert_true(archive_required_backends.has(backend_name), "approval_history_archive.required_backends should include %s" % backend_name)
		assert_true(matrix_required_backends.has(backend_name), "backend_matrix_governance.required_backend_matrix should include %s for D36 archive" % backend_name)
	assert_gte(int(approval_history_archive.get("max_missing_archive_backends", -1)), 0, "approval_history_archive.max_missing_archive_backends should be >= 0")
	assert_gte(int(approval_history_archive.get("max_missing_archive_run_modes", -1)), 0, "approval_history_archive.max_missing_archive_run_modes should be >= 0")
	assert_gte(int(approval_history_archive.get("max_backend_warning_delta", -1)), 0, "approval_history_archive.max_backend_warning_delta should be >= 0")
	assert_gte(int(approval_history_archive.get("max_backend_blocker_delta", -1)), 0, "approval_history_archive.max_backend_blocker_delta should be >= 0")
	assert_gte(int(approval_history_archive.get("max_archive_trace_failures", -1)), 0, "approval_history_archive.max_archive_trace_failures should be >= 0")

	var default_strategy: String = str(strategy_orchestration.get("default_strategy", ""))
	var strategies: Dictionary = strategy_orchestration.get("strategies", {})
	var templates: Dictionary = strategy_orchestration.get("templates", {})
	assert_ne(default_strategy, "", "strategy_orchestration.default_strategy should be non-empty")
	assert_typeof(strategies, TYPE_DICTIONARY, "strategy_orchestration.strategies should be Dictionary")
	assert_typeof(templates, TYPE_DICTIONARY, "strategy_orchestration.templates should be Dictionary")
	assert_true(strategies.has(default_strategy), "strategy_orchestration.default_strategy should reference strategies key")
	assert_true(strategies.has("ci_rehearsal"), "strategy_orchestration should include ci_rehearsal strategy")
	assert_true(strategies.has("ci_trend_gate"), "strategy_orchestration should include ci_trend_gate strategy")
	assert_true(templates.has("rehearsal_relaxed"), "strategy_orchestration templates should include rehearsal_relaxed")
	assert_true(templates.has("trend_gate_strict"), "strategy_orchestration templates should include trend_gate_strict")

	var allowed_template_sections: Array[String] = [
		"thresholds",
		"whitelist_policy",
		"backend_attribution",
		"whitelist_convergence",
		"exception_lifecycle",
		"cross_version_baseline",
		"report_layers",
	]
	for strategy_name_var: Variant in strategies.keys():
		var strategy_name: String = str(strategy_name_var)
		var strategy_row: Dictionary = strategies.get(strategy_name, {})
		assert_typeof(strategy_row, TYPE_DICTIONARY, "strategy row should be Dictionary")
		var template_name: String = str(strategy_row.get("template", ""))
		assert_ne(template_name, "", "strategy template should be non-empty")
		assert_true(templates.has(template_name), "strategy template should reference existing template")

	for template_name_var: Variant in templates.keys():
		var template_name: String = str(template_name_var)
		var template_row: Dictionary = templates.get(template_name, {})
		assert_typeof(template_row, TYPE_DICTIONARY, "template row should be Dictionary")
		for section_key_var: Variant in template_row.keys():
			var section_key: String = str(section_key_var)
			assert_true(allowed_template_sections.has(section_key), "template section should be supported")
			assert_typeof(template_row.get(section_key, {}), TYPE_DICTIONARY, "template override section should be Dictionary")

	var manifest_required_strategies: Array = release_gate_templates.get("required_strategies", [])
	var manifest_required_bindings: Dictionary = release_gate_templates.get("required_strategy_bindings", {})
	var manifest_ci_bindings: Dictionary = release_gate_templates.get("ci_mode_bindings", {})
	var manifest_release_checklist: Dictionary = release_gate_templates.get("release_checklist", {})
	assert_typeof(manifest_required_strategies, TYPE_ARRAY, "release_gate_templates.required_strategies should be Array")
	assert_typeof(manifest_required_bindings, TYPE_DICTIONARY, "release_gate_templates.required_strategy_bindings should be Dictionary")
	assert_typeof(manifest_ci_bindings, TYPE_DICTIONARY, "release_gate_templates.ci_mode_bindings should be Dictionary")
	assert_typeof(manifest_release_checklist, TYPE_DICTIONARY, "release_gate_templates.release_checklist should be Dictionary")
	for strategy_name in ["ci_rehearsal", "ci_trend_gate", "release_candidate", "release_blocking"]:
		assert_true(manifest_required_strategies.has(strategy_name), "release_gate_templates.required_strategies should include %s" % strategy_name)
		assert_true(manifest_required_bindings.has(strategy_name), "release_gate_templates.required_strategy_bindings should include %s" % strategy_name)
		assert_true(strategies.has(strategy_name), "strategy_orchestration.strategies should include %s" % strategy_name)
		assert_eq(str(manifest_required_bindings.get(strategy_name, "")), str(strategies.get(strategy_name, {}).get("template", "")), "required strategy binding should match strategy template")
	assert_true(manifest_ci_bindings.has("rehearsal"), "release_gate_templates.ci_mode_bindings should include rehearsal")
	assert_true(manifest_ci_bindings.has("trend_gate"), "release_gate_templates.ci_mode_bindings should include trend_gate")
	for run_mode_name_var: Variant in matrix_required_run_modes:
		var run_mode_name: String = str(run_mode_name_var)
		assert_true(manifest_ci_bindings.has(run_mode_name), "release_gate_templates.ci_mode_bindings should include %s for D36 backend matrix governance" % run_mode_name)

	var approval_templates_default: String = str(approval_threshold_templates.get("default_template", ""))
	var approval_templates_run_mode: Dictionary = approval_threshold_templates.get("run_mode_templates", {})
	var approval_templates_rows: Dictionary = approval_threshold_templates.get("templates", {})
	assert_ne(approval_templates_default, "", "approval_threshold_templates.default_template should be non-empty")
	assert_typeof(approval_templates_run_mode, TYPE_DICTIONARY, "approval_threshold_templates.run_mode_templates should be Dictionary")
	assert_typeof(approval_templates_rows, TYPE_DICTIONARY, "approval_threshold_templates.templates should be Dictionary")
	assert_true(approval_templates_rows.has(approval_templates_default), "approval_threshold_templates.default_template should reference templates")
	for run_mode_name in ["rehearsal", "trend_gate", "release_candidate", "release_blocking"]:
		assert_true(approval_templates_run_mode.has(run_mode_name), "approval_threshold_templates.run_mode_templates should include %s" % run_mode_name)
		var template_name: String = str(approval_templates_run_mode.get(run_mode_name, ""))
		assert_ne(template_name, "", "approval threshold template should be non-empty for %s" % run_mode_name)
		assert_true(approval_templates_rows.has(template_name), "approval threshold template should reference templates.%s" % template_name)
		assert_true(manifest_ci_bindings.has(run_mode_name), "release_gate_templates.ci_mode_bindings should include %s for D36 approval templates" % run_mode_name)

	var allowed_approval_template_sections: Array[String] = [
		"approval_workflow",
		"approval_audit_trail",
		"approval_history_archive",
	]
	for template_name_var: Variant in approval_templates_rows.keys():
		var template_name: String = str(template_name_var)
		var template_row: Dictionary = approval_templates_rows.get(template_name, {})
		assert_typeof(template_row, TYPE_DICTIONARY, "approval template row should be Dictionary")
		for section_key_var: Variant in template_row.keys():
			var section_key: String = str(section_key_var)
			assert_true(allowed_approval_template_sections.has(section_key), "approval template section should be supported")
			assert_typeof(template_row.get(section_key, {}), TYPE_DICTIONARY, "approval template override section should be Dictionary")

	var tracking_history_file: String = str(release_candidate_tracking.get("history_file", ""))
	var tracking_required_run_modes: Array = release_candidate_tracking.get("required_run_modes", [])
	var tracking_required_strategies: Array = release_candidate_tracking.get("required_strategies", [])
	assert_true(tracking_history_file.begins_with("user://"), "release_candidate_tracking.history_file should be user:// path")
	assert_gte(int(release_candidate_tracking.get("window", 0)), 5, "release_candidate_tracking.window should be >= 5")
	assert_typeof(tracking_required_run_modes, TYPE_ARRAY, "release_candidate_tracking.required_run_modes should be Array")
	assert_typeof(tracking_required_strategies, TYPE_ARRAY, "release_candidate_tracking.required_strategies should be Array")
	assert_gte(int(release_candidate_tracking.get("min_runs", 0)), 1, "release_candidate_tracking.min_runs should be >= 1")
	assert_gte(float(release_candidate_tracking.get("max_avg_warnings", -1.0)), 0.0, "release_candidate_tracking.max_avg_warnings should be >= 0")
	assert_gte(int(release_candidate_tracking.get("max_total_blockers", -1)), 0, "release_candidate_tracking.max_total_blockers should be >= 0")
	assert_gte(int(release_candidate_tracking.get("max_tracking_failures", -1)), 0, "release_candidate_tracking.max_tracking_failures should be >= 0")
	assert_true(tracking_required_run_modes.has("release_candidate"), "release_candidate_tracking.required_run_modes should include release_candidate")
	assert_true(tracking_required_strategies.has("release_candidate"), "release_candidate_tracking.required_strategies should include release_candidate")
	for run_mode_name_var: Variant in tracking_required_run_modes:
		var run_mode_name: String = str(run_mode_name_var)
		assert_true(manifest_ci_bindings.has(run_mode_name), "release_gate_templates.ci_mode_bindings should include %s for D36 tracking" % run_mode_name)
	for strategy_name_var: Variant in tracking_required_strategies:
		var strategy_name: String = str(strategy_name_var)
		assert_true(manifest_required_strategies.has(strategy_name), "release_gate_templates.required_strategies should include %s for D36 tracking" % strategy_name)
	var required_reports: Array = manifest_release_checklist.get("required_reports", [])
	var publish_strategies: Array = manifest_release_checklist.get("required_strategies_for_publish", [])
	var zero_warning_strategies: Array = manifest_release_checklist.get("require_zero_warnings_for", [])
	assert_typeof(required_reports, TYPE_ARRAY, "release_checklist.required_reports should be Array")
	assert_typeof(publish_strategies, TYPE_ARRAY, "release_checklist.required_strategies_for_publish should be Array")
	assert_typeof(zero_warning_strategies, TYPE_ARRAY, "release_checklist.require_zero_warnings_for should be Array")
	assert_gte(required_reports.size(), 1, "release_checklist.required_reports should be non-empty")
	assert_true(publish_strategies.has("release_candidate"), "release_checklist.required_strategies_for_publish should include release_candidate")
	assert_true(publish_strategies.has("release_blocking"), "release_checklist.required_strategies_for_publish should include release_blocking")
	assert_true(zero_warning_strategies.has("release_blocking"), "release_checklist.require_zero_warnings_for should include release_blocking")
	for report_path_var: Variant in required_reports:
		var report_path: String = str(report_path_var)
		assert_true(report_path.begins_with("user://"), "release_checklist.required_reports should use user:// paths")
	assert_gte(int(manifest_release_checklist.get("max_checklist_failures", -1)), 0, "release_checklist.max_checklist_failures should be >= 0")

	for layer_name_var: Variant in report_layers.keys():
		var layer_name: String = str(layer_name_var)
		var layer_row: Dictionary = report_layers.get(layer_name, {})
		assert_typeof(layer_row, TYPE_DICTIONARY, "report_layers.%s should be Dictionary" % layer_name)
		var snapshot_ids: Array = layer_row.get("snapshot_ids", [])
		assert_typeof(snapshot_ids, TYPE_ARRAY, "report_layers.%s.snapshot_ids should be Array" % layer_name)
		assert_gte(snapshot_ids.size(), 1, "report_layers.%s.snapshot_ids should be non-empty" % layer_name)
		for snapshot_id_var: Variant in snapshot_ids:
			var snapshot_id: String = str(snapshot_id_var)
			assert_true(snapshots.has(snapshot_id), "report_layers.%s should reference existing snapshot ids" % layer_name)
		assert_gte(int(layer_row.get("max_layer_blockers", -1)), 0, "report_layers.%s.max_layer_blockers should be >= 0" % layer_name)
		assert_gte(int(layer_row.get("max_layer_warnings", -1)), 0, "report_layers.%s.max_layer_warnings should be >= 0" % layer_name)
		assert_gte(float(layer_row.get("min_pass_ratio", -1.0)), 0.0, "report_layers.%s.min_pass_ratio should be >= 0" % layer_name)
		assert_lte(float(layer_row.get("min_pass_ratio", 2.0)), 1.0, "report_layers.%s.min_pass_ratio should be <= 1" % layer_name)

	var reference_channels: Array = cross_version_baseline.get("reference_channels", [])
	var max_drift: Dictionary = cross_version_baseline.get("max_drift", {})
	var max_violations: int = int(cross_version_baseline.get("max_violations", -1))
	var snapshot_references: Dictionary = cross_version_baseline.get("snapshot_references", {})
	assert_typeof(reference_channels, TYPE_ARRAY, "cross_version_baseline.reference_channels should be Array")
	assert_gte(reference_channels.size(), 1, "cross_version_baseline.reference_channels should be non-empty")
	assert_typeof(max_drift, TYPE_DICTIONARY, "cross_version_baseline.max_drift should be Dictionary")
	assert_gte(max_violations, 0, "cross_version_baseline.max_violations should be >= 0")
	assert_typeof(snapshot_references, TYPE_DICTIONARY, "cross_version_baseline.snapshot_references should be Dictionary")
	for snapshot_id_var: Variant in snapshot_references.keys():
		var snapshot_id: String = str(snapshot_id_var)
		assert_true(snapshots.has(snapshot_id), "cross_version_baseline should reference existing snapshot ids")
		var ref_row: Dictionary = snapshot_references.get(snapshot_id, {})
		assert_typeof(ref_row, TYPE_DICTIONARY, "cross_version_baseline snapshot row should be Dictionary")
		for metric_key in ["opaque_ratio", "unique_colors", "avg_luma"]:
			var metric_refs: Dictionary = ref_row.get(metric_key, {})
			assert_typeof(metric_refs, TYPE_DICTIONARY, "cross_version metric refs should be Dictionary")
			for channel_name_var: Variant in reference_channels:
				var channel_name: String = str(channel_name_var)
				assert_true(metric_refs.has(channel_name), "cross_version metric refs should include reference channels")
			if metric_key == "unique_colors":
				for value in metric_refs.values():
					assert_gte(float(value), 1.0, "cross_version unique_colors refs should be >= 1")
			else:
				for value in metric_refs.values():
					assert_gte(float(value), 0.0, "cross_version normalized refs should be >= 0")
					assert_lte(float(value), 1.0, "cross_version normalized refs should be <= 1")

	assert_gte(float(max_drift.get("opaque_ratio", -1.0)), 0.0, "max_drift.opaque_ratio should be >= 0")
	assert_lte(float(max_drift.get("opaque_ratio", -1.0)), 1.0, "max_drift.opaque_ratio should be <= 1")
	assert_gte(float(max_drift.get("unique_color_ratio", -1.0)), 0.0, "max_drift.unique_color_ratio should be >= 0")
	assert_lte(float(max_drift.get("unique_color_ratio", -1.0)), 1.0, "max_drift.unique_color_ratio should be <= 1")
	assert_gte(float(max_drift.get("avg_luma", -1.0)), 0.0, "max_drift.avg_luma should be >= 0")
	assert_lte(float(max_drift.get("avg_luma", -1.0)), 1.0, "max_drift.avg_luma should be <= 1")

	for snapshot_id_var: Variant in snapshots.keys():
		var snapshot_id: String = str(snapshot_id_var)
		var row: Dictionary = snapshots.get(snapshot_id, {})
		assert_typeof(row, TYPE_DICTIONARY, "snapshot %s should be Dictionary" % snapshot_id)
		assert_true(str(row.get("scene", "")).begins_with("res://"), "%s scene should be res:// path" % snapshot_id)
		assert_ne(str(row.get("setup", "")), "", "%s setup should be non-empty" % snapshot_id)
		assert_gte(int(row.get("width", 0)), 320, "%s width should be >= 320" % snapshot_id)
		assert_gte(int(row.get("height", 0)), 180, "%s height should be >= 180" % snapshot_id)
		assert_gte(int(row.get("warmup_frames", 0)), 1, "%s warmup_frames should be >= 1" % snapshot_id)
		assert_gte(int(row.get("capture_frames", 0)), 1, "%s capture_frames should be >= 1" % snapshot_id)
		assert_gte(float(row.get("opaque_ratio_min", -1.0)), 0.0, "%s opaque_ratio_min should be >= 0" % snapshot_id)
		assert_lte(float(row.get("opaque_ratio_min", -1.0)), 1.0, "%s opaque_ratio_min should be <= 1" % snapshot_id)
		assert_gte(int(row.get("unique_colors_min", 0)), 1, "%s unique_colors_min should be >= 1" % snapshot_id)
		assert_gte(float(row.get("luma_min", -1.0)), 0.0, "%s luma_min should be >= 0" % snapshot_id)
		assert_lte(float(row.get("luma_min", -1.0)), 1.0, "%s luma_min should be <= 1" % snapshot_id)
		assert_gte(float(row.get("luma_max", -1.0)), 0.0, "%s luma_max should be >= 0" % snapshot_id)
		assert_lte(float(row.get("luma_max", -1.0)), 1.0, "%s luma_max should be <= 1" % snapshot_id)
		assert_lte(float(row.get("luma_min", 0.0)), float(row.get("luma_max", 1.0)), "%s luma_min should not exceed luma_max" % snapshot_id)


func test_visual_snapshot_targets_reference_existing_scenes() -> void:
	var cfg: Dictionary = _load_json_dict(VISUAL_SNAPSHOT_TARGETS_PATH)
	var snapshots: Dictionary = cfg.get("snapshots", {})

	for snapshot_id_var: Variant in snapshots.keys():
		var snapshot_id: String = str(snapshot_id_var)
		var row: Dictionary = snapshots.get(snapshot_id, {})
		var scene_path: String = str(row.get("scene", ""))
		assert_true(ResourceLoader.exists(scene_path), "%s scene should exist" % snapshot_id)

	var thresholds: Dictionary = cfg.get("thresholds", {})
	assert_gte(int(thresholds.get("min_snapshots", 0)), 5, "D36 min_snapshots should be >= 5")
	assert_eq(int(thresholds.get("max_failures", -1)), 0, "max_failures should stay strict at 0")
	assert_eq(int(thresholds.get("max_trend_regressions", -1)), 0, "max_trend_regressions should stay strict at 0")
	assert_gte(float(thresholds.get("max_opaque_ratio_drop", -1.0)), 0.0, "max_opaque_ratio_drop should be >= 0")
	assert_lte(float(thresholds.get("max_opaque_ratio_drop", -1.0)), 1.0, "max_opaque_ratio_drop should be <= 1")
	assert_lte(float(thresholds.get("max_opaque_ratio_drop", 1.0)), 0.12, "D36 max_opaque_ratio_drop should be <= 0.12")
	assert_gte(float(thresholds.get("max_unique_color_drop_ratio", -1.0)), 0.0, "max_unique_color_drop_ratio should be >= 0")
	assert_lte(float(thresholds.get("max_unique_color_drop_ratio", -1.0)), 1.0, "max_unique_color_drop_ratio should be <= 1")
	assert_lte(float(thresholds.get("max_unique_color_drop_ratio", 1.0)), 0.45, "D36 max_unique_color_drop_ratio should be <= 0.45")
	assert_gte(float(thresholds.get("max_luma_delta", -1.0)), 0.0, "max_luma_delta should be >= 0")
	assert_lte(float(thresholds.get("max_luma_delta", -1.0)), 1.0, "max_luma_delta should be <= 1")
	assert_lte(float(thresholds.get("max_luma_delta", 1.0)), 0.15, "D36 max_luma_delta should be <= 0.15")
