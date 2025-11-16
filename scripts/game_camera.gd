extends Camera2D
class_name GameCamera


const PREVENT_CAMERA_MOVEMENT_START : float = 1


const ZOOM_OUT_MAX : int = -10
const ZOOM_START : int = 0
const ZOOM_IN_MAX : int = 5
const BASE_MOVE_SPEED : float = 8


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
@export var Attacks : RichTextLabel
@export var PowerSprite : TextureRect
@export var PowerAmount : Label
@export var CurrentTurn : Label
@export var CurrentAlignment : Label
@export var CurrentAction : Label
@export var PhaseInfo : Label
@export var ReplayPausedLabel : Label

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

var hovering_advance_turn : bool = false
var hovering_turn_order : bool = false

var hovered_player : int = -1

var shake_duration : float
var shake_time : float
var shake_amplitude : float
var shake_period : float


func _ready():
	z_index = 100
	window_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	window_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	game_control.game_camera = self
	game_control.command_callout = CommandCallout
	
	zoom_level = ZOOM_START
	zoom_change(0)
	
	if PlayerInfo:
		PlayerInfo.visible = false
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
		AdvanceTurnButton.mouse_entered.connect(show_tooltip_phase)
		AdvanceTurnButton.mouse_exited.connect(hide_tooltip_phase)
	if EndTurnButton:
		EndTurnButton.pressed.connect(try_end_turn)
		EndTurnButton.mouse_entered.connect(show_tooltip_end_turn)
		EndTurnButton.mouse_exited.connect(hide_tooltip_end_turn)
	if ForfeitButton:
		ForfeitButton.pressed.connect(_forfeit_show)
		ForfeitButton.mouse_entered.connect(show_tooltip_forfeit)
		ForfeitButton.mouse_exited.connect(hide_tooltip_forfeit)
	if PowerAmount:
		PowerAmount.mouse_entered.connect(show_tooltip_actions)
		PowerAmount.mouse_exited.connect(hide_tooltip_actions)
	if TurnOrder:
		TurnOrder.mouse_entered.connect(_TurnOrder_cam_disable)
		TurnOrder.mouse_exited.connect(_TurnOrder_cam_enable)
	if PauseButton:
		PauseButton.pressed.connect(toggle_pause_menu)
	if LeaveButton:
		LeaveButton.pressed.connect(_leaving)
	
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
	
	call_deferred("_deffered_ready")


func _deffered_ready():
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
	
	update_ui_color()
	update_current_action(region_control.current_phase)
	
	for path in MapTintList:
		get_node(path).self_modulate = region_control.color
	
	CommandCallout.default_color = region_control.command_callout_color
	
	connect_region_control_signals()
	
	call_deferred("_ready_turn_order")
	
	update_current_turn()
	update_alignment_label()
	
	Attacks.scale = Vector2(region_control.city_size, region_control.city_size);


func connect_region_control_signals():
	if region_control:
		region_control.turn_ended.connect(_turn_ended)
		region_control.turn_phase_changed.connect(_turn_phase_changed)


func _ready_turn_order():
	if not TurnOrder:
		return
	
	TurnOrder._ready_list(region_control)
	TurnOrder.select_leader(region_control.current_playing_align)
	
#	if Attacks:
#		if TurnOrder.size.x > AlignmentList.PLAY_ORDER_MAX_SIZE:
#			Attacks.size.x = AlignmentList.PLAY_ORDER_MAX_SIZE
#		else:
#			Attacks.size.x = TurnOrder.size.x


func _process(delta):
	if hovering_advance_turn or hovering_turn_order:
		cam_movement_stop = 1
	
	if PowerAmount:
		if region_control.current_phase == RegionControl.PHASE_NORMAL:
			PowerAmount.text = String.num(region_control.action_amount)
		else:
			PowerAmount.text = String.num(region_control.bonus_action_amount)
	
	if PlayerInfo:
		PlayerInfo.visible = hovering_turn_order
	if hovering_turn_order and TurnOrder and PlayerInfo:
		var hovering_over_player : int = int((game_control.mouse_position.x - AlignmentList.PLAY_ORDER_SCREEN_BORDER_GAP) / (AlignmentList.PLAY_ORDER_SPACING * TurnOrder.scale.x))
		
		if hovering_over_player >= region_control.align_amount - 1:
			hovering_over_player = region_control.align_amount - 2
		if hovering_over_player < 0:
			hovering_over_player = 0
		
		var new_player : bool = false
		if hovered_player != hovering_over_player:
			hovered_player = hovering_over_player
			new_player = true
		
		var player_alignment : int = region_control.align_play_order[hovered_player]
		var leader : Sprite2D = TurnOrder.get_node(String.num(player_alignment)) as Sprite2D
		if leader.visible:
			var city_amount : Label = PlayerInfo.get_node("CityAmount") as Label
			var capital_amount : Label = PlayerInfo.get_node("CapitalAmount") as Label
			if new_player:
				var info_leader : Sprite2D = PlayerInfo.get_node("Player") as Sprite2D
				info_leader.self_modulate = leader.self_modulate
				info_leader.frame = leader.frame
				PlayerInfo.self_modulate = leader.self_modulate
				PlayerInfo.get_node("City").self_modulate = leader.self_modulate
				PlayerInfo.get_node("Capital").self_modulate = leader.self_modulate
				if leader.self_modulate.v > region_control.COLOR_TOO_BRIGHT:
					city_amount.self_modulate = Color(0, 0, 0)
					capital_amount.self_modulate = Color(0, 0, 0)
				else:
					city_amount.self_modulate = Color(1, 1, 1)
					capital_amount.self_modulate = Color(1, 1, 1)
				PlayerInfo.get_node("Name").text = region_control.align_names[player_alignment]
			
			city_amount.text = String.num(region_control.region_amount[player_alignment - 1])
			capital_amount.text = String.num(region_control.capital_amount[player_alignment - 1])
			if region_control.penalty_amount[player_alignment - 1] > 0:
				capital_amount.text += "\n-" + String.num(region_control.penalty_amount[player_alignment - 1])
		else:
			PlayerInfo.visible = false
	
	if ReplayControl.replay_active:
		ReplayPausedLabel.visible = ReplayControl.paused
	
	var shake_offset : Vector2 = Vector2(0.0, 0.0)
	
	if shake_time > 0.0:
		shake_time -= delta
		var damp : float = shake_time / shake_duration
		shake_offset.x = shake_amplitude * (abs(shake_period - wrap(shake_time, 0.0, shake_period * 0.15) * 13.3) - 0.5) * damp
		shake_offset.y = shake_amplitude * abs(shake_period - wrap(shake_time, 0.0, shake_period * 0.4) * 5.0) * damp
#		print(shake_offset)
		if shake_time <= 0.0:
			shake_time = 0.0
			shake_duration = 0.0
			shake_amplitude = 0.0
			shake_period = 0.0
	
	position = next_position + shake_offset
	force_update_scroll()
#	call_deferred("set", "position", next_position)


func update_ui_color():
	if PlayerActions:
		PlayerActions.modulate = region_control.align_color[region_control.current_playing_align]
		PlayerActions.modulate.a = 1
		PlayerActions.visible = region_control.is_player_controled and not ReplayControl.replay_active
		if AdvanceActionLight:
			AdvanceActionLight.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if AdvanceActionDark:
			AdvanceActionDark.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if AdvanceMobilizeLight:
			AdvanceMobilizeLight.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if AdvanceMobilizeDark:
			AdvanceMobilizeDark.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if EndTurnButton:
			EndTurnButton.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if ForfeitButton:
			ForfeitButton.material.set_shader_parameter("value", PlayerActions.modulate.v)
		if CurrentAction:
			if region_control.is_player_controled:
				CurrentAction.self_modulate = RegionControl.text_color(PlayerActions.modulate.v)
			else:
				CurrentAction.self_modulate = Color.WHITE
	if PowerSprite:
		PowerSprite.self_modulate = region_control.align_color[region_control.current_playing_align]
		PowerSprite.self_modulate.a = 1
	if PowerAmount:
		PowerAmount.self_modulate = RegionControl.text_color(PowerSprite.self_modulate.v)


func update_current_action(current_phase : int):
	if CurrentAction:
		const ACTIONS : Array[String] = ["FIRST ACTIONS", "MOBILIZATION", "BONUS ACTIONS"]
		CurrentAction.text = ACTIONS[current_phase]
	if current_phase == RegionControl.PHASE_MOBILIZE:
		advance_turn_visual(2)
	elif current_phase == RegionControl.PHASE_BONUS and region_control.bonus_action_amount == 0:
		advance_turn_visual(0)
	else:
		advance_turn_visual(1)
	if PhaseInfo:
		const PHASE_INFO : Array[String] = [
			"First Actions: Attack or defend regions!",
			"Mobilization: Grab extra units!",
			"Bonus Actions: Attack or defend regions with mobilized units!"
		]
		PhaseInfo.text = PHASE_INFO[current_phase]


func _turn_ended():
	update_ui_color()
	
	if TurnOrder:
		TurnOrder.update_list(region_control)
		TurnOrder.select_leader(region_control.current_playing_align)
	
	if not region_control.is_player_controled:
		hovering_advance_turn = false
	
	update_current_turn()
	update_current_action(region_control.current_phase)
	
	update_alignment_label()
	
	hide_tooltips()


func _turn_phase_changed(current_phase : int):
	update_current_action(current_phase)


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


func try_advance_turn():
	if region_control.current_phase == RegionControl.PHASE_BONUS and region_control.bonus_action_amount > 0:
		_leftover_show()
	else:
		advance_turn()


func advance_turn():
	region_control.change_current_phase()


func try_end_turn():
	if region_control.current_phase == RegionControl.PHASE_NORMAL and region_control.action_amount > 0:
		_leftover_show()
	elif region_control.bonus_action_amount > 0:
		_leftover_show()
	else:
		end_turn()


func end_turn():
	_leftover_hide()
	region_control.end_turn(true)


func _leftover_show():
	if LeftoverMessage:
		LeftoverMessage.visible = true


func _leftover_hide():
	if LeftoverMessage:
		LeftoverMessage.visible = false


func _forfeit_show():
	if ForfeitMessage:
		ForfeitMessage.visible = true


func _forfeit_hide():
	if ForfeitMessage:
		ForfeitMessage.visible = false


func show_victory_message(alignment : int):
	if VictoryMessage:
		VictoryMessage.visible = true
		VictoryMessage.modulate = region_control.align_color[alignment]


func show_defeat_message(alignment : int):
	if DefeatMessage:
		DefeatMessage.visible = true
		DefeatMessage.modulate = region_control.align_color[alignment]


func _forfeit():
	_forfeit_hide()
	region_control.forfeit()


func hide_tooltips():
	TooltipActions.visible = false
	TooltipPhase.visible = false
	TooltipEndTurn.visible = false
	TooltipForfeit.visible = false
	button_cam_enable()


func show_tooltip_actions():
	TooltipActions.visible = true
	TooltipPhase.visible = false
	TooltipEndTurn.visible = false
	TooltipForfeit.visible = false
	button_cam_disable()


func hide_tooltip_actions():
	TooltipActions.visible = false
	button_cam_enable()


func show_tooltip_phase():
	TooltipActions.visible = false
	TooltipPhase.visible = true
	TooltipEndTurn.visible = false
	TooltipForfeit.visible = false
	button_cam_disable()


func hide_tooltip_phase():
	TooltipPhase.visible = false
	button_cam_enable()


func show_tooltip_end_turn():
	TooltipActions.visible = false
	TooltipPhase.visible = false
	TooltipEndTurn.visible = true
	TooltipForfeit.visible = false
	button_cam_disable()


func hide_tooltip_end_turn():
	TooltipEndTurn.visible = false
	button_cam_enable()


func show_tooltip_forfeit():
	TooltipActions.visible = false
	TooltipPhase.visible = false
	TooltipEndTurn.visible = false
	TooltipForfeit.visible = true
	button_cam_disable()


func hide_tooltip_forfeit():
	TooltipForfeit.visible = false
	button_cam_enable()


func button_cam_disable():
	hovering_advance_turn = true


func button_cam_enable():
	hovering_advance_turn = false


func _TurnOrder_cam_disable():
	hovering_turn_order = true


func _TurnOrder_cam_enable():
	hovering_turn_order = false


func update_current_turn():
	if CurrentTurn:
		CurrentTurn.text = "Turn " + str(region_control.current_turn)


func toggle_pause_menu():
	if PauseMenu:
		PauseMenu.visible = not PauseMenu.visible
		if game_control:
			game_control.inputs_active = not PauseMenu.visible
	_not_leaving()


func hide_pause_menu():
	if PauseMenu:
		PauseMenu.visible = false
		if game_control:
			game_control.inputs_active = true


func toggle_ui_visibility():
	if UIHideable:
		UIHideable.visible = not UIHideable.visible
		if VisUI:
			VisUI.button_pressed = UIHideable.visible


func set_ui_visibility(visibility : bool):
	if UIHideable:
		UIHideable.visible = visibility


func toggle_turn_order_visibility():
	if TurnOrder:
		TurnOrder.visible = not TurnOrder.visible
		if VisTurnOrder:
			VisTurnOrder.button_pressed = TurnOrder.visible


func set_turn_order_visibility(visibility : bool):
	if TurnOrder:
		TurnOrder.visible = visibility


func show_attacks(region : Region):
	if not Attacks:
		return
	
	var adjanced : Array[int] = region.get_adjacent_attack_power()
	
	var text : String = ""
	var align_amount : int = region_control.align_amount
	
	for alignment in range(adjanced.size()):
		if alignment == 0 or adjanced[alignment] == 0:
			align_amount -= 1
			continue
		var color : Color = region_control.align_color[alignment]
		var text_color : Color = RegionControl.text_color(color.v)
		text += "[cell][bgcolor=#" + color.to_html() + "][color=#" + text_color.to_html() + "] "
		text += String.num(adjanced[alignment]) + " [/color][/bgcolor][/cell]"
	
	if align_amount > 0:
		text = "[center][table=" + String.num(align_amount) + "]" + text + "[/table][/center]"
		
		Attacks.clear()
		Attacks.append_text(text)
		Attacks.visible = true
	
	Attacks.position = region.position + Vector2(-Attacks.size.x, City.CAPITAL_TEXTURE_SIZE.y if region.is_capital else City.CITY_TEXTURE_SIZE.y) * Attacks.scale * 0.5


func hide_attacks():
	if Attacks:
		Attacks.visible = false


func _leaving():
	hide_pause_menu()
	if LeaveMessage:
		LeaveMessage.visible = true
	else:
		_confirmed_leave()


func _not_leaving():
	if LeaveMessage:
		LeaveMessage.visible = false


func _confirmed_leave():
	game_control.leave()


func center_camera(pos : Vector2):
	next_position = pos


func shake_camera(duration : float, amplitude : float, period : float) -> void:
	shake_duration += duration
	shake_time += duration
	shake_amplitude += amplitude
	shake_period = max(period, shake_period)


func changed_action_amount(amount : int, color : Color) -> void:
	if not Options.action_change_particles:
		return
	if UIHideable:
		if not UIHideable.visible:
			return
	if amount == 0:
		return
	var part = ActionChangeParticle.instantiate()
	if amount > 0:
		part.text = "+" + str(amount)
	else:
		part.text = str(amount)
	part.position = Vector2(-448, 208)
	part.color = color
	UI.add_child(part)
	
	if AdvanceActionLight:
		if region_control.current_phase == RegionControl.PHASE_NORMAL and region_control.action_amount == 0:
			advance_turn_visual(0)
		if region_control.current_phase == RegionControl.PHASE_BONUS and region_control.bonus_action_amount == 0:
			advance_turn_visual(0)


func advance_turn_visual(type : int):
	if AdvanceActionLight:
		if type == 0:
			AdvanceActionLight.visible = true
		else:
			AdvanceActionLight.visible = false
	
	if AdvanceActionDark:
		if type == 1:
			AdvanceActionDark.visible = true
		else:
			AdvanceActionDark.visible = false
	
	if AdvanceMobilizeLight:
		if type == 2:
			AdvanceMobilizeLight.visible = true
		else:
			AdvanceMobilizeLight.visible = false
	
	if AdvanceMobilizeDark:
		if type == 3:
			AdvanceMobilizeDark.visible = true
		else:
			AdvanceMobilizeDark.visible = false


func update_alignment_label():
	if CurrentAlignment:
		CurrentAlignment.text = region_control.align_names[region_control.current_playing_align]
