#!/usr/bin/env python3
"""Export the playable web build into docs/ for GitHub Pages.

Usage: python3 tools/export_web.py /path/to/godot
Use --pack-only to reuse the existing docs/ runtime for the same Godot version.
A full export needs the Godot 4.7.2 web templates (web_nothreads_release.zip) installed in
the editor's export_templates/4.7.2.stable folder. The build is single-threaded,
so it runs on GitHub Pages without special server headers.
"""
import pathlib, subprocess, sys, json, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = ROOT / "side_scroller"
OUT = ROOT / "docs"
BUILD_FILES = ["index.html", "index.js", "index.wasm", "index.pck", "index.png", "index.icon.png",
               "index.apple-touch-icon.png", "index.audio.worklet.js", "index.audio.position.worklet.js"]
LIMIT = 100 * 1024 * 1024  # GitHub rejects files over 100 MB.

def main():
    if len(sys.argv) not in [2,3] or len(sys.argv)==3 and sys.argv[2]!="--pack-only":
        sys.exit(__doc__)
    godot = sys.argv[1]
    OUT.mkdir(exist_ok=True)
    subprocess.run([godot, "--headless", "--path", str(PROJECT), "--editor", "--import", "--quit"], check=False)
    if len(sys.argv)==3:
        # Scripts/art can reuse the existing runtime when the Godot version stays
        # the same. No export-template download is needed for a resource pack.
        for name in BUILD_FILES:
            if not (OUT/name).exists(): sys.exit(f"pack-only needs existing runtime: {name}")
        subprocess.run([godot,"--headless","--path",str(PROJECT),"--export-pack","Web",str(OUT/"index.pck")],check=True)
        html=OUT/"index.html"
        text=html.read_text()
        match=re.search(r"const GODOT_CONFIG = (\{[^\n]+\});",text)
        if not match:sys.exit("missing web loader configuration")
        config=json.loads(match.group(1))
        config["fileSizes"]["index.pck"]=(OUT/"index.pck").stat().st_size
        config["fileSizes"]["index.wasm"]=(OUT/"index.wasm").stat().st_size
        text=text[:match.start(1)]+json.dumps(config,separators=(",",":"))+text[match.end(1):]
        html.write_text(text)
    else:
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
