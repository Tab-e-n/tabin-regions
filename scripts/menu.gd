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
	change_tab("maps")


func change_tab(tab: String) -> void:
	for node in tabs.get_children():
		var button: BaseButton = node as BaseButton
		if button:
			button.set_pressed_no_signal(button.name == tab)
	
	for node in menus.get_children():
		var menu: Control = node as Control
		if menu:
			menu.visible = menu.name == tab


func _on_tab_toggled(pressed: bool, tab: String) -> void:
	if pressed:
		change_tab(tab)
	else:
		change_tab("")
