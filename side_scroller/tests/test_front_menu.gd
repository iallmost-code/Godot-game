extends RefCounted
const H=preload("res://tests/helpers.gd")
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    t.check(game.has_method("return_to_title"),"game has a save-and-return main menu flow")
    if not game.has_method("return_to_title"):
        game.queue_free()
        await t.process_frame
        return
    var files=[]
    for slot in game.save_store.slot_paths:
        var path="user://front-menu-test-"+slot+".json"
        files.append(path)
        game.save_store.slot_paths[slot]=path
    game.save_store.selection_path="user://front-menu-test-slot.txt"
    files.append(game.save_store.selection_path)
    for path in files:
        if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
    game.save_store.use_slot("warrior")
    var thief=H.make("thief",["thief","assassin","hermit","night_lord"],150)
    thief.coins=54321
    var file=FileAccess.open(game.save_store.slot_paths.thief,FileAccess.WRITE)
    file.store_string(game.save_store.export_json(thief,game.bindings))
    file.close()
    t.check(game.return_to_title() and game.frontend.opened and t.paused,"main menu pauses the world after saving current progress")
    game.frontend.show_characters()
    var slots=game.frontend.summaries()
    t.check(slots.size()==4 and slots.thief.level==150 and slots.thief.job=="Nightblade","character select previews all four slots and saved job progress")
    t.check(not slots.magician.exists,"an empty slot is offered as a new character")
    game.frontend.choose_slot("thief")
    t.check(game.frontend.play_selected() and game.state.level==150 and game.state.coins==54321 and game.state.job=="night_lord","Play loads the chosen existing character without resetting it")
    t.check(not game.frontend.opened and not t.paused,"playing closes the main menu and resumes gameplay")
    game.state.coins=54322
    t.check(game.return_to_title(),"returning from gameplay opens the title screen")
    var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_store.slot_paths.thief))
    t.check(saved.character.coins==54322 and saved.character.level==150,"returning to title saves the active slot")
    game.frontend.show_settings()
    t.check(game.frontend.mode=="settings","main menu has keyboard and audio settings")
    game.frontend.show_characters()
    game.frontend.choose_slot("magician")
    t.check(game.frontend.play_selected() and game.state.archetype=="magician" and game.state.level==1,"an empty class slot starts a new character")
    t.check(JSON.parse_string(FileAccess.get_file_as_string(game.save_store.slot_paths.thief)).character.coins==54322,"creating another class preserves the existing thief save")
    game.save_store.path="user://front-menu-missing-directory/save.json"
    t.check(not game.return_to_title() and not game.frontend.opened and not t.paused,"a failed save keeps gameplay active instead of leaving the character")
    game.save_store.path=game.save_store.slot_paths.magician
    file=FileAccess.open(game.save_store.slot_paths.bowman,FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    game.frontend.show_characters()
    t.check(not game.frontend.summaries().bowman.valid,"character select detects invalid save data")
    game.frontend.choose_slot("bowman")
    t.check(not game.frontend.play_selected() and game.state.archetype=="magician","an invalid slot cannot overwrite the active character")
    game.frontend.resume_game()
    file=FileAccess.open(game.save_store.slot_paths.magician,FileAccess.WRITE)
    file.store_string("{original-unreadable-save")
    file.close()
    game.loaded_character=false
    game.protected_startup_save=true
    game.frontend.session_started=false
    game.frontend.open_title()
    game.test_mode=false
    game.persist()
    game.test_mode=true
    t.check(FileAccess.get_file_as_string(game.save_store.slot_paths.magician)=="{original-unreadable-save","title settings cannot replace an unreadable current save")
    game.frontend.choose_slot("warrior")
    t.check(game.frontend.play_selected() and FileAccess.get_file_as_string(game.save_store.slot_paths.magician)=="{original-unreadable-save","choosing another character preserves an unreadable startup save")
    game.frontend.resume_game()
    game.queue_free()
    await t.process_frame
    for path in files:
        if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
