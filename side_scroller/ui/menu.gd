extends CanvasLayer
const Style=preload("res://ui/style.gd")
var state
var bindings
var root_control
var window_panel
var window_title
var dragging=false
var world_map_id="town"
var player
var tabs_by_id={}
var content
var current_panel
var opened=false
var selected="stats"
signal menu_visibility_changed(open: bool)
signal save_requested
signal export_requested
signal import_requested
signal character_requested(slot: String)
signal binding_changed
func setup(s,b):
    state=s
    bindings=b
    process_mode=Node.PROCESS_MODE_ALWAYS
    layer=20
    root_control=Control.new()
    root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.theme=Style.theme()
    add_child(root_control)
    var shade=ColorRect.new()
    shade.color=Color(0.035,0.075,0.10,0.16)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(shade)
    var panel=PanelContainer.new()
    window_panel=panel
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position=Vector2(-450,-295)
    panel.size=Vector2(900,590)
    root_control.add_child(panel)
    var layout=VBoxContainer.new()
    layout.add_theme_constant_override("separation",7)
    panel.add_child(layout)
    var title_row=HBoxContainer.new()
    layout.add_child(title_row)
    title_row.custom_minimum_size.y=30
    title_row.mouse_filter=Control.MOUSE_FILTER_STOP
    title_row.gui_input.connect(drag_header)
    var title=Style.label("CHARACTER STATS",17,Color("ffffff"))
    window_title=title
    title.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var title_background=StyleBoxFlat.new()
    title_background.bg_color=Color("27323f")
    title_background.set_content_margin_all(6)
    var title_frame=PanelContainer.new()
    title_frame.add_theme_stylebox_override("panel",title_background)
    layout.remove_child(title_row)
    title_frame.add_child(title_row)
    layout.add_child(title_frame)
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title_row.add_child(title)
    var close_button=Style.button("×",close)
    close_button.custom_minimum_size=Vector2(30,28)
    close_button.tooltip_text="Close window (Escape or its shortcut)"
    title_row.add_child(close_button)
    var tabs=HBoxContainer.new()
    layout.add_child(tabs)
    for id in ["stats","skills","inventory","quests","shop","map","controls","characters","save"]:
        var tab=Style.button(id.capitalize(),func(): open_panel(id))
        tabs.add_child(tab)
        tabs_by_id[id]=tab
    var scroll=ScrollContainer.new()
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size.y=450
    layout.add_child(scroll)
    content=VBoxContainer.new()
    content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",7)
    scroll.add_child(content)
    root_control.hide()
func open_panel(id: String):
    if current_panel!=null and selected=="controls": current_panel.capture_action=""
    selected=id
    window_title.text={"stats":"CHARACTER STATS","skills":"SKILL BOOK","inventory":"ITEM INVENTORY","shop":"MERCHANT","map":"WORLD MAP","quests":"QUEST LOG","controls":"KEY SETTINGS","characters":"CHARACTER SELECT","save":"SAVE & BACKUP"}.get(id,id.to_upper())
    for tab_id in tabs_by_id:
        var action="menu_"+tab_id
        var key_name=" ["+OS.get_keycode_string(bindings.current()[action])+"]" if bindings.current().has(action) else ""
        tabs_by_id[tab_id].text=tab_id.capitalize()+key_name
        tabs_by_id[tab_id].modulate=Color("b7d88a") if tab_id==id else Color.WHITE
    opened=true
    root_control.show()
    get_tree().paused=true
    Style.clear(content)
    current_panel=null
    var scripts={"stats":"stats_panel","skills":"skills_panel","inventory":"inventory_panel","shop":"shop_panel","controls":"controls_panel","map":"map_panel","quests":"quest_panel"}
    if scripts.has(id):
        current_panel=load("res://ui/"+scripts[id]+".gd").new()
        content.add_child(current_panel)
        if id=="inventory": current_panel.bind(state)
        else: current_panel.bind(state,bindings)
        if id=="map": current_panel.set_context(world_map_id,player.position if is_instance_valid(player) else Vector2.ZERO)
        if id in ["inventory","shop"]: current_panel.set_context(world_map_id)
        if id=="controls": current_panel.binding_changed.connect(func(): binding_changed.emit())
    elif id=="characters":
        content.add_child(Style.label("YOUR CHARACTERS",24,Color("f4d48a")))
        content.add_child(Style.label("Four independent save slots, one per class. Switching saves your current character.\nStand beside Captain Elowen in town and press Up to advance your job.",16))
        var blurbs={"warrior":"Warrior — Squire at 10 → Duelist / Shieldbearer / Lancer at 30 → 70 → 120.",
            "magician":"Mage — Initiate at 8 → Ember Adept / Frost Adept / Acolyte at 30 → 70 → 120.",
            "bowman":"Archer — Scout at 10 → Tracker / Arbalist at 30 → 70 → 120.",
            "thief":"Thief — Prowler at 10 → Stalker / Brigand at 30 → 70 → 120."}
        for slot in ["warrior","magician","bowman","thief"]:
            var active=state.archetype==slot
            var button=Style.button(("Current: " if active else "Play / Continue: ")+state.archetype_name(slot),func(): character_requested.emit(slot))
            button.disabled=active
            content.add_child(button)
            content.add_child(Style.label(blurbs[slot],14,Color("bfaee5")))
        var style_panel=load("res://ui/style_panel.gd").new()
        content.add_child(style_panel)
        style_panel.bind(state)
    else:
        content.add_child(Style.label("SAVE & BACKUP",24,Color("f4d48a")))
        content.add_child(Style.label("Your character saves locally after progress changes.\nBrowser site data belongs to this browser and can be erased.\nExport a JSON backup before clearing site data or changing devices.
Import a backup into its matching class slot.",18))
        content.add_child(Style.button("Save character now",func(): save_requested.emit()))
        content.add_child(Style.button("Download JSON backup",func(): export_requested.emit()))
        content.add_child(Style.button("Import JSON backup",func(): import_requested.emit()))
    menu_visibility_changed.emit(true)
func close():
    dragging=false
    if current_panel!=null and selected=="controls": current_panel.capture_action=""
    opened=false
    root_control.hide()
    get_tree().paused=false
    menu_visibility_changed.emit(false)
func drag_header(event):
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        dragging=event.pressed
    elif event is InputEventMouseMotion and dragging:
        var target=window_panel.position+event.relative
        var viewport=get_viewport().get_visible_rect().size
        window_panel.position=Vector2(clampf(target.x,8,maxf(8,viewport.x-window_panel.size.x-8)),clampf(target.y,8,maxf(8,viewport.y-window_panel.size.y-8)))
func _unhandled_input(event):
    if not event is InputEventKey or not event.pressed or event.echo: return
    if event.is_action_pressed("menu"):
        if opened: close()
        else: open_panel("stats")
        get_viewport().set_input_as_handled()
        return
    for id in ["inventory","map","skills","stats","quests"]:
        if event.is_action_pressed("menu_"+id):
            if opened and selected==id: close()
            else: open_panel(id)
            get_viewport().set_input_as_handled()
            return
