extends RefCounted
# Vector monster art. Every template draws in local space with the feet at (0,0),
# facing right; the caller passes facing and size so one template serves many monsters.
const OUTLINE=Color("2b2233")

static func oval(points: int,center: Vector2,rx: float,ry: float,start=0.0,end=TAU) -> PackedVector2Array:
    var result=PackedVector2Array()
    for i in range(points+1):
        var a=lerpf(start,end,float(i)/points)
        result.append(center+Vector2(cos(a)*rx,sin(a)*ry))
    return result
static func blob(c: CanvasItem,center: Vector2,rx: float,ry: float,color: Color,line=2.0):
    var pts=oval(28,center,rx,ry)
    c.draw_colored_polygon(pts,color)
    c.draw_polyline(pts,OUTLINE,line,true)
static func poly(c: CanvasItem,points: Array,color: Color,line=2.0):
    var pts=PackedVector2Array(points)
    c.draw_colored_polygon(pts,color)
    pts.append(points[0])
    c.draw_polyline(pts,OUTLINE,line,true)
static func box(c: CanvasItem,rect: Rect2,color: Color,line=2.0):
    poly(c,[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)],color,line)
static func eyes(c: CanvasItem,at: Vector2,gap: float,radius=3.4,angry=false,glow=Color.TRANSPARENT):
    for side in [-1,1]:
        var p=at+Vector2(side*gap,0)
        if glow.a>0:
            c.draw_circle(p,radius+2,Color(glow,0.35))
            c.draw_circle(p,radius,glow)
            continue
        c.draw_circle(p,radius,Color.WHITE)
        c.draw_circle(p+Vector2(1,0.5),radius*0.55,OUTLINE)
        c.draw_circle(p+Vector2(0.4,-0.8),radius*0.2,Color.WHITE)
        if angry: c.draw_line(p+Vector2(-radius,-radius-1+side*0.0),p+Vector2(radius,-radius+1+(1.5 if side<0 else -1.5)),OUTLINE,2)
static func legs(c: CanvasItem,xs: Array,top: float,color: Color,t: float,width=5.0):
    for i in xs.size():
        var swing=sin(t*9+i*1.7)*3
        c.draw_line(Vector2(xs[i],top),Vector2(xs[i]+swing,0),OUTLINE,width+2,true)
        c.draw_line(Vector2(xs[i],top),Vector2(xs[i]+swing,0),color,width,true)

static func draw(c: CanvasItem,p: Dictionary,t: float,facing: int,flash: float,status: Dictionary={}):
    var body=p.get("body","slime")
    var main: Color=p.get("color",Color("8fd6b6"))
    var accent: Color=p.get("accent",Color.WHITE)
    if flash>0:
        main=main.lerp(Color.WHITE,0.75)
        accent=accent.lerp(Color.WHITE,0.75)
    if status.get("frozen",false):
        main=main.lerp(Color("bfe9ff"),0.55)
        accent=accent.lerp(Color("bfe9ff"),0.55)
    if status.get("doom",false):
        main=main.lerp(Color("8a8a8a"),0.6)
    var size: float=p.get("size",1.0)
    var bob=sin(t*4.0)*1.2
    c.draw_set_transform(Vector2(0,bob if body in ["wraith","fish","clock","bat","idol","bird"] or p.get("behavior","")=="flyer" else 0),0,Vector2(facing*size,size))
    match body:
        "snail":
            var crawl=sin(t*5)*1.5
            poly(c,[Vector2(-18,0),Vector2(22+crawl,0),Vector2(26+crawl,-6),Vector2(20,-12),Vector2(-10,-8)],accent)
            blob(c,Vector2(-4,-20),16,16,main)
            c.draw_arc(Vector2(-4,-20),10,0.4,TAU*0.85,18,main.darkened(0.35),3)
            c.draw_arc(Vector2(-3,-19),4,0.0,TAU*0.8,12,main.darkened(0.35),2.5)
            for side in [0,1]:
                var tip=Vector2(22+side*6+crawl,-26+side*2)
                c.draw_line(Vector2(20+side*3,-10),tip,OUTLINE,3)
                c.draw_circle(tip,3.2,Color.WHITE)
                c.draw_circle(tip+Vector2(1,0),1.6,OUTLINE)
        "mushroom":
            box(c,Rect2(-10,-20,20,20),accent)
            if p.get("rot",false):
                c.draw_line(Vector2(-6,-14),Vector2(4,-6),Color("c8b89a"),3)
                c.draw_line(Vector2(4,-14),Vector2(-6,-6),Color("c8b89a"),3)
            eyes(c,Vector2(1,-12),5,3,p.get("behavior","")=="charger")
            var cap=oval(22,Vector2(0,-20),24,18,PI,TAU)
            cap.append(Vector2(-24,-20))
            c.draw_colored_polygon(cap,main)
            c.draw_polyline(cap,OUTLINE,2,true)
            for spot in [Vector2(-10,-29),Vector2(6,-33),Vector2(14,-24),Vector2(-2,-24)]:
                c.draw_circle(spot,3.5 if spot.y<-30 else 2.6,Color(1,1,1,0.85) if not p.get("rot",false) else Color("5a6a4a"))
            if p.get("horns",false):
                poly(c,[Vector2(-14,-33),Vector2(-20,-48),Vector2(-8,-36)],Color("f2ead2"))
                poly(c,[Vector2(10,-36),Vector2(16,-50),Vector2(16,-33)],Color("f2ead2"))
        "slime":
            var squash=1.0+sin(t*6)*0.06
            blob(c,Vector2(0,-15*squash),22/squash,15*squash,Color(main,0.92))
            c.draw_circle(Vector2(-8,-22),4,Color(1,1,1,0.6))
            eyes(c,Vector2(3,-16),6,3.2)
            c.draw_arc(Vector2(3,-10),4,0.3,PI-0.3,8,OUTLINE,1.5)
            if p.get("boss",false):
                poly(c,[Vector2(-12,-30),Vector2(-14,-44),Vector2(-6,-37),Vector2(0,-47),Vector2(6,-37),Vector2(14,-44),Vector2(12,-30)],Color("f2c94c"))
        "stump":
            box(c,Rect2(-15,-36,30,36),main)
            blob(c,Vector2(0,-36),15,5,main.lightened(0.35),1.5)
            c.draw_arc(Vector2(0,-36),8,0,TAU,16,main.darkened(0.2),1.5)
            for leaf in [Vector2(-8,-44),Vector2(2,-48),Vector2(10,-43)]:
                blob(c,leaf,6,4,accent,1.5)
            eyes(c,Vector2(2,-22),6,3.2,p.get("behavior","")!="walker")
            c.draw_line(Vector2(-15,-18),Vector2(-24,-26+sin(t*6)*3),OUTLINE,3)
            c.draw_line(Vector2(15,-18),Vector2(24,-24-sin(t*6)*3),OUTLINE,3)
            if p.get("weapon","")=="axe":
                c.draw_line(Vector2(24,-24),Vector2(28,-44),Color("6b4a2c"),4)
                poly(c,[Vector2(26,-46),Vector2(40,-50),Vector2(38,-36),Vector2(28,-38)],accent)
        "boar":
            legs(c,[-14,-6,8,16],-8,main.darkened(0.25),t)
            blob(c,Vector2(0,-18),24,13,main)
            if p.get("flame",false):
                for i in range(4): poly(c,[Vector2(-16+i*9,-28),Vector2(-12+i*9,-44-sin(t*10+i)*5),Vector2(-8+i*9,-28)],Color("ff8a4c"),1)
            blob(c,Vector2(20,-20),11,10,main)
            blob(c,Vector2(29,-17),5,4,accent,1.5)
            c.draw_circle(Vector2(30,-18),1,OUTLINE)
            poly(c,[Vector2(14,-28),Vector2(12,-36),Vector2(19,-29)],main.darkened(0.2),1.5)
            eyes(c,Vector2(22,-24),0.1,2.6,p.get("behavior","")=="charger")
            if p.get("tusks",false):
                c.draw_line(Vector2(27,-13),Vector2(33,-22),Color("f6f0dc"),3)
        "octopus":
            for i in range(5):
                var x=-14+i*7
                var pts=PackedVector2Array()
                for k in range(6): pts.append(Vector2(x+sin(t*5+i+k*0.8)*3,-16+k*3.2))
                c.draw_polyline(pts,main.darkened(0.2),4,true)
            blob(c,Vector2(0,-28),17,16,main)
            c.draw_circle(Vector2(-6,-36),3,Color(1,1,1,0.5))
            eyes(c,Vector2(3,-27),6,3.2)
        "wraith":
            # Dome from left to right, then a wavy tail back from right to left.
            var full=Array(oval(16,Vector2(0,-32),16,16,PI,TAU))
            full.append(Vector2(16,-18))
            for i in range(7): full.append(Vector2(16-i*5.3,-6+sin(t*7+i)*3+(5 if i%2 else 0)))
            full.append(Vector2(-16,-18))
            c.draw_colored_polygon(PackedVector2Array(full),Color(main,0.8))
            eyes(c,Vector2(3,-32),6,3.2,false,accent)
            c.draw_line(Vector2(-14,-24),Vector2(-26,-18+sin(t*5)*4),Color(main,0.8),4,true)
        "gator":
            legs(c,[-16,-4,10,20],-6,main.darkened(0.2),t,4)
            poly(c,[Vector2(-40,-8),Vector2(-20,-16),Vector2(-20,-4)],main.darkened(0.1))
            blob(c,Vector2(0,-11),24,9,main)
            blob(c,Vector2(0,-7),18,4,accent,0)
            var jaw=sin(t*4)*2
            poly(c,[Vector2(20,-16),Vector2(44,-12),Vector2(44,-8),Vector2(20,-6)],main)
            poly(c,[Vector2(22,-6),Vector2(42,-6+jaw),Vector2(22,-2)],main.darkened(0.15),1.5)
            for x in [26,31,36,40]: c.draw_line(Vector2(x,-8),Vector2(x+1,-5),Color.WHITE,1.5)
            eyes(c,Vector2(24,-19),0.1,2.8,true)
        "ape":
            legs(c,[-8,8],-12,main.darkened(0.2),t,6)
            blob(c,Vector2(0,-26),17,17,main)
            blob(c,Vector2(3,-28),10,9,accent,1.5)
            eyes(c,Vector2(3,-31),4,2.6)
            c.draw_arc(Vector2(4,-24),3,0.2,PI-0.2,8,OUTLINE,1.5)
            c.draw_line(Vector2(14,-24),Vector2(24,-34+sin(t*6)*5),OUTLINE,6,true)
            c.draw_line(Vector2(14,-24),Vector2(24,-34+sin(t*6)*5),main,4,true)
        "golem":
            legs(c,[-10,10],-16,main.darkened(0.25),t,10)
            box(c,Rect2(-20,-52,40,36),main)
            box(c,Rect2(-11,-68,22,16),main.lightened(0.08))
            eyes(c,Vector2(0,-61),5,2.6,false,accent)
            for side in [-1,1]:
                box(c,Rect2(side*20-(10 if side<0 else 0)-1,-50+sin(t*3+side)*2,11,28),main.darkened(0.1))
            if p.get("flame",false) or p.get("statue",false):
                c.draw_line(Vector2(-12,-44),Vector2(-2,-30),accent,2)
                c.draw_line(Vector2(-2,-30),Vector2(8,-40),accent,2)
                c.draw_line(Vector2(6,-24),Vector2(14,-34),accent,2)
            else:
                c.draw_circle(Vector2(-8,-40),3,main.darkened(0.25))
                c.draw_circle(Vector2(9,-30),4,main.darkened(0.25))
        "drake":
            var fly=p.get("behavior","")=="flyer" or p.get("wings",false)
            if not fly: legs(c,[-12,-4,8,14],-8,main.darkened(0.2),t)
            poly(c,[Vector2(-20,-18),Vector2(-42,-10+sin(t*4)*3),Vector2(-18,-10)],main.darkened(0.1))
            if fly:
                var f=sin(t*9)*10
                poly(c,[Vector2(-4,-24),Vector2(-20,-52-f),Vector2(6,-30)],main.darkened(0.2))
            blob(c,Vector2(0,-18),22,12,main)
            blob(c,Vector2(2,-13),14,5,accent,0)
            c.draw_line(Vector2(16,-24),Vector2(24,-36),OUTLINE,9,true)
            c.draw_line(Vector2(16,-24),Vector2(24,-36),main,7,true)
            blob(c,Vector2(30,-38),11,8,main)
            poly(c,[Vector2(24,-44),Vector2(22,-54),Vector2(30,-46)],accent,1.5)
            eyes(c,Vector2(32,-40),0.1,2.6,true)
            c.draw_circle(Vector2(39,-36),1.2,OUTLINE)
        "yeti":
            legs(c,[-8,8],-12,main.darkened(0.15),t,8)
            blob(c,Vector2(0,-28),20,21,main)
            blob(c,Vector2(4,-32),11,9,accent.lightened(0.2),1.5)
            eyes(c,Vector2(4,-34),4,2.6,p.get("behavior","")=="tank")
            if p.get("horns",false):
                poly(c,[Vector2(-10,-46),Vector2(-20,-60),Vector2(-4,-49)],Color("f2ead2"))
                poly(c,[Vector2(10,-48),Vector2(20,-62),Vector2(16,-45)],Color("f2ead2"))
            c.draw_line(Vector2(-18,-28),Vector2(-26,-14+sin(t*5)*3),OUTLINE,7,true)
            c.draw_line(Vector2(-18,-28),Vector2(-26,-14+sin(t*5)*3),main,5,true)
        "wolf":
            if p.get("upright",false):
                legs(c,[-6,6],-20,main.darkened(0.2),t,7)
                blob(c,Vector2(0,-36),14,18,main)
                blob(c,Vector2(4,-58),10,9,main)
                poly(c,[Vector2(8,-58),Vector2(20,-55),Vector2(9,-52)],main.darkened(0.1),1.5)
                poly(c,[Vector2(-2,-64),Vector2(-4,-74),Vector2(4,-66)],main,1.5)
                eyes(c,Vector2(8,-60),0.1,2.4,true,accent)
                c.draw_line(Vector2(12,-40),Vector2(24,-34),OUTLINE,5,true)
            else:
                legs(c,[-14,-6,8,14],-10,main.darkened(0.2),t)
                poly(c,[Vector2(-20,-18),Vector2(-36,-26+sin(t*6)*4),Vector2(-20,-12)],main)
                blob(c,Vector2(0,-18),22,10,main)
                blob(c,Vector2(22,-24),10,9,main)
                poly(c,[Vector2(28,-26),Vector2(40,-21),Vector2(29,-18)],main.darkened(0.1),1.5)
                poly(c,[Vector2(16,-30),Vector2(15,-40),Vector2(22,-32)],main,1.5)
                eyes(c,Vector2(25,-27),0.1,2.4,true,accent if accent.v>0.7 else Color.TRANSPARENT)
        "toy":
            legs(c,[-8,8],-10,Color("5a4a3a"),t,5)
            box(c,Rect2(-17,-46,34,36),main)
            blob(c,Vector2(0,-30),11,11,accent.lightened(0.5),1.5)
            c.draw_line(Vector2(0,-30),Vector2(0,-37),OUTLINE,2)
            c.draw_line(Vector2(0,-30),Vector2(5+sin(t)*1,-30),OUTLINE,2)
            c.draw_line(Vector2(-17,-30),Vector2(-26,-30),OUTLINE,3)
            c.draw_line(Vector2(-26,-36),Vector2(-26,-24),OUTLINE,3)
            eyes(c,Vector2(0,-42),6,2.4,p.get("behavior","")=="tank",accent if p.get("behavior","")=="tank" else Color.TRANSPARENT)
        "teddy":
            legs(c,[-7,7],-10,main.darkened(0.2),t,8)
            blob(c,Vector2(0,-22),16,15,main)
            blob(c,Vector2(0,-44),13,12,main)
            blob(c,Vector2(-10,-54),5,5,main,1.5)
            blob(c,Vector2(10,-54),5,5,main,1.5)
            blob(c,Vector2(2,-40),6,4,accent,1.2)
            c.draw_circle(Vector2(-4,-47),2.4,OUTLINE)
            c.draw_circle(Vector2(7,-47),2.4,OUTLINE if accent.r<0.8 or p.get("behavior","")!="charger" else accent)
            for y in [-28,-22,-16]: c.draw_line(Vector2(-3,y),Vector2(3,y),OUTLINE,1.2)
        "clock":
            var f=sin(t*10)*6
            poly(c,[Vector2(-18,-34),Vector2(-34,-46-f),Vector2(-20,-26)],Color("f2ecff"),1.5)
            poly(c,[Vector2(18,-34),Vector2(34,-46-f),Vector2(20,-26)],Color("f2ecff"),1.5)
            blob(c,Vector2(0,-30),20,20,main)
            blob(c,Vector2(0,-30),14,14,accent,1.5)
            c.draw_line(Vector2(0,-30),Vector2(cos(t)*10,-30+sin(t)*10),OUTLINE,2)
            c.draw_line(Vector2(0,-30),Vector2(cos(t*0.2)*6,-30+sin(t*0.2)*6),OUTLINE,3)
            if p.get("boss",false): eyes(c,Vector2(0,-38),6,3,true,Color("ff6b6b"))
        "skeleton":
            legs(c,[-5,5],-20,Color("e8e0c8"),t,3)
            c.draw_line(Vector2(0,-20),Vector2(0,-44),OUTLINE,4)
            c.draw_line(Vector2(0,-20),Vector2(0,-44),main,2.5)
            for y in [-40,-34,-28]:
                c.draw_line(Vector2(-8,y),Vector2(8,y),OUTLINE,3)
                c.draw_line(Vector2(-8,y),Vector2(8,y),main,2)
            blob(c,Vector2(0,-52),10,9,main)
            c.draw_circle(Vector2(-3,-53),2.6,OUTLINE)
            c.draw_circle(Vector2(4,-53),2.6,OUTLINE)
            c.draw_line(Vector2(6,-38),Vector2(16,-30+sin(t*6)*3),main,3)
            if p.get("bow",false): c.draw_arc(Vector2(18,-34),12,-1.2,1.2,10,accent,3)
            elif p.get("helmet",false):
                poly(c,[Vector2(-11,-56),Vector2(11,-56),Vector2(8,-64),Vector2(-8,-64)],accent)
                c.draw_line(Vector2(16,-30),Vector2(26,-50),Color("c8c8d0"),3)
            else: c.draw_line(Vector2(16,-30),Vector2(24,-46),Color("c8c8d0"),3)
        "crab":
            for i in range(3):
                for side in [-1,1]:
                    c.draw_line(Vector2(side*8,-10),Vector2(side*(18+i*4),-2+sin(t*10+i)*2),OUTLINE,2.5)
            blob(c,Vector2(0,-14),20,11,main)
            for side in [-1,1]:
                blob(c,Vector2(side*22,-24+sin(t*5)*2),7,6,main.lightened(0.1),1.5)
                c.draw_line(Vector2(side*4,-22),Vector2(side*5,-30),OUTLINE,2)
                c.draw_circle(Vector2(side*5,-31),2.6,Color.WHITE)
                c.draw_circle(Vector2(side*5+0.8,-31),1.3,OUTLINE)
        "fish":
            poly(c,[Vector2(-20,-30),Vector2(-34,-40+sin(t*8)*3),Vector2(-34,-20+sin(t*8)*3)],accent)
            blob(c,Vector2(0,-30),24,13,main)
            blob(c,Vector2(2,-25),16,5,accent.lightened(0.2),0)
            poly(c,[Vector2(-4,-42),Vector2(6,-54),Vector2(10,-42)],accent,1.5)
            eyes(c,Vector2(14,-33),0.1,3,p.get("boss",false))
            c.draw_arc(Vector2(20,-27),3,0.4,PI-0.4,6,OUTLINE,1.5)
        "centaur":
            legs(c,[-20,-12,4,10],-18,main.darkened(0.2),t,4)
            blob(c,Vector2(-6,-26),22,11,main)
            poly(c,[Vector2(-26,-28),Vector2(-38,-18+sin(t*5)*3),Vector2(-26,-22)],accent)
            box(c,Rect2(6,-58,14,30),main.lightened(0.15))
            blob(c,Vector2(13,-66),8,8,Color("e9c9a3"))
            c.draw_circle(Vector2(16,-67),1.6,OUTLINE)
            poly(c,[Vector2(5,-70),Vector2(13,-80),Vector2(21,-70)],accent,1.5)
            c.draw_line(Vector2(20,-50),Vector2(36,-62),Color("8a6a4a"),3)
            c.draw_circle(Vector2(37,-63),4,Color(accent,0.8))
        "bird":
            var f=sin(t*12)*12
            poly(c,[Vector2(-6,-30),Vector2(-26,-50-f),Vector2(4,-34)],main.darkened(0.15))
            blob(c,Vector2(0,-28),16,11,main)
            poly(c,[Vector2(6,-30),Vector2(26,-48-f),Vector2(10,-26)],main.darkened(0.1))
            var heads=[Vector2(14,-38),Vector2(8,-44)] if p.get("twin",false) else [Vector2(14,-36)]
            for h in heads:
                blob(c,h,7,6,main.lightened(0.1),1.5)
                poly(c,[h+Vector2(5,-1),h+Vector2(14,2),h+Vector2(5,3)],accent,1.2)
                c.draw_circle(h+Vector2(2,-1),1.6,OUTLINE)
            c.draw_line(Vector2(-4,-18),Vector2(-6,-8),OUTLINE,2)
            c.draw_line(Vector2(4,-18),Vector2(6,-8),OUTLINE,2)
        "monk":
            poly(c,[Vector2(-16,0),Vector2(16,0),Vector2(8,-40),Vector2(-8,-40)],main)
            c.draw_line(Vector2(-8,-20),Vector2(8,-20),accent,3)
            blob(c,Vector2(0,-48),9,9,Color("e9c9a3"))
            poly(c,[Vector2(-11,-44),Vector2(-9,-54),Vector2(0,-62),Vector2(9,-54),Vector2(11,-44),Vector2(7,-50),Vector2(-7,-50)],accent,1.5)
            c.draw_circle(Vector2(3,-48),1.6,OUTLINE)
            c.draw_line(Vector2(14,-6),Vector2(22,-56),Color("8a6a4a"),3)
            c.draw_circle(Vector2(22,-58),4,Color(accent,0.85))
        "bat":
            var f=sin(t*7)*14
            poly(c,[Vector2(-6,-48),Vector2(-46,-70-f),Vector2(-36,-44-f*0.5),Vector2(-44,-30-f*0.3),Vector2(-8,-34)],main.darkened(0.2))
            poly(c,[Vector2(6,-48),Vector2(46,-70-f),Vector2(36,-44-f*0.5),Vector2(44,-30-f*0.3),Vector2(8,-34)],main.darkened(0.2))
            blob(c,Vector2(0,-36),15,22,main)
            blob(c,Vector2(0,-60),11,10,main)
            poly(c,[Vector2(-8,-66),Vector2(-14,-80),Vector2(-3,-69)],accent,1.5)
            poly(c,[Vector2(8,-66),Vector2(14,-80),Vector2(3,-69)],accent,1.5)
            eyes(c,Vector2(1,-61),4,2.4,true,accent)
            legs(c,[-6,6],-16,main.darkened(0.3),t,4)
        "colossus":
            for i in range(3):
                for side in [-1,1]:
                    var y=-56+i*12
                    var reach=26+sin(t*2+i+side)*6
                    c.draw_line(Vector2(side*16,y),Vector2(side*(16+reach),y-10+i*6),OUTLINE,9,true)
                    c.draw_line(Vector2(side*16,y),Vector2(side*(16+reach),y-10+i*6),main.lightened(0.1),7,true)
            box(c,Rect2(-18,-70,36,70),main)
            box(c,Rect2(-13,-90,26,22),main.lightened(0.1))
            eyes(c,Vector2(0,-80),6,3,true,accent)
            for crack in [[Vector2(-10,-60),Vector2(0,-46)],[Vector2(0,-46),Vector2(10,-56)],[Vector2(-6,-30),Vector2(6,-18)]]:
                c.draw_line(crack[0],crack[1],accent,2.5)
        "wyrm":
            legs(c,[-14,14],-14,main.darkened(0.25),t,8)
            poly(c,[Vector2(-24,-24),Vector2(-48,-10+sin(t*3)*4),Vector2(-22,-14)],main.darkened(0.1))
            var f=sin(t*5)*8
            poly(c,[Vector2(-8,-40),Vector2(-34,-74-f),Vector2(4,-46)],main.darkened(0.2))
            blob(c,Vector2(0,-28),26,17,main)
            for i in range(3):
                var base=Vector2(10,-40)
                var head=Vector2(20+i*10,-64+i*10+sin(t*3+i)*4)
                c.draw_line(base,head,OUTLINE,8,true)
                c.draw_line(base,head,main,6,true)
                blob(c,head,8,6,main.lightened(0.08),1.5)
                c.draw_circle(head+Vector2(3,-2),1.8,accent)
        "idol":
            blob(c,Vector2(0,-30),22,26,main)
            for i in range(5):
                var a=-PI/2+i*TAU/5
                c.draw_line(Vector2(0,-30),Vector2(0,-30)+Vector2(cos(a),sin(a))*14,accent,2)
            c.draw_arc(Vector2(0,-30),30+sin(t*3)*2,0,TAU,32,Color(accent,0.6),2)
            eyes(c,Vector2(0,-36),7,3,false,accent)
            c.draw_line(Vector2(-20,-26),Vector2(-30,-36+sin(t*4)*4),OUTLINE,5,true)
            c.draw_line(Vector2(20,-26),Vector2(30,-36-sin(t*4)*4),OUTLINE,5,true)
        _:
            blob(c,Vector2(0,-15),20,15,main)
            eyes(c,Vector2(3,-16),6,3)
    c.draw_set_transform(Vector2.ZERO)
