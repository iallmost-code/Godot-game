extends CanvasLayer
# Full-screen title / character lobby. Gameplay and save slots stay in main.gd.
const Style=preload("res://ui/style.gd")
const Character=preload("res://systems/character_state.gd")
const Catalog=preload("res://data/catalog.gd")
const CLASSES=["warrior","magician","bowman","thief"]
const BLURBS={"warrior":"Swords, shields and spears.\nA sturdy first adventure.","magician":"Fire, frost and holy magic.\nPowerful spells and summons.","bowman":"Bows and crossbows.\nPrecision, range and companions.","thief":"Throwing stars or daggers.\nSpeed, shadows and sharp strikes."}
var game
var root_control: Control
var body: Control
var sky: TextureRect
var note_label: Label
var mode="title"
var opened=false
var selected="warrior"
var portraits: Array=[]
var cached={}
var settings_panel
var age=0.0
var session_started=false
func setup(owner_game):
    game=owner_game
    process_mode=Node.PROCESS_MODE_ALWAYS
    layer=40
    root_control=Control.new()
    root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.theme=Style.theme()
    add_child(root_control)
    sky=TextureRect.new()
    sky.texture=preload("res://art/sky.png")
    sky.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    sky.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sky.offset_left=-24
    sky.offset_right=24
    root_control.add_child(sky)
    var shade=ColorRect.new()
    shade.color=Color(.035,.09,.16,.60)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(shade)
    scenery(Rect2(74,10,622,634),Rect2(-90,240,480,490),.35)
    scenery(Rect2(782,56,724,583),Rect2(810,355,465,375),.6)
    body=Control.new()
    body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(body)
    root_control.hide()
func scenery(region: Rect2,rect: Rect2,alpha: float):
    var art=TextureRect.new()
    var atlas=AtlasTexture.new()
    atlas.atlas=preload("res://art/props.png")
    atlas.region=region
    art.texture=atlas
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.position=rect.position
    art.size=rect.size
    art.modulate=Color(1,1,1,alpha)
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    root_control.add_child(art)
func summaries() -> Dictionary:
    var result={}
    for slot in CLASSES:
        var path=game.save_store.slot_paths[slot]
        var exists=FileAccess.file_exists(path)
        var info={"exists":exists,"valid":not exists,"level":1,"job":"New adventurer","class":Character.archetype_name(slot)}
        if exists:
            var file=FileAccess.open(path,FileAccess.READ)
            if file!=null and file.get_length()<=1048576:
                var parser=JSON.new()
                var record=parser.data if parser.parse(file.get_as_text())==OK else null
                if record is Dictionary and (record.get("version",0)==1 or record.get("version",0)==2) and record.get("character") is Dictionary and record.get("bindings") is Dictionary:
                    var trial=Character.new()
                    if trial.load_record(record.character) and trial.archetype==slot:
                        info.valid=true
                        info.level=trial.level
                        info.job=trial.job_name()
                        info.character=trial
            if not info.valid:info.job="Save needs recovery"
        result[slot]=info
    return result
func open_title():
    selected=game.state.archetype
    cached=summaries()
    opened=true
    root_control.show()
    get_tree().paused=true
    show_title()
func prepare(next_mode: String):
    mode=next_mode
    opened=true
    root_control.show()
    get_tree().paused=true
    portraits.clear()
    settings_panel=null
    Style.clear(body)
    note_label=Style.label("",14,Color("ffe3a3"))
    note_label.position=Vector2(80,672)
    note_label.size=Vector2(1120,36)
    note_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    body.add_child(note_label)
func heading(title: String,subtitle: String):
    var label=Style.label(title,42,Color("fff4d0"))
    label.position=Vector2(80,48)
    label.add_theme_color_override("font_outline_color",Color("223746"))
    label.add_theme_constant_override("outline_size",4)
    body.add_child(label)
    var sub=Style.label(subtitle,16,Color("e5eef1"))
    sub.position=Vector2(82,106)
    body.add_child(sub)
func action(text: String,callback: Callable,primary=false) -> Button:
    var button=Style.button(text,callback)
    button.custom_minimum_size.y=48
    button.add_theme_font_size_override("font_size",18)
    if primary:
        button.add_theme_stylebox_override("normal",Style.box(Color("eed38e"),Color("a78745"),6,12))
        button.add_theme_stylebox_override("hover",Style.box(Color("ffe7a9"),Color("b08b43"),6,12))
    return button
func show_title():
    cached=summaries()
    prepare("title")
    var logo=Style.label("WINDSWEPT",78,Color("fff0c1"))
    logo.position=Vector2(88,158)
    logo.add_theme_constant_override("outline_size",8)
    logo.add_theme_color_override("font_outline_color",Color("263d4d"))
    body.add_child(logo)
    var caption=Style.label("A small beginning. A world of adventures.",22,Color("edf4ec"))
    caption.position=Vector2(95,260)
    body.add_child(caption)
    var hint=Style.label("Four classes • Towns, treasures and towering bosses\nYour next journey starts here.",17,Color("cadfe4"))
    hint.position=Vector2(97,310)
    body.add_child(hint)
    var cast=HBoxContainer.new()
    cast.position=Vector2(110,390)
    cast.add_theme_constant_override("separation",18)
    body.add_child(cast)
    for slot in CLASSES:cast.add_child(portrait(slot,Vector2(130,140)))
    var panel=PanelContainer.new()
    panel.position=Vector2(855,160)
    panel.size=Vector2(335,390)
    body.add_child(panel)
    var buttons=VBoxContainer.new()
    buttons.add_theme_constant_override("separation",12)
    panel.add_child(buttons)
    buttons.add_child(Style.section("YOUR ADVENTURE"))
    var info=cached[game.state.archetype]
    var continuation=action("Continue",resume_game,true)
    continuation.disabled=not can_continue()
    buttons.add_child(continuation)
    var saved=Style.label("Lv %d %s" % [info.level,info.job] if info.exists and info.valid else "Choose a class to begin.",14)
    saved.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    buttons.add_child(saved)
    buttons.add_child(action("Character Select",show_characters))
    buttons.add_child(action("Settings",show_settings))
    buttons.add_child(action("How to Play",show_help))
    buttons.add_child(action("Quit" if not OS.has_feature("web") else "Exit",quit_game))
    note_label.text="Enter: continue / choose character • Original world, art and music"
    if game.startup_warning!="":note_label.text=game.startup_warning
func can_continue() -> bool:
    var info=cached.get(game.state.archetype,{})
    return session_started or game.loaded_character and info.get("exists",false) and info.get("valid",false)
func portrait(slot: String,dimensions: Vector2) -> Control:
    var frame=Control.new()
    frame.custom_minimum_size=dimensions
    frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var visual=preload("res://visuals/character_visual.gd").new()
    visual.appearance={"warrior":"warrior","magician":"mage","bowman":"archer","thief":"thief"}[slot]
    frame.add_child(visual)
    visual.position=Vector2(dimensions.x/2,dimensions.y-30)
    visual.scale=Vector2.ONE*1.45
    var info=cached.get(slot,{})
    if info.has("character"):
        visual.looks=info.character.looks
        visual.set_equipment(info.character.equipment.weapon)
        visual.set_worn(info.character)
    else:visual.set_equipment(Character.STARTER[slot])
    portraits.append(visual)
    return frame
func show_characters():
    cached=summaries()
    prepare("characters")
    heading("CHOOSE YOUR CHARACTER","Four independent save slots. Existing characters keep all their progress.")
    var cards=HBoxContainer.new()
    cards.position=Vector2(80,155)
    cards.add_theme_constant_override("separation",15)
    body.add_child(cards)
    for slot in CLASSES:
        var kind=slot
        var info=cached[slot]
        var card=Style.button("",func():choose_slot(kind))
        card.custom_minimum_size=Vector2(269,380)
        card.add_theme_stylebox_override("normal",Style.box(Color("fff5d3") if selected==slot else Color("e7edf0"),Color("ddb75c") if selected==slot else Color("96acb9"),8,10))
        cards.add_child(card)
        var content=VBoxContainer.new()
        content.mouse_filter=Control.MOUSE_FILTER_IGNORE
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        content.offset_left=14
        content.offset_right=-14
        content.offset_top=16
        content.offset_bottom=-12
        card.add_child(content)
        var title=Style.label(info["class"].to_upper(),22)
        title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(title)
        content.add_child(portrait(slot,Vector2(235,160)))
        var status=Style.label("Lv %d • %s" % [info.level,info.job] if info.exists and info.valid else "NEW ADVENTURER" if not info.exists else info.job,15,Color("536623") if info.valid else Color("a83b3b"))
        status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        content.add_child(status)
        var desc=Style.label(BLURBS[slot],15)
        desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        content.add_child(desc)
        var tag=Style.label("SELECTED" if selected==slot else "Click to select",13,Color("536623"))
        tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(tag)
    var controls=HBoxContainer.new()
    controls.position=Vector2(340,567)
    controls.add_theme_constant_override("separation",22)
    body.add_child(controls)
    var back=action("Back",show_title)
    back.custom_minimum_size.x=210
    controls.add_child(back)
    var play=action("Continue "+cached[selected]["class"] if cached[selected].exists else "Start "+cached[selected]["class"],play_selected,true)
    play.custom_minimum_size.x=350
    play.disabled=not cached[selected].valid
    controls.add_child(play)
    note_label.text="Left / Right: select a class • Enter: play • Escape: back"
func choose_slot(slot: String):
    if not CLASSES.has(slot):return
    selected=slot
    show_characters()
func play_selected() -> bool:
    cached=summaries()
    if not cached[selected].valid:
        note_label.text="This save cannot be read. It has not been overwritten. Choose another slot or restore a backup."
        return false
    if selected==game.state.archetype and cached[selected].exists and not game.loaded_character and not session_started:
        if not game.save_store.load_into(game.state,game.bindings):
            note_label.text="Could not load this save. Restore a valid backup before continuing."
            return false
        game.loaded_character=true
        game.protected_startup_save=false
        game.refresh_skill_keys()
    if selected!=game.state.archetype and not game.switch_character(selected):
        note_label.text="Could not load this character. Your current character is kept."
        return false
    session_started=true
    resume_game()
    return true
func resume_game():
    opened=false
    root_control.hide()
    get_tree().paused=false
    session_started=true
func show_settings():
    prepare("settings")
    heading("SETTINGS","Audio, combat feedback and your keyboard layout.")
    var panel=PanelContainer.new()
    panel.position=Vector2(80,150)
    panel.size=Vector2(1120,470)
    body.add_child(panel)
    var scroll=ScrollContainer.new()
    panel.add_child(scroll)
    settings_panel=preload("res://ui/controls_panel.gd").new()
    settings_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    scroll.add_child(settings_panel)
    settings_panel.bind(game.state,game.bindings)
    settings_panel.binding_changed.connect(game.refresh_skill_keys)
    settings_panel.binding_changed.connect(game.persist)
    var back=action("Back",show_title)
    back.position=Vector2(1000,635)
    back.size=Vector2(200,44)
    body.add_child(back)
func show_help():
    prepare("help")
    heading("YOUR FIRST ADVENTURE","Explore, learn skills and grow into your next job.")
    var panel=PanelContainer.new()
    panel.position=Vector2(160,170)
    panel.size=Vector2(960,390)
    body.add_child(panel)
    var text=Style.label("Move with the arrow keys. Shift jumps; press it again for a double jump.\nHold Down and press Jump to descend through a platform.\nPress Up beside a portal, rope or NPC to interact.\n\nSpace attacks. Learn skills in the Skill Book, then assign them to any key.\nM opens the level guide. H visits the town hub; T returns to the nearest town.\nJ shows your character journey. B shows bosses and their rewards.\n\nAdvance your job at levels 10 / 30 / 70 / 120 (Mage starts at 8).\nVisit Captain Elowen in Willowbridge. Inventory and settings are in the menu.\nYour characters save locally; export a backup through Menu → Save.",19)
    text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(text)
    var back=action("Back",show_title)
    back.position=Vector2(500,585)
    back.size=Vector2(280,48)
    body.add_child(back)
func quit_game():
    if session_started and not game.save_store.save(game.state,game.bindings):
        note_label.text="Could not save. Export a backup in game before leaving."
        return
    if OS.has_feature("web"):
        note_label.text="Progress saved. Close this browser tab to exit, or Continue to keep playing."
    else:get_tree().quit()
func _process(delta):
    if not opened:return
    age+=delta
    sky.position.x=-24+sin(age*.09)*12
    for visual in portraits:
        if is_instance_valid(visual):visual.set_pose("idle",1,age)
func _input(event):
    if not opened or not event is InputEventKey:return
    if mode=="settings" and is_instance_valid(settings_panel) and settings_panel.capture_action!="":return
    if event.pressed and not event.echo:
        var key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
        if key==KEY_ESCAPE:
            if mode!="title":show_title()
            elif can_continue():resume_game()
        elif key in [KEY_ENTER,KEY_KP_ENTER]:
            if mode=="characters":play_selected()
            elif mode=="title":
                if can_continue():resume_game()
                else:show_characters()
        elif mode=="characters" and key in [KEY_LEFT,KEY_RIGHT]:
            choose_slot(CLASSES[posmod(CLASSES.find(selected)+(1 if key==KEY_RIGHT else -1),CLASSES.size())])
    get_viewport().set_input_as_handled()

func _exit_tree():
    if opened and get_tree()!=null:get_tree().paused=false
