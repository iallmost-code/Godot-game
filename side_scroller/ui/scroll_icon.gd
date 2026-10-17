extends Control
# Painted icon for a scroll or quest item.
const Adventure=preload("res://data/adventure.gd")
const UiIcons=preload("res://visuals/ui_icon_layout.gd")
var scroll_id=""
func _init(): mouse_filter=Control.MOUSE_FILTER_IGNORE
static func draw_icon(canvas: CanvasItem,id: String,area: Rect2):
    var key=Adventure.icon_id(id)
    if UiIcons.DATA.has(key): canvas.draw_texture_rect_region(UiIcons.ART,area,UiIcons.DATA[key])
func _draw(): draw_icon(self,scroll_id,Rect2(Vector2.ZERO,size))
