extends DigitalPlayer


enum PRIORITY {
	# lowest
	BAD = -1,
	INDECISIVE,
	REINFORCE,
	CAPTURE_NEUTRAL,
	REINFORCE_HIGH_ATTACK_NEIGHBOR,
	REINFORCE_ENEMY_ADJACENT,
	REINFORCE_ENEMY_ADJACENT_CAPTURE,
	REINFORCE_SAVING,
	CAPTURE_ENEMY,
	REINFORCE_HIGH_ATTACK_CAPITAL,
	REINFORCE_CAPITAL_ADJACENT,
	REINFORCE_CAPITAL_ADJACENT_CAPTURE,
	REINFORCE_SAVING_CAPITAL,
	CAPTURE_CAPITAL,
	# highest
}


@export var cheater : bool = false
var cheat_turn : bool = false
var cheat_amount : int = 0
var cheat_amount_max : int = 1


func start_turn(align : int):
	super.start_turn(align)
	cheat_amount = 0
	if controler.region_control:
		if cheater:
			cheat_turn = controler.region_control.current_turn % 6 == 0
			@warning_ignore("integer_division")
			cheat_amount_max = controler.region_control.current_turn / 18
		if cheat_turn:
			controler.CALL_cheat = true
			cheat_amount += 1


func choose_regions(benefit_func : Callable, regions : Array) -> String:
	if regions.size() == 0:
		return ""
	
	var priorities : Dictionary = {}
	for region in regions:
		priorities[region] = PRIORITY.INDECISIVE
	for region in regions:
		priorities[region] = benefit_func.call(region, priorities)
	
	var highest_benefit : int = 0
	var results : Array[Region] = []
	for region in priorities:
		if priorities[region] > highest_benefit:
			results = [region]
			highest_benefit = priorities[region]
		elif priorities[region] == highest_benefit:
			results.append(region)
	
	var chosen : Region = null
	if highest_benefit >= 0:
		if results.size() == 1:
			chosen = results[0]
		elif results.size() > 1:
			# TODO: Tie brakes here
			chosen = results[randi_range(0, results.size() - 1)]
	
	if chosen:
		return chosen.name
	return ""


func set_linked_priority(region : Region, priorities : Dictionary, priority : int) -> void:
	for link in region.links:
		var target : Region = link.get_other_region(region)
		if priorities.has(target) and priorities[target] != PRIORITY.BAD:
			priorities[target] = max(priorities[target], priority)


func calculate_priority(region : Region, priorities : Dictionary, phase_bonus : bool) -> int:
	var action_amount : int = controler.get_action_amount()
	var priority : int = PRIORITY.INDECISIVE
	if controler.alignment_friendly(current_alignment, region.alignment):
		var threat : int = region.worst_power_delta()
		var in_threat : bool = -threat > 0
		var saveable : bool = -threat <= action_amount
		var bonus_saveable : bool = saveable or not phase_bonus
		var capturable : bool = region.highest_single_power() + 2 <= action_amount
		var next_to_capital : bool = region.next_to_capital()
		var next_to_enemy : bool = region.next_to_enemy()
		priority = PRIORITY.REINFORCE
		if not saveable:
			priority = PRIORITY.BAD
		elif in_threat and region.is_capital:
			priority = PRIORITY.REINFORCE_SAVING_CAPITAL
		if next_to_capital:
			if capturable and bonus_saveable:
				priority = max(priority, PRIORITY.REINFORCE_CAPITAL_ADJACENT_CAPTURE)
			elif not saveable:
				priority = PRIORITY.BAD
				set_linked_priority(region, priorities, PRIORITY.REINFORCE_HIGH_ATTACK_CAPITAL)
			else:
				priority = max(priority, PRIORITY.REINFORCE_CAPITAL_ADJACENT)
		if in_threat and saveable:
				priority = max(priority, PRIORITY.REINFORCE_SAVING)
		elif next_to_enemy:
			if capturable and bonus_saveable:
				priority = max(priority, PRIORITY.REINFORCE_ENEMY_ADJACENT_CAPTURE)
			elif not saveable:
				priority = PRIORITY.BAD
				set_linked_priority(region, priorities, PRIORITY.REINFORCE_HIGH_ATTACK_NEIGHBOR)
			else:
				priority = max(priority, PRIORITY.REINFORCE_ENEMY_ADJACENT)
	else:
		if region.is_capital:
			priority = PRIORITY.CAPTURE_CAPITAL
		elif controler.alignment_inactive(region.alignment):
			priority = PRIORITY.CAPTURE_NEUTRAL
		else:
			priority = PRIORITY.CAPTURE_ENEMY
	
#	print(region, ": ", benefit)
	return priority


func calculate_priority_normal(region : Region, priorities : Dictionary) -> int:
	return calculate_priority(region, priorities, false)


func calculate_priority_bonus(region : Region, priorities : Dictionary) -> int:
	return calculate_priority(region, priorities, true)


func calculate_benefit_mobilize(region : Region, _regions):
	return 0 if region.worst_power_delta() == 0 else 1


func think_normal():
	if controler.get_action_amount() <= 0:
		controler.CALL_change_current_phase = true
		return
	
	var regions : Set = Set.new()
	
	var friendly_regions : Array = controler.get_owned_regions()
	
	for region in friendly_regions:
		if region.power < region.max_power:
			regions.add(region)
		for link in region.links:
			var target : Region = link.get_other_region(region)
			if target.incoming_attack(current_alignment, 0, true):
				regions.add(target)
	
	var allied_regions : Array = []
	
	if controler.aliances_on():
		allied_regions = controler.get_allied_regions()
		for region in allied_regions:
			regions.add(region)
	
	var choice : String = choose_regions(calculate_priority_normal, regions.values())
	if choice.is_empty():
		controler.CALL_change_current_phase = true
	else:
		controler.selected_capital = choice


func think_mobilize():
	var regions : Set = Set.new()
	
	var friendly_regions : Array = controler.get_owned_regions()
	
	for region in friendly_regions:
		if region.power > 1:
			regions.add(region)
	
	var choice : String = choose_regions(calculate_benefit_mobilize, regions.values())
	
	if choice.is_empty():
		if controler.get_bonus_action_amount() == 0:
			controler.CALL_end_turn = true
		else:
			if cheat_amount < cheat_amount_max and cheat_turn:
				controler.CALL_cheat = true
				cheat_amount += 1
			else:
				controler.CALL_change_current_phase = true
	else:
		controler.selected_capital = choice


func think_bonus():
	think_normal()

