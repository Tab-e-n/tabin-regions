extends Node


const DEFAULT_STATS : Dictionary = {
	"alignment name" : "",
	"align color" : Color(0, 0, 0, 0),
	"controler" : 0,
	"placement" : "N/A",
	"turns lasted" : 0,
	"first actions done" : 0,
	"bonus actions done" : 0,
	"enemy units removed" : 0,
	"units lost" : 0,
	"units mobilized" : 0,
	"most regions owned" : 0,
	"most capitals owned" : 0,
	"regions captured" : 0,
	"regions reinforced" : 0,
	"capital regions captured" : 0,
	"turn order" : 0,
	
	# GRAPH
	"regions" : 0,
	"capitals" : 0,
	"penalties" : 0,
}

const DEFAULT_GRAPH_STATISTICS : Dictionary = {
	"regions" : 0,
	"capitals" : 0,
	"penalties" : 0,
}


var victorious_alignment: String = ""

var stats: Array = []

var graph_statistics: Dictionary
var graph: Array = []


func clear_statistics() -> void:
	stats.clear()
	graph.clear()


func reset_statistics(align_amount) -> void:
	clear_statistics()
	stats.resize(align_amount)
	graph.resize(align_amount)
	for i in range(align_amount):
		stats[i] = DEFAULT_STATS.duplicate()
		graph[i] = []
	graph_statistics = DEFAULT_GRAPH_STATISTICS.duplicate()
	victorious_alignment = ""


func stat_exists(align: int, key: String) -> bool:
	if align < 0 or align >= stats.size():
		return false
	if not stats[align].has(key):
		push_warning("Statistic ", key, " doesn't exist.")
		return false
	return true


func create_stat(key: String, initial: Variant) -> void:
	for align_stats in stats:
		align_stats[key] = initial


func add_to_stat(align: int, key: String, value: Variant) -> void:
	if not stat_exists(align, key):
		return
	if not typeof(stats[align][key]) in [TYPE_FLOAT, TYPE_INT]:
		return
	stats[align][key] += value


func set_stat(align: int, key: String, value: Variant) -> void:
	if not stat_exists(align, key):
		return
	stats[align][key] = value


func get_stat(align: int, key: String, failsafe = null):
	if not stat_exists(align, key):
		return failsafe
	return stats[align][key]


# ------------ SAVING STATS ------------

func format_stat_for_csv(stat: String, value: Variant) -> String:
	if stat in ["alignment name", "placement"]:
		return value
	elif stat == "align color":
		return "#" + value.to_html(false)
	elif stat == "controler":
		return DPControl.CONTROLER_NAMES[value]
	return String.num(value)


func stat_keys() -> PackedStringArray:
	return DEFAULT_STATS.keys()


func stats_as_strings(align: int) -> PackedStringArray:
	var str_stats: PackedStringArray = []
	for i in stat_keys():
		str_stats.append(format_stat_for_csv(i, stats[align][i]))
	
	return str_stats


func single_stat_to_row(stat: String) -> PackedStringArray:
	var str_stats : PackedStringArray = [stat]
	for i in range(stats.size()):
		str_stats.append(format_stat_for_csv(stat, stats[i][stat]))
	return str_stats


func full_filename(file_name: String) -> String:
	if not victorious_alignment.is_empty():
		file_name += " - " + victorious_alignment
	if FileAccess.file_exists("user://" + file_name + ".csv"):
		var i: int = 1
		while FileAccess.file_exists("user://" + file_name + " " + str(i) + ".csv"):
			i += 1
		file_name += " " + str(i)
	return "user://" + file_name + ".csv"


func save_as_csv_transposed(file_name: String):
	file_name = full_filename(file_name)
	
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	
	file.store_csv_line(stat_keys())
	for i in range(stats.size()):
		file.store_csv_line(stats_as_strings(i))
	
	file.close()


func save_as_csv(file_name: String):
	file_name = full_filename(file_name)
	
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	
	for stat in stat_keys():
		file.store_csv_line(single_stat_to_row(stat))
	
	file.close()


# ------------ STATS GRAPH ------------

func create_graph_stat(stat: String, stat_max: int) -> void:
	graph_statistics[stat] = stat_max
	create_stat(stat, 0)


func set_graph_max(stat: String, stat_max: int) -> void:
	graph_statistics[stat] = stat_max


func record_graph_column() -> void:
	if not Options.use_graph:
		return
	for i in range(graph.size()):
		var graph_stats : Dictionary = {}
		for stat in graph_statistics:
			graph_stats[stat] = stats[i][stat]
#		print("recording ", graph_stats)
		graph[i].append(graph_stats)
