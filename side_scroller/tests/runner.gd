extends SceneTree
var checks = 0
var failures: Array[String] = []
func _initialize():
    call_deferred("run_all")
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures.append(message)
        print("FAIL: ", message)
func run_all():
    var selection = ""
    var args = OS.get_cmdline_user_args()
    if args.size() >= 2 and args[0] == "--suite": selection = args[1]
    for name in ["enemy_damage", "menu_shortcuts", "briar", "bulk_stats", "partner", "classes", "stars", "animation", "lunge", "progression", "movement", "combat", "equipment", "ui", "world", "save", "skills", "roster"]:
        if selection != "" and selection != name: continue
        var path = "res://tests/test_" + name + ".gd"
        if not FileAccess.file_exists(path): continue
        print("SUITE: ", name)
        var script = load(path)
        if script == null:
            check(false, "suite parses: " + name)
            continue
        var suite = script.new()
        await suite.run(self)
    print("RESULT: ", checks - failures.size(), "/", checks, " passed")
    quit(1 if checks == 0 or not failures.is_empty() else 0)
