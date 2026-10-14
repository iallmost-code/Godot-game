extends CanvasLayer
const Style=preload("res://ui/style.gd")
var state
var bindings
var root_control
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
    shade.color=Color(0.035,0.075,0.10,0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(shade)
    var panel=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position=Vector2(-450,-300)
    panel.size=Vector2(900,600)
    root_control.add_child(panel)
    var layout=VBoxContainer.new()
    layout.add_theme_constant_override("separation",12)
    panel.add_child(layout)
    var title_row=HBoxContainer.new()
    layout.add_child(title_row)
    var title=Style.label("CHARACTER JOURNAL",24,Color("f4d48a"))
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title_row.add_child(title)
    title_row.add_child(Style.button("Return to game",close))
    var tabs=HBoxContainer.new()
    layout.add_child(tabs)
    for id in ["stats","skills","inventory","controls","characters","save"]:
        tabs.add_child(Style.button(id.capitalize(),func(): open_panel(id)))
    var scroll=ScrollContainer.new()
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size.y=430
    layout.add_child(scroll)
    content=VBoxContainer.new()
    content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",12)
    scroll.add_child(content)
    root_control.hide()
func open_panel(id: String):
    selected=id
    opened=true
    root_control.show()
    get_tree().paused=true
    Style.clear(content)
    current_panel=null
    var scripts={"stats":"stats_panel","skills":"skills_panel","inventory":"inventory_panel","controls":"controls_panel"}
    if scripts.has(id):
        current_panel=load("res://ui/"+scripts[id]+".gd").new()
        content.add_child(current_panel)
        if id=="inventory": current_panel.bind(state)
        else: current_panel.bind(state,bindings)
        if id=="controls": current_panel.binding_changed.connect(func(): binding_changed.emit())
    elif id=="characters":
        content.add_child(Style.label("YOUR CHARACTERS",24,Color("f4d48a")))
        content.add_child(Style.label("Two independent save slots. Switching saves your current character.
A new character starts at level 1; first job advancement is at level 10.
Stand beside Captain Elowen in town and press Up to advance.",17))
        for slot in ["warrior","thief"]:
            var active=state.archetype==slot
            var button=Style.button(("Current: " if active else "Play / Continue: ")+slot.capitalize(),func(): character_requested.emit(slot))
            button.disabled=active
            content.add_child(button)
        content.add_child(Style.label("Warrior: sword combat, lunge, mob pushes; Spearman at level 30.
Thief: claw and throwing stars; Shadow Fan at 10; basic stars increase at each job.
Assassin 30: 2 stars. Hermit 60: 3 stars + Shadow Partner.
Night Lord 100: 4 stars (8 with Shadow Partner).",17,Color("bfaee5")))
    else:
        content.add_child(Style.label("SAVE & BACKUP",24,Color("f4d48a")))
        content.add_child(Style.label("Your character saves locally after progress changes.\nBrowser site data belongs to this browser and can be erased.\nExport a JSON backup before clearing site data or changing devices.
Import a backup into its matching Warrior or Thief character slot.",18))
        content.add_child(Style.button("Save character now",func(): save_requested.emit()))
        content.add_child(Style.button("Download JSON backup",func(): export_requested.emit()))
        content.add_child(Style.button("Import JSON backup",func(): import_requested.emit()))
    menu_visibility_changed.emit(true)
func close():
    if current_panel!=null and selected=="controls": current_panel.capture_action=""
    opened=false
    root_control.hide()
    get_tree().paused=false
    menu_visibility_changed.emit(false)
func _unhandled_input(event):
    if not event.is_action_pressed("menu") or event is InputEventKey and event.echo: return
    if opened: close()
    else: open_panel("stats")
    get_viewport().set_input_as_handled()
