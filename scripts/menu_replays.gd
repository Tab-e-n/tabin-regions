extends MenuScene


var replay_filenames: PackedStringArray = []

@onready var replay_list: SelectionList = $replays as SelectionList
@onready var fail_popup: Control = $fail_popup as Control


func _start() -> void:
	replay_filenames = load_replay_names("user://")
	setup_replay_list(replay_filenames)


func load_replay_names(directory_name: String) -> PackedStringArray:
	var directory: PackedStringArray = DirAccess.get_files_at(directory_name)
	var replays: PackedStringArray = []
	
	for filename in directory:
		if filename.ends_with(".replay"):
			replays.append(filename)
	
	replays.sort()
	
	return replays


func setup_replay_list(replay_names: PackedStringArray) -> void:
	replay_list.clear()
	
	for replay_name in replay_names:
		var _item: SelectionListItem = replay_list.add_item(replay_name, replay_name)
	
	replay_list.select_index(0)


func start_replay(filename: String):
	if ReplayControl.load_replay("user://" + filename):
		Options.discard_timestamp_sums()
		Options.timestamp("START MAP", "")
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		show_fail_popup()


func show_fail_popup():
	fail_popup.visible = true


func hide_fail_popup():
	fail_popup.visible = false


func _on_start_pressed():
	var item: SelectionListItem = replay_list.get_selected_item()
	if item:
		start_replay(item.value)


func _on_replays_item_activated(item: SelectionListItem):
	start_replay(item.value)


func _on_replays_item_selected(_item: SelectionListItem):
	pass # Replace with function body.
