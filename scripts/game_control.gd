extends Node2D
class_name GameControl


signal show_extra_current(alignment : int)
signal show_extra_other(alignment : int)


## Possible cursor graphics that set_cursor can use.
enum CURSOR {
	## Regular cursor.
	NORMAL,
	## Blocked symbol.
	BLOCKED,
	## Regular cursor with an addition plus.
	PLUS,
	## Regular cursor with an addition shield.
	SHIELD,
	## Regular cursor with an addition sword.
	SWORD,
	## Plus symbol.
	FULL_PLUS,
	## Shield symbol.
	FULL_SHIELD,
	## Sword symbol.
	FULL_SWORD,
	## Hand symbol.
	HAND
}

@onready var game_camera : GameCamera
@onready var region_control : RegionControl
@onready var dp_control : DPControl
@onready var command_callout : CommandCallouts

var mouse_wheel_input : int = 0
var mouse_position : Vector2

var win_timer : float = -1

var inputs_active : bool = true

var map_name : String = "A.2_Title_Map.tscn"


## Sets the cursor graphic.
static func set_cursor(cursor : CURSOR):
	match cursor:
		CURSOR.NORMAL:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor.png"))
		CURSOR.BLOCKED:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_block.png"), Input.CURSOR_ARROW, Vector2(16, 16))
		CURSOR.PLUS:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_addon_plus.png"))
		CURSOR.SHIELD:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_addon_shield.png"))
		CURSOR.SWORD:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_addon_sword.png"))
		CURSOR.FULL_PLUS:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_plus.png"), Input.CURSOR_ARROW, Vector2(16, 16))
		CURSOR.FULL_SHIELD:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_shield.png"), Input.CURSOR_ARROW, Vector2(16, 16))
		CURSOR.FULL_SWORD:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_sword.png"))
		CURSOR.HAND:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor_hand.png"), Input.CURSOR_ARROW, Vector2(16, 16))
		_:
			Input.set_custom_mouse_cursor(preload("res://sprites/cursor/cursor.png"))


func _ready():
	Options.timestamp("GameControl")
	
	GameControl.set_cursor(CURSOR.NORMAL)
	
	if not MapSetup.current_map_name.is_empty():
		map_name = MapSetup.current_map_name
	else:
		push_warning("current_map_name in Map Setup is empty.")
	
	change_map(map_name, false)
	
	if not game_camera:
		push_error("No Game Camera present.")
	if not dp_control:
		push_error("No Digital Player Control present.")
	
	Options.timestamp("GameControl ready", "GameControl")


func _input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				mouse_wheel_input = 1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				mouse_wheel_input = -1


func _process(delta : float):
	if win_timer > 0:
		win_timer -= delta
		if win_timer <= 0:
			leave()
			return
	
	if inputs_active:
		if Input.is_action_just_pressed("escape"):
			if game_camera:
				if game_camera.leave_message.visible:
					leave()
					return
				game_camera.leave_message.visible = true
			else:
				leave()
				return
		
		mouse_position = get_viewport().get_mouse_position()
		var shift = Input.is_action_pressed("shift")
		var ctrl = Input.is_action_pressed("ctrl")
		
		var direction : Vector2 = Vector2(0, 0)
		if Input.is_action_pressed("right"):
			direction.x += 1
		if Input.is_action_pressed("left"):
			direction.x -= 1
		if Input.is_action_pressed("down"):
			direction.y += 1
		if Input.is_action_pressed("up"):
			direction.y -= 1
		
		var mouse_scrolling : bool = Options.mouse_scroll_active
		var window_limits : Vector2 = Vector2(0, 0)
		if game_camera:
			if game_camera.cam_movement_stop > 0:
				game_camera.cam_movement_stop -= 1
				mouse_scrolling = false
			window_limits = game_camera.window_size
		else:
			window_limits = GameCamera.get_window_size()
		
		if mouse_scrolling:
			if mouse_position.x > window_limits.x - 16:
				direction.x += 1
			if mouse_position.x < 16:
				direction.x -= 1
			if mouse_position.y > window_limits.y - 16:
				direction.y += 1
			if mouse_position.y < 16:
				direction.y -= 1
		
		if game_camera:
			game_camera.move_camera(delta, direction, shift, ctrl)
			
			if Input.is_action_just_pressed("zoom_out") or mouse_wheel_input < 0:
				game_camera.zoom_change(-1)
			if Input.is_action_just_pressed("zoom_in") or mouse_wheel_input > 0:
				game_camera.zoom_change(1)
			if Input.is_action_just_pressed("zoom_reset"):
				game_camera.reset_zoom()
				new_callout("Reset zoom")
			
			if Input.is_action_just_pressed("hide_ui"):
				game_camera.toggle_ui_visible()
				new_callout("Toggle hide UI")
			
			if Input.is_action_just_pressed("hide_turn_order"):
				game_camera.toggle_turn_order_visible()
				new_callout("Toggle turn order")
		
		if Input.is_action_just_pressed("hide_capitals"):
			toggle_cities()
			new_callout("Toggle hide capitols")
		
		if Input.is_action_just_pressed("disable_mouse_scroll"):
			set_mouse_scroll(not Options.mouse_scroll_active)
			if Options.mouse_scroll_active:
				new_callout("Mouse scrolling active")
			else:
				new_callout("Mouse scrolling disabled")
			if game_camera and game_camera.mouse_scroll:
				game_camera.mouse_scroll.button_pressed = Options.mouse_scroll_active
		
		if Input.is_action_just_pressed("auto_phase"):
			set_auto_phases(not Options.auto_end_turn_phases)
			if Options.auto_end_turn_phases:
				new_callout("Phases end when no actions are left")
			else:
				new_callout("Phases end only after user input")
			if game_camera and game_camera.auto_phase:
				game_camera.auto_phase.button_pressed = Options.auto_end_turn_phases
		
		if Input.is_action_just_pressed("dp_speedrun"):
			set_dp_speedrun(not Options.dp_speedrun)
			if Options.dp_speedrun:
				new_callout("Fast Digital Players")
			else:
				new_callout("Slow Digital Players")
			if game_camera and game_camera.fast_dp:
				game_camera.fast_dp.button_pressed = Options.dp_speedrun
		
		if Input.is_action_just_pressed("action_change_particles"):
			set_action_change_particles(not Options.action_change_particles)
			if Options.action_change_particles:
				new_callout("Action change particles on")
			else:
				new_callout("Action change particles off")
			if game_camera and game_camera.action_change_part:
				game_camera.action_change_part.button_pressed = Options.action_change_particles
		
		if ReplayControl.replay_active:
			if Input.is_action_just_pressed("right_click"):
				ReplayControl.toggle_pause()
		
		if region_control:
			if region_control.is_player_controled:
				if Input.is_action_just_pressed("forfeit"):
					region_control.forfeit()
					new_callout("Forfeit")
				elif Input.is_action_just_pressed("plus_foward"):
					region_control.end_turn(true)
					new_callout("End turn")
				elif Input.is_action_just_pressed("plus_turn"):
					region_control.change_current_phase()
					new_callout("Advance turn")
			
			if Input.is_action_just_pressed("show_extra"):
				if Input.is_action_pressed("shift"):
					show_extra_other.emit(region_control.current_playing_align)
				else:
					show_extra_current.emit(region_control.current_playing_align)
	
	mouse_wheel_input = 0


## Toggles if cities are visible or invisible.
func toggle_cities():
	if region_control:
		set_city_visibility(not region_control.cities_visible)


## Sets the visibility of cities.
func set_city_visibility(visibility : bool):
	if region_control:
		region_control.cities_visible = visibility
		if game_camera and game_camera.visible_capitals:
			game_camera.visible_capitals.set_pressed_no_signal(region_control.cities_visible)


## Sets whether to use mouse camera scrolling or not.
func set_mouse_scroll(scrolling : bool):
	Options.mouse_scroll_active = scrolling


## Sets whether to use automatic phases or not.
func set_auto_phases(auto : bool):
	Options.auto_end_turn_phases = auto


## Sets whether to use digital player speedrun or not.
func set_dp_speedrun(speedy : bool):
	Options.dp_speedrun = speedy
	if dp_control:
		dp_control.dp_speedrun_update()


## Sets whether to show action change particles or not.
func set_action_change_particles(active : bool):
	Options.action_change_particles = active


## Makes a new command callout.
func new_callout(text: String):
	if command_callout:
		command_callout.new_callout(text)


func unload_current_map() -> void:
	if not region_control:
		return
	if game_camera:
		game_camera._disconnect_region_control_signals()
	remove_child(region_control)
	region_control.queue_free()
	region_control = null


func load_map(_map_name : String) -> RegionControl:
	var packed_map : PackedScene = load(MapSetup.current_directory + "/" + _map_name) as PackedScene
	if not packed_map:
		push_error(_map_name, " is not a Scene, could not load.")
		return null
	var new_map : RegionControl = packed_map.instantiate() as RegionControl
	if not new_map:
		push_warning(_map_name, " is not a RegionControl, refused to load.")
		return null
	return new_map


## Tries to load a new map and if it succeeds, replaces the current map with the new one.
func change_map(new_map_name : String, update_others : bool = true) -> void:
	Options.timestamp("Call change_map", "GameControl")
	
	var new_map : RegionControl = load_map(new_map_name)
	if new_map:
		unload_current_map()
		
		map_name = new_map_name
		
		region_control = new_map
		add_child(region_control)
		move_child(region_control, 1)
		
		if update_others:
			if game_camera:
				game_camera.region_control = region_control
				game_camera._connect_region_control_signals()
			if dp_control:
				dp_control.region_control = region_control
			
			ReplayControl.clear_replay()
	
	Options.timestamp("Return change_map", "GameControl")


func win(align : int):
	if game_camera:
		game_camera.show_victory_message(align)
	win_timer = 5.0


func lose(align : int):
	if game_camera:
		game_camera.show_defeat_message(align)
	win_timer = 5.0


func leave():
	Options.discard_timestamp_sums()
	Options.timestamp("EXIT MAP", "")
	get_tree().change_scene_to_file("res://stats.tscn")
