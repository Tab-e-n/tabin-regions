extends Node
## Volcano is a game object that periodically explodes and turns regions neutral.
## Volcanos act like pseudo-players.
class_name Volcano


const WARNING_NAME : String = "VolcanoWarning"


## Region that will be used to decide when the volcano erupts.
## The volcano will add 1 power to it's residing region every turn.
## When at max power, the volcano erupts and the region is set back to 1 power.
## Residing region should be a capital.
@export var residing_region : Region
## The alignment used by the volcano. Should have DPDummy.
@export var dummy_alignment : int = 0
## Makes warnings appear further from the city.
## Useful if multiple disasters are present, so their warnings don't overlap.
@export var warning_number : int = 1

@export_subgroup("Screen Shake")
@export var duration : float = 1.2
@export var amplitude : float = 32
@export var period : float = 0.8

@onready var controler : DPDummy
@onready var dp_control : DPControl
@onready var region_control : RegionControl

var pathways: Array[RegionPath] = []
var active: bool = false
var iteration: int = 0
var volcano_id: int = 0


func _ready():
	
	region_control = get_parent() as RegionControl
	if not region_control:
		push_warning("Volcano could not find region control, thus it is not functional.")
		queue_free()
		return
	if region_control.dummy:
		queue_free()
		return
	
	volcano_id = region_control.volcanos.size()
	region_control.volcanos.append(self)
	
	if ReplayControl.replay_active:
		return
	
	if not residing_region:
		push_warning("Volcano could not find residing region, thus it is not functional.")
		queue_free()
		return
	
	_deferred_ready.call_deferred()
	activate_pathways.call_deferred()


func _deferred_ready():
	for node in get_children():
		var path : RegionPath = node as RegionPath
		if not path:
			continue
		path.ready_pathway(region_control)
		path.create_warnings(warning_number, region_control.get_alignment_color(dummy_alignment))
		pathways.append(path)
	
	dp_control = region_control.dp_control
	var controler_id = region_control.align_controlers[dummy_alignment - 1]
	controler = dp_control.controlers[controler_id] as DPDummy
	if not controler:
		push_warning("Volcano could not find DPDummy, thus it is not functional. Use custom_dp_setup to force the dummy_alignment to have DPDummy.")
		queue_free()
		return
	controler.started_turn.connect(_start_volcano_turn)
	controler.thinking_normal.connect(_think_normal)
	controler.thinking_bonus.connect(_think_bonus)
	controler.thinking_mobilize.connect(_think_mobilize)


func _start_volcano_turn():
	if controler.current_alignment != dummy_alignment:
		return
	
	if residing_region.alignment != dummy_alignment:
		controler.selected_action = DPControl.PlayerAction.FORFEIT
		for path in pathways:
			path.deactivate()
			path.update_warnings()
		return
	
	if residing_region.power == residing_region.max_power:
		controler.selected_action = DPControl.PlayerAction.NEXT_PHASE
#	print(residing_region.power, "/", residing_region.max_power, " -> ", controler.selected_action)
	
	active = true


func _think_normal():
	if controler.current_alignment != dummy_alignment:
		return
	if controler.selected_action != DPControl.PlayerAction.REGION:
#		print("Skipping normal")
		return
	if not active:
#		print("Ending turn")
		controler.selected_action = DPControl.PlayerAction.END_TURN
		return
	
	if region_control.get_action_amount() == 0:
		controler.selected_action = DPControl.PlayerAction.ADD_ACTION
	else:
		dp_control.selected_capital = residing_region.name
		active = false
#		print(dp_control.selected_capital)


func _think_mobilize():
	if controler.current_alignment != dummy_alignment:
		return
	if controler.selected_action != DPControl.PlayerAction.REGION:
		return
	
	if residing_region.power == 1:
#		print("Erupting")
		controler.selected_action = DPControl.PlayerAction.NEXT_PHASE
		shake_screen()
	else:
#		print("Timer reset")
		dp_control.selected_capital = residing_region.name
		dp_control.selected_amount = residing_region.power - 1


func _think_bonus():
	if controler.current_alignment != dummy_alignment:
		return
	
	var call_end_turn = true
	for path in pathways:
		if not path.is_active():
			continue
		call_end_turn = false
		dp_control.select_overtake(path.get_next_region().name)
		break
	if call_end_turn:
		controler.selected_action = DPControl.PlayerAction.END_TURN
		activate_pathways()


func activate_pathways():
	for path in pathways:
		path.activate_iteration(iteration)
		path.update_warnings()
	iteration += 1


func shake_screen():
	if region_control.game_camera:
		ReplayControl.record_move(ReplayControl.RecordType.VOLCANO, "shake_screen", volcano_id)
		region_control.game_camera.shake_camera(duration, amplitude, period)
