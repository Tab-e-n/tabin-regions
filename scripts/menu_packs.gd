extends MenuScene


var current_pack_name: String = ""

@onready var pack_list: SelectionList = $packs as SelectionList

@onready var dir_window: FileDialog = $dir_window as FileDialog
@onready var dir_warning: Control = $dir_warning as Control
@onready var remove_popup: Control = $remove_popup as Control

@onready var pack_title: Label = $pack_title as Label
@onready var pack_lore: Label = $pack_lore as Label


func _start() -> void:
	setup_pack_list(Options.allowed_directories)


func load_pack_info(dir: String = MapSetup.current_directory) -> Dictionary:
	var info: Dictionary = {
		"title" : dir,
		"lore" : "A pack of maps.",
	}
	
	if FileAccess.file_exists(dir + "/info.json"):
		var file = FileAccess.open(dir + "/info.json", FileAccess.READ)
		
		info = JSON.parse_string(file.get_as_text())
		
		file.close()
		
	return info


func set_info(info: Dictionary):
	current_pack_name = info["title"]
	pack_title.text = info["title"]
	pack_lore.text = info["lore"]


func setup_pack_list(pack_names: PackedStringArray, selected_pack: String = MapSetup.current_directory) -> void:
	pack_list.clear()
	
	var selected_item: SelectionListItem = null
	
	pack_list.add_item("res://maps", "Base Maps")
	for pack_name in pack_names:
		var info: Dictionary = load_pack_info(pack_name)
		var item: SelectionListItem = pack_list.add_item(pack_name, info["title"])
		if pack_name == selected_pack:
			selected_item = item
	
	if selected_item == null:
		pack_list.select_index(0)
	else:
		pack_list.select_item(selected_item)
	change_directory_visual(pack_list.get_selected_item().value)


func add_directory(dir: String):
	Options.allow_directory(dir)
	setup_pack_list(Options.allowed_directories, dir)


func remove_directory(dir: String):
	Options.disallow_directory(dir)
	setup_pack_list(Options.allowed_directories)


func change_directory_visual(dir: String):
	var info: Dictionary = load_pack_info(dir)
	set_info(info)


func change_directory(dir: String):
	change_directory_visual(dir)
	MapSetup.current_directory = dir
	Options.last_pack = dir
	MapSetup.current_pack_name = current_pack_name


func open_directory(dir: String):
	change_directory(dir)
	menu_control.change_tab("maps")


func _on_dir_window_dir_selected(dir):
	add_directory(dir)


func _on_start_pressed():
	var item: SelectionListItem = pack_list.get_selected_item()
	if item:
		open_directory(item.value)


func _on_add_pressed():
	if Options.accepted_directory_danger:
		dir_window.popup_centered(Vector2(480, 480))
	else:
		dir_warning.visible = true


func _on_remove_pressed():
	var item: SelectionListItem = pack_list.get_selected_item()
	if item and item.value != "res://maps":
		remove_popup.visible = true


func _on_dir_warning_yes():
	Options.accepted_directory_danger = true
	Options.save_options()
	dir_window.popup_centered(Vector2(480, 480))
	dir_warning.visible = false


func _on_dir_warning_no():
	dir_warning.visible = false


func _on_remove_popup_yes():
	var item: SelectionListItem = pack_list.get_selected_item()
	if item:
		remove_directory(item.value)
	remove_popup.visible = false


func _on_remove_popup_no():
	remove_popup.visible = false


func _on_packs_item_selected(item: SelectionListItem):
	change_directory_visual(item.value)


func _on_packs_item_activated(item: SelectionListItem):
	open_directory(item.value)
