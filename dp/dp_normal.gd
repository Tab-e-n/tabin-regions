extends DigitalPlayer


@export var cheater : bool = false
var cheated : bool = false


func start_turn(align : int):
	super.start_turn(align)
	cheated = false
	if controler.region_control:
		if cheater and controler.region_control.current_turn % 6 == 0:
			controler.CALL_cheat = true


func think_bonus():
	think_normal()


func think_normal():
	if controler.get_action_amount() == 0:
		controler.CALL_change_current_phase = true
		return
	
#	print("think default first")
	var eligable_regions : Set = Set.new()
	
	var friendly_regions : Array = controler.get_owned_regions()
	
	if controler.aliances_on():
		friendly_regions.append_array(controler.get_allied_regions())
	
	for region in friendly_regions:
		var in_threat : bool = false
		for link in region.links:
			var target : Region = link.get_other_region(region)
			if not target:
				continue
			if controler.alignment_friendly(current_alignment, target.alignment):
				continue
			if not controler.alignment_inactive(target.alignment):
				in_threat = true
			if region.alignment != current_alignment:
				continue
			if not target.incoming_attack(current_alignment, 0, true):
				continue
			eligable_regions.add(target)
		if in_threat and region.power < region.max_power:
			eligable_regions.add(region)
	
#	print(eligable_regions)
	
	var highest_benefit : int = 0
	var lowest_distance : int = 0
	var results : Array = []
	while not eligable_regions.empty():
		var region : Region = eligable_regions.pop()
		var benefit : int = calculate_benefit_default(region)
		var distance = region.distance_from_capital
		if benefit > highest_benefit or (benefit == highest_benefit and distance < lowest_distance):
			results = [region.name]
			highest_benefit = benefit
			lowest_distance = distance
		elif benefit == highest_benefit:
			results.append(region.name)
	
	if results:
		controler.selected_capital = results[randi_range(0, results.size() - 1)]
	else:
		# Backup strategy
		for region in friendly_regions:
			if region.power < region.max_power:
				eligable_regions.add(region)
		if eligable_regions.empty():
			controler.CALL_change_current_phase = true
		else:
			var index : int = randi_range(0, eligable_regions.size() - 1)
			controler.selected_capital = eligable_regions.values()[index].name
	
#	print(controler.selected_capital)


func think_mobilize():
	var no_more_extra : bool = true
	for region in controler.get_owned_regions():
		var threat : int = region.worst_power_delta()
		if threat >= 1 and region.power > 1 and not controler.get_current_moves().contains(region.name):
			controler.selected_capital = region.name
			no_more_extra = false
			break
#	print("think default mobilize")
	if no_more_extra:
		if controler.get_bonus_action_amount() == 0:
			controler.CALL_end_turn = true
		else:
			if cheater and not cheated and controler.region_control.current_turn % 6 == 0:
				controler.CALL_cheat = true
				cheated = true
			else:
				controler.CALL_change_current_phase = true


func calculate_benefit_default(region : Region):
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
