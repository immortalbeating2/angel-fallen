from pathlib import Path
import json


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    expected_dirs = [
        root / "scenes",
        root / "scenes" / "game",
        root / "scenes" / "ui",
        root / "scripts" / "autoload",
        root / "scripts" / "game",
        root / "scripts" / "systems",
        root / "test",
        root / "test" / "unit",
        root / "test" / "integration",
        root / "scripts",
        root / "scripts" / "tools",
        root / "data" / "balance",
        root / "assets" / "sprites" / "tiles",
        root / "resources" / "characters",
        root / "resources" / "weapons",
        root / "resources" / "passives",
        root / "resources" / "accessories",
        root / "resources" / "enemies",
        root / "resources" / "evolutions",
        root / "resources" / "meta_upgrades",
        root / "resources" / "forge_recipes",
        root / "resources" / "material_profiles",
        root / "resources" / "tilesets",
    ]

    expected_files = [
        root / "project.godot",
        root / "scenes" / "main_menu" / "main_menu.tscn",
        root / "scenes" / "game" / "game_world.tscn",
        root / "scenes" / "ui" / "hud.tscn",
        root / "scenes" / "ui" / "pause_panel.tscn",
        root / "scenes" / "ui" / "runtime_settings_panel.tscn",
        root / "scripts" / "autoload" / "game_manager.gd",
        root / "scripts" / "autoload" / "event_bus.gd",
        root / "scripts" / "autoload" / "save_manager.gd",
        root / "scripts" / "game" / "game_world.gd",
        root / "scripts" / "ui" / "pause_panel.gd",
        root / "scripts" / "ui" / "runtime_settings_panel.gd",
        root / "scripts" / "systems" / "enemy_spawner.gd",
        root / "scripts" / "systems" / "map_generator.gd",
        root / "scripts" / "systems" / "narrative_system.gd",
        root / "data" / "balance" / "characters.json",
        root / "data" / "balance" / "quality_baseline_targets.json",
        root / "data" / "balance" / "release_gate_targets.json",
        root / "data" / "balance" / "compatibility_rehearsal_targets.json",
        root / "data" / "balance" / "resource_acceptance_targets.json",
        root / "data" / "balance" / "visual_snapshot_targets.json",
        root / "data" / "balance" / "map_generation.json",
        root / "test" / "unit" / "test_character_weapon_profiles.gd",
        root / "test" / "unit" / "test_enemy_scaling_profiles.gd",
        root / "test" / "unit" / "test_shop_economy_config.gd",
        root / "test" / "unit" / "test_narrative_route_style_config.gd",
        root / "test" / "unit" / "test_map_generation_config.gd",
        root / "test" / "unit" / "test_evolutions_config.gd",
        root / "test" / "unit" / "test_enemy_pooling.gd",
        root / "test" / "unit" / "test_quality_baseline_targets.gd",
        root / "test" / "unit" / "test_release_gate_targets.gd",
        root / "test" / "unit" / "test_compatibility_rehearsal_targets.gd",
        root / "test" / "unit" / "test_resource_acceptance_targets.gd",
        root / "test" / "unit" / "test_resource_directory_baseline.gd",
        root / "test" / "unit" / "test_visual_snapshot_targets.gd",
        root / "test" / "unit" / "test_visual_tilemap_layers.gd",
        root / "test" / "integration" / "test_core_flow_regression.gd",
        root / "scripts" / "tools" / "generate_visual_tiles.py",
        root / "scripts" / "tools" / "build_tileset_resources.gd",
        root / "scripts" / "tools" / "check_json_syntax.py",
        root / "scripts" / "tools" / "sync_resource_stubs.py",
        root / "scripts" / "tools" / "run_quality_baseline.gd",
        root / "scripts" / "tools" / "run_release_gate.gd",
        root / "scripts" / "tools" / "run_compatibility_rehearsal.gd",
        root / "scripts" / "tools" / "run_resource_acceptance.gd",
        root / "scripts" / "tools" / "run_visual_snapshot_regression.gd",
        root / "assets" / "sprites" / "tiles" / "ground_ch1.png",
        root / "assets" / "sprites" / "tiles" / "ground_ch2.png",
        root / "assets" / "sprites" / "tiles" / "ground_ch3.png",
        root / "assets" / "sprites" / "tiles" / "ground_ch4.png",
        root / "assets" / "sprites" / "tiles" / "ground_detail_ch1.png",
        root / "assets" / "sprites" / "tiles" / "ground_detail_ch2.png",
        root / "assets" / "sprites" / "tiles" / "ground_detail_ch3.png",
        root / "assets" / "sprites" / "tiles" / "ground_detail_ch4.png",
        root / "assets" / "sprites" / "tiles" / "doors_ch1.png",
        root / "assets" / "sprites" / "tiles" / "doors_ch2.png",
        root / "assets" / "sprites" / "tiles" / "doors_ch3.png",
        root / "assets" / "sprites" / "tiles" / "doors_ch4.png",
        root / "assets" / "sprites" / "tiles" / "hazard_overlay_ch1.png",
        root / "assets" / "sprites" / "tiles" / "hazard_overlay_ch2.png",
        root / "assets" / "sprites" / "tiles" / "hazard_overlay_ch3.png",
        root / "assets" / "sprites" / "tiles" / "hazard_overlay_ch4.png",
        root / "assets" / "sprites" / "tiles" / "ambient_fx_ch1.png",
        root / "assets" / "sprites" / "tiles" / "ambient_fx_ch2.png",
        root / "assets" / "sprites" / "tiles" / "ambient_fx_ch3.png",
        root / "assets" / "sprites" / "tiles" / "ambient_fx_ch4.png",
        root / "assets" / "sprites" / "tiles" / "doors.png",
        root / "assets" / "sprites" / "tiles" / "hazard_overlay.png",
        root / "assets" / "sprites" / "tiles" / "atlas_manifest.json",
        root / "resources" / "resource_catalog.json",
        root / "resources" / "material_profiles" / "mat_character_base.tres",
        root / "resources" / "material_profiles" / "mat_weapon_base.tres",
        root / "resources" / "material_profiles" / "mat_passive_base.tres",
        root / "resources" / "material_profiles" / "mat_accessory_base.tres",
        root / "resources" / "material_profiles" / "mat_enemy_base.tres",
        root / "resources" / "material_profiles" / "mat_evolution_base.tres",
        root / "resources" / "material_profiles" / "mat_meta_upgrade_base.tres",
        root / "resources" / "material_profiles" / "mat_forge_recipe_base.tres",
        root / "resources" / "characters" / "char_knight.tres",
        root / "resources" / "weapons" / "wpn_holy_cross.tres",
        root / "resources" / "passives" / "pas_might.tres",
        root / "resources" / "accessories" / "acc_heart_of_mine.tres",
        root / "resources" / "enemies" / "enemy_slime.tres",
        root / "resources" / "evolutions" / "evo_arcane_comet.tres",
        root / "resources" / "meta_upgrades" / "meta_max_hp.tres",
        root / "resources" / "forge_recipes" / "forge_radiant_edge.tres",
        root / "resources" / "tilesets" / "game_world_ground_ch1.tres",
        root / "resources" / "tilesets" / "game_world_ground_ch2.tres",
        root / "resources" / "tilesets" / "game_world_ground_ch3.tres",
        root / "resources" / "tilesets" / "game_world_ground_ch4.tres",
        root / "resources" / "tilesets" / "game_world_ground_detail_ch1.tres",
        root / "resources" / "tilesets" / "game_world_ground_detail_ch2.tres",
        root / "resources" / "tilesets" / "game_world_ground_detail_ch3.tres",
        root / "resources" / "tilesets" / "game_world_ground_detail_ch4.tres",
        root / "resources" / "tilesets" / "game_world_doors_ch1.tres",
        root / "resources" / "tilesets" / "game_world_doors_ch2.tres",
        root / "resources" / "tilesets" / "game_world_doors_ch3.tres",
        root / "resources" / "tilesets" / "game_world_doors_ch4.tres",
        root / "resources" / "tilesets" / "game_world_hazard_overlay_ch1.tres",
        root / "resources" / "tilesets" / "game_world_hazard_overlay_ch2.tres",
        root / "resources" / "tilesets" / "game_world_hazard_overlay_ch3.tres",
        root / "resources" / "tilesets" / "game_world_hazard_overlay_ch4.tres",
        root / "resources" / "tilesets" / "game_world_ambient_fx_ch1.tres",
        root / "resources" / "tilesets" / "game_world_ambient_fx_ch2.tres",
        root / "resources" / "tilesets" / "game_world_ambient_fx_ch3.tres",
        root / "resources" / "tilesets" / "game_world_ambient_fx_ch4.tres",
        root / "resources" / "tilesets" / "game_world_doors.tres",
        root / "resources" / "tilesets" / "game_world_hazard_overlay.tres",
    ]

    warnings: list[str] = []

    for directory in expected_dirs:
        if not directory.exists():
            print(f"Missing required directory: {directory}")
            return 1

    for file_path in expected_files:
        if not file_path.exists():
            print(f"Missing required file: {file_path}")
            return 1

    manifest_path = root / "assets" / "sprites" / "tiles" / "atlas_manifest.json"
    try:
        atlas_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Cannot parse atlas_manifest.json: {exc}")
        return 1

    if atlas_manifest.get("style") != "handdrawn_v1":
        print("atlas_manifest.json style must be 'handdrawn_v1'")
        return 1

    atlas_entries = atlas_manifest.get("atlases", [])
    if not isinstance(atlas_entries, list) or len(atlas_entries) < 10:
        print("atlas_manifest.json atlases must be a non-empty array with at least 10 entries")
        return 1

    resource_catalog_path = root / "resources" / "resource_catalog.json"
    try:
        resource_catalog = json.loads(resource_catalog_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Cannot parse resource_catalog.json: {exc}")
        return 1

    if resource_catalog.get("version") != "stub_catalog_v8":
        print("resource_catalog.json version must be 'stub_catalog_v8'")
        return 1

    resource_acceptance_targets_path = root / "data" / "balance" / "resource_acceptance_targets.json"
    try:
        resource_acceptance_targets = json.loads(resource_acceptance_targets_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Cannot parse resource_acceptance_targets.json: {exc}")
        return 1

    profile_policy = resource_acceptance_targets.get("acceptance_profile_policy", {})
    scene_matrix = resource_acceptance_targets.get("acceptance_scene_matrix", {})
    scene_visual_requirements = resource_acceptance_targets.get("scene_visual_requirements", {})
    trend_baseline = resource_acceptance_targets.get("trend_baseline", {})
    thresholds = resource_acceptance_targets.get("thresholds", {})
    if not isinstance(profile_policy, dict) or not profile_policy:
        print("resource_acceptance_targets.json acceptance_profile_policy must be a non-empty object")
        return 1
    profiles = profile_policy.get("profiles", {})
    category_profile_map = profile_policy.get("category_profile_map", {})
    required_ready_profile_tier = profile_policy.get("required_ready_profile_tier", "ready")
    if not isinstance(profiles, dict) or not profiles:
        print("resource_acceptance_targets.json acceptance_profile_policy.profiles must be a non-empty object")
        return 1
    if not isinstance(category_profile_map, dict) or not category_profile_map:
        print("resource_acceptance_targets.json acceptance_profile_policy.category_profile_map must be a non-empty object")
        return 1
    if required_ready_profile_tier not in {"candidate", "ready"}:
        print("resource_acceptance_targets.json acceptance_profile_policy.required_ready_profile_tier must be candidate or ready")
        return 1
    if not isinstance(scene_visual_requirements, dict) or not scene_visual_requirements:
        print("resource_acceptance_targets.json scene_visual_requirements must be a non-empty object")
        return 1
    if not isinstance(scene_matrix, dict) or not scene_matrix:
        print("resource_acceptance_targets.json acceptance_scene_matrix must be a non-empty object")
        return 1
    allowed_visual_rules = {
        "exists",
        "non_null",
        "non_empty_string",
        "array_non_empty",
        "float_gt_zero",
        "bool_true",
    }
    if not isinstance(trend_baseline, dict) or not trend_baseline:
        print("resource_acceptance_targets.json trend_baseline must be a non-empty object")
        return 1
    bucket_ready_ratio_min = trend_baseline.get("bucket_ready_ratio_min", {})
    if not isinstance(bucket_ready_ratio_min, dict) or not bucket_ready_ratio_min:
        print("resource_acceptance_targets.json trend_baseline.bucket_ready_ratio_min must be a non-empty object")
        return 1
    for bucket in ("menu", "combat", "ui"):
        ratio = bucket_ready_ratio_min.get(bucket)
        if not isinstance(ratio, (int, float)) or ratio < 0.1 or ratio > 1.0:
            print(f"resource_acceptance_targets.json trend_baseline.bucket_ready_ratio_min.{bucket} must be within [0.1, 1.0]")
            return 1
    max_category_ratio_drop = trend_baseline.get("max_category_ratio_drop")
    max_bucket_ratio_drop = trend_baseline.get("max_bucket_ratio_drop")
    if not isinstance(max_category_ratio_drop, (int, float)) or max_category_ratio_drop < 0.0 or max_category_ratio_drop > 1.0:
        print("resource_acceptance_targets.json trend_baseline.max_category_ratio_drop must be within [0.0, 1.0]")
        return 1
    if not isinstance(max_bucket_ratio_drop, (int, float)) or max_bucket_ratio_drop < 0.0 or max_bucket_ratio_drop > 1.0:
        print("resource_acceptance_targets.json trend_baseline.max_bucket_ratio_drop must be within [0.0, 1.0]")
        return 1
    max_trend_regressions = thresholds.get("max_trend_regressions")
    min_scene_smokes_per_category = thresholds.get("min_scene_smokes_per_category")
    min_visual_checks_per_category = thresholds.get("min_visual_checks_per_category")
    max_visual_failures = thresholds.get("max_visual_failures")
    if not isinstance(max_trend_regressions, int) or max_trend_regressions < 0:
        print("resource_acceptance_targets.json thresholds.max_trend_regressions must be int >= 0")
        return 1
    if not isinstance(min_visual_checks_per_category, int) or min_visual_checks_per_category < 1:
        print("resource_acceptance_targets.json thresholds.min_visual_checks_per_category must be int >= 1")
        return 1
    if not isinstance(min_scene_smokes_per_category, int) or min_scene_smokes_per_category < 1:
        print("resource_acceptance_targets.json thresholds.min_scene_smokes_per_category must be int >= 1")
        return 1
    if not isinstance(max_visual_failures, int) or max_visual_failures < 0:
        print("resource_acceptance_targets.json thresholds.max_visual_failures must be int >= 0")
        return 1

    production_ready_counts = resource_catalog.get("production_ready_counts", {})
    if not isinstance(production_ready_counts, dict):
        print("resource_catalog.json production_ready_counts must be an object")
        return 1

    production_ready_ratio_by_category = resource_catalog.get("production_ready_ratio_by_category", {})
    if not isinstance(production_ready_ratio_by_category, dict):
        print("resource_catalog.json production_ready_ratio_by_category must be an object")
        return 1

    acceptance_tier_counts = resource_catalog.get("acceptance_tier_counts", {})
    if not isinstance(acceptance_tier_counts, dict):
        print("resource_catalog.json acceptance_tier_counts must be an object")
        return 1

    acceptance_bucket_counts = resource_catalog.get("acceptance_bucket_counts", {})
    if not isinstance(acceptance_bucket_counts, dict):
        print("resource_catalog.json acceptance_bucket_counts must be an object")
        return 1

    catalog_scene_visual_requirements = resource_catalog.get("scene_visual_requirements", {})
    if not isinstance(catalog_scene_visual_requirements, dict):
        print("resource_catalog.json scene_visual_requirements must be an object")
        return 1

    catalog_scene_visual_requirement_counts = resource_catalog.get("scene_visual_requirement_counts", {})
    if not isinstance(catalog_scene_visual_requirement_counts, dict):
        print("resource_catalog.json scene_visual_requirement_counts must be an object")
        return 1

    categories = resource_catalog.get("categories", {})
    if not isinstance(categories, dict):
        print("resource_catalog.json categories must be an object")
        return 1

    required_categories = [
        "characters",
        "weapons",
        "passives",
        "accessories",
        "enemies",
        "evolutions",
        "meta_upgrades",
        "forge_recipes",
    ]

    computed_bucket_counts: dict[str, dict[str, int]] = {}

    for category in required_categories:
        entries = categories.get(category, [])
        if not isinstance(entries, list) or not entries:
            print(f"resource_catalog.json categories.{category} must be a non-empty array")
            return 1

        visual_rows = scene_visual_requirements.get(category, [])
        smoke_scenes = scene_matrix.get(category, [])
        if not isinstance(smoke_scenes, list) or not smoke_scenes:
            print(f"resource_acceptance_targets.json acceptance_scene_matrix.{category} must be a non-empty array")
            return 1
        if len(smoke_scenes) < min_scene_smokes_per_category:
            print(
                f"resource_acceptance_targets.json acceptance_scene_matrix.{category} "
                f"must include at least {min_scene_smokes_per_category} scenes"
            )
            return 1
        for idx, scene_path in enumerate(smoke_scenes):
            if not isinstance(scene_path, str) or not scene_path.startswith("res://"):
                print(f"resource_acceptance_targets.json acceptance_scene_matrix.{category}[{idx}] must be res:// path")
                return 1
            scene_disk_path = root / scene_path.replace("res://", "")
            if not scene_disk_path.exists():
                print(f"resource_acceptance_targets.json acceptance_scene_matrix scene target missing: {scene_path}")
                return 1

        if not isinstance(visual_rows, list) or not visual_rows:
            print(f"resource_acceptance_targets.json scene_visual_requirements.{category} must be a non-empty array")
            return 1
        if len(visual_rows) < min_visual_checks_per_category:
            print(
                f"resource_acceptance_targets.json scene_visual_requirements.{category} "
                f"must include at least {min_visual_checks_per_category} checks"
            )
            return 1
        catalog_visual_rows = catalog_scene_visual_requirements.get(category, [])
        if not isinstance(catalog_visual_rows, list) or len(catalog_visual_rows) != len(visual_rows):
            print(f"resource_catalog.json scene_visual_requirements.{category} mismatch with targets")
            return 1
        if catalog_scene_visual_requirement_counts.get(category) != len(visual_rows):
            print(f"resource_catalog.json scene_visual_requirement_counts.{category} mismatch with visual requirements")
            return 1
        for idx, visual_row in enumerate(visual_rows):
            if not isinstance(visual_row, dict):
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}] must be object")
                return 1
            scene_path = visual_row.get("scene")
            node_path = visual_row.get("node_path")
            node_type = visual_row.get("node_type")
            rule = visual_row.get("rule")
            prop = visual_row.get("property")
            if not isinstance(scene_path, str) or not scene_path.startswith("res://"):
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].scene must be res:// path")
                return 1
            if not isinstance(node_path, str) or not node_path:
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].node_path must be non-empty string")
                return 1
            if not isinstance(node_type, str) or not node_type:
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].node_type must be non-empty string")
                return 1
            if not isinstance(rule, str) or rule not in allowed_visual_rules:
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].rule invalid")
                return 1
            if rule != "exists" and (not isinstance(prop, str) or not prop):
                print(f"resource_acceptance_targets.json scene_visual_requirements.{category}[{idx}].property required when rule != exists")
                return 1
            scene_disk_path = root / scene_path.replace("res://", "")
            if not scene_disk_path.exists():
                print(f"resource_acceptance_targets.json visual scene target missing: {scene_path}")
                return 1

        ready_count = 0
        category_tier_count = {"candidate": 0, "ready": 0}

        for entry in entries:
            if not isinstance(entry, dict):
                print(f"resource_catalog.json categories.{category} entry must be object")
                return 1

            resource_id = entry.get("id")
            resource_path = entry.get("path")
            source_json_path = entry.get("source_json")
            material_profile = entry.get("material_profile")
            asset_state = entry.get("asset_state")
            preview_texture = entry.get("preview_texture")
            acceptance_scene = entry.get("acceptance_scene")
            acceptance_profile = entry.get("acceptance_profile")
            acceptance_tier = entry.get("acceptance_tier")

            if not isinstance(resource_id, str) or not resource_id:
                print(f"resource_catalog.json categories.{category} entry id must be non-empty string")
                return 1
            if not isinstance(resource_path, str) or not resource_path.startswith("res://resources/"):
                print(f"resource_catalog.json categories.{category} entry path must start with res://resources/")
                return 1
            if not isinstance(source_json_path, str) or not source_json_path.startswith("res://"):
                print(f"resource_catalog.json categories.{category} entry source_json must start with res://")
                return 1
            if not isinstance(material_profile, str) or not material_profile.startswith("res://resources/material_profiles/"):
                print(f"resource_catalog.json categories.{category} entry material_profile must be a material profile path")
                return 1
            if asset_state not in {"production_candidate", "production_ready"}:
                print(f"resource_catalog.json categories.{category} entry asset_state must be production_candidate or production_ready")
                return 1
            if not isinstance(preview_texture, str) or not preview_texture.startswith("res://"):
                print(f"resource_catalog.json categories.{category} entry preview_texture must be res:// path")
                return 1
            if not isinstance(acceptance_scene, str) or not acceptance_scene.startswith("res://"):
                print(f"resource_catalog.json categories.{category} entry acceptance_scene must be res:// path")
                return 1
            if not isinstance(acceptance_profile, str) or not acceptance_profile:
                print(f"resource_catalog.json categories.{category} entry acceptance_profile must be non-empty string")
                return 1
            if not isinstance(acceptance_tier, str) or acceptance_tier not in {"candidate", "ready"}:
                print(f"resource_catalog.json categories.{category} entry acceptance_tier must be candidate or ready")
                return 1

            profile_row = profiles.get(acceptance_profile)
            if not isinstance(profile_row, dict):
                print(f"resource_catalog.json categories.{category} entry acceptance_profile must reference acceptance_profile_policy.profiles")
                return 1
            profile_tier = profile_row.get("tier")
            if profile_tier != acceptance_tier:
                print(f"resource_catalog.json categories.{category} entry acceptance_tier must match profile tier")
                return 1
            report_bucket = profile_row.get("report_bucket")
            if not isinstance(report_bucket, str) or not report_bucket:
                print(f"resource_catalog.json categories.{category} entry acceptance_profile report_bucket must be non-empty string")
                return 1

            state_profile_row = category_profile_map.get(category, {})
            if not isinstance(state_profile_row, dict):
                print(f"resource_acceptance_targets.json acceptance_profile_policy.category_profile_map.{category} must be object")
                return 1
            expected_profile = state_profile_row.get(asset_state)
            if isinstance(expected_profile, str) and expected_profile and expected_profile != acceptance_profile:
                print(f"resource_catalog.json categories.{category} entry acceptance_profile must match category_profile_map for {asset_state}")
                return 1

            if asset_state == "production_ready":
                ready_count += 1
                if acceptance_tier != required_ready_profile_tier:
                    print(f"resource_catalog.json categories.{category} production_ready entry acceptance_tier must be {required_ready_profile_tier}")
                    return 1

            category_tier_count[acceptance_tier] = int(category_tier_count.get(acceptance_tier, 0)) + 1
            if report_bucket not in computed_bucket_counts:
                computed_bucket_counts[report_bucket] = {
                    "entries": 0,
                    "ready_entries": 0,
                }
            computed_bucket_counts[report_bucket]["entries"] = int(computed_bucket_counts[report_bucket].get("entries", 0)) + 1
            if asset_state == "production_ready":
                computed_bucket_counts[report_bucket]["ready_entries"] = int(computed_bucket_counts[report_bucket].get("ready_entries", 0)) + 1

            resource_disk_path = root / resource_path.replace("res://", "")
            if not resource_disk_path.exists():
                print(f"Resource stub missing from catalog path: {resource_path}")
                return 1

            try:
                resource_text = resource_disk_path.read_text(encoding="utf-8")
            except Exception as exc:
                print(f"Cannot read resource stub {resource_path}: {exc}")
                return 1

            if f'id = "{resource_id}"' not in resource_text:
                print(f"Resource stub id mismatch: {resource_path}")
                return 1
            if f'source_json = "{source_json_path}"' not in resource_text:
                print(f"Resource stub source_json mismatch: {resource_path}")
                return 1
            if f'material_profile = "{material_profile}"' not in resource_text:
                print(f"Resource stub material_profile mismatch: {resource_path}")
                return 1
            if f'asset_state = "{asset_state}"' not in resource_text:
                print(f"Resource stub asset_state mismatch: {resource_path}")
                return 1
            if f'preview_texture = "{preview_texture}"' not in resource_text:
                print(f"Resource stub preview_texture mismatch: {resource_path}")
                return 1
            if f'acceptance_scene = "{acceptance_scene}"' not in resource_text:
                print(f"Resource stub acceptance_scene mismatch: {resource_path}")
                return 1
            if f'acceptance_profile = "{acceptance_profile}"' not in resource_text:
                print(f"Resource stub acceptance_profile mismatch: {resource_path}")
                return 1
            if f'acceptance_tier = "{acceptance_tier}"' not in resource_text:
                print(f"Resource stub acceptance_tier mismatch: {resource_path}")
                return 1

            source_disk_path = root / source_json_path.replace("res://", "")
            if not source_disk_path.exists():
                print(f"Resource stub source_json target missing: {source_json_path} (from {resource_path})")
                return 1

            material_profile_disk_path = root / material_profile.replace("res://", "")
            if not material_profile_disk_path.exists():
                print(f"Resource stub material_profile target missing: {material_profile} (from {resource_path})")
                return 1

            preview_texture_disk_path = root / preview_texture.replace("res://", "")
            if not preview_texture_disk_path.exists():
                print(f"Resource stub preview_texture target missing: {preview_texture} (from {resource_path})")
                return 1

            acceptance_scene_disk_path = root / acceptance_scene.replace("res://", "")
            if not acceptance_scene_disk_path.exists():
                print(f"Resource stub acceptance_scene target missing: {acceptance_scene} (from {resource_path})")
                return 1

        if production_ready_counts.get(category) != ready_count:
            print(f"resource_catalog.json production_ready_counts.{category} mismatch with categorized entries")
            return 1
        entry_count = len(entries)
        expected_ratio = float(ready_count) / float(entry_count) if entry_count > 0 else 0.0
        ratio_value = production_ready_ratio_by_category.get(category)
        if not isinstance(ratio_value, (int, float)):
            print(f"resource_catalog.json production_ready_ratio_by_category.{category} must be number")
            return 1
        if abs(float(ratio_value) - expected_ratio) > 0.0001:
            print(f"resource_catalog.json production_ready_ratio_by_category.{category} mismatch with categorized entries")
            return 1

        tier_count_row = acceptance_tier_counts.get(category)
        if not isinstance(tier_count_row, dict):
            print(f"resource_catalog.json acceptance_tier_counts.{category} must be object")
            return 1
        if tier_count_row.get("candidate") != category_tier_count["candidate"]:
            print(f"resource_catalog.json acceptance_tier_counts.{category}.candidate mismatch with categorized entries")
            return 1
        if tier_count_row.get("ready") != category_tier_count["ready"]:
            print(f"resource_catalog.json acceptance_tier_counts.{category}.ready mismatch with categorized entries")
            return 1

    for bucket, row in computed_bucket_counts.items():
        catalog_row = acceptance_bucket_counts.get(bucket)
        if not isinstance(catalog_row, dict):
            print(f"resource_catalog.json acceptance_bucket_counts.{bucket} must be object")
            return 1
        if catalog_row.get("entries") != row["entries"]:
            print(f"resource_catalog.json acceptance_bucket_counts.{bucket}.entries mismatch with categorized entries")
            return 1
        if catalog_row.get("ready_entries") != row["ready_entries"]:
            print(f"resource_catalog.json acceptance_bucket_counts.{bucket}.ready_entries mismatch with categorized entries")
            return 1

    visual_snapshot_targets_path = root / "data" / "balance" / "visual_snapshot_targets.json"
    try:
        visual_snapshot_targets = json.loads(visual_snapshot_targets_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Cannot parse visual_snapshot_targets.json: {exc}")
        return 1

    channel = visual_snapshot_targets.get("channel")
    snapshots = visual_snapshot_targets.get("snapshots", {})
    precision = visual_snapshot_targets.get("precision", {})
    backend_profiles = visual_snapshot_targets.get("backend_profiles", {})
    snapshot_thresholds = visual_snapshot_targets.get("thresholds", {})
    baseline_alignment = visual_snapshot_targets.get("baseline_alignment", {})
    diff_whitelist = visual_snapshot_targets.get("diff_whitelist", {})
    whitelist_policy = visual_snapshot_targets.get("whitelist_policy", {})
    backend_attribution = visual_snapshot_targets.get("backend_attribution", {})
    whitelist_convergence = visual_snapshot_targets.get("whitelist_convergence", {})
    exception_lifecycle = visual_snapshot_targets.get("exception_lifecycle", {})
    strategy_orchestration = visual_snapshot_targets.get("strategy_orchestration", {})
    release_gate_templates = visual_snapshot_targets.get("release_gate_templates", {})
    backend_matrix_governance = visual_snapshot_targets.get("backend_matrix_governance", {})
    approval_workflow = visual_snapshot_targets.get("approval_workflow", {})
    approval_audit_trail = visual_snapshot_targets.get("approval_audit_trail", {})
    approval_history_archive = visual_snapshot_targets.get("approval_history_archive", {})
    approval_threshold_templates = visual_snapshot_targets.get("approval_threshold_templates", {})
    release_candidate_tracking = visual_snapshot_targets.get("release_candidate_tracking", {})
    stability_scoring = visual_snapshot_targets.get("stability_scoring", {})
    stability_tiers = visual_snapshot_targets.get("stability_tiers", {})
    convergence_dashboard = visual_snapshot_targets.get("convergence_dashboard", {})
    ci_signal_contract = visual_snapshot_targets.get("ci_signal_contract", {})
    convergence_trend_reinforcement = visual_snapshot_targets.get("convergence_trend_reinforcement", {})
    exception_lifecycle_linkage = visual_snapshot_targets.get("exception_lifecycle_linkage", {})
    visual_performance_cogate = visual_snapshot_targets.get("visual_performance_cogate", {})
    cogate_threshold_templates = visual_snapshot_targets.get("cogate_threshold_templates", {})
    cross_platform_alignment = visual_snapshot_targets.get("cross_platform_alignment", {})
    pressure_scenario_standardization = visual_snapshot_targets.get("pressure_scenario_standardization", {})
    alignment_dashboard_refinement = visual_snapshot_targets.get("alignment_dashboard_refinement", {})
    pressure_alignment_convergence_gate = visual_snapshot_targets.get("pressure_alignment_convergence_gate", {})
    regression_cycle_window_governance = visual_snapshot_targets.get("regression_cycle_window_governance", {})
    multi_cycle_adaptive_gate = visual_snapshot_targets.get("multi_cycle_adaptive_gate", {})
    release_feedback_governance = visual_snapshot_targets.get("release_feedback_governance", {})
    report_layers = visual_snapshot_targets.get("report_layers", {})
    cross_version_baseline = visual_snapshot_targets.get("cross_version_baseline", {})

    if not isinstance(channel, str) or not channel:
        print("visual_snapshot_targets.json channel must be non-empty string")
        return 1
    if channel != "chapter_snapshot_v19":
        print("visual_snapshot_targets.json channel must be chapter_snapshot_v19")
        return 1
    if not isinstance(snapshots, dict) or not snapshots:
        print("visual_snapshot_targets.json snapshots must be non-empty object")
        return 1
    if not isinstance(snapshot_thresholds, dict) or not snapshot_thresholds:
        print("visual_snapshot_targets.json thresholds must be non-empty object")
        return 1
    if not isinstance(precision, dict) or not precision:
        print("visual_snapshot_targets.json precision must be non-empty object")
        return 1
    if not isinstance(backend_profiles, dict) or not backend_profiles:
        print("visual_snapshot_targets.json backend_profiles must be non-empty object")
        return 1

    required_backend_profiles = ["default", "linux_headless", "windows_headless"]
    for profile_name in required_backend_profiles:
        if profile_name not in backend_profiles:
            print(f"visual_snapshot_targets.json backend_profiles must include '{profile_name}'")
            return 1

    min_snapshots = snapshot_thresholds.get("min_snapshots")
    max_failures = snapshot_thresholds.get("max_failures")
    max_trend_regressions = snapshot_thresholds.get("max_trend_regressions")
    max_opaque_ratio_drop = snapshot_thresholds.get("max_opaque_ratio_drop")
    max_unique_color_drop_ratio = snapshot_thresholds.get("max_unique_color_drop_ratio")
    max_luma_delta = snapshot_thresholds.get("max_luma_delta")

    if not isinstance(min_snapshots, int) or min_snapshots < 1:
        print("visual_snapshot_targets.json thresholds.min_snapshots must be int >= 1")
        return 1
    if not isinstance(max_failures, int) or max_failures < 0:
        print("visual_snapshot_targets.json thresholds.max_failures must be int >= 0")
        return 1
    if not isinstance(max_trend_regressions, int) or max_trend_regressions < 0:
        print("visual_snapshot_targets.json thresholds.max_trend_regressions must be int >= 0")
        return 1
    if not isinstance(max_opaque_ratio_drop, (int, float)) or max_opaque_ratio_drop < 0.0 or max_opaque_ratio_drop > 1.0:
        print("visual_snapshot_targets.json thresholds.max_opaque_ratio_drop must be within [0.0, 1.0]")
        return 1
    if not isinstance(max_unique_color_drop_ratio, (int, float)) or max_unique_color_drop_ratio < 0.0 or max_unique_color_drop_ratio > 1.0:
        print("visual_snapshot_targets.json thresholds.max_unique_color_drop_ratio must be within [0.0, 1.0]")
        return 1
    if not isinstance(max_luma_delta, (int, float)) or max_luma_delta < 0.0 or max_luma_delta > 1.0:
        print("visual_snapshot_targets.json thresholds.max_luma_delta must be within [0.0, 1.0]")
        return 1

    sample_rounds = precision.get("sample_rounds")
    max_opaque_ratio_stddev = precision.get("max_opaque_ratio_stddev")
    max_luma_stddev = precision.get("max_luma_stddev")
    max_unique_color_stddev_ratio = precision.get("max_unique_color_stddev_ratio")
    if not isinstance(sample_rounds, int) or sample_rounds < 1 or sample_rounds > 8:
        print("visual_snapshot_targets.json precision.sample_rounds must be int within [1, 8]")
        return 1
    if not isinstance(max_opaque_ratio_stddev, (int, float)) or max_opaque_ratio_stddev < 0.0 or max_opaque_ratio_stddev > 0.5:
        print("visual_snapshot_targets.json precision.max_opaque_ratio_stddev must be within [0.0, 0.5]")
        return 1
    if not isinstance(max_luma_stddev, (int, float)) or max_luma_stddev < 0.0 or max_luma_stddev > 0.5:
        print("visual_snapshot_targets.json precision.max_luma_stddev must be within [0.0, 0.5]")
        return 1
    if not isinstance(max_unique_color_stddev_ratio, (int, float)) or max_unique_color_stddev_ratio < 0.0 or max_unique_color_stddev_ratio > 1.0:
        print("visual_snapshot_targets.json precision.max_unique_color_stddev_ratio must be within [0.0, 1.0]")
        return 1

    for profile_name, row in backend_profiles.items():
        if not isinstance(profile_name, str) or not profile_name:
            print("visual_snapshot_targets.json backend_profiles key must be non-empty string")
            return 1
        if not isinstance(row, dict) or not row:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name} must be non-empty object")
            return 1
        max_opaque_ratio_drop_profile = row.get("max_opaque_ratio_drop")
        max_unique_color_drop_ratio_profile = row.get("max_unique_color_drop_ratio")
        max_luma_delta_profile = row.get("max_luma_delta")
        unique_colors_min_scale = row.get("unique_colors_min_scale")
        luma_range_padding = row.get("luma_range_padding")
        if not isinstance(max_opaque_ratio_drop_profile, (int, float)) or max_opaque_ratio_drop_profile < 0.0 or max_opaque_ratio_drop_profile > 1.0:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_opaque_ratio_drop must be within [0.0, 1.0]")
            return 1
        if not isinstance(max_unique_color_drop_ratio_profile, (int, float)) or max_unique_color_drop_ratio_profile < 0.0 or max_unique_color_drop_ratio_profile > 1.0:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_unique_color_drop_ratio must be within [0.0, 1.0]")
            return 1
        if not isinstance(max_luma_delta_profile, (int, float)) or max_luma_delta_profile < 0.0 or max_luma_delta_profile > 1.0:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name}.max_luma_delta must be within [0.0, 1.0]")
            return 1
        if not isinstance(unique_colors_min_scale, (int, float)) or unique_colors_min_scale < 0.5 or unique_colors_min_scale > 2.0:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name}.unique_colors_min_scale must be within [0.5, 2.0]")
            return 1
        if not isinstance(luma_range_padding, (int, float)) or luma_range_padding < 0.0 or luma_range_padding > 0.3:
            print(f"visual_snapshot_targets.json backend_profiles.{profile_name}.luma_range_padding must be within [0.0, 0.3]")
            return 1

    if not isinstance(baseline_alignment, dict) or not baseline_alignment:
        print("visual_snapshot_targets.json baseline_alignment must be non-empty object")
        return 1
    required_snapshot_ids = baseline_alignment.get("required_snapshot_ids", [])
    allowed_capture_modes = baseline_alignment.get("allowed_capture_modes", {})
    if not isinstance(required_snapshot_ids, list) or not required_snapshot_ids:
        print("visual_snapshot_targets.json baseline_alignment.required_snapshot_ids must be non-empty array")
        return 1
    for idx, snapshot_id in enumerate(required_snapshot_ids):
        if not isinstance(snapshot_id, str) or not snapshot_id:
            print(f"visual_snapshot_targets.json baseline_alignment.required_snapshot_ids[{idx}] must be non-empty string")
            return 1
        if snapshot_id not in snapshots:
            print(f"visual_snapshot_targets.json baseline_alignment.required_snapshot_ids[{idx}] must reference snapshots key")
            return 1
    if not isinstance(allowed_capture_modes, dict) or not allowed_capture_modes:
        print("visual_snapshot_targets.json baseline_alignment.allowed_capture_modes must be non-empty object")
        return 1
    for profile_name in required_backend_profiles:
        if profile_name not in allowed_capture_modes:
            print(f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes must include '{profile_name}'")
            return 1
    for backend_name, modes in allowed_capture_modes.items():
        if not isinstance(backend_name, str) or not backend_name:
            print("visual_snapshot_targets.json baseline_alignment.allowed_capture_modes key must be non-empty string")
            return 1
        if not isinstance(modes, list) or not modes:
            print(f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes.{backend_name} must be non-empty array")
            return 1
        for idx, mode in enumerate(modes):
            if not isinstance(mode, str) or not mode:
                print(f"visual_snapshot_targets.json baseline_alignment.allowed_capture_modes.{backend_name}[{idx}] must be non-empty string")
                return 1

    if not isinstance(diff_whitelist, dict):
        print("visual_snapshot_targets.json diff_whitelist must be object")
        return 1
    for backend_name, backend_rows in diff_whitelist.items():
        if not isinstance(backend_name, str) or not backend_name:
            print("visual_snapshot_targets.json diff_whitelist key must be non-empty string")
            return 1
        if not isinstance(backend_rows, dict):
            print(f"visual_snapshot_targets.json diff_whitelist.{backend_name} must be object")
            return 1
        for snapshot_id, row in backend_rows.items():
            if not isinstance(snapshot_id, str) or not snapshot_id:
                print(f"visual_snapshot_targets.json diff_whitelist.{backend_name} snapshot key must be non-empty string")
                return 1
            if snapshot_id not in snapshots:
                print(f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id} must reference snapshots key")
                return 1
            if not isinstance(row, dict) or not row:
                print(f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id} must be non-empty object")
                return 1
            reason = row.get("reason", "")
            if reason != "" and (not isinstance(reason, str) or not reason):
                print(f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id}.reason must be non-empty string")
                return 1
            for numeric_key in ("max_opaque_ratio_drop", "max_unique_color_drop_ratio", "max_luma_delta"):
                if numeric_key not in row:
                    continue
                value = row.get(numeric_key)
                if not isinstance(value, (int, float)) or value < 0.0 or value > 1.0:
                    print(f"visual_snapshot_targets.json diff_whitelist.{backend_name}.{snapshot_id}.{numeric_key} must be within [0.0, 1.0]")
                    return 1

    if not isinstance(whitelist_policy, dict) or not whitelist_policy:
        print("visual_snapshot_targets.json whitelist_policy must be non-empty object")
        return 1
    max_hits = whitelist_policy.get("max_hits")
    max_ratio = whitelist_policy.get("max_ratio")
    if not isinstance(max_hits, int) or max_hits < 0:
        print("visual_snapshot_targets.json whitelist_policy.max_hits must be int >= 0")
        return 1
    if not isinstance(max_ratio, (int, float)) or max_ratio < 0.0 or max_ratio > 1.0:
        print("visual_snapshot_targets.json whitelist_policy.max_ratio must be within [0.0, 1.0]")
        return 1

    if not isinstance(backend_attribution, dict) or not backend_attribution:
        print("visual_snapshot_targets.json backend_attribution must be non-empty object")
        return 1
    required_backends = backend_attribution.get("required_backends", [])
    max_unattributed_regressions = backend_attribution.get("max_unattributed_regressions")
    max_backend_specific_regressions = backend_attribution.get("max_backend_specific_regressions")
    if not isinstance(required_backends, list) or not required_backends:
        print("visual_snapshot_targets.json backend_attribution.required_backends must be non-empty array")
        return 1
    backend_set = set()
    for idx, backend_name in enumerate(required_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json backend_attribution.required_backends[{idx}] must be non-empty string")
            return 1
        backend_set.add(backend_name)
    for required_backend in ("linux_headless", "windows_headless"):
        if required_backend not in backend_set:
            print(f"visual_snapshot_targets.json backend_attribution.required_backends must include '{required_backend}'")
            return 1
    if not isinstance(max_unattributed_regressions, int) or max_unattributed_regressions < 0:
        print("visual_snapshot_targets.json backend_attribution.max_unattributed_regressions must be int >= 0")
        return 1
    if not isinstance(max_backend_specific_regressions, int) or max_backend_specific_regressions < 0:
        print("visual_snapshot_targets.json backend_attribution.max_backend_specific_regressions must be int >= 0")
        return 1

    if not isinstance(whitelist_convergence, dict) or not whitelist_convergence:
        print("visual_snapshot_targets.json whitelist_convergence must be non-empty object")
        return 1
    stale_run_threshold = whitelist_convergence.get("stale_run_threshold")
    tighten_margin_ratio = whitelist_convergence.get("tighten_margin_ratio")
    max_suggestions = whitelist_convergence.get("max_suggestions")
    if not isinstance(stale_run_threshold, int) or stale_run_threshold < 1:
        print("visual_snapshot_targets.json whitelist_convergence.stale_run_threshold must be int >= 1")
        return 1
    if not isinstance(tighten_margin_ratio, (int, float)) or tighten_margin_ratio < 0.0 or tighten_margin_ratio > 1.0:
        print("visual_snapshot_targets.json whitelist_convergence.tighten_margin_ratio must be within [0.0, 1.0]")
        return 1
    if not isinstance(max_suggestions, int) or max_suggestions < 0:
        print("visual_snapshot_targets.json whitelist_convergence.max_suggestions must be int >= 0")
        return 1

    if not isinstance(exception_lifecycle, dict) or not exception_lifecycle:
        print("visual_snapshot_targets.json exception_lifecycle must be non-empty object")
        return 1
    expire_idle_runs = exception_lifecycle.get("expire_idle_runs")
    auto_reclaim_hit_streak = exception_lifecycle.get("auto_reclaim_hit_streak")
    max_expired_entries = exception_lifecycle.get("max_expired_entries")
    max_reclaim_candidates = exception_lifecycle.get("max_reclaim_candidates")
    if not isinstance(expire_idle_runs, int) or expire_idle_runs < 1:
        print("visual_snapshot_targets.json exception_lifecycle.expire_idle_runs must be int >= 1")
        return 1
    if not isinstance(auto_reclaim_hit_streak, int) or auto_reclaim_hit_streak < 1:
        print("visual_snapshot_targets.json exception_lifecycle.auto_reclaim_hit_streak must be int >= 1")
        return 1
    if not isinstance(max_expired_entries, int) or max_expired_entries < 0:
        print("visual_snapshot_targets.json exception_lifecycle.max_expired_entries must be int >= 0")
        return 1
    if not isinstance(max_reclaim_candidates, int) or max_reclaim_candidates < 0:
        print("visual_snapshot_targets.json exception_lifecycle.max_reclaim_candidates must be int >= 0")
        return 1

    if not isinstance(strategy_orchestration, dict) or not strategy_orchestration:
        print("visual_snapshot_targets.json strategy_orchestration must be non-empty object")
        return 1
    default_strategy = strategy_orchestration.get("default_strategy")
    strategies = strategy_orchestration.get("strategies", {})
    templates = strategy_orchestration.get("templates", {})
    if not isinstance(default_strategy, str) or not default_strategy:
        print("visual_snapshot_targets.json strategy_orchestration.default_strategy must be non-empty string")
        return 1
    if not isinstance(strategies, dict) or not strategies:
        print("visual_snapshot_targets.json strategy_orchestration.strategies must be non-empty object")
        return 1
    if not isinstance(templates, dict) or not templates:
        print("visual_snapshot_targets.json strategy_orchestration.templates must be non-empty object")
        return 1
    if default_strategy not in strategies:
        print("visual_snapshot_targets.json strategy_orchestration.default_strategy must reference strategies key")
        return 1

    allowed_template_sections = {
        "thresholds",
        "whitelist_policy",
        "backend_attribution",
        "whitelist_convergence",
        "exception_lifecycle",
        "cross_version_baseline",
        "report_layers",
    }

    for strategy_name, strategy_row in strategies.items():
        if not isinstance(strategy_name, str) or not strategy_name:
            print("visual_snapshot_targets.json strategy_orchestration.strategies key must be non-empty string")
            return 1
        if not isinstance(strategy_row, dict) or not strategy_row:
            print(f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name} must be non-empty object")
            return 1
        template_name = strategy_row.get("template")
        if not isinstance(template_name, str) or not template_name:
            print(f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name}.template must be non-empty string")
            return 1
        if template_name not in templates:
            print(f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name}.template must reference templates key")
            return 1

    for template_name, template_row in templates.items():
        if not isinstance(template_name, str) or not template_name:
            print("visual_snapshot_targets.json strategy_orchestration.templates key must be non-empty string")
            return 1
        if not isinstance(template_row, dict) or not template_row:
            print(f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name} must be non-empty object")
            return 1
        for section_key, section_row in template_row.items():
            if section_key not in allowed_template_sections:
                print(f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name}.{section_key} is not a supported override section")
                return 1
            if not isinstance(section_row, dict) or not section_row:
                print(f"visual_snapshot_targets.json strategy_orchestration.templates.{template_name}.{section_key} must be non-empty object")
                return 1

    if not isinstance(release_gate_templates, dict) or not release_gate_templates:
        print("visual_snapshot_targets.json release_gate_templates must be non-empty object")
        return 1
    required_strategies = release_gate_templates.get("required_strategies", [])
    required_strategy_bindings = release_gate_templates.get("required_strategy_bindings", {})
    ci_mode_bindings = release_gate_templates.get("ci_mode_bindings", {})
    release_checklist = release_gate_templates.get("release_checklist", {})
    if not isinstance(required_strategies, list) or not required_strategies:
        print("visual_snapshot_targets.json release_gate_templates.required_strategies must be non-empty array")
        return 1
    for idx, strategy_name in enumerate(required_strategies):
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategies[{idx}] must be non-empty string")
            return 1
        if strategy_name not in strategies:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategies[{idx}] must reference strategy_orchestration.strategies")
            return 1

    if not isinstance(required_strategy_bindings, dict) or not required_strategy_bindings:
        print("visual_snapshot_targets.json release_gate_templates.required_strategy_bindings must be non-empty object")
        return 1
    for strategy_name in required_strategies:
        if strategy_name not in required_strategy_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings must include '{strategy_name}'")
            return 1

    for strategy_name, template_name in required_strategy_bindings.items():
        if not isinstance(strategy_name, str) or not strategy_name:
            print("visual_snapshot_targets.json release_gate_templates.required_strategy_bindings key must be non-empty string")
            return 1
        if not isinstance(template_name, str) or not template_name:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must be non-empty string")
            return 1
        if strategy_name not in strategies:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must reference strategy_orchestration.strategies")
            return 1
        strategy_row = strategies.get(strategy_name, {})
        if not isinstance(strategy_row, dict):
            print(f"visual_snapshot_targets.json strategy_orchestration.strategies.{strategy_name} must be object")
            return 1
        actual_template = strategy_row.get("template")
        if actual_template != template_name:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must match strategy_orchestration template")
            return 1
        if template_name not in templates:
            print(f"visual_snapshot_targets.json release_gate_templates.required_strategy_bindings.{strategy_name} must reference strategy_orchestration.templates")
            return 1

    if not isinstance(ci_mode_bindings, dict) or not ci_mode_bindings:
        print("visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must be non-empty object")
        return 1
    for mode_name, strategy_name in ci_mode_bindings.items():
        if not isinstance(mode_name, str) or not mode_name:
            print("visual_snapshot_targets.json release_gate_templates.ci_mode_bindings key must be non-empty string")
            return 1
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings.{mode_name} must be non-empty string")
            return 1
        if strategy_name not in strategies:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings.{mode_name} must reference strategy_orchestration.strategies")
            return 1

    if not isinstance(release_checklist, dict) or not release_checklist:
        print("visual_snapshot_targets.json release_gate_templates.release_checklist must be non-empty object")
        return 1
    required_reports = release_checklist.get("required_reports", [])
    required_strategies_for_publish = release_checklist.get("required_strategies_for_publish", [])
    require_zero_warnings_for = release_checklist.get("require_zero_warnings_for", [])
    max_checklist_failures = release_checklist.get("max_checklist_failures")

    if not isinstance(required_reports, list) or not required_reports:
        print("visual_snapshot_targets.json release_gate_templates.release_checklist.required_reports must be non-empty array")
        return 1
    for idx, report_path in enumerate(required_reports):
        if not isinstance(report_path, str) or not report_path or not report_path.startswith("user://"):
            print(f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_reports[{idx}] must be non-empty user:// path")
            return 1

    if not isinstance(required_strategies_for_publish, list) or not required_strategies_for_publish:
        print("visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish must be non-empty array")
        return 1
    for idx, strategy_name in enumerate(required_strategies_for_publish):
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish[{idx}] must be non-empty string")
            return 1
        if strategy_name not in required_strategies:
            print(f"visual_snapshot_targets.json release_gate_templates.release_checklist.required_strategies_for_publish[{idx}] must be listed in required_strategies")
            return 1

    if not isinstance(require_zero_warnings_for, list):
        print("visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for must be array")
        return 1
    for idx, strategy_name in enumerate(require_zero_warnings_for):
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for[{idx}] must be non-empty string")
            return 1
        if strategy_name not in required_strategies:
            print(f"visual_snapshot_targets.json release_gate_templates.release_checklist.require_zero_warnings_for[{idx}] must be listed in required_strategies")
            return 1

    if not isinstance(max_checklist_failures, int) or max_checklist_failures < 0:
        print("visual_snapshot_targets.json release_gate_templates.release_checklist.max_checklist_failures must be int >= 0")
        return 1

    if not isinstance(backend_matrix_governance, dict) or not backend_matrix_governance:
        print("visual_snapshot_targets.json backend_matrix_governance must be non-empty object")
        return 1
    required_backend_matrix = backend_matrix_governance.get("required_backend_matrix", [])
    required_run_modes = backend_matrix_governance.get("required_run_modes", [])
    max_missing_backend_matrix = backend_matrix_governance.get("max_missing_backend_matrix")
    max_missing_run_mode_bindings = backend_matrix_governance.get("max_missing_run_mode_bindings")
    if not isinstance(required_backend_matrix, list) or not required_backend_matrix:
        print("visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must be non-empty array")
        return 1
    backend_matrix_set = set()
    for idx, backend_name in enumerate(required_backend_matrix):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix[{idx}] must be non-empty string")
            return 1
        backend_matrix_set.add(backend_name)
    for required_backend in ("linux_headless", "windows_headless"):
        if required_backend not in backend_matrix_set:
            print(f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{required_backend}'")
            return 1
    if not isinstance(required_run_modes, list) or not required_run_modes:
        print("visual_snapshot_targets.json backend_matrix_governance.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(required_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json backend_matrix_governance.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for backend_matrix_governance")
            return 1
    if not isinstance(max_missing_backend_matrix, int) or max_missing_backend_matrix < 0:
        print("visual_snapshot_targets.json backend_matrix_governance.max_missing_backend_matrix must be int >= 0")
        return 1
    if not isinstance(max_missing_run_mode_bindings, int) or max_missing_run_mode_bindings < 0:
        print("visual_snapshot_targets.json backend_matrix_governance.max_missing_run_mode_bindings must be int >= 0")
        return 1

    if not isinstance(approval_workflow, dict) or not approval_workflow:
        print("visual_snapshot_targets.json approval_workflow must be non-empty object")
        return 1
    required_report_sections = approval_workflow.get("required_report_sections", [])
    require_zero_blockers = approval_workflow.get("require_zero_blockers")
    require_zero_warnings_for_strategies = approval_workflow.get("require_zero_warnings_for_strategies", [])
    max_approval_failures = approval_workflow.get("max_approval_failures")
    allowed_sections = {
        "Snapshots",
        "Trend",
        "Whitelist",
        "Backend Attribution",
        "Release Manifest",
        "Backend Matrix Governance",
        "Approval Workflow",
        "Approval Audit Trail",
        "Approval History Archive",
        "Approval Template",
        "Release Candidate Tracking",
        "Stability Scoring",
        "Convergence Dashboard",
        "CI Signal Contract",
        "Convergence Trend Reinforcement",
        "Exception Lifecycle Linkage",
        "Visual-Performance Co-Gate",
        "Co-Gate Threshold Template",
        "Cross-Platform Alignment",
        "Pressure Scenario Standardization",
        "Alignment Dashboard Refinement",
        "Pressure Alignment Convergence Gate",
        "Regression Cycle Window Governance",
        "Multi-Cycle Adaptive Gate",
        "Release Feedback Governance",
    }
    if not isinstance(required_report_sections, list) or not required_report_sections:
        print("visual_snapshot_targets.json approval_workflow.required_report_sections must be non-empty array")
        return 1
    for idx, section_name in enumerate(required_report_sections):
        if not isinstance(section_name, str) or not section_name:
            print(f"visual_snapshot_targets.json approval_workflow.required_report_sections[{idx}] must be non-empty string")
            return 1
        if section_name not in allowed_sections:
            print(f"visual_snapshot_targets.json approval_workflow.required_report_sections[{idx}] is not supported")
            return 1
    if not isinstance(require_zero_blockers, bool):
        print("visual_snapshot_targets.json approval_workflow.require_zero_blockers must be bool")
        return 1
    if not isinstance(require_zero_warnings_for_strategies, list):
        print("visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies must be array")
        return 1
    for idx, strategy_name in enumerate(require_zero_warnings_for_strategies):
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies[{idx}] must be non-empty string")
            return 1
        if strategy_name not in required_strategies:
            print(f"visual_snapshot_targets.json approval_workflow.require_zero_warnings_for_strategies[{idx}] must be listed in release_gate_templates.required_strategies")
            return 1
    if not isinstance(max_approval_failures, int) or max_approval_failures < 0:
        print("visual_snapshot_targets.json approval_workflow.max_approval_failures must be int >= 0")
        return 1

    if not isinstance(approval_audit_trail, dict) or not approval_audit_trail:
        print("visual_snapshot_targets.json approval_audit_trail must be non-empty object")
        return 1
    history_file = approval_audit_trail.get("history_file")
    max_entries = approval_audit_trail.get("max_entries")
    required_audit_run_modes = approval_audit_trail.get("required_run_modes", [])
    required_audit_backends = approval_audit_trail.get("required_backends", [])
    require_unique_pipeline_id = approval_audit_trail.get("require_unique_pipeline_id")
    max_missing_pipeline_id = approval_audit_trail.get("max_missing_pipeline_id")
    max_history_trace_failures = approval_audit_trail.get("max_history_trace_failures")

    if not isinstance(history_file, str) or not history_file.startswith("user://"):
        print("visual_snapshot_targets.json approval_audit_trail.history_file must be non-empty user:// path")
        return 1
    if not isinstance(max_entries, int) or max_entries < 10:
        print("visual_snapshot_targets.json approval_audit_trail.max_entries must be int >= 10")
        return 1
    if not isinstance(required_audit_run_modes, list) or not required_audit_run_modes:
        print("visual_snapshot_targets.json approval_audit_trail.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(required_audit_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json approval_audit_trail.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_audit_trail")
            return 1

    if not isinstance(required_audit_backends, list) or not required_audit_backends:
        print("visual_snapshot_targets.json approval_audit_trail.required_backends must be non-empty array")
        return 1
    backend_set = set()
    for idx, backend_name in enumerate(required_audit_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json approval_audit_trail.required_backends[{idx}] must be non-empty string")
            return 1
        backend_set.add(backend_name)
    for required_backend in ("linux_headless", "windows_headless"):
        if required_backend not in backend_set:
            print(f"visual_snapshot_targets.json approval_audit_trail.required_backends must include '{required_backend}'")
            return 1
        if required_backend not in backend_matrix_set:
            print(f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{required_backend}' for approval_audit_trail")
            return 1

    if not isinstance(require_unique_pipeline_id, bool):
        print("visual_snapshot_targets.json approval_audit_trail.require_unique_pipeline_id must be bool")
        return 1
    if not isinstance(max_missing_pipeline_id, int) or max_missing_pipeline_id < 0:
        print("visual_snapshot_targets.json approval_audit_trail.max_missing_pipeline_id must be int >= 0")
        return 1
    if not isinstance(max_history_trace_failures, int) or max_history_trace_failures < 0:
        print("visual_snapshot_targets.json approval_audit_trail.max_history_trace_failures must be int >= 0")
        return 1

    if not isinstance(approval_history_archive, dict) or not approval_history_archive:
        print("visual_snapshot_targets.json approval_history_archive must be non-empty object")
        return 1
    archive_file = approval_history_archive.get("archive_file")
    archive_max_entries = approval_history_archive.get("max_entries")
    aggregation_window = approval_history_archive.get("aggregation_window")
    required_archive_run_modes = approval_history_archive.get("required_run_modes", [])
    required_archive_backends = approval_history_archive.get("required_backends", [])
    max_missing_archive_backends = approval_history_archive.get("max_missing_archive_backends")
    max_missing_archive_run_modes = approval_history_archive.get("max_missing_archive_run_modes")
    max_backend_warning_delta = approval_history_archive.get("max_backend_warning_delta")
    max_backend_blocker_delta = approval_history_archive.get("max_backend_blocker_delta")
    max_archive_trace_failures = approval_history_archive.get("max_archive_trace_failures")

    if not isinstance(archive_file, str) or not archive_file.startswith("user://"):
        print("visual_snapshot_targets.json approval_history_archive.archive_file must be non-empty user:// path")
        return 1
    if not isinstance(archive_max_entries, int) or archive_max_entries < 20:
        print("visual_snapshot_targets.json approval_history_archive.max_entries must be int >= 20")
        return 1
    if not isinstance(aggregation_window, int) or aggregation_window < 10:
        print("visual_snapshot_targets.json approval_history_archive.aggregation_window must be int >= 10")
        return 1

    if not isinstance(required_archive_run_modes, list) or not required_archive_run_modes:
        print("visual_snapshot_targets.json approval_history_archive.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(required_archive_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json approval_history_archive.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_history_archive")
            return 1

    if not isinstance(required_archive_backends, list) or not required_archive_backends:
        print("visual_snapshot_targets.json approval_history_archive.required_backends must be non-empty array")
        return 1
    archive_backend_set = set()
    for idx, backend_name in enumerate(required_archive_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json approval_history_archive.required_backends[{idx}] must be non-empty string")
            return 1
        archive_backend_set.add(backend_name)
        if backend_name not in backend_matrix_set:
            print(f"visual_snapshot_targets.json backend_matrix_governance.required_backend_matrix must include '{backend_name}' for approval_history_archive")
            return 1
    for required_backend in ("linux_headless", "windows_headless"):
        if required_backend not in archive_backend_set:
            print(f"visual_snapshot_targets.json approval_history_archive.required_backends must include '{required_backend}'")
            return 1

    if not isinstance(max_missing_archive_backends, int) or max_missing_archive_backends < 0:
        print("visual_snapshot_targets.json approval_history_archive.max_missing_archive_backends must be int >= 0")
        return 1
    if not isinstance(max_missing_archive_run_modes, int) or max_missing_archive_run_modes < 0:
        print("visual_snapshot_targets.json approval_history_archive.max_missing_archive_run_modes must be int >= 0")
        return 1
    if not isinstance(max_backend_warning_delta, int) or max_backend_warning_delta < 0:
        print("visual_snapshot_targets.json approval_history_archive.max_backend_warning_delta must be int >= 0")
        return 1
    if not isinstance(max_backend_blocker_delta, int) or max_backend_blocker_delta < 0:
        print("visual_snapshot_targets.json approval_history_archive.max_backend_blocker_delta must be int >= 0")
        return 1
    if not isinstance(max_archive_trace_failures, int) or max_archive_trace_failures < 0:
        print("visual_snapshot_targets.json approval_history_archive.max_archive_trace_failures must be int >= 0")
        return 1

    if not isinstance(approval_threshold_templates, dict) or not approval_threshold_templates:
        print("visual_snapshot_targets.json approval_threshold_templates must be non-empty object")
        return 1
    default_template = approval_threshold_templates.get("default_template")
    run_mode_templates = approval_threshold_templates.get("run_mode_templates", {})
    template_rows = approval_threshold_templates.get("templates", {})
    if not isinstance(default_template, str) or not default_template:
        print("visual_snapshot_targets.json approval_threshold_templates.default_template must be non-empty string")
        return 1
    if not isinstance(run_mode_templates, dict) or not run_mode_templates:
        print("visual_snapshot_targets.json approval_threshold_templates.run_mode_templates must be non-empty object")
        return 1
    if not isinstance(template_rows, dict) or not template_rows:
        print("visual_snapshot_targets.json approval_threshold_templates.templates must be non-empty object")
        return 1
    if default_template not in template_rows:
        print("visual_snapshot_targets.json approval_threshold_templates.default_template must reference templates key")
        return 1

    allowed_approval_template_sections = {"approval_workflow", "approval_audit_trail", "approval_history_archive"}
    for mode_name, template_name in run_mode_templates.items():
        if not isinstance(mode_name, str) or not mode_name:
            print("visual_snapshot_targets.json approval_threshold_templates.run_mode_templates key must be non-empty string")
            return 1
        if not isinstance(template_name, str) or not template_name:
            print(f"visual_snapshot_targets.json approval_threshold_templates.run_mode_templates.{mode_name} must be non-empty string")
            return 1
        if template_name not in template_rows:
            print(f"visual_snapshot_targets.json approval_threshold_templates.run_mode_templates.{mode_name} must reference templates key")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for approval_threshold_templates")
            return 1

    for template_name, template_row in template_rows.items():
        if not isinstance(template_name, str) or not template_name:
            print("visual_snapshot_targets.json approval_threshold_templates.templates key must be non-empty string")
            return 1
        if not isinstance(template_row, dict) or not template_row:
            print(f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name} must be non-empty object")
            return 1
        for section_name, section_row in template_row.items():
            if section_name not in allowed_approval_template_sections:
                print(f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name}.{section_name} is not a supported override section")
                return 1
            if not isinstance(section_row, dict) or not section_row:
                print(f"visual_snapshot_targets.json approval_threshold_templates.templates.{template_name}.{section_name} must be non-empty object")
                return 1

    if not isinstance(release_candidate_tracking, dict) or not release_candidate_tracking:
        print("visual_snapshot_targets.json release_candidate_tracking must be non-empty object")
        return 1
    tracking_history_file = release_candidate_tracking.get("history_file")
    tracking_window = release_candidate_tracking.get("window")
    tracking_run_modes = release_candidate_tracking.get("required_run_modes", [])
    tracking_strategies = release_candidate_tracking.get("required_strategies", [])
    tracking_min_runs = release_candidate_tracking.get("min_runs")
    tracking_max_avg_warnings = release_candidate_tracking.get("max_avg_warnings")
    tracking_max_total_blockers = release_candidate_tracking.get("max_total_blockers")
    tracking_max_failures = release_candidate_tracking.get("max_tracking_failures")

    if not isinstance(tracking_history_file, str) or not tracking_history_file.startswith("user://"):
        print("visual_snapshot_targets.json release_candidate_tracking.history_file must be non-empty user:// path")
        return 1
    if not isinstance(tracking_window, int) or tracking_window < 5:
        print("visual_snapshot_targets.json release_candidate_tracking.window must be int >= 5")
        return 1
    if not isinstance(tracking_run_modes, list) or not tracking_run_modes:
        print("visual_snapshot_targets.json release_candidate_tracking.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(tracking_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json release_candidate_tracking.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for release_candidate_tracking")
            return 1

    if not isinstance(tracking_strategies, list) or not tracking_strategies:
        print("visual_snapshot_targets.json release_candidate_tracking.required_strategies must be non-empty array")
        return 1
    for idx, strategy_name in enumerate(tracking_strategies):
        if not isinstance(strategy_name, str) or not strategy_name:
            print(f"visual_snapshot_targets.json release_candidate_tracking.required_strategies[{idx}] must be non-empty string")
            return 1
        if strategy_name not in required_strategies:
            print(f"visual_snapshot_targets.json release_candidate_tracking.required_strategies[{idx}] must be listed in release_gate_templates.required_strategies")
            return 1

    if not isinstance(tracking_min_runs, int) or tracking_min_runs < 1:
        print("visual_snapshot_targets.json release_candidate_tracking.min_runs must be int >= 1")
        return 1
    if not isinstance(tracking_max_avg_warnings, (int, float)) or tracking_max_avg_warnings < 0.0:
        print("visual_snapshot_targets.json release_candidate_tracking.max_avg_warnings must be float >= 0.0")
        return 1
    if not isinstance(tracking_max_total_blockers, int) or tracking_max_total_blockers < 0:
        print("visual_snapshot_targets.json release_candidate_tracking.max_total_blockers must be int >= 0")
        return 1
    if not isinstance(tracking_max_failures, int) or tracking_max_failures < 0:
        print("visual_snapshot_targets.json release_candidate_tracking.max_tracking_failures must be int >= 0")
        return 1

    if not isinstance(stability_scoring, dict) or not stability_scoring:
        print("visual_snapshot_targets.json stability_scoring must be non-empty object")
        return 1
    scoring_weights = stability_scoring.get("weights", {})
    scoring_caps = stability_scoring.get("failure_caps", {})
    scoring_confidence = stability_scoring.get("confidence", {})
    score_round_digits = stability_scoring.get("score_round_digits")
    if not isinstance(scoring_weights, dict) or not scoring_weights:
        print("visual_snapshot_targets.json stability_scoring.weights must be non-empty object")
        return 1
    weight_sum = 0.0
    for key in ("matching_runs", "avg_warnings", "total_blockers", "tracking_failures"):
        value = scoring_weights.get(key)
        if not isinstance(value, (int, float)) or value < 0.0 or value > 1.0:
            print(f"visual_snapshot_targets.json stability_scoring.weights.{key} must be within [0.0, 1.0]")
            return 1
        weight_sum += float(value)
    if weight_sum <= 0.0:
        print("visual_snapshot_targets.json stability_scoring.weights sum must be > 0")
        return 1

    if not isinstance(scoring_caps, dict) or not scoring_caps:
        print("visual_snapshot_targets.json stability_scoring.failure_caps must be non-empty object")
        return 1
    max_avg_warnings_cap = scoring_caps.get("max_avg_warnings")
    max_total_blockers_cap = scoring_caps.get("max_total_blockers")
    max_tracking_failures_cap = scoring_caps.get("max_tracking_failures")
    if not isinstance(max_avg_warnings_cap, (int, float)) or max_avg_warnings_cap <= 0.0:
        print("visual_snapshot_targets.json stability_scoring.failure_caps.max_avg_warnings must be float > 0.0")
        return 1
    if not isinstance(max_total_blockers_cap, int) or max_total_blockers_cap < 0:
        print("visual_snapshot_targets.json stability_scoring.failure_caps.max_total_blockers must be int >= 0")
        return 1
    if not isinstance(max_tracking_failures_cap, int) or max_tracking_failures_cap < 0:
        print("visual_snapshot_targets.json stability_scoring.failure_caps.max_tracking_failures must be int >= 0")
        return 1

    if not isinstance(scoring_confidence, dict) or not scoring_confidence:
        print("visual_snapshot_targets.json stability_scoring.confidence must be non-empty object")
        return 1
    reference_runs = scoring_confidence.get("reference_runs")
    min_confidence = scoring_confidence.get("min_confidence")
    if not isinstance(reference_runs, int) or reference_runs < 1:
        print("visual_snapshot_targets.json stability_scoring.confidence.reference_runs must be int >= 1")
        return 1
    if not isinstance(min_confidence, (int, float)) or min_confidence < 0.0 or min_confidence > 1.0:
        print("visual_snapshot_targets.json stability_scoring.confidence.min_confidence must be within [0.0, 1.0]")
        return 1

    if not isinstance(score_round_digits, int) or score_round_digits < 0 or score_round_digits > 5:
        print("visual_snapshot_targets.json stability_scoring.score_round_digits must be int within [0, 5]")
        return 1

    if not isinstance(stability_tiers, dict) or not stability_tiers:
        print("visual_snapshot_targets.json stability_tiers must be non-empty object")
        return 1
    default_tier = stability_tiers.get("default_tier")
    tiers = stability_tiers.get("tiers", [])
    if not isinstance(default_tier, str) or not default_tier:
        print("visual_snapshot_targets.json stability_tiers.default_tier must be non-empty string")
        return 1
    if not isinstance(tiers, list) or not tiers:
        print("visual_snapshot_targets.json stability_tiers.tiers must be non-empty array")
        return 1
    tier_names = set()
    for idx, tier_row in enumerate(tiers):
        if not isinstance(tier_row, dict) or not tier_row:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}] must be non-empty object")
            return 1
        tier_name = tier_row.get("name")
        tier_min_score = tier_row.get("min_score")
        tier_max_avg_warnings = tier_row.get("max_avg_warnings")
        tier_max_total_blockers = tier_row.get("max_total_blockers")
        tier_max_tracking_failures = tier_row.get("max_tracking_failures")
        tier_min_confidence = tier_row.get("min_confidence")
        if not isinstance(tier_name, str) or not tier_name:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].name must be non-empty string")
            return 1
        if tier_name in tier_names:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].name must be unique ({tier_name})")
            return 1
        tier_names.add(tier_name)
        if not isinstance(tier_min_score, (int, float)) or tier_min_score < 0.0 or tier_min_score > 100.0:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].min_score must be within [0.0, 100.0]")
            return 1
        if not isinstance(tier_max_avg_warnings, (int, float)) or tier_max_avg_warnings < 0.0:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_avg_warnings must be float >= 0.0")
            return 1
        if not isinstance(tier_max_total_blockers, int) or tier_max_total_blockers < 0:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_total_blockers must be int >= 0")
            return 1
        if not isinstance(tier_max_tracking_failures, int) or tier_max_tracking_failures < 0:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].max_tracking_failures must be int >= 0")
            return 1
        if not isinstance(tier_min_confidence, (int, float)) or tier_min_confidence < 0.0 or tier_min_confidence > 1.0:
            print(f"visual_snapshot_targets.json stability_tiers.tiers[{idx}].min_confidence must be within [0.0, 1.0]")
            return 1
    if default_tier not in tier_names:
        print("visual_snapshot_targets.json stability_tiers.default_tier must reference tiers.name")
        return 1

    if not isinstance(convergence_dashboard, dict) or not convergence_dashboard:
        print("visual_snapshot_targets.json convergence_dashboard must be non-empty object")
        return 1
    for key in (
        "max_approval_failures",
        "max_tracking_failures",
        "max_trace_failures",
        "max_manifest_failures",
        "max_blockers",
        "max_warnings",
        "max_dashboard_failures",
    ):
        value = convergence_dashboard.get(key)
        if not isinstance(value, int) or value < 0:
            print(f"visual_snapshot_targets.json convergence_dashboard.{key} must be int >= 0")
            return 1

    if not isinstance(ci_signal_contract, dict) or not ci_signal_contract:
        print("visual_snapshot_targets.json ci_signal_contract must be non-empty object")
        return 1
    required_fields = ci_signal_contract.get("required_fields", [])
    tier_requirements = ci_signal_contract.get("tier_requirements", {})
    max_contract_failures = ci_signal_contract.get("max_contract_failures")
    if not isinstance(required_fields, list) or not required_fields:
        print("visual_snapshot_targets.json ci_signal_contract.required_fields must be non-empty array")
        return 1
    for idx, field_name in enumerate(required_fields):
        if not isinstance(field_name, str) or not field_name:
            print(f"visual_snapshot_targets.json ci_signal_contract.required_fields[{idx}] must be non-empty string")
            return 1
    if not isinstance(tier_requirements, dict) or not tier_requirements:
        print("visual_snapshot_targets.json ci_signal_contract.tier_requirements must be non-empty object")
        return 1
    for mode_name, tier_name in tier_requirements.items():
        if not isinstance(mode_name, str) or not mode_name:
            print("visual_snapshot_targets.json ci_signal_contract.tier_requirements key must be non-empty string")
            return 1
        if not isinstance(tier_name, str) or not tier_name:
            print(f"visual_snapshot_targets.json ci_signal_contract.tier_requirements.{mode_name} must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for ci_signal_contract")
            return 1
        if tier_name not in tier_names:
            print(f"visual_snapshot_targets.json ci_signal_contract.tier_requirements.{mode_name} must reference stability_tiers.tiers.name")
            return 1
    if not isinstance(max_contract_failures, int) or max_contract_failures < 0:
        print("visual_snapshot_targets.json ci_signal_contract.max_contract_failures must be int >= 0")
        return 1

    if not isinstance(convergence_trend_reinforcement, dict) or not convergence_trend_reinforcement:
        print("visual_snapshot_targets.json convergence_trend_reinforcement must be non-empty object")
        return 1
    trend_history_file = convergence_trend_reinforcement.get("history_file")
    trend_long_window = convergence_trend_reinforcement.get("long_window")
    trend_short_window = convergence_trend_reinforcement.get("short_window")
    trend_min_samples = convergence_trend_reinforcement.get("min_samples")
    trend_required_metrics = convergence_trend_reinforcement.get("required_metrics", [])
    trend_max_worsening_metrics = convergence_trend_reinforcement.get("max_worsening_metrics")
    trend_max_worsening_delta = convergence_trend_reinforcement.get("max_worsening_delta")
    trend_min_improving_metrics = convergence_trend_reinforcement.get("min_improving_metrics")
    trend_min_improvement_delta = convergence_trend_reinforcement.get("min_improvement_delta")
    trend_max_trend_failures = convergence_trend_reinforcement.get("max_trend_failures")

    if not isinstance(trend_history_file, str) or not trend_history_file.startswith("user://"):
        print("visual_snapshot_targets.json convergence_trend_reinforcement.history_file must be non-empty user:// path")
        return 1
    if isinstance(archive_file, str) and archive_file and trend_history_file != archive_file:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.history_file must match approval_history_archive.archive_file")
        return 1
    if not isinstance(trend_long_window, int) or trend_long_window < 5:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.long_window must be int >= 5")
        return 1
    if not isinstance(trend_short_window, int) or trend_short_window < 3:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.short_window must be int >= 3")
        return 1
    if trend_short_window > trend_long_window:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.short_window cannot exceed long_window")
        return 1
    if not isinstance(trend_min_samples, int) or trend_min_samples < 1:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.min_samples must be int >= 1")
        return 1
    if trend_min_samples > trend_short_window:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.min_samples cannot exceed short_window")
        return 1
    if not isinstance(trend_required_metrics, list) or not trend_required_metrics:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics must be non-empty array")
        return 1
    allowed_trend_metrics = {
        "warnings",
        "blockers",
        "approval_failures",
        "tracking_failures",
        "dashboard_failures",
        "contract_failures",
        "stability_score",
    }
    for idx, metric_name in enumerate(trend_required_metrics):
        if not isinstance(metric_name, str) or not metric_name:
            print(f"visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics[{idx}] must be non-empty string")
            return 1
        if metric_name not in allowed_trend_metrics:
            print(f"visual_snapshot_targets.json convergence_trend_reinforcement.required_metrics[{idx}] is not supported")
            return 1

    if not isinstance(trend_max_worsening_metrics, int) or trend_max_worsening_metrics < 0:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_metrics must be int >= 0")
        return 1
    if trend_max_worsening_metrics > len(trend_required_metrics):
        print("visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_metrics cannot exceed required_metrics size")
        return 1
    if not isinstance(trend_max_worsening_delta, (int, float)) or float(trend_max_worsening_delta) < 0.0:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.max_worsening_delta must be float >= 0.0")
        return 1
    if not isinstance(trend_min_improving_metrics, int) or trend_min_improving_metrics < 0:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.min_improving_metrics must be int >= 0")
        return 1
    if trend_min_improving_metrics > len(trend_required_metrics):
        print("visual_snapshot_targets.json convergence_trend_reinforcement.min_improving_metrics cannot exceed required_metrics size")
        return 1
    if not isinstance(trend_min_improvement_delta, (int, float)) or float(trend_min_improvement_delta) < 0.0:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.min_improvement_delta must be float >= 0.0")
        return 1
    if not isinstance(trend_max_trend_failures, int) or trend_max_trend_failures < 0:
        print("visual_snapshot_targets.json convergence_trend_reinforcement.max_trend_failures must be int >= 0")
        return 1

    if not isinstance(exception_lifecycle_linkage, dict) or not exception_lifecycle_linkage:
        print("visual_snapshot_targets.json exception_lifecycle_linkage must be non-empty object")
        return 1
    linkage_required_states = exception_lifecycle_linkage.get("required_states", [])
    linkage_stale_idle_runs = exception_lifecycle_linkage.get("stale_idle_runs")
    linkage_min_transition_count = exception_lifecycle_linkage.get("min_transition_count")
    linkage_max_orphan_entries = exception_lifecycle_linkage.get("max_orphan_entries")
    linkage_max_unlinked_reclaims = exception_lifecycle_linkage.get("max_unlinked_reclaims")
    linkage_max_unlinked_expired = exception_lifecycle_linkage.get("max_unlinked_expired")
    linkage_max_linkage_failures = exception_lifecycle_linkage.get("max_linkage_failures")

    if not isinstance(linkage_required_states, list):
        print("visual_snapshot_targets.json exception_lifecycle_linkage.required_states must be array")
        return 1
    allowed_lifecycle_states = {"active", "stale", "reclaim_candidate", "expired"}
    for idx, state_name in enumerate(linkage_required_states):
        if not isinstance(state_name, str) or not state_name:
            print(f"visual_snapshot_targets.json exception_lifecycle_linkage.required_states[{idx}] must be non-empty string")
            return 1
        if state_name not in allowed_lifecycle_states:
            print(f"visual_snapshot_targets.json exception_lifecycle_linkage.required_states[{idx}] is not supported")
            return 1
    if not isinstance(linkage_stale_idle_runs, int) or linkage_stale_idle_runs < 1:
        print("visual_snapshot_targets.json exception_lifecycle_linkage.stale_idle_runs must be int >= 1")
        return 1
    if isinstance(expire_idle_runs, int) and linkage_stale_idle_runs >= expire_idle_runs:
        print("visual_snapshot_targets.json exception_lifecycle_linkage.stale_idle_runs must be < exception_lifecycle.expire_idle_runs")
        return 1
    if not isinstance(linkage_min_transition_count, int) or linkage_min_transition_count < 0:
        print("visual_snapshot_targets.json exception_lifecycle_linkage.min_transition_count must be int >= 0")
        return 1
    if isinstance(max_expired_entries, int) and isinstance(max_reclaim_candidates, int):
        if linkage_min_transition_count > (max_expired_entries + max_reclaim_candidates):
            print("visual_snapshot_targets.json exception_lifecycle_linkage.min_transition_count cannot exceed exception_lifecycle capacity")
            return 1
    for key_name, key_value in (
        ("max_orphan_entries", linkage_max_orphan_entries),
        ("max_unlinked_reclaims", linkage_max_unlinked_reclaims),
        ("max_unlinked_expired", linkage_max_unlinked_expired),
        ("max_linkage_failures", linkage_max_linkage_failures),
    ):
        if not isinstance(key_value, int) or key_value < 0:
            print(f"visual_snapshot_targets.json exception_lifecycle_linkage.{key_name} must be int >= 0")
            return 1

    if not isinstance(visual_performance_cogate, dict) or not visual_performance_cogate:
        print("visual_snapshot_targets.json visual_performance_cogate must be non-empty object")
        return 1
    cogate_baseline_report = visual_performance_cogate.get("baseline_report")
    cogate_required_run_modes = visual_performance_cogate.get("required_run_modes", [])
    cogate_max_alert_total = visual_performance_cogate.get("max_alert_total")
    cogate_max_alert_critical = visual_performance_cogate.get("max_alert_critical")
    cogate_max_alert_warning = visual_performance_cogate.get("max_alert_warning")
    cogate_max_scenario_failures = visual_performance_cogate.get("max_scenario_failures")
    cogate_required_scenarios = visual_performance_cogate.get("required_scenarios", [])
    cogate_max_frame_ms_ratio = visual_performance_cogate.get("max_frame_ms_ratio")
    cogate_max_memory_mb_ratio = visual_performance_cogate.get("max_memory_mb_ratio")
    cogate_max_failures = visual_performance_cogate.get("max_cogate_failures")

    if not isinstance(cogate_baseline_report, str) or not cogate_baseline_report.startswith("user://"):
        print("visual_snapshot_targets.json visual_performance_cogate.baseline_report must be non-empty user:// path")
        return 1
    if isinstance(required_reports, list) and cogate_baseline_report not in required_reports:
        print("visual_snapshot_targets.json visual_performance_cogate.baseline_report must be listed in release_gate_templates.release_checklist.required_reports")
        return 1

    if not isinstance(cogate_required_run_modes, list) or not cogate_required_run_modes:
        print("visual_snapshot_targets.json visual_performance_cogate.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(cogate_required_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json visual_performance_cogate.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for visual_performance_cogate")
            return 1

    if not isinstance(cogate_max_alert_total, int) or cogate_max_alert_total < 0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_alert_total must be int >= 0")
        return 1
    if not isinstance(cogate_max_alert_critical, int) or cogate_max_alert_critical < 0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_alert_critical must be int >= 0")
        return 1
    if not isinstance(cogate_max_alert_warning, int) or cogate_max_alert_warning < 0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_alert_warning must be int >= 0")
        return 1
    if not isinstance(cogate_max_scenario_failures, int) or cogate_max_scenario_failures < 0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_scenario_failures must be int >= 0")
        return 1

    if not isinstance(cogate_required_scenarios, list):
        print("visual_snapshot_targets.json visual_performance_cogate.required_scenarios must be array")
        return 1
    for idx, scenario_id in enumerate(cogate_required_scenarios):
        if not isinstance(scenario_id, str) or not scenario_id:
            print(f"visual_snapshot_targets.json visual_performance_cogate.required_scenarios[{idx}] must be non-empty string")
            return 1

    if not isinstance(cogate_max_frame_ms_ratio, (int, float)) or float(cogate_max_frame_ms_ratio) < 1.0 or float(cogate_max_frame_ms_ratio) > 3.0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_frame_ms_ratio must be within [1.0, 3.0]")
        return 1
    if not isinstance(cogate_max_memory_mb_ratio, (int, float)) or float(cogate_max_memory_mb_ratio) < 1.0 or float(cogate_max_memory_mb_ratio) > 3.0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_memory_mb_ratio must be within [1.0, 3.0]")
        return 1
    if not isinstance(cogate_max_failures, int) or cogate_max_failures < 0:
        print("visual_snapshot_targets.json visual_performance_cogate.max_cogate_failures must be int >= 0")
        return 1

    if not isinstance(cogate_threshold_templates, dict) or not cogate_threshold_templates:
        print("visual_snapshot_targets.json cogate_threshold_templates must be non-empty object")
        return 1
    cogate_default_template = cogate_threshold_templates.get("default_template")
    cogate_run_mode_templates = cogate_threshold_templates.get("run_mode_templates", {})
    cogate_templates = cogate_threshold_templates.get("templates", {})
    if not isinstance(cogate_default_template, str) or not cogate_default_template:
        print("visual_snapshot_targets.json cogate_threshold_templates.default_template must be non-empty string")
        return 1
    if not isinstance(cogate_templates, dict) or not cogate_templates:
        print("visual_snapshot_targets.json cogate_threshold_templates.templates must be non-empty object")
        return 1
    if cogate_default_template not in cogate_templates:
        print("visual_snapshot_targets.json cogate_threshold_templates.default_template must exist in templates")
        return 1
    for template_name, template_row in cogate_templates.items():
        if not isinstance(template_name, str) or not template_name:
            print("visual_snapshot_targets.json cogate_threshold_templates.templates key must be non-empty string")
            return 1
        if not isinstance(template_row, dict) or not template_row:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name} must be non-empty object")
            return 1
        for key in (
            "max_alert_total",
            "max_alert_critical",
            "max_alert_warning",
            "max_scenario_failures",
            "max_cogate_failures",
        ):
            value = template_row.get(key)
            if not isinstance(value, int) or value < 0:
                print(f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.{key} must be int >= 0")
                return 1
        frame_ratio = template_row.get("max_frame_ms_ratio")
        memory_ratio = template_row.get("max_memory_mb_ratio")
        if not isinstance(frame_ratio, (int, float)) or float(frame_ratio) < 1.0 or float(frame_ratio) > 3.0:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.max_frame_ms_ratio must be within [1.0, 3.0]")
            return 1
        if not isinstance(memory_ratio, (int, float)) or float(memory_ratio) < 1.0 or float(memory_ratio) > 3.0:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.templates.{template_name}.max_memory_mb_ratio must be within [1.0, 3.0]")
            return 1

    if not isinstance(cogate_run_mode_templates, dict) or not cogate_run_mode_templates:
        print("visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates must be non-empty object")
        return 1
    for mode_name, template_name in cogate_run_mode_templates.items():
        if not isinstance(mode_name, str) or not mode_name:
            print("visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates key must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for cogate_threshold_templates")
            return 1
        if not isinstance(template_name, str) or not template_name:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates.{mode_name} must be non-empty string")
            return 1
        if template_name not in cogate_templates:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates.{mode_name} must reference templates key")
            return 1
    for mode_name in cogate_required_run_modes:
        if mode_name not in cogate_run_mode_templates:
            print(f"visual_snapshot_targets.json cogate_threshold_templates.run_mode_templates must include '{mode_name}' from visual_performance_cogate.required_run_modes")
            return 1

    if not isinstance(cross_platform_alignment, dict) or not cross_platform_alignment:
        print("visual_snapshot_targets.json cross_platform_alignment must be non-empty object")
        return 1
    alignment_history_file = cross_platform_alignment.get("history_file")
    alignment_window = cross_platform_alignment.get("aggregation_window")
    alignment_run_modes = cross_platform_alignment.get("required_run_modes", [])
    alignment_backends = cross_platform_alignment.get("required_backends", [])
    alignment_metric_limits = cross_platform_alignment.get("metric_limits", {})
    alignment_max_missing_backends = cross_platform_alignment.get("max_missing_backends")
    alignment_max_missing_run_modes = cross_platform_alignment.get("max_missing_run_modes")
    alignment_max_failures = cross_platform_alignment.get("max_alignment_failures")
    if not isinstance(alignment_history_file, str) or not alignment_history_file.startswith("user://"):
        print("visual_snapshot_targets.json cross_platform_alignment.history_file must be non-empty user:// path")
        return 1
    if alignment_history_file != archive_file:
        print("visual_snapshot_targets.json cross_platform_alignment.history_file must match approval_history_archive.archive_file")
        return 1
    if not isinstance(alignment_window, int) or alignment_window < 10:
        print("visual_snapshot_targets.json cross_platform_alignment.aggregation_window must be int >= 10")
        return 1
    if not isinstance(alignment_run_modes, list) or not alignment_run_modes:
        print("visual_snapshot_targets.json cross_platform_alignment.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(alignment_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json cross_platform_alignment.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for cross_platform_alignment")
            return 1
    if not isinstance(alignment_backends, list) or not alignment_backends:
        print("visual_snapshot_targets.json cross_platform_alignment.required_backends must be non-empty array")
        return 1
    for idx, backend_name in enumerate(alignment_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json cross_platform_alignment.required_backends[{idx}] must be non-empty string")
            return 1
    if not isinstance(alignment_metric_limits, dict) or not alignment_metric_limits:
        print("visual_snapshot_targets.json cross_platform_alignment.metric_limits must be non-empty object")
        return 1
    allowed_alignment_metrics = {
        "performance_alert_total",
        "performance_alert_critical",
        "performance_alert_warning",
        "performance_scenario_failures",
        "performance_cogate_failures",
    }
    for metric_name, metric_limit in alignment_metric_limits.items():
        if not isinstance(metric_name, str) or not metric_name:
            print("visual_snapshot_targets.json cross_platform_alignment.metric_limits key must be non-empty string")
            return 1
        if metric_name not in allowed_alignment_metrics:
            print(f"visual_snapshot_targets.json cross_platform_alignment.metric_limits.{metric_name} is not supported")
            return 1
        if not isinstance(metric_limit, int) or metric_limit < 0:
            print(f"visual_snapshot_targets.json cross_platform_alignment.metric_limits.{metric_name} must be int >= 0")
            return 1
    for key_name, key_value in (
        ("max_missing_backends", alignment_max_missing_backends),
        ("max_missing_run_modes", alignment_max_missing_run_modes),
        ("max_alignment_failures", alignment_max_failures),
    ):
        if not isinstance(key_value, int) or key_value < 0:
            print(f"visual_snapshot_targets.json cross_platform_alignment.{key_name} must be int >= 0")
            return 1

    if not isinstance(pressure_scenario_standardization, dict) or not pressure_scenario_standardization:
        print("visual_snapshot_targets.json pressure_scenario_standardization must be non-empty object")
        return 1
    standardization_targets_file = pressure_scenario_standardization.get("baseline_targets_file")
    standardization_report_file = pressure_scenario_standardization.get("baseline_report")
    standardization_run_modes = pressure_scenario_standardization.get("required_run_modes", [])
    standardization_scenarios = pressure_scenario_standardization.get("required_scenarios", [])
    standardization_avg_ratio = pressure_scenario_standardization.get("max_avg_frame_ms_ratio")
    standardization_p95_ratio = pressure_scenario_standardization.get("max_p95_frame_ms_ratio")
    standardization_memory_ratio = pressure_scenario_standardization.get("max_peak_memory_mb_ratio")
    standardization_max_failures = pressure_scenario_standardization.get("max_standardization_failures")

    if not isinstance(standardization_targets_file, str) or not standardization_targets_file.startswith("res://"):
        print("visual_snapshot_targets.json pressure_scenario_standardization.baseline_targets_file must be non-empty res:// path")
        return 1
    if not isinstance(standardization_report_file, str) or not standardization_report_file.startswith("user://"):
        print("visual_snapshot_targets.json pressure_scenario_standardization.baseline_report must be non-empty user:// path")
        return 1
    if isinstance(required_reports, list) and standardization_report_file not in required_reports:
        print("visual_snapshot_targets.json pressure_scenario_standardization.baseline_report must be listed in release_gate_templates.release_checklist.required_reports")
        return 1

    if not isinstance(standardization_run_modes, list) or not standardization_run_modes:
        print("visual_snapshot_targets.json pressure_scenario_standardization.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(standardization_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json pressure_scenario_standardization.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for pressure_scenario_standardization")
            return 1

    if not isinstance(standardization_scenarios, list) or not standardization_scenarios:
        print("visual_snapshot_targets.json pressure_scenario_standardization.required_scenarios must be non-empty array")
        return 1
    for idx, scenario_id in enumerate(standardization_scenarios):
        if not isinstance(scenario_id, str) or not scenario_id:
            print(f"visual_snapshot_targets.json pressure_scenario_standardization.required_scenarios[{idx}] must be non-empty string")
            return 1

    for key_name, key_value in (
        ("max_avg_frame_ms_ratio", standardization_avg_ratio),
        ("max_p95_frame_ms_ratio", standardization_p95_ratio),
        ("max_peak_memory_mb_ratio", standardization_memory_ratio),
    ):
        if not isinstance(key_value, (int, float)) or float(key_value) < 1.0 or float(key_value) > 3.0:
            print(f"visual_snapshot_targets.json pressure_scenario_standardization.{key_name} must be within [1.0, 3.0]")
            return 1
    if not isinstance(standardization_max_failures, int) or standardization_max_failures < 0:
        print("visual_snapshot_targets.json pressure_scenario_standardization.max_standardization_failures must be int >= 0")
        return 1

    if not isinstance(alignment_dashboard_refinement, dict) or not alignment_dashboard_refinement:
        print("visual_snapshot_targets.json alignment_dashboard_refinement must be non-empty object")
        return 1
    refinement_run_modes = alignment_dashboard_refinement.get("required_run_modes", [])
    refinement_metric_weights = alignment_dashboard_refinement.get("metric_weights", {})
    refinement_missing_backend_weight = alignment_dashboard_refinement.get("missing_backend_weight")
    refinement_missing_run_mode_weight = alignment_dashboard_refinement.get("missing_run_mode_weight")
    refinement_watch_score = alignment_dashboard_refinement.get("watch_score_threshold")
    refinement_critical_score = alignment_dashboard_refinement.get("critical_score_threshold")
    refinement_max_failures = alignment_dashboard_refinement.get("max_dashboard_failures")

    if not isinstance(refinement_run_modes, list) or not refinement_run_modes:
        print("visual_snapshot_targets.json alignment_dashboard_refinement.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(refinement_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json alignment_dashboard_refinement.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for alignment_dashboard_refinement")
            return 1

    if not isinstance(refinement_metric_weights, dict) or not refinement_metric_weights:
        print("visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights must be non-empty object")
        return 1
    allowed_dashboard_metrics = {
        "performance_alert_total",
        "performance_alert_critical",
        "performance_alert_warning",
        "performance_scenario_failures",
        "performance_cogate_failures",
    }
    metric_limits_keys = set(alignment_metric_limits.keys()) if isinstance(alignment_metric_limits, dict) else set()
    for metric_name, metric_weight in refinement_metric_weights.items():
        if not isinstance(metric_name, str) or not metric_name:
            print("visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights key must be non-empty string")
            return 1
        if metric_name not in allowed_dashboard_metrics:
            print(f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} is not supported")
            return 1
        if metric_name not in metric_limits_keys:
            print(f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} must exist in cross_platform_alignment.metric_limits")
            return 1
        if not isinstance(metric_weight, (int, float)) or float(metric_weight) < 0.0 or float(metric_weight) > 5.0:
            print(f"visual_snapshot_targets.json alignment_dashboard_refinement.metric_weights.{metric_name} must be within [0.0, 5.0]")
            return 1

    for key_name, key_value in (
        ("missing_backend_weight", refinement_missing_backend_weight),
        ("missing_run_mode_weight", refinement_missing_run_mode_weight),
    ):
        if not isinstance(key_value, (int, float)) or float(key_value) < 0.0 or float(key_value) > 5.0:
            print(f"visual_snapshot_targets.json alignment_dashboard_refinement.{key_name} must be within [0.0, 5.0]")
            return 1

    if not isinstance(refinement_watch_score, (int, float)) or float(refinement_watch_score) < 0.0:
        print("visual_snapshot_targets.json alignment_dashboard_refinement.watch_score_threshold must be float >= 0.0")
        return 1
    if not isinstance(refinement_critical_score, (int, float)) or float(refinement_critical_score) < 0.0:
        print("visual_snapshot_targets.json alignment_dashboard_refinement.critical_score_threshold must be float >= 0.0")
        return 1
    if float(refinement_critical_score) < float(refinement_watch_score):
        print("visual_snapshot_targets.json alignment_dashboard_refinement.critical_score_threshold must be >= watch_score_threshold")
        return 1
    if not isinstance(refinement_max_failures, int) or refinement_max_failures < 0:
        print("visual_snapshot_targets.json alignment_dashboard_refinement.max_dashboard_failures must be int >= 0")
        return 1

    if not isinstance(pressure_alignment_convergence_gate, dict) or not pressure_alignment_convergence_gate:
        print("visual_snapshot_targets.json pressure_alignment_convergence_gate must be non-empty object")
        return 1
    convergence_run_modes = pressure_alignment_convergence_gate.get("required_run_modes", [])
    convergence_backends = pressure_alignment_convergence_gate.get("required_backends", [])
    convergence_max_standardization_failures = pressure_alignment_convergence_gate.get("max_standardization_failures")
    convergence_max_alignment_failures = pressure_alignment_convergence_gate.get("max_alignment_failures")
    convergence_max_dashboard_failures = pressure_alignment_convergence_gate.get("max_dashboard_failures")
    convergence_max_critical_severity_count = pressure_alignment_convergence_gate.get("max_critical_severity_count")
    convergence_max_failures = pressure_alignment_convergence_gate.get("max_convergence_failures")

    if not isinstance(convergence_run_modes, list) or not convergence_run_modes:
        print("visual_snapshot_targets.json pressure_alignment_convergence_gate.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(convergence_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for pressure_alignment_convergence_gate")
            return 1

    if not isinstance(convergence_backends, list) or not convergence_backends:
        print("visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends must be non-empty array")
        return 1
    for idx, backend_name in enumerate(convergence_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends[{idx}] must be non-empty string")
            return 1
        if backend_name not in backend_matrix_set:
            print(f"visual_snapshot_targets.json pressure_alignment_convergence_gate.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")
            return 1

    for key_name, key_value in (
        ("max_standardization_failures", convergence_max_standardization_failures),
        ("max_alignment_failures", convergence_max_alignment_failures),
        ("max_dashboard_failures", convergence_max_dashboard_failures),
        ("max_critical_severity_count", convergence_max_critical_severity_count),
        ("max_convergence_failures", convergence_max_failures),
    ):
        if not isinstance(key_value, int) or key_value < 0:
            print(f"visual_snapshot_targets.json pressure_alignment_convergence_gate.{key_name} must be int >= 0")
            return 1

    if not isinstance(regression_cycle_window_governance, dict) or not regression_cycle_window_governance:
        print("visual_snapshot_targets.json regression_cycle_window_governance must be non-empty object")
        return 1
    cycle_history_file = regression_cycle_window_governance.get("history_file")
    cycle_window_size = regression_cycle_window_governance.get("cycle_window_size")
    cycle_min_entries = regression_cycle_window_governance.get("min_cycle_entries")
    cycle_run_modes = regression_cycle_window_governance.get("required_run_modes", [])
    cycle_backends = regression_cycle_window_governance.get("required_backends", [])
    cycle_max_warning_delta = regression_cycle_window_governance.get("max_warning_delta")
    cycle_max_blocker_delta = regression_cycle_window_governance.get("max_blocker_delta")
    cycle_max_alignment_score_delta = regression_cycle_window_governance.get("max_alignment_score_delta")
    cycle_max_failures = regression_cycle_window_governance.get("max_cycle_failures")

    if not isinstance(cycle_history_file, str) or not cycle_history_file.startswith("user://"):
        print("visual_snapshot_targets.json regression_cycle_window_governance.history_file must be non-empty user:// path")
        return 1
    if cycle_history_file != archive_file:
        print("visual_snapshot_targets.json regression_cycle_window_governance.history_file must match approval_history_archive.archive_file")
        return 1
    if not isinstance(cycle_window_size, int) or cycle_window_size < 10:
        print("visual_snapshot_targets.json regression_cycle_window_governance.cycle_window_size must be int >= 10")
        return 1
    if not isinstance(cycle_min_entries, int) or cycle_min_entries < 1:
        print("visual_snapshot_targets.json regression_cycle_window_governance.min_cycle_entries must be int >= 1")
        return 1
    if cycle_min_entries > cycle_window_size:
        print("visual_snapshot_targets.json regression_cycle_window_governance.min_cycle_entries must be <= cycle_window_size")
        return 1

    if not isinstance(cycle_run_modes, list) or not cycle_run_modes:
        print("visual_snapshot_targets.json regression_cycle_window_governance.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(cycle_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json regression_cycle_window_governance.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for regression_cycle_window_governance")
            return 1

    if not isinstance(cycle_backends, list) or not cycle_backends:
        print("visual_snapshot_targets.json regression_cycle_window_governance.required_backends must be non-empty array")
        return 1
    for idx, backend_name in enumerate(cycle_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json regression_cycle_window_governance.required_backends[{idx}] must be non-empty string")
            return 1
        if backend_name not in backend_matrix_set:
            print(f"visual_snapshot_targets.json regression_cycle_window_governance.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")
            return 1

    if not isinstance(cycle_max_warning_delta, int) or cycle_max_warning_delta < 0:
        print("visual_snapshot_targets.json regression_cycle_window_governance.max_warning_delta must be int >= 0")
        return 1
    if not isinstance(cycle_max_blocker_delta, int) or cycle_max_blocker_delta < 0:
        print("visual_snapshot_targets.json regression_cycle_window_governance.max_blocker_delta must be int >= 0")
        return 1
    if not isinstance(cycle_max_alignment_score_delta, (int, float)) or float(cycle_max_alignment_score_delta) < 0.0 or float(cycle_max_alignment_score_delta) > 5.0:
        print("visual_snapshot_targets.json regression_cycle_window_governance.max_alignment_score_delta must be within [0.0, 5.0]")
        return 1
    if not isinstance(cycle_max_failures, int) or cycle_max_failures < 0:
        print("visual_snapshot_targets.json regression_cycle_window_governance.max_cycle_failures must be int >= 0")
        return 1

    if not isinstance(multi_cycle_adaptive_gate, dict) or not multi_cycle_adaptive_gate:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate must be non-empty object")
        return 1
    adaptive_history_file = multi_cycle_adaptive_gate.get("history_file")
    adaptive_window_sizes = multi_cycle_adaptive_gate.get("window_sizes", {})
    adaptive_min_window_entries = multi_cycle_adaptive_gate.get("min_window_entries")
    adaptive_run_modes = multi_cycle_adaptive_gate.get("required_run_modes", [])
    adaptive_backends = multi_cycle_adaptive_gate.get("required_backends", [])
    adaptive_warning_slopes = multi_cycle_adaptive_gate.get("max_warning_slopes", {})
    adaptive_blocker_slopes = multi_cycle_adaptive_gate.get("max_blocker_slopes", {})
    adaptive_max_missing_run_modes = multi_cycle_adaptive_gate.get("max_missing_run_modes")
    adaptive_max_missing_backends = multi_cycle_adaptive_gate.get("max_missing_backends")
    adaptive_max_failures = multi_cycle_adaptive_gate.get("max_adaptive_failures")

    if not isinstance(adaptive_history_file, str) or not adaptive_history_file.startswith("user://"):
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.history_file must be non-empty user:// path")
        return 1
    if adaptive_history_file != archive_file:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.history_file must match approval_history_archive.archive_file")
        return 1

    if not isinstance(adaptive_window_sizes, dict) or not adaptive_window_sizes:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes must be non-empty object")
        return 1
    adaptive_short_window = adaptive_window_sizes.get("short")
    adaptive_mid_window = adaptive_window_sizes.get("mid")
    adaptive_long_window = adaptive_window_sizes.get("long")
    if not isinstance(adaptive_short_window, int) or adaptive_short_window < 4:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.short must be int >= 4")
        return 1
    if not isinstance(adaptive_mid_window, int) or adaptive_mid_window < 4:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.mid must be int >= 4")
        return 1
    if not isinstance(adaptive_long_window, int) or adaptive_long_window < 4:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.long must be int >= 4")
        return 1
    if adaptive_mid_window < adaptive_short_window:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.mid must be >= short")
        return 1
    if adaptive_long_window < adaptive_mid_window:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.window_sizes.long must be >= mid")
        return 1

    if not isinstance(adaptive_min_window_entries, int) or adaptive_min_window_entries < 1:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.min_window_entries must be int >= 1")
        return 1
    if adaptive_min_window_entries > adaptive_short_window:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.min_window_entries must be <= window_sizes.short")
        return 1

    if not isinstance(adaptive_run_modes, list) or not adaptive_run_modes:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(adaptive_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for multi_cycle_adaptive_gate")
            return 1

    if not isinstance(adaptive_backends, list) or not adaptive_backends:
        print("visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends must be non-empty array")
        return 1
    for idx, backend_name in enumerate(adaptive_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends[{idx}] must be non-empty string")
            return 1
        if backend_name not in backend_matrix_set:
            print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")
            return 1

    for key_name, slope_row in (
        ("max_warning_slopes", adaptive_warning_slopes),
        ("max_blocker_slopes", adaptive_blocker_slopes),
    ):
        if not isinstance(slope_row, dict) or not slope_row:
            print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key_name} must be non-empty object")
            return 1
        for window_name in ("short", "mid", "long"):
            slope_value = slope_row.get(window_name)
            if not isinstance(slope_value, (int, float)) or float(slope_value) < 0.0 or float(slope_value) > 10.0:
                print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key_name}.{window_name} must be within [0.0, 10.0]")
                return 1

    for key_name, key_value in (
        ("max_missing_run_modes", adaptive_max_missing_run_modes),
        ("max_missing_backends", adaptive_max_missing_backends),
        ("max_adaptive_failures", adaptive_max_failures),
    ):
        if not isinstance(key_value, int) or key_value < 0:
            print(f"visual_snapshot_targets.json multi_cycle_adaptive_gate.{key_name} must be int >= 0")
            return 1

    if not isinstance(release_feedback_governance, dict) or not release_feedback_governance:
        print("visual_snapshot_targets.json release_feedback_governance must be non-empty object")
        return 1
    feedback_history_file = release_feedback_governance.get("history_file")
    feedback_window_size = release_feedback_governance.get("feedback_window_size")
    min_feedback_entries = release_feedback_governance.get("min_feedback_entries")
    feedback_run_modes = release_feedback_governance.get("required_run_modes", [])
    feedback_backends = release_feedback_governance.get("required_backends", [])
    issue_metrics = release_feedback_governance.get("issue_metrics", [])
    min_closure_rate = release_feedback_governance.get("min_closure_rate")
    max_unresolved_issues = release_feedback_governance.get("max_unresolved_issues")
    feedback_max_missing_run_modes = release_feedback_governance.get("max_missing_run_modes")
    feedback_max_missing_backends = release_feedback_governance.get("max_missing_backends")
    feedback_max_failures = release_feedback_governance.get("max_feedback_failures")

    if not isinstance(feedback_history_file, str) or not feedback_history_file.startswith("user://"):
        print("visual_snapshot_targets.json release_feedback_governance.history_file must be non-empty user:// path")
        return 1
    if feedback_history_file != archive_file:
        print("visual_snapshot_targets.json release_feedback_governance.history_file must match approval_history_archive.archive_file")
        return 1
    if not isinstance(feedback_window_size, int) or feedback_window_size < 5:
        print("visual_snapshot_targets.json release_feedback_governance.feedback_window_size must be int >= 5")
        return 1
    if not isinstance(min_feedback_entries, int) or min_feedback_entries < 1:
        print("visual_snapshot_targets.json release_feedback_governance.min_feedback_entries must be int >= 1")
        return 1
    if min_feedback_entries > feedback_window_size:
        print("visual_snapshot_targets.json release_feedback_governance.min_feedback_entries must be <= feedback_window_size")
        return 1

    if not isinstance(feedback_run_modes, list) or not feedback_run_modes:
        print("visual_snapshot_targets.json release_feedback_governance.required_run_modes must be non-empty array")
        return 1
    for idx, mode_name in enumerate(feedback_run_modes):
        if not isinstance(mode_name, str) or not mode_name:
            print(f"visual_snapshot_targets.json release_feedback_governance.required_run_modes[{idx}] must be non-empty string")
            return 1
        if mode_name not in ci_mode_bindings:
            print(f"visual_snapshot_targets.json release_gate_templates.ci_mode_bindings must include '{mode_name}' for release_feedback_governance")
            return 1

    if not isinstance(feedback_backends, list) or not feedback_backends:
        print("visual_snapshot_targets.json release_feedback_governance.required_backends must be non-empty array")
        return 1
    for idx, backend_name in enumerate(feedback_backends):
        if not isinstance(backend_name, str) or not backend_name:
            print(f"visual_snapshot_targets.json release_feedback_governance.required_backends[{idx}] must be non-empty string")
            return 1
        if backend_name not in backend_matrix_set:
            print(f"visual_snapshot_targets.json release_feedback_governance.required_backends[{idx}] must be listed in backend_matrix_governance.required_backend_matrix")
            return 1

    allowed_issue_metrics = {
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
    }
    if not isinstance(issue_metrics, list) or not issue_metrics:
        print("visual_snapshot_targets.json release_feedback_governance.issue_metrics must be non-empty array")
        return 1
    for idx, metric_name in enumerate(issue_metrics):
        if not isinstance(metric_name, str) or not metric_name:
            print(f"visual_snapshot_targets.json release_feedback_governance.issue_metrics[{idx}] must be non-empty string")
            return 1
        if metric_name not in allowed_issue_metrics:
            print(f"visual_snapshot_targets.json release_feedback_governance.issue_metrics[{idx}] is not supported")
            return 1

    if not isinstance(min_closure_rate, (int, float)) or float(min_closure_rate) < 0.0 or float(min_closure_rate) > 1.0:
        print("visual_snapshot_targets.json release_feedback_governance.min_closure_rate must be within [0.0, 1.0]")
        return 1

    for key_name, key_value in (
        ("max_unresolved_issues", max_unresolved_issues),
        ("max_missing_run_modes", feedback_max_missing_run_modes),
        ("max_missing_backends", feedback_max_missing_backends),
        ("max_feedback_failures", feedback_max_failures),
    ):
        if not isinstance(key_value, int) or key_value < 0:
            print(f"visual_snapshot_targets.json release_feedback_governance.{key_name} must be int >= 0")
            return 1

    if not isinstance(report_layers, dict) or not report_layers:
        print("visual_snapshot_targets.json report_layers must be non-empty object")
        return 1
    for layer_name, layer_row in report_layers.items():
        if not isinstance(layer_name, str) or not layer_name:
            print("visual_snapshot_targets.json report_layers key must be non-empty string")
            return 1
        if not isinstance(layer_row, dict) or not layer_row:
            print(f"visual_snapshot_targets.json report_layers.{layer_name} must be non-empty object")
            return 1
        snapshot_ids = layer_row.get("snapshot_ids")
        max_layer_blockers = layer_row.get("max_layer_blockers")
        max_layer_warnings = layer_row.get("max_layer_warnings")
        min_pass_ratio = layer_row.get("min_pass_ratio")
        if not isinstance(snapshot_ids, list) or not snapshot_ids:
            print(f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids must be non-empty array")
            return 1
        for idx, snapshot_id in enumerate(snapshot_ids):
            if not isinstance(snapshot_id, str) or not snapshot_id:
                print(f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids[{idx}] must be non-empty string")
                return 1
            if snapshot_id not in snapshots:
                print(f"visual_snapshot_targets.json report_layers.{layer_name}.snapshot_ids[{idx}] must reference snapshots key")
                return 1
        if not isinstance(max_layer_blockers, int) or max_layer_blockers < 0:
            print(f"visual_snapshot_targets.json report_layers.{layer_name}.max_layer_blockers must be int >= 0")
            return 1
        if not isinstance(max_layer_warnings, int) or max_layer_warnings < 0:
            print(f"visual_snapshot_targets.json report_layers.{layer_name}.max_layer_warnings must be int >= 0")
            return 1
        if not isinstance(min_pass_ratio, (int, float)) or min_pass_ratio < 0.0 or min_pass_ratio > 1.0:
            print(f"visual_snapshot_targets.json report_layers.{layer_name}.min_pass_ratio must be within [0.0, 1.0]")
            return 1

    if not isinstance(cross_version_baseline, dict) or not cross_version_baseline:
        print("visual_snapshot_targets.json cross_version_baseline must be non-empty object")
        return 1
    reference_channels = cross_version_baseline.get("reference_channels")
    max_drift = cross_version_baseline.get("max_drift")
    max_violations = cross_version_baseline.get("max_violations")
    snapshot_references = cross_version_baseline.get("snapshot_references")
    if not isinstance(reference_channels, list) or not reference_channels:
        print("visual_snapshot_targets.json cross_version_baseline.reference_channels must be non-empty array")
        return 1
    for idx, channel_name in enumerate(reference_channels):
        if not isinstance(channel_name, str) or not channel_name:
            print(f"visual_snapshot_targets.json cross_version_baseline.reference_channels[{idx}] must be non-empty string")
            return 1
    if not isinstance(max_drift, dict) or not max_drift:
        print("visual_snapshot_targets.json cross_version_baseline.max_drift must be non-empty object")
        return 1
    opaque_drift = max_drift.get("opaque_ratio")
    unique_drift = max_drift.get("unique_color_ratio")
    luma_drift = max_drift.get("avg_luma")
    if not isinstance(opaque_drift, (int, float)) or opaque_drift < 0.0 or opaque_drift > 1.0:
        print("visual_snapshot_targets.json cross_version_baseline.max_drift.opaque_ratio must be within [0.0, 1.0]")
        return 1
    if not isinstance(unique_drift, (int, float)) or unique_drift < 0.0 or unique_drift > 1.0:
        print("visual_snapshot_targets.json cross_version_baseline.max_drift.unique_color_ratio must be within [0.0, 1.0]")
        return 1
    if not isinstance(luma_drift, (int, float)) or luma_drift < 0.0 or luma_drift > 1.0:
        print("visual_snapshot_targets.json cross_version_baseline.max_drift.avg_luma must be within [0.0, 1.0]")
        return 1
    if not isinstance(max_violations, int) or max_violations < 0:
        print("visual_snapshot_targets.json cross_version_baseline.max_violations must be int >= 0")
        return 1
    if not isinstance(snapshot_references, dict) or not snapshot_references:
        print("visual_snapshot_targets.json cross_version_baseline.snapshot_references must be non-empty object")
        return 1
    for snapshot_id, row in snapshot_references.items():
        if not isinstance(snapshot_id, str) or not snapshot_id:
            print("visual_snapshot_targets.json cross_version_baseline.snapshot_references key must be non-empty string")
            return 1
        if snapshot_id not in snapshots:
            print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id} must reference snapshots key")
            return 1
        if not isinstance(row, dict) or not row:
            print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id} must be non-empty object")
            return 1
        for metric_key in ("opaque_ratio", "unique_colors", "avg_luma"):
            metric_refs = row.get(metric_key)
            if not isinstance(metric_refs, dict) or not metric_refs:
                print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} must be non-empty object")
                return 1
            for channel_name in reference_channels:
                if channel_name not in metric_refs:
                    print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} must include {channel_name}")
                    return 1
            for channel_name, value in metric_refs.items():
                if not isinstance(channel_name, str) or not channel_name:
                    print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key} channel key must be non-empty string")
                    return 1
                if metric_key == "unique_colors":
                    if not isinstance(value, (int, float)) or float(value) < 1.0:
                        print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.unique_colors.{channel_name} must be >= 1")
                        return 1
                elif not isinstance(value, (int, float)) or float(value) < 0.0 or float(value) > 1.0:
                    print(f"visual_snapshot_targets.json cross_version_baseline.snapshot_references.{snapshot_id}.{metric_key}.{channel_name} must be within [0.0, 1.0]")
                    return 1

    if len(snapshots) < min_snapshots:
        print("visual_snapshot_targets.json snapshots count must satisfy thresholds.min_snapshots")
        return 1

    for snapshot_id, row in snapshots.items():
        if not isinstance(snapshot_id, str) or not snapshot_id:
            print("visual_snapshot_targets.json snapshots key must be non-empty string")
            return 1
        if not isinstance(row, dict):
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id} must be object")
            return 1

        scene_path = row.get("scene")
        setup = row.get("setup")
        width = row.get("width")
        height = row.get("height")
        warmup_frames = row.get("warmup_frames")
        capture_frames = row.get("capture_frames")
        opaque_ratio_min = row.get("opaque_ratio_min")
        unique_colors_min = row.get("unique_colors_min")
        luma_min = row.get("luma_min")
        luma_max = row.get("luma_max")

        if not isinstance(scene_path, str) or not scene_path.startswith("res://"):
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.scene must be res:// path")
            return 1
        if not isinstance(setup, str) or not setup:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.setup must be non-empty string")
            return 1
        if not isinstance(width, int) or width < 320:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.width must be int >= 320")
            return 1
        if not isinstance(height, int) or height < 180:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.height must be int >= 180")
            return 1
        if not isinstance(warmup_frames, int) or warmup_frames < 1:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.warmup_frames must be int >= 1")
            return 1
        if not isinstance(capture_frames, int) or capture_frames < 1:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.capture_frames must be int >= 1")
            return 1
        if not isinstance(opaque_ratio_min, (int, float)) or opaque_ratio_min < 0.0 or opaque_ratio_min > 1.0:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.opaque_ratio_min must be within [0.0, 1.0]")
            return 1
        if not isinstance(unique_colors_min, int) or unique_colors_min < 1:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.unique_colors_min must be int >= 1")
            return 1
        if not isinstance(luma_min, (int, float)) or luma_min < 0.0 or luma_min > 1.0:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_min must be within [0.0, 1.0]")
            return 1
        if not isinstance(luma_max, (int, float)) or luma_max < 0.0 or luma_max > 1.0:
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_max must be within [0.0, 1.0]")
            return 1
        if float(luma_min) > float(luma_max):
            print(f"visual_snapshot_targets.json snapshots.{snapshot_id}.luma_min cannot exceed luma_max")
            return 1

        scene_disk_path = root / scene_path.replace("res://", "")
        if not scene_disk_path.exists():
            print(f"visual_snapshot_targets.json scene target missing: {scene_path}")
            return 1

    narrative_index_path = root / "data" / "balance" / "narrative_index.json"
    try:
        narrative_index = json.loads(narrative_index_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Cannot parse narrative_index.json: {exc}")
        return 1

    segments = narrative_index.get("segments", [])
    if not isinstance(segments, list):
        print("narrative_index.json segments must be an array")
        return 1

    for item in segments:
        if not isinstance(item, dict):
            continue
        resource_path = item.get("resource_path", "")
        if not isinstance(resource_path, str) or not resource_path.startswith("res://"):
            continue
        disk_path = root / resource_path.replace("res://", "")
        if not disk_path.exists():
            warnings.append(f"Missing narrative resource placeholder: {resource_path}")

    if warnings:
        for message in warnings:
            print(f"Warning: {message}")

    print("Basic resource structure check passed.")
    if warnings:
        print(f"Resource check completed with {len(warnings)} warning(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
