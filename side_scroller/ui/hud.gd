extends CanvasLayer
const Style=preload("res://ui/style.gd")
const Catalog=preload("res://data/catalog.gd")
var state
var combat
var bindings
var hp_bar
var mp_bar
var xp_gain=0
var xp_time=0.0
var xp_text
var xp_bar
var status
var skills: Array=[]
var menu_buttons={}
var travel_buttons={}
var notice
var notice_time=0.0
var map_label
var potion_button
var mana_button
var boss_target
var player
var boss_panel
var boss_label
var boss_bar
var buff_label
var minimap
signal travel_requested(destination: String)
signal town_requested
signal menu_requested(panel_id: String)
const Keymap=preload("res://systems/keymap.gd")
# Hotbar: basic attack, then skills on keys in keyboard order.
const HOTBAR_SIZE=10
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
    minimap=preload("res://ui/minimap.gd").new()
    minimap.position=Vector2(25,76)
    root_control.add_child(minimap)
    var top=HBoxContainer.new()
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    top.position=Vector2(-600,22)
    root_control.add_child(top)
    for id in ["stats","skills","inventory","quests","map"]:
        var menu_button=Style.button(id.capitalize(),func(): menu_requested.emit(id))
        top.add_child(menu_button)
        menu_buttons[id]=menu_button
    top.add_child(Style.button("Menu",func(): menu_requested.emit("controls")))
    var travel=HBoxContainer.new()
    travel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    travel.position=Vector2(-600,62)
    root_control.add_child(travel)
    travel_buttons.travel_town=Style.button("Nearest town [T]",func(): town_requested.emit())
    travel_buttons.travel_hub=Style.button("Portal hub [H]",func(): travel_requested.emit("portal_hub"))
    travel_buttons.menu_map=Style.button("Level guide [M]",func(): menu_requested.emit("map"))
    for button in travel_buttons.values(): travel.add_child(button)
    boss_panel=PanelContainer.new()
    boss_panel.position=Vector2(340,145)
    boss_panel.custom_minimum_size=Vector2(600,60)
    root_control.add_child(boss_panel)
    var boss_layout=VBoxContainer.new()
    boss_panel.add_child(boss_layout)
    boss_label=Style.label("Rootwarden",18,Color("f4d48a"))
    boss_layout.add_child(boss_label)
    boss_bar=create_bar(boss_layout,Color("bd729c"))
    boss_panel.hide()
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
    status=Style.label("",13,Color("f4d48a"))
    status.clip_text=true
    status.custom_minimum_size.x=360
    left.add_child(status)
    hp_bar=create_bar(left,Color("ea8391"))
    mp_bar=create_bar(left,Color("71b7df"))
    xp_bar=create_bar(left,Color("e2c16c"))
    xp_text=Style.label("",11,Color.WHITE)
    xp_text.add_theme_color_override("font_outline_color",Color("49412a"))
    xp_text.add_theme_constant_override("outline_size",2)
    xp_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    xp_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    xp_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
    xp_bar.add_child(xp_text)
    var ability_row=HBoxContainer.new()
    ability_row.add_theme_constant_override("separation",8)
    row.add_child(ability_row)
    ability_row.add_theme_constant_override("separation",4)
    for slot in range(HOTBAR_SIZE):
        var button=Style.button("",func(): show_notice("Put skills on any key in Menu → Keys, or with Set key in the skill book."))
        button.custom_minimum_size=Vector2(66,72)
        button.add_theme_font_size_override("font_size",12)
        button.clip_text=true
        ability_row.add_child(button)
        var icon=preload("res://ui/skill_icon.gd").new()
        icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon.offset_left=3
        icon.offset_right=-3
        icon.offset_top=3
        icon.offset_bottom=-2
        button.add_child(icon)
        skills.append({"slot":slot,"button":button,"icon":icon,"peak":0.0})
    var right=VBoxContainer.new()
    row.add_child(right)
    var potions=HBoxContainer.new()
    potions.add_theme_constant_override("separation",3)
    right.add_child(potions)
    potion_button=Style.button("HP",func():
        show_notice("Health restored." if state.use_potion("hp") else "HP potion unavailable: full HP, cooldown, or none left."))
    potions.add_child(potion_button)
    for button in [potion_button]:
        button.custom_minimum_size=Vector2(70,30)
        button.add_theme_font_size_override("font_size",12)
        button.clip_text=true
    mana_button=Style.button("MP",func():
        show_notice("Mana restored." if state.use_potion("mp") else "MP potion unavailable: full MP, cooldown, or none left."))
    potions.add_child(mana_button)
    mana_button.custom_minimum_size=Vector2(70,30)
    mana_button.add_theme_font_size_override("font_size",12)
    mana_button.clip_text=true
    right.add_child(Style.button("Menu / Save",func(): menu_requested.emit("save")))
    buff_label=Style.label("",14,Color("e8f4ff"))
    buff_label.add_theme_color_override("font_outline_color",Color("254451"))
    buff_label.add_theme_constant_override("outline_size",3)
    buff_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    buff_label.position=Vector2(25,-128)
    root_control.add_child(buff_label)
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
func show_xp(amount: int):
    xp_gain=amount
    xp_time=2.5
func _process(delta):
    xp_time=maxf(0,xp_time-delta)
    notice_time-=delta
    if notice_time<=0: notice.text=""
    refresh()
func refresh():
    if state==null or status==null: return
    if boss_panel!=null:
        var nearby=is_instance_valid(boss_target) and boss_target.hp>0 and player!=null and absf(player.global_position.x-boss_target.global_position.x)<650
        boss_panel.visible=nearby
        if nearby:
            boss_label.text="Lv %d %s  •  %d / %d" % [boss_target.level,boss_target.profile.get("name","Boss") if boss_target.get("profile")!=null else "Rootwarden",boss_target.hp,boss_target.max_hp]
            boss_bar.max_value=boss_target.max_hp
            boss_bar.value=boss_target.hp
    for action in travel_buttons:
        var key=Keymap.key_name(int(bindings.current()[action])) if bindings!=null else ""
        travel_buttons[action].text={"travel_town":"Nearest town","travel_hub":"Portal hub","menu_map":"Level guide"}[action]+" ["+key+"]"
    for id in menu_buttons:
        var shortcut=Keymap.key_name(int(bindings.current()["menu_"+id])) if bindings!=null else ""
        menu_buttons[id].text=id.capitalize()+" ["+shortcut+"]"
    var stats=state.derived_stats()
    status.text="LV %d %s • HP %d/%d • MP %d/%d" % [state.level,Catalog.jobs()[state.job].name,state.hp,stats.max_hp,state.mp,stats.max_mp]
    var parts=[]
    for id in state.buffs:
        parts.append("%s %ds" % [state.skill_name(id),ceili(state.buffs[id].time)])
    if combat.partner_time>0: parts.append("Shadow Twin %ds" % ceili(combat.partner_time))
    for id in combat.summons:
        if is_instance_valid(combat.summons[id]): parts.append("%s %ds" % [state.skill_name(id),ceili(combat.summons[id].lifetime)])
    if state.buff_group("combo")!="": parts.append("Orbs "+"●".repeat(combat.combo_orbs)+"○".repeat(maxi(0,int(maxf(5,state.bonus("combo_max")))-combat.combo_orbs)))
    if player!=null and player.stun_time>0: parts.push_front("STUNNED")
    buff_label.text="  •  ".join(parts)
    hp_bar.max_value=stats.max_hp
    hp_bar.value=state.hp
    mp_bar.max_value=stats.max_mp
    mp_bar.value=state.mp
    xp_bar.max_value=state.xp_required(state.level)
    xp_bar.value=state.xp
    xp_text.text="EXP %d / %d  (%.1f%%)" % [state.xp,state.xp_required(state.level),100.0*state.xp/state.xp_required(state.level)]+("  +%d EXP" % xp_gain if xp_time>0 else "")
    xp_bar.tooltip_text="XP %d / %d  •  %d attribute points available" % [state.xp,state.xp_required(state.level),state.ap]
    var hp_key=Keymap.key_name(int(bindings.current().get("potion_hp",KEY_1))) if bindings!=null else "1"
    var mp_key=Keymap.key_name(int(bindings.current().get("potion_mp",KEY_2))) if bindings!=null else "2"
    potion_button.text="%s HP %d" % [hp_key,state.count_potions("hp")]
    potion_button.tooltip_text="HP potion [%s]: uses the smallest potion that fills your missing health." % hp_key
    potion_button.modulate=Color("819a9c") if state.potion_cooldown>0 else Color.WHITE
    mana_button.text="%s MP %d" % [mp_key,state.count_potions("mp")]
    mana_button.tooltip_text="MP potion [%s]" % mp_key
    var codes=Keymap.skill_keys(state)
    for entry in skills:
        var slot=entry.slot
        var code=0
        var id=""
        if slot==0:
            id=state.basic_skill()
            code=int(bindings.current().get("attack",0)) if bindings!=null else KEY_SPACE
        elif slot-1<codes.size():
            code=codes[slot-1]
            id=state.keys[code]
        var key=Keymap.key_name(code) if code>0 else ""
        var cooldown=combat.cooldowns.get(id,0)
        entry.peak=maxf(entry.peak,cooldown) if cooldown>0 else 0.0
        entry.icon.set_state(id,key,cooldown,entry.peak,state.skill_name(id) if id!="" else "—")
        var cost=combat.mana_cost(id) if id!="" else 0
        entry.button.tooltip_text=(state.skill_name(id)+("  •  %d MP" % cost if cost>0 else "")+"\n"+Catalog.skill(id).get("description","")) if id!="" else "Empty. Put skills on any key in Menu → Keys."
        entry.button.modulate=Color("b8c4c6") if id=="" else Color.WHITE
