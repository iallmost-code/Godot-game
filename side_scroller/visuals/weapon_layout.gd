extends RefCounted
const ART=preload("res://art/weapons_atlas.png")
const DATA={
    "sword":{"rect":Rect2(58,40,126,365),"grip":Vector2(63.00,295.65),"length":60},
    "spear":{"rect":Rect2(341,13,87,395),"grip":Vector2(26.10,284.40),"length":112},
    "dagger":{"rect":Rect2(555,54,95,349),"grip":Vector2(40.85,289.67),"length":40},
    "claw":{"rect":Rect2(736,193,303,131),"grip":Vector2(48.48,72.05),"length":36},
    "staff":{"rect":Rect2(1071,27,116,387),"grip":Vector2(60.32,294.12),"length":95},
    "bow":{"rect":Rect2(1290,42,122,376),"grip":Vector2(93.94,188.00),"length":74},
    "crossbow":{"rect":Rect2(1484,185,275,166),"grip":Vector2(66.00,114.54),"length":65},
    "sword_rare":{"rect":Rect2(37,425,166,439),"grip":Vector2(83.00,355.59),"length":66},
    "spear_rare":{"rect":Rect2(325,425,146,447),"grip":Vector2(43.80,321.84),"length":118},
    "dagger_rare":{"rect":Rect2(538,472,116,390),"grip":Vector2(49.88,323.70),"length":46},
    "claw_rare":{"rect":Rect2(709,602,343,163),"grip":Vector2(54.88,89.65),"length":42},
    "staff_rare":{"rect":Rect2(1048,431,164,441),"grip":Vector2(85.28,335.16),"length":101},
    "bow_rare":{"rect":Rect2(1290,441,148,421),"grip":Vector2(113.96,210.50),"length":80},
    "crossbow_rare":{"rect":Rect2(1466,592,298,193),"grip":Vector2(71.52,133.17),"length":71},
}
static func definition(kind: String,rare=false) -> Dictionary:
    return DATA.get(kind+("_rare" if rare else ""),DATA.sword)
