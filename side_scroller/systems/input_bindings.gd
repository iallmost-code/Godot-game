extends RefCounted
const DEFAULTS = {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"interact":KEY_UP,"jump":KEY_SHIFT,"attack":KEY_SPACE,"skill_z":KEY_Z,"skill_x":KEY_X,"skill_c":KEY_C,"menu":KEY_ESCAPE}
var bindings = DEFAULTS.duplicate()
func defaults() -> Dictionary: return DEFAULTS.duplicate()
func current() -> Dictionary: return bindings.duplicate()
func apply(new_bindings: Dictionary) -> bool:
    if new_bindings.size() != DEFAULTS.size(): return false
    var used: Array = []
    for action in DEFAULTS:
        if not new_bindings.has(action): return false
        var code = new_bindings[action]
        if not (code is int or code is float) or code <= 0 or code != int(code) or code > 0x1ffffff or used.has(int(code)): return false
        used.append(int(code))
    bindings.clear()
    for action in DEFAULTS:
        bindings[action] = int(new_bindings[action])
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
