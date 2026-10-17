extends RefCounted
# Authored sprite data only. Coordinates and anchors are in atlas pixels.
const ART=preload("res://art/climb_atlas.png")
const TILE_HEIGHT=64
const DATA={
    "meadow":{"rope_top":Rect2(2,2,16,16),"rope_mid":Rect2(22,2,16,64),"rope_bottom":Rect2(42,2,16,16),"ladder_top":Rect2(62,2,32,16),"ladder_mid":Rect2(98,2,32,64),"ladder_bottom":Rect2(134,2,32,16)},
    "forest":{"rope_top":Rect2(2,70,16,16),"rope_mid":Rect2(22,70,16,64),"rope_bottom":Rect2(42,70,16,16),"ladder_top":Rect2(62,70,32,16),"ladder_mid":Rect2(98,70,32,64),"ladder_bottom":Rect2(134,70,32,16)},
    "coast":{"rope_top":Rect2(2,138,16,16),"rope_mid":Rect2(22,138,16,64),"rope_bottom":Rect2(42,138,16,16),"ladder_top":Rect2(62,138,32,16),"ladder_mid":Rect2(98,138,32,64),"ladder_bottom":Rect2(134,138,32,16)},
    "highland":{"rope_top":Rect2(2,206,16,16),"rope_mid":Rect2(22,206,16,64),"rope_bottom":Rect2(42,206,16,16),"ladder_top":Rect2(62,206,32,16),"ladder_mid":Rect2(98,206,32,64),"ladder_bottom":Rect2(134,206,32,16)},
    "roots":{"rope_top":Rect2(2,274,16,16),"rope_mid":Rect2(22,274,16,64),"rope_bottom":Rect2(42,274,16,16),"ladder_top":Rect2(62,274,32,16),"ladder_mid":Rect2(98,274,32,64),"ladder_bottom":Rect2(134,274,32,16)},
    "snow":{"rope_top":Rect2(2,342,16,16),"rope_mid":Rect2(22,342,16,64),"rope_bottom":Rect2(42,342,16,16),"ladder_top":Rect2(62,342,32,16),"ladder_mid":Rect2(98,342,32,64),"ladder_bottom":Rect2(134,342,32,16)},
    "toy":{"rope_top":Rect2(2,410,16,16),"rope_mid":Rect2(22,410,16,64),"rope_bottom":Rect2(42,410,16,16),"ladder_top":Rect2(62,410,32,16),"ladder_mid":Rect2(98,410,32,64),"ladder_bottom":Rect2(134,410,32,16)},
    "tech":{"rope_top":Rect2(2,478,16,16),"rope_mid":Rect2(22,478,16,64),"rope_bottom":Rect2(42,478,16,16),"ladder_top":Rect2(62,478,32,16),"ladder_mid":Rect2(98,478,32,64),"ladder_bottom":Rect2(134,478,32,16)},
    "underwater":{"rope_top":Rect2(2,546,16,16),"rope_mid":Rect2(22,546,16,64),"rope_bottom":Rect2(42,546,16,16),"ladder_top":Rect2(62,546,32,16),"ladder_mid":Rect2(98,546,32,64),"ladder_bottom":Rect2(134,546,32,16)},
    "cloud":{"rope_top":Rect2(2,614,16,16),"rope_mid":Rect2(22,614,16,64),"rope_bottom":Rect2(42,614,16,16),"ladder_top":Rect2(62,614,32,16),"ladder_mid":Rect2(98,614,32,64),"ladder_bottom":Rect2(134,614,32,16)},
    "temple":{"rope_top":Rect2(2,682,16,16),"rope_mid":Rect2(22,682,16,64),"rope_bottom":Rect2(42,682,16,16),"ladder_top":Rect2(62,682,32,16),"ladder_mid":Rect2(98,682,32,64),"ladder_bottom":Rect2(134,682,32,16)},
    "desert":{"rope_top":Rect2(2,750,16,16),"rope_mid":Rect2(22,750,16,64),"rope_bottom":Rect2(42,750,16,16),"ladder_top":Rect2(62,750,32,16),"ladder_mid":Rect2(98,750,32,64),"ladder_bottom":Rect2(134,750,32,16)},
    "alchemy":{"rope_top":Rect2(2,818,16,16),"rope_mid":Rect2(22,818,16,64),"rope_bottom":Rect2(42,818,16,16),"ladder_top":Rect2(62,818,32,16),"ladder_mid":Rect2(98,818,32,64),"ladder_bottom":Rect2(134,818,32,16)},
    "eastern":{"rope_top":Rect2(2,886,16,16),"rope_mid":Rect2(22,886,16,64),"rope_bottom":Rect2(42,886,16,16),"ladder_top":Rect2(62,886,32,16),"ladder_mid":Rect2(98,886,32,64),"ladder_bottom":Rect2(134,886,32,16)},
    "mushroom":{"rope_top":Rect2(2,954,16,16),"rope_mid":Rect2(22,954,16,64),"rope_bottom":Rect2(42,954,16,16),"ladder_top":Rect2(62,954,32,16),"ladder_mid":Rect2(98,954,32,64),"ladder_bottom":Rect2(134,954,32,16)},
    "farm":{"rope_top":Rect2(2,1022,16,16),"rope_mid":Rect2(22,1022,16,64),"rope_bottom":Rect2(42,1022,16,16),"ladder_top":Rect2(62,1022,32,16),"ladder_mid":Rect2(98,1022,32,64),"ladder_bottom":Rect2(134,1022,32,16)},
    "city":{"rope_top":Rect2(2,1090,16,16),"rope_mid":Rect2(22,1090,16,64),"rope_bottom":Rect2(42,1090,16,16),"ladder_top":Rect2(62,1090,32,16),"ladder_mid":Rect2(98,1090,32,64),"ladder_bottom":Rect2(134,1090,32,16)},
    "dragon":{"rope_top":Rect2(2,1158,16,16),"rope_mid":Rect2(22,1158,16,64),"rope_bottom":Rect2(42,1158,16,16),"ladder_top":Rect2(62,1158,32,16),"ladder_mid":Rect2(98,1158,32,64),"ladder_bottom":Rect2(134,1158,32,16)},
    "shrine":{"rope_top":Rect2(2,886,16,16),"rope_mid":Rect2(22,886,16,64),"rope_bottom":Rect2(42,886,16,16),"ladder_top":Rect2(62,886,32,16),"ladder_mid":Rect2(98,886,32,64),"ladder_bottom":Rect2(134,886,32,16)},
    "beach":{"rope_top":Rect2(2,138,16,16),"rope_mid":Rect2(22,138,16,64),"rope_bottom":Rect2(42,138,16,16),"ladder_top":Rect2(62,138,32,16),"ladder_mid":Rect2(98,138,32,64),"ladder_bottom":Rect2(134,138,32,16)},
    "mountain":{"rope_top":Rect2(2,206,16,16),"rope_mid":Rect2(22,206,16,64),"rope_bottom":Rect2(42,206,16,16),"ladder_top":Rect2(62,206,32,16),"ladder_mid":Rect2(98,206,32,64),"ladder_bottom":Rect2(134,206,32,16)},
    "swamp":{"rope_top":Rect2(2,274,16,16),"rope_mid":Rect2(22,274,16,64),"rope_bottom":Rect2(42,274,16,16),"ladder_top":Rect2(62,274,32,16),"ladder_mid":Rect2(98,274,32,64),"ladder_bottom":Rect2(134,274,32,16)},
    "ocean":{"rope_top":Rect2(2,546,16,16),"rope_mid":Rect2(22,546,16,64),"rope_bottom":Rect2(42,546,16,16),"ladder_top":Rect2(62,546,32,16),"ladder_mid":Rect2(98,546,32,64),"ladder_bottom":Rect2(134,546,32,16)},
    "sky":{"rope_top":Rect2(2,614,16,16),"rope_mid":Rect2(22,614,16,64),"rope_bottom":Rect2(42,614,16,16),"ladder_top":Rect2(62,614,32,16),"ladder_mid":Rect2(98,614,32,64),"ladder_bottom":Rect2(134,614,32,16)},
    "clockwork":{"rope_top":Rect2(2,478,16,16),"rope_mid":Rect2(22,478,16,64),"rope_bottom":Rect2(42,478,16,16),"ladder_top":Rect2(62,478,32,16),"ladder_mid":Rect2(98,478,32,64),"ladder_bottom":Rect2(134,478,32,16)},
    "time":{"rope_top":Rect2(2,682,16,16),"rope_mid":Rect2(22,682,16,64),"rope_bottom":Rect2(42,682,16,16),"ladder_top":Rect2(62,682,32,16),"ladder_mid":Rect2(98,682,32,64),"ladder_bottom":Rect2(134,682,32,16)},
    "temple/time":{"rope_top":Rect2(2,682,16,16),"rope_mid":Rect2(22,682,16,64),"rope_bottom":Rect2(42,682,16,16),"ladder_top":Rect2(62,682,32,16),"ladder_mid":Rect2(98,682,32,64),"ladder_bottom":Rect2(134,682,32,16)},
    "toy/clockwork":{"rope_top":Rect2(2,410,16,16),"rope_mid":Rect2(22,410,16,64),"rope_bottom":Rect2(42,410,16,16),"ladder_top":Rect2(62,410,32,16),"ladder_mid":Rect2(98,410,32,64),"ladder_bottom":Rect2(134,410,32,16)},
}
const BIOMES=DATA
