extends Line2D
class_name RegionConnection


const CUTOFF_DISTANCE : float = pow(768.0, 2)
const SHOW_TIMER_BASE : float = 3.0

const TINT : Color = Color(0.6, 0.6, 0.6, 1.0)
const TINT_REDUCTION : Color = Color(0.25, 0.25, 0.25, 1.0)
const TINT_DISABLED : Color = Color(0.15, 0.15, 0.15, 0.65)
const CUTOFF_APLHA : float = 0.0

const LABEL_SIZE_BASE : Vector2 = Vector2(256, 24)


@export var num : int = 0
@export var disabled : bool = false

@export var region_from : Region
@export var region_to : Region

@export var power_reduction : int = 0
@export var kinetic : bool = false

@onready var label : Label = null

var is_cutoff : bool = false

var from_position : Vector2
var to_position : Vector2

var from_side : bool = false

var label_size : Vector2 = LABEL_SIZE_BASE

var timer : float = 0.0


func _ready():
	update()
	
	var region_control: RegionControl = region_from.get_parent() as RegionControl
	if region_control:
		width *= region_control.city_size
	
	if kinetic or is_cutoff or power_reduction > 0:
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.z_index = 11
		label.size = LABEL_SIZE_BASE
		if region_control:
			label.scale *= region_control.city_size
			label_size *= region_control.city_size
		add_child(label)
	
	default_color = Color(0, 0, 0.2)
	
	gradient = Gradient.new()
	gradient.set_offset(1, 0.325)
	gradient.add_point(0.675, TINT)
	gradient.add_point(1.0, TINT)
	update_gradient()
	
	z_index = 10


func _process(delta):
	timer -= delta
	if timer > 0:
		if kinetic:
			var prev_is_cutoff : bool = is_cutoff
			update()
			if prev_is_cutoff != is_cutoff:
				update_gradient()
	else:
		hide_self()


func get_other_region(region : Region) -> Region:
	if disabled:
		return null
	if region == region_from:
		return region_to
	else:
		return region_from


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


func update():
	from_position = region_from.position
	to_position = region_to.position
	
	clear_points()
	add_point(from_position)
	add_point(to_position * 0.325 + from_position * 0.675)
	add_point(to_position * 0.675 + from_position * 0.325)
	add_point(to_position)
	
	update_label()
	
	var difference : Vector2 = to_position - from_position
	var distance : float = pow(difference.x, 2) + pow(difference.y * 1.333, 2)
	
	if distance > CUTOFF_DISTANCE:
		is_cutoff = true
	else:
		is_cutoff = false


func update_label():
	if label:
		if is_cutoff:
			label.visible = true
			label.text = ""
			if from_side:
				label.position = to_position * 0.25 + from_position * 0.75 - label_size * 0.5
				label.text += region_to.name
			else:
				label.position = to_position * 0.75 + from_position * 0.25 - label_size * 0.5
				label.text += region_from.name
			if disabled:
				label.text += " [X]"
			elif power_reduction > 0:
				label.text += " (-" + str(power_reduction) + ")"
		elif disabled:
			label.visible = true
			label.position = (to_position + from_position - label_size) * 0.5
			label.text = "[X]"
		elif power_reduction > 0:
			label.visible = true
			label.position = (to_position + from_position - label_size) * 0.5
			if power_reduction > 0:
				label.text = "(-" + str(power_reduction) + ")"
		else:
			label.visible = false


func update_gradient():
	var edge : Color = TINT
	if disabled:
		edge = TINT_DISABLED
	elif power_reduction > 0:
		edge = TINT_REDUCTION
	var middle : Color = edge
	if is_cutoff:
		middle.a = CUTOFF_APLHA
		gradient.set_color(3, region_from.color * edge)
		gradient.set_color(2, region_from.color * middle)
		gradient.set_color(1, region_to.color * middle)
		gradient.set_color(0, region_to.color * edge)
	else:
		gradient.set_color(0, region_from.color * edge)
		gradient.set_color(1, region_from.color * middle)
		gradient.set_color(2, region_to.color * middle)
		gradient.set_color(3, region_to.color * edge)


func hide_self():
	timer = 0.0
	visible = false


func show_self(region : Region = null):
	timer = SHOW_TIMER_BASE + num * 0.1
	visible = true
	from_side = (region == region_from)
	update_label()
