extends Node
class_name DPControl


signal timer_has_ended


enum CONTROLER {USER, DEFAULT, TURTLE, NEURAL, CHEATER, DUMMY, SIZE}

const THINKING_TIMER_DEFAULT : float = 0.5
const THINKING_TIMER_SPEEDRUN : float = 0.05
const THINKING_TIMER_NETWORK : float = 0.001

const CONTROLER_NAMES : Array = ["User Controled", "Simple", "Turtle", "Neural", "Cheater", "Environment"]


@export var controler_paths : Array[NodePath] = []


@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl


var thinking_timer : float = THINKING_TIMER_DEFAULT

var controlers : Array[DigitalPlayer] = []
var current_controler : int

var timer : float = 0

var owned_regions : Dictionary = {}
var current_moves : Dictionary = {}
var previous_moves : Set = Set.new()

var selected_capital : String = ""

var CALL_change_current_phase : bool = false
var CALL_end_turn : bool = false
var CALL_forfeit : bool = false
var CALL_nothing : bool = false
var CALL_cheat : bool = false
var CALL_overtake : bool = false

var replay_done_action : bool = true


func _ready():
	Options.timestamp("DPCotrol")
	
	dp_speedrun_update()
	
	if game_control:
		game_control.dp_control = self
	
	# Player controler, not handled by dp_control
	controlers.append(null)
	# Other controlers
	for path in controler_paths:
		var dp : DigitalPlayer = get_node(path) as DigitalPlayer
		if dp:
			dp.controler = self
			controlers.append(dp)
	
	timer_has_ended.connect(timer_ended)
	
	call_deferred("_ready_deferred")
	
	Options.timestamp("DPCotrol ready", "DPCotrol")


func _ready_deferred():
	if game_control:
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
	previous_moves.clear()
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
			current_moves[current_align()].copy_to(previous_moves)
		current_moves[current_align()] = Set.new()
		
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
		
		var dp : DigitalPlayer = controlers[current_controler]
		if dp:
			var phase = RegionControl.PHASE.NORMAL
			if region_control:
				phase = region_control.current_phase
			match phase:
				RegionControl.PHASE.NORMAL:
					dp.think_normal()
				RegionControl.PHASE.MOBILIZE:
					dp.think_mobilize()
				RegionControl.PHASE.BONUS:
					dp.think_bonus()
		else:
			push_error("Digital player number ", current_controler, " is null, skipping turn")
			CALL_end_turn = true


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
			note_region_selection(selected_capital, current_align())
		should_think = true
	else:
		region_control.get_node(selected_capital).action_decided()
		if not ReplayControl.replay_active:
			note_region_selection(selected_capital, current_align())
	
	replay_done_action = true
	if should_think:
		think()
#	print(current_moves)


func _add_new_current_moves(alignment : int) -> void:
	if not current_moves.has(alignment):
		current_moves[alignment] = Set.new()


func note_region_selection(region : StringName, alignment : int) -> void:
	_add_new_current_moves(alignment)
	current_moves[alignment].add(region)


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
	if not region_control:
		return
	for region in region_control.regions.values():
		if region.alignment != alignment:
			continue
		owned_regions[alignment].append(region)


func used_region_previously(region_name) -> bool:
	return previous_moves.contains(region_name)


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
	return region_control.get_region(region_name)


func get_current_moves() -> Set:
	_add_new_current_moves(current_align())
	return current_moves[current_align()].duplicate()


func get_action_amount() -> int:
	return region_control.get_action_amount()


func get_first_action_amount() -> int:
	return region_control.first_action_amount


func get_bonus_action_amount() -> int:
	return region_control.bonus_action_amount


func get_alignment_amount() -> int:
	return region_control.align_amount


func get_capital_amount(alignment : int = current_align()) -> int:
	return region_control.get_alignment_capitals(alignment)


func alignment_friendly(your_align : int, opposing_align : int) -> bool:
	return region_control.alignment_friendly(your_align, opposing_align)


func alignment_inactive(alignment : int = current_align()) -> bool:
	return region_control.alignment_inactive(alignment)

