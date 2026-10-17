extends RefCounted
# Authored sprite data only. Coordinates and anchors are in atlas pixels.
const ART=preload("res://art/looks_atlas.png")
# Multiply-tint HAIR and FACES separately. Faces include neutral skin, ears and neck.
# Use custom_body_layout.DATA to avoid the original baked-in hair/hat beneath an overlay.
const HAIR_SCALE=1.5
const FACE_SCALE=1.1
const HAIR={
    "spiky":{"side":Rect2(4,4,124,124),"front":Rect2(4,136,124,124),"back":Rect2(4,268,124,124),"rear_side":Rect2(4,400,124,124)},
    "long":{"side":Rect2(136,4,124,124),"front":Rect2(136,136,124,124),"back":Rect2(136,268,124,124),"rear_side":Rect2(136,400,124,124)},
    "ponytail":{"side":Rect2(268,4,124,124),"front":Rect2(268,136,124,124),"back":Rect2(268,268,124,124),"rear_side":Rect2(268,400,124,124)},
    "bowl":{"side":Rect2(400,4,124,124),"front":Rect2(400,136,124,124),"back":Rect2(400,268,124,124),"rear_side":Rect2(400,400,124,124)},
    "messy":{"side":Rect2(532,4,124,124),"front":Rect2(532,136,124,124),"back":Rect2(532,268,124,124),"rear_side":Rect2(532,400,124,124)},
    "braid":{"side":Rect2(664,4,124,124),"front":Rect2(664,136,124,124),"back":Rect2(664,268,124,124),"rear_side":Rect2(664,400,124,124)},
    "mohawk":{"side":Rect2(796,4,124,124),"front":Rect2(796,136,124,124),"back":Rect2(796,268,124,124),"rear_side":Rect2(796,400,124,124)},
    "bun":{"side":Rect2(928,4,124,124),"front":Rect2(928,136,124,124),"back":Rect2(928,268,124,124),"rear_side":Rect2(928,400,124,124)},
}
const HAIR_ANCHORS={
    "spiky":{"side":Vector2(78.92,82.15),"front":Vector2(63.93,82.97),"back":Vector2(58.49,80.93),"rear_side":Vector2(61.62,81.28)},
    "long":{"side":Vector2(85.61,66.95),"front":Vector2(63.48,67.11),"back":Vector2(62.0,67.11),"rear_side":Vector2(53.25,67.38)},
    "ponytail":{"side":Vector2(81.13,79.88),"front":Vector2(66.51,85.89),"back":Vector2(54.56,85.74),"rear_side":Vector2(52.07,81.23)},
    "bowl":{"side":Vector2(77.37,78.18),"front":Vector2(64.3,78.44),"back":Vector2(62.39,78.84),"rear_side":Vector2(63.14,77.98)},
    "messy":{"side":Vector2(78.53,79.43),"front":Vector2(62.0,78.81),"back":Vector2(63.83,79.58),"rear_side":Vector2(58.31,80.02)},
    "braid":{"side":Vector2(79.33,59.86),"front":Vector2(60.06,59.52),"back":Vector2(62.09,59.52),"rear_side":Vector2(56.0,59.75)},
    "mohawk":{"side":Vector2(77.65,90.83),"front":Vector2(63.06,94.24),"back":Vector2(63.63,94.24),"rear_side":Vector2(61.61,92.56)},
    "bun":{"side":Vector2(73.68,75.94),"front":Vector2(63.78,78.12),"back":Vector2(61.87,78.63),"rear_side":Vector2(66.34,77.63)},
}
const FACES={
    "default":{"side":Rect2(4,532,124,124),"front":Rect2(4,664,124,124)},
    "determined":{"side":Rect2(136,532,124,124),"front":Rect2(136,664,124,124)},
    "sleepy":{"side":Rect2(268,532,124,124),"front":Rect2(268,664,124,124)},
    "angry":{"side":Rect2(400,532,124,124),"front":Rect2(400,664,124,124)},
    "smiling":{"side":Rect2(532,532,124,124),"front":Rect2(532,664,124,124)},
    "cool":{"side":Rect2(664,532,124,124),"front":Rect2(664,664,124,124)},
}
const FACE_ANCHORS={
    "default":{"side":Vector2(61.5,57.04),"front":Vector2(61.5,57.04)},
    "determined":{"side":Vector2(62.0,57.04),"front":Vector2(62.0,57.04)},
    "sleepy":{"side":Vector2(62.0,57.04),"front":Vector2(61.5,57.04)},
    "angry":{"side":Vector2(61.5,57.04),"front":Vector2(62.0,57.04)},
    "smiling":{"side":Vector2(61.5,57.04),"front":Vector2(62.0,57.04)},
    "cool":{"side":Vector2(61.5,57.04),"front":Vector2(62.0,57.04)},
}
# Head centers follow each authored pose rather than a fixed offset at the feet.
const FRAME_HEAD_ANCHORS=preload("res://visuals/body_layout.gd").HEAD_ANCHORS
const FRAME_OFFSETS={"warrior":[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],"thief":[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],"mage":[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],"archer":[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]}
