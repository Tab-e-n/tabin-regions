extends Node


const NOTHING_MOVE = [1, "nothing", 0]

enum RecordType {
	REGION,
	FUNCTION,
	OVERTAKE,
	VOLCANO,
	TORNADO,
	START,
	MOD_POWER,
	MOD_MAX_POWER,
	ALL_EXCESS,
}


var initializing: bool = true
var replay_active: bool = false
var replay_ended: bool = false

var replay: Array = []
var current_replay_pos: int = 0

var replay_play_order: Array = []
var replay_controlers: Array = []

var replay_uses_aliances: bool = false
var replay_aliances: Array[int] = []

var replay_removed_alignments: Array = []

var last_turn: int = 0


func clear_replay():
	replay.clear()
	current_replay_pos = 0
	replay_play_order.clear()
	replay_uses_aliances = false
	replay_aliances.clear()
	replay_controlers.clear()
	replay_active = false


func record_move(type: RecordType, action: String = "", amount: int = 1):
	if not replay_active:
		replay.append([type, action, amount])
#		print(type, " ", action, " ", amount)


func get_next_move():
#	if paused and not initializing:
#		return NOTHING_MOVE
	if current_replay_pos < replay.size():
		var next_move: Array = replay[current_replay_pos]
		current_replay_pos += 1
		if next_move[0] == RecordType.START:
			initializing = false
#		print(current_replay_pos)
#		print(type, " ", action, " ", amount)
		return next_move
	else:
		replay_ended = true
		return NOTHING_MOVE


# ------------ SAVE AND LOAD ------------

func standard_replay_filename(replay_name: String) -> String:
	if FileAccess.file_exists("user://" + replay_name + ".replay"):
		var i: int = 1
		while FileAccess.file_exists("user://" + replay_name + " " + str(i) + ".replay"):
			i += 1
		replay_name += " " + str(i)
	
	return "user://" + replay_name + ".replay"


func stats_replay_filename(replay_name: String) -> String:
	if not GameStats.victorious_alignment.is_empty():
		replay_name += " - " + GameStats.victorious_alignment
	return standard_replay_filename(replay_name)


func pack_replay_filename(pack: String, map: String, check: String, dp: DPControl.Controler) -> String:
	pack = pack.trim_prefix("res://")
	return standard_replay_filename(pack + "/" + map + "_" + check + "_" + str(dp))


func save_replay(replay_name: String) -> void:
	var replay_save : Dictionary = {
		"game_version" : Options.VERSION,
		"replay_dir" : MapSetup.current_directory,
		"replay_map" : MapSetup.current_map_name,
		"replay_play_order" : replay_play_order,
		"replay_aliances" : replay_aliances,
		"replay_controlers" : replay_controlers,
		"replay" : replay,
		"replay_uses_aliances" : replay_uses_aliances,
		"replay_removed_alignments" : replay_removed_alignments,
		"last_turn" : last_turn,
	}
	
	var file = FileAccess.open(replay_name, FileAccess.WRITE)
	
	if file == null:
		push_error("Couldn't save replay file: ", replay_name)
		return
	
	file.store_string(JSON.stringify(replay_save))
	
	file.close()


func load_replay(replay_name: String) -> bool:
	var replay_save: Dictionary = {
	}
	
	if FileAccess.file_exists(replay_name):
		var file = FileAccess.open(replay_name, FileAccess.READ)
		
		replay_save = JSON.parse_string(file.get_as_text()) as Dictionary
		
		file.close()
		
		if not replay_save.has("game_version"):
			push_warning("Replay is from an old version")
			return false
		if replay_save["game_version"] not in Options.REPLAY_COMPATIBLE_VERSIONS:
			push_warning("Replay is from an incompatible version")
			return false
		
		MapSetup.current_directory = replay_save["replay_dir"]
		MapSetup.current_map_name = replay_save["replay_map"]
		
		replay_play_order = replay_save["replay_play_order"]
		replay_controlers = replay_save["replay_controlers"]
		replay = replay_save["replay"]
		replay_uses_aliances = replay_save["replay_uses_aliances"]
		replay_removed_alignments = replay_save["replay_removed_alignments"]
		
		var ra_size = replay_save["replay_aliances"].size()
		replay_aliances.resize(ra_size)
		for i in range(ra_size):
			replay_aliances[i] = int(replay_save["replay_aliances"][i])
		
		last_turn = replay_save.get("last_turn", -1)
		
		replay_active = true
		replay_ended = false
		initializing = true
		
		return true
	else:
		push_warning("Couldn't open replay file: ", replay_name)
		return false
