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

func get_pack_save_folder(pack_folder: String) -> String:
	return "user:" + pack_folder.trim_prefix("res:")


func get_pack_savefile_name(pack_save_folder: String) -> String:
	return pack_save_folder + "/savefile.sav"


#func get_pack_savefile_name(pack_folder: String) -> String:
#	if Options.pack_user_folders.has(pack_folder):
#		return Options.pack_user_folders[pack_folder]
#
#	var savefile: String = "save" + Options.pack_user_folders.size()
#	if FileAccess.file_exists("user://" + savefile):
#		var i: int = 1
#		while FileAccess.file_exists("user://" + savefile + "_" + str(i)):
#			i += 1
#		savefile += "_" + str(i)
#
#	Options.pack_user_folders[pack_folder] = savefile
#
#	return savefile


func save_pack_savefile(save_name: String, data: Dictionary) -> bool:
	var savefile: ConfigFile = ConfigFile.new()
	
	for section in data:
		if data[section] is Dictionary:
			for key in data[section]:
				savefile.set_value(section, key, data[section][key])
	
	return savefile.save(save_name) == OK


func load_pack_savefile(save_name: String) -> Dictionary:
	var savefile: ConfigFile = ConfigFile.new()
	
	var data: Dictionary = {}
	
	if savefile.load(save_name):
		for section in savefile.get_sections():
			data[section] = {}
			for key in savefile.get_section_keys(section):
				var value: Variant = savefile.get_value(section, key)
				if value != null:
					data[section][key] = value
	
	return data


func set_pack_data(data: Dictionary, section: String, key: String, value: Variant) -> void:
	if not data.has(section):
		data[section] = {}
	data[section][key] = value


func get_pack_data(data: Dictionary, section: String, key: String, default: Variant = null) -> Variant:
	if not data.has(section) or not data[section] is Dictionary or not data[section].has(key):
		return default
	return data[section][key]


# ------------ CHECKMARKS ------------

func check_general() -> String:
	return "won"


func check_alignment(alignment: int) -> String:
	return str(alignment)


func checkmark_set(data: Dictionary, map: String, check: String, dp: DPControl.Controler) -> void:
	set_pack_data(data, map, check, dp)


func checkmark_save_replay(data: Dictionary, map: String, check: String, dp: DPControl.Controler) -> void:
	pass # TODO
