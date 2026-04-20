#!/usr/bin/env python3
"""
Prepare iOS Simulator screenshots for App Store Connect submission.

- Looks for .png files in the current working directory.
- If none are found, asks the user where to look.
- Sorts by file creation time (oldest first).
- Resizes each to 1242x2688 (6.5" iPhone display spec accepted by App
  Store Connect for legacy screenshot sets).
- Writes output into the current working directory as screenshot0.png,
  screenshot1.png, ...
"""
import subprocess
import sys
from pathlib import Path

TARGET_W, TARGET_H = 1242, 2688


def find_pngs(directory: Path) -> list[Path]:
    return [p for p in directory.iterdir() if p.is_file() and p.suffix.lower() == ".png"]


def main() -> int:
    cwd = Path.cwd()
    src = cwd
    pngs = find_pngs(src)

    if not pngs:
        print("No .png files found in the current directory.")
        answer = input("Enter the path to the directory containing screenshots: ").strip()
        if not answer:
            print("No path provided; aborting.", file=sys.stderr)
            return 1
        src = Path(answer).expanduser()
        if not src.is_dir():
            print(f"Not a directory: {src}", file=sys.stderr)
            return 1
        pngs = find_pngs(src)
        if not pngs:
            print(f"No .png files found in {src}", file=sys.stderr)
            return 1

    pngs.sort(key=lambda p: p.stat().st_birthtime)

    for index, src_path in enumerate(pngs):
        dest = cwd / f"screenshot{index}.png"
        if dest.resolve() == src_path.resolve():
            continue
        subprocess.run(
            [
                "sips",
                "--resampleHeightWidth", str(TARGET_H), str(TARGET_W),
                str(src_path),
                "--out", str(dest),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        print(f"{src_path.name} -> {dest.name}")

    print(f"\nProcessed {len(pngs)} screenshots into {cwd}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
