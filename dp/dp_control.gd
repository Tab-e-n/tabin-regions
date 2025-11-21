extends Node
class_name DPControl


signal timer_has_ended


@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl

const THINKING_TIMER_DEFAULT : float = 0.5
const THINKING_TIMER_SPEEDRUN : float = 0.05
const THINKING_TIMER_NETWORK : float = 0.001

var thinking_timer : float = THINKING_TIMER_DEFAULT

enum CONTROLER {USER, DEFAULT, TURTLE, NEURAL, CHEATER, DUMMY}
const CONTROLER_NAMES : Array = ["User Controled", "Simple", "Turtle", "Neural", "Cheater", "Environment"]
const PACKED_CONTROLERS : Array = [
	null, # CONTROLER.USER (can be just null)
	preload("res://dp/dp_normal.gd"), # CONTROLER.DEFAULT
	preload("res://dp/dp_turtle.gd"), # CONTROLER.TURTLE
	preload("res://dp/dp_neural.gd"), # CONTROLER.NEURAL
	preload("res://dp/dp_normal.gd"), # CONTROLER.CHEATER
	preload("res://dp/dp_dummy.gd") # CONTROLER.DUMMY
]


var current_controler : int

var timer : float = 0

var owned_regions : Dictionary = {}
var current_moves : Dictionary = {}
var previous_moves : Array = []

var selected_capital : String = ""

var CALL_change_current_phase : bool = false
var CALL_end_turn : bool = false
var CALL_forfeit : bool = false
var CALL_nothing : bool = false
var CALL_cheat : bool = false
var CALL_overtake : bool = false

var controlers : Array[DigitalPlayer] = []

var replay_done_action : bool = true


func _ready():
	dp_speedrun_update()
	
	game_control.dp_control = self
	
	controlers.resize(PACKED_CONTROLERS.size())
	
	for i in range(PACKED_CONTROLERS.size()):
		if PACKED_CONTROLERS[i]:
			controlers[i] = DigitalPlayer.new()
			controlers[i].set_script(PACKED_CONTROLERS[i])
			controlers[i].controler = self
			add_child(controlers[i])
	controlers[CONTROLER.CHEATER].cheater = true
	
	
	timer_has_ended.connect(timer_ended)
	
	call_deferred("_ready_deferred")


func _ready_deferred():
	region_control = game_control.region_control


func _process(delta):
	if not RegionControl.active(region_control):
		return
	
#	print(timer)
	if region_control.is_player_controled:
		timer = 0
	if timer > 0:
		timer -= delta
		if timer == 0:
			timer = -1
	if timer < 0:
		timer = 0
		timer_has_ended.emit()


func reset():
	owned_regions = {}
	current_moves = {}
	previous_moves = []
	selected_capital = ""
	reset_CALL()
	timer = 0


func dp_speedrun_update():
	if game_control is NetworkTrainer:
		thinking_timer = THINKING_TIMER_NETWORK
	elif Options.dp_speedrun:
		thinking_timer = THINKING_TIMER_SPEEDRUN
	else:
		thinking_timer = THINKING_TIMER_DEFAULT


func start_turn(alignment : int, control : int):
#	print("start turn")
	
	current_controler = control
	
	if not ReplayControl.replay_active:
		if current_moves.has(current_align()):
			previous_moves = current_moves[current_align()].duplicate()
		current_moves[current_align()] = []
		
		controlers[current_controler].start_turn(alignment)
	
	call_deferred("think")


func think():
#	print("think")
	
	timer = thinking_timer
	
	if ReplayControl.replay_active:
		if replay_done_action:
			replay_done_action = false
			var next_move = ReplayControl.get_next_move()
#			print(current_alignment, " ", next_move)
			if next_move[0] == ReplayControl.RECORD_TYPE_REGION:
				selected_capital = next_move[1]
			elif next_move[0] == ReplayControl.RECORD_TYPE_OVERTAKE:
				selected_capital = next_move[1]
				CALL_overtake = true
			else:
				match(next_move[1]):
					"forfeit":
						CALL_forfeit = true
					"end_turn":
						CALL_end_turn = true
					"change_current_phase":
						CALL_change_current_phase = true
					"nothing":
						CALL_nothing = true
					"add_action":
						CALL_cheat = true
	else:
		find_owned_regions()
		
		match region_control.current_phase:
			RegionControl.PHASE.NORMAL:
				if controlers[current_controler].has_method("think_normal"):
					controlers[current_controler].call("think_normal")
			RegionControl.PHASE.MOBILIZE:
				if controlers[current_controler].has_method("think_mobilize"):
					controlers[current_controler].call("think_mobilize")
			RegionControl.PHASE.BONUS:
				if controlers[current_controler].has_method("think_bonus"):
					controlers[current_controler].call("think_bonus")


func timer_ended():
#	print("timer ended")
	if ReplayControl.replay_active and replay_done_action:
		think()
		return
	var should_think : bool = true
	if CALL_nothing:
		reset_CALL()
	elif CALL_forfeit:
		reset_CALL()
		region_control.forfeit()
		should_think = false
	elif CALL_end_turn:
		reset_CALL()
		region_control.end_turn(true)
		should_think = false
	elif CALL_change_current_phase:
		reset_CALL()
		region_control.change_current_phase()
		should_think = region_control.current_phase != RegionControl.PHASE.NORMAL
	elif CALL_cheat:
		reset_CALL()
		region_control.add_action()
		should_think = true
	elif CALL_overtake:
		reset_CALL()
		region_control.overtake_region(selected_capital)
		if not ReplayControl.replay_active:
			if not current_moves.has(current_align()):
				current_moves[current_align()] = []
			current_moves[current_align()].append(selected_capital)
		should_think = true
	else:
		region_control.get_node(selected_capital).action_decided()
		if not ReplayControl.replay_active:
			if not current_moves.has(current_align()):
				current_moves[current_align()] = []
			current_moves[current_align()].append(selected_capital)
	
	replay_done_action = true
	if should_think:
		think()
#	print(current_moves)


func reset_CALL():
	CALL_forfeit = false
	CALL_end_turn = false
	CALL_change_current_phase = false
	CALL_nothing = false
	CALL_cheat = false
	CALL_overtake = false


func current_align() -> int:
	if region_control:
		return region_control.current_playing_align
	else:
		return 0


func find_owned_regions(alignment : int = current_align()):
	owned_regions[alignment] = []
	for region in region_control.get_children():
		if not region is Region:
			continue
		if region.alignment != alignment:
			continue
		owned_regions[alignment].append(region)


func used_region_previously(region_name) -> bool:
	return previous_moves.has(region_name)


func get_owned_regions(alignment : int = current_align()) -> Array:
	if not owned_regions.has(alignment):
		find_owned_regions(alignment)
	return owned_regions[alignment].duplicate()


func aliances_on() -> bool:
	return region_control.use_aliances


func get_allied_regions(alignment : int = current_align()) -> Array:
	var allied_regs : Array = []
	for i in range(region_control.align_amount - 1):
		if alignment_friendly(alignment, i + 1) and alignment != i + 1:
			find_owned_regions(i + 1)
			allied_regs.append_array(get_owned_regions(i + 1))
#	print(allied_regs)
	return allied_regs


func get_region(region_name : String) -> Region:
	return region_control.get_node(region_name)


func get_current_moves() -> Array:
	if not current_moves.has(current_align()):
		current_moves[current_align()] = []
	return current_moves[current_align()].duplicate()


func get_action_amount() -> int:
	return region_control.get_action_amount()


func get_first_action_amount() -> int:
	return region_control.first_action_amount


func get_bonus_action_amount() -> int:
	return region_control.bonus_action_amount


## TODO: Fix this typo
func get_alingment_amount() -> int:
	return region_control.align_amount


func get_capital_amount(alignment : int = current_align()) -> int:
	return region_control.capital_amount[alignment - 1]


func alignment_friendly(your_align : int, opposing_align : int) -> bool:
	return region_control.alignment_friendly(your_align, opposing_align)


func alignment_inactive(alignment : int = current_align()) -> bool:
	return region_control.alignment_inactive(alignment)

