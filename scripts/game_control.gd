extends Node2D
class_name GameControl


enum CURSOR {NORMAL, BLOCKED, PLUS, SHIELD, SWORD, FULL_PLUS, FULL_SHIELD, FULL_SWORD, HAND}

@export var map : String = "2._Testlandia.tscn"

@onready var game_camera : GameCamera
@onready var region_control : RegionControl
@onready var ai_control : AIControl
@onready var command_callout : CommandCallouts

var mouse_wheel_input : int = 0
var mouse_position : Vector2

var win_timer : float = -1

var inputs_active : bool = true

func _ready():
	GameControl.set_cursor(CURSOR.NORMAL)
	
	if not MapSetup.current_map_name.is_empty():
		map = MapSetup.current_map_name
	
	load_map(map)


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				mouse_wheel_input = 1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				mouse_wheel_input = -1


func _process(delta):
	if win_timer > 0:
		win_timer -= delta
		if win_timer <= 0:
			leave()
			return
	
	if inputs_active:
		if Input.is_action_just_pressed("escape"):
			if game_camera.LeaveMessage.visible:
				leave()
			game_camera.LeaveMessage.visible = true
		
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
		
		if game_camera.cam_movement_stop > 0:
			game_camera.cam_movement_stop -= 1
		elif Options.mouse_scroll_active:
			if mouse_position.x > game_camera.window_size.x - 16:
				direction.x += 1
			if mouse_position.x < 16:
				direction.x -= 1
			if mouse_position.y > game_camera.window_size.y - 16:
				direction.y += 1
			if mouse_position.y < 16:
				direction.y -= 1
		
		game_camera.move_camera(delta, direction, shift, ctrl)
		
		if Input.is_action_just_pressed("zoom_out") or mouse_wheel_input < 0:
			game_camera.zoom_change(-1)
		if Input.is_action_just_pressed("zoom_in") or mouse_wheel_input > 0:
			game_camera.zoom_change(1)
		if Input.is_action_just_pressed("zoom_reset"):
			game_camera.reset_zoom()
			new_callout("Reset zoom")
		
		if Input.is_action_just_pressed("hide_ui"):
			game_camera.toggle_ui_visibility()
			new_callout("Toggle hide UI")
		
		if Input.is_action_just_pressed("hide_turn_order"):
			game_camera.toggle_turn_order_visibility()
			new_callout("Toggle turn order")
		
		if Input.is_action_just_pressed("hide_capitals"):
			hide_capitals()
			game_camera.CommandCallout.new_callout("Toggle hide capitols")
		
		if Input.is_action_just_pressed("disable_mouse_scroll"):
			set_mouse_scroll(not Options.mouse_scroll_active)
			if Options.mouse_scroll_active:
				new_callout("Mouse scrolling active")
			else:
				new_callout("Mouse scrolling disabled")
			if game_camera.MouseScroll:
				game_camera.MouseScroll.button_pressed = Options.mouse_scroll_active
		
		if Input.is_action_just_pressed("auto_phase"):
			set_auto_phases(not Options.auto_end_turn_phases)
			if Options.auto_end_turn_phases:
				new_callout("Phases end when no actions are left")
			else:
				new_callout("Phases end only after user input")
			if game_camera.AutoPhase:
				game_camera.AutoPhase.button_pressed = Options.auto_end_turn_phases
		
		if Input.is_action_just_pressed("ai_speedrun"):
			set_speedrun_ai(not Options.speedrun_ai)
			if Options.speedrun_ai:
				new_callout("Fast AI")
			else:
				new_callout("Slow AI")
			if game_camera.FastAI:
				game_camera.FastAI.button_pressed = Options.speedrun_ai
		
		if Input.is_action_just_pressed("action_change_particles"):
			set_action_change_particles(not Options.action_change_particles)
			if Options.action_change_particles:
				new_callout("Action change particles on")
			else:
				new_callout("Action change particles off")
			if game_camera.ActionChangePart:
				game_camera.ActionChangePart.button_pressed = Options.action_change_particles
	
	mouse_wheel_input = 0


func hide_capitals():
	if region_control:
		region_control.hide_capitals()
		if game_camera.VisCapitals:
			game_camera.VisCapitals.button_pressed = region_control.cities_visible


func set_capital_visibility(visibility : bool):
	if region_control:
		region_control.set_capital_visibility(visibility)


func set_mouse_scroll(scrolling : bool):
	Options.mouse_scroll_active = scrolling


func set_auto_phases(auto : bool):
	Options.auto_end_turn_phases = auto


func set_speedrun_ai(speedy : bool):
	Options.speedrun_ai = speedy
	ai_control.speedrun_ai_update()


func set_action_change_particles(active : bool):
	Options.action_change_particles = active


func new_callout(text: String):
	if command_callout:
		command_callout.new_callout(text)


func load_map(map_name : String):
	var packed_map : PackedScene = load(MapSetup.current_directory + "/" + map_name)
	region_control = packed_map.instantiate()
	add_child(region_control)
	move_child(region_control, 1)


func change_map(map_name : String):
	if region_control:
		remove_child(region_control)
		region_control.queue_free()
	
	load_map(map_name)
	
	region_control.spawn_particles = false
	game_camera.region_control = region_control
	game_camera.connect_region_control_signals()
	ai_control.region_control = region_control
	
	ReplayControl.clear_replay()


func win(align : int):
	game_camera.show_victory_message(align)
	win_timer = 5.0


func lose(align : int):
	game_camera.show_defeat_message(align)
	win_timer = 5.0


func leave():
	get_tree().change_scene_to_file("res://stats.tscn")


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
