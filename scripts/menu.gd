extends Control


"""

TODO

 - Tabs

# Replays Tab

 - Selection list for replays
 - Start replay

# Options Tab

 - Access to things in pause menu

"""

@export var tabs: Control = null
@export var menus: Control = null


func _ready():
	GameControl.set_cursor(GameControl.CURSOR.NORMAL)
	
	Options.save_options()
	
	MapSetup.preset_alignments.clear()
	
	ReplayControl.clear_replay()
	
	change_tab("maps")


func _process(_delta):
	# TODO: Should title be part of the menu aswell? or remain a seperate scene?
	if Input.is_action_just_pressed("escape"):
		Options.discard_timestamp_sums()
		Options.timestamp("START TITLE", "")
		get_tree().change_scene_to_file("res://title.tscn")


func change_tab(tab: String) -> void:
	for node in tabs.get_children():
		var button: BaseButton = node as BaseButton
		if button:
			button.set_pressed_no_signal(button.name == tab)
	
	for node in menus.get_children():
		var menu: MenuScene = node as MenuScene
		if menu:
			menu.visible = menu.name == tab
			menu._start()


func _on_tab_toggled(pressed: bool, tab: String) -> void:
	if pressed:
		change_tab(tab)
	else:
		change_tab("")
