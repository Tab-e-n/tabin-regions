extends MenuScene

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

var current_map: RegionControl = null
var map_filenames: PackedStringArray = []

@onready var map_list: SelectionList = $maps as SelectionList
@onready var map_preview: Node2D = $preview

@onready var map_title: Label = $map_title as Label
@onready var map_lore: Label = $map_lore as Label
@onready var map_info: Label = $presets/clip/container/info as Label

@onready var slider_leaders: HSlider = $presets/clip/container/leaders/slider as HSlider
@onready var slider_players: HSlider = $presets/clip/container/players/slider as HSlider
@onready var slider_aliances: HSlider = $presets/clip/container/aliances/slider as HSlider
@onready var slider_key_leaders: Label = $presets/clip/container/leaders/key as Label
@onready var slider_key_players: Label = $presets/clip/container/players/key as Label
@onready var slider_key_aliances: Label = $presets/clip/container/aliances/key as Label

@onready var dp_selector: Sprite2D = $presets/clip/container/dp/selector
@onready var dp_label: Label = $presets/clip/container/dp/name
@onready var dp_buttons: Control = $presets/clip/container/dp/buttons
@onready var dp_button_turtle: BaseButton = $presets/clip/container/dp/buttons/turtle
@onready var dp_button_simpleton: BaseButton = $presets/clip/container/dp/buttons/simpleton
@onready var dp_button_overthinker: BaseButton = $presets/clip/container/dp/buttons/overthinker
@onready var dp_button_bookwyrm: BaseButton = $presets/clip/container/dp/buttons/bookwyrm
@onready var dp_button_cheater: BaseButton = $presets/clip/container/dp/buttons/cheater


func _ready() -> void:
	update_presets.call_deferred()
	
	slider_leaders.min_value = 2
	slider_players.min_value = 0
	slider_aliances.min_value = 1


func _start() -> void:
	map_filenames = load_map_names(MapSetup.current_directory)
	setup_map_list(map_filenames)


func load_map_names(directory_name: String) -> PackedStringArray:
	var directory: PackedStringArray = DirAccess.get_files_at(directory_name)
	var maps: PackedStringArray = []
	
	for filename in directory:
		filename = filename.trim_suffix(".remap")
		if filename.ends_with(".tscn"):
			maps.append(filename)
	
	maps.sort()
	
	return maps


func setup_map_list(map_names: PackedStringArray) -> void:
	map_list.clear()
	
	var selected_item: SelectionListItem = null
	
	for map_name in map_names:
		var item: SelectionListItem = map_list.add_item(map_name, map_name.trim_suffix(".tscn").replace("_", " "))
		if map_name == MapSetup.current_map_name:
			selected_item = item
	
	if selected_item == null:
		map_list.select_index(0)
	else:
		map_list.select_item(selected_item)


func load_map(map_name: String, map_display_name: String, keep_sliders: bool = false) -> void:
	if current_map:
		map_preview.remove_child(current_map)
		current_map.queue_free()
		current_map = null
	
	if not map_name.is_empty():
		var packed_map : PackedScene = load(MapSetup.current_directory + "/" + map_name)
		if packed_map:
			current_map = packed_map.instantiate() as RegionControl
	
	if current_map:
		current_map.dummy = true
		
		var bounds: Vector4 = current_map.map_bounds()
		var map_size: Vector2 = current_map.map_size(bounds)
		current_map.scale = Vector2(0.5, 0.5) * (1 / max(max(map_size.x / 1120, map_size.y / 800), 1))
		current_map.position = -current_map.map_center_offset(bounds) * current_map.scale
		
		map_preview.add_child(current_map)
		
		map_title.text = map_display_name
		map_lore.text = current_map.lore
		
		setup_sliders()
		
		if keep_sliders:
			slider_leaders.value = MapSetup.used_alignments
			slider_players.value = MapSetup.player_amount
			slider_aliances.value = MapSetup.aliances_amount
		else:
			MapSetup.current_map_name = map_name
			if current_map.used_alignments >= 2:
				slider_leaders.value = current_map.used_alignments
			else:
				slider_leaders.value = current_map.align_amount - 1
			slider_players.value = current_map.player_amount
			slider_aliances.value = 1
		
		set_dp_disabled(current_map.lock_dp_setup)
		
		update_presets()
		
		modulate = RegionControl.slight_tint(current_map.color)
	
	else:
		map_title.text = "No map selected."
		map_lore.text = "Select a map from the list on the left.\nIf there are no maps, change the directory."
		slider_leaders.visible = false
		slider_players.visible = false
		slider_aliances.visible = false
		set_dp_disabled(true)
		modulate = Color.WHITE


func start_map(map_name: String) -> void:
	MapSetup.current_map_name = map_name
	MapSetup.player_amount = int(slider_players.value)
	MapSetup.aliances_amount = int(slider_aliances.value)
	MapSetup.used_alignments = int(slider_leaders.value)
	if current_map.use_alignment_picker and MapSetup.player_amount > 0:
		Options.discard_timestamp_sums()
		Options.timestamp("START ALIGN PICKER", "")
		get_tree().change_scene_to_file("res://alignment_picker.tscn")
	else:
		Options.discard_timestamp_sums()
		Options.timestamp("START MAP", "")
		get_tree().change_scene_to_file("res://main.tscn")


func setup_sliders() -> void:
	if not current_map:
		return
	
	slider_leaders.visible = not current_map.lock_align_amount
	slider_leaders.max_value = current_map.align_amount - 1
	slider_leaders.tick_count = int(slider_leaders.max_value) - 1
		
	slider_players.visible = not current_map.lock_player_amount
	if current_map.max_player_amount >= 0:
		slider_players.max_value = current_map.max_player_amount
	else:
		slider_players.max_value = current_map.align_amount - 1
	slider_players.tick_count = int(slider_players.max_value) + 1
	
	slider_aliances.visible = not current_map.lock_aliances
	slider_aliances.max_value = current_map.align_amount - 1
	slider_aliances.tick_count = int(slider_aliances.max_value)


func update_presets() -> void:
	update_map_info()
	
	update_slider_leaders()
	update_slider_players()
	update_slider_aliances()
	
	update_dp_selection()


func update_map_info() -> void:
	if current_map:
		map_info.text = (
			RegionControl.setup_tag_name(current_map.tag) + ", " +
			RegionControl.setup_complexity_name(current_map.complexity) + "\n" +
			("PRESET ORDER" if current_map.use_preset_alignments else "RANDOM ORDER")
		)
	else:
		map_info.text = "\n"


func update_slider_leaders() -> void:
	slider_key_leaders.text = "LEADERS: " + str(slider_leaders.value)


func update_slider_players() -> void:
	slider_key_players.text = "PLAYERS: " + (str(slider_players.value) if slider_players.value > 0 else "X")


func update_slider_aliances() -> void:
	slider_key_aliances.text = "ALIANCES: " + (str(slider_aliances.value) if slider_aliances.value > 1 else "X")


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
	
	dp_selector_position.call_deferred()


func dp_selector_position() -> void:
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
		buttons[dp].visible = not disabled or MapSetup.default_digital_player == dp
	
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


func _on_map_selected(item: SelectionListItem) -> void:
	load_map(item.value, item.text, false)


func _on_map_activated(item: SelectionListItem) -> void:
	start_map(item.value)


func _on_leaders_value_changed(value):
	if slider_players.value > value:
		slider_players.value = value
		update_slider_players()
	update_slider_leaders()


func _on_players_value_changed(value):
	if slider_leaders.value < value:
		slider_leaders.value = value
		update_slider_leaders()
	update_slider_players()


func _on_aliances_value_changed(_value):
	update_slider_aliances()


func _on_button_dp_pressed(dp_name: String) -> void:
	change_dp_by_name(dp_name)


func _on_start_pressed():
	var item: SelectionListItem = map_list.get_selected_item()
	if item:
		start_map(item.value)
