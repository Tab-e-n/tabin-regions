extends Camera2D
class_name GameCamera


enum TOOLTIP {
	ACTIONS,
	PHASE,
	END_TURN,
	FORFEIT,
}

const PREVENT_CAMERA_MOVEMENT_START : float = 1

const ZOOM_OUT_MAX : int = -10
const ZOOM_START : int = 0
const ZOOM_IN_MAX : int = 5
const BASE_MOVE_SPEED : float = 8

const ACTIONS : Array[String] = ["FIRST ACTIONS", "MOBILIZATION", "BONUS ACTIONS"]
const PHASE_INFO : Array[String] = [
	"First Actions: Attack or defend regions!",
	"Mobilization: Grab extra units!",
	"Bonus Actions: Attack or defend regions with mobilized units!"
]


@export var ui : Control
@export var ui_hideable : Control
@export var pause_menu : Control
@export var player_info : Control
@export var player_actions : Control
@export var map_tint_list : Array[NodePath]
@export var action_change_particle : PackedScene

@export_subgroup("Buttons")
@export var advance_turn_button : BaseButton
@export var advance_action_light : Sprite2D
@export var advance_action_dark : Sprite2D
@export var advance_mobilize_light : Sprite2D
@export var advance_mobilize_dark : Sprite2D
@export var end_turn_button : BaseButton
@export var forfeit_button : BaseButton
@export var pause_button : BaseButton
@export var leave_button : BaseButton
@export var graph_button : BaseButton

@export_subgroup("Info")
@export var turn_order : AlignmentList
@export var power_sprite : TextureRect
@export var power_amount : Label
@export var current_turn : Label
@export var current_alignment : Label
@export var current_action : Label
@export var phase_info : Label
@export var replay_paused_label : Label
@export var stats_graph : GameStatsGraph

@export_subgroup("Player Info")
@export var player_info_leader : Sprite2D
@export var player_info_city : Sprite2D
@export var player_info_capital : Sprite2D
@export var player_info_regions : Label
@export var player_info_power : Label
@export var player_info_name : Label

@export_subgroup("Messages")
@export var victory_message : Control
@export var defeat_message : Control
@export var leave_message : Control
@export var forfeit_message : Control
@export var leftover_message : Control
@export var command_callout : CommandCallouts

@export_subgroup("Pause Options")
@export var mouse_scroll : BaseButton
@export var auto_phase : BaseButton
@export var fast_dp : BaseButton
@export var action_change_part : BaseButton
@export var visible_capitals : BaseButton
@export var visible_ui : BaseButton
@export var visible_turn_order : BaseButton

@export_subgroup("Tooltips")
@export var tooltip_actions : Label
@export var tooltip_phase : Label
@export var tooltip_end_turn : Label
@export var tooltip_forfeit : Label

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl
@onready var window_size : Vector2

var farthest_left : float = 0
var farthest_right : float = 0
var farthest_up : float = 0
var farthest_down : float = 0

var cam_movement_stop : float = PREVENT_CAMERA_MOVEMENT_START
var next_position : Vector2 = position

var zoom_level : int = 0

var disable_camera_movement : bool = false
var hovering_turn_order : bool = false

var hovered_player : int = -1

var shake_duration : float
var shake_time : float
var shake_amplitude : float
var shake_period : float


static func get_window_size() -> Vector2:
	var window : Vector2 = Vector2(0, 0)
	window.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	window.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	return window


func _ready():
	Options.timestamp("GameCamera")
	
	z_index = 100
	window_size = GameCamera.get_window_size()
	
	game_control.game_camera = self
	game_control.command_callout = command_callout
	
	zoom_level = ZOOM_START
	zoom_change(0)
	
	if player_info:
		player_info.visible = false
		if player_info_leader:
			var leader : Sprite2D = AlignmentList.make_leader(0)
			leader.position = player_info_leader.position
			leader.scale = player_info_leader.scale
			player_info_leader.queue_free()
			player_info.add_child(leader)
			player_info_leader = leader
	if pause_menu:
		pause_menu.visible = false
	if victory_message:
		victory_message.visible = false
	if defeat_message:
		defeat_message.visible = false
	if leave_message:
		leave_message.visible = false
	if forfeit_message:
		forfeit_message.visible = false
	if stats_graph:
		stats_graph.visible = false
	
	if advance_turn_button:
		advance_turn_button.pressed.connect(try_advance_turn)
		advance_turn_button.mouse_entered.connect(show_tooltip.bind(TOOLTIP.PHASE))
		advance_turn_button.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.PHASE))
	if end_turn_button:
		end_turn_button.pressed.connect(try_end_turn)
		end_turn_button.mouse_entered.connect(show_tooltip.bind(TOOLTIP.END_TURN))
		end_turn_button.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.END_TURN))
	if forfeit_button:
		forfeit_button.pressed.connect(try_forfeit)
		forfeit_button.mouse_entered.connect(show_tooltip.bind(TOOLTIP.FORFEIT))
		forfeit_button.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.FORFEIT))
	if power_amount:
		power_amount.mouse_entered.connect(show_tooltip.bind(TOOLTIP.ACTIONS))
		power_amount.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.ACTIONS))
	if turn_order:
		turn_order.mouse_entered.connect(_on_turn_order_hovered)
		turn_order.mouse_exited.connect(_on_turn_order_left)
	if pause_button:
		pause_button.pressed.connect(toggle_pause_menu)
	if graph_button:
		if Options.use_graph:
			graph_button.pressed.connect(toggle_graph)
			stats_graph.update_graph_name()
		else:
			graph_button.visible = false
	if leave_button:
		leave_button.pressed.connect(try_leaving)
	
	if mouse_scroll:
		mouse_scroll.button_pressed = Options.mouse_scroll_active
	if auto_phase:
		auto_phase.button_pressed = Options.auto_end_turn_phases
	if fast_dp:
		fast_dp.button_pressed = Options.dp_speedrun
	if action_change_part:
		action_change_part.button_pressed = Options.action_change_particles
	if visible_ui and ui_hideable:
		visible_ui.button_pressed = ui_hideable.visible
	if visible_turn_order and turn_order:
		visible_turn_order.button_pressed = turn_order.visible
	
	_deferred_ready.call_deferred()
	Options.timestamp("GameCamera ready", "GameCamera")


func _deferred_ready():
	Options.timestamp("GameCamera deferred")
	
	region_control = game_control.region_control as RegionControl
	
	for i in region_control.polygon:
		if i.x > farthest_right:
			farthest_right = i.x
		if i.x < farthest_left:
			farthest_left = i.x
		if i.y > farthest_down:
			farthest_down = i.y
		if i.y < farthest_up:
			farthest_up = i.y
	
	if farthest_right < window_size.x * 0.5:
		farthest_right = window_size.x * 0.5
	if farthest_left > -window_size.x * 0.5:
		farthest_left = -window_size.x * 0.5
	if farthest_down < window_size.y * 0.5:
		farthest_down = window_size.y * 0.5
	if farthest_up > -window_size.y * 0.5:
		farthest_up = -window_size.y * 0.5
	
	farthest_right += region_control.offset.x
	farthest_left += region_control.offset.x
	farthest_down += region_control.offset.y
	farthest_up += region_control.offset.y
	
#	print(farthest_right, " ",farthest_left, " ",farthest_down, " ",farthest_up,)
	
	if position.x > farthest_right:
		position.x = farthest_right
	if position.x < farthest_left:
		position.x = farthest_left
	if position.y > farthest_down:
		position.y = farthest_down
	if position.y < farthest_up:
		position.y = farthest_up
	next_position = position
	
	if visible_capitals and region_control:
		visible_capitals.button_pressed = region_control.cities_visible
	
	update_alignment_colored_ui()
	update_current_action(region_control.current_phase)
	
	for path in map_tint_list:
		get_node(path).self_modulate = region_control.color
	
	command_callout.default_color = region_control.command_callout_color
	
	_connect_region_control_signals()
	
	update_current_turn()
	update_alignment_label()
	
	if turn_order:
		turn_order.ready_list(region_control)
		turn_order.select_leader(region_control.current_playing_align)
	
	if Options.use_graph and stats_graph:
		stats_graph.make_lines(region_control.align_amount, region_control.align_color)
		stats_graph.create_stat_button("regions")
		stats_graph.create_stat_button("capitals")
		if region_control.apply_penalties:
			stats_graph.create_stat_button("penalties")
		stats_graph.tint_bg(region_control.color)
	
	Options.timestamp("GameCamera deferred ready", "GameCamera")


func _connect_region_control_signals():
	if region_control:
		region_control.turn_ended.connect(_on_turn_ended)
		region_control.turn_phase_changed.connect(_on_turn_phase_changed)
		region_control.actions_modified.connect(_on_actions_modified)


func _disconnect_region_control_signals():
	if region_control:
		region_control.turn_ended.disconnect(_on_turn_ended)
		region_control.turn_phase_changed.disconnect(_on_turn_phase_changed)
		region_control.actions_modified.disconnect(_on_actions_modified)


func _process(delta):
	if disable_camera_movement or hovering_turn_order:
		cam_movement_stop = 1
	
	if hovering_turn_order:
		update_player_info()
	
	if replay_paused_label and ReplayControl.replay_active:
		replay_paused_label.visible = ReplayControl.paused
	
	var shake_offset : Vector2 = Vector2(0.0, 0.0)
	
	if shake_time > 0.0:
		shake_time -= delta
		shake_offset = _camera_shake_offset()
		if shake_time <= 0.0:
			reset_camera_shake()
	
	position = next_position + shake_offset
	force_update_scroll()


func _camera_shake_offset() -> Vector2:
		var shake_offset : Vector2 = Vector2(0, 0)
		var damp : float = shake_time / shake_duration
		shake_offset.x = shake_amplitude * (abs(shake_period - wrap(shake_time, 0.0, shake_period * 0.15) * 13.3) - 0.5) * damp
		shake_offset.y = shake_amplitude * abs(shake_period - wrap(shake_time, 0.0, shake_period * 0.4) * 5.0) * damp
		return shake_offset


func set_ui_shader_parameter(Element : CanvasItem, param : String, value : Variant) -> void:
	if not Element:
		return
	if Element.material:
		Element.material.set_shader_parameter(param, value)
	else:
		push_warning(Element, " doesn't have a shader material")


func move_camera(delta : float, direction : Vector2, shift : bool, ctrl : bool):
	var move_speed = BASE_MOVE_SPEED
	if ui:
		move_speed *= ui.scale.x
	if shift:
		move_speed *= 2.0
	if ctrl:
		move_speed *= 0.3
	next_position += direction * Vector2(move_speed, move_speed) * 60 * delta
	
	snapped(next_position, Vector2(1.0, 1.0))
	if next_position.x > farthest_right:
		next_position.x = farthest_right
	if next_position.x < farthest_left:
		next_position.x = farthest_left
	if next_position.y < farthest_up:
		next_position.y = farthest_up
	if next_position.y > farthest_down:
		next_position.y = farthest_down


func center_camera(pos : Vector2):
	next_position = pos


func zoom_change(amount : int):
	zoom_level += amount
	if zoom_level < ZOOM_OUT_MAX:
		zoom_level = ZOOM_OUT_MAX
	if zoom_level > ZOOM_IN_MAX:
		zoom_level = ZOOM_IN_MAX
	zoom.x = pow(1.25, zoom_level)
	zoom.y = zoom.x
	if ui:
		ui.scale.x = 1 / zoom.x
		ui.scale.y = ui.scale.x


func reset_zoom():
	zoom_level = ZOOM_START
	zoom_change(0)


func reset_camera_shake() -> void:
	shake_time = 0.0
	shake_duration = 0.0
	shake_amplitude = 0.0
	shake_period = 0.0


func shake_camera(duration : float, amplitude : float, period : float) -> void:
	shake_duration += duration
	shake_time += duration
	shake_amplitude += amplitude
	shake_period = max(period, shake_period)


func try_leaving():
	set_pause_menu_visible(false)
	set_leave_message(true)


func try_advance_turn():
	if region_control.current_phase == RegionControl.PHASE.BONUS and region_control.get_action_amount() > 0:
		set_leftover_message(true)
	else:
		region_control.change_current_phase()


func try_end_turn():
	if region_control.get_action_amount() > 0:
		set_leftover_message(true)
	else:
		region_control.end_turn(true)


func try_forfeit():
	set_forfeit_message(true)


func make_action_changed_particle(amount : int, color : Color) -> void:
	if not Options.action_change_particles:
		return
	if ui_hideable and not ui_hideable.visible:
		return
	
	var part = action_change_particle.instantiate()
	part.text = str(amount)
	if amount > 0:
		part.text = "+" + part.text
	part.position = Vector2(-448, 208)
	part.color = color
	
	ui.add_child(part)


func toggle_ui_visible():
	set_ui_visible(not ui_hideable.visible)


func set_ui_visible(visibility : bool):
	if ui_hideable:
		ui_hideable.visible = visibility
		if visible_ui:
			visible_ui.set_pressed_no_signal(visibility)


func toggle_turn_order_visible():
	if turn_order:
		set_turn_order_visible(not turn_order.visible)


func set_turn_order_visible(visibility : bool):
	if turn_order:
		turn_order.visible = visibility
		if visible_turn_order:
			visible_turn_order.set_pressed_no_signal(turn_order.visible)


func set_player_info_visible(visibility : bool):
	if player_info:
		player_info.visible = visibility


func update_player_info() -> void:
	if not turn_order or not player_info:
		return
	
	var recent_hovered_player : int = turn_order.get_leader_id_from_mouse()
	
	var new_player : bool = false
	if hovered_player != recent_hovered_player:
		hovered_player = recent_hovered_player
		new_player = true
	
	var player_alignment : int = region_control.get_alignment_from_play_order(hovered_player)
	var leader : Sprite2D = turn_order.get_leader(player_alignment) as Sprite2D
	if leader and leader.visible:
		var color : Color = leader.self_modulate
		if new_player:
			AlignmentList.color_leader(player_info_leader, color)
			AlignmentList.set_leader_dp(player_info_leader, leader.frame)
			player_info.self_modulate = color
			player_info_city.self_modulate = color
			player_info_capital.self_modulate = color
			player_info_regions.self_modulate = RegionControl.text_color(color.v)
			player_info_power.self_modulate = RegionControl.text_color(color.v)
			player_info_name.text = region_control.get_alignment_name(player_alignment)
			if stats_graph:
				stats_graph.show_certain_line(player_alignment)
		
		player_info_regions.text = String.num(region_control.get_alignment_regions(player_alignment))
		player_info_power.text = String.num(region_control.get_alignment_capitals(player_alignment))
		AlignmentList.leader_sweat(player_info_leader, region_control.get_alignment_capitals(player_alignment) <= 0)
		
		if region_control.get_alignment_penalties(player_alignment) > 0:
			player_info_power.text += "\n-" + String.num(region_control.get_alignment_penalties(player_alignment))
		if not stats_graph or not stats_graph.visible:
			set_player_info_visible(true)
	else:
		set_player_info_visible(false)
		if stats_graph:
			stats_graph.show_lines()


func update_alignment_colored_ui():
	if player_actions:
		player_actions.modulate = region_control.get_current_alignment_color()
		player_actions.modulate.a = 1
		player_actions.visible = region_control.is_player_controled and not ReplayControl.replay_active
		var value : float = player_actions.modulate.v
		set_ui_shader_parameter(advance_action_light, "value", value)
		set_ui_shader_parameter(advance_action_dark, "value", value)
		set_ui_shader_parameter(advance_mobilize_light, "value", value)
		set_ui_shader_parameter(advance_mobilize_dark, "value", value)
		set_ui_shader_parameter(end_turn_button, "value", value)
		set_ui_shader_parameter(forfeit_button, "value", value)
		if current_action:
			if region_control.is_player_controled:
				current_action.self_modulate = RegionControl.text_color(value)
			else:
				current_action.self_modulate = Color.WHITE
	if power_sprite:
		power_sprite.self_modulate = region_control.get_current_alignment_color()
		power_sprite.self_modulate.a = 1
		if power_amount:
			power_amount.self_modulate = RegionControl.text_color(power_sprite.self_modulate.v)


func update_alignment_label():
	if current_alignment:
		current_alignment.text = region_control.get_current_alignment_name()


func update_current_turn():
	if current_turn:
		current_turn.text = "Turn " + str(region_control.current_turn)


func advance_turn_visual(type : int):
	if advance_action_light:
		advance_action_light.visible = type == 0
	
	if advance_action_dark:
		advance_action_dark.visible = type == 1
	
	if advance_mobilize_light:
		advance_mobilize_light.visible = type == 2
	
	if advance_mobilize_dark:
		advance_mobilize_dark.visible = type == 3


func update_current_action(current_phase : int):
	if current_action:
		current_action.text = ACTIONS[current_phase]
	if current_phase == RegionControl.PHASE.MOBILIZE:
		advance_turn_visual(2)
	elif current_phase == RegionControl.PHASE.BONUS and region_control.bonus_action_amount == 0:
		advance_turn_visual(1)
	else:
		advance_turn_visual(0)
	if phase_info:
		phase_info.text = PHASE_INFO[current_phase]


func show_victory_message(alignment : int):
	if victory_message:
		victory_message.visible = true
		victory_message.modulate = region_control.align_color[alignment]


func show_defeat_message(alignment : int):
	if defeat_message:
		defeat_message.visible = true
		defeat_message.modulate = region_control.align_color[alignment]


func set_leave_message(visibility : bool):
	if leave_message:
		leave_message.visible = visibility


func set_forfeit_message(visibility : bool):
	if forfeit_message:
		forfeit_message.visible = visibility


func set_leftover_message(visibility : bool):
	if leftover_message:
		leftover_message.visible = visibility


func toggle_pause_menu():
	if pause_menu:
		set_pause_menu_visible(not pause_menu.visible)
	set_graph_visible(false)
	set_leave_message(false)


func set_pause_menu_visible(visibility : bool):
	if pause_menu:
		pause_menu.visible = visibility
		if game_control:
			game_control.inputs_active = not visibility


func show_tooltip(tooltip : TOOLTIP):
	tooltip_actions.visible = tooltip == TOOLTIP.ACTIONS
	tooltip_phase.visible = tooltip == TOOLTIP.PHASE
	tooltip_end_turn.visible = tooltip == TOOLTIP.END_TURN
	tooltip_forfeit.visible = tooltip == TOOLTIP.FORFEIT
	disable_camera_movement = true


func hide_tooltip(tooltip : TOOLTIP):
	match tooltip:
		TOOLTIP.ACTIONS:
			tooltip_actions.visible = false
		TOOLTIP.PHASE:
			tooltip_phase.visible = false
		TOOLTIP.END_TURN:
			tooltip_end_turn.visible = false
		TOOLTIP.FORFEIT:
			tooltip_forfeit.visible = false
	disable_camera_movement = false


func hide_all_tooltips():
	tooltip_actions.visible = false
	tooltip_phase.visible = false
	tooltip_end_turn.visible = false
	tooltip_forfeit.visible = false
	disable_camera_movement = false


func toggle_graph():
	if stats_graph:
		set_graph_visible(not stats_graph.visible)
	set_pause_menu_visible(false)
	set_leave_message(false)


func set_graph_visible(visibility : bool) -> void:
	if stats_graph:
		if visibility:
			stats_graph.show_graph()
		else:
			stats_graph.hide_graph()


func update_graph():
	if stats_graph:
		stats_graph.update_lines()


func _on_turn_ended():
	update_alignment_colored_ui()
	
	if turn_order:
		turn_order.update_list(region_control)
		turn_order.select_leader(region_control.current_playing_align)
	
	if not region_control.is_player_controled:
		disable_camera_movement = false
	
	update_current_turn()
	update_current_action(region_control.current_phase)
	
	update_alignment_label()
	
	hide_all_tooltips()


func _on_turn_phase_changed(current_phase : int):
	update_current_action(current_phase)


func _on_actions_modified(amount : int) -> void:
	if power_amount:
		power_amount.text = String.num(region_control.get_action_amount())
	if amount != 0:
		make_action_changed_particle(amount, region_control.get_current_alignment_color())
	if region_control.get_action_amount() == 0:
		advance_turn_visual(1)


func _on_turn_order_hovered():
	hovering_turn_order = true
	if not stats_graph or not stats_graph.visible:
		set_player_info_visible(true)
	if stats_graph and region_control:
		var player_alignment : int = region_control.get_alignment_from_play_order(hovered_player)
		stats_graph.show_certain_line(player_alignment)


func _on_turn_order_left():
	hovering_turn_order = false
	set_player_info_visible(false)
	if stats_graph:
		stats_graph.show_lines()


func _on_leave_confirmed():
	game_control.leave()


func _on_leave_canceled():
	set_leave_message(false)


func _on_leftover_confirmed():
	set_leftover_message(false)
	region_control.end_turn(true)


func _on_leftover_canceled():
	set_leftover_message(false)


func _on_forfeit_confirmed():
	set_forfeit_message(false)
	region_control.forfeit()


func _on_forfeit_canceled():
	set_forfeit_message(false)
