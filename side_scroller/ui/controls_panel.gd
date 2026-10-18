extends VBoxContainer
# Key config: a keyboard where every key can hold an action or a skill.
# Pick something from the lists (or click a key to pick up what is on it), then
# click a key to put it there. Right-click a key to empty it.
const Style=preload("res://ui/style.gd")
const Catalog=preload("res://data/catalog.gd")
const Keymap=preload("res://systems/keymap.gd")
const SkillIcon=preload("res://ui/skill_icon.gd")
var state
var bindings
# Waiting for a key press for this action ("Press a key" flow).
var capture_action=""
# Picked-up item waiting for a key click: {"kind":"action"/"skill","id":...}.
var held={}
var note="Pick an action or skill below, then click a key. Click a key first to move what is on it. Right-click clears a key."
signal binding_changed
func bind(s,b):
    process_mode=Node.PROCESS_MODE_ALWAYS
    state=s
    bindings=b
    refresh()
func start_capture(action: String):
    capture_action=action
    held={}
    note="Press a key for "+Keymap.LABELS.get(action,action)+". Escape cancels."
    refresh()
func _input(event):
    if capture_action=="" or not event is InputEventKey or not event.pressed or event.echo: return
    var code=event.physical_keycode if event.physical_keycode!=0 else event.keycode
    if code==KEY_ESCAPE and capture_action!="menu":
        capture_action=""
        note="Binding capture cancelled."
    else:
        var action=capture_action
        capture_action=""
        place({"kind":"action","id":action},code)
    get_viewport().set_input_as_handled()
    refresh()
func place(item: Dictionary,code: int):
    var problem=Keymap.assign(state,bindings,code,item.kind,item.id)
    if problem!="": note=problem
    else:
        note="%s is now on %s." % [label_for(item),Keymap.key_name(code)]
        binding_changed.emit()
func label_for(item: Dictionary) -> String:
    return Keymap.LABELS.get(item.id,item.id) if item.kind=="action" else state.skill_name(item.id)
func pick(item: Dictionary):
    held=item
    capture_action=""
    note="Holding %s. Click a key to place it." % label_for(item)
    refresh()
func key_clicked(code: int):
    if not held.is_empty():
        var item=held
        held={}
        place(item,code)
    else:
        var on=Keymap.on_key(state,bindings,code)
        if on.kind=="": note="%s is empty. Pick something below first." % Keymap.key_name(code)
        else:
            held=on
            note="Holding %s from %s. Click another key to move it, or right-click a key to clear it." % [label_for(on),Keymap.key_name(code)]
    refresh()
func key_cleared(code: int):
    var problem=Keymap.clear(state,bindings,code)
    note=problem if problem!="" else "%s cleared." % Keymap.key_name(code)
    binding_changed.emit()
    refresh()
func restore_defaults():
    bindings.apply(bindings.defaults())
    Keymap.apply_skills(state,bindings)
    capture_action=""
    held={}
    note="Default action keys restored. Your skills stay on their keys unless a default needed the key."
    binding_changed.emit()
    refresh()
func key_button(code: int) -> Control:
    var on=Keymap.on_key(state,bindings,code)
    var wide={KEY_SPACE:150,KEY_SHIFT:84,KEY_ENTER:76,KEY_BACKSPACE:70,KEY_TAB:62,KEY_CAPSLOCK:70,KEY_CTRL:62,KEY_ALT:56}.get(code,52)
    var button=Button.new()
    button.focus_mode=Control.FOCUS_NONE
    button.custom_minimum_size=Vector2(wide,50)
    button.tooltip_text=Keymap.key_name(code)+": "+(label_for(on) if on.kind!="" else "empty")
    button.pressed.connect(func(): key_clicked(code))
    button.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: key_cleared(code))
    var colour=Color("e8f0f5")
    if on.kind=="action": colour=Color("d9e9c4") if not Keymap.InputBindings.REQUIRED.has(on.id) else Color("cfdcef")
    elif on.kind=="skill": colour=Color("2a3a48")
    if not held.is_empty() and held.kind==on.kind and held.id==on.id: colour=Color("ffe39a")
    button.add_theme_stylebox_override("normal",Style.box(colour,Color("9cabb7"),4,2))
    button.add_theme_stylebox_override("hover",Style.box(colour.lightened(0.15),Color("4f8fbf"),4,2))
    if on.kind=="skill":
        var icon=SkillIcon.new()
        icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon.offset_left=4
        icon.offset_right=-4
        icon.offset_top=3
        icon.offset_bottom=-3
        icon.set_state(on.id,Keymap.key_name(code))
        button.add_child(icon)
    else:
        var short=Keymap.SHORT.get(on.id,"") if on.kind=="action" else ""
        button.text=Keymap.key_name(code)+("\n"+short if short!="" and short!=Keymap.key_name(code) else "")
        button.add_theme_font_size_override("font_size",11)
    return button
func refresh():
    Style.clear(self)
    add_child(Style.label("KEY CONFIG",22,Color("f4d48a")))
    var hint=Style.label(note,14,Color("25758a"))
    hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    hint.custom_minimum_size.x=840
    add_child(hint)
    var board=VBoxContainer.new()
    board.add_theme_constant_override("separation",3)
    add_child(board)
    for row in Keymap.ROWS:
        var line=HBoxContainer.new()
        line.add_theme_constant_override("separation",3)
        board.add_child(line)
        for code in row: line.add_child(key_button(code))
    add_child(Style.section("ACTIONS  —  click one, then click a key",true))
    var actions=HFlowContainer.new()
    add_child(actions)
    for action in bindings.current():
        var item={"kind":"action","id":action}
        var text="%s  [%s]" % [Keymap.LABELS.get(action,action),Keymap.key_name(int(bindings.current()[action]))]
        var button=Style.button("Press a key…" if capture_action==action else text,func(): pick(item))
        button.add_theme_font_size_override("font_size",13)
        if held.get("id","")==action: button.modulate=Color("ffe39a")
        actions.add_child(button)
    add_child(Style.section("SKILLS  —  click one, then click a key",true))
    var skills=HFlowContainer.new()
    add_child(skills)
    var any=false
    for id in Catalog.skills():
        var skill=Catalog.skill(id)
        if skill.job=="" or not skill.active or not state.can_use(id): continue
        any=true
        var item={"kind":"skill","id":id}
        var code=state.key_of(id)
        var button=Style.button("",func(): pick(item))
        button.custom_minimum_size=Vector2(150,44)
        button.tooltip_text=skill.name+"\n"+skill.get("description","")
        var icon=SkillIcon.new()
        icon.custom_minimum_size=Vector2(36,36)
        icon.position=Vector2(4,4)
        icon.size=Vector2(36,36)
        icon.set_state(id)
        button.add_child(icon)
        var text=Style.label(state.skill_name(id)+"\n"+("on "+Keymap.key_name(code) if code!=0 else "not on a key"),11)
        text.position=Vector2(44,4)
        text.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(text)
        if held.get("id","")==id: button.modulate=Color("ffe39a")
        skills.add_child(button)
    if not any: add_child(Style.label("Learn active skills in the Skill Book (K) first.",14))
    add_child(Style.button("Restore default action keys",restore_defaults))
