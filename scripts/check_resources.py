from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    expected_dirs = [
        root / "scenes",
        root / "scripts",
        root / "data" / "balance",
    ]

    for directory in expected_dirs:
        if not directory.exists():
            print(f"Missing required directory: {directory}")
            return 1

    print("Basic resource structure check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
