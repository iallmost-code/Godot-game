extends RefCounted
# Native source sheets: idle (left), attack (right). Feet are anchored at the bottom.
const DATA={
    "rootwarden":{"file":"res://art/bosses/rootwarden.png","texture":preload("res://art/bosses/rootwarden.png"),"rect":Rect2(37,18,970,752),"attack_rect":Rect2(1048,12,919,757),"foot_anchor":Vector2(522,770),"attack_anchor":Vector2(1507.5,769),"height":150.0,"source_facing":-1},
    "abyssal_leviathan":{"file":"res://art/bosses/abyssal_leviathan.png","texture":preload("res://art/bosses/abyssal_leviathan.png"),"rect":Rect2(32,37,910,791),"attack_rect":Rect2(950,65,876,764),"foot_anchor":Vector2(487.0,828),"attack_anchor":Vector2(1388.0,829),"height":204.0},
    "blight_mother":{"file":"res://art/bosses/blight_mother.png","texture":preload("res://art/bosses/blight_mother.png"),"rect":Rect2(10,6,872,747),"attack_rect":Rect2(1197,6,850,747),"foot_anchor":Vector2(446.0,753),"attack_anchor":Vector2(1622.0,753),"height":216.0},
    "chronovore":{"file":"res://art/bosses/chronovore.png","texture":preload("res://art/bosses/chronovore.png"),"rect":Rect2(24,10,935,766),"attack_rect":Rect2(1006,2,891,802),"foot_anchor":Vector2(491.5,776),"attack_anchor":Vector2(1451.5,804),"height":216.0},
    "crimson_hellwing":{"file":"res://art/bosses/crimson_hellwing.png","texture":preload("res://art/bosses/crimson_hellwing.png"),"rect":Rect2(16,42,957,724),"attack_rect":Rect2(1042,19,932,747),"foot_anchor":Vector2(494.5,766),"attack_anchor":Vector2(1508.0,766),"height":216.0},
    "elder_stumpus":{"file":"res://art/bosses/elder_stumpus.png","texture":preload("res://art/bosses/elder_stumpus.png"),"rect":Rect2(17,26,723,817),"attack_rect":Rect2(786,51,978,792),"foot_anchor":Vector2(378.5,843),"attack_anchor":Vector2(1275.0,843),"height":192.0},
    "gelatinous_monarch":{"file":"res://art/bosses/gelatinous_monarch.png","texture":preload("res://art/bosses/gelatinous_monarch.png"),"rect":Rect2(11,79,769,736),"attack_rect":Rect2(842,109,922,705),"foot_anchor":Vector2(395.5,815),"attack_anchor":Vector2(1303.0,814),"height":204.0},
    "gloam_idol":{"file":"res://art/bosses/gloam_idol.png","texture":preload("res://art/bosses/gloam_idol.png"),"rect":Rect2(36,92,689,684),"attack_rect":Rect2(958,130,803,644),"foot_anchor":Vector2(380.5,776),"attack_anchor":Vector2(1359.5,774),"height":180.0},
    "grand_shellmaw":{"file":"res://art/bosses/grand_shellmaw.png","texture":preload("res://art/bosses/grand_shellmaw.png"),"rect":Rect2(23,123,832,684),"attack_rect":Rect2(901,130,859,682),"foot_anchor":Vector2(439.0,807),"attack_anchor":Vector2(1330.5,812),"height":180.0},
    "lesser_hellwing":{"file":"res://art/bosses/lesser_hellwing.png","texture":preload("res://art/bosses/lesser_hellwing.png"),"rect":Rect2(16,13,933,790),"attack_rect":Rect2(1054,26,879,777),"foot_anchor":Vector2(482.5,803),"attack_anchor":Vector2(1493.5,803),"height":180.0},
    "molten_colossus":{"file":"res://art/bosses/molten_colossus.png","texture":preload("res://art/bosses/molten_colossus.png"),"rect":Rect2(19,16,757,795),"attack_rect":Rect2(886,56,976,755),"foot_anchor":Vector2(397.5,811),"attack_anchor":Vector2(1374.0,811),"height":156.0},
    "mother_cap":{"file":"res://art/bosses/mother_cap.png","texture":preload("res://art/bosses/mother_cap.png"),"rect":Rect2(13,60,762,765),"attack_rect":Rect2(901,67,860,757),"foot_anchor":Vector2(394.0,825),"attack_anchor":Vector2(1331.0,824),"height":216.0},
    "thornscale_wyrm":{"file":"res://art/bosses/thornscale_wyrm.png","texture":preload("res://art/bosses/thornscale_wyrm.png"),"rect":Rect2(18,18,973,741),"attack_rect":Rect2(1037,18,965,741),"foot_anchor":Vector2(504.5,759),"attack_anchor":Vector2(1519.5,759),"height":204.0},
}
static func draw(canvas: CanvasItem,id: String,attacking: bool,facing: int,flash=0.0,frozen=false,offset=Vector2.ZERO) -> bool:
    if not DATA.has(id): return false
    var data=DATA[id]
    var region: Rect2=data.attack_rect if attacking else data.rect
    var anchor: Vector2=(data.attack_anchor if attacking else data.foot_anchor)-region.position
    var factor=float(data.height)/data.rect.size.y
    var tint=Color.WHITE.lerp(Color("bfe9ff"),0.55) if frozen else Color.WHITE
    if flash>0: tint=Color(1.35,1.35,1.35)
    canvas.draw_set_transform(offset,0,Vector2(facing*data.get("source_facing",1),1))
    canvas.draw_texture_rect_region(data.texture,Rect2(-anchor*factor,region.size*factor),region,tint)
    canvas.draw_set_transform(Vector2.ZERO)
    return true
