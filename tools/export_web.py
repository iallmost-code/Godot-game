#!/usr/bin/env python3
"""Export the playable web build into docs/ for GitHub Pages.

Usage: python3 tools/export_web.py /path/to/godot
Needs the Godot 4.7.2 web templates (web_nothreads_release.zip) installed in
the editor's export_templates/4.7.2.stable folder. The build is single-threaded,
so it runs on GitHub Pages without special server headers.
"""
import pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = ROOT / "side_scroller"
OUT = ROOT / "docs"
BUILD_FILES = ["index.html", "index.js", "index.wasm", "index.pck", "index.png", "index.icon.png",
               "index.apple-touch-icon.png", "index.audio.worklet.js", "index.audio.position.worklet.js"]
LIMIT = 100 * 1024 * 1024  # GitHub rejects files over 100 MB.

def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    godot = sys.argv[1]
    OUT.mkdir(exist_ok=True)
    subprocess.run([godot, "--headless", "--path", str(PROJECT), "--editor", "--import", "--quit"], check=False)
    subprocess.run([godot, "--headless", "--path", str(PROJECT), "--export-release", "Web", str(OUT / "index.html")], check=True)
    for name in BUILD_FILES:
        path = OUT / name
        if not path.exists():
            sys.exit(f"missing {path}")
        if path.stat().st_size >= LIMIT:
            sys.exit(f"{path} is over GitHub's 100 MB limit")
    print("Web build ready in docs/: " + ", ".join(f"{n} {(OUT / n).stat().st_size // 1024} KB" for n in ["index.wasm", "index.pck"]))

if __name__ == "__main__":
    main()
