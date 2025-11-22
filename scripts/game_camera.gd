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


@export var UI : Control
@export var UIHideable : Control
@export var PauseMenu : Control
@export var PlayerInfo : Control
@export var PlayerActions : Control
@export var MapTintList : Array[NodePath]
@export var ActionChangeParticle : PackedScene

@export_subgroup("Buttons")
@export var AdvanceTurnButton : BaseButton
@export var AdvanceActionLight : Sprite2D
@export var AdvanceActionDark : Sprite2D
@export var AdvanceMobilizeLight : Sprite2D
@export var AdvanceMobilizeDark : Sprite2D
@export var EndTurnButton : BaseButton
@export var ForfeitButton : BaseButton
@export var PauseButton : BaseButton
@export var LeaveButton : BaseButton

@export_subgroup("Info")
@export var TurnOrder : AlignmentList
@export var PowerSprite : TextureRect
@export var PowerAmount : Label
@export var CurrentTurn : Label
@export var CurrentAlignment : Label
@export var CurrentAction : Label
@export var PhaseInfo : Label
@export var ReplayPausedLabel : Label

@export_subgroup("Player Info")
@export var PILeader : Sprite2D
@export var PICity : Sprite2D
@export var PICapital : Sprite2D
@export var PIRegions : Label
@export var PIPower : Label
@export var PIName : Label

@export_subgroup("Messages")
@export var VictoryMessage : Control
@export var DefeatMessage : Control
@export var LeaveMessage : Control
@export var ForfeitMessage : Control
@export var LeftoverMessage : Control
@export var CommandCallout : CommandCallouts

@export_subgroup("Pause Options")
@export var MouseScroll : BaseButton
@export var AutoPhase : BaseButton
@export var FastDP : BaseButton
@export var ActionChangePart : BaseButton
@export var VisCapitals : BaseButton
@export var VisUI : BaseButton
@export var VisTurnOrder : BaseButton

@export_subgroup("Tooltips")
@export var TooltipActions : Label
@export var TooltipPhase : Label
@export var TooltipEndTurn : Label
@export var TooltipForfeit : Label

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl
@onready var window_size : Vector2

var farthest_left : int = 0
var farthest_right : int = 0
var farthest_up : int = 0
var farthest_down : int = 0

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
	game_control.command_callout = CommandCallout
	
	zoom_level = ZOOM_START
	zoom_change(0)
	
	if PlayerInfo:
		PlayerInfo.visible = false
		if PILeader:
			var leader : Sprite2D = AlignmentList.make_leader(0)
			leader.position = PILeader.position
			leader.scale = PILeader.scale
			PILeader.queue_free()
			PlayerInfo.add_child(leader)
			PILeader = leader
	if PauseMenu:
		PauseMenu.visible = false
	if VictoryMessage:
		VictoryMessage.visible = false
	if DefeatMessage:
		DefeatMessage.visible = false
	if LeaveMessage:
		LeaveMessage.visible = false
	if ForfeitMessage:
		ForfeitMessage.visible = false
	
	if AdvanceTurnButton:
		AdvanceTurnButton.pressed.connect(try_advance_turn)
		AdvanceTurnButton.mouse_entered.connect(show_tooltip.bind(TOOLTIP.PHASE))
		AdvanceTurnButton.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.PHASE))
	if EndTurnButton:
		EndTurnButton.pressed.connect(try_end_turn)
		EndTurnButton.mouse_entered.connect(show_tooltip.bind(TOOLTIP.END_TURN))
		EndTurnButton.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.END_TURN))
	if ForfeitButton:
		ForfeitButton.pressed.connect(try_forfeit)
		ForfeitButton.mouse_entered.connect(show_tooltip.bind(TOOLTIP.FORFEIT))
		ForfeitButton.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.FORFEIT))
	if PowerAmount:
		PowerAmount.mouse_entered.connect(show_tooltip.bind(TOOLTIP.ACTIONS))
		PowerAmount.mouse_exited.connect(hide_tooltip.bind(TOOLTIP.ACTIONS))
	if TurnOrder:
		TurnOrder.mouse_entered.connect(_on_turn_order_hovered)
		TurnOrder.mouse_exited.connect(_on_turn_order_left)
	if PauseButton:
		PauseButton.pressed.connect(toggle_pause_menu)
	if LeaveButton:
		LeaveButton.pressed.connect(try_leaving)
	
	if MouseScroll:
		MouseScroll.button_pressed = Options.mouse_scroll_active
	if AutoPhase:
		AutoPhase.button_pressed = Options.auto_end_turn_phases
	if FastDP:
		FastDP.button_pressed = Options.dp_speedrun
	if ActionChangePart:
		ActionChangePart.button_pressed = Options.action_change_particles
	if VisUI and UIHideable:
		VisUI.button_pressed = UIHideable.visible
	if VisTurnOrder and TurnOrder:
		VisTurnOrder.button_pressed = TurnOrder.visible
	
	Options.timestamp("GameCamera ready", "GameCamera")
	call_deferred("_deferred_ready")


func _deferred_ready():
	Options.timestamp("GameCamera deferred")
	
	region_control = game_control.region_control as RegionControl
	
	for i in region_control.polygon:
		if i.x > farthest_right:
			@warning_ignore("narrowing_conversion")
			farthest_right = i.x
		if i.x < farthest_left:
			@warning_ignore("narrowing_conversion")
			farthest_left = i.x
		if i.y > farthest_down:
			@warning_ignore("narrowing_conversion")
			farthest_down = i.y
		if i.y < farthest_up:
			@warning_ignore("narrowing_conversion")
			farthest_up = i.y
	
	if farthest_right < window_size.x / 2:
		@warning_ignore("narrowing_conversion")
		farthest_right = window_size.x / 2
	if farthest_left > -window_size.x / 2:
		@warning_ignore("narrowing_conversion")
		farthest_left = -window_size.x / 2
	if farthest_down < window_size.y / 2:
		@warning_ignore("narrowing_conversion")
		farthest_down = window_size.y / 2
	if farthest_up > -window_size.y / 2:
		@warning_ignore("narrowing_conversion")
		farthest_up = -window_size.y / 2
	
	@warning_ignore("narrowing_conversion")
	farthest_right += region_control.offset.x
	@warning_ignore("narrowing_conversion")
	farthest_left += region_control.offset.x
	@warning_ignore("narrowing_conversion")
	farthest_down += region_control.offset.y
	@warning_ignore("narrowing_conversion")
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
	
	if VisCapitals and region_control:
		VisCapitals.button_pressed = region_control.cities_visible
	
	update_alignment_colored_ui()
	update_current_action(region_control.current_phase)
	
	for path in MapTintList:
		get_node(path).self_modulate = region_control.color
	
	CommandCallout.default_color = region_control.command_callout_color
	
	_connect_region_control_signals()
	
	update_current_turn()
	update_alignment_label()
	
	if TurnOrder:
		TurnOrder.ready_list(region_control)
		TurnOrder.select_leader(region_control.current_playing_align)
	
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
	
	if ReplayControl.replay_active:
		ReplayPausedLabel.visible = ReplayControl.paused
	
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
	if UI:
		move_speed *= UI.scale.x
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
	if UI:
		UI.scale.x = 1 / zoom.x
		UI.scale.y = UI.scale.x


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
	if UIHideable and not UIHideable.visible:
		return
	
	var part = ActionChangeParticle.instantiate()
	part.text = str(amount)
	if amount > 0:
		part.text = "+" + part.text
	part.position = Vector2(-448, 208)
	part.color = color
	
	UI.add_child(part)


func toggle_ui_visible():
	set_ui_visible(not UIHideable.visible)


func set_ui_visible(visibility : bool):
	if UIHideable:
		UIHideable.visible = visibility
		if VisUI:
			VisUI.set_pressed_no_signal(visibility)


func toggle_turn_order_visible():
	if TurnOrder:
		set_turn_order_visible(not TurnOrder.visible)


func set_turn_order_visible(visibility : bool):
	if TurnOrder:
		TurnOrder.visible = visibility
		if VisTurnOrder:
			VisTurnOrder.set_pressed_no_signal(TurnOrder.visible)


func set_player_info_visible(visibility : bool):
	if PlayerInfo:
		PlayerInfo.visible = visibility


func update_player_info() -> void:
	if not TurnOrder or not PlayerInfo:
		return
	
	var recent_hovered_player : int = TurnOrder.get_leader_id_from_position(game_control.mouse_position)
	
	var new_player : bool = false
	if hovered_player != recent_hovered_player:
		hovered_player = recent_hovered_player
		new_player = true
	
	var player_alignment : int = region_control.get_alignment_from_play_order(hovered_player)
	var leader : Sprite2D = TurnOrder.get_leader(player_alignment) as Sprite2D
	if leader and leader.visible:
		var color : Color = leader.self_modulate
		if new_player:
			AlignmentList.color_leader(PILeader, color)
			AlignmentList.set_leader_dp(PILeader, leader.frame)
			PlayerInfo.self_modulate = color
			PICity.self_modulate = color
			PICapital.self_modulate = color
			PIRegions.self_modulate = RegionControl.text_color(color.v)
			PIPower.self_modulate = RegionControl.text_color(color.v)
			PIName.text = region_control.get_alignment_name(player_alignment)
		
		PIRegions.text = String.num(region_control.get_alignment_regions(player_alignment))
		PIPower.text = String.num(region_control.get_alignment_capitals(player_alignment))
		AlignmentList.leader_sweat(PILeader, region_control.get_alignment_capitals(player_alignment) <= 0)
		
		if region_control.get_alignment_penalties(player_alignment) > 0:
			PIPower.text += "\n-" + String.num(region_control.get_alignment_penalties(player_alignment))
		
	else:
		set_player_info_visible(false)


func update_alignment_colored_ui():
	if PlayerActions:
		PlayerActions.modulate = region_control.get_current_alignment_color()
		PlayerActions.modulate.a = 1
		PlayerActions.visible = region_control.is_player_controled and not ReplayControl.replay_active
		var value : float = PlayerActions.modulate.v
		set_ui_shader_parameter(AdvanceActionLight, "value", value)
		set_ui_shader_parameter(AdvanceActionDark, "value", value)
		set_ui_shader_parameter(AdvanceMobilizeLight, "value", value)
		set_ui_shader_parameter(AdvanceMobilizeDark, "value", value)
		set_ui_shader_parameter(EndTurnButton, "value", value)
		set_ui_shader_parameter(ForfeitButton, "value", value)
		if CurrentAction:
			if region_control.is_player_controled:
				CurrentAction.self_modulate = RegionControl.text_color(value)
			else:
				CurrentAction.self_modulate = Color.WHITE
	if PowerSprite:
		PowerSprite.self_modulate = region_control.get_current_alignment_color()
		PowerSprite.self_modulate.a = 1
		if PowerAmount:
			PowerAmount.self_modulate = RegionControl.text_color(PowerSprite.self_modulate.v)


func update_alignment_label():
	if CurrentAlignment:
		CurrentAlignment.text = region_control.get_current_alignment_name()


func update_current_turn():
	if CurrentTurn:
		CurrentTurn.text = "Turn " + str(region_control.current_turn)


func advance_turn_visual(type : int):
	if AdvanceActionLight:
		AdvanceActionLight.visible = type == 0
	
	if AdvanceActionDark:
		AdvanceActionDark.visible = type == 1
	
	if AdvanceMobilizeLight:
		AdvanceMobilizeLight.visible = type == 2
	
	if AdvanceMobilizeDark:
		AdvanceMobilizeDark.visible = type == 3


func update_current_action(current_phase : int):
	if CurrentAction:
		CurrentAction.text = ACTIONS[current_phase]
	if current_phase == RegionControl.PHASE.MOBILIZE:
		advance_turn_visual(2)
	elif current_phase == RegionControl.PHASE.BONUS and region_control.bonus_action_amount == 0:
		advance_turn_visual(1)
	else:
		advance_turn_visual(0)
	if PhaseInfo:
		PhaseInfo.text = PHASE_INFO[current_phase]


func show_victory_message(alignment : int):
	if VictoryMessage:
		VictoryMessage.visible = true
		VictoryMessage.modulate = region_control.align_color[alignment]


func show_defeat_message(alignment : int):
	if DefeatMessage:
		DefeatMessage.visible = true
		DefeatMessage.modulate = region_control.align_color[alignment]


func set_leave_message(visibility : bool):
	if LeaveMessage:
		LeaveMessage.visible = visibility


func set_forfeit_message(visibility : bool):
	if ForfeitMessage:
		ForfeitMessage.visible = visibility


func set_leftover_message(visibility : bool):
	if LeftoverMessage:
		LeftoverMessage.visible = visibility


func toggle_pause_menu():
	set_pause_menu_visible(not PauseMenu.visible)
	set_leave_message(false)


func set_pause_menu_visible(visibility : bool):
	if PauseMenu:
		PauseMenu.visible = visibility
		if game_control:
			game_control.inputs_active = not visibility


func show_tooltip(tooltip : TOOLTIP):
	TooltipActions.visible = tooltip == TOOLTIP.ACTIONS
	TooltipPhase.visible = tooltip == TOOLTIP.PHASE
	TooltipEndTurn.visible = tooltip == TOOLTIP.END_TURN
	TooltipForfeit.visible = tooltip == TOOLTIP.FORFEIT
	disable_camera_movement = true


func hide_tooltip(tooltip : TOOLTIP):
	match tooltip:
		TOOLTIP.ACTIONS:
			TooltipActions.visible = false
		TOOLTIP.PHASE:
			TooltipPhase.visible = false
		TOOLTIP.END_TURN:
			TooltipEndTurn.visible = false
		TOOLTIP.FORFEIT:
			TooltipForfeit.visible = false
	disable_camera_movement = false


func hide_all_tooltips():
	TooltipActions.visible = false
	TooltipPhase.visible = false
	TooltipEndTurn.visible = false
	TooltipForfeit.visible = false
	disable_camera_movement = false


func _on_turn_ended():
	update_alignment_colored_ui()
	
	if TurnOrder:
		TurnOrder.update_list(region_control)
		TurnOrder.select_leader(region_control.current_playing_align)
	
	if not region_control.is_player_controled:
		disable_camera_movement = false
	
	update_current_turn()
	update_current_action(region_control.current_phase)
	
	update_alignment_label()
	
	hide_all_tooltips()


func _on_turn_phase_changed(current_phase : int):
	update_current_action(current_phase)


func _on_actions_modified(amount : int) -> void:
	if PowerAmount:
		PowerAmount.text = String.num(region_control.get_action_amount())
	if amount != 0:
		make_action_changed_particle(amount, region_control.get_current_alignment_color())
	if region_control.get_action_amount() == 0:
		advance_turn_visual(1)


func _on_turn_order_hovered():
	hovering_turn_order = true
	set_player_info_visible(true)


func _on_turn_order_left():
	hovering_turn_order = false
	set_player_info_visible(false)


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
