extends VBoxContainer
# Character looks (hair, colour, face, skin) and pet choice.
const Style=preload("res://ui/style.gd")
const Adventure=preload("res://data/adventure.gd")
var state
func bind(s):
    state=s
    refresh()
func cycle(key: String,step: int):
    var next=state.looks.duplicate()
    match key:
        "hair","face":
            var keys=(Adventure.HAIR if key=="hair" else Adventure.FACES).keys()
            next[key]=keys[posmod(keys.find(next[key])+step,keys.size())]
        "hair_color": next.hair_color=posmod(next.hair_color+step,Adventure.HAIR_COLORS.size())
        "skin": next.skin=posmod(next.skin+step,Adventure.SKINS.size())
    state.set_looks(next)
    refresh()
func choose_pet(id: String):
    state.set_pet(id)
    refresh()
func refresh():
    Style.clear(self)
    add_child(Style.section("LOOKS",true))
    var rows=[["Hair","hair",Adventure.HAIR.get(state.looks.hair,"")],["Hair colour","hair_color",Adventure.HAIR_COLOR_NAMES[state.looks.hair_color]],
        ["Face","face",Adventure.FACES.get(state.looks.face,"")],["Skin","skin",Adventure.SKIN_NAMES[state.looks.skin]]]
    for row in rows:
        var line=HBoxContainer.new()
        add_child(line)
        var name=Style.label(row[0],15)
        name.custom_minimum_size.x=120
        line.add_child(name)
        var key=row[1]
        line.add_child(Style.button("◀",func(): cycle(key,-1)))
        var value=Style.label(row[2],15,Color("25758a"))
        value.custom_minimum_size.x=150
        value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        line.add_child(value)
        line.add_child(Style.button("▶",func(): cycle(key,1)))
        if key in ["hair_color","skin"]:
            var swatch=ColorRect.new()
            swatch.custom_minimum_size=Vector2(28,28)
            swatch.color=(Adventure.HAIR_COLORS if key=="hair_color" else Adventure.SKINS)[state.looks[key]]
            line.add_child(swatch)
    add_child(Style.label("Classic keeps your class's original painted head. Any other hair style uses the face and skin tone you pick.",13,Color("617180")))
    var stage=Control.new()
    stage.custom_minimum_size=Vector2(320,190)
    add_child(stage)
    for i in 2:
        var preview=preload("res://visuals/character_visual.gd").new()
        preview.appearance=preload("res://actors/player.gd").appearance_for(state)
        preview.looks=state.looks
        preview.position=Vector2(90+i*150,175)
        preview.scale=Vector2(2,2)
        stage.add_child(preview)
        preview.set_equipment(state.equipment.weapon)
        preview.set_pose("idle",1 if i==0 else -1,0)
    add_child(Style.section("PETS",true))
    if state.pets.is_empty():
        add_child(Style.label("No pets yet. Town Merchants sell them in the Pets tab. A pet follows you and picks up loot.",14))
        return
    var line=HBoxContainer.new()
    add_child(line)
    var none=Style.button("No pet",func(): choose_pet(""))
    none.modulate=Color("b7d88a") if state.pet=="" else Color.WHITE
    line.add_child(none)
    for id in state.pets:
        var pet_id=id
        var button=Style.button(Adventure.PETS[id].name,func(): choose_pet(pet_id))
        button.modulate=Color("b7d88a") if state.pet==id else Color.WHITE
        line.add_child(button)
