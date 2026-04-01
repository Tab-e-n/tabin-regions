extends Control

"""

# Maps Tab

 - Selection list for map
 - Start map button
 - Map preview

 - Map title
 - Map description
 - Map option selection
   * Leaders
   * Players
   * Aliances
 - DP selection

 - Changing map directory
 - Adding directory + warning about unsafety
 - Removing directory

"""

@onready var dp_selector: Sprite2D = $presets/clip/container/dp/selector
@onready var dp_label: Label = $presets/clip/container/dp/name
@onready var dp_buttons: Control = $presets/clip/container/dp/buttons
@onready var dp_button_turtle: BaseButton = $presets/clip/container/dp/buttons/turtle
@onready var dp_button_simpleton: BaseButton = $presets/clip/container/dp/buttons/simpleton
@onready var dp_button_overthinker: BaseButton = $presets/clip/container/dp/buttons/overthinker
@onready var dp_button_bookwyrm: BaseButton = $presets/clip/container/dp/buttons/bookwyrm
@onready var dp_button_cheater: BaseButton = $presets/clip/container/dp/buttons/cheater


func _ready():
	update_dp_selection.call_deferred()


func update_dp_selection() -> void:
	match(MapSetup.default_digital_player):
		DPControl.CONTROLER.TURTLE:
			dp_selector.position = dp_button_turtle.position
			dp_label.text = "Turtle"
		DPControl.CONTROLER.DEFAULT:
			dp_selector.position = dp_button_simpleton.position
			dp_label.text = "Simpleton"
		DPControl.CONTROLER.NEURAL:
			dp_selector.position = dp_button_overthinker.position
			dp_label.text = "Overthinker"
		DPControl.CONTROLER.SMARTIE:
			dp_selector.position = dp_button_bookwyrm.position
			dp_label.text = "Bookwyrm"
		DPControl.CONTROLER.CHEATER:
			dp_selector.position = dp_button_cheater.position
			dp_label.text = "Cheater"
	
	dp_selector.position += dp_buttons.position


func set_dp_disabled(disabled: bool) -> void:
	var buttons: Dictionary = {
		DPControl.CONTROLER.TURTLE : dp_button_turtle,
		DPControl.CONTROLER.DEFAULT : dp_button_simpleton, 
		DPControl.CONTROLER.NEURAL : dp_button_overthinker,
		DPControl.CONTROLER.SMARTIE : dp_button_bookwyrm,
		DPControl.CONTROLER.CHEATER : dp_button_cheater,
	}
	for dp in buttons:
		buttons[dp].disabled = disabled
		buttons[dp].visible = MapSetup.default_digital_player == dp
	
	dp_selector.visible = not disabled


func change_dp_by_name(dp_name: String) -> void:
	match(dp_name):
		"Turtle":
			MapSetup.default_digital_player = DPControl.CONTROLER.TURTLE
		"Simpleton":
			MapSetup.default_digital_player = DPControl.CONTROLER.DEFAULT
		"Overthinker":
			MapSetup.default_digital_player = DPControl.CONTROLER.NEURAL
		"Bookwyrm":
			MapSetup.default_digital_player = DPControl.CONTROLER.SMARTIE
		"Cheater":
			MapSetup.default_digital_player = DPControl.CONTROLER.CHEATER
	update_dp_selection()


func _on_button_dp_pressed(dp_name: String) -> void:
	change_dp_by_name(dp_name)
