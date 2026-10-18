extends RefCounted
# Keys for actions (one key each). Skills live per character in CharacterState.keys
# and can sit on any key these actions do not use; see systems/keymap.gd.
const DEFAULTS = {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"interact":KEY_UP,"jump":KEY_SHIFT,"attack":KEY_SPACE,"potion_hp":KEY_1,"potion_mp":KEY_2,"menu":KEY_ESCAPE,"menu_inventory":KEY_I,"menu_map":KEY_M,"menu_skills":KEY_K,"menu_stats":KEY_S,"travel_hub":KEY_H,"travel_town":KEY_T,"move_down":KEY_DOWN,"menu_quests":KEY_Q,"menu_journey":KEY_J,"menu_bosses":KEY_B}
# These always need a key; the rest can be cleared (0) to free their key for skills.
const REQUIRED=["move_left","move_right","move_down","interact","jump","attack","menu"]
var bindings = DEFAULTS.duplicate()
# Skill-slot keys from saves made before free key placement ({"z": keycode}).
var legacy_skill_keys = {}
func defaults() -> Dictionary: return DEFAULTS.duplicate()
func current() -> Dictionary: return bindings.duplicate()
func apply(new_bindings: Dictionary) -> bool:
    var proposed={}
    var legacy={}
    for key in new_bindings:
        if not (key is String or key is StringName): return false
        var action=str(key)
        if action.begins_with("skill_"): legacy[action.trim_prefix("skill_")]=new_bindings[key]
        elif not DEFAULTS.has(action): return false
        else: proposed[action]=new_bindings[key]
    # Older backups lack newer actions. Keep their custom keys and give each
    # missing action its default or a free key.
    for action in ["move_left","move_right","interact","jump","attack","menu"]:
        if not proposed.has(action): return false
    var taken=[]
    for value in proposed.values(): taken.append(int(value) if value is float else value)
    for value in legacy.values(): taken.append(int(value) if value is float else value)
    for action in DEFAULTS:
        if proposed.has(action): continue
        var code=DEFAULTS[action]
        if taken.has(code):
            code=0 if not REQUIRED.has(action) else -1
            for alternative in [KEY_B,KEY_N,KEY_J,KEY_U,KEY_O,KEY_P,KEY_H,KEY_L,KEY_Q,KEY_W,KEY_E,KEY_R,KEY_T,KEY_Y,KEY_G,KEY_1,KEY_2,KEY_3,KEY_4]:
                if not taken.has(alternative):
                    code=alternative
                    break
        proposed[action]=code
        taken.append(code)
    var used: Array = []
    for action in DEFAULTS:
        var code = proposed[action]
        if not (code is int or code is float) or code != int(code) or code < 0 or code > 0x1ffffff: return false
        if code==0:
            if REQUIRED.has(action): return false
            continue
        if used.has(int(code)): return false
        used.append(int(code))
    bindings.clear()
    legacy_skill_keys={}
    for slot in legacy: legacy_skill_keys[slot]=int(legacy[slot])
    for action in DEFAULTS:
        bindings[action] = int(proposed[action])
        if not InputMap.has_action(action): InputMap.add_action(action)
        InputMap.action_erase_events(action)
        if bindings[action]==0: continue
        var event = InputEventKey.new()
        event.physical_keycode = bindings[action]
        InputMap.action_add_event(action,event)
    return true
func rebind(action: String, code: int) -> bool:
    if not bindings.has(action): return false
    var proposed = current()
    proposed[action] = code
    return apply(proposed)
# The action on a key, or "".
func action_on(code: int) -> String:
    for action in bindings:
        if bindings[action]==code and code!=0: return action
    return ""
