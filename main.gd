extends Node3D

# All artwork is generated locally; no external assets or plugins required.
const GREEN = Color("67efad")
const PURPLE = Color("b385ef")
const BONE = Color("d8d5ba")
var player: Node3D
var camera: Camera3D
var destination = Vector3.ZERO
var health = 100.0
var enemies: Array = []
var summons: Array = []
var corpses: Array = []
var drops: Array = []
var effects: Array = []
var cooldowns = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var cooldown_limits = [0.45, 1.0, 0.7, 5.0, 7.0, 15.0]
var loot_count = 0
var trait_unlocked = false
var frenzy = 0.0
var respawn_timer = 0.0
var golem_timer = 0.0
var victories = 0
var toast_timer = 0.0
var toast_label: Label
var status_label: Label
var ability_buttons: Array = []
var victory = false
var smoke_mode = false

func _ready():
    build_world()
    build_ui()
    load_progress()
    start_run()
    notify("Claim the crypt. Your army obeys.")

func material(color: Color, glow = false) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.85
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.6
    return m

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, glow = false) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var shape = BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.material_override = material(color, glow)
    mesh.position = pos
    parent.add_child(mesh)
    return mesh

func orb(parent: Node3D, radius: float, pos: Vector3, color: Color, glow = false) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var shape = SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2
    mesh.mesh = shape
    mesh.material_override = material(color, glow)
    mesh.position = pos
    parent.add_child(mesh)
    return mesh

func actor(pos: Vector3, color: Color, kind: String) -> Node3D:
    var n = Node3D.new()
    add_child(n)
    n.position = pos
    var scale_factor = 1.0
    if kind == "golem": scale_factor = 1.65
    if kind == "boss": scale_factor = 2.0
    if kind == "elite": scale_factor = 1.3
    box(n, Vector3(0.65, 0.9, 0.4), Vector3(0, 0.9, 0), color)
    orb(n, 0.25, Vector3(0, 1.6, 0), color)
    for side in [-1, 1]:
        box(n, Vector3(0.18, 0.65, 0.22), Vector3(side * 0.2, 0.32, 0), color.darkened(0.15))
        box(n, Vector3(0.22, 0.75, 0.24), Vector3(side * 0.47, 0.92, 0), color)
        orb(n, 0.06, Vector3(side * 0.09, 1.64, -0.23), GREEN if kind in ["hero", "skeleton", "golem"] else Color("ff6f8c"), true)
    if kind == "hero":
        box(n, Vector3(0.08, 1.5, 0.08), Vector3(0.65, 1, 0), BONE)
        orb(n, 0.15, Vector3(0.65, 1.85, 0), GREEN, true)
    if kind == "golem" or kind == "boss":
        box(n, Vector3(0.15, 0.65, 0.07), Vector3(0, 1, -0.24), GREEN if kind == "golem" else PURPLE, true)
    n.scale = Vector3.ONE * scale_factor
    return n

func build_world():
    var world = WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("0b101c")
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("96a2bd")
    world.environment.ambient_light_energy = 0.65
    add_child(world)
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-65, -25, 0)
    light.light_color = Color("c7d4ff")
    light.light_energy = 0.85
    add_child(light)
    for x in range(-8, 9):
        for z in range(-13, 6):
            var shade = 0.13 + float(posmod(x * 7 + z * 13, 5)) * 0.012
            box(self, Vector3(1.96, 0.2, 1.96), Vector3(x * 2, -0.2, z * 2), Color(shade, shade * 1.08, shade * 1.25))
    for x in [-18, 18]:
        box(self, Vector3(1, 3, 40), Vector3(x, 1.3, -8), Color("242537"))
        for z in range(-26, 12, 6):
            box(self, Vector3(1.8, 4.5, 1.8), Vector3(x, 2, z), Color("303247"))
            orb(self, 0.18, Vector3(x * 0.94, 2, z), GREEN, true)
    for z in [-28, 12]:
        box(self, Vector3(37, 2.8, 1), Vector3(0, 1.2, z), Color("242537"))
    for z in [-19, -7, 5]:
        for x in [-14, 14]:
            box(self, Vector3(2, 0.9, 3), Vector3(x, 0.3, z), Color("444356"))
            box(self, Vector3(0.2, 0.12, 1.2), Vector3(x, 0.85, z), BONE.darkened(0.4))
            box(self, Vector3(0.8, 0.12, 0.2), Vector3(x, 0.85, z - 0.2), BONE.darkened(0.4))
    player = actor(Vector3(0, 0, 7), Color("443451"), "hero")
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 25
    camera.far = 120
    add_child(camera)
    camera.current = true
    update_camera()

func build_ui():
    var layer = CanvasLayer.new()
    add_child(layer)
    var layout = Control.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(layout)
    var title = Label.new()
    title.text = "CRYPT SOVEREIGN  /  SUMMONER PROTOTYPE"
    title.position = Vector2(22, 14)
    title.add_theme_color_override("font_color", GREEN)
    title.add_theme_font_size_override("font_size", 22)
    layout.add_child(title)
    status_label = Label.new()
    status_label.position = Vector2(22, 47)
    status_label.add_theme_font_size_override("font_size", 17)
    layout.add_child(status_label)
    var help = Label.new()
    help.text = "CLICK floor: move  •  CLICK glowing loot: collect\n1–6: cast at cursor  •  R: new run, keep loot\nMinions fight automatically. Find the violet elite."
    help.position = Vector2(22, 82)
    help.add_theme_font_size_override("font_size", 15)
    layout.add_child(help)
    toast_label = Label.new()
    toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    toast_label.position += Vector2(-280, 140)
    toast_label.size = Vector2(560, 70)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.add_theme_color_override("font_color", GREEN)
    toast_label.add_theme_font_size_override("font_size", 22)
    layout.add_child(toast_label)
    var bar = HBoxContainer.new()
    bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    bar.position += Vector2(-450, -94)
    bar.add_theme_constant_override("separation", 8)
    layout.add_child(bar)
    var names = ["Bone Bolt", "Raise Dead", "Corpse Blast", "Golem Slam", "Soul Siphon", "Frenzy"]
    for i in range(6):
        var button = Button.new()
        button.custom_minimum_size = Vector2(142, 65)
        button.text = str(i + 1) + "\n" + names[i]
        button.tooltip_text = "Press " + str(i + 1) + " while aiming with your mouse"
        button.pressed.connect(func(): cast(i, cursor_ground()))
        bar.add_child(button)
        ability_buttons.append({"button": button, "name": names[i]})
    var save_button = Button.new()
    save_button.text = "Save loot"
    save_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    save_button.position += Vector2(-130, 20)
    save_button.size = Vector2(110, 35)
    save_button.pressed.connect(func(): save_progress(); notify("Loot saved on this device."))
    layout.add_child(save_button)

func cursor_ground() -> Vector3:
    var mouse = get_viewport().get_mouse_position()
    var origin = camera.project_ray_origin(mouse)
    var direction = camera.project_ray_normal(mouse)
    var hit = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
    if hit == null: return player.position
    return Vector3(clampf(hit.x, -16, 16), 0, clampf(hit.z, -26, 10))

func _unhandled_input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        destination = cursor_ground()
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode >= KEY_1 and event.keycode <= KEY_6:
            cast(event.keycode - KEY_1, cursor_ground())
        if event.keycode == KEY_R: start_run()

func start_run():
    for collection in [enemies, summons, corpses, drops]:
        for entry in collection:
            entry.node.queue_free()
        collection.clear()
    player.position = Vector3(0, 0, 7)
    destination = player.position
    health = 100
    respawn_timer = 0
    golem_timer = 0
    frenzy = 0
    victory = false
    cooldowns = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    for i in range(3): add_summon("skeleton", player.position + Vector3(i - 1, 0, 1))
    add_summon("golem", player.position + Vector3(2, 0, 0))
    for p in [Vector3(-4, 0, 0), Vector3(3, 0, -2), Vector3(0, 0, -4), Vector3(-7, 0, -9), Vector3(5, 0, -11), Vector3(-3, 0, -15), Vector3(6, 0, -19)]:
        add_enemy("guard", p)
    for p in [Vector3(6, 0, -5), Vector3(-5, 0, -12), Vector3(4, 0, -20)]: add_enemy("acolyte", p)
    add_enemy("elite", Vector3(-4, 0, -18))
    add_enemy("boss", Vector3(0, 0, -24))

func add_summon(kind: String, pos: Vector3):
    var hp = 160.0 if kind == "golem" else 45.0
    var n = actor(pos, Color("687779") if kind == "golem" else BONE, kind)
    if kind == "golem" and trait_unlocked:
        box(n, Vector3(1.1, 0.25, 0.6), Vector3(0, 1.3, 0), PURPLE)
    summons.append({"node": n, "kind": kind, "hp": hp, "cd": 0.0, "command": null})

func add_enemy(kind: String, pos: Vector3):
    var hp = {"guard": 55.0, "acolyte": 40.0, "elite": 160.0, "boss": 420.0}[kind]
    var color = {"guard": Color("94525d"), "acolyte": Color("756087"), "elite": PURPLE, "boss": Color("743850")}[kind]
    var n = actor(pos, color, kind)
    var label = Label3D.new()
    label.position.y = 2.8 if kind == "boss" else 2.2
    label.font_size = 32
    label.pixel_size = 0.012
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    n.add_child(label)
    enemies.append({"node": n, "kind": kind, "hp": hp, "maxhp": hp, "cd": 1.0, "label": label, "phase": false, "windup": 0.0, "slam_pos": Vector3.ZERO})

func closest_enemy(pos: Vector3, radius: float):
    var found = null
    for e in enemies:
        var distance = e.node.position.distance_to(pos)
        if distance < radius:
            radius = distance
            found = e
    return found

func closest_corpse(pos: Vector3):
    var found = null
    var distance = 3.0
    for c in corpses:
        var d = c.node.position.distance_to(pos)
        if d < distance and c.node.position.distance_to(player.position) <= 11:
            distance = d
            found = c
    return found

func consume_corpse(c):
    corpses.erase(c)
    c.node.queue_free()

func cast(slot: int, target: Vector3):
    if health <= 0 or cooldowns[slot] > 0: return
    match slot:
        0:
            var e = closest_enemy(target, 4)
            if e == null or e.node.position.distance_to(player.position) > 13:
                notify("Aim Bone Bolt at an enemy within range."); return
            burst(e.node.position, GREEN, 0.7)
            damage_enemy(e, 18 + loot_count * 2)
        1:
            if skeleton_count() >= 3: notify("Your three skeletons are already summoned."); return
            var c = closest_corpse(target)
            if c == null: notify("Aim at a green corpse to raise a skeleton."); return
            add_summon("skeleton", c.node.position)
            consume_corpse(c)
        2:
            var c = closest_corpse(target)
            if c == null: notify("Aim at a green corpse within range."); return
            var pos = c.node.position
            consume_corpse(c)
            burst(pos, GREEN, 4.0)
            for e in enemies.duplicate():
                if e.node.position.distance_to(pos) < 4: damage_enemy(e, 60 + loot_count * 3)
        3:
            var golem = get_golem()
            if golem == null: notify("Your golem is reforming."); return
            if player.position.distance_to(target) > 14: notify("Golem target is too far away."); return
            golem.command = target
            burst(target, PURPLE, 0.7)
        4:
            var e = closest_enemy(target, 4)
            if e == null or e.node.position.distance_to(player.position) > 11:
                notify("Aim Soul Siphon at a nearby enemy."); return
            damage_enemy(e, 30 + loot_count * 2)
            health = minf(100, health + 30)
            burst(player.position, PURPLE, 1.5)
        5:
            frenzy = 6
            burst(player.position, GREEN, 3)
            notify("Your army hungers! Frenzy: 6 seconds.")
    cooldowns[slot] = cooldown_limits[slot]

func damage_enemy(e, amount: float):
    if not enemies.has(e): return
    e.hp -= amount
    if e.hp > 0: return
    var pos = e.node.position
    var kind = e.kind
    enemies.erase(e)
    e.node.queue_free()
    var body = Node3D.new()
    add_child(body)
    body.position = pos
    box(body, Vector3(0.9, 0.13, 0.65), Vector3(0, 0.05, 0), GREEN.darkened(0.45), true)
    orb(body, 0.14, Vector3(0, 0.35, 0), GREEN, true)
    corpses.append({"node": body, "ttl": 30.0})
    if kind in ["elite", "boss"] or randf() < 0.45:
        var drop = Node3D.new()
        add_child(drop)
        drop.position = pos + Vector3(0.6, 0, 0.5)
        orb(drop, 0.22, Vector3(0, 0.6, 0), PURPLE if kind == "elite" else Color("ffc66d"), true)
        drops.append({"node": drop, "trait": kind == "elite"})
    if kind == "boss":
        victory = true
        victories += 1
        save_progress()
        notify("THE CRYPT IS YOURS. Collect loot, then press R for a new run.", 12)

func burst(pos: Vector3, color: Color, radius: float):
    var n = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.top_radius = 1
    mesh.bottom_radius = 1
    mesh.height = 0.06
    n.mesh = mesh
    n.material_override = material(color, true)
    n.position = pos + Vector3(0, 0.06, 0)
    n.scale = Vector3(0.1, 1, 0.1)
    add_child(n)
    effects.append({"node": n, "age": 0.0, "radius": radius})

func move_actor(n: Node3D, target: Vector3, speed: float, delta: float):
    var direction = target - n.position
    direction.y = 0
    if direction.length() > 0.1:
        n.position += direction.normalized() * minf(speed * delta, direction.length())
        n.rotation.y = atan2(-direction.x, -direction.z)
    n.position.x = clampf(n.position.x, -16.5, 16.5)
    n.position.z = clampf(n.position.z, -26.5, 10.5)

func _process(delta):
    if smoke_mode: return
    tick(delta)

func tick(delta: float):
    for i in range(6): cooldowns[i] = maxf(0, cooldowns[i] - delta)
    frenzy = maxf(0, frenzy - delta)
    toast_timer -= delta
    if toast_timer <= 0: toast_label.text = ""
    if health <= 0:
        respawn_timer -= delta
        if respawn_timer <= 0:
            start_run()
            notify("You return. Your collected loot remains.")
    else:
        move_actor(player, destination, 5.5, delta)
        tick_summons(delta)
        tick_enemies(delta)
        for d in drops.duplicate():
            if d.node.position.distance_to(player.position) < 1.3:
                collect_drop(d)
        if get_golem() == null:
            golem_timer -= delta
            if golem_timer <= 0: add_summon("golem", player.position + Vector3(1, 0, 0))
    for c in corpses.duplicate():
        c.ttl -= delta
        if c.ttl <= 0: consume_corpse(c)
    for fx in effects.duplicate():
        fx.age += delta
        var radius = lerpf(0.1, fx.radius, minf(1, fx.age * 4))
        fx.node.scale = Vector3(radius, 1, radius)
        if fx.age > 0.35:
            fx.node.queue_free()
            effects.erase(fx)
    update_camera()
    update_ui()

func tick_summons(delta: float):
    for s in summons.duplicate():
        s.cd = maxf(0, s.cd - delta)
        var e = closest_enemy(s.node.position, 9)
        var is_golem = s.kind == "golem"
        if s.command != null:
            move_actor(s.node, s.command, 8, delta)
            if s.node.position.distance_to(s.command) < 0.5:
                burst(s.command, PURPLE, 3.5)
                for victim in enemies.duplicate():
                    if victim.node.position.distance_to(s.command) < 3.5: damage_enemy(victim, 65 + loot_count * 3)
                s.command = null
        elif e != null and s.node.position.distance_to(player.position) < 13:
            move_actor(s.node, e.node.position, 4.5, delta)
            if s.node.position.distance_to(e.node.position) < 1.5 and s.cd <= 0:
                damage_enemy(e, (14 if is_golem else 7) + loot_count)
                s.cd = 0.5 if frenzy > 0 else 1.0
        else:
            var index = summons.find(s)
            var offset = Vector3(cos(index * 1.6), 0, sin(index * 1.6)) * 2
            move_actor(s.node, player.position + offset, 5, delta)

func tick_enemies(delta: float):
    for e in enemies.duplicate():
        e.cd = maxf(0, e.cd - delta)
        e.label.text = (e.kind.to_upper() + "  " if e.kind in ["boss", "elite"] else "") + str(int(maxf(0, e.hp)))
        if e.node.position.distance_to(player.position) > 13: continue
        if e.kind == "boss" and e.hp < e.maxhp * 0.5 and not e.phase:
            e.phase = true
            for offset in [Vector3(-3, 0, 0), Vector3(3, 0, 0)]: add_enemy("guard", e.node.position + offset)
            notify("The crypt lord calls its guards!")
        if e.windup > 0:
            e.windup -= delta
            if e.windup <= 0:
                burst(e.slam_pos, Color("ff6f8c"), 3.5)
                if player.position.distance_to(e.slam_pos) < 3.5: hurt_player(25)
                for s in summons.duplicate():
                    if s.node.position.distance_to(e.slam_pos) < 3.5: hurt_summon(s, 25)
            continue
        var target_node = player
        var target_summon = null
        var near = e.node.position.distance_to(player.position)
        for s in summons:
            var distance = e.node.position.distance_to(s.node.position)
            if distance < near:
                near = distance
                target_node = s.node
                target_summon = s
        var reach = 7.0 if e.kind == "acolyte" else 1.5
        if near > reach:
            move_actor(e.node, target_node.position, 2.8 if e.kind != "boss" else 2.1, delta)
        elif e.cd <= 0:
            e.cd = 2.8 if e.kind == "boss" else 1.4
            if e.kind == "boss":
                e.windup = 1.0
                e.slam_pos = target_node.position
                burst(e.slam_pos, Color("943e59"), 3.5)
            else:
                var damage = 8 if e.kind != "elite" else 14
                if target_summon == null: hurt_player(damage)
                else: hurt_summon(target_summon, damage)
                burst(target_node.position, Color("bc5565"), 0.6)

func hurt_player(amount: float):
    health = maxf(0, health - amount)
    if health <= 0:
        respawn_timer = 2
        save_progress()
        notify("Your body falls. Your power endures.")

func hurt_summon(s, amount: float):
    if not summons.has(s): return
    if s.kind == "golem" and trait_unlocked: amount *= 0.6
    s.hp -= amount
    if s.hp <= 0:
        summons.erase(s)
        s.node.queue_free()
        if s.kind == "golem": golem_timer = 10

func skeleton_count() -> int:
    var count = 0
    for s in summons:
        if s.kind == "skeleton": count += 1
    return count

func get_golem():
    for s in summons:
        if s.kind == "golem": return s
    return null

func collect_drop(d):
    if not drops.has(d): return
    loot_count += 1
    if d.trait:
        trait_unlocked = true
        var g = get_golem()
        if g != null: box(g.node, Vector3(1.1, 0.25, 0.6), Vector3(0, 1.3, 0), PURPLE)
        notify("BONE PLATING CLAIMED. Golem takes 40% less damage.", 6)
    else: notify("Relic claimed. Your spells and army grow stronger.")
    drops.erase(d)
    d.node.queue_free()
    save_progress()

func update_camera():
    camera.position = player.position + Vector3(0, 21, 16)
    camera.look_at(player.position + Vector3(0, 0, -2))

func update_ui():
    status_label.text = "HEALTH %d / 100    SKELETONS %d / 3    RELICS %d    %s" % [int(health), skeleton_count(), loot_count, "GOLEM: BONE PLATING" if trait_unlocked else "GOLEM: " + ("READY" if get_golem() != null else "REFORMING")]
    for i in range(6):
        var entry = ability_buttons[i]
        entry.button.text = str(i + 1) + "  " + ("%.1fs" % cooldowns[i] if cooldowns[i] > 0 else "READY") + "\n" + entry.name
        entry.button.modulate = Color("82a395") if cooldowns[i] > 0 else Color.WHITE

func notify(message: String, duration = 3.5):
    toast_label.text = message
    toast_timer = duration

func save_progress():
    if smoke_mode: return
    var file = FileAccess.open("user://crypt_sovereign.json", FileAccess.WRITE)
    if file == null:
        notify("Save unavailable. Loot is kept for this session only."); return
    file.store_string(JSON.stringify({"version": 1, "loot": loot_count, "trait": trait_unlocked, "wins": victories}))

func load_progress():
    if not FileAccess.file_exists("user://crypt_sovereign.json"): return
    var file = FileAccess.open("user://crypt_sovereign.json", FileAccess.READ)
    if file == null: return
    var data = JSON.parse_string(file.get_as_text())
    if not data is Dictionary: return
    loot_count = clampi(int(data.get("loot", 0)), 0, 999)
    trait_unlocked = data.get("trait", false) == true
    victories = clampi(int(data.get("wins", 0)), 0, 999)
