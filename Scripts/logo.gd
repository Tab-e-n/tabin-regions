extends Node2D


enum {PHASE_START, PHASE_HOLD, PHASE_END}


var phase : int = PHASE_START

var timer : float = 0.0
var current_region : int = 0
var region_ids : Array = range(14)
var region_velocities : Array[Vector2] = []


func _ready():
	region_ids.shuffle()
	for i in range(14):
		region_velocities.append(Vector2(0, 0))


func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		phase = PHASE_HOLD
		timer = 0.0
		current_region = 0
		for i in range(14):
			var region : Region = get_node(str(i)) as Region
			if region:
				region.color_self(true, Color("eeeeee"))


func _process(delta):
	if phase == PHASE_START:
		timer += delta
		if timer >= 0.075:
			timer = 0.0
			
			var region : Region = get_node(str(region_ids[current_region])) as Region
			if region:
				region.color_self(true, Color("eeeeee"))
			
			current_region += 1
			if current_region == 14:
				current_region = 0
				phase = PHASE_HOLD
	if phase == PHASE_HOLD:
		timer += delta
		if timer >= 1.5:
			timer = 0.0
			phase = PHASE_END
	if phase == PHASE_END:
		timer += delta
		if current_region != 14:
			if timer >= 0.05:
				timer = 0.0
				region_velocities[current_region] = Vector2((float(current_region) - 6.5) * 3, -32)
				current_region += 1
		elif timer >= 1.5:
				get_tree().change_scene_to_file("res://title.tscn")
		for i in range(current_region):
			region_velocities[i].y += 1
			var region = get_node(str(i))
			region.position += region_velocities[i] * delta * 60
