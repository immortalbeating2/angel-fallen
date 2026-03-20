from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json


ROOT = Path(__file__).resolve().parents[2]
RESOURCE_ACCEPTANCE_TARGETS_PATH = ROOT / "data" / "balance" / "resource_acceptance_targets.json"

MATERIAL_PROFILE_BY_CATEGORY: dict[str, str] = {
    "characters": "res://resources/material_profiles/mat_character_base.tres",
    "weapons": "res://resources/material_profiles/mat_weapon_base.tres",
    "passives": "res://resources/material_profiles/mat_passive_base.tres",
    "accessories": "res://resources/material_profiles/mat_accessory_base.tres",
    "enemies": "res://resources/material_profiles/mat_enemy_base.tres",
    "evolutions": "res://resources/material_profiles/mat_evolution_base.tres",
    "meta_upgrades": "res://resources/material_profiles/mat_meta_upgrade_base.tres",
    "forge_recipes": "res://resources/material_profiles/mat_forge_recipe_base.tres",
}

ASSET_STATE_BY_CATEGORY: dict[str, str] = {
    "characters": "production_candidate",
    "weapons": "production_candidate",
    "passives": "production_candidate",
    "accessories": "production_candidate",
    "enemies": "production_candidate",
    "evolutions": "production_candidate",
    "meta_upgrades": "production_candidate",
    "forge_recipes": "production_candidate",
}

DEFAULT_ACCEPTANCE_PROFILE_BY_CATEGORY_STATE: dict[str, dict[str, str]] = {
    "characters": {
        "production_candidate": "menu_candidate_preview",
        "production_ready": "menu_ready_matrix",
    },
    "weapons": {
        "production_candidate": "combat_candidate_preview",
        "production_ready": "combat_ready_matrix",
    },
    "passives": {
        "production_candidate": "combat_candidate_preview",
        "production_ready": "combat_ready_matrix",
    },
    "accessories": {
        "production_candidate": "combat_candidate_preview",
        "production_ready": "combat_ready_matrix",
    },
    "enemies": {
        "production_candidate": "combat_candidate_preview",
        "production_ready": "combat_ready_matrix",
    },
    "evolutions": {
        "production_candidate": "ui_candidate_preview",
        "production_ready": "ui_ready_matrix",
    },
    "meta_upgrades": {
        "production_candidate": "menu_candidate_preview",
        "production_ready": "menu_ready_matrix",
    },
    "forge_recipes": {
        "production_candidate": "ui_candidate_preview",
        "production_ready": "ui_ready_matrix",
    },
}

DEFAULT_ACCEPTANCE_PROFILE_DEFS: dict[str, dict[str, str]] = {
    "menu_candidate_preview": {"tier": "candidate", "report_bucket": "menu"},
    "combat_candidate_preview": {"tier": "candidate", "report_bucket": "combat"},
    "ui_candidate_preview": {"tier": "candidate", "report_bucket": "ui"},
    "menu_ready_matrix": {"tier": "ready", "report_bucket": "menu"},
    "combat_ready_matrix": {"tier": "ready", "report_bucket": "combat"},
    "ui_ready_matrix": {"tier": "ready", "report_bucket": "ui"},
}


def _read_json(relative_path: str) -> dict:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.write_text(content, encoding="utf-8")


def _to_display_name(resource_id: str) -> str:
    raw = resource_id.replace("_", " ").strip()
    return " ".join(word.capitalize() for word in raw.split())


def _load_acceptance_targets() -> dict:
    if not RESOURCE_ACCEPTANCE_TARGETS_PATH.exists():
        return {}
    try:
        return json.loads(RESOURCE_ACCEPTANCE_TARGETS_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _get_acceptance_scene_map(data: dict) -> dict[str, str]:
    row = data.get("acceptance_scene_map") if isinstance(data, dict) else None
    if not isinstance(row, dict):
        return {}
    result: dict[str, str] = {}
    for key, value in row.items():
        if isinstance(key, str) and isinstance(value, str) and value.startswith("res://"):
            result[key] = value
    return result


def _get_preview_texture_map(data: dict) -> dict[str, str]:
    row = data.get("preview_texture_map") if isinstance(data, dict) else None
    if not isinstance(row, dict):
        return {}
    result: dict[str, str] = {}
    for key, value in row.items():
        if isinstance(key, str) and isinstance(value, str) and value.startswith("res://"):
            result[key] = value
    return result


def _get_production_ready_targets(data: dict) -> dict[str, set[str]]:
    row = data.get("required_production_ready_ids") if isinstance(data, dict) else None
    if not isinstance(row, dict):
        return {}
    result: dict[str, set[str]] = {}
    for category, values in row.items():
        if not isinstance(category, str) or not isinstance(values, list):
            continue
        category_ids: set[str] = set()
        for value in values:
            if isinstance(value, str) and value:
                category_ids.add(value)
        result[category] = category_ids
    return result


def _get_scene_visual_requirements(data: dict) -> dict[str, list[dict[str, str]]]:
    row = data.get("scene_visual_requirements") if isinstance(data, dict) else None
    if not isinstance(row, dict):
        return {}
    allowed_rules = {
        "exists",
        "non_null",
        "non_empty_string",
        "array_non_empty",
        "float_gt_zero",
        "bool_true",
    }
    result: dict[str, list[dict[str, str]]] = {}
    for category, values in row.items():
        if not isinstance(category, str) or not isinstance(values, list):
            continue
        category_rows: list[dict[str, str]] = []
        for value in values:
            if not isinstance(value, dict):
                continue
            scene = str(value.get("scene", "")).strip()
            node_path = str(value.get("node_path", "")).strip()
            node_type = str(value.get("node_type", "")).strip()
            rule = str(value.get("rule", "")).strip()
            prop = str(value.get("property", "")).strip()
            if not scene.startswith("res://") or not node_path or not node_type or rule not in allowed_rules:
                continue
            row_data = {
                "scene": scene,
                "node_path": node_path,
                "node_type": node_type,
                "rule": rule,
            }
            if prop:
                row_data["property"] = prop
            category_rows.append(row_data)
        if category_rows:
            result[category] = category_rows
    return result


def _get_acceptance_profile_policy(data: dict) -> tuple[dict[str, dict[str, str]], dict[str, dict[str, str]], str]:
    policy = data.get("acceptance_profile_policy") if isinstance(data, dict) else None
    if not isinstance(policy, dict):
        return DEFAULT_ACCEPTANCE_PROFILE_DEFS, DEFAULT_ACCEPTANCE_PROFILE_BY_CATEGORY_STATE, "ready"

    profile_defs_raw = policy.get("profiles")
    category_profile_map_raw = policy.get("category_profile_map")
    required_ready_profile_tier = str(policy.get("required_ready_profile_tier", "ready")).strip() or "ready"

    profile_defs: dict[str, dict[str, str]] = {}
    if isinstance(profile_defs_raw, dict):
        for profile_name, profile_row in profile_defs_raw.items():
            if not isinstance(profile_name, str) or not profile_name:
                continue
            if not isinstance(profile_row, dict):
                continue
            tier = str(profile_row.get("tier", "")).strip()
            report_bucket = str(profile_row.get("report_bucket", "")).strip()
            if tier in {"candidate", "ready"} and report_bucket:
                profile_defs[profile_name] = {
                    "tier": tier,
                    "report_bucket": report_bucket,
                }
    if not profile_defs:
        profile_defs = DEFAULT_ACCEPTANCE_PROFILE_DEFS

    category_profile_map: dict[str, dict[str, str]] = {}
    if isinstance(category_profile_map_raw, dict):
        for category, row in category_profile_map_raw.items():
            if not isinstance(category, str) or not category:
                continue
            if not isinstance(row, dict):
                continue
            candidate_profile = str(row.get("production_candidate", "")).strip()
            ready_profile = str(row.get("production_ready", "")).strip()
            if candidate_profile and ready_profile:
                category_profile_map[category] = {
                    "production_candidate": candidate_profile,
                    "production_ready": ready_profile,
                }
    if not category_profile_map:
        category_profile_map = DEFAULT_ACCEPTANCE_PROFILE_BY_CATEGORY_STATE

    if required_ready_profile_tier not in {"candidate", "ready"}:
        required_ready_profile_tier = "ready"

    return profile_defs, category_profile_map, required_ready_profile_tier


def _build_resource_text(
    resource_id: str,
    resource_kind: str,
    source_json: str,
    material_profile: str,
    asset_state: str,
    preview_texture: str,
    acceptance_scene: str,
    acceptance_profile: str,
    acceptance_tier: str,
) -> str:
    display_name = _to_display_name(resource_id)
    return (
        '[gd_resource type="Resource" format=3]\n\n'
        "[resource]\n"
        f'id = "{resource_id}"\n'
        f'display_name = "{display_name}"\n'
        f'resource_kind = "{resource_kind}"\n'
        f'source_json = "{source_json}"\n'
        f'material_profile = "{material_profile}"\n'
        f'asset_state = "{asset_state}"\n'
        f'preview_texture = "{preview_texture}"\n'
        f'acceptance_scene = "{acceptance_scene}"\n'
        f'acceptance_profile = "{acceptance_profile}"\n'
        f'acceptance_tier = "{acceptance_tier}"\n'
    )


def _extract_ids() -> dict[str, list[dict[str, str]]]:
    characters = _read_json("data/balance/characters.json").get("characters", [])
    evolutions = _read_json("data/balance/evolutions.json").get("evolutions", [])
    shop_items = _read_json("data/balance/shop_items.json")
    meta_upgrades = _read_json("data/balance/meta_upgrades.json").get("upgrades", [])
    enemy_scaling = _read_json("data/balance/enemy_scaling.json")
    boss_phases = _read_json("data/balance/boss_phases.json")

    chapter_map = enemy_scaling.get("chapter_archetype_map", {})
    chapter_enemy_ids: set[str] = set()
    for chapter_data in chapter_map.values():
        if isinstance(chapter_data, dict):
            for value in chapter_data.values():
                if isinstance(value, str) and value:
                    chapter_enemy_ids.add(value)

    boss_profiles = boss_phases.get("bosses", {})
    if not isinstance(boss_profiles, dict):
        boss_profiles = boss_phases.get("phase_profiles", {})
    if not isinstance(boss_profiles, dict):
        boss_profiles = {}

    boss_enemy_ids = {
        key
        for key in boss_profiles.keys()
        if isinstance(key, str) and key
    }

    accessory_ids = [
        "acc_heart_of_mine",
        "acc_flame_core",
        "acc_zero_mark",
        "acc_void_eye",
    ]

    forge_recipe_ids: list[str] = []
    for evolution in evolutions:
        evo_id = str(evolution.get("id", "")).strip()
        if not evo_id:
            continue
        suffix = evo_id[4:] if evo_id.startswith("evo_") else evo_id
        forge_recipe_ids.append(f"forge_{suffix}")

    return {
        "characters": [
            {"id": str(row.get("id", "")).strip(), "source_json": "res://data/balance/characters.json"}
            for row in characters
            if isinstance(row, dict) and str(row.get("id", "")).strip()
        ],
        "weapons": [
            {"id": item, "source_json": "res://data/balance/shop_items.json"}
            for item in sorted({str(x) for x in shop_items.get("pools", {}).get("weapon", []) if isinstance(x, str) and x})
        ],
        "passives": [
            {"id": item, "source_json": "res://data/balance/shop_items.json"}
            for item in sorted({str(x) for x in shop_items.get("pools", {}).get("passive", []) if isinstance(x, str) and x})
        ],
        "accessories": [
            {"id": item, "source_json": "res://scripts/game/game_world.gd"}
            for item in accessory_ids
        ],
        "enemies": [
            {"id": item, "source_json": "res://data/balance/enemy_scaling.json"}
            for item in sorted(chapter_enemy_ids)
        ]
        + [
            {"id": item, "source_json": "res://data/balance/boss_phases.json"}
            for item in sorted(boss_enemy_ids)
            if item not in chapter_enemy_ids
        ],
        "evolutions": [
            {"id": str(row.get("id", "")).strip(), "source_json": "res://data/balance/evolutions.json"}
            for row in evolutions
            if isinstance(row, dict) and str(row.get("id", "")).strip()
        ],
        "meta_upgrades": [
            {"id": str(row.get("id", "")).strip(), "source_json": "res://data/balance/meta_upgrades.json"}
            for row in meta_upgrades
            if isinstance(row, dict) and str(row.get("id", "")).strip()
        ],
        "forge_recipes": [
            {"id": recipe_id, "source_json": "res://data/balance/evolutions.json"}
            for recipe_id in sorted(set(forge_recipe_ids))
        ],
    }


def main() -> int:
    resource_kind_by_category = {
        "characters": "character",
        "weapons": "weapon",
        "passives": "passive",
        "accessories": "accessory",
        "enemies": "enemy",
        "evolutions": "evolution",
        "meta_upgrades": "meta_upgrade",
        "forge_recipes": "forge_recipe",
    }

    entries_by_category = _extract_ids()
    acceptance_targets = _load_acceptance_targets()
    acceptance_scene_map = _get_acceptance_scene_map(acceptance_targets)
    preview_texture_map = _get_preview_texture_map(acceptance_targets)
    production_ready_targets = _get_production_ready_targets(acceptance_targets)
    scene_visual_requirements = _get_scene_visual_requirements(acceptance_targets)
    acceptance_profile_defs, category_profile_map, required_ready_profile_tier = _get_acceptance_profile_policy(acceptance_targets)
    catalog: dict[str, object] = {
        "version": "stub_catalog_v8",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "asset_state": "mixed_candidate_ready",
        "material_profile_map": MATERIAL_PROFILE_BY_CATEGORY,
        "acceptance_scene_map": acceptance_scene_map,
        "scene_visual_requirements": scene_visual_requirements,
        "scene_visual_requirement_counts": {},
        "preview_texture_map": preview_texture_map,
        "acceptance_profile_policy": {
            "required_ready_profile_tier": required_ready_profile_tier,
            "profiles": acceptance_profile_defs,
            "category_profile_map": category_profile_map,
        },
        "production_ready_counts": {},
        "production_ready_ratio_by_category": {},
        "acceptance_tier_counts": {},
        "acceptance_bucket_counts": {},
        "categories": {},
    }
    acceptance_bucket_counts: dict[str, dict[str, int]] = {}

    for category, entries in entries_by_category.items():
        category_dir = ROOT / "resources" / category
        category_dir.mkdir(parents=True, exist_ok=True)

        sorted_entries = sorted(entries, key=lambda row: row["id"])
        catalog_entries: list[dict[str, str]] = []
        production_ready_count = 0
        category_tier_counts: dict[str, int] = {"candidate": 0, "ready": 0}
        for entry in sorted_entries:
            resource_id = entry["id"]
            source_json = entry["source_json"]
            material_profile = MATERIAL_PROFILE_BY_CATEGORY[category]
            is_production_ready = resource_id in production_ready_targets.get(category, set())
            asset_state = "production_ready" if is_production_ready else ASSET_STATE_BY_CATEGORY[category]
            if is_production_ready:
                production_ready_count += 1
            preview_texture = preview_texture_map.get(category, "res://assets/sprites/tiles/ground_ch1.png")
            acceptance_scene = acceptance_scene_map.get(category, "res://scenes/main_menu/main_menu.tscn")
            category_profiles = category_profile_map.get(category, {})
            acceptance_profile = str(category_profiles.get(asset_state, "")).strip()
            if not acceptance_profile:
                acceptance_profile = str(
                    DEFAULT_ACCEPTANCE_PROFILE_BY_CATEGORY_STATE.get(category, {}).get(asset_state, "menu_candidate_preview")
                ).strip()
            profile_def = acceptance_profile_defs.get(acceptance_profile, {})
            acceptance_tier = str(profile_def.get("tier", "")).strip()
            if not acceptance_tier:
                acceptance_tier = required_ready_profile_tier if is_production_ready else "candidate"
            category_tier_counts[acceptance_tier] = int(category_tier_counts.get(acceptance_tier, 0)) + 1
            report_bucket = str(profile_def.get("report_bucket", "")).strip() or "uncategorized"
            if report_bucket not in acceptance_bucket_counts:
                acceptance_bucket_counts[report_bucket] = {
                    "entries": 0,
                    "ready_entries": 0,
                }
            acceptance_bucket_counts[report_bucket]["entries"] = int(
                acceptance_bucket_counts[report_bucket].get("entries", 0)
            ) + 1
            if is_production_ready:
                acceptance_bucket_counts[report_bucket]["ready_entries"] = int(
                    acceptance_bucket_counts[report_bucket].get("ready_entries", 0)
                ) + 1
            resource_path = category_dir / f"{resource_id}.tres"
            resource_text = _build_resource_text(
                resource_id,
                resource_kind_by_category[category],
                source_json,
                material_profile,
                asset_state,
                preview_texture,
                acceptance_scene,
                acceptance_profile,
                acceptance_tier,
            )
            _write_text(resource_path, resource_text)

            catalog_entries.append(
                {
                    "id": resource_id,
                    "path": f"res://resources/{category}/{resource_id}.tres",
                    "source_json": source_json,
                    "material_profile": material_profile,
                    "asset_state": asset_state,
                    "preview_texture": preview_texture,
                    "acceptance_scene": acceptance_scene,
                    "acceptance_profile": acceptance_profile,
                    "acceptance_tier": acceptance_tier,
                }
            )

        cast_categories = catalog["categories"]
        if isinstance(cast_categories, dict):
            cast_categories[category] = catalog_entries
        cast_counts = catalog["production_ready_counts"]
        if isinstance(cast_counts, dict):
            cast_counts[category] = production_ready_count
        cast_ratios = catalog["production_ready_ratio_by_category"]
        if isinstance(cast_ratios, dict):
            entry_count = len(catalog_entries)
            cast_ratios[category] = float(production_ready_count) / float(entry_count) if entry_count > 0 else 0.0
        cast_tier_counts = catalog["acceptance_tier_counts"]
        if isinstance(cast_tier_counts, dict):
            cast_tier_counts[category] = category_tier_counts
        cast_visual_counts = catalog["scene_visual_requirement_counts"]
        if isinstance(cast_visual_counts, dict):
            visual_rows = scene_visual_requirements.get(category, [])
            cast_visual_counts[category] = len(visual_rows)

    cast_bucket_counts = catalog["acceptance_bucket_counts"]
    if isinstance(cast_bucket_counts, dict):
        cast_bucket_counts.update(acceptance_bucket_counts)

    catalog_path = ROOT / "resources" / "resource_catalog.json"
    _write_text(catalog_path, json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")

    counts = []
    for category in resource_kind_by_category.keys():
        category_entries = catalog["categories"].get(category, []) if isinstance(catalog["categories"], dict) else []
        counts.append(f"{category}={len(category_entries)}")

    print("Resource stubs synchronized.")
    print("  " + ", ".join(counts))
    print(f"  catalog: {catalog_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
