extends Node
class_name RegionPath


@export var pathway_region_names: Array[String] = []

@export_subgroup("Disasters")
## When a disaster activates, it chooses which paths to use.
## Chosen frequency determines how many activations need to happen until this path gets chosen.
## At frequency 1 the path will be chosen every time.
@export var chosen_frequency: int = 5
@export var chosen_offset: int = 0

var active: bool = false
var current: int = 0
var pathway: Array[Region] = []
var warnings: Array[RegionWarning] = []


func ready_pathway(region_control: RegionControl) -> void:
#	print(region_control.get_all_regions(), pathway_region_names)
	for region_name in pathway_region_names:
		var region = region_control.get_region(region_name)
		if not region:
			push_warning("Could not get region ", region_name)
			continue
		pathway.append(region)


func is_active() -> bool:
	return active


func activate() -> void:
	current = 0
	active = true


func deactivate() -> void:
	current = 0
	active = false


func activate_iteration(iteration : int) -> void:
	if ((iteration + chosen_offset) % chosen_frequency) == 0:
		activate()


func get_regions() -> Array[Region]:
	return pathway


func get_next_region() -> Region:
	if not active:
		return null
	var region : Region = pathway[current] as Region
	current += 1
	if current >= pathway.size():
		active = false
	return region


func create_warnings(warning_number : int, warning_color : Color) -> void:
	for region in pathway:
		var warning : RegionWarning = preload("res://objects/warning.tscn").instantiate() as RegionWarning
		warning.warning_number = warning_number
		warning.color = warning_color
		region.add_child(warning)
		warnings.append(warning)


func show_warnings() -> void:
	for warning in warnings:
		if not warning:
			continue
		warning.show_self()


func hide_warnings() -> void:
	for warning in warnings:
		if not warning:
			continue
		warning.hide_self()


func update_warnings() -> void:
	if active:
		show_warnings()
	else:
		hide_warnings()
