extends Node


var current_map : RegionControl

var maps : Array

enum {MENU_LORE, MENU_ALIGNMENTS, MENU_DIFFICULTY}
var current_menu : int = MENU_LORE


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
	map_directory.add_item("Base Maps")
	for i in range(Options.allowed_directories.size()):
		var dir = Options.allowed_directories[i]
		add_directory(dir)
		if(dir == MapSetup.current_directory):
			map_directory.select(i + 1)
	
	change_directory(MapSetup.current_directory)


func _dir_warning_confirm():
	$dir_window.popup_centered(Vector2(480, 480))
	_dir_warning_close()
func _dir_warning_close():
	$tintable_ui/dir_warning.visible = false
func _on_add_directory_pressed():
	$tintable_ui/dir_warning.visible = true


func _on_dir_window_dir_selected(dir):
	add_directory(dir)


func add_directory(dir : String):
	map_directory.add_item(dir)
	map_directory.select(map_directory.item_count - 1)
	_on_map_directory_item_selected(map_directory.item_count - 1)
	Options.allow_directory(dir)


func _on_remove_directory_pressed():
	var i : int = map_directory.selected
	if i > 0:
		map_directory.remove_item(i)
		map_directory.select(i - 1)
		_on_map_directory_item_selected(i - 1)
		Options.disallow_directory(i - 1)


func _on_map_directory_item_selected(index):
	if index == 0:
		change_directory("res://maps")
	else:
		change_directory(Options.allowed_directories[index - 1])


func change_directory(dir : String):
	MapSetup.current_directory = dir
	
	# Update map list


func _on_map_list_item_selected(index):
	pass


func _on_replay_window_file_selected(path):
	if ReplayControl.load_replay(path):
		ReplayControl.paused = true
		Options.discard_timestamp_sums()
		Options.timestamp("START MAP", "")
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		_show_replay_fail()
#	print(path)


func _on_replay_pressed():
	$replay_window.popup_centered(Vector2(480, 480))
func _show_replay_fail():
	$tintable_ui/replay_fail.visible = true
func _hide_replay_fail():
	$tintable_ui/replay_fail.visible = false
