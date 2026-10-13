extends SceneTree

var checks = 0
var game

func _initialize():
    call_deferred("run_checks")

func check(condition: bool, message: String):
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
        return false
    checks += 1
    print("PASS: " + message)
    return true

func run_checks():
    game = load("res://main.tscn").instantiate()
    game.smoke_mode = true
    root.add_child(game)
    game.loot_count = 0
    game.trait_unlocked = false
    game.start_run()
    if not check(game.skeleton_count() == 3 and game.get_golem() != null, "army starts with three skeletons and a golem"): return
    var before = game.player.position
    game.destination = before + Vector3(3, 0, 0)
    game.tick(0.1)
    if not check(game.player.position.x > before.x, "movement advances toward destination"): return
    var enemy = game.enemies[0]
    enemy.node.position = game.player.position + Vector3(0, 0, -3)
    var hp = enemy.hp
    game.cast(0, enemy.node.position)
    if not check(enemy.hp < hp, "Bone Bolt damages aimed enemy"): return
    hp = enemy.hp
    game.cast(0, enemy.node.position)
    if not check(enemy.hp == hp, "cooldown blocks repeat cast"): return
    game.damage_enemy(enemy, 1000)
    if not check(not game.enemies.has(enemy) and game.corpses.size() == 1, "enemy death creates a corpse"): return
    var corpse = game.corpses[0]
    var pos = corpse.node.position
    var victim = game.enemies[0]
    victim.node.position = pos + Vector3(1, 0, 0)
    game.cast(2, pos)
    if not check(not game.corpses.has(corpse) and not game.enemies.has(victim), "corpse explosion consumes corpse and kills nearby target"): return
    var new_corpse = game.corpses[0]
    var s = game.summons[0]
    game.hurt_summon(s, 1000)
    game.cast(1, new_corpse.node.position)
    if not check(game.skeleton_count() == 3 and not game.corpses.has(new_corpse), "raise dead replaces lost skeleton and consumes corpse"): return
    var count = game.corpses.size()
    game.cooldowns[1] = 0
    game.cast(1, pos)
    if not check(game.skeleton_count() == 3 and game.corpses.size() == count, "summon cap prevents over-summoning"): return
    var g = game.get_golem()
    victim = game.enemies[0]
    victim.node.position = game.player.position + Vector3(2, 0, -1)
    g.node.position = victim.node.position
    game.cast(3, victim.node.position)
    hp = victim.hp
    game.tick_summons(0.05)
    if not check(not game.enemies.has(victim) or victim.hp < hp, "commanded golem slam deals damage"): return
    game.health = 40
    victim = game.enemies[0]
    victim.node.position = game.player.position + Vector3(0, 0, -2)
    game.cast(4, victim.node.position)
    if not check(game.health == 70, "Soul Siphon restores health"): return
    game.cast(5, game.player.position)
    if not check(game.frenzy == 6, "Frenzy activates for six seconds"): return
    var elite
    for e in game.enemies:
        if e.kind == "elite": elite = e
    game.damage_enemy(elite, 1000)
    var trait_drop
    for d in game.drops:
        if d.trait: trait_drop = d
    game.collect_drop(trait_drop)
    if not check(game.trait_unlocked and game.loot_count == 1, "elite loot unlocks golem trait and power"): return
    g = game.get_golem()
    hp = g.hp
    game.hurt_summon(g, 10)
    if not check(is_equal_approx(g.hp, hp - 6), "Bone Plating reduces damage by forty percent"): return
    game.hurt_player(1000)
    game.tick(2.1)
    if not check(game.health == 100 and game.loot_count == 1 and game.trait_unlocked and game.skeleton_count() == 3, "death resets run while keeping collected loot and trait"): return
    game.smoke_mode = false
    game.save_progress()
    game.loot_count = 0
    game.trait_unlocked = false
    game.load_progress()
    if not check(game.loot_count == 1 and game.trait_unlocked, "loot save round trip"): return
    game.smoke_mode = true
    var boss
    for e in game.enemies:
        if e.kind == "boss": boss = e
    game.damage_enemy(boss, 1000)
    if not check(game.victory and game.victories > 0, "boss death triggers victory"): return
    print("ALL ", checks, " GAMEPLAY CHECKS PASSED")
    game.queue_free()
    quit(0)
