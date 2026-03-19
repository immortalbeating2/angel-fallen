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
        root / "scripts",
        root / "data" / "balance",
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
        root / "data" / "balance" / "map_generation.json",
        root / "test" / "unit" / "test_character_weapon_profiles.gd",
        root / "test" / "unit" / "test_enemy_scaling_profiles.gd",
        root / "test" / "unit" / "test_shop_economy_config.gd",
        root / "test" / "unit" / "test_narrative_route_style_config.gd",
        root / "test" / "unit" / "test_map_generation_config.gd",
        root / "test" / "unit" / "test_evolutions_config.gd",
        root / "test" / "unit" / "test_enemy_pooling.gd",
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
