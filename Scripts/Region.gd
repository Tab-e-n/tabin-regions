@tool
extends Polygon2D
## Region is a class that represents a single region. Requires being a child node of a RegionControl to function.
class_name Region


const TEXTURE_SIZE : Vector2 = Vector2(128, 128)
const DISTANCE_CAP : int = 0b1111_1111_1111_1111
const COLOR_CHANGE_SPEED : float = 2.4


enum RENDER_MODE {DISABLED, ALIGNMENT, POWER, MAX_POWER, CAPITAL, POSITION}


signal captured()
signal changed_alignment(alignment : int)
signal reinforced(amount : int)
signal mobilized()


## Which alignment owns the region.
@export var alignment : int = 0
## Current power of the region.
@export var power : int = 1
## The maximum power of the region. When reinforcing the region, region will not gain more power than the max power.
@export var max_power : int = 5
## Whether the region is a capital or not. Capitals give players extra actions.
@export var is_capital : bool = false

@export_subgroup("Cosmetic")
## Setting kinetic to true makes region arrows constantly update themselfs.
@export var kinetic : bool = false

@export_subgroup("Editor")
@export var connections : Array[RegionConnection] = []


@onready var region_control : RegionControl = get_parent() as RegionControl

@onready var city : City


var tool_render_mode : int = RENDER_MODE.ALIGNMENT
var distance_from_capital : int = DISTANCE_CAP

var color_change_time : float = 1.0


func _ready():
	texture = preload("res://Sprites/region.png")
	material = ShaderMaterial.new()
	material.shader = preload("res://Scripts/region_shader.gdshader")
	
	if polygon.size() > 0:
		var far_left : float = polygon[0].x
		var far_right : float = polygon[0].x
		var far_up : float = polygon[0].y
		var far_down : float = polygon[0].y
		
		for i in polygon:
			if i.x < far_left:
				far_left = i.x
			if i.x > far_right:
				far_right = i.x
			if i.y < far_up:
				far_up = i.y
			if i.y > far_down:
				far_down = i.y
		
		var width : float = abs(far_right - far_left)
		var height : float = abs(far_down - far_up)
		if width == 0.0:
			width = 1.0
		if height == 0.0:
			height = 1.0
		
		var temp_uv : PackedVector2Array = polygon.duplicate()
		
		for i in range(temp_uv.size()):
			temp_uv[i].x = TEXTURE_SIZE.x * ((polygon[i].x - far_left) / width)
			temp_uv[i].y = TEXTURE_SIZE.y * ((polygon[i].y - far_up) / height)
#			print(temp_uv[i])
		
		set_uv(temp_uv)
		
#		print(polygon, " ", uv)
	
	
	if Engine.is_editor_hint():
		return
	
	call_deferred("_ready_deferred")


func _ready_deferred():
	city = City.new()
	city.is_capital = is_capital
	add_child(city)
	if !region_control.dummy:
		city.pressed.connect(_on_capital_pressed)
		city.mouse_entered.connect(show_region_connections)
		
	color_self(false)


func _process(delta):
	if Engine.is_editor_hint() and region_control:
		tool_render_mode = region_control.render_mode
		match(tool_render_mode):
			RENDER_MODE.DISABLED:
				color = Color(1, 1, 1, 1)
			RENDER_MODE.ALIGNMENT:
				color = region_control.align_color[alignment]
			RENDER_MODE.POWER:
				power_color(power, false)
			RENDER_MODE.MAX_POWER:
				power_color(max_power, true)
			RENDER_MODE.CAPITAL:
				if is_capital:
					color = Color(0.9, 1, 0.9, 1)
				else:
					color = Color(0.3, 0.1, 0.1, 1)
			RENDER_MODE.POSITION:
				var pos_range : float = region_control.render_range * 40
				var col1 : float = 1.0 - clampf(abs(position.x) / pos_range, 0, 1)
				var col2 : float = 1.0 - clampf(abs(position.y) / pos_range, 0, 1)
				
				color = Color(col1, col2, 0.5, 1)
	if not Engine.is_editor_hint():
		if color_change_time < 1.0:
			color_change_time += delta * COLOR_CHANGE_SPEED
			if color_change_time < 1.0:
				material.set_shader_parameter("n", color_change_time)
			else:
				material.set_shader_parameter("changing_color", false)


func reinforce(reinforce_align : int = alignment, addon_power : int = 1):
	if power >= max_power:
		return false
	power += addon_power
	GameStats.add_to_stat(reinforce_align, "regions reinforced", 1)
#	GameStats.stats[reinforce_align]["regions reinforced"] += 1
	reinforced.emit(addon_power)
	return true


func mobilize(mobilize_align : int = alignment, mobilize_amount : int = 1):
	if power <= 1:
		return 0
	GameStats.add_to_stat(mobilize_align, "units mobilized", mobilize_amount)
#	GameStats.stats[mobilize_align]["units mobilized"] += 1
	power -= mobilize_amount
	region_control.bonus_action_amount += mobilize_amount
	mobilized.emit()
	return mobilize_amount


func incoming_attack(attack_align : int, attack_power : int = 0, test_only : bool = false):
	attack_power += get_alignments_attack_power(attack_align)
	if incoming_attack_captures(attack_power):
		if test_only:
			return true
		GameStats.add_to_stat(attack_align, "enemy units removed", power)
		GameStats.add_to_stat(alignment, "units lost", power)
#		GameStats.stats[attack_align]["enemy units removed"] += power
#		GameStats.stats[alignment]["units lost"] += power
		power = 1
		change_alignment(attack_align)
		GameStats.add_to_stat(attack_align, "regions captured", 1)
#		GameStats.stats[alignment]["regions captured"] += 1
		if is_capital:
			GameStats.add_to_stat(attack_align, "capital regions captured", 1)
#			GameStats.stats[alignment]["capital regions captured"] += 1
		captured.emit()
		return true
	else:
		return false


func change_alignment(align : int, recolor_self : bool = true):
	region_control.change_region_amount(-1, alignment, is_capital)
	alignment = align
	if recolor_self:
		color_self()
	region_control.change_region_amount(1, alignment, is_capital)
	changed_alignment.emit(alignment)


func overtake():
	city_particle(false)
	if region_control.alignment_friendly(region_control.current_playing_align, alignment):
		reinforce(region_control.current_playing_align)
	else:
		incoming_attack(region_control.current_playing_align, max_power + 1)


func set_max_power(new_max : int, reduce_power : bool = true):
	max_power = new_max
	if reduce_power and power > max_power:
		power = max_power
	city.update_region_name()


func action_decided():
	if region_control.current_action != region_control.ACTION_MOBILIZE:
		if region_control.has_enough_actions():
			if region_control.alignment_friendly(region_control.current_playing_align, alignment):
				if reinforce(region_control.current_playing_align):
					region_control.action_done(name)
					city_particle(false)
					return
			elif alignment_can_attack(region_control.current_playing_align):
				if incoming_attack(region_control.current_playing_align):
					region_control.action_done(name)
					city_particle(false)
					return
		region_control.cross(position)
	else:
		if region_control.current_playing_align == alignment:
			var amount_requested = 1
			if Input.is_action_pressed("shift") and region_control.is_player_controled:
				amount_requested = power - 1
			var amount_gotten = mobilize(alignment, amount_requested)
			if amount_gotten:
				region_control.action_done(name, amount_gotten)
				city_particle(true)
				return
		region_control.cross(position)


func alignment_can_attack(attack_align : int) -> bool:
	for connection in connections:
		var region : Region = connection.get_other_region(self)
		if region and region.alignment == attack_align:
			return true
	return false


func connection_attack_power(connection : RegionConnection) -> int:
	return max(connection.get_other_region(self).power - connection.power_reduction, 0)


func get_adjacent_attack_power() -> Array[int]:
	var attacks : Array[int] = []
	attacks.resize(region_control.align_amount)
	
	for connection in connections:
		var target : Node = connection.get_other_region(self)
		if target and region_control.alignment_active(target.alignment):
			attacks[target.alignment] += connection_attack_power(connection)
	
	return attacks


func strongest_enemy_attack(align : int = alignment) -> int:
	var attacks : Array[int] = get_adjacent_attack_power()
	var strongest : int = 0
	for i in range(attacks.size()):
		if i == align:
			continue
		if attacks[i] > strongest:
			strongest = attacks[i]
	return strongest


func incoming_attack_captures(attack_power : int) -> bool:
	return attack_power > power


func get_alignments_attack_power(align : int) -> int:
	var attack_power : int = 0
	for connection in connections:
		var region : Region = connection.get_other_region(self)
		if region and region.alignment == align:
			attack_power += connection_attack_power(connection)
	return attack_power


func attack_power_difference(attack_align : int) -> int:
	return power - get_alignments_attack_power(attack_align)


func color_self(animate : bool = true):
	if(animate):
		material.set_shader_parameter("changing_color", true)
		material.set_shader_parameter("n", 0)
		material.set_shader_parameter("previous_color", color)
		color_change_time = 0.0
	color = region_control.align_color[alignment]
	city.color_self(region_control.align_color[alignment])
	for connection in connections:
		connection.update_gradient()


func city_particle(is_mobilized : bool):
	city.call_deferred("make_particle", is_mobilized)


func show_region_connections():
	for i in range(connections.size()):
		var connection : RegionConnection = connections[i]
		connection.num = i
		connection.show_self(self)


func _on_capital_pressed():
	if region_control.is_player_controled and !region_control.dummy:
		action_decided()


func power_color(amount : int, no_zero : bool):
	if amount == 0 and no_zero:
		color = Color("703d5d")
		return
	var c : float = 1.0 - clampf(amount, 0, region_control.render_range) / region_control.render_range
	color = Color(c, c, c, 1)

