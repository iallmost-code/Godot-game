# Art and skill assignment revision

The Skills window now moves or swaps learned active skills between slots, confirms the change near the top, and displays configured keys. Original shaded chibi character/enemy sprites, illustrated attack effects, textured grass/stone platforms, mushroom cottages, trees, and a parallax landscape replace the flat prototype art. Collision geometry remains separate from the artwork.

Verification:

- Godot 4.7.2: `python3 tools/verify_side_scroller.py` — 111/111 checks passed, with no script/runtime errors.
- `python3 tools/test_package.py` — archive layout, dependencies, directory entries, exclusions, and shipped archive/source byte parity passed.
- Official Godot 4.7.2 Web Editor in Chromium: imported the ZIP, installed the project, and ran the illustrated town. Loaded a valid level-31 Spearman fixture through the game's backup callback, opened Skills, and clicked the Ground Wave C button using a real browser mouse event. The UI confirmed C assignment, Crescent Sweep moved to Z, and the hotbar updated while paused.
- Native rendered town/forest/Skills captures inspected, including illustrated attack effect. Forest preview: `docs/previews/windswept-forest.png`.
- Read-only code review found a stale packaged Skills script; rebuilt the archive and added shipped-source parity validation. No other critical/important findings.

The Web Editor emitted its existing unsupported TCP debugger and main-thread warnings; no game script errors appeared. Browser software rendering is unsuitable for assessing performance. This remains a playable prototype, with later jobs and hyper skills visibly locked.
