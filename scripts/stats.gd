extends Node2D


@onready var window_size : Vector2 = get_viewport_rect().size
@onready var columbs : Node2D = $columbs
@onready var graph : GameStatsGraph = $graph
@onready var graph_align_list : AlignmentList = $graph_alignments

@onready var farthest_left : float = columbs.position.x
@onready var farthest_right : float = columbs.position.x


var input_delay : bool = true

var hovering_alignments : bool = false
var hovered_player : int = 0


func _ready():
	GameControl.set_cursor(GameControl.CURSOR.NORMAL)
	
	# bad code inbound
	var pos : int = 0
	var size : int = GameStats.stats.size()
	for placement in range(size + 1):
		for stats in GameStats.stats:
			var place_text : String
			if placement == 0:
				place_text = "N/A"
			else:
				place_text = String.num(placement)
			if stats["placement"] == place_text:
				new_stats_panel(stats, pos)
				pos += 1
	
	var columb_amount : int = pos
#	print(pos)
	
	if columb_amount > 5:
		farthest_left -= (columb_amount - 5) * 192
		$buttons/expo1.visible = true
	
	if Options.use_graph:
		graph_align_list.set_align_list_size(size)
		
		var align_color : Array[Color] = []
		
		for i in range(size):
			var leader : Sprite2D = graph_align_list.add_leader(i, i)
			AlignmentList.set_leader_dp(leader, GameStats.stats[i]["controler"])
			align_color.append(GameStats.stats[i]["align color"])
			AlignmentList.color_leader(leader, align_color[i])
		
		graph.make_lines(size, align_color)
		graph.create_stat_button("regions")
		graph.create_stat_button("capitals")
		graph.create_stat_button("penalties")
		graph.update_graph_name()
		graph.update_lines()
	else:
		$buttons/graph.visible = false
		$buttons/stats.visible = false
	graph.visible = false
	graph_align_list.visible = false


func new_stats_panel(stats : Dictionary, pos : int):
	var panel : Panel = Panel.new()
	
	panel.add_theme_stylebox_override("panel", preload("res://styles/style_label_normal_box.tres"))
	panel.size = Vector2(192, 640)
	panel.modulate = stats["align color"]
	panel.position.x = 192 * pos
	
	columbs.add_child(panel)
	
	var sprite : Sprite2D = Sprite2D.new()
	
	sprite.texture = preload("res://sprites/ui/capital_highres.png")
	sprite.scale = Vector2(0.45, 0.45)
	sprite.position.x = 192 * pos + 32
	sprite.position.y = 32
	sprite.modulate = stats["align color"]
	
	columbs.add_child(sprite)
	
	var label : Label = Label.new()
	label.position.x = 192 * pos
	#label.position = Vector2(-32, -32)
	label.size = Vector2(64, 64)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = stats["placement"]
	label.self_modulate = RegionControl.text_color(stats["align color"].v)
	
	columbs.add_child(label)
	
	var columb : Label = Label.new()
	
	columb.clip_text = true
	columb.position.y += 8
	columb.size = Vector2(192, 192)
	columb.position.x = 192 * pos
	# Why did i name it like this
	var funny_spacing_value : String = "                "
	columb.text = funny_spacing_value + stats["alignment name"] + "\n" + funny_spacing_value + DPControl.CONTROLER_NAMES[stats["controler"]]
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
	
	columbs.add_child(columb)


func _physics_process(delta):
	if input_delay:
		input_delay = false
	elif Input.is_action_just_pressed("escape"):
		leave()
	
	var mouse_position = get_viewport().get_mouse_position()
	var move_speed = 480 * delta
	if Input.is_action_pressed("shift"):
		move_speed *= 2.0
	
	if columbs.visible:
		if mouse_position.x > window_size.x - 64 or Input.is_action_pressed("right"):
			columbs.position.x -= move_speed
			if columbs.position.x < farthest_left:
				columbs.position.x = farthest_left
		if mouse_position.x < 64 or Input.is_action_pressed("left"):
			columbs.position.x += move_speed
			if columbs.position.x > farthest_right:
				columbs.position.x = farthest_right
	
	if hovering_alignments:
		var recent_hovered_player : int = graph_align_list.get_leader_id_from_mouse()
		
		var new_player : bool = false
		if hovered_player != recent_hovered_player:
			hovered_player = recent_hovered_player
			new_player = true
		
		if new_player:
			graph.show_certain_line(hovered_player)


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


func _show_stats():
	columbs.visible = true
	graph.visible = false
	graph_align_list.visible = false


func _show_graph():
	columbs.visible = false
	graph.visible = true
	graph_align_list.visible = true


func _on_graph_alignments_mouse_entered():
	hovering_alignments = true


func _on_graph_alignments_mouse_exited():
	hovering_alignments = false
	graph.show_lines()
