extends RefCounted
const DEFAULTS = {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"interact":KEY_UP,"jump":KEY_SHIFT,"attack":KEY_SPACE,"skill_z":KEY_Z,"skill_x":KEY_X,"skill_c":KEY_C,"skill_v":KEY_V,"skill_a":KEY_A,"skill_d":KEY_D,"skill_f":KEY_F,"potion_hp":KEY_1,"potion_mp":KEY_2,"menu":KEY_ESCAPE,"menu_inventory":KEY_I,"menu_map":KEY_M,"menu_skills":KEY_K,"menu_stats":KEY_S}
var bindings = DEFAULTS.duplicate()
func defaults() -> Dictionary: return DEFAULTS.duplicate()
func current() -> Dictionary: return bindings.duplicate()
func apply(new_bindings: Dictionary) -> bool:
    var proposed=new_bindings.duplicate()
    # Older backups lack newer actions (menu shortcuts, extra skill slots). Keep
    # their custom keys and give each missing action its default or a free key.
    var core=["move_left","move_right","interact","jump","attack","skill_z","skill_x","skill_c","menu"]
    for action in core:
        if not proposed.has(action): return false
    for action in proposed:
        if not DEFAULTS.has(action): return false
    var taken=[]
    for value in proposed.values(): taken.append(int(value) if value is float else value)
    for action in DEFAULTS:
        if proposed.has(action): continue
        var code=DEFAULTS[action]
        if taken.has(code):
            for alternative in [KEY_B,KEY_N,KEY_J,KEY_U,KEY_O,KEY_P,KEY_H,KEY_L,KEY_Q,KEY_W,KEY_E,KEY_R,KEY_T,KEY_Y,KEY_G,KEY_1,KEY_2,KEY_3,KEY_4]:
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
