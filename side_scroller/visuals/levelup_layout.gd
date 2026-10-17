extends RefCounted
# Authored sprite data only. Coordinates and anchors are in atlas pixels.
const ART=preload("res://art/levelup_atlas.png")
const LEVEL_UP={"rects":[Rect2(2,2,256,256),Rect2(262,2,256,256),Rect2(522,2,256,256),Rect2(782,2,256,256),Rect2(1042,2,256,256),Rect2(2,262,256,256)],"anchors":[Vector2(130,218),Vector2(390,218),Vector2(650,218),Vector2(910,218),Vector2(1170,218),Vector2(130,478)],"fps":10,"loop":false}
const SKILL_LEARNED={"rects":[Rect2(262,262,256,256),Rect2(522,262,256,256),Rect2(782,262,256,256),Rect2(1042,262,256,256)],"anchors":[Vector2(390,390),Vector2(650,390),Vector2(910,390),Vector2(1170,390)],"fps":10,"loop":false}
const DATA={"level_up":LEVEL_UP,"skill_learned":SKILL_LEARNED}
