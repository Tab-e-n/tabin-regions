extends Node

var current_directory: String = "res://maps"
var current_map_name: String = ""
var current_pack_name: String = "Base Maps"

var player_amount: int = 1
var default_digital_player: DPControl.Controler = DPControl.Controler.DEFAULT

var aliances_amount: int = 0

var used_alignments: int = 0

var preset_alignments: Array[int] = []


func _ready():
	current_directory = Options.last_pack
	var info: Dictionary = load_pack_info()
	current_pack_name = info["title"]


func load_map(_map_name: String) -> RegionControl:
	var packed_map: PackedScene = load(MapSetup.current_directory + "/" + _map_name) as PackedScene
	if not packed_map:
		push_error(_map_name, " is not a Scene, could not load.")
		return null
	var new_map: RegionControl = packed_map.instantiate() as RegionControl
	if not new_map:
		push_warning(_map_name, " is not a RegionControl, refused to load.")
		return null
	return new_map


func load_pack_info(dir: String = current_directory) -> Dictionary:
	var info: Dictionary = {
		"title" : dir,
		"lore" : "A pack of maps.",
	}
	
	if FileAccess.file_exists(dir + "/info.json"):
		var file = FileAccess.open(dir + "/info.json", FileAccess.READ)
		
		info = JSON.parse_string(file.get_as_text())
		
		file.close()
		
	return info


func print_map_data():
	print(current_map_name)
	print("Players: ", player_amount)
	print("Default DP: ", default_digital_player)
	print("Aliances: ", aliances_amount)
	print("Used Aligns: ", used_alignments)
	print("Preset Aligns: ", preset_alignments)


# ------------ PACK USER DATA ------------

func pack_user_folder(pack_filename: String) -> String:
	return "user:" + pack_filename.trim_prefix("res:")


func load_user_folder() -> Dictionary:
	
	ConfigFile
	
	return {}
