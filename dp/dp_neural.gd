extends DigitalPlayer


enum {
	INPUT_CAPITAL,
	INPUT_POWER,
	INPUT_MAX_POWER,
	INPUT_CAPITAL_DISTANCE,
	INPUT_ACTIONS,
	INPUT_ATTACK_POWER,
	INPUT_OWN_ATTACK_POWER,
	INPUT_PREVIOUS_MOVE,
}

const NET_NAMES : Array[String] = ["attack", "reinforce", "mobilize"]
const NET_AMOUNT : int = 10
const CHECK : int = -1


var final_network_attack : Array[Network] = []
var final_network_reinforce : Array[Network] = []
var final_network_mobilize : Array[Network] = []

var trainer : NetworkTrainer = null

var network_attack : Network
var network_reinforce : Network
var network_mobilize : Network


func load_network(id : int, net_type : int) -> Network:
	var dir : String = "res://dp/networks/" + str(id) + "/"
	
	var save : Dictionary = {}
	
	var filename : String = NET_NAMES[net_type]
	var net : Network = Network.new()
	
	# Fuck checking, if the file doesn't exist i'm just an idiot
	
	var file = FileAccess.open(dir + filename, FileAccess.READ)
	
	save = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	net.load_network_from_dict(save)
	
	add_child(net)
	
	return net


func _ready():
	_ready_network_trainer.call_deferred()


func _ready_network_trainer():
	trainer = controler.game_control as NetworkTrainer
	if not trainer:
		if CHECK >= 0:
			print(CHECK)
			for i in range(NET_AMOUNT):
				final_network_attack.append(load_network(CHECK, 0))
				final_network_reinforce.append(load_network(CHECK, 0))
				final_network_mobilize.append(load_network(CHECK, 0))
		else:
			for i in range(NET_AMOUNT):
				final_network_attack.append(load_network(i, 0))
				final_network_reinforce.append(load_network(i, 1))
				final_network_mobilize.append(load_network(i, 2))


func start_turn(align : int, soflock_prevention : int = 0):
	if trainer:
		network_attack = trainer.get_network_for_align(align, 0)
		network_reinforce = trainer.get_network_for_align(align, 1)
		network_mobilize = trainer.get_network_for_align(align, 2)
	else:
		if not controler.region_control:
			if soflock_prevention < 10:
				start_turn.call_deferred(align, soflock_prevention + 1)
			return
		var i : int = controler.region_control.play_order_i % NET_AMOUNT
		network_attack = final_network_attack[i]
		network_reinforce = final_network_reinforce[i]
		network_mobilize = final_network_mobilize[i]
	super.start_turn(align)


func think_normal():
	if not network_attack or not network_reinforce:
		controler.CALL_nothing = true
		return
	if controler.get_action_amount() <= 0:
		controler.CALL_change_current_phase = true
		return
	
	if trainer:
		trainer.increment_order_amount(current_alignment)
	
	var attack_regions : Set = Set.new()
	var reinforce_regions : Array = []
	var friendly_regions : Array = controler.get_owned_regions()
	if controler.aliances_on():
		friendly_regions.append_array(controler.get_allied_regions())
	
	for region in friendly_regions:
#		print("FROM: ", region.name)
		if region.power != region.max_power:
			reinforce_regions.append(region)
		if region.alignment != current_alignment:
#			print("allies region, cannot attack through")
			continue
		for link in region.links:
			var target = link.get_other_region(region)
			if not target:
				continue
#			print("--> ", target.name)
			if controler.alignment_friendly(current_alignment, target.alignment):
#				print("friendly alignment")
				continue
			if not target.incoming_attack(current_alignment, 0, true):
#				print("cannot attack")
				continue
			attack_regions.add(target)
	
	var chosen_attack : Array = choose_using_network(network_attack, attack_regions.values())
	var chosen_reinforce : Array = choose_using_network(network_reinforce, reinforce_regions)
	if chosen_attack[0] == "" and chosen_reinforce[0] == "":
		controler.CALL_change_current_phase = true
	else:
		if chosen_reinforce[0] == "" or chosen_attack[1] >= chosen_reinforce[1]:
			controler.selected_capital = chosen_attack[0]
		else:
			controler.selected_capital = chosen_reinforce[0]
	


func think_mobilize():
	if not network_mobilize:
		controler.CALL_nothing = true
		return
	
	if trainer:
		trainer.increment_order_amount(current_alignment)
	
	var mobilize_regions : Array = []
	var friendly_regions : Array = controler.get_owned_regions()
	
	var can_mobilize : bool = false
	for region in friendly_regions:
		if region.power > 1:
			mobilize_regions.append(region)
			can_mobilize = true
	if not can_mobilize:
		if controler.get_bonus_action_amount() <= 0:
			controler.CALL_end_turn = true
		else:
			controler.CALL_change_current_phase = true
		return
	
	var chosen_mobilize : Array = choose_using_network(network_mobilize, mobilize_regions)
	if chosen_mobilize[0] == "":
		if controler.get_bonus_action_amount() <= 0:
			controler.CALL_end_turn = true
		else:
			controler.CALL_change_current_phase = true
	else:
		controler.selected_capital = chosen_mobilize[0]


func think_bonus():
	think_normal()


func choose_using_network(network : Network, regions : Array) -> Array:
	if regions.size() == 0:
		return ["", -1.0]
	var chosen : String = ""
	var highest_benefit : float = -1.0
	var results : Array = []
	for region in regions:
		var benefit : float = calculate_benefit(network, region)
		if benefit > highest_benefit:
			results = [region.name]
			highest_benefit = benefit
		elif benefit == highest_benefit:
			results.append(region.name)
	if highest_benefit >= 0:
		if results.size() == 1:
			chosen = results[0]
		elif results.size() > 1:
			chosen = results[randi_range(0, results.size() - 1)]
	return [chosen, highest_benefit]


func calculate_benefit(network : Network, region : Region) -> float:
	var inputs = range(8)
	
	if region.is_capital:
		inputs[INPUT_CAPITAL] = 1.0
	else:
		inputs[INPUT_CAPITAL] = 0.0
	
	inputs[INPUT_POWER] = region.power
	inputs[INPUT_MAX_POWER] = region.max_power
	inputs[INPUT_CAPITAL_DISTANCE] = region.distance_from_capital
	
	inputs[INPUT_ACTIONS] = controler.get_action_amount()
	
	inputs[INPUT_ATTACK_POWER] = region.strongest_enemy_attack(current_alignment)
	inputs[INPUT_OWN_ATTACK_POWER] = region.get_alignments_attack_power(current_alignment)
	
	inputs[INPUT_PREVIOUS_MOVE] = controler.used_region_previously(region.name)
	
	network.set_inputs(inputs)
	network.calculate_results()
	var results : Array = network.get_results()
	
	return results[0]
