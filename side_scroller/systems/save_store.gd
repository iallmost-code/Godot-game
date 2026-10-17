extends Node
const Character=preload("res://systems/character_state.gd")
const Bindings=preload("res://systems/input_bindings.gd")
var path="user://side_scroller.json"
var slot_paths={"warrior":"user://side_scroller.json","thief":"user://side_scroller_thief.json","magician":"user://side_scroller_magician.json","bowman":"user://side_scroller_bowman.json"}
var selection_path="user://side_scroller_slot.txt"
var active_slot="warrior"
func selected_slot() -> String:
    if FileAccess.file_exists(selection_path):
        var selected=FileAccess.get_file_as_string(selection_path).strip_edges()
        if slot_paths.has(selected): return selected
    return "warrior"
func remember_slot(slot: String) -> bool:
    if not slot_paths.has(slot): return false
    var file=FileAccess.open(selection_path,FileAccess.WRITE)
    if file==null:
        warning.emit("Cannot switch characters here: current progress was kept.")
        return false
    file.store_string(slot)
    file.close()
    return true
func use_slot(slot: String):
    active_slot=slot
    path=slot_paths[slot]

var browser_callback
var pending_state
var pending_bindings
signal warning(message: String)
func export_json(state,bindings) -> String:
    return JSON.stringify({"version":2,"character":state.to_record(),"bindings":bindings.current()},"\t")
func import_json(text: String,state,bindings) -> bool:
    if text.length()>1048576: return false
    var parser=JSON.new()
    if parser.parse(text)!=OK: return false
    var data=parser.data
    if not data is Dictionary or not (data.get("version",0)==1 or data.get("version",0)==2) or not data.get("character",null) is Dictionary or not data.get("bindings",null) is Dictionary: return false
    var staged=Character.new()
    if not staged.load_record(data.character) or staged.archetype!=state.archetype: return false
    var validator=Bindings.new()
    # Validate bindings without changing the live InputMap on rejection.
    var before=bindings.current()
    if not validator.apply(data.bindings): return false
    bindings.apply(validator.current())
    if not state.load_record(data.character):
        bindings.apply(before)
        return false
    return true
func save(state,bindings) -> bool:
    var temporary=path+".tmp"
    var file=FileAccess.open(temporary,FileAccess.WRITE)
    if file==null:
        warning.emit("Cannot save here. Export a backup to keep your progress.")
        return false
    file.store_string(export_json(state,bindings))
    file.flush()
    var status=file.get_error()
    file.close()
    if status!=OK: return false
    var result=DirAccess.rename_absolute(temporary,path)
    if result!=OK:
        warning.emit("Save could not be replaced. Previous save was preserved.")
        return false
    return true
func load_into(state,bindings) -> bool:
    if not FileAccess.file_exists(path): return false
    var file=FileAccess.open(path,FileAccess.READ)
    if file==null: return false
    if file.get_length()>1048576:
        warning.emit("Save is too large and was not loaded.")
        return false
    var text=file.get_as_text()
    file.close()
    if import_json(text,state,bindings): return true
    DirAccess.copy_absolute(path,path+".corrupt-backup")
    warning.emit("Save is invalid. A fresh character is active; original save was backed up.")
    return false
func export_backup(state,bindings):
    var text=export_json(state,bindings)
    if OS.has_feature("web"):
        JavaScriptBridge.download_buffer(text.to_utf8_buffer(),"Windswept-"+state.archetype+"-save.json","application/json")
        warning.emit("Backup download requested.")
    else:
        var dialog=FileDialog.new()
        dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE
        dialog.access=FileDialog.ACCESS_FILESYSTEM
        dialog.current_file="Windswept-"+state.archetype+"-save.json"
        dialog.filters=PackedStringArray(["*.json ; Character save"])
        dialog.process_mode=Node.PROCESS_MODE_ALWAYS
        add_child(dialog)
        dialog.file_selected.connect(func(filename):
            var file=FileAccess.open(filename,FileAccess.WRITE)
            if file!=null: file.store_string(text); warning.emit("Backup saved.")
            dialog.queue_free())
        dialog.canceled.connect(dialog.queue_free)
        dialog.popup_centered(Vector2i(800,500))
func import_backup(state,bindings):
    pending_state=state
    pending_bindings=bindings
    if OS.has_feature("web"):
        if browser_callback==null: browser_callback=JavaScriptBridge.create_callback(_browser_file)
        var window=JavaScriptBridge.get_interface("window")
        window.windsweptImport=browser_callback
        JavaScriptBridge.eval("""
            const picker = document.createElement('input');
            picker.type = 'file'; picker.accept = '.json,application/json';
            picker.onchange = () => {
                const file = picker.files[0]; if (!file) return;
                if (file.size > 1048576) { window.windsweptImport(''); return; }
                const reader = new FileReader();
                reader.onload = () => window.windsweptImport(String(reader.result));
                reader.readAsText(file);
            };
            picker.click();
        """,true)
    else:
        var dialog=FileDialog.new()
        dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
        dialog.access=FileDialog.ACCESS_FILESYSTEM
        dialog.filters=PackedStringArray(["*.json ; Character save"])
        dialog.process_mode=Node.PROCESS_MODE_ALWAYS
        add_child(dialog)
        dialog.file_selected.connect(func(filename):
            var file=FileAccess.open(filename,FileAccess.READ)
            if file!=null and file.get_length()<=1048576: finish_import(file.get_as_text())
            else: warning.emit("Backup cannot be read or is too large.")
            dialog.queue_free())
        dialog.canceled.connect(dialog.queue_free)
        dialog.popup_centered(Vector2i(800,500))
func _browser_file(args):
    if args.size()>0: finish_import(str(args[0]))
func finish_import(text: String):
    if import_json(text,pending_state,pending_bindings):
        save(pending_state,pending_bindings)
        warning.emit("Backup imported. Close and reopen panels to refresh their contents.")
    else: warning.emit("Invalid backup. Your current character was not changed.")
