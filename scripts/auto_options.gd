extends Node


const VERSION: String = "v2.0.0"
const REPLAY_COMPATIBLE_VERSIONS: Array[String] = [VERSION]

const SAVEFILE: String = "user://OPTIONS.json"

const TIMESTAMPS_ACTIVE: bool = false
# 0 Will let through anything
const TIMESTAMP_THRESHOLD: float = 0.001

const BUILTIN_PACKS: Array = [
	"res://maps",
	"res://maps/botbattles",
]


var default_dp: DPControl.Controler = DPControl.Controler.SIMPLETON
var dp_speedrun: bool = false
var dp_think_timer: float = DPControl.THINKING_TIMER_DEFAULT
var mouse_scroll_active: bool = true
var auto_end_turn_phases: bool = false
var use_graph: bool = true

var action_change_particles: bool = true
var capital_distance_visible: bool = false

var last_tab: String = "maps"
var last_pack: String = "res://maps"
var accepted_directory_danger: bool = false
var allowed_directories: Array = []


var editor: bool = OS.has_feature("editor")

var current_timestamp: int = 0
var timestamp_sums: Dictionary = {}


func _ready():
	DirAccess.make_dir_absolute("user://Dev")
	
	load_options()


func _physics_process(_delta):
	if Input.is_action_just_pressed("super_exit"):
		discard_timestamp_sums()
		get_tree().quit()


func should_limit_flashing() -> bool:
	return dp_speedrun or dp_think_timer <= 0.35


func save_options():
	var options : Dictionary = {
		"default_dp" : default_dp,
		"dp_speedrun" : dp_speedrun,
		"dp_think_timer" : dp_think_timer,
		"mouse_scroll_active" : mouse_scroll_active,
		"auto_end_turn_phases" : auto_end_turn_phases,
		"use_graph" : use_graph,
		
		"action_change_particles" : action_change_particles,
		"capital_distance_visible" : capital_distance_visible,
		
		"last_tab" : last_tab,
		"last_pack" : last_pack,
		"accepted_directory_danger" : accepted_directory_danger,
		"allowed_directories" : allowed_directories,
	}
	
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(options))
	
	file.close()


func load_options():
	var options: Dictionary = {}
	
	if FileAccess.file_exists(SAVEFILE):
		var file = FileAccess.open(SAVEFILE, FileAccess.READ)
		
		options = JSON.parse_string(file.get_as_text())
		
		file.close()
		
		for i in options.keys():
			set(i, options[i])
		
		return true
	else:
		return false


func allow_directory(dir: String):
	allowed_directories.append(dir)
	allowed_directories.sort()
	save_options()


func disallow_directory_index(index: int):
	allowed_directories.remove_at(index)
	save_options()


func disallow_directory(dir: String):
	disallow_directory_index(allowed_directories.find(dir))


func _print_timestamp(timestamp_name: String, duration: float) -> void:
	print(timestamp_name, " : ", duration)


func _timestamp_duration(stamp: int, current: int) -> float:
	return (current - stamp) * 0.000001


func timestamp(timestamp_name: String = "Timestamp", group: String = "Other") -> void:
	if not TIMESTAMPS_ACTIVE or not editor:
		return
	var new: int = Time.get_ticks_usec()
	var duration: float = _timestamp_duration(current_timestamp, new)
	if duration >= TIMESTAMP_THRESHOLD:
		_print_timestamp(timestamp_name, duration)
	current_timestamp = new
	if not group.is_empty():
		timestamp_sums[group] = timestamp_sums.get(group, 0.0) + duration
		timestamp_sums["TOTAL"] = timestamp_sums.get("TOTAL", 0.0) + duration


func discard_timestamp_sums():
	if not TIMESTAMPS_ACTIVE or not editor:
		return
	print("SUMMARY OF CURRENT SECTION")
	var keys: Array = timestamp_sums.keys()
	var summaries: Array = []
	for key in keys:
		summaries.append([timestamp_sums[key], key])
	summaries.sort()
	summaries.reverse()
	for pair in summaries:
		var value = pair[0]
		var key = pair[1]
		_print_timestamp(key, value)
	print("")
	timestamp_sums.clear()
