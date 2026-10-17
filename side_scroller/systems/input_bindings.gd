extends RefCounted
const DEFAULTS = {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"interact":KEY_UP,"jump":KEY_SHIFT,"attack":KEY_SPACE,"skill_z":KEY_Z,"skill_x":KEY_X,"skill_c":KEY_C,"menu":KEY_ESCAPE,"menu_inventory":KEY_I,"menu_map":KEY_M,"menu_skills":KEY_K,"menu_stats":KEY_S}
var bindings = DEFAULTS.duplicate()
func defaults() -> Dictionary: return DEFAULTS.duplicate()
func current() -> Dictionary: return bindings.duplicate()
func apply(new_bindings: Dictionary) -> bool:
    var proposed=new_bindings.duplicate()
    var menu_actions=["menu_inventory","menu_map","menu_skills","menu_stats"]
    # Old backups have the original nine actions. Preserve their custom keys,
    # choosing unused shortcuts when a new default conflicts with one of them.
    if proposed.size()==DEFAULTS.size()-menu_actions.size():
        for action in DEFAULTS:
            if action not in menu_actions and not proposed.has(action): return false
        var taken=proposed.values()
        for action in menu_actions:
            var code=DEFAULTS[action]
            if taken.has(code):
                for alternative in [KEY_B,KEY_N,KEY_J,KEY_U,KEY_O,KEY_P,KEY_H,KEY_L,KEY_V,KEY_T,KEY_Y,KEY_R,KEY_E]:
                    if not taken.has(alternative):
                        code=alternative
                        break
            proposed[action]=code
            taken.append(code)
    if proposed.size() != DEFAULTS.size(): return false
    var used: Array = []
    for action in DEFAULTS:
        if not proposed.has(action): return false
        var code = proposed[action]
        if not (code is int or code is float) or code <= 0 or code != int(code) or code > 0x1ffffff or used.has(int(code)): return false
        used.append(int(code))
    bindings.clear()
    for action in DEFAULTS:
        bindings[action] = int(proposed[action])
        if not InputMap.has_action(action): InputMap.add_action(action)
        InputMap.action_erase_events(action)
        var event = InputEventKey.new()
        event.physical_keycode = bindings[action]
        InputMap.action_add_event(action,event)
    return true
func rebind(action: String, code: int) -> bool:
    if not bindings.has(action): return false
    var proposed = current()
    proposed[action] = code
    return apply(proposed)
