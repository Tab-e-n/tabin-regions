extends Node
class_name DPControl


signal think_timeout


enum Controler {
	DEFAULT,
	SIMPLETON,
	TURTLE,
	OVERTHINKER,
	CHEATER,
	DUMMY,
	BOOKWYRM,
	SIZE
}
enum PlayerAction {
	NOTHING,
	REGION,
	OVERTAKE,
	ADD_ACTION,
	NEXT_PHASE,
	END_TURN,
	FORFEIT,
	MOD_POWER,
	MOD_MAX_POWER,
	GRAB_EXTRA_POWER,
}

const THINKING_TIMER_MAX: float = 0.75
const THINKING_TIMER_DEFAULT: float = 0.505
const THINKING_TIMER_MIN: float = 0.05

const THINKING_TIMER_SPEEDRUN: float = 0.025
const THINKING_TIMER_NETWORK: float = 0.001

const CONTROLER_NAMES: Array = ["User Controled", "Simpleton", "Turtle", "Overthinker", "Cheater", "Environment", "Bookwyrm"]


@export var controler_paths: Array[NodePath] = []


@onready var game_control: GameControl = get_parent()
@onready var region_control: RegionControl


var thinking_timer: float = THINKING_TIMER_DEFAULT

var controlers: Array[DigitalPlayer] = []
var current_controler: int

var timer: float = 0
var paused: bool = false

var owned_regions: Dictionary = {}
var current_moves: Dictionary = {}
var previous_moves: Set = Set.new()

var selected_action: PlayerAction = PlayerAction.REGION
var selected_capital: String = ""
#	set(c):
#		print(get_stack())
#		print("-> ", c)
#		selected_capital = c
var selected_amount: int = 1

var replay_done_action: bool = true


func _ready():
	Options.timestamp("DPCotrol")
	
	thinking_timer_update()
	
	if game_control:
		game_control.dp_control = self
	
	# Player controler, not handled by dp_control
	controlers.append(null)
	# Other controlers
	for path in controler_paths:
		var dp: DigitalPlayer = get_node(path) as DigitalPlayer
		if dp:
			dp.controler = self
			controlers.append(dp)
	
	think_timeout.connect(_on_think_timeout)
	
	paused = ReplayControl.replay_active or MapSetup.player_amount == 0
	
	Options.timestamp("DPCotrol ready", "DPCotrol")


func _init_replay():
	while ReplayControl.initializing and not ReplayControl.replay_ended:
		_on_think_timeout()


func _reset():
	owned_regions = {}
	current_moves = {}
	previous_moves.clear()
	selected_action = PlayerAction.REGION
	selected_capital = ""
	selected_amount = 1
	timer = 0


func _process(delta: float):
	if not RegionControl.active(region_control):
		return
	
#	print(timer)
	if region_control.is_player_controled:
		timer = 0
	if timer > 0:
		if ReplayControl.replay_active and ReplayControl.initializing:
			timer = -1
		if not paused:
			timer -= delta
		if timer == 0:
			timer = -1
	if timer < 0:
		timer = 0
		think_timeout.emit()


func _on_think_timeout():
	if ReplayControl.replay_active and replay_done_action:
		think()
		return
	
	var should_continue: bool = perform_selection()
	
	replay_done_action = true
	if should_continue:
		think()
#	print(current_moves)


func thinking_timer_update():
	if game_control is NetworkTrainer:
		thinking_timer = THINKING_TIMER_NETWORK
	elif Options.dp_speedrun:
		thinking_timer = THINKING_TIMER_SPEEDRUN
	else:
		thinking_timer = Options.dp_think_timer


func toggle_pause():
	paused = not paused


func start_turn(alignment : int, control : int):
#	print("start turn")
	
	current_controler = control
	
	if not ReplayControl.replay_active:
		if current_moves.has(current_align()):
			current_moves[current_align()].copy_to(previous_moves)
		current_moves[current_align()] = Set.new()
		
		controlers[current_controler].start_turn(alignment)
	
	think.call_deferred()


func think():
	timer = thinking_timer
	
	if ReplayControl.replay_active:
		replay()
	else:
		selected_action = PlayerAction.REGION
		selected_capital = ""
		selected_amount = 1
		
		find_owned_regions()
		
		var dp: DigitalPlayer = controlers[current_controler]
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
			selected_action = PlayerAction.END_TURN


func replay():
	if not replay_done_action:
		return
	replay_done_action = false
	
	var next_move = ReplayControl.get_next_move()
	print(next_move)
	var type: ReplayControl.RecordType = next_move[0]
	var action: String = next_move[1]
	var amount: int = next_move[2]
	
	if type == ReplayControl.RecordType.REGION:
		selected_action = PlayerAction.REGION
		selected_capital = action
		selected_amount = amount
	elif type == ReplayControl.RecordType.OVERTAKE:
		selected_action = PlayerAction.OVERTAKE
		selected_capital = action
		selected_amount = amount
	
	elif type == ReplayControl.RecordType.FUNCTION:
		selected_capital = action
		match(action):
			"forfeit":
				selected_action = PlayerAction.FORFEIT
			"end_turn":
				selected_action = PlayerAction.END_TURN
			"change_current_phase":
				selected_action = PlayerAction.NEXT_PHASE
			"nothing":
				selected_action = PlayerAction.NOTHING
			"add_action":
				selected_action = PlayerAction.ADD_ACTION
			"grab_extra_power":
				selected_action = PlayerAction.GRAB_EXTRA_POWER
	
	elif type == ReplayControl.RecordType.VOLCANO:
		selected_action = PlayerAction.NOTHING
		match(action):
			"shake_screen":
				region_control.volcanos[amount].shake_screen()
	elif type == ReplayControl.RecordType.TORNADO:
		selected_action = PlayerAction.NOTHING
		if action.is_empty():
			region_control.tornados[amount].deactivate()
		else:
			region_control.tornados[amount].take_region(region_control.get_region(action), thinking_timer)
	
	elif type == ReplayControl.RecordType.START:
		selected_action = PlayerAction.NOTHING
	
	elif type == ReplayControl.RecordType.MOD_POWER:
		selected_action = PlayerAction.MOD_POWER
		selected_capital = action
		selected_amount = amount
	elif type == ReplayControl.RecordType.MOD_MAX_POWER:
		selected_action = PlayerAction.MOD_MAX_POWER
		selected_capital = action
		selected_amount = amount
	
	else:
		push_warning("Unrecognized replay move: ", type, " ", action, " ", amount)
		selected_action = PlayerAction.NOTHING


func perform_selection() -> bool:
#	print(selected_action, " |", selected_capital, "| ", selected_amount)
	match selected_action:
		PlayerAction.NOTHING:
			pass
		
		PlayerAction.REGION:
			action_decided(selected_capital, selected_amount)
		
		PlayerAction.OVERTAKE:
			if selected_amount == -1:
				overtake(selected_capital)
			else:
				overtake_as_alignment(selected_capital, selected_amount)
		
		PlayerAction.ADD_ACTION:
			add_actions(selected_amount)
		
		PlayerAction.NEXT_PHASE:
			return next_phase()
		
		PlayerAction.END_TURN:
			end_turn()
			return false
		
		PlayerAction.FORFEIT:
			forfeit()
			return false
		
		PlayerAction.MOD_POWER:
			modify_power(selected_capital, selected_amount)
		
		PlayerAction.MOD_MAX_POWER:
			modify_max_power(selected_capital, selected_amount)
		
		PlayerAction.GRAB_EXTRA_POWER:
			grab_extra_power()
	
	return true


# ------------ PREVIOUS MOVES ------------

func _add_new_current_moves(alignment : int) -> void:
	if not current_moves.has(alignment):
		current_moves[alignment] = Set.new()


func note_region_selection(region: StringName, alignment: int) -> void:
	_add_new_current_moves(alignment)
	current_moves[alignment].add(region)


# ------------ MOVE SELECTION HELPERS ------------

func select_overtake(region_name: String):
	selected_action = PlayerAction.OVERTAKE
	selected_capital = region_name
	selected_amount = -1


func select_overtake_as_alignment(region_name: String, alignment: int):
	selected_action = PlayerAction.OVERTAKE
	selected_capital = region_name
	selected_amount = alignment


# ------------ PLAYER MOVES ------------

func action_decided_region(region: Region, amount: int) -> void:
	if region:
		region.action_decided(amount)
		if not ReplayControl.replay_active:
			note_region_selection(region.name, current_align())


func action_decided(region_name: String, amount: int) -> void:
	var region = region_control.get_region(region_name)
	action_decided_region(region, amount)


func overtake(region_name: String) -> bool:
	if region_control.overtake_region(region_name):
		ReplayControl.record_move(ReplayControl.RecordType.OVERTAKE, region_name, -1)
		if not ReplayControl.replay_active:
			note_region_selection(region_name, current_align())
		return true
	return false


func add_actions(amount: int) -> void:
	region_control.add_action(amount)
	ReplayControl.record_move(ReplayControl.RecordType.FUNCTION, "add_action", amount)


func forfeit() -> void:
	region_control.forfeit()
	ReplayControl.record_move(ReplayControl.RecordType.FUNCTION, "forfeit")


func end_turn() -> void:
	region_control.end_turn()
	ReplayControl.record_move.call_deferred(ReplayControl.RecordType.FUNCTION, "end_turn")


func next_phase() -> bool:
	region_control.change_current_phase()
	ReplayControl.record_move(ReplayControl.RecordType.FUNCTION, "change_current_phase")
	return region_control.current_phase != RegionControl.PHASE.NORMAL


func grab_extra_power() -> void:
	region_control.grab_extra_power()
	ReplayControl.record_move(ReplayControl.RecordType.FUNCTION, "grab_extra_power")


# -- PLAYER INDEPENDENT MOVES --

func overtake_as_alignment(region_name: String, alignment: int) -> bool:
	if region_control.overtake_region(region_name, alignment, true):
		ReplayControl.record_move(ReplayControl.RecordType.OVERTAKE, region_name, alignment)
		return true
	return false


func modify_power(region_name: String, amount: int) -> bool:
	var region: Region = region_control.get_region(region_name)
	if region:
		var retval: bool = region._set_power(amount)
		ReplayControl.record_move(ReplayControl.RecordType.MOD_POWER, region_name, amount)
		return retval
	return false


func modify_max_power(region_name: String, amount: int) -> bool:
	var region: Region = region_control.get_region(region_name)
	if region:
		region.set_max_power(amount)
		ReplayControl.record_move(ReplayControl.RecordType.MOD_MAX_POWER, region_name, amount)
		return true
	return false


# ------------ OWNED REGIONS ------------

func find_owned_regions(alignment: int = current_align()):
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


# ------------ ALLIANCES ------------

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


# ------------ GET FUNCTIONS ------------

func current_align() -> int:
	if region_control:
		return region_control.current_playing_align
	else:
		return 0


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


func alignment_inactive(alignment: int = current_align()) -> bool:
	return region_control.alignment_inactive(alignment)
