extends CanvasLayer
const Style=preload("res://ui/style.gd")
const Catalog=preload("res://data/catalog.gd")
var state
var combat
var bindings
var hp_bar
var mp_bar
var xp_bar
var status
var skills: Array=[]
var notice
var notice_time=0.0
var map_label
var potion_button
signal menu_requested(panel_id: String)
func bind(s,c,b=null):
    state=s
    combat=c
    bindings=b
    layer=10
    var root_control=Control.new()
    root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.mouse_filter=Control.MOUSE_FILTER_IGNORE
    root_control.theme=Style.theme()
    add_child(root_control)
    var brand=Style.label("WINDSWEPT",27,Color("fff5d8"))
    brand.add_theme_color_override("font_outline_color",Color("254451"))
    brand.add_theme_constant_override("outline_size",3)
    brand.position=Vector2(25,18)
    root_control.add_child(brand)
    map_label=Style.label("SPEARBOUND  /  FIRST JOURNEY",13,Color("bbdcda"))
    map_label.add_theme_color_override("font_outline_color",Color("254451"))
    map_label.add_theme_constant_override("outline_size",2)
    map_label.position=Vector2(27,54)
    root_control.add_child(map_label)
    var top=HBoxContainer.new()
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    top.position=Vector2(-410,22)
    root_control.add_child(top)
    for id in ["stats","skills","inventory"]:
        top.add_child(Style.button(id.capitalize(),func(): menu_requested.emit(id)))
    top.add_child(Style.button("Menu",func(): menu_requested.emit("controls")))
    var panel=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top=-100
    root_control.add_child(panel)
    var row=HBoxContainer.new()
    row.add_theme_constant_override("separation",20)
    panel.add_child(row)
    var left=VBoxContainer.new()
    left.custom_minimum_size.x=360
    row.add_child(left)
    status=Style.label("",17,Color("f4d48a"))
    left.add_child(status)
    hp_bar=create_bar(left,Color("ea8391"))
    mp_bar=create_bar(left,Color("71b7df"))
    xp_bar=create_bar(left,Color("e2c16c"))
    var ability_row=HBoxContainer.new()
    ability_row.add_theme_constant_override("separation",8)
    row.add_child(ability_row)
    for slot in ["attack","z","x","c"]:
        var button=Style.button("",func(): show_notice("Use the displayed key to attack. Aim by facing your target."))
        button.custom_minimum_size=Vector2(143,72)
        ability_row.add_child(button)
        skills.append({"slot":slot,"button":button})
    var right=VBoxContainer.new()
    row.add_child(right)
    potion_button=Style.button("Potion",func():
        show_notice("Health restored." if state.use_potion() else "Potion unavailable: full HP, cooldown, or none left."))
    right.add_child(potion_button)
    right.add_child(Style.button("Menu / Save",func(): menu_requested.emit("save")))
    notice=Style.label("",21,Color("fff3ce"))
    notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    notice.position=Vector2(-460,91)
    notice.size=Vector2(920,60)
    notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    notice.add_theme_color_override("font_outline_color",Color("254451"))
    notice.add_theme_constant_override("outline_size",3)
    root_control.add_child(notice)
    state.changed.connect(refresh)
    refresh()
func create_bar(parent,color):
    var bar=ProgressBar.new()
    bar.custom_minimum_size=Vector2(350,16)
    bar.show_percentage=false
    var fill=StyleBoxFlat.new()
    fill.bg_color=color
    fill.set_corner_radius_all(5)
    var back=StyleBoxFlat.new()
    back.bg_color=Color("0f222f")
    back.set_corner_radius_all(5)
    bar.add_theme_stylebox_override("fill",fill)
    bar.add_theme_stylebox_override("background",back)
    parent.add_child(bar)
    return bar
func show_notice(message: String,duration=4.0):
    notice.text=message
    notice_time=duration
func _process(delta):
    notice_time-=delta
    if notice_time<=0: notice.text=""
    refresh()
func refresh():
    if state==null or status==null: return
    var stats=state.derived_stats()
    status.text="LV %d  %s  •  HP %d/%d  MP %d/%d" % [state.level,state.job.capitalize(),state.hp,stats.max_hp,state.mp,stats.max_mp]
    hp_bar.max_value=stats.max_hp
    hp_bar.value=state.hp
    mp_bar.max_value=stats.max_mp
    mp_bar.value=state.mp
    xp_bar.max_value=state.xp_required(state.level)
    xp_bar.value=state.xp
    xp_bar.tooltip_text="XP %d / %d  •  %d attribute points available" % [state.xp,state.xp_required(state.level),state.ap]
    potion_button.text="Potion ×%d%s" % [state.potions," (%.1fs)" % state.potion_cooldown if state.potion_cooldown>0 else ""]
    for entry in skills:
        var slot=entry.slot
        var id=state.basic_skill() if slot=="attack" else state.slots[slot]
        var action="attack" if slot=="attack" else "skill_"+slot
        var key=OS.get_keycode_string(bindings.current()[action]) if bindings!=null else slot.to_upper()
        var cooldown=combat.cooldowns.get(id,0)
        entry.button.text=key+"\n"+(state.skill_name(id) if id!="" else "Unassigned")+("\n%.1fs" % cooldown if cooldown>0 else "")
        entry.button.modulate=Color("819a9c") if id=="" or cooldown>0 else Color.WHITE
