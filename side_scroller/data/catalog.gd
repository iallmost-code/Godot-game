extends RefCounted
# Classic job tree: Beginner -> 1st (Lv 10, Magician Lv 8) -> 2nd (Lv 30) -> 3rd (Lv 70) -> 4th (Lv 120).
# Skill numbers given as [rank 1, max rank] scale linearly; see value().
const MAX_LEVEL=200
const SLOTS=["z","x","c","v","a","d","f"]
const ARCHETYPES=["warrior","magician","bowman","thief"]
const RENAMES={"three_snails":"Shell Toss","recovery":"Second Wind","nimble_feet":"Quickstep",
    "power_strike":"Heavy Blow","slash_blast":"Cleave","iron_body":"Steel Skin","improved_hp_recovery":"Battle Recovery","improved_maxhp":"Toughness","endure_warrior":"Grit",
    "sword_booster":"Blade Tempo","page_booster":"Blade Tempo","spear_booster":"Spear Tempo","bow_booster":"Bow Tempo","crossbow_booster":"Crossbow Tempo","claw_booster":"Claw Tempo","dagger_booster":"Dagger Tempo",
    "sword_mastery":"Blade Discipline","page_mastery":"Blade Discipline","spear_mastery":"Spear Discipline","bow_mastery":"Bow Discipline","crossbow_mastery":"Crossbow Discipline","claw_mastery":"Claw Discipline","dagger_mastery":"Dagger Discipline",
    "rage":"Bloodlust","combo_attack":"Momentum","panic":"Shatterblow","coma":"Concussion","shout":"War Cry","armor_crash":"Sunder","brandish":"Twin Reaver","advanced_combo":"Unstoppable Momentum","enrage":"Fury Unleashed",
    "threaten":"Intimidate","charge_blow":"Charged Smite","fire_charge":"Flame Brand","ice_charge":"Frost Brand","lightning_charge":"Storm Brand","magic_crash":"Spellbreaker","blast":"Judgment","holy_charge":"Radiant Brand","heavens_hammer":"Hammer of Dawn","advanced_charge":"Brand Mastery",
    "iron_will":"Bulwark","hyper_body":"Titan's Vigor","spear_crusher":"Impaling Flurry","dragon_fury":"Wyrm Sweep","dragon_roar":"Wyrm's Roar","dragon_blood":"Wyrmblood","sacrifice":"Blood Price","power_crash":"Armor Breaker","berserk":"Last Stand","beholder":"Dread Eye","aura_of_the_beholder":"Eye's Mending","hex_of_the_beholder":"Eye's Malice",
    "energy_bolt":"Arcane Bolt","magic_claw":"Spell Talons","magic_guard":"Mana Shield","magic_armor":"Runic Ward","improved_mp_recovery":"Mana Flow","improved_maxmp":"Deep Reserves",
    "fire_arrow":"Flame Dart","poison_breath":"Toxic Breath","explosion":"Combustion","poison_mist":"Plague Fog","element_composition_fp":"Cinderblight","meteor_shower":"Starfall","paralyze":"Numbing Toxin","fire_demon":"Hellbrand","elquines":"Frost Wisp",
    "cold_beam":"Frost Lance","thunderbolt":"Thunderclap","ice_strike":"Glacial Spike","thunder_spear":"Storm Javelin","element_composition_il":"Frostshock","blizzard":"Whiteout","chain_lightning":"Arc Lightning","ice_demon":"Rimebrand","ifrit":"Ember Djinn",
    "heal":"Mending Light","bless":"Benediction","invincible":"Sanctity","holy_arrow":"Sacred Bolt","shining_ray":"Radiance","holy_symbol":"Sign of Wisdom","mystic_door":"Wayshrine","dispel":"Purify","doom":"Wither","summon_dragon":"Light Drake","genesis":"Dawnfall","angel_ray":"Seraph's Ray","bahamut":"Sun Wyrm","resurrection":"Rebirth","holy_shield":"Sanctuary",
    "arrow_blow":"Power Shot","double_shot":"Twin Shot","focus":"Steady Aim","critical_shot":"Keen Shot","eye_of_amazon":"Far Sight","blessing_of_amazon":"Hunter's Instinct",
    "arrow_bomb":"Blast Arrow","arrow_rain":"Arrow Storm","inferno":"Flame Arrow","silver_hawk":"Silverwing","hurricane":"Tempest Volley","dragons_breath":"Gale Burst","phoenix":"Firebird","hamstring":"Crippling Shot","concentrate":"Focus Fire","bow_expert":"Bow Grandmaster",
    "iron_arrow":"Piercing Bolt","arrow_eruption":"Bolt Eruption","blizzard_sniper":"Frost Bolt","golden_eagle":"Goldwing","snipe":"Deadshot","piercing_arrow":"Rail Bolt","frostprey":"Rimehawk","blind":"Blinding Bolt","marksman_boost":"Crossbow Grandmaster",
    "lucky_seven":"Double Toss","double_stab":"Twin Fang","disorder":"Distract","dark_sight":"Vanish","nimble_body":"Light Feet","keen_eyes":"Long Reach",
    "drain":"Leeching Star","critical_throw":"Vital Throw","avenger":"Grand Shuriken","flash_jump":"Shadow Leap","shadow_meso":"Coin Barrage","shadow_web":"Shadow Snare","alchemist":"Herbalism","meso_up":"Fortune","triple_throw":"Triple Toss","shadow_stars":"Night Stars","ninja_storm":"Shadow Gale","venomous_star":"Toxic Stars",
    "savage_blow":"Frenzy Cuts","steal":"Pilfer","band_of_thieves":"Gang Ambush","assaulter":"Lunging Strike","meso_explosion":"Coin Burst","meso_guard":"Gold Ward","pickpocket":"Light Fingers","chakra":"Inner Focus","boomerang_step":"Ricochet Step","assassinate":"Execute","smokescreen":"Smoke Bomb","venomous_stab":"Toxic Edge"}
# Families shared by several jobs, matched by id prefix.
const FAMILY_NAMES={"maple_warrior_":"Legend's Resolve","heros_will_":"Unbroken Will","achilles_":"Unyielding","rush_":"Onslaught","monster_magnet_":"Gravity Grip","power_stance_":"Rooted Stance","guardian_":"Aegis","power_guard_":"Iron Riposte","final_attack_":"Follow-Through",
    "meditation_":"Clarity","slow_":"Hinder","teleport_":"Blink","mp_eater_":"Mana Siphon","seal_":"Silence","spell_booster_":"Quickcast","element_amplification_":"Overcharge","infinity_":"Boundless","mana_reflection_":"Spell Mirror","big_bang_":"Singularity",
    "soul_arrow_":"Spirit Quiver","power_knockback_":"Recoil Shot","puppet_":"Scarecrow","mortal_blow_":"Killing Shot","thrust_":"Swiftfoot","sharp_eyes_":"Eagle Eye","strafe_":"Rapid Fire",
    "haste_":"Swiftness","endure_":"Toughened","shadow_partner_":"Shadow Twin","ninja_ambush_":"Hidden Blades","taunt_":"Mock","shadow_shifter_":"Slip"}
# [level, prefix, weapon attack, armor defense]
const BANDS=[[10,"Dewdrop",22,3],[30,"Ironbark",40,12],[50,"Cinderforged",52,16],[70,"Frostwrought",66,21],[90,"Clockwork",80,26],[110,"Bonecarved",94,32],[130,"Wyrmscale",108,38],[150,"Starforged",122,45],[170,"Gloamsteel",136,52]]
static var _skills={}
static var _jobs={}
static var _items={}

static func value(v,rank: int,max_rank: int) -> float:
    if v is Array:
        if max_rank<=1: return float(v[1])
        return lerpf(float(v[0]),float(v[1]),clampf(float(rank-1)/float(max_rank-1),0.0,1.0))
    return float(v)

static func jobs() -> Dictionary:
    if not _jobs.is_empty(): return _jobs
    var j={}
    j.beginner={"name":"Novice","tier":0,"level":1,"path":"","parent":""}
    var tree=[
        # id, name, tier, level, path, parent, weapon, reward
        ["warrior","Squire",1,10,"warrior","beginner","sword","warrior_sword"],
        ["fighter","Duelist",2,30,"warrior","warrior","sword","fighter_weapon"],
        ["crusader","Warlord",3,70,"warrior","fighter","sword","crusader_weapon"],
        ["hero","Champion",4,120,"warrior","crusader","sword","hero_weapon"],
        ["page","Shieldbearer",2,30,"warrior","warrior","sword","page_weapon"],
        ["white_knight","Runeknight",3,70,"warrior","page","sword","white_knight_weapon"],
        ["paladin","Templar",4,120,"warrior","white_knight","sword","paladin_weapon"],
        ["spearman","Lancer",2,30,"warrior","warrior","spear","job_spear"],
        ["dragon_knight","Wyrm Knight",3,70,"warrior","spearman","spear","dragon_knight_weapon"],
        ["dark_knight","Dread Knight",4,120,"warrior","dragon_knight","spear","dark_knight_weapon"],
        ["magician","Initiate",1,8,"magician","beginner","staff","magician_weapon"],
        ["fp_wizard","Ember Adept",2,30,"magician","magician","staff","fp_wizard_weapon"],
        ["fp_mage","Cinder Magus",3,70,"magician","fp_wizard","staff","fp_mage_weapon"],
        ["fp_arch_mage","Inferno Archon",4,120,"magician","fp_mage","staff","fp_arch_mage_weapon"],
        ["il_wizard","Frost Adept",2,30,"magician","magician","staff","il_wizard_weapon"],
        ["il_mage","Storm Magus",3,70,"magician","il_wizard","staff","il_mage_weapon"],
        ["il_arch_mage","Tempest Archon",4,120,"magician","il_mage","staff","il_arch_mage_weapon"],
        ["cleric","Acolyte",2,30,"magician","magician","staff","cleric_weapon"],
        ["priest","Oracle",3,70,"magician","cleric","staff","priest_weapon"],
        ["bishop","Hierarch",4,120,"magician","priest","staff","bishop_weapon"],
        ["archer","Scout",1,10,"bowman","beginner","bow","archer_weapon"],
        ["hunter","Tracker",2,30,"bowman","archer","bow","hunter_weapon"],
        ["ranger","Falconer",3,70,"bowman","hunter","bow","ranger_weapon"],
        ["bowmaster","Windmaster",4,120,"bowman","ranger","bow","bowmaster_weapon"],
        ["crossbowman","Arbalist",2,30,"bowman","archer","crossbow","crossbowman_weapon"],
        ["sniper","Deadeye",3,70,"bowman","crossbowman","crossbow","sniper_weapon"],
        ["marksman","Sharpshooter",4,120,"bowman","sniper","crossbow","marksman_weapon"],
        ["thief","Prowler",1,10,"thief","beginner","claw","thief_claw"],
        ["assassin","Stalker",2,30,"thief","thief","claw","assassin_weapon"],
        ["hermit","Shadeweaver",3,70,"thief","assassin","claw","hermit_weapon"],
        ["night_lord","Nightblade",4,120,"thief","hermit","claw","night_lord_weapon"],
        ["bandit","Brigand",2,30,"thief","thief","dagger","bandit_weapon"],
        ["chief_bandit","Cutthroat",3,70,"thief","bandit","dagger","chief_bandit_weapon"],
        ["shadower","Duskreaper",4,120,"thief","chief_bandit","dagger","shadower_weapon"]]
    for row in tree:
        j[row[0]]={"name":row[1],"tier":row[2],"level":row[3],"path":row[4],"parent":row[5],"weapon":row[6],"reward":row[7]}
    _jobs=j
    return j

static func first_job(archetype: String) -> String:
    return {"warrior":"warrior","magician":"magician","bowman":"archer","thief":"thief"}.get(archetype,"")

static func items() -> Dictionary:
    if not _items.is_empty(): return _items
    var icons={"sword":"⚔","spear":"♜","claw":"✦","dagger":"🗡","staff":"✧","bow":"➶","crossbow":"⤞"}
    var paths={"sword":"warrior","spear":"warrior","claw":"thief","dagger":"thief","staff":"magician","bow":"bowman","crossbow":"bowman"}
    var nouns={"sword":"Sword","spear":"Spear","claw":"Claw","dagger":"Dagger","staff":"Staff","bow":"Bow","crossbow":"Crossbow"}
    var i={}
    var add=func(id,name,type,attack): i[id]={"name":name,"slot":"weapon","path":paths[type],"weapon":type,"attack":attack,"defense":0,"icon":icons[type]}
    add.call("starter_sword","Trail Sword","sword",18)
    add.call("starter_spear","Oak Spear","spear",18)
    add.call("starter_claw","Moonlit Claw","claw",18)
    add.call("starter_staff","Willow Wand","staff",18)
    add.call("starter_bow","Ashwood Bow","bow",18)
    add.call("warrior_sword","Elowen's Sword","sword",25)
    add.call("thief_claw","Elowen's Shadow Claw","claw",25)
    add.call("job_spear","Elowen's Spear","spear",30)
    add.call("forest_sword","Windsteel Sword","sword",28)
    add.call("forest_spear","Windsteel Spear","spear",24)
    add.call("forest_claw","Nightwind Claw","claw",30)
    add.call("forest_dagger","Windsteel Dagger","dagger",27)
    add.call("forest_staff","Mossheart Staff","staff",28)
    add.call("forest_bow","Windstring Bow","bow",28)
    add.call("forest_crossbow","Windlock Crossbow","crossbow",29)
    add.call("briar_sword","Briarsteel Sword","sword",36)
    add.call("briar_spear","Briarsteel Spear","spear",38)
    add.call("briar_claw","Thornweave Claw","claw",38)
    add.call("briar_dagger","Thornfang Dagger","dagger",37)
    add.call("briar_staff","Thornroot Staff","staff",37)
    add.call("briar_bow","Thornstring Bow","bow",37)
    add.call("briar_crossbow","Thornlock Crossbow","crossbow",38)
    add.call("warden_sword","Rootwarden's Edge","sword",50)
    add.call("warden_spear","Rootwarden's Lance","spear",50)
    add.call("warden_claw","Rootwarden's Talon","claw",50)
    add.call("warden_dagger","Rootwarden's Fang","dagger",50)
    add.call("warden_staff","Rootwarden's Branch","staff",50)
    add.call("warden_bow","Rootwarden's Longbow","bow",50)
    add.call("warden_crossbow","Rootwarden's Arbalest","crossbow",50)
    var tier_attack={1:25,2:34,3:62,4:95}
    for id in jobs():
        var job=jobs()[id]
        if job.tier==0 or i.has(job.reward): continue
        var title=("Elowen's" if job.tier==1 else job.name+"'s")
        add.call(job.reward,title+" "+nouns[job.weapon],job.weapon,tier_attack[job.tier])
    # Hunting-ground drops in level bands.
    for band in BANDS:
        for type in nouns:
            add.call("%s_lv%d" % [type,band[0]],"%s %s" % [band[1],nouns[type]],type,band[2])
        i["armor_lv%d" % band[0]]={"name":band[1]+" Mail","slot":"armor","attack":0,"defense":band[3],"icon":"◆"}
    i.starter_armor={"name":"Trail Vest","slot":"armor","attack":0,"defense":2,"icon":"◆"}
    i.forest_armor={"name":"Mossguard Coat","slot":"armor","attack":0,"defense":5,"icon":"◆"}
    i.briar_armor={"name":"Briarweave Coat","slot":"armor","attack":0,"defense":9,"icon":"◆"}
    _items=i
    return i

static func skill(id: String) -> Dictionary: return skills().get(id,{})

static func skills() -> Dictionary:
    if not _skills.is_empty(): return _skills
    var s={}
    var put=func(id: String,job: String,name: String,max_rank: int,kind: String,description: String,extra: Dictionary):
        var entry={"name":name,"job":job,"max":max_rank,"kind":kind,"description":description,
            "mana":0,"cooldown":0.0,"power":1.0,"shape":"melee","reach":120,"height":70,"targets":1,"hits":1,
            "count":1,"spread":0.0,"pierce":0,"style":"","element":"","fx":"slash"}
        entry.merge(extra,true)
        entry.active=kind!="passive"
        if not extra.has("cooldown"): entry.cooldown=0.5 if kind=="attack" else 0.0 if kind=="passive" else 1.0
        s[id]=entry
    # ---- Weapon attacks every character has ----
    put.call("basic","","Attack",1,"attack","A quick weapon strike. Always available.",{"power":1.0,"reach":110,"targets":2,"cooldown":0.38})
    put.call("star","","Star Throw",1,"attack","Throw a spinning star. No ammunition needed.",{"shape":"projectile","style":"star","power":1.0,"reach":480,"cooldown":0.38})
    put.call("arrow","","Shoot",1,"attack","Fire a single arrow. No ammunition needed.",{"shape":"projectile","style":"arrow","power":1.0,"reach":520,"cooldown":0.4})
    # ---- Beginner ----
    put.call("three_snails","beginner","Three Snails",3,"attack","Throw a snail shell at the nearest monster ahead.",{"shape":"projectile","style":"snail","power":[0.9,1.6],"reach":360,"mana":2,"cooldown":0.6})
    put.call("recovery","beginner","Recovery",3,"buff","Recover HP over time.",{"stats":{"hp_regen":[3,9]},"duration":30,"cooldown":60,"mana":0})
    put.call("nimble_feet","beginner","Nimble Feet",3,"buff","Run faster for a short time.",{"stats":{"speed":[0.1,0.25]},"duration":[20,40],"cooldown":60,"mana":4})
    # ---- Shared 4th-job skills ----
    for job in ["hero","paladin","dark_knight","fp_arch_mage","il_arch_mage","bishop","bowmaster","marksman","night_lord","shadower"]:
        put.call("maple_warrior_"+job,job,"Maple Warrior",30,"buff","Increases all attributes by a percentage.",{"stats":{"stat_pct":[0.01,0.15]},"duration":[30,900],"mana":[10,70]})
        put.call("heros_will_"+job,job,"Hero's Will",5,"special","Break free of stuns and slows, then resist them briefly.",{"effect":"cure","cooldown":[600,360],"mana":30,"fx":"aura"})
    # ---- WARRIOR ----
    put.call("power_strike","warrior","Power Strike",20,"attack","A single, powerful blow.",{"power":[1.6,2.6],"mana":[4,8],"cooldown":0.45})
    put.call("slash_blast","warrior","Slash Blast",20,"attack","Sweep the weapon to strike up to six monsters in front.",{"power":[0.9,1.3],"reach":170,"targets":6,"mana":[6,12]})
    put.call("iron_body","warrior","Iron Body",20,"buff","Raise defense for a time.",{"stats":{"defense":[3,20]},"duration":[20,150],"mana":[4,12]})
    put.call("improved_hp_recovery","warrior","Improved HP Recovery",16,"passive","Recover more HP over time.",{"stats":{"hp_regen":[1,10]}})
    put.call("improved_maxhp","warrior","Improved MaxHP Increase",10,"passive","Raise maximum HP.",{"stats":{"max_hp_pct":[0.02,0.2]}})
    put.call("endure_warrior","warrior","Endure",8,"passive","Shrug off pain and keep recovering HP.",{"stats":{"hp_regen":[0.5,4]}})
    var booster=func(id,job,name): put.call(id,job,name,20,"buff","Raise attack speed for a time.",{"stats":{"attack_speed":[0.08,0.22]},"duration":[30,200],"mana":[20,10]})
    var mastery=func(id,job,name): put.call(id,job,name,20,"passive","Raise weapon mastery and accuracy for steadier damage.",{"stats":{"mastery":[0.03,0.2],"attack":[1,10]}})
    var final_attack=func(id,job): put.call(id,job,"Final Attack",30,"passive","Chance to strike an extra time after an attack.",{"stats":{"final_attack":[0.05,0.4]}})
    var power_guard=func(id,job): put.call(id,job,"Power Guard",30,"buff","Reflect part of each hit back at the attacker.",{"stats":{"reflect":[0.1,0.4]},"duration":[30,180],"mana":[10,25]})
    # Fighter -> Crusader -> Hero
    put.call("rage","fighter","Rage",20,"buff","Fury raises attack power.",{"stats":{"attack":[2,25]},"duration":[40,160],"mana":[6,15]})
    power_guard.call("power_guard_fighter","fighter")
    booster.call("sword_booster","fighter","Sword Booster")
    mastery.call("sword_mastery","fighter","Sword Mastery")
    final_attack.call("final_attack_fighter","fighter")
    put.call("combo_attack","crusader","Combo Attack",30,"buff","Each attack builds a combo orb that raises damage. Panic, Coma and Enrage spend them.",{"stats":{"orb_bonus":[0.02,0.06]},"group":"combo","duration":[20,200],"mana":[10,20]})
    put.call("panic","crusader","Panic",30,"attack","Spend combo orbs on a crushing blow that may blind.",{"needs_combo":true,"power":[2.5,4.5],"mana":[16,24],"status":{"id":"blind","chance":[0.4,0.8],"time":6}})
    put.call("coma","crusader","Coma",30,"attack","Spend combo orbs to strike six monsters and stun them.",{"needs_combo":true,"power":[1.6,2.8],"reach":170,"targets":6,"mana":[16,24],"status":{"id":"stun","chance":[0.4,0.8],"time":[2,4]}})
    put.call("shout","crusader","Shout",30,"attack","A battle cry that damages and stuns monsters on both sides.",{"shape":"area","both":true,"reach":180,"targets":6,"power":[0.8,1.6],"mana":[10,20],"cooldown":2.0,"fx":"burst","status":{"id":"stun","chance":[0.4,0.85],"time":[1,3]}})
    put.call("armor_crash","crusader","Armor Crash",20,"attack","Shatter monster armor so they take more damage.",{"shape":"area","reach":220,"targets":6,"power":0.0,"mana":15,"cooldown":4.0,"fx":"burst","status":{"id":"armor_break","chance":1.0,"time":[10,40]}})
    put.call("brandish","hero","Brandish",30,"attack","Two mighty slashes against up to three monsters.",{"power":[1.4,2.6],"reach":180,"targets":3,"hits":2,"mana":[16,26]})
    put.call("advanced_combo","hero","Advanced Combo",30,"passive","Hold up to ten combo orbs and build them faster.",{"requires":"combo_attack","stats":{"combo_max":[6,10],"combo_double":[0.05,0.5]}})
    put.call("enrage","hero","Enrage",30,"buff","Spend combo orbs to unleash greatly increased damage.",{"needs_combo":true,"stats":{"damage_pct":[0.1,0.4]},"duration":[30,120],"mana":20,"cooldown":2.0})
    # Page -> White Knight -> Paladin
    put.call("threaten","page","Threaten",20,"attack","Intimidate monsters on both sides, weakening their attacks.",{"shape":"area","both":true,"reach":220,"targets":6,"power":0.0,"mana":14,"cooldown":3.0,"fx":"burst","status":{"id":"weaken","chance":[0.5,0.95],"time":[10,40]}})
    power_guard.call("power_guard_page","page")
    booster.call("page_booster","page","Sword Booster")
    mastery.call("page_mastery","page","Sword Mastery")
    final_attack.call("final_attack_page","page")
    put.call("charge_blow","white_knight","Charge Blow",30,"attack","Release your elemental charge in a stunning blow.",{"needs_charge":true,"power":[1.5,3.2],"mana":20,"status":{"id":"stun","chance":[0.3,0.7],"time":2}})
    for e in [["fire_charge","Fire Charge","fire",{}],["ice_charge","Ice Charge","ice",{"on_hit":{"id":"freeze","chance":[0.1,0.3],"time":2}}],["lightning_charge","Lightning Charge","lightning",{"damage_pct":[0.04,0.08]}]]:
        var stats={"damage_pct":[0.1,0.4],"charge":1.0}
        var extra={"stats":stats,"group":"charge","element":e[2],"duration":[30,180],"mana":[10,20],"fx":"aura"}
        if e[3].has("on_hit"): extra.on_hit=e[3].on_hit
        if e[3].has("damage_pct"): stats.damage_pct=[0.14,0.48]
        put.call(e[0],"white_knight",e[1],30,"buff","Charge your weapon with "+e[2]+". Only one charge at a time.",extra)
    put.call("magic_crash","white_knight","Magic Crash",20,"attack","Break monster protections so they take more damage.",{"shape":"area","both":true,"reach":260,"targets":6,"power":0.0,"mana":20,"cooldown":5.0,"fx":"burst","status":{"id":"armor_break","chance":[0.3,0.8],"time":[10,30]}})
    put.call("blast","paladin","Blast",30,"attack","An overwhelming single strike.",{"power":[2.5,5.0],"reach":140,"mana":[18,30],"cooldown":0.6})
    put.call("holy_charge","paladin","Holy Charge",30,"buff","Charge your weapon with holy power.",{"stats":{"damage_pct":[0.15,0.5],"charge":1.0},"group":"charge","element":"holy","duration":[30,180],"mana":[14,24],"fx":"aura"})
    put.call("heavens_hammer","paladin","Heaven's Hammer",30,"attack","Call down a hammer of light on everything ahead.",{"shape":"drop","reach":380,"height":160,"targets":15,"power":[2.0,4.0],"mana":40,"cooldown":6.0,"element":"holy","fx":"rain","status":{"id":"stun","chance":0.6,"time":1}})
    put.call("advanced_charge","paladin","Advanced Charge",30,"passive","Charges hit harder and Charge Blow may keep your charge.",{"requires":"holy_charge","stats":{"charge_bonus":[0.02,0.2],"charge_keep":[0.05,0.9]}})
    # Spearman -> Dragon Knight -> Dark Knight
    put.call("iron_will","spearman","Iron Will",20,"buff","Raise defense for a time.",{"stats":{"defense":[5,30]},"duration":[20,200],"mana":[10,20]})
    put.call("hyper_body","spearman","Hyper Body",30,"buff","Greatly raise maximum HP and MP.",{"stats":{"max_hp_pct":[0.02,0.6],"max_mp_pct":[0.02,0.6]},"duration":[20,200],"mana":[10,40]})
    booster.call("spear_booster","spearman","Spear Booster")
    mastery.call("spear_mastery","spearman","Spear Mastery")
    final_attack.call("final_attack_spearman","spearman")
    put.call("spear_crusher","dragon_knight","Spear Crusher",30,"attack","Three rapid thrusts against up to three monsters.",{"power":[0.9,1.7],"reach":160,"targets":3,"hits":3,"mana":[12,20],"fx":"thrust"})
    put.call("dragon_fury","dragon_knight","Dragon Fury",30,"attack","A sweeping dragon-shaped wave hits monsters ahead.",{"power":[1.2,2.2],"reach":300,"height":110,"targets":6,"mana":[14,24],"fx":"wave","cooldown":0.55})
    put.call("dragon_roar","dragon_knight","Dragon Roar",30,"attack","A roar that hits everything around you. Costs HP.",{"shape":"area","both":true,"reach":360,"height":140,"targets":15,"power":[1.5,3.0],"hp_cost":0.15,"mana":10,"cooldown":2.5,"fx":"burst"})
    put.call("dragon_blood","dragon_knight","Dragon Blood",20,"buff","Burn your own HP for greater attack power.",{"stats":{"attack":[5,25],"hp_drain":[8,4]},"duration":[30,150],"mana":15})
    put.call("sacrifice","dragon_knight","Sacrifice",30,"attack","Pour your own HP into one devastating strike.",{"power":[2.5,4.5],"reach":150,"hp_cost":[0.05,0.03],"mana":15,"cooldown":0.6,"fx":"thrust"})
    put.call("power_crash","dragon_knight","Power Crash",20,"attack","Break monster armor ahead.",{"shape":"area","reach":260,"targets":6,"power":0.0,"mana":15,"cooldown":4.0,"fx":"burst","status":{"id":"armor_break","chance":[0.3,0.9],"time":[10,30]}})
    put.call("berserk","dark_knight","Berserk",30,"passive","When your HP falls below 40%, deal far more damage.",{"stats":{"berserk":[0.2,1.0]}})
    put.call("beholder","dark_knight","Beholder",30,"summon","Summon a watchful Beholder that follows you.",{"summon":{"style":"beholder","color":"8f6bd8","follow":true,"interval":4.0,"power":0.0,"targets":0,"reach":0},"duration":[60,250],"mana":40,"cooldown":5.0})
    put.call("aura_of_the_beholder","dark_knight","Aura of the Beholder",30,"passive","Your Beholder heals you every few seconds.",{"requires":"beholder","stats":{"beholder_heal":[0.02,0.1]}})
    put.call("hex_of_the_beholder","dark_knight","Hex of the Beholder",30,"passive","Your Beholder attacks nearby monsters.",{"requires":"beholder","stats":{"beholder_power":[1.0,3.0]}})
    for job in ["hero","paladin","dark_knight"]:
        put.call("achilles_"+job,job,"Achilles",30,"passive","Permanently reduce damage taken.",{"stats":{"damage_reduction":[0.02,0.3]}})
        put.call("rush_"+job,job,"Rush",30,"attack","Charge forward, dragging monsters with you.",{"shape":"lunge","lunge":[0.3,0.45],"power":[1.2,2.4],"reach":90,"targets":10,"push":380,"mana":[20,30],"cooldown":3.0,"fx":"thrust"})
        put.call("monster_magnet_"+job,job,"Monster Magnet",30,"attack","Pull distant monsters to you and stun them.",{"shape":"pull","reach":340,"targets":[3,10],"power":[0.6,1.2],"mana":[16,30],"cooldown":3.0,"fx":"burst","status":{"id":"stun","chance":1.0,"time":1}})
        put.call("power_stance_"+job,job,"Power Stance",30,"passive","Chance to ignore knock-back.",{"stats":{"knockback_resist":[0.05,0.9]}})
        if job!="dark_knight": put.call("guardian_"+job,job,"Guardian",30,"passive","Chance to block an attack completely.",{"stats":{"block":[0.04,0.25]}})
    # ---- MAGICIAN ----
    put.call("energy_bolt","magician","Energy Bolt",20,"attack","Fire a bolt of pure magic.",{"shape":"projectile","style":"bolt","element":"neutral","power":[1.3,2.4],"reach":380,"mana":[5,10]})
    put.call("magic_claw","magician","Magic Claw",20,"attack","Rake one monster twice with magic claws.",{"shape":"projectile","style":"bolt","element":"arcane","power":[0.9,1.6],"hits":2,"reach":320,"mana":[8,16]})
    put.call("magic_guard","magician","Magic Guard",20,"buff","Part of each hit drains MP instead of HP.",{"stats":{"magic_guard":[0.15,0.85]},"duration":[30,600],"mana":[8,20],"fx":"aura"})
    put.call("magic_armor","magician","Magic Armor",20,"buff","Raise defense for a time.",{"stats":{"defense":[5,30]},"duration":[30,180],"mana":12,"fx":"aura"})
    put.call("improved_mp_recovery","magician","Improved MP Recovery",16,"passive","Recover more MP over time.",{"stats":{"mp_regen":[0.5,8]}})
    put.call("improved_maxmp","magician","Improved MaxMP Increase",10,"passive","Raise maximum MP.",{"stats":{"max_mp_pct":[0.02,0.2]}})
    var meditation=func(id,job): put.call(id,job,"Meditation",20,"buff","Focus to raise magic attack.",{"stats":{"attack":[3,20]},"duration":[30,240],"mana":14,"fx":"aura"})
    var slow=func(id,job): put.call(id,job,"Slow",20,"attack","Slow monsters on both sides.",{"shape":"area","both":true,"reach":260,"targets":6,"power":0.0,"mana":12,"cooldown":3.0,"fx":"burst","status":{"id":"slow","chance":[0.6,1.0],"time":[5,15]}})
    var teleport=func(id,job): put.call(id,job,"Teleport",20,"move","Instantly blink forward.",{"effect":"teleport","distance":[120,200],"mana":[10,4],"cooldown":0.35,"fx":"aura"})
    var mp_eater=func(id,job): put.call(id,job,"MP Eater",20,"passive","Chance to absorb MP whenever magic hits.",{"stats":{"mp_eater":[0.05,0.3]}})
    var spell_booster=func(id,job): put.call(id,job,"Spell Booster",20,"buff","Cast spells faster.",{"stats":{"attack_speed":[0.05,0.2]},"duration":[30,200],"mana":20,"fx":"aura"})
    var seal=func(id,job): put.call(id,job,"Seal",20,"attack","Seal monsters so they cannot attack.",{"shape":"area","both":true,"reach":260,"targets":6,"power":0.0,"mana":18,"cooldown":4.0,"fx":"burst","status":{"id":"seal","chance":[0.4,0.85],"time":[5,20]}})
    var amplification=func(id,job): put.call(id,job,"Element Amplification",30,"passive","Spells deal more damage but cost more MP.",{"stats":{"damage_pct":[0.05,0.5],"mp_cost_pct":[0.05,0.5]}})
    var infinity=func(id,job): put.call(id,job,"Infinity",30,"buff","For a short time, spells cost no MP.",{"stats":{"mp_cost_pct":-1.0,"damage_pct":[0.05,0.3]},"duration":[10,40],"cooldown":180,"mana":0,"fx":"aura"})
    var reflection=func(id,job): put.call(id,job,"Mana Reflection",30,"buff","Reflect part of each hit back at the attacker.",{"stats":{"reflect":[0.2,0.8]},"duration":60,"mana":30,"fx":"aura"})
    var big_bang=func(id,job,element): put.call(id,job,"Big Bang",30,"attack","Gather magic, then detonate it around you.",{"shape":"area","both":true,"reach":260,"height":150,"targets":15,"power":[3.0,6.5],"windup":0.6,"mana":60,"cooldown":5.0,"element":element,"fx":"burst"})
    # Fire / Poison
    put.call("fire_arrow","fp_wizard","Fire Arrow",30,"attack","Fire a flaming arrow of magic.",{"shape":"projectile","style":"bolt","element":"fire","power":[1.8,3.2],"reach":420,"mana":[10,18],"cooldown":0.55})
    put.call("poison_breath","fp_wizard","Poison Breath",30,"attack","Breathe poison that keeps hurting.",{"shape":"projectile","style":"bolt","element":"poison","power":[1.0,1.8],"reach":360,"mana":12,"cooldown":0.55,"status":{"id":"poison","chance":[0.5,0.9],"time":[4,8]}})
    meditation.call("meditation_fp","fp_wizard")
    slow.call("slow_fp","fp_wizard")
    teleport.call("teleport_fp","fp_wizard")
    mp_eater.call("mp_eater_fp","fp_wizard")
    put.call("explosion","fp_mage","Explosion",30,"attack","Detonate fire around you.",{"shape":"area","both":true,"reach":200,"height":120,"targets":6,"power":[2.0,3.6],"mana":[20,32],"cooldown":0.8,"element":"fire","fx":"burst"})
    put.call("poison_mist","fp_mage","Poison Mist",30,"attack","Spread a poisonous cloud ahead.",{"shape":"area","reach":260,"targets":10,"power":[0.4,0.8],"mana":30,"cooldown":6.0,"element":"poison","fx":"burst","status":{"id":"poison","chance":1.0,"time":[6,12]}})
    put.call("element_composition_fp","fp_mage","Element Composition",30,"attack","Fuse fire and poison into one bolt.",{"shape":"projectile","style":"bolt","element":"fire","power":[2.4,4.0],"reach":420,"mana":26,"cooldown":0.6,"status":{"id":"poison","chance":[0.3,0.6],"time":6}})
    seal.call("seal_fp","fp_mage")
    spell_booster.call("spell_booster_fp","fp_mage")
    amplification.call("element_amplification_fp","fp_mage")
    put.call("meteor_shower","fp_arch_mage","Meteor Shower",30,"attack","Rain meteors on everything ahead.",{"shape":"drop","reach":520,"height":220,"targets":15,"power":[3.0,5.5],"mana":[60,80],"cooldown":2.5,"element":"fire","fx":"rain"})
    put.call("paralyze","fp_arch_mage","Paralyze",30,"attack","A poison bolt that may paralyze.",{"shape":"projectile","style":"bolt","element":"poison","power":[2.4,4.5],"reach":420,"mana":30,"cooldown":0.6,"status":{"id":"stun","chance":[0.4,0.8],"time":2}})
    put.call("fire_demon","fp_arch_mage","Fire Demon",30,"attack","Burn monsters and leave them vulnerable.",{"shape":"projectile","style":"bolt","element":"fire","power":[2.0,3.5],"reach":420,"mana":34,"cooldown":0.8,"status":{"id":"armor_break","chance":[0.5,0.9],"time":15}})
    put.call("elquines","fp_arch_mage","Elquines",30,"summon","Summon an ice spirit that freezes monsters.",{"summon":{"style":"spirit","color":"8fd6ff","follow":true,"interval":2.5,"power":[1.6,3.0],"targets":3,"reach":300,"status":{"id":"freeze","chance":0.4,"time":2}},"duration":[60,200],"mana":40,"cooldown":5.0})
    infinity.call("infinity_fp","fp_arch_mage")
    reflection.call("mana_reflection_fp","fp_arch_mage")
    big_bang.call("big_bang_fp","fp_arch_mage","fire")
    # Ice / Lightning
    put.call("cold_beam","il_wizard","Cold Beam",30,"attack","An icy beam that can freeze.",{"shape":"projectile","style":"bolt","element":"ice","power":[1.6,2.8],"reach":400,"mana":14,"cooldown":0.55,"status":{"id":"freeze","chance":[0.3,0.6],"time":2}})
    put.call("thunderbolt","il_wizard","Thunderbolt",30,"attack","Lightning strikes up to six monsters ahead.",{"shape":"area","reach":300,"targets":6,"power":[1.4,2.6],"mana":16,"cooldown":0.6,"element":"lightning","fx":"lightning"})
    meditation.call("meditation_il","il_wizard")
    slow.call("slow_il","il_wizard")
    teleport.call("teleport_il","il_wizard")
    mp_eater.call("mp_eater_il","il_wizard")
    put.call("ice_strike","il_mage","Ice Strike",30,"attack","Ice erupts around you, freezing monsters.",{"shape":"area","both":true,"reach":260,"height":120,"targets":6,"power":[1.8,3.2],"mana":30,"cooldown":0.8,"element":"ice","fx":"burst","status":{"id":"freeze","chance":[0.6,0.95],"time":2}})
    put.call("thunder_spear","il_mage","Thunder Spear",30,"attack","A spear of lightning that pierces three monsters.",{"shape":"projectile","style":"bolt","element":"lightning","power":[2.4,4.2],"pierce":3,"reach":460,"mana":22,"cooldown":0.6})
    put.call("element_composition_il","il_mage","Element Composition",30,"attack","Fuse ice and lightning into one bolt.",{"shape":"projectile","style":"bolt","element":"ice","power":[2.4,4.0],"reach":420,"mana":26,"cooldown":0.6,"status":{"id":"freeze","chance":[0.3,0.6],"time":2}})
    seal.call("seal_il","il_mage")
    spell_booster.call("spell_booster_il","il_mage")
    amplification.call("element_amplification_il","il_mage")
    put.call("blizzard","il_arch_mage","Blizzard",30,"attack","Bring a freezing storm down ahead.",{"shape":"drop","reach":520,"height":220,"targets":15,"power":[3.0,5.5],"mana":70,"cooldown":2.5,"element":"ice","fx":"rain","status":{"id":"freeze","chance":[0.5,0.8],"time":2}})
    put.call("chain_lightning","il_arch_mage","Chain Lightning",30,"attack","Lightning leaps from monster to monster.",{"shape":"chain","reach":360,"targets":[4,6],"power":[2.6,4.6],"mana":30,"cooldown":0.6,"element":"lightning","fx":"lightning"})
    put.call("ice_demon","il_arch_mage","Ice Demon",30,"attack","Freeze monsters and leave them vulnerable.",{"shape":"projectile","style":"bolt","element":"ice","power":[2.0,3.5],"reach":420,"mana":34,"cooldown":0.8,"status":{"id":"armor_break","chance":[0.5,0.9],"time":15}})
    put.call("ifrit","il_arch_mage","Ifrit",30,"summon","Summon a fire spirit that burns monsters.",{"summon":{"style":"spirit","color":"ff9a5c","follow":true,"interval":2.5,"power":[1.6,3.0],"targets":3,"reach":300,"status":{"id":"poison","chance":0.5,"time":4}},"duration":[60,200],"mana":40,"cooldown":5.0})
    infinity.call("infinity_il","il_arch_mage")
    reflection.call("mana_reflection_il","il_arch_mage")
    big_bang.call("big_bang_il","il_arch_mage","ice")
    # Cleric -> Priest -> Bishop
    put.call("heal","cleric","Heal",30,"heal","Restore HP with holy light that also hurts monsters nearby.",{"heal":[0.1,0.45],"power":[0.6,1.4],"reach":200,"targets":6,"mana":[20,40],"cooldown":1.0,"element":"holy","fx":"heal"})
    put.call("bless","cleric","Bless",20,"buff","Holy blessing raises attack, defense and evasion.",{"stats":{"defense":[3,20],"attack":[1,10],"avoid":[0.01,0.08]},"duration":[30,200],"mana":14,"fx":"aura"})
    put.call("invincible","cleric","Invincible",20,"passive","Permanently reduce damage taken.",{"stats":{"damage_reduction":[0.02,0.3]}})
    put.call("holy_arrow","cleric","Holy Arrow",30,"attack","Fire an arrow of holy light.",{"shape":"projectile","style":"bolt","element":"holy","power":[1.8,3.2],"reach":420,"mana":14,"cooldown":0.55})
    teleport.call("teleport_cleric","cleric")
    mp_eater.call("mp_eater_cleric","cleric")
    put.call("shining_ray","priest","Shining Ray",30,"attack","Holy rays burst around you.",{"shape":"area","both":true,"reach":230,"height":120,"targets":6,"power":[2.0,3.6],"mana":30,"cooldown":0.7,"element":"holy","fx":"burst","status":{"id":"stun","chance":[0.1,0.3],"time":1}})
    put.call("holy_symbol","priest","Holy Symbol",30,"buff","Earn more experience from monsters.",{"stats":{"xp_pct":[0.1,0.5]},"duration":[30,120],"mana":40,"fx":"aura"})
    put.call("mystic_door","priest","Mystic Door",20,"move","Open a door back to town.",{"effect":"door","mana":30,"cooldown":[60,10],"fx":"aura"})
    put.call("dispel","priest","Dispel",10,"attack","Cleanse yourself and weaken monsters around you.",{"shape":"area","both":true,"reach":260,"targets":10,"power":0.0,"effect":"cure","mana":20,"cooldown":5.0,"fx":"burst","status":{"id":"weaken","chance":1.0,"time":[5,15]}})
    put.call("doom","priest","Doom",30,"attack","Turn monsters harmless for a while.",{"shape":"area","both":true,"reach":240,"targets":6,"power":0.0,"mana":25,"cooldown":6.0,"fx":"burst","status":{"id":"doom","chance":[0.4,0.85],"time":[5,15]}})
    put.call("summon_dragon","priest","Summon Dragon",30,"summon","Summon a small holy dragon that attacks monsters.",{"summon":{"style":"dragon","color":"f6e7a0","follow":true,"interval":2.0,"power":[1.6,3.0],"targets":1,"reach":320},"duration":[60,180],"mana":30,"cooldown":5.0})
    put.call("genesis","bishop","Genesis",30,"attack","Holy light falls on everything ahead.",{"shape":"drop","reach":560,"height":220,"targets":15,"power":[3.2,6.0],"mana":70,"cooldown":2.5,"element":"holy","fx":"rain"})
    put.call("angel_ray","bishop","Angel Ray",30,"attack","A piercing ray of holy light.",{"shape":"projectile","style":"bolt","element":"holy","power":[2.6,5.0],"pierce":1,"reach":460,"mana":30,"cooldown":0.6})
    put.call("bahamut","bishop","Bahamut",30,"summon","Summon the great holy dragon Bahamut.",{"summon":{"style":"dragon","color":"fff2b8","follow":true,"interval":2.5,"power":[2.5,4.5],"targets":3,"reach":360},"duration":[60,260],"mana":50,"cooldown":5.0})
    put.call("resurrection","bishop","Resurrection",10,"buff","If you fall while this is active, rise again at half HP.",{"stats":{"revive":1.0},"duration":[60,180],"mana":60,"cooldown":[600,300],"fx":"aura"})
    put.call("holy_shield","bishop","Holy Shield",30,"buff","Holy protection greatly reduces damage and blocks stuns.",{"stats":{"damage_reduction":[0.2,0.6],"status_immune":1.0},"duration":[20,40],"mana":40,"cooldown":[120,60],"fx":"aura"})
    infinity.call("infinity_bishop","bishop")
    big_bang.call("big_bang_bishop","bishop","holy")
    # ---- BOWMAN ----
    put.call("arrow_blow","archer","Arrow Blow",20,"attack","A powerful single arrow.",{"shape":"projectile","style":"arrow","power":[1.4,2.4],"reach":500,"mana":[5,10]})
    put.call("double_shot","archer","Double Shot",20,"attack","Fire two arrows at once.",{"shape":"projectile","style":"arrow","count":2,"power":[0.8,1.4],"reach":500,"mana":[6,12]})
    put.call("focus","archer","Focus",20,"buff","Concentrate to raise critical rate and evasion.",{"stats":{"crit":[0.02,0.1],"avoid":[0.01,0.1]},"duration":[30,240],"mana":10,"fx":"aura"})
    put.call("critical_shot","archer","Critical Shot",20,"passive","Raise critical rate.",{"stats":{"crit":[0.02,0.4]}})
    put.call("eye_of_amazon","archer","The Eye of Amazon",8,"passive","Arrows fly farther.",{"stats":{"reach":[10,80]}})
    put.call("blessing_of_amazon","archer","Blessing of Amazon",16,"passive","Steadier aim raises attack.",{"stats":{"attack":[1,16]}})
    var soul_arrow=func(id,job): put.call(id,job,"Soul Arrow",20,"buff","Spirit arrows strike harder.",{"stats":{"attack":[2,12]},"duration":[60,300],"mana":14,"fx":"aura"})
    var knockback=func(id,job): put.call(id,job,"Power Knock-Back",20,"passive","Arrows knock monsters back.",{"stats":{"knockback":[40,200]}})
    var puppet=func(id,job): put.call(id,job,"Puppet",20,"summon","Place a decoy that lures monsters away.",{"summon":{"style":"puppet","color":"c79a5a","follow":false,"decoy":true,"interval":99.0,"power":0.0,"targets":0,"reach":400},"duration":[30,80],"mana":25,"cooldown":20.0})
    var mortal=func(id,job): put.call(id,job,"Mortal Blow",20,"passive","Point-blank shots may slay a monster outright.",{"stats":{"mortal":[0.02,0.1]}})
    var thrust=func(id,job): put.call(id,job,"Thrust",20,"passive","Move faster.",{"stats":{"speed":[0.02,0.15]}})
    var sharp_eyes=func(id,job): put.call(id,job,"Sharp Eyes",30,"buff","Raise critical rate and critical damage.",{"stats":{"crit":[0.02,0.15],"crit_damage":[0.1,0.4]},"duration":[30,300],"mana":30,"fx":"aura"})
    put.call("arrow_bomb","hunter","Arrow Bomb",30,"attack","An exploding arrow that can stun.",{"shape":"projectile","style":"arrow","element":"fire","power":[1.2,2.2],"splash":90,"targets":6,"reach":480,"mana":14,"status":{"id":"stun","chance":[0.2,0.6],"time":2}})
    booster.call("bow_booster","hunter","Bow Booster")
    mastery.call("bow_mastery","hunter","Bow Mastery")
    final_attack.call("final_attack_hunter","hunter")
    soul_arrow.call("soul_arrow_bow","hunter")
    knockback.call("power_knockback_bow","hunter")
    put.call("arrow_rain","ranger","Arrow Rain",30,"attack","Arrows rain on monsters ahead.",{"shape":"drop","reach":420,"height":180,"targets":6,"power":[1.6,3.0],"mana":30,"cooldown":1.2,"fx":"rain"})
    put.call("strafe_ranger","ranger","Strafe",30,"attack","Fire four arrows in rapid succession.",{"shape":"projectile","style":"arrow","count":4,"power":[0.6,1.2],"reach":500,"mana":20,"cooldown":0.6})
    put.call("inferno","ranger","Inferno",30,"attack","A flaming arrow that bursts and burns.",{"shape":"projectile","style":"arrow","element":"fire","power":[1.8,3.2],"splash":100,"targets":6,"reach":480,"mana":24,"cooldown":0.6,"status":{"id":"poison","chance":0.5,"time":4}})
    put.call("silver_hawk","ranger","Silver Hawk",20,"summon","Summon a hawk that strikes and stuns.",{"summon":{"style":"bird","color":"d9e4ee","follow":true,"interval":2.0,"power":[1.0,2.0],"targets":3,"reach":300,"status":{"id":"stun","chance":0.4,"time":1.5}},"duration":[60,180],"mana":30,"cooldown":5.0})
    puppet.call("puppet_ranger","ranger")
    mortal.call("mortal_blow_ranger","ranger")
    thrust.call("thrust_ranger","ranger")
    put.call("hurricane","bowmaster","Hurricane",30,"attack","Unleash a storm of eight arrows.",{"shape":"projectile","style":"arrow","count":8,"volley_delay":0.04,"power":[0.5,1.0],"reach":560,"mana":20,"cooldown":0.9})
    put.call("dragons_breath","bowmaster","Dragon's Breath",30,"attack","A roaring blast that knocks monsters back.",{"shape":"area","reach":320,"targets":6,"power":[1.4,2.8],"push":260,"mana":30,"cooldown":2.0,"fx":"wave","status":{"id":"stun","chance":0.4,"time":1.5}})
    put.call("phoenix","bowmaster","Phoenix",30,"summon","Summon a phoenix that burns monsters.",{"summon":{"style":"bird","color":"ff9a5c","follow":true,"interval":2.5,"power":[2.0,3.8],"targets":4,"reach":320,"status":{"id":"poison","chance":0.5,"time":4}},"duration":[60,200],"mana":40,"cooldown":5.0})
    sharp_eyes.call("sharp_eyes_bowmaster","bowmaster")
    put.call("hamstring","bowmaster","Hamstring",30,"buff","Your arrows slow monsters.",{"on_hit":{"id":"slow","chance":[0.3,0.7],"time":6},"stats":{"hamstring":1.0},"duration":[30,200],"mana":25,"fx":"aura"})
    put.call("concentrate","bowmaster","Concentrate",30,"buff","Greatly raise damage for a short time.",{"stats":{"damage_pct":[0.1,0.3]},"duration":[20,60],"mana":30,"cooldown":[180,120],"fx":"aura"})
    put.call("bow_expert","bowmaster","Bow Expert",30,"passive","Master the bow for higher attack and steadier damage.",{"stats":{"attack":[2,30],"mastery":[0.02,0.1]}})
    put.call("iron_arrow","crossbowman","Iron Arrow",30,"attack","A heavy bolt that pierces several monsters.",{"shape":"projectile","style":"arrow","power":[1.2,2.2],"pierce":[2,6],"reach":500,"mana":16})
    booster.call("crossbow_booster","crossbowman","Crossbow Booster")
    mastery.call("crossbow_mastery","crossbowman","Crossbow Mastery")
    final_attack.call("final_attack_crossbowman","crossbowman")
    soul_arrow.call("soul_arrow_crossbow","crossbowman")
    knockback.call("power_knockback_crossbow","crossbowman")
    put.call("arrow_eruption","sniper","Arrow Eruption",30,"attack","Arrows burst up from the ground ahead.",{"shape":"area","reach":360,"height":110,"targets":6,"power":[1.6,3.0],"mana":30,"cooldown":1.2,"fx":"rain"})
    put.call("strafe_sniper","sniper","Strafe",30,"attack","Fire four bolts in rapid succession.",{"shape":"projectile","style":"arrow","count":4,"power":[0.6,1.2],"reach":500,"mana":20,"cooldown":0.6})
    put.call("blizzard_sniper","sniper","Blizzard",30,"attack","A frozen bolt that bursts and can freeze.",{"shape":"projectile","style":"arrow","element":"ice","power":[1.8,3.2],"splash":100,"targets":6,"reach":480,"mana":24,"cooldown":0.6,"status":{"id":"freeze","chance":[0.3,0.6],"time":2}})
    put.call("golden_eagle","sniper","Golden Eagle",20,"summon","Summon an eagle that strikes and stuns.",{"summon":{"style":"bird","color":"e7c05a","follow":true,"interval":2.0,"power":[1.0,2.0],"targets":3,"reach":300,"status":{"id":"stun","chance":0.4,"time":1.5}},"duration":[60,180],"mana":30,"cooldown":5.0})
    puppet.call("puppet_sniper","sniper")
    mortal.call("mortal_blow_sniper","sniper")
    thrust.call("thrust_sniper","sniper")
    put.call("snipe","marksman","Snipe",30,"attack","One enormous, perfectly aimed shot.",{"shape":"projectile","style":"arrow","power":[6.0,12.0],"reach":700,"mana":40,"cooldown":[8.0,5.0]})
    put.call("piercing_arrow","marksman","Piercing Arrow",30,"attack","A bolt that pierces every monster in its path.",{"shape":"projectile","style":"arrow","power":[2.0,4.0],"pierce":10,"reach":600,"mana":30,"cooldown":0.8})
    put.call("frostprey","marksman","Frostprey",30,"summon","Summon an ice bird that freezes monsters.",{"summon":{"style":"bird","color":"8fd6ff","follow":true,"interval":2.5,"power":[2.0,3.8],"targets":4,"reach":320,"status":{"id":"freeze","chance":0.5,"time":2}},"duration":[60,200],"mana":40,"cooldown":5.0})
    sharp_eyes.call("sharp_eyes_marksman","marksman")
    put.call("blind","marksman","Blind",30,"buff","Your bolts blind monsters so their attacks miss.",{"on_hit":{"id":"blind","chance":[0.3,0.7],"time":8},"stats":{"blinding":1.0},"duration":[30,200],"mana":25,"fx":"aura"})
    put.call("marksman_boost","marksman","Marksman Boost",30,"passive","Master the crossbow for higher attack and steadier damage.",{"stats":{"attack":[2,30],"mastery":[0.02,0.1]}})
    # ---- THIEF ----
    put.call("lucky_seven","thief","Lucky Seven",20,"attack","Throw two stars at once.",{"shape":"projectile","style":"star","count":2,"power":[1.0,1.6],"reach":480,"mana":[6,12]})
    put.call("double_stab","thief","Double Stab",20,"attack","Stab twice in quick succession.",{"power":[0.9,1.5],"hits":2,"reach":110,"mana":[5,10],"cooldown":0.45})
    put.call("disorder","thief","Disorder",20,"attack","Confuse a monster so its attacks weaken.",{"shape":"area","reach":200,"targets":1,"power":0.0,"mana":10,"cooldown":2.0,"fx":"burst","status":{"id":"weaken","chance":1.0,"time":[10,40]}})
    put.call("dark_sight","thief","Dark Sight",20,"buff","Vanish: monsters cannot see or touch you. Attacking ends it.",{"stats":{"invisible":1.0},"duration":[10,60],"mana":12,"cooldown":2.0,"fx":"aura"})
    put.call("nimble_body","thief","Nimble Body",20,"passive","Raise evasion.",{"stats":{"avoid":[0.01,0.2]}})
    put.call("keen_eyes","thief","Keen Eyes",8,"passive","Thrown stars fly farther.",{"stats":{"reach":[20,120]}})
    var haste=func(id,job): put.call(id,job,"Haste",20,"buff","Move faster and jump higher.",{"stats":{"speed":[0.05,0.25],"jump":[0.03,0.15]},"duration":[20,200],"mana":16,"fx":"aura"})
    var endure=func(id,job): put.call(id,job,"Endure",20,"passive","Keep recovering HP even in battle.",{"stats":{"hp_regen":[1,8]}})
    var partner=func(id,job): put.call(id,job,"Shadow Partner",30,"buff","Your shadow mirrors your attacks at half damage.",{"partner":true,"stats":{"partner":1.0},"duration":[60,180],"mana":[20,30],"cooldown":60.0})
    var ambush=func(id,job): put.call(id,job,"Ninja Ambush",30,"attack","Hidden ninjas poison everything ahead.",{"shape":"area","reach":320,"targets":6,"power":[0.6,1.2],"mana":30,"cooldown":4.0,"fx":"burst","status":{"id":"poison","chance":1.0,"time":6}})
    var taunt=func(id,job): put.call(id,job,"Taunt",30,"attack","Provoke monsters: they take more damage and give more experience.",{"shape":"area","both":true,"reach":300,"targets":10,"power":0.0,"mana":25,"cooldown":6.0,"fx":"burst","status":{"id":"taunt","chance":[0.5,1.0],"time":[20,60]}})
    var shifter=func(id,job): put.call(id,job,"Shadow Shifter",30,"passive","Chance to slip away from any attack.",{"stats":{"avoid":[0.02,0.3]}})
    put.call("drain","assassin","Drain",30,"attack","A star that steals HP from its target.",{"shape":"projectile","style":"star","power":[1.4,2.6],"drain":[0.1,0.3],"reach":480,"mana":14})
    haste.call("haste_assassin","assassin")
    booster.call("claw_booster","assassin","Claw Booster")
    mastery.call("claw_mastery","assassin","Claw Mastery")
    put.call("critical_throw","assassin","Critical Throw",30,"passive","Raise critical rate for thrown stars.",{"stats":{"crit":[0.02,0.5]}})
    endure.call("endure_assassin","assassin")
    put.call("avenger","hermit","Avenger",30,"attack","A giant star that pierces five monsters.",{"shape":"projectile","style":"big_star","power":[2.2,3.8],"pierce":5,"reach":520,"mana":22,"cooldown":0.6})
    partner.call("shadow_partner_hermit","hermit")
    put.call("flash_jump","hermit","Flash Jump",20,"passive","Jump again in midair with a burst of speed.",{"stats":{"flash_jump":[1.1,1.6]}})
    put.call("shadow_meso","hermit","Shadow Meso",30,"attack","Throw coins as a devastating attack. Costs coins.",{"shape":"projectile","style":"coin","power":[3.0,6.0],"coin_cost":[20,60],"reach":420,"mana":20,"cooldown":1.0})
    put.call("shadow_web","hermit","Shadow Web",30,"attack","Bind monsters ahead in a shadow web.",{"shape":"area","reach":280,"targets":6,"power":0.0,"mana":20,"cooldown":4.0,"fx":"burst","status":{"id":"web","chance":1.0,"time":[5,15]}})
    put.call("alchemist","hermit","Alchemist",20,"passive","Potions heal more.",{"stats":{"heal_pct":[0.1,0.6]}})
    put.call("meso_up","hermit","Meso Up",20,"buff","Monsters drop more coins.",{"stats":{"coin_pct":[0.1,1.0]},"duration":120,"mana":30,"fx":"aura"})
    put.call("triple_throw","night_lord","Triple Throw",30,"attack","Throw three stars at once.",{"shape":"projectile","style":"star","count":3,"power":[1.2,2.0],"reach":500,"mana":[16,26]})
    put.call("shadow_stars","night_lord","Shadow Stars",30,"buff","Stars charged with shadow hit harder.",{"stats":{"attack":[10,40]},"duration":[60,200],"mana":30,"fx":"aura"})
    ambush.call("ninja_ambush_nl","night_lord")
    put.call("ninja_storm","night_lord","Ninja Storm",30,"attack","A storm of shadows blasts monsters away.",{"shape":"area","reach":340,"targets":10,"power":[2.0,3.6],"push":300,"mana":40,"cooldown":2.0,"fx":"wave"})
    taunt.call("taunt_nl","night_lord")
    put.call("venomous_star","night_lord","Venomous Star",30,"passive","Stars may poison monsters.",{"on_hit":{"id":"poison","chance":[0.1,0.4],"time":6},"stats":{"venom":1.0}})
    shifter.call("shadow_shifter_nl","night_lord")
    put.call("savage_blow","bandit","Savage Blow",30,"attack","Six lightning-fast dagger strikes.",{"power":[0.4,0.8],"hits":6,"reach":120,"mana":14,"cooldown":0.55})
    put.call("steal","bandit","Steal",30,"attack","A strike that may steal coins or a potion.",{"power":[0.8,1.4],"steal":[0.05,0.4],"reach":120,"mana":14,"cooldown":1.0})
    haste.call("haste_bandit","bandit")
    booster.call("dagger_booster","bandit","Dagger Booster")
    mastery.call("dagger_mastery","bandit","Dagger Mastery")
    endure.call("endure_bandit","bandit")
    put.call("band_of_thieves","chief_bandit","Band of Thieves",30,"attack","Call your gang to strike every monster ahead.",{"shape":"area","reach":300,"targets":6,"power":[1.6,3.0],"mana":24,"cooldown":0.8,"fx":"burst"})
    put.call("assaulter","chief_bandit","Assaulter",30,"attack","Dash through a monster and stun it.",{"shape":"lunge","lunge":[0.28,0.34],"power":[2.2,4.2],"reach":90,"targets":1,"push":120,"mana":24,"cooldown":1.5,"fx":"thrust","status":{"id":"stun","chance":[0.3,0.6],"time":2}})
    put.call("meso_explosion","chief_bandit","Meso Explosion",30,"attack","Detonate coins around you. Costs coins.",{"shape":"area","both":true,"reach":260,"targets":10,"power":[2.6,5.0],"coin_cost":[30,80],"mana":20,"cooldown":1.0,"fx":"burst"})
    put.call("meso_guard","chief_bandit","Meso Guard",30,"buff","Spend coins to soak up part of each hit.",{"stats":{"meso_guard":[0.1,0.5]},"duration":120,"mana":30,"fx":"aura"})
    put.call("pickpocket","chief_bandit","Pickpocket",30,"buff","Your hits shake coins loose from monsters.",{"stats":{"pickpocket":[0.05,0.6]},"duration":120,"mana":20,"fx":"aura"})
    put.call("chakra","chief_bandit","Chakra",30,"heal","Focus your breath to recover HP.",{"heal":[0.1,0.4],"power":0.0,"reach":0,"targets":0,"mana":20,"cooldown":6.0,"fx":"heal"})
    partner.call("shadow_partner_chief","chief_bandit")
    put.call("boomerang_step","shadower","Boomerang Step",30,"attack","Dash forward slashing up to four monsters twice.",{"shape":"lunge","lunge":[0.25,0.3],"power":[2.0,3.6],"reach":100,"targets":4,"hits":2,"mana":26,"cooldown":1.2,"fx":"thrust"})
    put.call("assassinate","shadower","Assassinate",30,"attack","Four lethal strikes. Deals more from Dark Sight.",{"power":[1.6,3.2],"hits":4,"reach":120,"mana":40,"cooldown":4.0})
    put.call("smokescreen","shadower","Smokescreen",30,"buff","Hide in smoke: no attack can touch you.",{"stats":{"invincible":1.0},"duration":[10,30],"mana":40,"cooldown":[180,90],"fx":"aura"})
    ambush.call("ninja_ambush_sh","shadower")
    taunt.call("taunt_sh","shadower")
    put.call("venomous_stab","shadower","Venomous Stab",30,"passive","Dagger strikes may poison monsters.",{"on_hit":{"id":"poison","chance":[0.1,0.4],"time":6},"stats":{"venom":1.0}})
    shifter.call("shadow_shifter_sh","shadower")
    for id in s:
        if RENAMES.has(id): s[id].name=RENAMES[id]
        else:
            for prefix in FAMILY_NAMES:
                if id.begins_with(prefix) and not RENAMES.has(id): s[id].name=FAMILY_NAMES[prefix]
    _skills=s
    return s
