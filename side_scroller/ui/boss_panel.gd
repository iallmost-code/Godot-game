extends VBoxContainer
const Style=preload("res://ui/style.gd")
const C=preload("res://data/catalog.gd")
const Maps=preload("res://data/maps.gd")
const Stats=preload("res://data/enemy_stats.gd")
const Art=preload("res://visuals/boss_layout.gd")
const Q=preload("res://data/loot_quality.gd")
var state
var selected="grand_shellmaw"
signal travel_requested(destination: String)
func bind(s,_b=null):
    state=s
    refresh()
func entries() -> Array:
    var result=["rootwarden"]+Stats.BOSSES.keys()
    result.sort_custom(func(a,b):return Stats.profile(a).level<Stats.profile(b).level)
    return result
func refresh():
    Style.clear(self)
    add_child(Style.section("BOSS JOURNAL / LAIRS & TREASURES"))
    var selector=HFlowContainer.new()
    add_child(selector)
    for id in entries():
        var boss_id=id
        var profile=Stats.profile(id)
        var button=Style.button("%s  Lv %d" % [profile.name,profile.level],func():selected=boss_id;refresh())
        if id==selected:button.modulate=Color("c1dfa2")
        selector.add_child(button)
    var p=Stats.profile(selected)
    add_child(Style.section("%s / LEVEL %d" % [p.name.to_upper(),p.level],true))
    var columns=HBoxContainer.new()
    add_child(columns)
    var portrait=TextureRect.new()
    var texture=AtlasTexture.new()
    texture.atlas=Art.DATA[selected].texture
    texture.region=Art.DATA[selected].rect
    portrait.texture=texture
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.custom_minimum_size=Vector2(200,210)
    columns.add_child(portrait)
    var details=VBoxContainer.new()
    details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    columns.add_child(details)
    var region="town" if selected=="rootwarden" else Maps.LAIRS[selected]
    details.add_child(Style.label("Gate town: "+Maps.definition(region).name,16))
    details.add_child(Style.label("Recommended: level %d+ • Your level: %d" % [p.level,state.level],14))
    details.add_child(Style.label("Reward: "+Q.TROPHIES[selected],16,Q.INK.epic))
    details.add_child(Style.label("Guaranteed epic class weapon + potions and Shards.\nEXP before bonuses: %d" % Stats.experience(selected,p.level),14))
    var patterns=[]
    for pattern in p.get("patterns",["slam","volley"]):
        patterns.append({"slam":"Slam: jump over the ground shockwave","beam":"Low sweep: jump above the warning strip","volley":"Volley: dodge the spread of projectiles","rain":"Rain: move away from marked landing spots","summon":"Summon: clear the supporting monsters","charge":"Charge: jump over the marked rush lane"}.get(pattern,pattern))
    var tactics=Style.label("\n".join(patterns),13)
    tactics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    details.add_child(tactics)
    details.add_child(Style.label("Phases: 100–60% • 60–35% • below 35%.\nLater phases add projectiles and shorten recoveries.",13))
    var arena="briar" if selected=="rootwarden" else Maps.boss_arena_id(selected)
    var warning="Travel to hunting ground" if selected=="rootwarden" else "Travel to gate town"
    details.add_child(Style.button(warning,func():travel_requested.emit(arena)))
    add_child(Style.label("Gear and progress are kept on defeat. Use your potions and watch each telegraph before attacking.",13))
