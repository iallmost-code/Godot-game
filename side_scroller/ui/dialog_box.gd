extends CanvasLayer
# NPC conversation window for quests.
const Style=preload("res://ui/style.gd")
const Quests=preload("res://systems/quests.gd")
var state
var town=""
var npc=""
var quest_id=""
var page=0
var panel: PanelContainer
var body: VBoxContainer
var opened=false
signal closed
signal reward_received(text: String)
func setup(s):
    state=s
    layer=25
    process_mode=Node.PROCESS_MODE_ALWAYS
    var root=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    root.theme=Style.theme()
    add_child(root)
    panel=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    panel.position=Vector2(-330,-370)
    panel.custom_minimum_size=Vector2(660,240)
    root.add_child(panel)
    body=VBoxContainer.new()
    panel.add_child(body)
    panel.hide()
func talk(town_id: String,name: String):
    town=town_id
    npc=name
    quest_id=""
    page=0
    var list=Quests.for_npc(state,town,npc)
    if list.size()==1: quest_id=list[0]
    opened=true
    panel.show()
    get_tree().paused=true
    refresh()
func close():
    opened=false
    panel.hide()
    get_tree().paused=false
    closed.emit()
func pick(id: String):
    quest_id=id
    page=0
    refresh()
func refresh():
    Style.clear(body)
    body.add_child(Style.label(npc.to_upper(),20,Color("536623")))
    var buttons=HBoxContainer.new()
    if quest_id=="":
        var list=Quests.for_npc(state,town,npc)
        if list.is_empty():
            body.add_child(Style.label("Nothing for you right now, friend. Check back after you've grown a bit.",16))
        else:
            body.add_child(Style.label("What can I do for you?",16))
            for id in list:
                var q=Quests.all()[id]
                var tag={"ready":"  ✔ Ready","available":"  (new)","active":"  (in progress)","locked":"  (Lv %d)" % q.min_level}.get(Quests.status(state,id),"")
                var choice=Style.button(q.title+tag,func(): pick(id))
                choice.alignment=HORIZONTAL_ALIGNMENT_LEFT
                body.add_child(choice)
        body.add_child(buttons)
        buttons.add_child(Style.button("Goodbye",close))
        return
    var q=Quests.all()[quest_id]
    var s=Quests.status(state,quest_id)
    body.add_child(Style.label(q.title,15,Color("25758a")))
    match s:
        "available":
            body.add_child(para(q.intro[page]))
            if page<q.intro.size()-1:
                buttons.add_child(Style.button("Next",func(): page+=1; refresh()))
            else:
                body.add_child(Style.label("Reward: "+Quests.reward_text(q.reward),14,Color("7e6539")))
                buttons.add_child(Style.button("Accept",func():
                    Quests.accept(state,quest_id)
                    page=0
                    refresh()))
            buttons.add_child(Style.button("Not now",close))
        "active":
            body.add_child(para(q.progress))
            if q.type!="deliver": body.add_child(Style.label("Progress: %d / %d" % [Quests.progress(state,quest_id),q.count],15,Color("7e6539")))
            buttons.add_child(Style.button("Okay",close))
            buttons.add_child(Style.button("Abandon quest",func():
                Quests.abandon(state,quest_id)
                close()))
        "ready":
            body.add_child(para(q.complete[mini(page,q.complete.size()-1)]))
            if page<q.complete.size()-1:
                buttons.add_child(Style.button("Next",func(): page+=1; refresh()))
            else:
                buttons.add_child(Style.button("Complete quest",func():
                    var reward=Quests.complete(state,quest_id)
                    if reward.is_empty():
                        body.add_child(Style.label("Your bag is full. Make room first.",14,Color("b33a3a")))
                        return
                    reward_received.emit("Quest complete! Received "+Quests.reward_text(reward)+".")
                    quest_id=""
                    page=0
                    refresh()))
        "locked":
            body.add_child(para("I might have work for you later. Come back at level %d." % q.min_level))
            buttons.add_child(Style.button("Okay",close))
        _:
            body.add_child(para("Thanks again for your help!"))
            buttons.add_child(Style.button("Goodbye",close))
    body.add_child(buttons)
func para(text: String) -> Label:
    var label=Style.label(text,17)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size.x=620
    return label
func _unhandled_input(event):
    if opened and event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("menu"):
        close()
        get_viewport().set_input_as_handled()
