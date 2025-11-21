extends Node


var current_map : RegionControl

var maps : Array

enum {MENU_LORE, MENU_ALIGNMENTS, MENU_DIFFICULTY}
var current_menu : int = 0


@onready var tintable_ui : Node2D = $tintable_ui

@onready var map_list : ItemList = $tintable_ui/map_list
@onready var map_directory : OptionButton = $tintable_ui/map_directory
@onready var map_options : Control = $tintable_ui/def
@onready var map_dp : Control = $tintable_ui/diff

@onready var map_name : Label = $tintable_ui/map_name
@onready var map_lore : Label = $tintable_ui/lore

@onready var options_label : Label = $tintable_ui/def/map_data
@onready var slider_player : HSlider = $tintable_ui/def/players
@onready var slider_leader : HSlider = $tintable_ui/def/leaders
@onready var slider_aliances : HSlider = $tintable_ui/def/aliances

@onready var dp_preset : Label = $tintable_ui/diff/preset
@onready var dp_cursor : Sprite2D = $tintable_ui/diff/cursor


func _ready():
	GameControl.set_cursor(GameControl.CURSOR.NORMAL)
	
	Options.save_options()
	
	map_directory.add_item("Official Maps")
	for i in range(Options.allowed_directories.size()):
		var dir = Options.allowed_directories[i]
		add_directory(dir)
		if(dir == MapSetup.current_directory):
			map_directory.select(i + 1)
	
	change_directory(MapSetup.current_directory)
	
	MapSetup.preset_alignments.clear()
	
	ReplayControl.clear_replay()


func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("res://title.tscn")


func _on_leaders_value_changed(value):
	if slider_player.value > value:
		slider_player.value = value
	_on_def_slider_value_changed(value)


func _on_players_value_changed(value):
	if slider_leader.value < value:
		slider_leader.value = value
	_on_def_slider_value_changed(value)


func _on_def_slider_value_changed(_value):
	map_data_text()


func _on_map_directory_item_selected(index):
	if index == 0:
		change_directory("res://maps")
	else:
		change_directory(Options.allowed_directories[index - 1])


func _on_dir_window_dir_selected(dir):
	Options.allowed_directories.append(dir)
	add_directory(dir)
	map_directory.select(map_directory.item_count - 1)
	_on_map_directory_item_selected(map_directory.item_count - 1)
	Options.save_options()


func _dir_warning_confirm():
	$dir_window.popup_centered(Vector2(480, 480))
	_dir_warning_close()


func _dir_warning_close():
	$tintable_ui/dir_warning.visible = false


func _on_add_directory_pressed():
	$tintable_ui/dir_warning.visible = true


func add_directory(dir : String):
	map_directory.add_item(dir)


func _on_remove_directory_pressed():
	var i : int = map_directory.selected
	if i > 0:
		Options.allowed_directories.remove_at(i - 1)
		map_directory.remove_item(i)
		map_directory.select(i - 1)
		_on_map_directory_item_selected(i - 1)
		Options.save_options()


func change_directory(dir : String):
	MapSetup.current_directory = dir
	
	map_list.clear()
	
	maps = DirAccess.get_files_at(dir)
	
	maps.sort()
	
	for i in range(maps.size()):
		maps[i] = maps[i].trim_suffix(".remap")
		if maps[i].ends_with(".tscn"):
			var new_name : String = maps[i].trim_suffix(".tscn")
			new_name = new_name.replace("_", " ")
			map_list.add_item(new_name)
			map_list.set_item_tooltip_enabled(i, false)
		else:
			maps[i] = ""
	
	if not maps.is_empty():
		var map = maps.find(MapSetup.current_map_name)
		
		if map < 0 or map >= map_list.item_count:
			map_list.select(0)
			_on_map_list_item_selected(0)
		else:
			map_list.select(map)
			_on_map_list_item_selected(map)
	else:
		_on_map_list_item_selected(-1)


func _on_map_list_item_activated(index):
	start_playing(index)


func _on_map_list_item_selected(index):
	if current_map:
		$map.remove_child(current_map)
		current_map.queue_free()
		current_map = null
	
	if not maps.is_empty() and not maps[index].is_empty():
		var packed_map : PackedScene = load(MapSetup.current_directory + "/" + maps[index])
		current_map = packed_map.instantiate() as RegionControl
	
	if current_map:
		current_map.dummy = true
		
		current_map.position = Vector2(768, 384)
		current_map.scale = Vector2(0.5, 0.5)
		
		tintable_ui.modulate = RegionControl.slight_tint(current_map.color)
		
		$map.add_child(current_map)
		
		map_name.text = map_list.get_item_text(index)
		
		map_data_text()
		
		slider_leader.visible = not current_map.lock_align_amount
		slider_leader.max_value = current_map.align_amount - 1
		slider_leader.tick_count = int(slider_leader.max_value) - 1
		
		slider_player.visible = not current_map.lock_player_amount
		if current_map.max_player_amount >= 0:
			slider_player.max_value = current_map.max_player_amount
		else:
			slider_player.max_value = current_map.align_amount - 1
		slider_player.tick_count = int(slider_player.max_value) + 1
		
		slider_aliances.visible = not current_map.lock_aliances
		slider_aliances.max_value = current_map.align_amount - 1
		slider_aliances.tick_count = int(slider_aliances.max_value)
		
		dp_preset.visible = current_map.lock_dp_setup
		dp_cursor.visible = not current_map.lock_dp_setup
		if current_map.lock_dp_setup:
			$tintable_ui/diff/opponent.text = ""
		else:
			dp_selected_pos()
		
		map_lore.text = RegionControl.setup_tag_name(current_map.tag) + ", " + RegionControl.setup_complexity_name(current_map.complexity) + "\n" + current_map.lore
		
		if MapSetup.current_map_name != maps[index]:
			if current_map.used_alignments >= 2:
				slider_leader.value = current_map.used_alignments
			else:
				slider_leader.value = current_map.align_amount - 1
			slider_player.value = current_map.player_amount
			slider_aliances.value = 1
			MapSetup.current_map_name = maps[index]
		else:
			slider_player.value = MapSetup.player_amount
			slider_aliances.value = MapSetup.aliances_amount
			slider_leader.value = MapSetup.used_alignments
	else:
		tintable_ui.modulate = Color.WHITE
		map_name.text = "No map selected."
		slider_leader.visible = false
		slider_player.visible = false
		slider_aliances.visible = false
		map_lore.text = "This directory of maps is most likely empty."
		dp_preset.visible = true
		dp_cursor.visible = false


func map_data_text():
	if current_map:
		options_label.text = ("PRESET ORDER" if current_map.use_preset_alignments else "RANDOM ORDER")
	options_label.text += "\nLEADERS: " + String.num(slider_leader.value)
	options_label.text += "\nPLAYERS: " + (String.num(slider_player.value) if slider_player.value > 0 else "X")
	options_label.text += "\nALIANCES: " + (String.num(slider_aliances.value) if slider_aliances.value > 1 else "X")


func _on_play_pressed():
	if map_list.is_anything_selected():
		start_playing(map_list.get_selected_items()[0])


func start_playing(index):
	if not maps.is_empty():
		MapSetup.current_map_name = maps[index]
		MapSetup.player_amount = int(slider_player.value)
		MapSetup.aliances_amount = int(slider_aliances.value)
		MapSetup.used_alignments = int(slider_leader.value)
		if current_map.use_alignment_picker and MapSetup.player_amount > 0:
			get_tree().change_scene_to_file("res://alignment_picker.tscn")
		else:
			get_tree().change_scene_to_file("res://main.tscn")


func _on_next_menu_pressed():
	current_menu += 1
	if current_menu > 2:
		current_menu = 0
	
	map_lore.visible = current_menu == MENU_LORE
	map_options.visible = current_menu == MENU_ALIGNMENTS
	map_dp.visible = current_menu == MENU_DIFFICULTY


func dp_selected_pos():
	match(MapSetup.default_digital_player):
		DPControl.CONTROLER.TURTLE:
			dp_cursor.position.x = $tintable_ui/diff/dp_turtle.position.x
			$tintable_ui/diff/opponent.text = "OPPONENT:\nTURTLE"
		DPControl.CONTROLER.DEFAULT:
			dp_cursor.position.x = $tintable_ui/diff/dp_default.position.x
			$tintable_ui/diff/opponent.text = "OPPONENT:\nSIMPLETON"
		DPControl.CONTROLER.NEURAL:
			dp_cursor.position.x = $tintable_ui/diff/dp_neural.position.x
			$tintable_ui/diff/opponent.text = "OPPONENT:\nTHINKER"
		DPControl.CONTROLER.CHEATER:
			dp_cursor.position.x = $tintable_ui/diff/dp_cheater.position.x
			$tintable_ui/diff/opponent.text = "OPPONENT:\nCHEATER"


func _on_dp_turtle_pressed():
	MapSetup.default_digital_player = DPControl.CONTROLER.TURTLE
	dp_selected_pos()


func _on_dp_default_pressed():
	MapSetup.default_digital_player = DPControl.CONTROLER.DEFAULT
	dp_selected_pos()


func _on_dp_neural_pressed():
	MapSetup.default_digital_player = DPControl.CONTROLER.NEURAL
	dp_selected_pos()


func _on_dp_cheater_pressed():
	MapSetup.default_digital_player = DPControl.CONTROLER.CHEATER
	dp_selected_pos()


func _on_replay_pressed():
	$replay_window.popup_centered(Vector2(480, 480))


func _on_replay_window_file_selected(path):
	if ReplayControl.load_replay(path):
		ReplayControl.paused = true
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		_show_replay_fail()
#	print(path)


func _show_replay_fail():
	$tintable_ui/replay_fail.visible = true


func _hide_replay_fail():
	$tintable_ui/replay_fail.visible = false
