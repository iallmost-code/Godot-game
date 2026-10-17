extends RefCounted
const ART=preload("res://art/monster_atlas.png")
const ART_2=preload("res://art/monster_atlas_2.png")
const LYCAN=preload("res://art/moonfang_lycan.png")
const DATA={
    "snail":{"rect":Rect2(25,70,308,250),"height":34},
    "mushroom":{"rect":Rect2(349,60,258,258),"height":43},
    "stump":{"rect":Rect2(658,36,301,285),"height":43},
    "slime":{"rect":Rect2(1003,87,228,234),"height":31},
    "boar":{"rect":Rect2(22,371,325,247),"height":39},
    "octopus":{"rect":Rect2(370,349,268,272),"height":49},
    "wraith":{"rect":Rect2(661,350,253,283),"height":52},
    "gator":{"rect":Rect2(927,428,313,197),"height":34},
    "bat":{"rect":Rect2(16,668,350,219),"height":36},
    "clock":{"rect":Rect2(384,644,213,268),"height":49},
    "fish":{"rect":Rect2(619,666,302,245),"height":35},
    "crab":{"rect":Rect2(952,663,284,251),"height":33},
    "golem":{"rect":Rect2(19,920,323,301),"height":76},
    "skeleton":{"rect":Rect2(370,922,214,296),"height":62},
    "wolf":{"rect":Rect2(616,935,323,287),"height":43},
    "teddy":{"rect":Rect2(980,937,222,287),"height":57},
    "drake":{"rect":Rect2(31,64,377,318),"height":48,"texture":ART_2},
    "drake_winged":{"rect":Rect2(427,22,427,365),"height":66,"texture":ART_2},
    "yeti":{"rect":Rect2(873,30,367,351),"height":59,"texture":ART_2},
    "yeti_horned":{"rect":Rect2(25,410,398,376),"height":65,"texture":ART_2},
    "ape":{"rect":Rect2(452,406,420,385),"height":57,"texture":ART_2},
    "toy":{"rect":Rect2(906,401,331,384),"height":63,"texture":ART_2},
    "centaur":{"rect":Rect2(14,789,410,450),"height":76,"texture":ART_2},
    "bird":{"rect":Rect2(431,810,469,432),"height":61,"texture":ART_2},
    "monk":{"rect":Rect2(880,803,357,430),"height":70,"texture":ART_2},
    "wolf_upright":{"rect":Rect2(57,6,1145,1246),"height":76,"texture":LYCAN},
}
