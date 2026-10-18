extends RefCounted
# Raid bosses: each phase's parts must all fall before the next phase starts.
# The reward chest pays out once a week per character.
const WEEK=7*24*3600
const RAIDS={
    "ember_tyrant":{"name":"Ember Tyrant","level":120,"town":"frostmere","biome":"highland","loot":"tyrant",
        "phases":[["tyrant_arm_left","tyrant_arm_right","tyrant_arm_low_left","tyrant_arm_low_right"],["ember_tyrant"]],
        "intro":"The Ember Tyrant's four arms rise from the magma. Break them to expose its body."},
    "stormcrown_hydra":{"name":"Stormcrown Hydra","level":160,"town":"wyrmrest","biome":"dragon","loot":"hydra",
        "phases":[["hydra_head_left","hydra_head_right"],["stormcrown_hydra"]],
        "intro":"Two heads guard the Stormcrown Hydra. Sever both and the beast itself descends."},
    "dreaming_seraph":{"name":"Dreaming Seraph","level":190,"town":"hourglass","biome":"temple","loot":"seraph",
        "phases":[["seraph_guardian_dawn","seraph_guardian_dusk","seraph_guardian_star"],["dreaming_seraph"],["seraph_awakened"]],
        "intro":"Three guardians keep the Seraph's dream. Wake her, then survive what she becomes."}}
# Raid-only gear: a weapon for every weapon type plus one armour piece per raid.
const GEAR={"tyrant":{"prefix":"Tyrant's","attack":128,"req":120,"piece":"tyrant_eye"},
    "hydra":{"prefix":"Stormcrown","attack":150,"req":160,"piece":"hydra_cloak"},
    "seraph":{"prefix":"Seraphic","attack":166,"req":190,"piece":"seraph_halo"}}
static func arena_id(raid: String) -> String: return "raid_"+raid
static func ready(state,raid: String,now: float=-1.0) -> bool:
    if now<0: now=Time.get_unix_time_from_system()
    return now-float(state.raid_clears.get(raid,0))>=WEEK
static func days_left(state,raid: String) -> int:
    return maxi(0,ceili((WEEK-(Time.get_unix_time_from_system()-float(state.raid_clears.get(raid,0))))/86400.0))
