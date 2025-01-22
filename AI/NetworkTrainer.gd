extends GameControl
class_name NetworkTrainer


const NETWORK_SAVE_DIR : String = "user://Networks"
const NET_NAMES : Array[String] = ["attack", "reinforce", "mobilize"]
const ALLOWED_MAPS : Dictionary = {
# List of used maps
	"B.5_Testlandia.tscn" : [5, 20],
	
	"A.4_Cubical_Warfare.tscn" : [4, 20],
	"A.6_Honeycomb_Madness.tscn" : [6, 25],
	"A.6_Under_Lock_And_Lock.tscn" : [6, 25],
	"B.3_Trees_Trees_Trees.tscn" : [3, 25],
	"B.4_The_Power_Of_Two.tscn" : [4, 25],
	"B.5_We_Didn't_Start_the_Fire.tscn" : [5, 25],
	"B.6_Azgaar_Map.tscn" : [6, 25],
	"B.7_On_The_Slots.tscn" : [7, 30],
	"B.8_No_Tickes_Left_To_Ride.tscn" : [8, 30],
	"C.6_Final_Frontiers.tscn" : [6, 30],
# This one is a mistake, but i'm doing it anyway
#	"C.30_World_Map.tscn" : [30, 70]
# Coinflips
#	"A.2_Odd_&_Even.tscn" : [2, 15], 
#	"B.2_House_Of_90_Degrees.tscn" : [2, 15],
# Stalematy
#	"A.2_Music_Land.tscn" : [2, 25], 
#	"A.2_Stretched_Out.tscn" : [2, 25],
#	"A.2_Title_Map.tscn" : [2, 15],
#	"A.3_Three_Crabs.tscn" : [2, 25],
}

enum {MAP_ALIGN_AMOUNT, MAP_TURN_CUTOFF}


@export var network_amount : int = 100
@export var remove_amount : int = 40
@export var new_creatures : int = 10
@export var network_inputs : int = 8
@export var network_specifications : Array = [8, 8, 1]
@export var turn_cutoff_mult : int = 3
@export var only_test_no_execute : bool = false

var turn_cutoff : int = 10

var networks : Node
var rankings : Array = []
var current_rankings : Array = []
var choosable_networks : Array = []
var chosen_networks : Array = []
var order_amount : Array = []
var chosen_variations : int = 0

var region_control_visible : bool = true


func _ready():
	networks = Node.new()
	add_child(networks)
	
	if not DirAccess.dir_exists_absolute(NETWORK_SAVE_DIR):
		DirAccess.make_dir_absolute(NETWORK_SAVE_DIR)
		make_new_networks(network_amount, network_inputs, network_specifications)
		print("New Networks")
	else:
		load_all_networks(network_amount)
		print("Loading Networks")
	
	MapSetup.current_map_name = "B.5_Testlandia.tscn"
	MapSetup.player_amount = 0
	MapSetup.default_ai_controler = AIControler.CONTROLER_NEURAL
	MapSetup.aliances_amount = 1
	MapSetup.used_aligments = 65532
	MapSetup.preset_alignments = []
	
	choosable_networks = range(network_amount)
	chosen_networks.resize(ALLOWED_MAPS[MapSetup.current_map_name][MAP_ALIGN_AMOUNT])
	
	rankings.resize(network_amount)
	reset_rankings(rankings, 1.0)
	current_rankings.resize(ALLOWED_MAPS[MapSetup.current_map_name][MAP_ALIGN_AMOUNT])
	reset_rankings(current_rankings)
	order_amount.resize(ALLOWED_MAPS[MapSetup.current_map_name][MAP_ALIGN_AMOUNT])
	reset_rankings(order_amount)
	
	choose_networks()
	
	super._ready()
	
	region_control.turn_ended.connect(_turn_ended)
	
	turn_cutoff = ALLOWED_MAPS[MapSetup.current_map_name][MAP_TURN_CUTOFF] * turn_cutoff_mult


func _physics_process(_delta):
	if Input.is_action_just_pressed("ai_speedrun"):
		win(0)


func make_new_networks(amount : int, net_inputs : int, net_specs : Array):
	if not networks:
		return
	
	if networks.get_child_count() > 0:
		for net in networks.get_children():
			networks.remove_child(net)
			net.queue_free()
	
	for i in range(amount):
		var net_set : Node = new_network_set(i, net_inputs,net_specs)
		randomize_network_set(net_set)


func new_network_set(id : int, net_inputs : int, net_specs : Array) -> Node:
	var net_set : Node = Node.new()
	net_set.name = str(id)
	networks.add_child(net_set)
	for j in range(3):
		var net : Network = Network.new()
		net.name = NET_NAMES[j]
		net.setup_network(net_inputs, net_specs)
		net_set.add_child(net)
	return net_set


func randomize_network_set(net_set : Node):
	for net in net_set.get_children():
		net.randomize_network()


func choose_networks() -> bool:
	if chosen_networks.size() > choosable_networks.size():
		return false
	for i in range(chosen_networks.size()):
		chosen_networks[i] = choosable_networks.pop_at(randi_range(0, choosable_networks.size() - 1))
	
	print("c: ", chosen_networks)
	return true


func get_network_for_align(align : int, net_type : int) -> Network:
	var chosen_net = get_net_id(align)
	if chosen_net == -1:
		return null
	var net_set : Node = networks.get_node(str(chosen_net))
	return net_set.get_node(NET_NAMES[net_type])


func get_net_id(align : int) -> int:
	if chosen_networks.size() == 0:
		print("chosen_networks is empty")
		return -1
	var al = (align - 1 + chosen_variations) % chosen_networks.size()
	return chosen_networks[al]


func reset_rankings(ranks : Array, value : float = 0.0):
	for i in range(ranks.size()):
		ranks[i] = value


func sort_networks():
	for i in range(choosable_networks.size()):
		for j in range(choosable_networks.size() - i - 1):
			if rankings[j] < rankings[j + 1]:
				var t : float = rankings[j]
				rankings[j] = rankings[j + 1]
				rankings[j + 1] = t
				var n : int = choosable_networks[j]
				choosable_networks[j] = choosable_networks[j + 1]
				choosable_networks[j + 1] = n


func remove_last_networks(removed : int):
	if removed > choosable_networks.size():
		removed = choosable_networks.size()
	for i in range(removed):
		var net_id : int = choosable_networks.pop_back()
		var network : Node = networks.get_node(str(net_id))
		networks.remove_child(network)
		network.queue_free()


func fill_missing_networks(net_amount : int, new_amount : int):
	var n : int = 0
	for i in range(net_amount):
		if networks.has_node(str(i)):
			continue
		var net_set : Node = Node.new()
		net_set.name = str(i)
		networks.add_child(net_set)
		if n < new_amount:
			for j in range(3):
				var net : Network = Network.new()
				net.setup_network(network_inputs, network_specifications)
				net.randomize_network()
				net.name = NET_NAMES[j]
				net_set.add_child(net)
		else:
			var net_set_parent : Node = networks.get_node(str(choosable_networks[randi_range(0, choosable_networks.size() - 1)]))
			for j in range(3):
				var net : Network = net_set_parent.get_node(NET_NAMES[j]).copy_self()
				net.name = NET_NAMES[j]
				net.mutate()
				net_set.add_child(net)


func win(_align : int):
	ai_control.reset()
	
	var turn_penalty : float = 0.1 * (float(region_control.current_turn) / float(turn_cutoff))
	print("Turn penalty: ",  turn_penalty)
	
	var highest_placement : float = 0
	for i in range(chosen_networks.size()):
		var placement : String = GameStats.get_stat(i + 1, "placement") as String
		if placement.is_valid_int():
			var place : float = 1.0 - float(placement.to_int()) / float(chosen_networks.size())
			if highest_placement < place:
				highest_placement = place
	for i in range(chosen_networks.size()):
		var placement : String = GameStats.get_stat(i + 1, "placement") as String
#		print(placement)
		var al = (i + chosen_variations) % chosen_networks.size()
		
		if placement.is_valid_int():
			current_rankings[al] += 1.0 - float(placement.to_int()) / float(chosen_networks.size())
		else:
			current_rankings[al] += highest_placement
		current_rankings[al] -= turn_penalty
	
	for i in range(chosen_networks.size()):
		var turns : int = GameStats.get_stat(i + 1, "turns lasted") as int
		var al = (i + chosen_variations) % chosen_networks.size()
		order_amount[al] /= turns
	var stalling_networks : Array = []
	var most_orders : float = 0
	for i in range(chosen_networks.size()):
		if order_amount[i] > most_orders:
			stalling_networks = [i]
			most_orders = order_amount[i]
		elif order_amount[i] == most_orders:
			stalling_networks.append(i)
	if most_orders > chosen_networks.size() + 5:
		print("stallers: ", stalling_networks)
		for i in stalling_networks:
			current_rankings[i] -= 0.05
#	print("o: ", order_amount)
	reset_rankings(order_amount, 0)
	
	if chosen_variations >= chosen_networks.size() - 1:
		chosen_variations = 0
		for i in range(current_rankings.size()):
			current_rankings[i] /= float(chosen_networks.size())
			if only_test_no_execute:
				rankings[chosen_networks[i]] += current_rankings[i]
			else:
				rankings[chosen_networks[i]] = current_rankings[i]
		print("r: ", current_rankings)
		reset_rankings(current_rankings)
		
		print("NEW SET OF NETS")
		
		MapSetup.current_map_name = ALLOWED_MAPS.keys()[randi_range(0, ALLOWED_MAPS.size() - 1)]
		turn_cutoff = ALLOWED_MAPS[MapSetup.current_map_name][MAP_TURN_CUTOFF] * turn_cutoff_mult
		
		print("Next map: ", MapSetup.current_map_name)
		print("Timeout time: ", turn_cutoff)
		
		var align_amount : int = ALLOWED_MAPS[MapSetup.current_map_name][MAP_ALIGN_AMOUNT]
		chosen_networks.resize(align_amount)
		current_rankings.resize(align_amount)
		reset_rankings(current_rankings)
		order_amount.resize(align_amount)
		reset_rankings(order_amount)
		
		if not choose_networks():
			print(" --- ALL NETS TESTED --- ")
			print("R: ", rankings)
			# End of session
			if not only_test_no_execute:
				# Remove poorly performing nets
				choosable_networks = range(network_amount)
				sort_networks()
				print("Sorted: ", rankings)
				remove_last_networks(remove_amount)
				# Generate new nets
				fill_missing_networks(network_amount, new_creatures)
				
				reset_rankings(rankings, 1.0)
			
			choosable_networks = range(network_amount)
			choose_networks()
		else:
			print(" *** Remaining nets: ", choosable_networks.size())
	else:
		chosen_variations += 1
		print("r: ", current_rankings)
		print("New variation, number: ", chosen_variations)
	
	change_map(MapSetup.current_map_name)
	region_control.turn_ended.connect(_turn_ended)
	region_control.visible = region_control_visible


func lose(align : int):
	win(align)


func _turn_ended():
	if region_control.current_turn >= turn_cutoff:
		print("Timeout")
		lose(0)


func increment_order_amount(alignment : int):
	var al = (alignment + chosen_variations - 1) % chosen_networks.size()
	order_amount[al] += 1


func save_network(net_set : Node):
	var dir : String = NETWORK_SAVE_DIR + "/" + net_set.name
	
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
	
	for i in range(3):
		var filename : String = NET_NAMES[i]
		var net : Network = net_set.get_node(filename) as Network
		
		var file = FileAccess.open(dir + "/" + filename, FileAccess.WRITE)
		
		file.store_string(JSON.stringify(net.network_to_dict()))
		
		file.close()


func load_network(id : int):
	if networks.has_node(str(id)):
		return
	
	var dir : String = NETWORK_SAVE_DIR + "/" + str(id)
	
	if not DirAccess.dir_exists_absolute(dir):
		return
	
	var net_set : Node = Node.new()
	net_set.name = str(id)
	networks.add_child(net_set)
	
	var save : Dictionary = {}
	
	for i in range(3):
		var filename : String = NET_NAMES[i]
		var net : Network = Network.new()
		if FileAccess.file_exists(dir + "/" + filename):
			
			var file = FileAccess.open(dir + "/" + filename, FileAccess.READ)
			
			save = JSON.parse_string(file.get_as_text())
			
			file.close()
			
			net.load_network_from_dict(save)
		else:
			net.setup_network(network_inputs, network_specifications)
			net.randomize_network()
		net.name = filename
		
		net_set.add_child(net)


func save_all_networks():
	if only_test_no_execute:
		
		choosable_networks = range(network_amount)
		sort_networks()
		print("NETS SORTED: ", choosable_networks)
		get_tree().quit()
	else:
		print("SAVE ALL NETWORKS")
		for net_set in networks.get_children():
			save_network(net_set)


func load_all_networks(amount : int):
	print("LOAD ALL NETWORKS")
	for i in range(amount):
		load_network(i)


func toggle_region_control_visibility():
	region_control_visible = !region_control_visible
	region_control.visible = region_control_visible
