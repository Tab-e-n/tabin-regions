extends Node
class_name RegionPath


@export var pathway_region_names : Array[String] = []

@export_subgroup("Disasters")
@export var chosen_frequency : int = 5
@export var chosen_offset : int = 0

var active : bool = false
var current : int = 0
var pathway : Array[Region] = []
var warnings : Array[RegionWarning] = []


func ready_pathway(region_control : RegionControl) -> void:
	for region_name in pathway_region_names:
		var region = region_control.get_region(region_name)
		if not region:
			push_warning("Could not get region ", region_name)
			continue
		pathway.append(region)


func is_active() -> bool:
	return active


func reset() -> void:
	current = 0
	active = true


func get_next_region() -> Region:
	if not active:
		return null
	var region : Region = pathway[current] as Region
	current += 1
	if current >= pathway.size():
		active = false
	return region


func activate_iteration(iteration : int) -> void:
	reset()
	active = ((iteration + chosen_offset) % chosen_frequency) == 0


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
