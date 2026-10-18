extends RefCounted
# Maple-style key setup: every key holds an action (attack, jump, potions, menus,
# travel) or one of your skills. Actions live in InputBindings (shared by all
# characters); skills live in CharacterState.keys (per character).
const Catalog=preload("res://data/catalog.gd")
const LABELS={"move_left":"Left","move_right":"Right","move_down":"Down / Climb","interact":"Up / Talk","jump":"Jump","attack":"Attack",
    "potion_hp":"HP Potion","potion_mp":"MP Potion","menu":"Menu","menu_inventory":"Inventory","menu_map":"Map","menu_skills":"Skills",
    "menu_stats":"Stats","menu_quests":"Quests","menu_journey":"Journey","menu_bosses":"Boss Journal","travel_hub":"Portal Hub","travel_town":"Nearest Town"}
const SHORT={"move_left":"←","move_right":"→","move_down":"↓","interact":"↑","jump":"Jump","attack":"Atk","potion_hp":"HP","potion_mp":"MP","menu":"Menu",
    "menu_inventory":"Item","menu_map":"Map","menu_skills":"Skill","menu_stats":"Stat","menu_quests":"Quest","menu_journey":"Jrny","menu_bosses":"Boss","travel_hub":"Hub","travel_town":"Town"}
# Keyboard drawn by the key config window, row by row.
const ROWS=[
    [KEY_ESCAPE,KEY_F1,KEY_F2,KEY_F3,KEY_F4,KEY_F5,KEY_F6,KEY_F7,KEY_F8,KEY_F9,KEY_F10,KEY_F11,KEY_F12],
    [KEY_QUOTELEFT,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0,KEY_MINUS,KEY_EQUAL,KEY_BACKSPACE],
    [KEY_TAB,KEY_Q,KEY_W,KEY_E,KEY_R,KEY_T,KEY_Y,KEY_U,KEY_I,KEY_O,KEY_P,KEY_BRACKETLEFT,KEY_BRACKETRIGHT,KEY_BACKSLASH],
    [KEY_CAPSLOCK,KEY_A,KEY_S,KEY_D,KEY_F,KEY_G,KEY_H,KEY_J,KEY_K,KEY_L,KEY_SEMICOLON,KEY_APOSTROPHE,KEY_ENTER],
    [KEY_SHIFT,KEY_Z,KEY_X,KEY_C,KEY_V,KEY_B,KEY_N,KEY_M,KEY_COMMA,KEY_PERIOD,KEY_SLASH],
    [KEY_CTRL,KEY_ALT,KEY_SPACE,KEY_INSERT,KEY_HOME,KEY_PAGEUP,KEY_DELETE,KEY_END,KEY_PAGEDOWN,KEY_LEFT,KEY_UP,KEY_DOWN,KEY_RIGHT]]
static func key_name(code: int) -> String:
    if code<=0: return "—"
    var names={KEY_QUOTELEFT:"`",KEY_MINUS:"-",KEY_EQUAL:"=",KEY_BRACKETLEFT:"[",KEY_BRACKETRIGHT:"]",KEY_BACKSLASH:"\\",KEY_SEMICOLON:";",KEY_APOSTROPHE:"'",
        KEY_COMMA:",",KEY_PERIOD:".",KEY_SLASH:"/",KEY_ESCAPE:"Esc",KEY_BACKSPACE:"Bksp",KEY_CAPSLOCK:"Caps",KEY_PAGEUP:"PgUp",KEY_PAGEDOWN:"PgDn",
        KEY_INSERT:"Ins",KEY_DELETE:"Del",KEY_LEFT:"←",KEY_RIGHT:"→",KEY_UP:"↑",KEY_DOWN:"↓"}
    return names.get(code,OS.get_keycode_string(code))
# What a key does: {"kind":"action"/"skill"/"", "id":...}.
static func on_key(state,bindings,code: int) -> Dictionary:
    var action=bindings.action_on(code)
    if action!="": return {"kind":"action","id":action}
    if state.keys.has(code): return {"kind":"skill","id":state.keys[code]}
    return {"kind":"","id":""}
# Rebuilds one InputMap action per skill key ("key_<code>").
static func apply_skills(state,bindings=null):
    for action in InputMap.get_actions():
        if str(action).begins_with("key_"): InputMap.erase_action(action)
    for code in state.keys:
        if bindings!=null and bindings.action_on(code)!="": continue
        var action="key_%d" % code
        InputMap.add_action(action)
        var event=InputEventKey.new()
        event.physical_keycode=code
        InputMap.action_add_event(action,event)
# Puts a skill or an action on a key. Returns "" or why it was refused.
static func assign(state,bindings,code: int,kind: String,id: String) -> String:
    if code<=0: return "Pick a key."
    var current=on_key(state,bindings,code)
    if kind=="skill":
        if current.kind=="action":
            if InputBindings.REQUIRED.has(current.id): return "%s needs its key. Move %s to another key first." % [LABELS[current.id],LABELS[current.id]]
            bindings.rebind(current.id,0)
        if not state.assign_key(code,id): return "Learn %s first." % state.skill_name(id)
    elif kind=="action":
        if current.kind=="action" and current.id==id: return ""
        var old=int(bindings.current().get(id,0))
        if current.kind=="skill": state.clear_key(code)
        if current.kind=="action":
            # Swap the two actions' keys.
            if old==0 and InputBindings.REQUIRED.has(current.id): return "%s needs its key. Move it first." % LABELS[current.id]
            var proposed=bindings.current()
            proposed[current.id]=old
            proposed[id]=code
            if not bindings.apply(proposed): return "That key cannot be used."
        elif not bindings.rebind(id,code): return "That key cannot be used."
    apply_skills(state,bindings)
    return ""
# Empties a key. Required actions cannot be removed, only moved.
static func clear(state,bindings,code: int) -> String:
    var current=on_key(state,bindings,code)
    match current.kind:
        "skill": state.clear_key(code)
        "action":
            if InputBindings.REQUIRED.has(current.id): return "%s always needs a key. Put it on another key instead." % LABELS[current.id]
            bindings.rebind(current.id,0)
    apply_skills(state,bindings)
    return ""
# Skill keys in keyboard order, for the hotbar.
static func skill_keys(state) -> Array:
    var order=[]
    for row in ROWS: order.append_array(row)
    var result=state.keys.keys()
    result.sort_custom(func(a,b): return (order.find(a) if order.has(a) else 999)<(order.find(b) if order.has(b) else 999))
    return result
const InputBindings=preload("res://systems/input_bindings.gd")
