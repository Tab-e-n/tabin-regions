extends Node

var current_directory: String = "res://maps"
var current_map_name: String = ""
var current_pack_name: String = "Base Maps"

var pack_user_data: Dictionary = {}

var used_alignments: int = 0
var player_amount: int = 1
var aliances_amount: int = 0
var default_digital_player: DPControl.Controler = DPControl.Controler.DEFAULT

var preset_alignments: Array[int] = []

var loading_in: bool = true


func _options_loaded():
	current_directory = Options.last_pack
	if not current_directory in Options.BUILTIN_PACKS and not current_directory in Options.allowed_directories:
		current_directory = "res://maps"
	
	var info: Dictionary = load_pack_info()
	current_pack_name = info["title"]
	
	load_pack_user_data()


func load_map(_map_name: String) -> RegionControl:
	var packed_map: PackedScene = load(current_directory + "/" + _map_name) as PackedScene
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
	if pack_folder.begins_with("res:"):
		return "user://data_base/" + pack_folder.trim_prefix("res://")
	return "user://data_packs/" + pack_folder.trim_prefix("user://packs/")


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


func make_user_data_folder(pack_folder: String) -> void:
	var save_folder: String = get_pack_save_folder(pack_folder)
	DirAccess.make_dir_recursive_absolute(save_folder)


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
	var err: Error = savefile.load(save_name)
	
	if err == OK:
		for section in savefile.get_sections():
			data[section] = {}
			for key in savefile.get_section_keys(section):
				var value: Variant = savefile.get_value(section, key)
				if value != null:
					data[section][key] = value
	else:
		push_error("Couldn't open pack savefile: ", save_name)
	
	return data


func load_pack_user_data() -> void:
	var save_folder: String = get_pack_save_folder(current_directory)
#	print(save_folder)
	if DirAccess.dir_exists_absolute(save_folder):
		var savefile_name: String = get_pack_savefile_name(save_folder)
#		print(savefile_name)
		pack_user_data = load_pack_savefile(savefile_name)


func set_pack_data(data: Dictionary, section: String, key: String, value: Variant) -> void:
	if not data.has(section):
		data[section] = {}
	data[section][key] = value


func get_pack_data(data: Dictionary, section: String, key: String, default: Variant = null) -> Variant:
	if not data.has(section) or not data[section] is Dictionary or not data[section].has(key):
		return default
	return data[section][key]


func get_pack_section(data: Dictionary, section: String, default: Dictionary = {}) -> Dictionary:
	if not data.has(section) or not data[section] is Dictionary:
		return default
	return data[section]


# ------------ CHECKMARKS ------------

func dp_difficulty(dp: DPControl.Controler) -> int:
	match dp:
		DPControl.Controler.DEFAULT:
			return 1
		DPControl.Controler.DUMMY:
			return 0
		DPControl.Controler.TURTLE:
			return 2
		DPControl.Controler.SIMPLETON:
			return 3
		DPControl.Controler.OVERTHINKER:
			return 4
		DPControl.Controler.BOOKWYRM:
			return 5
		DPControl.Controler.CHEATER:
			return 6
		_:
			return 0


func harder_dp(current: DPControl.Controler, new: DPControl.Controler) -> bool:
	return dp_difficulty(current) < dp_difficulty(new)


func check_general() -> String:
	return "won"


func check_bonus() -> String:
	return "bonus"


func check_alignment(alignment: int) -> String:
	return str(alignment)


func checkmark_set(map: String, check: String, dp: DPControl.Controler) -> void:
	set_pack_data(pack_user_data, map, check, dp)


func checkmark_get(map: String, check: String, dp: DPControl.Controler = DPControl.Controler.DUMMY) -> Variant:
	return get_pack_data(pack_user_data, map, check, dp)


func get_map_checkmarks(map: String) -> Dictionary:
	return get_pack_section(pack_user_data, map)


func checkmark_save_replay(pack: String, map: String, check: String, dp: DPControl.Controler) -> void:
	make_user_data_folder(pack)
	var replay_name: String = ReplayControl.pack_replay_filename(pack, map, check, dp)
	ReplayControl.save_replay(replay_name)


func checkmark_load_replay(pack: String, map: String, check: String, dp: DPControl.Controler) -> bool:
	var replay_name: String = ReplayControl.pack_replay_filename(pack, map, check, dp)
	return ReplayControl.load_replay(replay_name)


func save_checkmarks() -> void:
	make_user_data_folder(current_directory)
	var save_folder: String = get_pack_save_folder(current_directory)
	var savefile_name: String = get_pack_savefile_name(save_folder)
	save_pack_savefile(savefile_name, pack_user_data)
