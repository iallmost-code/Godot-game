extends VBoxContainer
const Style=preload("res://ui/style.gd")
var bindings
var capture_action=""
var note="Click a binding, then press its new key. Escape cancels."
signal binding_changed
func bind(_s,b):
    process_mode=Node.PROCESS_MODE_ALWAYS
    bindings=b
    refresh()
func start_capture(action: String):
    capture_action=action
    note="Press a key for "+action.replace("_"," ")+". Escape cancels."
    refresh()
func _input(event):
    if capture_action=="" or not event is InputEventKey or not event.pressed or event.echo: return
    var code=event.physical_keycode if event.physical_keycode!=0 else event.keycode
    if code==KEY_ESCAPE:
        capture_action=""
        note="Binding capture cancelled."
    elif bindings.rebind(capture_action,code):
        capture_action=""
        note="Binding saved."
        binding_changed.emit()
    else:
        note="That key is already assigned. Choose another key or Escape."
    get_viewport().set_input_as_handled()
    refresh()
func restore_defaults():
    bindings.apply(bindings.defaults())
    capture_action=""
    note="Default controls restored."
    binding_changed.emit()
    refresh()
func set_audio(music: float,effects: float,shake=true):
    var sound=get_tree().get_first_node_in_group("soundscape")
    if sound!=null:sound.set_levels(music,effects,shake)
func audio_controls():
    var sound=get_tree().get_first_node_in_group("soundscape")
    if sound==null:return
    add_child(Style.section("SOUND & COMBAT FEEDBACK"))
    for key in ["music","effects"]:
        var row=HBoxContainer.new()
        add_child(row)
        var label=Style.label(key.capitalize()+" volume",14)
        label.custom_minimum_size.x=160
        row.add_child(label)
        var slider=HSlider.new()
        slider.custom_minimum_size=Vector2(280,26)
        slider.min_value=0
        slider.max_value=1
        slider.step=.05
        slider.value=sound.music_volume if key=="music" else sound.effects_volume
        row.add_child(slider)
        slider.value_changed.connect(func(value):
            set_audio(value if key=="music" else sound.music_volume,value if key=="effects" else sound.effects_volume,sound.shake_enabled))
    var shake=CheckButton.new()
    shake.text="Gentle combat camera shake"
    shake.button_pressed=sound.shake_enabled
    shake.toggled.connect(func(value): set_audio(sound.music_volume,sound.effects_volume,value))
    add_child(shake)
func refresh():
    Style.clear(self)
    add_child(Style.label("CONTROLS",24,Color("f4d48a")))
    audio_controls()
    for action in bindings.current():
        var row=HBoxContainer.new()
        add_child(row)
        var text=Style.label(action.replace("_"," ").capitalize())
        text.custom_minimum_size.x=300
        row.add_child(text)
        var key_name=OS.get_keycode_string(bindings.current()[action])
        row.add_child(Style.button("Press a key…" if capture_action==action else key_name,func(): start_capture(action)))
    add_child(Style.label(note,15,Color("e8cf8e")))
    add_child(Style.button("Restore defaults",restore_defaults))
