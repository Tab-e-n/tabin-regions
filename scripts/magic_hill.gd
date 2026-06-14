extends Node
class_name MagicHill


@export var residing_region : Region = null
@export var magic_path : RegionPath = null

@onready var region_control : RegionControl = get_parent()


func _ready():
	if region_control.dummy:
		return
	region_control.round_ended.connect(_on_round_ended)
	_deferred_ready.call_deferred()


func _deferred_ready():
	if not residing_region:
		push_warning("Magic Hill needs a residing Region to function.")
	if not magic_path:
		push_warning("Magic Hill needs a RegionPath to function.")
		return
	magic_path.ready_pathway(region_control)


func _on_round_ended():
	if region_control.dummy or not residing_region or not magic_path:
		return
	var decreased : bool = false
	if residing_region.power == residing_region.max_power:
		residing_region.power = 0
		decreased = true
		for region in magic_path.get_regions():
			region.reinforce(0)
			region.city_particle(false)
	residing_region.reinforce(0)
	residing_region.city_particle(decreased)
