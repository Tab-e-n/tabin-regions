extends Node


const SAVEFILE : String = "user://OPTIONS.json"

# 0 Will let through anything
const TIMESTAMP_THRESHOLD : float = 0.001


var version : String = "v2.0.0"
var replay_compatible_versions : Array[String] = [version]
var editor : bool = OS.has_feature("editor")

var dp_speedrun : bool = false
var mouse_scroll_active : bool = true
var auto_end_turn_phases : bool = false
var action_change_particles : bool = true
var allowed_directories : Array = []

var current_timestamp : int = 0
var timestamp_sums : Dictionary = {}


func _ready():
	DirAccess.make_dir_absolute("user://Dev")


func _physics_process(_delta):
	if Input.is_action_just_pressed("super_exit"):
		discard_timestamp_sums()
		get_tree().quit()


func save_options():
	var options : Dictionary = {
		"dp_speedrun" : dp_speedrun,
		"mouse_scroll_active" : mouse_scroll_active,
		"auto_end_turn_phases" : auto_end_turn_phases,
		"action_change_particles" : action_change_particles,
		"allowed_directories" : allowed_directories,
	}
	
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(options))
	
	file.close()


func load_options():
	var options : Dictionary = {}
	
	if FileAccess.file_exists(SAVEFILE):
		var file = FileAccess.open(SAVEFILE, FileAccess.READ)
		
		options = JSON.parse_string(file.get_as_text())
		
		file.close()
		
		for i in options.keys():
			set(i, options[i])
		
		return true
	else:
		return false


func _print_timestamp(timestamp_name : String, duration : float) -> void:
	print(timestamp_name, " : ", duration)


func _timestamp_duration(stamp : int, current : int) -> float:
	return (current - stamp) * 0.000001


func timestamp(timestamp_name : String = "Timestamp", group : String = "Other") -> void:
	if not editor:
		pass
	var new : int = Time.get_ticks_usec()
	var duration : float = _timestamp_duration(current_timestamp, new)
	if duration >= TIMESTAMP_THRESHOLD:
		_print_timestamp(timestamp_name, duration)
	current_timestamp = new
	timestamp_sums[group] = timestamp_sums.get(group, 0.0) + duration
	timestamp_sums["TOTAL"] = timestamp_sums.get("TOTAL", 0.0) + duration


func discard_timestamp_sums():
	print("SUMMARY OF CURRENT SECTION")
	for key in timestamp_sums:
		_print_timestamp(key, timestamp_sums[key])
	print("SUMMARY OVER")
	timestamp_sums.clear()
