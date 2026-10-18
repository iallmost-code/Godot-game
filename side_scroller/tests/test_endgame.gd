extends RefCounted
# Raid bosses, hard-mode rematches and field bosses.
const H=preload("res://tests/helpers.gd")
const Maps=preload("res://data/maps.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
const Raids=preload("res://data/raids.gd")
const Catalog=preload("res://data/catalog.gd")
func run(t):
    var missing=[]
    for boss in Maps.LAIRS:
        var hard=Maps.definition(Maps.boss_arena_id(boss)+"_hard")
        var profile=EnemyStats.profile(boss+"_hard")
        if hard.is_empty() or profile.level!=mini(200,EnemyStats.profile(boss).level+40) or profile.hp<=EnemyStats.profile(boss).hp or not EnemyStats.is_boss(boss+"_hard"): missing.append(boss)
    t.check(missing.is_empty(),"every lair boss has a tougher hard-mode rematch %s" % str(missing))
    for raid in Raids.RAIDS:
        var info=Raids.RAIDS[raid]
        var arena=Maps.definition(Raids.arena_id(raid))
        var gate=Maps.definition(info.town).portals.any(func(p): return p.target==Raids.arena_id(raid))
        var parts_ok=true
        for phase in info.phases:
            for part in phase: parts_ok=parts_ok and EnemyStats.RAID_PARTS.has(part) and EnemyStats.is_boss(part)
        t.check(not arena.is_empty() and gate and parts_ok and Catalog.items().has(Raids.GEAR[info.loot].piece) and Catalog.items().has(info.loot+"_claw"),"%s raid has an arena, a town gate, parts and gear" % info.name)
    t.check(Catalog.items().seraph_halo.req==190 and Catalog.items().tyrant_sword.req==120,"raid gear needs the raid's level")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    await t.process_frame
    game.state.load_record(H.make("thief",["thief","assassin","hermit","night_lord"],130).to_record())
    # A full raid: every phase must fall before the next one starts.
    game.change_map(Raids.arena_id("ember_tyrant"),"entry")
    var map=game.map
    map.raid_delay=0.01
    map._process(0.02)
    t.check(map.raid_phase==0 and map.raid_parts.size()==4 and game.hud.boss_target!=null,"the raid opens with the Tyrant's four arms")
    for part in map.raid_parts.duplicate(): part.receive_hit(part.hp,Vector2.ZERO,1000+part.get_instance_id())
    await t.process_frame
    t.check(map.raid_parts.is_empty() and map.raid_delay>0,"breaking every arm starts the next phase")
    map.raid_delay=0.01
    map._process(0.02)
    t.check(map.raid_phase==1 and map.raid_parts.size()==1 and map.raid_parts[0].definition_id=="ember_tyrant","the Tyrant's body appears in phase two")
    var before=map.pickups.size()
    map.raid_parts[0].receive_hit(map.raid_parts[0].hp,Vector2.ZERO,9999)
    await t.process_frame
    var items=map.pickups.filter(func(d): return is_instance_valid(d) and d.reward.has("item")).map(func(d): return d.reward.item)
    t.check(items.has("tyrant_claw") and items.has("tyrant_eye") and game.state.raid_clears.has("ember_tyrant"),"the raid chest gives raid gear and starts the weekly timer")
    t.check(not Raids.ready(game.state,"ember_tyrant") and Raids.ready(game.state,"ember_tyrant",Time.get_unix_time_from_system()+Raids.WEEK+1),"the chest resets after a week")
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(game.state.to_record()) and copy.raid_clears.has("ember_tyrant"),"weekly raid clears are saved")
    var bad=game.state.to_record()
    bad.raid_clears={"made_up_raid":1}
    t.check(not copy.load_record(bad),"unknown raids in a save are rejected")
    # A second clear in the same week pays coins only.
    game.change_map(Raids.arena_id("ember_tyrant"),"entry")
    map=game.map
    map.raid_phase=0
    map.finish_raid(Vector2(1000,610))
    t.check(not map.pickups.any(func(d): return d.reward.has("item")),"a repeat clear in the same week gives no chest")
    # Field bosses on hunting grounds.
    game.change_map("dewdrop","entry")
    map=game.map
    t.check(map.field_boss_info()[1]=="Old Shellback" and map.field_boss_delay>0,"Dewdrop Meadow's field boss is on its way")
    map.field_boss_delay=0.01
    map._process(0.02)
    var elite=map.field_boss
    var normal=EnemyStats.profile(elite.definition_id)
    t.check(elite!=null and elite.profile.name=="Old Shellback" and elite.max_hp>=normal.hp*30 and game.hud.boss_target==elite,"the field boss spawns big, named and tough")
    elite.receive_hit(elite.hp,Vector2.ZERO,4242)
    await t.process_frame
    t.check(map.pickups.any(func(d): return d.reward.has("item")) and float(map.field_boss_ready.get("dewdrop",0))>Time.get_unix_time_from_system()+500,"field bosses drop gear and return in about ten minutes")
    game.change_map("town","entry")
    game.change_map("dewdrop","entry")
    t.check(game.map.field_boss_delay<0,"a defeated field boss stays gone until its timer is up")
    t.check(Maps.definition("town").get("raid","")=="" and game.map.field_boss_info()!=[] and Maps.definition("frostmere_trail").get("climbs",[]).size()>0,"regional routes have a field boss too")
    game.queue_free()
    await t.process_frame
