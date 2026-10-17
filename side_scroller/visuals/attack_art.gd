extends RefCounted
const ART=preload("res://art/combat_atlas.png")
const REGIONS=[Rect2(18,97,358,363),Rect2(396,209,390,133),Rect2(790,123,425,324),Rect2(1215,88,312,370),Rect2(21,543,352,366),Rect2(410,528,262,387),Rect2(730,613,425,256),Rect2(1162,541,370,382)]
static func element_index(element: String) -> int:
    return {"fire":4,"ice":5,"lightning":6,"holy":3,"poison":7,"arcane":7}.get(element,3)
static func draw(canvas: CanvasItem,index: int,rect: Rect2,tint=Color.WHITE):
    canvas.draw_texture_rect_region(ART,rect,REGIONS[clampi(index,0,7)],tint)
