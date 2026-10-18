extends Node
# Original score and effect assets, with locally saved music/SFX sliders.
const TRACKS=["meadow","forest","ocean","snow","clockwork","temple","gloom","sky","battle"]
const EFFECTS=["star","arrow","spell","swing","hit","crit","hurt","loot","epic","level","warning","step"]
const SETTINGS="user://windswept_audio.cfg"
var enabled=true
var music_volume=0.38
var effects_volume=0.65
var shake_enabled=true
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var voices: Array=[]
var streams={}
var last_played={}
var current_track=""
var current_ambience=""
var next_voice=0
var fade: Tween
func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    add_to_group("soundscape")
    music=AudioStreamPlayer.new()
    ambience=AudioStreamPlayer.new()
    add_child(music)
    add_child(ambience)
    for i in range(8):
        var voice=AudioStreamPlayer.new()
        add_child(voice)
        voices.append(voice)
    for name in TRACKS+ ["breeze","drips","whirr"]:
        var stream=load("res://art/audio/"+name+".ogg")
        if stream!=null:
            stream=stream.duplicate()
            stream.loop=true
            streams[name]=stream
    for name in EFFECTS:streams[name]=load("res://art/audio/"+name+".wav")
    if enabled:
        var config=ConfigFile.new()
        if config.load(SETTINGS)==OK:
            music_volume=clampf(float(config.get_value("audio","music",0.38)),0,1)
            effects_volume=clampf(float(config.get_value("audio","effects",0.65)),0,1)
            shake_enabled=bool(config.get_value("audio","shake",true))
    apply_volumes()
static func track_for(biome: String,boss=false) -> String:
    if boss:return "battle"
    if biome in ["beach","ocean","harbor","coast","underwater"]:return "ocean"
    if biome in ["snow","ice"]:return "snow"
    if biome in ["toy","clockwork","city","tech"]:return "clockwork"
    if biome in ["temple","time","ruins","shrine","eastern"]:return "temple"
    if biome in ["cloud","sky"]:return "sky"
    if biome in ["cave","swamp","roots","dungeon","desert","mountain","volcano","highland","dragon"]:return "gloom"
    if biome in ["forest","bamboo","garden","alchemy"]:return "forest"
    return "meadow"
func set_region(biome: String,boss=false):
    var track=track_for(biome,boss)
    var bed="drips" if track=="gloom" else "whirr" if track=="clockwork" else "breeze"
    if bed!=current_ambience:
        current_ambience=bed
        ambience.stream=streams.get(bed)
        if enabled:ambience.play()
    if track==current_track:return
    current_track=track
    if is_instance_valid(fade):fade.kill()
    if not enabled:
        music.stream=streams.get(track)
        return
    fade=create_tween()
    fade.tween_property(music,"volume_db",-60.0,0.25)
    fade.tween_callback(func(): music.stream=streams.get(track);music.play())
    fade.tween_property(music,"volume_db",linear_to_db(maxf(0.001,music_volume)),0.6)
func set_levels(music_level: float,effects_level: float,shake=true):
    music_volume=clampf(music_level,0,1)
    effects_volume=clampf(effects_level,0,1)
    shake_enabled=shake
    if is_instance_valid(fade):fade.kill()
    apply_volumes()
    if enabled:
        var config=ConfigFile.new()
        config.set_value("audio","music",music_volume)
        config.set_value("audio","effects",effects_volume)
        config.set_value("audio","shake",shake_enabled)
        config.save(SETTINGS)
func apply_volumes():
    music.volume_db=linear_to_db(maxf(.001,music_volume))
    music.stream_paused=music_volume<=0
    ambience.volume_db=linear_to_db(maxf(.001,music_volume*.22))
    ambience.stream_paused=music_volume<=0
    for voice in voices:voice.volume_db=linear_to_db(maxf(.001,effects_volume*.55))
func play_effect(kind: String):
    if not enabled or effects_volume<=0 or not streams.has(kind):return
    var now=Time.get_ticks_msec()
    if now-int(last_played.get(kind,-1000))<(180 if kind=="step" else 55):return
    last_played[kind]=now
    var voice=voices[next_voice%voices.size()]
    next_voice+=1
    voice.stream=streams[kind]
    voice.pitch_scale=1.0 if kind in ["level","epic","warning"] else randf_range(.96,1.04)
    voice.play()
