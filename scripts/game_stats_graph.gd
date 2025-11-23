extends Control
class_name GameStatsGraph


const DEFAULT_SPACING : float = 32
const MINIMUM_DOT_SPACING : float = 12


@export var lines_node : Node2D = null
@export var current_stat : String = "regions"


@onready var graph_size : Vector2 = $limit.size
@onready var graph_name : Label = $name
@onready var dots : Line2D = $dots
@onready var buttons : HBoxContainer = $buttons
@onready var value_indicator : Node2D = $value


var lines : Array = []


func make_lines(amount : int, colors : Array) -> void:
	for i in range(amount):
		var line : Line2D = Line2D.new()
		line.width = 2
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.default_color = colors[i]
		lines_node.add_child(line)
		lines.append(line)


func update_lines(stat : String = current_stat) -> void:
#	print(get_stack())
	current_stat = stat
	if not visible:
		return
	if not GameStats.DEFAULT_STATS.has(stat):
		return
	if GameStats.graph.size() <= 0:
		return
	
	var max_value : float = GameStats.graph_statistics[stat]
	if max_value == 0:
		push_warning("Default max value of 0 defined for GameStatsGraph stat.")
		max_value = 1
	$max.text = str(max_value) + " "
	
	var spacing : Vector2 = Vector2(DEFAULT_SPACING, 0)
	var record_amount : int = GameStats.graph[0].size() - 1
	
	if record_amount == 0:
		record_amount = 1
	if record_amount * DEFAULT_SPACING >= graph_size.x:
		spacing.x = graph_size.x / record_amount
	spacing.y = graph_size.y / max_value
	
#	print(GameStats.graph)
	for line_id in range(lines.size()):
		var line : Line2D = lines[line_id]
		line.clear_points()
		var pos : int = 0
#		print(GameStats.graph[line_id])
		for record in GameStats.graph[line_id]:
#			print(record)
#			print(record[stat])
			var value : int = record[stat]
			var point : Vector2 = Vector2(pos, -value) * spacing
			line.add_point(point)
#			print(pos, " ", point)
			pos += 1
	
	var dot_spacing : Vector2 = spacing
	dot_spacing.x = _limit_dot_spacing(dot_spacing.x)
	dot_spacing.y = _limit_dot_spacing(dot_spacing.y)
	
	dots.clear_points()
	var j : int = 0
	while j * dot_spacing.y < graph_size.y:
		dots.add_point(Vector2(0, -j * dot_spacing.y))
		j += 1
	dots.add_point(Vector2(0, -graph_size.y))
	j = 1
	while j * dot_spacing.x < graph_size.x:
		dots.add_point(Vector2(j * dot_spacing.x, 0))
		j += 1
	dots.add_point(Vector2(graph_size.x, 0))


func _limit_dot_spacing(spacing : float) -> float:
	if spacing < MINIMUM_DOT_SPACING:
		spacing *= floor(MINIMUM_DOT_SPACING / spacing)
	return spacing


func show_certain_line(line_id : int) -> void:
	for i in range(lines.size()):
		var line : Line2D = lines[i]
		if i == line_id:
			line.visible = true
			value_indicator.default_color = RegionControl.slight_tint(line.default_color) * 0.5
			$value/bg.self_modulate = value_indicator.default_color
			if line.get_point_count() > 0:
				value_indicator.position.y = lines_node.position.y + line.get_point_position(line.get_point_count() - 1).y
			var records : Array = GameStats.graph[line_id]
			if records:
				var record = records[records.size() - 1]
				if record:
					$value/label.text = str(record[current_stat]) + " "
		else:
			line.visible = false
	value_indicator.visible = true


func show_lines() -> void:
	for i in range(lines.size()):
		lines[i].visible = true
	value_indicator.visible = false


func hide_graph():
	visible = false


func show_graph():
	visible = true
	update_lines()


func update_graph_name(new_name : String = current_stat):
	graph_name.text = new_name.to_upper()


func create_stat_button(stat : String) -> Button:
	var button : Button = Button.new()
	button.text = "  " + stat.to_upper() + "  "
	button.add_theme_font_size_override("font_size", 48)
	button.pressed.connect(_on_stat_button_pressed.bind(stat))
	button.focus_mode = Control.FOCUS_NONE
	buttons.add_child(button)
	return button


func _on_stat_button_pressed(stat : String) -> void:
	update_lines(stat)
	update_graph_name(stat)


func tint_bg(color : Color) -> void:
	$bg.self_modulate = color
