extends RefCounted
const GROUND=[Rect2(12,185,430,212),Rect2(455,192,430,206),Rect2(900,194,418,198),Rect2(1340,190,424,207),Rect2(14,526,425,222),Rect2(455,532,425,216),Rect2(897,531,425,216),Rect2(1339,533,425,216)]
const BUILDINGS=[Rect2(12,72,342,314),Rect2(355,3,369,375),Rect2(727,89,359,289),Rect2(1093,58,343,320),Rect2(5,393,358,332),Rect2(375,386,347,340),Rect2(729,416,364,307),Rect2(1097,386,344,339),Rect2(12,737,359,331),Rect2(373,733,349,328),Rect2(730,731,353,335),Rect2(1089,737,348,327)]
static func palette(biome: String) -> Dictionary:
    var specs={
        "mushroom":[0,"ffffff","ffffff","ffffff",-1],
        "meadow":[0,"fff2cf","ffffff","ffffff",-1],
        "farm":[0,"fff0c8","f0e8c0","ffffff",-1],
        "coast":[0,"e9f8ff","eee1ba","cdeed7",-1],
        "forest":[1,"d1f3ea","d2ead4","b9d8e0",-1],
        "highland":[2,"efd7c4","cb9e81","b9aa7d",1],
        "city":[3,"727da8","a5a2ad","8d8a9c",-1],
        "roots":[4,"c6b7d9","c7bddc","b5a5c8",-1],
        "cloud":[5,"f1efff","e4e8f8","dfe5f5",-1],
        "snow":[6,"ffffff","e4f5ff","d0e7f5",0],
        "toy":[7,"fff1e7","e4c5db","c3cfe5",-1],
        "tech":[3,"9eafbe","a6bbc1","a6bdba",-1],
        "eastern":[9,"ffe5f0","e6d7c2","ebbbd3",-1],
        "underwater":[5,"91e7ed","83b8ca","91cdcf",2],
        "dragon":[2,"dfc6df","b6a0ba","b09fbc",3],
        "desert":[8,"ffffff","f5d38e","d8cc8e",1],
        "alchemy":[10,"d5ebd0","b8ccae","b5cda5",-1],
        "temple":[5,"e0d9fa","c6bfd7","c0bad9",3],
        "shrine":[11,"ffe7eb","dfccca","e6bdd1",-1]}
    var p=specs.get(biome,specs.mushroom)
    return {"building":p[0],"sky":Color(p[1]),"tile":Color(p[2]),"foliage":Color(p[3]),"background":p[4]}
static func enemy_tint(biome: String) -> Color:
    return {"snow":Color("c0eaff"),"desert":Color("f5cf91"),"city":Color("c6b1eb"),"tech":Color("adcbd9"),"underwater":Color("a3e9eb"),"dragon":Color("ebb2cf"),"temple":Color("d4c2ff")}.get(biome,Color.WHITE)

static func ground_index(biome: String) -> int:
    return {"snow":0,"desert":1,"city":2,"tech":2,"toy":3,"underwater":4,"highland":5,"dragon":5,"temple":6,"coast":7,"eastern":7,"shrine":7}.get(biome,-1)
