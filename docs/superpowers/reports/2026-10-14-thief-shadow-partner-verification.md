# Thief basic stars and Shadow Partner

User-approved mechanics: basic attacks throw 1/2/3/4 stars at Thief/Assassin/Hermit/Night Lord respectively. Third-job Shadow Partner stays behind the player for 60 seconds and mirrors each star, for 6 basic stars at third job and 8 at fourth. Remove redundant Twin Stars.

Implemented the four Thief advancements at levels 10/30/60/100 through Captain Elowen, raised the level cap to 100, and extended save validation and skill-point pools. These advancements currently add the requested basic-star bonuses and third-job summon; additional second/fourth-job skill sets and Hyper are future work. Warrior third/fourth jobs remain unavailable.

Shadow Partner unlocks automatically at Hermit and is assigned to C. An existing C-slot attack is moved into an empty slot. The summon mirrors both basic volleys and Shadow Fan, follows the player's facing/movement, has an active countdown, pauses with menus, expires, and ends on death, character switching, reload or loading a job that cannot use it. Existing ray collision/range behavior applies to its stars.

Legacy Thief saves migrate Twin Stars out of learned skills and hotbar slots, refund invested rank points once, and retain other ranks, equipment and progression. Invalid legacy ranks and inflated points reject atomically.

Validation:

- `python3 tools/verify_side_scroller.py`: **212/212 passed**, no script errors. New tests cover all four job transitions and star counts, six/eight mirrored volleys, fan mirroring, 60-second lifetime, cooldown/no stacking, pause behavior, expiry, lower-job cleanup, old-save refunds/idempotency, level-100 AP/save limits and preservation of an existing C-slot attack. New regressions were observed failing before their corresponding fixes.
- Editor import and native capture completed. Rendered summon/combat and third-job Skills window inspected; long descriptions were split into readable lines to remove unintended horizontal scrolling.
- Official Godot 4.7.2 Web Editor in Chromium: imported and ran the ZIP, selected the Thief slot, imported a valid Hermit fixture through the existing backup callback, pressed C, and held Space. Observed the following shadow, traveling mirrored stars, the 60-second countdown and six-star basic hotbar label. No game script errors; upstream TCP-debugger/thread warnings remain.
- `python3 tools/test_package.py`: ZIP integrity, dependencies, root layout, explicit directory entries, cache/save exclusion and final shipped ZIP/source byte parity passed. Final archive: 84 files, approximately 18 MB.

Browser exercise preceded the final lower-job cleanup and automatic C-slot preservation fixes; those paths were then covered by the full native suite. The final ZIP also includes the description line-break correction. Existing root crypt edits were preserved and excluded from this revision.
