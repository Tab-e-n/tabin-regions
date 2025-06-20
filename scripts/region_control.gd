extends Polygon2D
## RegionControl is a class that represents a map.
class_name RegionControl


## Emitted once after RegionControl makes all region connections, so the mapmaker can edit them before the capital distance is calculated.
## Intended for maps that want to have different region structure every time players play them.
signal region_connections_ready

signal capital_distance_ready
## Emitted when a players turn ends.
signal turn_ended
## Emitted when a player changes the turns phase. First argument will is the turn phase which just started.
signal turn_phase_changed(phase : int)
## Emitted when all alignments played their turn.
signal round_ended
## Emitted after the an alignment ends their turn and no unfriendly alignments towards them are left.
signal game_ended(winner : int)


## When coloring text on an alignments color, the text will turn black if the brightness of the color is higher than this constant.
const COLOR_TOO_BRIGHT : float = 0.85

enum APPLY_PENALTIES {OFF, CURRENT_CAPITAL, PREVIOUS_CAPITAL}
## Skirmishes are free-for-all maps, this is the default tag.
## Challenges are curated experiences that are meant to challenge the player in some way.
## Bot battles are maps with no human players.
enum SETUP_TAG {SKIRMISH, CHALLENGE, BOT_BATTLE, GUIDE}
## Labels that tell the player how experienced with the game they have to be to play this map.
## There are some guidelines you can follow when choosing a maps complexity.
## BEGINNER maps are intended to be played by players who just started the game and should
## only use normal connections between regions,
## have the turn order hidden by default
## and should not have aliances.
## SIMPLE maps can use all default map features.
## INTERMEDIATE and onwards can use custom gimmicks, only differing in how hard the map is to understand.
enum SETUP_COMPLEXITY {UNSPECIFIED, BEGINNER, SIMPLE, INTERMEDIATE, ADVANCED, DIFFICULT, EXTREME, ROCKET_SCIENCE}


@onready var bg_color : Color = color
@onready var game_control : GameControl
@onready var ai_control : AIControl
@onready var game_camera : GameCamera


@export_subgroup("Setup Scene")
## When set to true, before starting the map players will be able to pick which alignment they want to play as.
@export var use_alignment_picker : bool = true
## Prevents the player from changing the number of alignments on the map.
## Set to true by default, because changing the align amount could break some maps by removing important alignments.
## If you think your map is not be affected by this, set this to false.
@export var lock_align_amount : bool = true
## Prevents users changing the amount of players that can be played on the map.
@export var lock_player_amount : bool = false
## Prevents users from changing the number of aliances.
@export var lock_aliances : bool = false
## Prevents users from changing the computer players. Set this to true if you need a specific AI active.
@export var lock_ai_setup : bool = false


@export_subgroup("Gameplay")

@export_enum ("Off", "Current Capital Amount", "Previous Capital Amount") var apply_penalties : int = APPLY_PENALTIES.OFF
## Sets penalties to slow down players who get ahead, so they don't snowball too hard.
## The keys should be intigers, values should be floats representing percentages.
## After a player reaches a certain capital amount, specified by the dictionary's keys,
## every subsequent capital the player gains will give them less power, specified by the dictionary's value.
@export var power_gain_penalties : Dictionary = {
	3 : .325,
	13 : .25,
	21 : .125,
} 

@export_subgroup("Alignments & Players")
## The number of alignments the map uses. It equals the number of all active alignments + the neutral alignment.
@export var align_amount : int = 3
## Will specify the amount of alignments that are used. When the map has more alignments than the amount specified with this property,
## random alignments not picked by players will have their regions converted to neutral.
@export var used_alignments : int = 0
## Determines if the capitals of alignments that were removed by 'used_alignments' should be removed as well.
## When set to true, all the alignments capitals will be converted to basic cities.
@export var remove_capitals_with_alignments : bool = true
## The intended amount of players the map should have. Can be overwritten in the setup scene unless allow_map_spec_change is set to false.
@export var player_amount : int = 1

@export var random_player_align_range : int = 0
## The maximum amount of players the map allows to be played. There can be more alignments than players.
## When set to -1, the max amount of players is equal to the number of active alignments.
@export var max_player_amount : int = -1
## Toggles the use of preset_alignments.
@export var use_preset_alignments : bool = false
## Specifies an unchanging turn order.
@export var preset_alignments : Array[int] = []

@export_subgroup("AI")
## The default AI that computer players will use. Uses the 'CONTROLER_' enums from 'AIControl'.
## Default, Turtle, Neural and Cheater are all accessible in the setup scene.
## The Dummy AI does nothing, expecting to be controled by the map.
@export_enum("None", "Default", "Turtle", "Neural", "Cheater", "Dummy") var default_ai_controler : int = AIControl.CONTROLER_DEFAULT

@export var custom_ai_setup : Array[int] = []
## If set to true, when starting the map custom_ai_setup will be shuffled so it is not the same every time.
@export var shuffle_ai : bool = false

@export_subgroup("Aliances")

@export var use_aliances : bool = false

@export var alignment_aliances : Array[int] = []

@export var use_autoaliances : bool = false

@export var autoaliances_divisions_amount : int = 2

@export_subgroup("Cosmetics")
## Tells the player the type of the map.
@export var tag : SETUP_TAG = SETUP_TAG.SKIRMISH
## Tells the player how experienced with the game they should be before playing this map.
@export var complexity : SETUP_COMPLEXITY = SETUP_COMPLEXITY.UNSPECIFIED
## Text explaing the context of the map.
@export_multiline var lore : String = """Insert lore here"""
## Colors used by the map's alignments. The first color is used for neutral regions.
@export var align_color : Array[Color] = [
		Color("625775"), # purplish gray
		
		Color("a72b37"), # red
		Color("368d61"), # green
		Color("2b7dba"), # blue
		Color("ae5b15"), # orange
		Color("8927a8"), # purple
		
		Color("ed858d"), # salmon
		Color("c5ebbf"), # pistachio
		Color("213775"), # navy
		Color("a58260"), # dirt
		Color("dd4f96"), # magenta
		
		Color("deaac7"), # pink
		Color("6da63d"), # vibrant green
		Color("7795ed"), # teal
		Color("d09f15"), # gold
		Color("b177c9"), # lavender
		
		Color("7a0e43"), # violet
		Color("395621"), # grass
		Color("556aa2"), # denim
		Color("d7e06b"), # yellow
		Color("895870"), # dim lavender
		
		Color("3f0628"), # dark red
		Color("7ded92"), # lime
		Color("2b4456"), # swamp
		Color("d7cac0"), # tan
		Color("828387"), # gray
		
		Color("673a2b"), # brown
		Color("4f4b3b"), # tank
		Color("b6b7eb"), # silver
		Color("eda75b"), # sandstorm
		Color("2e5949"), # dark green
]
## Names of alignments. Includes the name of the neutral alignment, at index 0.
@export var align_names : Array[String] = []
## Determines what message gets show at the end of the game.
## When set to 0 or lower, map will always show a victory message.
## When set to a positive integer, map will show a victory message only if an alignment of the same number wins, else it will show defeat.
## If aliances are turned on, this check applies to aliances and not to individual alignments.
@export var main_character : int = 0
## When set to true, the RegionControl will color itself based on which alignment is currently playing.
@export var color_bg_according_to_alignment : bool = true
## Controls the scale of cities. Smaller cities will make the map feel larger, without it taking up more space.
@export var city_size : float = 1
## When starting the map, the camera will snap to a capital of the starting alignment.
@export var snap_camera_to_first_align_capital : bool = true
## When set to true, the turn order will start invisible.
@export var hide_turn_order : bool = false
## When false, regions will not spawn particles.
@export var spawn_particles : bool = true
## What color does the text in the command callout have.
@export var command_callout_color : Color = Color(1, 1, 1, 1)

@export_subgroup("Editor")
## Only has an effect in the editor. When not set to Disabled, will color the regions depending on certain criteria.
## Alignment will color regions based on their alignment.
## Power and Max Power will color regions based on the regions current power and max possible power respectively. Darker regions have more power.
## Capital will color regions based on if they are a capital or not. Green means it is a capital, red means it is not.
## Position colors the regions based on their position.
@export_enum("Disabled", "Alignment", "Power", "Max Power", "Capital", "Position") var render_mode : int = 0
@export var render_range : float = 20
## When set to true, RegionControl wil not do anything on its own. This is intended to be used by other scenes, not RegionControl itself.
@export var dummy : bool = false
## When false, cities won't be rendered. Can be toggled in-game.
@export var cities_visible : bool = true
@export var print_more_info : bool = false
## Holds the connections of all regions. When the map is readying, RegionControl will attempt to make every connection in this array.
## Not recommended to use the inspector to edit this property, use a built-in script like in the template map instead, because it is easier to edit.
@export var connections : Array = []

var current_playing_align : int = 1
var align_play_order : Array = []
var play_order_i : int = 0


var align_controlers : Array = []
var is_player_controled : bool

var region_amount : Array = []
var last_turn_region_amount : Array = []
var capital_amount : Array = []

var removed_alignments : Array = []

enum {PHASE_NORMAL, PHASE_MOBILIZE, PHASE_BONUS}
const AMOUNT_OF_PHASES : int = 3
var current_phase : int = PHASE_NORMAL

var action_amount : int = 1
var bonus_action_amount : int = 0

var current_turn : int = 1
var current_placement : int = 0

var penalty_amount : Array = []


func _ready():
	if OS.has_feature("editor"):
		check_duplicate_connetions()
	if print_more_info:
		MapSetup.print_map_data()
	
	if dummy:
		return
	
	game_control = get_parent()
	game_control.region_control = self
	game_camera = game_control.game_camera
	ai_control = game_control.ai_control
	
	if ReplayControl.replay_active:
		align_play_order = ReplayControl.replay_play_order
		alignment_aliances = ReplayControl.replay_aliances
		align_controlers = ReplayControl.replay_controlers
		use_aliances = ReplayControl.replay_uses_aliances
	else:
		player_amount = MapSetup.player_amount
		if not lock_ai_setup:
			default_ai_controler = MapSetup.default_ai_controler
		if not use_aliances and MapSetup.aliances_amount > 1:
			use_aliances = true
			use_autoaliances = true
			autoaliances_divisions_amount = MapSetup.aliances_amount
#		if not use_preset_alignments and use_alignment_picker:
#			preset_alignments = MapSetup.preset_alignments.duplicate()
#			use_preset_alignments = true
		used_alignments = MapSetup.used_aligments
	
	for link in connections:
		var link_power_reduction = 0
		if link.size() >= 3:
			link_power_reduction = link[2]
		var region_from : Region = get_node(link[0]) as Region
		var region_to : Region = get_node(link[1]) as Region
		if region_from == null:
			push_warning(link[0], " does not exist.")
			continue
		if region_to == null:
			push_warning(link[1], " does not exist.")
			continue
		var connection : RegionConnection = RegionConnection.new()
		connection.region_from = region_from
		connection.region_to = region_to
		connection.power_reduction = link_power_reduction
		connection.kinetic = region_from.kinetic or region_to.kinetic
		add_child(connection)
		region_from.connections.append(connection)
		region_to.connections.append(connection)
	
	region_connections_ready.emit()
	
	region_amount.resize(align_amount - 1)
	capital_amount.resize(align_amount - 1)
	penalty_amount.resize(align_amount - 1)
	for i in range(align_amount - 1):
		region_amount[i] = 0
		capital_amount[i] = 0
		penalty_amount[i] = 0
	
	count_up_regions()
	
	bake_capital_distance()
	
	capital_distance_ready.emit()
	
	if not ReplayControl.replay_active:
		var rng : RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		var players : Array = range(align_amount)
		players.pop_front()
		
		if used_alignments < 2 or used_alignments >= align_amount:
			used_alignments = align_amount - 1
		
		var preset_alignments_amount : int = 0
		for i in preset_alignments:
			if i != 0:
				preset_alignments_amount += 1
		if preset_alignments_amount > 0 and used_alignments < preset_alignments_amount:
			used_alignments = preset_alignments_amount
		for i in preset_alignments:
			players.erase(i)
		
		if use_alignment_picker:
			for i in MapSetup.preset_alignments:
				players.erase(i)
		
		if used_alignments >= 2 and used_alignments < align_amount - 1:
			var removed_align_count : int = align_amount - used_alignments - 1
			if removed_align_count > players.size():
				removed_align_count = players.size()
			for i in range(removed_align_count):
				var pos : int = rng.randi_range(0, players.size() - 1)
				var alignment : int = players.pop_at(pos)
				remove_alignment(alignment, remove_capitals_with_alignments)
				removed_alignments.append(alignment)
		
		if random_player_align_range < max_player_amount:
			random_player_align_range = max_player_amount
		if random_player_align_range > players.size():
			random_player_align_range = players.size()
		
		align_play_order.resize(used_alignments)
		
		if use_preset_alignments and preset_alignments_amount > 0:
			for i in range(preset_alignments.size()):
				if align_play_order.size() <= i:
					break
				if preset_alignments[i] != 0:
					align_play_order[i] = preset_alignments[i]
		
		if use_alignment_picker:
			for i in range(MapSetup.preset_alignments.size()):
				if align_play_order.size() <= i:
					break
#				if align_play_order[i] == 0:
				align_play_order[i] = MapSetup.preset_alignments[i]
		
		for i in range(align_play_order.size()):
			if align_play_order[i]:
				continue
			var pos : int = 0
			if random_player_align_range > 0 and i < random_player_align_range and not use_preset_alignments:
				pos = rng.randi_range(0, random_player_align_range - i - 1)
			else:
				pos = rng.randi_range(0, players.size() - 1)
			align_play_order[i] = players.pop_at(pos)
	else:
		removed_alignments = ReplayControl.replay_removed_alignments.duplicate()
		for alignment in removed_alignments:
			remove_alignment(alignment, remove_capitals_with_alignments)
	
	if print_more_info:
		print(align_play_order)
	
	current_playing_align = align_play_order[0]
	
	if not ReplayControl.replay_active:
		if shuffle_ai:
			randomize()
			custom_ai_setup.shuffle()
		align_controlers.resize(align_amount - 1)
		for i in range(align_amount - 1):
			align_controlers[i] = default_ai_controler
			if i < custom_ai_setup.size():
				if custom_ai_setup[i] != 0:
					align_controlers[i] = custom_ai_setup[i]
		for i in range(player_amount):
			align_controlers[align_play_order[i] - 1] = AIControl.CONTROLER_USER
	
	last_turn_region_amount = region_amount.duplicate()
	
	GameStats.reset_statistics(align_amount)
	
	for align in range(align_amount):
		GameStats.set_stat(align, "align color", align_color[align])
#		GameStats.stats[align]["align color"] = align_color[align]
		if align != 0:
			GameStats.set_stat(align, "controler", align_controlers[align - 1])
#			GameStats.stats[align]["controler"] = align_controlers[align - 1]
		else:
			GameStats.set_stat(align, "controler", AIControl.CONTROLER_DUMMY)
#			GameStats.stats[align]["controler"] = AIControl.CONTROLER_DUMMY
	
	current_placement = align_play_order.size()
	
	if not ReplayControl.replay_active:
		if alignment_aliances.size() < align_amount:
			alignment_aliances.resize(align_amount)
		
		if not use_aliances:
			for i in range(align_amount):
				alignment_aliances[i] = i
		else:
			if use_autoaliances:
				alignment_aliances[0] = 0
				var current_aliance : int = 1
				for i in range(align_play_order.size()):
					alignment_aliances[align_play_order[i]] = current_aliance
					current_aliance += 1
					if current_aliance > autoaliances_divisions_amount:
						current_aliance = 1
	
	align_names.resize(align_amount)
	for align in range(align_amount):
		GameStats.set_stat(align, "alignment name", align_names[align])
	for align in removed_alignments:
		GameStats.set_stat(align, "placement", "X")
	
	reset()
	
	if hide_turn_order:
		game_camera.toggle_turn_order_visibility()
	
	if snap_camera_to_first_align_capital:
		var center_camera : Vector2 = Vector2(0, 0)
		for region in get_children():
			if region is Region:
				if region.alignment == current_playing_align:
					center_camera = region.position
					if region.is_capital:
						break
		game_camera.call_deferred("center_camera", center_camera)
		
	call_deferred("save_replay_data")


func check_duplicate_connetions():
	var regions : Dictionary = {}
	
	for link in connections:
		if link[0] == link[1]:
			push_warning("Connections cannot be connect to themselfs. [", link[0], "]")
			continue
		if regions.has(link[0]):
			if regions[link[0]].has(link[1]):
				push_warning("Connection ", link[0], " - ", link[1], " already exists.")
			else:
				regions[link[0]].append(link[1])
		else:
			regions[link[0]] = [link[1]]
		if regions.has(link[1]):
			if regions[link[1]].has(link[0]):
				push_warning("Connection ", link[1], " - ", link[0], " already exists.")
			else:
				regions[link[1]].append(link[0])
		else:
			regions[link[1]] = [link[0]]
	
	if print_more_info:
		print(regions)


func save_replay_data():
	if not ReplayControl.replay_active:
		ReplayControl.clear_replay()
		
		ReplayControl.replay_play_order = align_play_order.duplicate()
		ReplayControl.replay_aliances = alignment_aliances.duplicate()
		ReplayControl.replay_controlers = align_controlers.duplicate()
		
		ReplayControl.replay_uses_aliances = use_aliances
		
		ReplayControl.replay_removed_alignments = removed_alignments


func _process(_delta):
	if Engine.is_editor_hint():
		return
	
	if dummy:
		return
	
	if is_player_controled:
		if Input.is_action_just_pressed("forfeit"):
			forfeit()
			game_camera.CommandCallout.new_callout("Forfeit")
		elif Input.is_action_just_pressed("plus_foward"):
			turn_end(true)
			game_camera.CommandCallout.new_callout("End turn")
		elif Input.is_action_just_pressed("plus_turn"):
			change_current_action()
			game_camera.CommandCallout.new_callout("Advance turn")


func count_up_regions():
	for i in range(region_amount.size()):
		region_amount[i] = 0
	for region in get_children():
		if not region is Region:
			continue
		if region.alignment == 0 or region.alignment >= align_amount:
			continue
		region_amount[region.alignment - 1] += 1
		if region.is_capital:
			capital_amount[region.alignment - 1] += 1


func get_region(reg_name : String) -> Region:
	var node : Node = get_node(reg_name)
	if node is Region:
		return node
	else:
		return null


func bake_capital_distance():
	for node in get_children():
		var capital : Region = node as Region
		if not capital:
			continue
		if not capital.is_capital:
			continue
		capital.distance_from_capital = 0
		var current_distance : int = 2
		var links : Array[RegionConnection] = []
		var regions : Array[Region] = [capital]
		var i : int = 0
		while i != regions.size():
			if not regions[i]:
				i += 1
				continue
			
			links = regions[i].connections.duplicate()
			
			current_distance = snapped(regions[i].distance_from_capital + 0.1, 2) + 2
			
			for connection in links:
				var region : Region = connection.get_other_region(regions[i]) as Region
				if not region:
					continue
				if region.distance_from_capital < current_distance:
					continue
				var has_visited : bool = regions.has(region)
				if region.is_capital:
					region.distance_from_capital = 0
				elif region.distance_from_capital > current_distance:
					region.distance_from_capital = current_distance
					if not has_visited:
						regions.append(region)
				elif not has_visited and region.distance_from_capital == current_distance:
					region.distance_from_capital -= 1
			
			links.clear()
			
			i += 1


func remove_alignment(align : int, remove_capitals : bool):
	for region in get_children():
		if not region is Region:
			continue
		if region.alignment == align:
			region.change_alignment(0, false)
			if remove_capitals and region.is_capital:
				region.is_capital = false


func cross(capital_position : Vector2):
	var part : Sprite2D = Sprite2D.new()
	part.set_script(preload("res://scripts/particle_cross.gd"))
	part.texture = preload("res://sprites/cross.png")
	part.position = capital_position
	part.set_color(color)
	part.z_index = 25
	add_child(part)


func hide_capitals():
	cities_visible = not cities_visible


func set_capital_visibility(visibility : bool):
	cities_visible = visibility


func change_region_amount(amount : int, alignment : int, is_capital : bool):
	if alignment > 0 and alignment < align_amount and region_amount.size() > 0:
		region_amount[alignment - 1] += amount
		if is_capital:
			capital_amount[alignment - 1] += amount
			calculate_penalty(alignment)


func add_action():
	match(current_phase):
		PHASE_NORMAL:
			action_amount += 1
			game_camera.changed_action_amount(1, align_color[current_playing_align])
		PHASE_MOBILIZE, PHASE_BONUS:
			bonus_action_amount += 1
			game_camera.changed_action_amount(1, align_color[current_playing_align])
	ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "add_action")


func action_done(region_name : String, amount : int = 1):
	var auto_end_phase : bool = Options.auto_end_turn_phases and is_player_controled and not ReplayControl.replay_active
	if current_phase == PHASE_NORMAL:
		if action_amount > 0:
			GameStats.add_to_stat(current_playing_align, "first actions done", 1)
			action_amount -= 1
			game_camera.changed_action_amount(-1, align_color[current_playing_align])
			ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
		if action_amount <= 0 and auto_end_phase:
			change_current_action()
	elif current_phase == PHASE_MOBILIZE:
		bonus_action_amount += amount
		game_camera.changed_action_amount(amount, align_color[current_playing_align])
		for i in range(amount):
			ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
	elif current_phase == PHASE_BONUS:
		if bonus_action_amount > 0:
			GameStats.add_to_stat(current_playing_align, "bonus actions done", 1)
			bonus_action_amount -= 1
			game_camera.changed_action_amount(-1, align_color[current_playing_align])
			ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
		if bonus_action_amount <= 0 and auto_end_phase:
			change_current_action()


func overtake_region(region_name : String):
	var region : Region = get_node(region_name) as Region
	if region:
		region.overtake()
		ReplayControl.record_move(ReplayControl.RECORD_TYPE_OVERTAKE, region_name)


func has_enough_actions() -> bool:
	if current_phase == PHASE_NORMAL:
		return action_amount > 0
	elif current_phase == PHASE_BONUS:
		return bonus_action_amount > 0
	else:
		return true


func change_current_action():
	if current_phase == PHASE_NORMAL and action_amount > 0:
		bonus_action_amount = action_amount
	current_phase += 1
	
	var call_end_turn : bool = false
	
	if current_phase == AMOUNT_OF_PHASES:
		current_phase = PHASE_NORMAL
		call_end_turn = true
	
	turn_phase_changed.emit(current_phase)
	
	if call_end_turn:
		turn_end(false)
	
	ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "change_current_action")


func turn_end(record : bool):
	calculate_penalty(current_playing_align, true)
	
	if region_amount[current_playing_align - 1] > 0:
		GameStats.set_stat(current_playing_align, "turns lasted", current_turn)
#		GameStats.stats[current_playing_align]["turns lasted"] = current_turn
	var first_loop = true
	var starting_player = play_order_i
	var round_end : bool = false
	while region_amount[current_playing_align - 1] == 0 or first_loop:
		play_order_i += 1
		if play_order_i == align_play_order.size():
			play_order_i = 0
			current_turn += 1
			round_end = true
		current_playing_align = align_play_order[play_order_i]
		first_loop = false
		if play_order_i == starting_player:
#			victory(current_playing_align)
			break
	check_victory()
	
	var placement = String.num(current_placement)
	
	for i in range(region_amount.size()):
		if region_amount[i] != last_turn_region_amount[i] and region_amount[i] == 0: 
			GameStats.set_stat(i + 1, "placement", placement)
			if game_control and not align_names[i + 1].is_empty():
				game_control.new_callout(align_names[i + 1] + " got eliminated!")
#			GameStats.stats[i + 1]["placement"] = placement
			current_placement -= 1
	
	last_turn_region_amount = region_amount.duplicate()
	
	reset()
	
	turn_ended.emit()
	if round_end:
		round_ended.emit()
	
	if record:
		ReplayControl.call_deferred("record_move", ReplayControl.RECORD_TYPE_FUNCTION, "turn_end")
#		ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "turn_end")


func check_victory():
	var aliance : int = 0
	var victory_align : int = 0
	for i in range(region_amount.size()):
		if region_amount[i] > 0:
			if alignment_aliances[i + 1] <= 0:
				continue
			elif aliance == 0:
				victory_align = i + 1
				aliance = alignment_aliances[i + 1]
			elif aliance != alignment_aliances[i + 1]:
				return
	victory(victory_align)


func victory(align_victory : int):
	dummy = true
	
	GameStats.set_stat(align_victory, "placement", "1")
	
	var placement = String.num(current_placement)
	
	for i in range(align_amount - 1):
		var align : int = i + 1
		if alignment_aliances[align] <= 0:
			continue
		if use_aliances:
			if alignment_aliances[align] == alignment_aliances[align_victory]:
				GameStats.set_stat(align, "placement", "1")
				continue
		if GameStats.get_stat(align, "placement") == "N/A":
			GameStats.set_stat(align, "placement", placement)
	
	if main_character <= 0:
		game_control.win(align_victory)
	elif alignment_aliances[align_victory] == main_character:
		game_control.win(align_victory)
	else:
		game_control.lose(align_victory)
	
	game_ended.emit(align_victory)


func reset():
	var reg_amount = GameStats.get_stat(current_playing_align, "most regions owned")
	if reg_amount == null:
		reg_amount = 0
	var cap_amount = GameStats.get_stat(current_playing_align, "most capitals owned")
	if cap_amount == null:
		cap_amount = 0
	if region_amount[current_playing_align - 1] > int(reg_amount): #GameStats.stats[current_playing_align]["most regions owned"]
		GameStats.set_stat(current_playing_align, "most regions owned", region_amount[current_playing_align - 1])
#		GameStats.stats[current_playing_align]["most regions owned"] = region_amount[current_playing_align - 1]
	if capital_amount[current_playing_align - 1] > int(cap_amount): #GameStats.stats[current_playing_align]["most capitals owned"]
		GameStats.set_stat(current_playing_align, "most capitals owned", capital_amount[current_playing_align - 1])
#		GameStats.stats[current_playing_align]["most capitals owned"] = capital_amount[current_playing_align - 1]
	calculate_penalty(current_playing_align)
	action_amount = capital_amount[current_playing_align - 1] - penalty_amount[current_playing_align - 1]
	bonus_action_amount = 1 if action_amount == 0 and not use_aliances else 0
	current_phase = PHASE_MOBILIZE if action_amount == 0 else PHASE_NORMAL
	
	if color_bg_according_to_alignment:
		var bg_color_tinted : Color = bg_color + align_color[current_playing_align] * Color(0.25, 0.25, 0.25)
		if Options.speedrun_ai:
			if align_controlers[current_playing_align - 1] == AIControl.CONTROLER_USER:
				color = bg_color_tinted
			else:
				color = bg_color
		else:
			color = bg_color_tinted
	
	if ReplayControl.replay_active:
		is_player_controled = false
	else:
		is_player_controled = align_controlers[current_playing_align - 1] == AIControl.CONTROLER_USER
	
	if !is_player_controled:
		ai_control.start_turn(current_playing_align, align_controlers[current_playing_align - 1])


func calculate_penalty(alignment : int, end_of_turn : bool = false):
	if apply_penalties == APPLY_PENALTIES.OFF:
		return
	if apply_penalties == APPLY_PENALTIES.PREVIOUS_CAPITAL and not end_of_turn:
		return
	if power_gain_penalties.size() == 0:
		return
	
	var capitals : int = capital_amount[alignment - 1]
	
	var penalty : float = 0.0
	for i in power_gain_penalties.keys():
		if capitals <= i:
			break
		penalty += float(capitals - i) * power_gain_penalties[i]
	var penalty_total = int(penalty)
	
#	print(penalty_total)
	
	penalty_amount[alignment - 1] = penalty_total


func forfeit():
	convert_alignment(current_playing_align, 0)
	
	turn_end(false)
	
	ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "forfeit")


func convert_alignment(align_old : int, align_new : int):
	if align_old < 0:
		push_warning("Alignment ", align_old, " cannot be converted.")
		return
	if align_new < 0:
		push_warning("Alignment ", align_new, " cannot be converted to.")
		return
	
	for region in get_children():
		if region is Region:
			if region.alignment == align_old:
				region.change_alignment(align_new)


func alignment_friendly(your_align : int, opposing_align : int) -> bool:
	if your_align < 0 or your_align >= align_amount:
		return false
	if opposing_align < 0 or opposing_align >= align_amount:
		return false
	return alignment_aliances[your_align] == alignment_aliances[opposing_align]


func alignment_neutral(align : int) -> bool:
	return align == 0 or align >= align_amount


func alignment_active(align : int) -> bool:
	return align > 0 and align < align_amount


static func flip_color(c : Color) -> Color:
	c.r = 1 - c.r
	c.g = 1 - c.g
	c.b = 1 - c.b
	return c


static func slight_tint(tint_color : Color) -> Color:
	var temp_color : Color
	
	temp_color = flip_color(tint_color)
	temp_color *= 0.333
	temp_color = flip_color(temp_color)
	temp_color.a = 1.0
	
	return temp_color


static func setup_tag_name(stag : SETUP_TAG) -> String:
	match(stag):
		SETUP_TAG.SKIRMISH:
			return "Skirmish"
		SETUP_TAG.CHALLENGE:
			return "Challenge"
		SETUP_TAG.BOT_BATTLE:
			return "Bot Battle"
		SETUP_TAG.GUIDE:
			return "Guide"
		_:
			return "No Tag"


static func text_color(value : float) -> Color:
	if value > COLOR_TOO_BRIGHT:
		return Color(0, 0, 0, 1)
	else:
		return Color(1, 1, 1, 1)


static func setup_complexity_name(compx : SETUP_COMPLEXITY) -> String:
	match(compx):
		SETUP_COMPLEXITY.UNSPECIFIED:
			return "Unspecified"
		SETUP_COMPLEXITY.BEGINNER:
			return "Beginner"
		SETUP_COMPLEXITY.SIMPLE:
			return "Simple"
		SETUP_COMPLEXITY.INTERMEDIATE:
			return "Intermediate"
		SETUP_COMPLEXITY.ADVANCED:
			return "Advanced"
		SETUP_COMPLEXITY.DIFFICULT:
			return "Difficult"
		SETUP_COMPLEXITY.EXTREME:
			return "Extreme"
		SETUP_COMPLEXITY.ROCKET_SCIENCE:
			return "Rocket Science"
		_:
			return "Unknown"
