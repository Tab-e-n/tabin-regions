extends Node2D
class_name GameControl


@export var map : String = "2._Testlandia.tscn"

@onready var game_camera : GameCamera
@onready var region_control : RegionControl
@onready var ai_control : AIControler
@onready var command_callout : CommandCallouts

var mouse_wheel_input : int = 0
var mouse_position : Vector2

var win_timer : float = -1

var hide_cross : float = 0


func _ready():
	if not MapSetup.current_map_name.is_empty():
		map = MapSetup.current_map_name
	
	load_map(map)


func _input(event):
#	if event is InputEventKey:
#		if event.key_label != KEY_ESCAPE:
#			LeaveMessage.visible = false
	if event is InputEventMouseButton:
#		LeaveMessage.visible = false
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
		if mouse_position.x > game_camera.window_size.x - 64:
			direction.x += 1
		if mouse_position.x < 64:
			direction.x -= 1
		if mouse_position.y > game_camera.window_size.y - 64:
			direction.y += 1
		if mouse_position.y < 64:
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
		region_control.hide_capitals()
		game_camera.CommandCallout.new_callout("Toggle hide capitols")
	
	if Input.is_action_just_pressed("disable_mouse_scroll"):
		Options.mouse_scroll_active = not Options.mouse_scroll_active
		if Options.mouse_scroll_active:
			new_callout("Mouse scrolling active")
		else:
			new_callout("Mouse scrolling disabled")
	
	if Input.is_action_just_pressed("auto_phase"):
		Options.auto_end_turn_phases = not Options.auto_end_turn_phases
		if Options.auto_end_turn_phases:
			new_callout("Phases end when no actions are left")
		else:
			new_callout("Phases end only after user input")
	
	if Input.is_action_just_pressed("ai_speedrun"):
		Options.speedrun_ai = not Options.speedrun_ai
		ai_control.speedrun_ai_update()
		if Options.speedrun_ai:
			new_callout("Fast AI")
		else:
			new_callout("Slow AI")
	
	mouse_wheel_input = 0


func new_callout(text: String):
	if command_callout:
		command_callout.new_callout(text)


func load_map(map_name : String):
	var packed_map : PackedScene = load("res://Maps/" + map_name)
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


