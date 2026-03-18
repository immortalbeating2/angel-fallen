import json
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    balance_dir = root / "data" / "balance"
    files = sorted(balance_dir.glob("*.json"))
    if not files:
        print("No JSON config files found.")
        return 1

    for file in files:
        try:
            json.loads(file.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"Invalid JSON: {file.name} -> {exc}")
            return 1

    print(f"Validated {len(files)} JSON config files successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
