import json
from json import JSONDecodeError
from pathlib import Path


def _collect_targets(root: Path) -> list[Path]:
    targets: list[Path] = []
    balance_dir = root / "data" / "balance"
    if balance_dir.exists():
        targets.extend(sorted(balance_dir.glob("*.json")))

    for extra in (
        root / "resources" / "resource_catalog.json",
        root / "assets" / "sprites" / "tiles" / "atlas_manifest.json",
    ):
        if extra.exists():
            targets.append(extra)

    return targets


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    targets = _collect_targets(root)
    if not targets:
        print("No JSON targets found for syntax check.")
        return 1

    has_error = False
    for path in targets:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except JSONDecodeError as exc:
            has_error = True
            rel = path.relative_to(root).as_posix()
            print(f"JSON syntax error: {rel}:{exc.lineno}:{exc.colno} -> {exc.msg}")
        except Exception as exc:
            has_error = True
            rel = path.relative_to(root).as_posix()
            print(f"JSON read error: {rel} -> {exc}")

    if has_error:
        return 1

    print(f"JSON syntax check passed for {len(targets)} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
