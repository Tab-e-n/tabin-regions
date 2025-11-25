extends Panel
class_name AlignmentList


const PLAY_ORDER_SPACING : float = 48
const PLAY_ORDER_SPACING_DIV : float = 1 / PLAY_ORDER_SPACING
const PLAY_ORDER_VERTICAL_OFFSET : float = 44

@onready var max_size : float = size.x

var selector : Sprite2D = null

var count : int = 0


static func make_leader(alignment : int) -> Sprite2D:
	var leader : Sprite2D = Sprite2D.new()
	leader.name = String.num(alignment)
	leader.texture = preload("res://sprites/dp/turn_order_players.png")
	leader.hframes = DPControl.CONTROLER.SIZE
	leader.z_index = 1
	var new_sweat : Sprite2D = Sprite2D.new()
	new_sweat.texture = preload("res://sprites/dp/leader_sweat.png")
	new_sweat.position = Vector2(-16, -16)
	new_sweat.name = "sweat"
	new_sweat.visible = false
	leader.add_child(new_sweat)
	return leader


static func add_aliance_to_leader(leader : Sprite2D, aliance : int):
	if not leader:
		return
	var label : Label = Label.new()
	label.name = leader.name + "_txt"
	label.size = Vector2(PLAY_ORDER_SPACING, 48)
	label.clip_text = true
	label.text = String.num_int64(aliance)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position.x = -PLAY_ORDER_SPACING * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leader.add_child(label)


static func change_leaders_aliance(leader : Sprite2D, aliance : int):
	if not leader:
		return
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		label.text = String.num_int64(aliance)


static func remove_aliance_from_leader(leader : Sprite2D):
	if not leader:
		return
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		leader.remove_child(label)
		label.queue_free()


static func set_leader_dp(leader : Sprite2D, dp : int) -> void:
	if not leader:
		return
	leader.frame = dp


static func color_leader(leader : Sprite2D, color : Color):
	if not leader:
		return
	leader.self_modulate = color
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		if color.v > RegionControl.COLOR_TOO_BRIGHT:
			label.self_modulate = Color(0, 0, 0)
		else:
			label.self_modulate = Color(1, 1, 1)


static func leader_sweat(leader : Sprite2D, sweating : bool):
	if not leader:
		return
	leader.get_node("sweat").visible = sweating


func _get_leader_id(local_pos : float) -> int:
	var alignment : int = int(local_pos * PLAY_ORDER_SPACING_DIV)
	if alignment >= count:
		alignment = count - 1
	if alignment < 0:
		alignment = 0
	return alignment


func get_leader_id_from_mouse() -> int:
	return _get_leader_id(get_local_mouse_position().x)


func get_leader_id_from_position(pos : Vector2) -> int:
	return _get_leader_id((pos.x - global_position.x) / scale.x)


func add_leader(pos : int, alignment : int) -> Sprite2D:
	var leader : Sprite2D = AlignmentList.make_leader(alignment)
	leader.position.x = PLAY_ORDER_SPACING * 0.5 + PLAY_ORDER_SPACING * pos
	leader.position.y = PLAY_ORDER_VERTICAL_OFFSET
	add_child(leader)
	return leader


func random_leader_indicators(amount : int):
	for i in range(amount):
		var leader : Sprite2D = Sprite2D.new()
		leader.texture = preload("res://sprites/dp/align_picker_random.png")
		leader.position.x = PLAY_ORDER_SPACING * 0.5 + PLAY_ORDER_SPACING * i
		leader.position.y = PLAY_ORDER_VERTICAL_OFFSET
		leader.z_index = 0
		add_child(leader)


func get_leader(alignment : int) -> Sprite2D:
	return get_node_or_null(String.num(alignment))


func remove_leader(alignment : int):
	var leader : Sprite2D = get_leader(alignment)
	if leader:
		remove_child(leader)
		leader.queue_free()


func select_leader(alignment : int):
	if not selector:
		selector = Sprite2D.new()
		selector.texture = preload("res://sprites/dp/leader_outline.png")
		selector.z_index = 0
		add_child(selector)
	selector.position = get_leader(alignment).position


func valid_leader(alignment : int) -> bool:
	return alignment >= 0 and alignment < count


func set_align_list_size(i : int):
	count = i
	size.x = PLAY_ORDER_SPACING * i
#	print(size)
	if size.x > max_size:
		scale.x = max_size / size.x
		scale.y = scale.x


func ready_list(region_control : RegionControl):
	var play_order : Array = region_control.align_play_order.duplicate()
	set_align_list_size(play_order.size())
	
	for i in range(play_order.size()):
		var leader : Sprite2D = add_leader(i, play_order[i])
		leader.frame = region_control.align_controlers[play_order[i] - 1]
		if region_control.use_aliances:
			AlignmentList.add_aliance_to_leader(leader, region_control.alignment_aliances[play_order[i]])
		AlignmentList.color_leader(leader, region_control.align_color[play_order[i]])


func clear_list():
	for i in get_children():
		remove_child(i)
		i.queue_free()


func update_list(region_control : RegionControl):
	var play_order : Array = region_control.align_play_order.duplicate()
	for i in range(region_control.align_play_order.size()):
		var alignment : int = play_order[i]
		var leader = get_node(String.num(alignment))
		leader.visible = region_control.region_amount[alignment - 1]
		if not leader.visible:
			continue
		
		AlignmentList.change_leaders_aliance(leader, region_control.alignment_aliances[alignment])
		
		if region_control.get_alignment_capitals(alignment) > 0:
			AlignmentList.leader_sweat(leader, false)
		else:
			AlignmentList.leader_sweat(leader, true)
