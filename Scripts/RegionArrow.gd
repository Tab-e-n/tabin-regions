extends Line2D
class_name RegionArrow


const CUTOFF_DISTANCE : float = 768.0
const CUTOFF_ARROW_LENGHT : float = 128.0


@export var num : int = 0

@export var from_region : Region
@export var to_region : Region

@export var power_reduction : int = 0
@export var kinetic : bool = false


@onready var label : Label = null


var from_position : Vector2
var to_position : Vector2

var timer : float = 3.0


func _ready():
	var distance : float = update()
	
	if distance > CUTOFF_DISTANCE or power_reduction > 0:
		label = Label.new()
		label.text = to_region.name
		if power_reduction > 0:
			label.text = "(-" + str(power_reduction) + ")"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(256, 24)
		label.z_index = 11
		add_child(label)
	
	default_color = Color(0, 0, 0.2)
	
	gradient = Gradient.new()
	var dark : Color = Color(0.6, 0.6, 0.6)
	if power_reduction > 0:
		dark = Color(0.25, 0.25, 0.25)
	gradient.set_color(0, from_region.color * dark)
	gradient.set_color(1, to_region.color * dark)
	#gradient.add_point(0, from_color)
	#gradient.add_point(1, to_color)
	
	z_index = 10
	
	timer += num * 0.1


func _process(delta):
	timer -= delta
	if timer <= 0:
		queue_free()
	if kinetic:
		update()


func update() -> float:
	from_position = from_region.position
	to_position = to_region.position
	
	var difference = to_position - from_position
	var distance : float = sqrt(pow(difference.x, 2) + pow(difference.y * 1.333, 2))
	#print(distance)
	
	if distance > CUTOFF_DISTANCE:
#		print("Before: ", from_position, " ", to_position)
		var lenght = CUTOFF_ARROW_LENGHT + num * 24
		to_position.x = from_position.x + (difference.x * lenght) / distance
		to_position.y = from_position.y + (difference.y * lenght) / distance
#		print("After: ", from_position, " ", to_position)
		
		if label:
			label.position = to_position + Vector2(-128, -16)
	else:
		if label:
			label.position = from_position + difference * Vector2(0.5, 0.5) + Vector2(-32, -16)
	
	clear_points()
	add_point(from_position)
	add_point(to_position)
	
	return distance
