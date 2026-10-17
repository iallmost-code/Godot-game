extends RefCounted
const ART=preload("res://art/combat_atlas.png")
const REGIONS=[Rect2(18,97,358,363),Rect2(396,209,390,133),Rect2(790,123,425,324),Rect2(1215,88,312,370),Rect2(21,543,352,366),Rect2(410,528,262,387),Rect2(730,613,425,256),Rect2(1162,541,370,382)]
static func element_index(element: String) -> int:
    return {"fire":4,"ice":5,"lightning":6,"holy":3,"poison":7,"arcane":7}.get(element,3)
static func draw(canvas: CanvasItem,index: int,rect: Rect2,tint=Color.WHITE):
    canvas.draw_texture_rect_region(ART,rect,REGIONS[clampi(index,0,7)],tint)

# Supplemental sheets keep the original eight numeric regions stable for callers.
const EFFECT_ART_2=preload("res://art/combat_atlas_2.png")
const SUMMON_ART=preload("res://art/summons_atlas.png")
const EFFECTS={
    "rain_fire":Rect2(36,77,262,260),
    "rain_ice":Rect2(341,94,245,252),
    "rain_holy":Rect2(654,58,256,289),
    "rain_arrows":Rect2(964,84,267,262),
    "chain_lightning":Rect2(27,443,272,158),
    "burst_fire":Rect2(340,412,264,228),
    "burst_ice":Rect2(648,450,271,200),
    "burst_lightning":Rect2(971,411,255,232),
    "burst_poison":Rect2(24,702,275,224),
    "burst_holy":Rect2(337,680,272,257),
    "burst_arcane":Rect2(650,689,274,243),
    "buff_aura":Rect2(966,687,270,254),
    "heal_sparkles":Rect2(39,972,255,230),
    "buff_shield":Rect2(335,965,277,240),
    "dark_mist":Rect2(653,970,276,242),
    "star_impact":Rect2(980,968,242,234),
}
const SUMMONS={
    "summon_dragon":{"rect":Rect2(10,90,348,286),"height":49},
    "bahamut":{"rect":Rect2(378,12,408,374),"height":74},
    "silver_hawk":{"rect":Rect2(802,5,356,368),"height":52},
    "golden_eagle":{"rect":Rect2(1174,4,390,380),"height":54},
    "phoenix":{"rect":Rect2(1587,10,391,381),"height":60},
    "frostprey":{"rect":Rect2(5,395,397,368),"height":60},
    "elquines":{"rect":Rect2(475,396,305,374),"height":51},
    "ifrit":{"rect":Rect2(835,388,325,390),"height":56},
    "beholder":{"rect":Rect2(1202,414,392,365),"height":53},
    "puppet_ranger":{"rect":Rect2(1625,397,352,382),"height":80},
    "puppet_sniper":{"rect":Rect2(1625,397,352,382),"height":80},
}
static func draw_named(canvas: CanvasItem,id: String,rect: Rect2,tint=Color.WHITE):
    if EFFECTS.has(id): canvas.draw_texture_rect_region(EFFECT_ART_2,rect,EFFECTS[id],tint)
static func element_for_color(color: Color) -> String:
    var colors={"fire":Color("ff8a4c"),"ice":Color("8fd6ff"),"lightning":Color("f6ef7a"),"poison":Color("9be36b"),"holy":Color("fff2b8"),"arcane":Color("c9a4ff")}
    var closest="arcane"
    var distance=INF
    for id in colors:
        var candidate: Color=colors[id]
        var d=Vector3(color.r,color.g,color.b).distance_squared_to(Vector3(candidate.r,candidate.g,candidate.b))
        if d<distance:
            closest=id
            distance=d
    return closest
