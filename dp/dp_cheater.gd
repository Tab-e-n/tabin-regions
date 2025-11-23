extends DigitalPlayer


var cheat_turn : bool = false
var cheat_amount : int = 0
var cheat_amount_max : int = 1


func start_turn(align : int):
	super.start_turn(align)
	cheat_amount = 0
	if controler.region_control:
		cheat_turn = controler.region_control.current_turn % 6 == 0
		@warning_ignore("integer_division")
		cheat_amount_max = controler.region_control.current_turn / 18
		if cheat_turn:
			controler.CALL_cheat = true
			cheat_amount += 1


func choose_regions(benefit_func : Callable, regions : Array) -> String:
	if regions.size() == 0:
		return ""
	var chosen : String = ""
	var highest_benefit : int = 0
	var results : Array[String] = []
	for region in regions:
		var benefit : int = benefit_func.call(region)
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
	return chosen


func calculate_benefit_action(region : Region):
	var action_amount : int = controler.get_action_amount()
	var benefit : int = 0
	if controler.alignment_friendly(current_alignment, region.alignment):
		var threat : int = region.worst_power_delta()
		# Not enough actions, can't defend
		if -threat > action_amount:
			benefit = -region.power - 1
		# Not enough space on region, can't defend
		elif region.power - threat > region.max_power:
			benefit = -region.power - 1
		else:
			# Can defend, not as encouraged
			benefit = region.power >> 1
			# Capitals are still good to keep
			if region.is_capital:
				benefit -= threat
		# Self-centered
		if region.alignment != current_alignment:
			benefit -= 1
	else:
		# Capitals are good to take
		if region.is_capital:
			benefit += 5
		# Would remove all of the regions power and add one of your own
		benefit += region.power + 1
		if controler.used_region_previously(region.name):
			# Discourage repetition
			benefit -= 4
	
#	print(region, ": ", benefit)
	return benefit


func calculate_benefit_mobilize(region : Region):
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
	
	var choice : String = choose_regions(calculate_benefit_action, regions.values())
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

