extends Node


const SAVEFILE : String = "user://OPTIONS.json"


var version : String = "v2.0.0"
var replay_compatible_versions : Array[String] = [version]
var editor : bool = OS.has_feature("editor")

var dp_speedrun : bool = false
var mouse_scroll_active : bool = true
var auto_end_turn_phases : bool = false
var action_change_particles : bool = true
var allowed_directories : Array = []


func _ready():
	DirAccess.make_dir_absolute("user://Dev")


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
