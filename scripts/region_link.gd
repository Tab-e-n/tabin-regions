@tool
extends Line2D
class_name RegionLink


const CUTOFF_DISTANCE : float = pow(768.0, 2)
const SHOW_TIMER_BASE : float = 3.0

const TINT : Color = Color(0.6, 0.6, 0.6, 1.0)
const TINT_REDUCTION : Color = Color(0.25, 0.25, 0.25, 1.0)
const TINT_DISABLED : Color = Color(0.15, 0.15, 0.15, 0.65)
const CUTOFF_APLHA : float = 0.0

const LABEL_SIZE_BASE : Vector2 = Vector2(256, 24)


@export_node_path("Region") var from_path : NodePath:
	set(path):
		from_name = path.get_name(path.get_name_count() - 1)
@export_node_path("Region") var to_path : NodePath:
	set(path):
		to_name = path.get_name(path.get_name_count() - 1)

@export var from_name : StringName
@export var to_name : StringName

@export var generate_name : bool = false:
	set(_u):
		_generate_name()

@export var disabled : bool = false
@export var power_reduction : int = 0

@export var kinetic : bool = false


@onready var from : Region
@onready var to : Region

@onready var label : Label = null


var is_cutoff : bool = false

var from_side : bool = false

var label_size : Vector2 = LABEL_SIZE_BASE

var num : int = 0
var timer : float = 0.0

var first_time_update : bool = true


func _ready():
	if Engine.is_editor_hint():
		return
	
	_link_up(from)
	_link_up(to)
	
	gradient = Gradient.new()
	gradient.set_offset(1, 0.325)
	gradient.add_point(0.675, TINT)
	gradient.add_point(1.0, TINT)
	
	default_color = Color(0, 0, 0.2)
	
	z_index = 10
	
	hide_self()
	
	Options.timestamp(" -- " + name + " ready", "RegionLinks")


func _link_up(region : Region) -> void:
	if not region:
		return
	region.links.append(self)
	if region.kinetic:
		kinetic = true


func _ready_link(region_control : RegionControl) -> void:
	from = region_control.get_region(from_name)
	to = region_control.get_region(to_name)
	
	_link_up(from)
	_link_up(to)
	
	width *= region_control.city_size
	Options.timestamp("_ready_link", "RegionLinks")


func _process(delta):
	if Engine.is_editor_hint():
		return
	
	if timer > 0:
		timer -= delta
		if kinetic:
			var prev_is_cutoff : bool = is_cutoff
			update()
			if prev_is_cutoff != is_cutoff:
				update_gradient()
		if timer <= 0:
			hide_self()


func _get_region_control() -> RegionControl:
	var region : Region = from
	var region_control : RegionControl = null
	if not region:
		region = to
	if region:
		region_control = region.get_parent() as RegionControl
	return region_control


func _make_label() -> void:
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 11
	label.size = LABEL_SIZE_BASE
	var region_control : RegionControl = _get_region_control()
	if region_control:
		label.scale *= region_control.city_size
		label_size *= region_control.city_size
	add_child(label)


func _set_cutoff_label(close : Region, far : Region) -> void:
	if not close or not far:
		return
	label.position = far.position * 0.25 + close.position * 0.75 - label_size * 0.5
	label.text = far.name + " " + label.text


func _get_region_name(path : NodePath) -> String:
	if path.is_empty():
		return "_"
	var region : Region = get_node(path) as Region
	if region:
		return region.name
	return "?"


func _generate_name() -> void:
	if to_name < from_name:
		name = to_name + "-" + from_name
	else:
		name = from_name + "-" + to_name


func get_other_region(region : Region) -> Region:
	if disabled:
		return null
	if region == from:
		return to
	else:
		return from


func set_disabled(value : bool):
	if disabled != value:
		disabled = value
		update_gradient()
		update_label()


func set_power_reduction(amount : int):
	power_reduction = amount
	if power_reduction < 0:
		power_reduction = 0
	update_gradient()
	update_label()


func should_have_label() -> bool:
	return kinetic or is_cutoff or power_reduction > 0


func check_and_make_label() -> void:
	if label:
		return
	if should_have_label():
		_make_label()


func update_label():
	check_and_make_label()
	if label and should_have_label():
		label.visible = true
		
		if disabled:
			label.text = "[X]"
		elif power_reduction > 0:
			label.text = "(-" + str(power_reduction) + ")"
		else:
			label.text = ""
		
		if is_cutoff:
			if from_side:
				_set_cutoff_label(from, to)
			else:
				_set_cutoff_label(to, from)
		elif from and to:
			label.position = (to.position + from.position - label_size) * 0.5
	elif label:
		label.visible = false


func update_gradient():
	if not from or not to or not gradient:
		return
	var edge : Color = TINT
	if disabled:
		edge = TINT_DISABLED
	elif power_reduction > 0:
		edge = TINT_REDUCTION
	var middle : Color = edge
	if is_cutoff:
		middle.a = CUTOFF_APLHA
		gradient.set_color(3, from.color * edge)
		gradient.set_color(2, from.color * middle)
		gradient.set_color(1, to.color * middle)
		gradient.set_color(0, to.color * edge)
	else:
		gradient.set_color(0, from.color * edge)
		gradient.set_color(1, from.color * middle)
		gradient.set_color(2, to.color * middle)
		gradient.set_color(3, to.color * edge)


func update():
	if not from or not to:
		return
	clear_points()
	add_point(from.position)
	add_point(to.position * 0.325 + from.position * 0.675)
	add_point(to.position * 0.675 + from.position * 0.325)
	add_point(to.position)
	
	var difference : Vector2 = to.position - from.position
	var distance : float = pow(difference.x, 2) + pow(difference.y * 1.333, 2)
	
	if distance > CUTOFF_DISTANCE:
		is_cutoff = true
	else:
		is_cutoff = false
	
	update_gradient()
	update_label()


func hide_self():
	timer = 0.0
	visible = false


func show_self(region : Region = null):
	timer = SHOW_TIMER_BASE + num * 0.1
	visible = true
	from_side = (region == from)
	if first_time_update:
		first_time_update = false
		update()
	else:
		update_label()
