extends Node2D


@onready var window_size : Vector2 = get_viewport_rect().size


const farthest_left : int = 576


var farthest_right : int = 576
var input_delay : bool = true


func _ready():
	# bad code inbound
	var pos : int = 1
	var size : int = GameStats.stats.size()
	for placement in range(size + 1):
		for stats in GameStats.stats:
			var place_text : String
			if placement == 0:
				place_text = "N/A"
			else:
				place_text = String.num(placement)
			if stats["placement"] == place_text:
#				print(stats)
				new_stats_panel(stats, pos)
				pos += 1
	
	var columb_amount : int = pos#GameStats.stats.size() + 1
	
	if columb_amount > 6:
		farthest_right += (columb_amount - 6) * 192
		$buttons/expo1.visible = true


func new_stats_panel(stats : Dictionary, pos : int):
	var panel : Panel = Panel.new()
	
	panel.add_theme_stylebox_override("panel", preload("res://styles/style_label_normal_box.tres"))
	panel.size = Vector2(192, 640)
	panel.modulate = stats["align color"]
	panel.position.x = 192 * pos
	
	$columbs.add_child(panel)
	
	var sprite : Sprite2D = Sprite2D.new()
	
	sprite.texture = preload("res://sprites/capital.png")
	sprite.scale = Vector2(0.8, 0.8)
	sprite.position.x = 192 * pos + 32
	sprite.position.y = 32
	sprite.modulate = stats["align color"]
	
	$columbs.add_child(sprite)
	
	var label : Label = Label.new()
	label.position.x = 192 * pos
	#label.position = Vector2(-32, -32)
	label.size = Vector2(64, 64)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = stats["placement"]
	
	$columbs.add_child(label)
	
	var columb : Label = Label.new()
	
	columb.clip_text = true
	columb.position.y += 8
	columb.size = Vector2(192, 192)
	columb.position.x = 192 * pos
	# Why did i name it like this
	var funny_spacing_value : String = "                "
	columb.text = funny_spacing_value + stats["alignment name"] + "\n" + funny_spacing_value + AIControl.CONTROLER_NAMES[stats["controler"]]
	columb.text += "\n\nTurns lasted:\n" + String.num(stats["turns lasted"])
	columb.text += "\nFirst actions done:\n" + String.num(stats["first actions done"])
	columb.text += "\nBonus actions done:\n" + String.num(stats["bonus actions done"])
	columb.text += "\nEnemy units removed:\n" + String.num(stats["enemy units removed"])
	columb.text += "\nUnits lost:\n" + String.num(stats["units lost"])
	columb.text += "\nUnits mobilized:\n" + String.num(stats["units mobilized"])
	columb.text += "\nmost regions owned:\n" + String.num(stats["most regions owned"])
	columb.text += "\nmost capitals owned:\n" + String.num(stats["most capitals owned"])
	columb.text += "\nregions captured:\n" + String.num(stats["regions captured"])
	columb.text += "\nregions reinforced:\n" + String.num(stats["regions reinforced"])
	columb.text += "\ncapital regions captured:\n" + String.num(stats["capital regions captured"])
	
	$columbs.add_child(columb)


func _physics_process(delta):
	if input_delay:
		input_delay = false
	elif Input.is_action_just_pressed("escape"):
		leave()
	
	var mouse_position = get_viewport().get_mouse_position()
	var move_speed = 480 * delta
	if Input.is_action_pressed("shift"):
		move_speed *= 2.0
	
	if mouse_position.x > window_size.x - 64 or Input.is_action_pressed("right"):
		$cam.position.x += move_speed
		if $cam.position.x > farthest_right:
			$cam.position.x = farthest_right
	if mouse_position.x < 64 or Input.is_action_pressed("left"):
		$cam.position.x -= move_speed
		if $cam.position.x < farthest_left:
			$cam.position.x = farthest_left


func _on_csv_pressed():
	var map_name : String = MapSetup.current_map_name.trim_suffix(".tscn")
	GameStats.save_as_csv(map_name.replace("_", " "))
	$buttons/save.text = "Saved CSV!"


func _on_replay_pressed():
	var map_name : String = MapSetup.current_map_name.trim_suffix(".tscn")
	ReplayControl.save_replay(map_name.replace("_", " "))
	$buttons/save.text = "Saved Replay!"


func leave():
	get_tree().change_scene_to_file("res://setup_scene.tscn")

