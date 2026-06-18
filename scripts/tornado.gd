extends Node
class_name Tornado


const WARNING_NAME: String = "TornadoWarning"


## Trigger region should be a capital. Only exists so RegionControl doesn't get confused,
## and think that the dummy alignment is eliminated
@export var trigger_region: Region
## The alignment used by the tornado. Should have DPDummy.
@export var dummy_alignment: int = 0
## Makes warnings appear further from the city.
## Useful if multiple disasters are present, so their warnings don't overlap.
@export var warning_number: int = 1

@onready var controler: DPDummy
@onready var dp_control: DPControl
@onready var region_control: RegionControl

var pathways: Array[RegionPath] = []
var current_path: int = 0
var active: bool = false
var iteration: int = 0

var disabled_regions: Array[Region] = []
var particles: Array[ParticleTornado] = []
var particle_tornado: PackedScene = preload("res://objects/particle_tornado.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	region_control = get_parent() as RegionControl
	if not region_control:
		push_warning("Tornado could not find region control, thus it is not functional.")
		queue_free()
		return
	if region_control.dummy:
		queue_free()
		return
	
	_deferred_ready.call_deferred()
	
	if ReplayControl.replay_active:
		return
	
	activate_pathways.call_deferred()


func _deferred_ready():
	var color = region_control.get_alignment_color(dummy_alignment)
	
	for node in get_children():
		if not (node as RegionPath):
			continue
		
		var particle: ParticleTornado = particle_tornado.instantiate() as ParticleTornado
		particle.tornado_id = region_control.tornados.size()
		particle.modulate = color
		region_control.add_child(particle)
		region_control.tornados.append(particle)
		particles.append(particle)
	
	if ReplayControl.replay_active:
		return
	
	for node in get_children():
		var path : RegionPath = node as RegionPath
		if not path:
			continue
		path.ready_pathway(region_control)
		path.create_warnings(warning_number, color)
		pathways.append(path)
		
		disabled_regions.append(null)
	
	dp_control = region_control.dp_control
	var controler_id = region_control.align_controlers[dummy_alignment - 1]
	controler = dp_control.controlers[controler_id] as DPDummy
	if not controler:
		push_warning("Tornado could not find DPDummy, thus it is not functional. Use custom_dp_setup to force the dummy_alignment to have DPDummy.")
		queue_free()
		return
	controler.started_turn.connect(_start_tornado_turn)
	controler.thinking_normal.connect(_think_normal)
	controler.thinking_bonus.connect(_think_bonus)
	controler.thinking_mobilize.connect(_think_mobilize)


func _start_tornado_turn():
	if controler.current_alignment != dummy_alignment:
		return
	
	if trigger_region and trigger_region.alignment != dummy_alignment:
		dp_control.CALL_forfeit = true
		for path in pathways:
			path.deactivate()
			path.update_warnings()
		reset_tornados()
		return
	
	var should_active_paths: bool = true
	for path in pathways:
		if path.is_active():
			should_active_paths = false
	
	if should_active_paths:
		activate_pathways()
		dp_control.CALL_end_turn = true
	
	active = true


func _think_normal():
	if controler.current_alignment != dummy_alignment:
		return
	if dp_control.CALL_end_turn or dp_control.CALL_forfeit:
		return
	if not active:
		dp_control.CALL_end_turn = true
		return
	
	if current_path == pathways.size():
		dp_control.CALL_end_turn = true
		current_path = 0
		return
	
	var path = pathways[current_path]
	var particle = particles[current_path]
	var disabled_region = disabled_regions[current_path]
	
	if disabled_region:
		disabled_region.set_captureable(true)
		disabled_regions[current_path] = null
	
	if path.is_active():
		var region: Region = path.get_next_region()
		dp_control.overtake_region(region.name)
		
		particle.take_region(region, dp_control.thinking_timer)
		ReplayControl.record_move(ReplayControl.RecordType.TORNADO, region.name, particle.tornado_id)
		
		region.set_captureable(false)
		disabled_regions[current_path] = region
	else:
		dp_control.CALL_nothing = true
		if particle.deactivate():
			ReplayControl.record_move(ReplayControl.RecordType.TORNADO, "", particle.tornado_id)
	
	current_path += 1


func _think_mobilize():
	if controler.current_alignment != dummy_alignment:
		return
	dp_control.CALL_change_current_phase = true


func _think_bonus():
	_think_normal()


func reset_tornados():
	for particle in particles:
		if particle.deactivate():
			ReplayControl.record_move(ReplayControl.RecordType.TORNADO, "", particle.tornado_id)
	
	for region in disabled_regions:
		if region:
			region.set_captureable(true)


func activate_pathways():
	for path in pathways:
		path.activate_iteration(iteration)
		path.update_warnings()
	
	reset_tornados()
	
	iteration += 1
